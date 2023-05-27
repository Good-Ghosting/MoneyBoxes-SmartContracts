// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./MoneyBoxes.transferFromBox.t.sol";

contract MoneyBoxesTransferFromBoxToBox is MoneyBoxesTransferFromBox {
    function parameterized_test_transferFromBoxToBox(address token) public {
        uint256 boxOneIndex = 0;
        uint256 boxTwoIndex = 1;

        uint256 boxOneBalanceBefore = moneyBoxesModule.getBalanceOfBox(boxOneIndex, token);
        uint256 boxTwoBalanceBefore = moneyBoxesModule.getBalanceOfBox(boxTwoIndex, token);

        moneyBoxesModule.transferFromBoxToBox(boxOneIndex, boxTwoIndex, boxOneBalanceBefore, token);

        uint256 boxOneBalanceAfter = moneyBoxesModule.getBalanceOfBox(boxOneIndex, token);
        uint256 boxTwoBalanceAfter = moneyBoxesModule.getBalanceOfBox(boxTwoIndex, token);

        assertNotEq(boxOneBalanceBefore, 0);
        assertEq(boxOneBalanceAfter, 0);
        assertEq(boxTwoBalanceAfter, boxTwoBalanceBefore + boxOneBalanceBefore);
    }

    function test_transferFromBoxToBox_nativeToken() public {
        parameterized_test_transferFromBoxToBox(address(0));
    }

    function test_transferFromBoxToBox_ERC20() public {
        parameterized_test_transferFromBoxToBox(address(erc20Token));
    }

    function test_transferFromBoxToBox_revert_if_not_enough_balance() public {
        uint256 boxOneIndex = 0;
        uint256 boxTwoIndex = 1;

        uint256 boxOneBalanceBefore = moneyBoxesModule.getBalanceOfBox(boxOneIndex, address(0));
        uint256 toTransferAmount = boxOneBalanceBefore + 1;

        assertGt(toTransferAmount, boxOneBalanceBefore);

        vm.expectRevert(
            abi.encodeWithSelector(MoneyBoxesModule.NotEnoughFundsInBox.selector, boxOneIndex, toTransferAmount)
        );
        moneyBoxesModule.transferFromBoxToBox(boxOneIndex, boxTwoIndex, toTransferAmount, address(0));
    }
}
