// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./MoneyBoxes.transferFromBox.t.sol";

contract MoneyBoxesTransferFromBoxToSafe is MoneyBoxesTransferFromBox {
    function parameterized_test_transferFromBoxToSafe(address token, uint256 boxIndex) internal {
        uint256 safeBalanceBefore = getTokenBalance(address(safe), token);
        uint256 boxBalanceBefore = moneyBoxesModule.getBalanceOfBox(boxIndex, token);

        moneyBoxesModule.transferFromBoxToSafe(boxIndex, boxBalanceBefore, token);

        uint256 boxBalanceAfter = moneyBoxesModule.getBalanceOfBox(boxIndex, token);
        uint256 safeBalanceAfter = getTokenBalance(address(safe), token);

        uint256 safeBalanceDifference = safeBalanceAfter - safeBalanceBefore;

        assertNotEq(boxBalanceBefore, 0);
        assertEq(safeBalanceDifference, boxBalanceBefore);
        assertEq(boxBalanceAfter, 0);
    }

    function test_transferFromBoxToSafe_nativeToken() public {
        parameterized_test_transferFromBoxToSafe(address(0), 0);
        parameterized_test_transferFromBoxToSafe(address(0), 1);
        parameterized_test_transferFromBoxToSafe(address(0), 2);
    }

    function test_transferFromBoxToSafe_ERC20() public {
        parameterized_test_transferFromBoxToSafe(address(erc20Token), 0);
        parameterized_test_transferFromBoxToSafe(address(erc20Token), 1);
        parameterized_test_transferFromBoxToSafe(address(erc20Token), 2);
    }

    function test_transferFromBoxToSafe_revert_if_not_enough_balance() public {
        uint256 boxIndex = 0;
        uint256 boxBalance = moneyBoxesModule.getBalanceOfBox(boxIndex, address(0));

        uint256 toTransferAmount = boxBalance + 1;
        assertGt(toTransferAmount, boxBalance);

        vm.expectRevert(
            abi.encodeWithSelector(MoneyBoxesModule.NotEnoughFundsInBox.selector, boxIndex, toTransferAmount)
        );

        moneyBoxesModule.transferFromBoxToSafe(boxIndex, toTransferAmount, address(0));
    }

    function test_transferFromBoxToSafe_revert_if_not_owner() public {
        uint256 boxIndex = 0;
        address erc20Token = address(erc20Token);

        uint256 boxBalanceBefore = moneyBoxesModule.getBalanceOfBox(boxIndex, erc20Token);

        setUpNotOwnerTest();
        moneyBoxesModule.transferFromBoxToSafe(boxIndex, boxBalanceBefore, erc20Token);
    }
}
