// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./MoneyBoxes.transferFromBox.t.sol";

contract MoneyBoxesTransferFromBoxToAddress is MoneyBoxesTransferFromBox {
    address public constant TO_ADDRESS = 0x0E94569Aac75Bfafd157E27f2EC7aeA31c93466D;

    function parameterized_test_transferFromBoxToAddress(address token, uint256 boxIndex, address toAddress) internal {
        uint256 toAddressBalanceBefore = getTokenBalance(toAddress, token);
        uint256 boxBalanceBefore = moneyBoxesModule.getBalanceOfBox(boxIndex, token);

        moneyBoxesModule.transferFromBoxToAddress(boxIndex, boxBalanceBefore, token, toAddress);

        uint256 boxBalanceAfter = moneyBoxesModule.getBalanceOfBox(boxIndex, token);
        uint256 toAddressBalanceAfter = getTokenBalance(toAddress, token);

        uint256 toAddressBalanceDifference = toAddressBalanceAfter - toAddressBalanceBefore;

        assertNotEq(boxBalanceBefore, 0);
        assertEq(toAddressBalanceDifference, boxBalanceBefore);
        assertEq(boxBalanceAfter, 0);
    }

    function test_transferFromBoxToAddress_nativeToken() public {
        parameterized_test_transferFromBoxToAddress(address(0), 0, TO_ADDRESS);
        parameterized_test_transferFromBoxToAddress(address(0), 1, TO_ADDRESS);
        parameterized_test_transferFromBoxToAddress(address(0), 2, TO_ADDRESS);
    }

    function test_transferFromBoxToAddress_ERC20() public {
        parameterized_test_transferFromBoxToAddress(address(erc20Token), 0, TO_ADDRESS);
        parameterized_test_transferFromBoxToAddress(address(erc20Token), 1, TO_ADDRESS);
        parameterized_test_transferFromBoxToAddress(address(erc20Token), 2, TO_ADDRESS);
    }

    function test_transferFromBoxToAddress_revert_if_not_enough_balance() public {
        uint256 boxIndex = 0;
        uint256 boxBalance = moneyBoxesModule.getBalanceOfBox(boxIndex, address(0));

        uint256 toTransferAmount = boxBalance + 1;
        assertGt(toTransferAmount, boxBalance);

        vm.expectRevert(
            abi.encodeWithSelector(MoneyBoxesModule.NotEnoughFundsInBox.selector, boxIndex, toTransferAmount)
        );

        moneyBoxesModule.transferFromBoxToAddress(boxIndex, toTransferAmount, address(0), TO_ADDRESS);
    }

    function test_transferFromBoxToAddress_revert_if_not_owner() public {
        uint256 boxIndex = 0;

        setUpNotOwnerTest();
        moneyBoxesModule.transferFromBoxToAddress(boxIndex, 10, address(0), TO_ADDRESS);
    }
}
