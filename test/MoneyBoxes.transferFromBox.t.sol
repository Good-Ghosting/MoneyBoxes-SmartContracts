// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./MoneyBoxes.base.t.sol";

contract MoneyBoxesTransferFromBox is MoneyBoxesModuleBaseTest {
    function setUp() public virtual override {
        MoneyBoxesModuleBaseTest.setUp();

        //start with fund in boxes
        uint256 safeBalanceNative = getTokenBalance(address(safe), address(0));
        moneyBoxesModule.transferFromSafeToBoxes(safeBalanceNative, address(0));

        uint256 safeBalanceERC20 = getTokenBalance(address(safe), address(erc20Token));
        moneyBoxesModule.transferFromSafeToBoxes(safeBalanceERC20, address(erc20Token));
    }
}
