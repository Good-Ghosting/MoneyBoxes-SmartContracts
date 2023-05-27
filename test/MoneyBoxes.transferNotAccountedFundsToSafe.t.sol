// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./MoneyBoxes.transferFromBox.t.sol";

contract MoneyBoxesTransferNotAccountedFundsToSafe is MoneyBoxesTransferFromBox {
    uint256 constant notAccountedForAmount = 15000000000000000000;

    function setUp() public override {
        MoneyBoxesTransferFromBox.setUp();

        //Send additional funds (not accounted) to boxes
        erc20Token.mint(address(moneyBoxesModule), notAccountedForAmount);
        payable(address(moneyBoxesModule)).transfer(notAccountedForAmount);
    }

    function parameterized_test_transferFromBoxToSafe(address token) internal {
        uint256 safeBalanceBefore = getTokenBalance(address(safe), token);
        uint256 boxesContractBalanceBefore = getTokenBalance(address(moneyBoxesModule), token);

        moneyBoxesModule.transferNotAccountedFundsToSafe(token);

        uint256 safeBalanceAfter = getTokenBalance(address(safe), token);
        uint256 boxesContractBalanceAfter = getTokenBalance(address(moneyBoxesModule), token);

        uint256 safeBalanceDifference = safeBalanceAfter - safeBalanceBefore;
        uint256 boxesContractBalanceDifference = boxesContractBalanceBefore - boxesContractBalanceAfter;

        assertEq(safeBalanceDifference, notAccountedForAmount);
        assertEq(boxesContractBalanceDifference, notAccountedForAmount);
    }

    function test_transferNotAccountedFundsToSafe_nativeToken() public {
        parameterized_test_transferFromBoxToSafe(address(0));
    }

    function test_transferNotAccountedFundsToSafe_ERC20() public {
        parameterized_test_transferFromBoxToSafe(address(erc20Token));
    }

    function parameterized_test_transferNotAccountedFundsToSafe_Amount_Already_Accounted(address token) public {
        //After this execution everything should be accounted for
        parameterized_test_transferFromBoxToSafe(token);

        //This should revert because there is nothing to transfer
        vm.expectRevert(MoneyBoxesModule.AmountIsAlreadyAccountedFor.selector);
        moneyBoxesModule.transferNotAccountedFundsToSafe(token);
    }

    function test_transferNotAccountedFundsToSafe_Amount_Already_Accounted_nativeToken() public {
        parameterized_test_transferNotAccountedFundsToSafe_Amount_Already_Accounted(address(0));
    }

    function test_transferNotAccountedFundsToSafe_Amount_Already_Accounted_ERC20() public {
        parameterized_test_transferNotAccountedFundsToSafe_Amount_Already_Accounted(address(erc20Token));
    }

    function test_transferNotAccountedFundsToSafe_revert_if_not_owner() public {
        setUpNotOwnerTest();
        moneyBoxesModule.transferNotAccountedFundsToSafe(address(0));
    }
}
