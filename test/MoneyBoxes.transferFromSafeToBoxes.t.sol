// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";

import "./MoneyBoxes.base.t.sol";

contract MoneyBoxesTransferFromSafeToBox is MoneyBoxesModuleBaseTest {
    function printBoxesValues() internal {
        uint256 allBoxesBalance = address(moneyBoxesModule).balance;
        uint256 box1Balance = moneyBoxesModule.getBalanceOfBox(0, address(0));
        uint256 box2Balance = moneyBoxesModule.getBalanceOfBox(1, address(0));
        uint256 box3Balance = moneyBoxesModule.getBalanceOfBox(2, address(0));
        console.log("Boxes ");
        console.log("allBoxesBalance", allBoxesBalance);
        console.log("box1Balance", box1Balance);
        console.log("box2Balance", box2Balance);
        console.log("box3Balance", box3Balance);
    }

    function getBoxesPercentageSum() internal view returns (uint256) {
        uint256 percentageSum = 0;
        for (uint256 i = 0; i < boxConfiguration.length; i++) {
            percentageSum += boxConfiguration[i].percentage;
        }
        return percentageSum;
    }

    function test_transferFromSafeToBoxes_nativeToken() public {
        uint256 safeBalanceBefore = address(safe).balance;

        moneyBoxesModule.transferFromSafeToBoxes(safeBalanceBefore, address(0));

        uint256 safeBalanceAfter = address(safe).balance;
        uint256 safeBalanceDifferece = safeBalanceBefore - safeBalanceAfter;

        uint256 totalBoxesPercentage = getBoxesPercentageSum();
        uint256 expectedBalanceDifference = (safeBalanceBefore * totalBoxesPercentage) / 100;

        assertEq(safeBalanceDifferece, expectedBalanceDifference);
    }

    function test_transferFromSafeToBoxes_ERC20() public {
        uint256 safeBalanceBefore = address(safe).balance;

        moneyBoxesModule.transferFromSafeToBoxes(safeBalanceBefore, address(0));

        uint256 safeBalanceAfter = address(safe).balance;
        uint256 safeBalanceDifferece = safeBalanceBefore - safeBalanceAfter;

        uint256 totalBoxesPercentage = getBoxesPercentageSum();
        uint256 expectedBalanceDifference = (safeBalanceBefore * totalBoxesPercentage) / 100;

        assertEq(safeBalanceDifferece, expectedBalanceDifference);
    }
}
