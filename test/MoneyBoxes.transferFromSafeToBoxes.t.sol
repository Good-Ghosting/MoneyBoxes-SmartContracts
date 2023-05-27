// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./MoneyBoxes.base.t.sol";

contract MoneyBoxesTransferFromSafeToBox is MoneyBoxesModuleBaseTest {
    function getBoxesPercentageSum() internal view returns (uint256) {
        uint256 percentageSum = 0;
        for (uint256 i = 0; i < boxConfiguration.length; i++) {
            percentageSum += boxConfiguration[i].percentage;
        }
        return percentageSum;
    }

    function parameterized_test_transferFromSafeToBoxes(address token) internal {
        uint256 safeBalanceBefore = getTokenBalance(address(safe), token);
        uint256 boxesBalanceBefore = getTokenBalance(address(moneyBoxesModule), token);

        moneyBoxesModule.transferFromSafeToBoxes(safeBalanceBefore, token);

        uint256 safeBalanceAfter = getTokenBalance(address(safe), token);
        uint256 boxesBalanceAfter = getTokenBalance(address(moneyBoxesModule), token);

        uint256 safeBalanceDifferece = safeBalanceBefore - safeBalanceAfter;
        uint256 boxesBalanceDifferece = boxesBalanceAfter - boxesBalanceBefore;

        uint256 totalBoxesPercentage = getBoxesPercentageSum();
        uint256 expectedBalanceDifference = (safeBalanceBefore * totalBoxesPercentage) / 100;

        assertEq(safeBalanceDifferece, expectedBalanceDifference);
        assertEq(boxesBalanceDifferece, expectedBalanceDifference);

        //check that boxes balances are correct
        for (uint256 i = 0; i < boxConfiguration.length; i++) {
            uint256 boxBalance = moneyBoxesModule.getBalanceOfBox(i, token);
            uint256 expectedBoxBalance = (safeBalanceBefore * boxConfiguration[i].percentage) / 100;
            assertEq(boxBalance, expectedBoxBalance);
        }
    }

    function test_transferFromSafeToBoxes_nativeToken() public {
        parameterized_test_transferFromSafeToBoxes(address(0));
    }

    function test_transferFromSafeToBoxes_ERC20() public {
        parameterized_test_transferFromSafeToBoxes(address(erc20Token));
    }

    function test_transferFromSafeToBoxes_revert_if_not_owner() public {
        uint256 safeBalanceBefore = getTokenBalance(address(safe), address(0));

        setUpNotOwnerTest();
        moneyBoxesModule.transferFromSafeToBoxes(safeBalanceBefore, address(0));
    }
}
