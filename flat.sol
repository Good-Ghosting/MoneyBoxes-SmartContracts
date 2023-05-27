// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Safe {}

contract MoneyBoxesModule {
    //Starting gnosis module

    string public constant NAME = "Money Box Module";
    string public constant VERSION = "0.0.1";

    uint256[] public box_configuration = [30, 30, 40];

    Safe public constant safeAddress = Safe(0x57Ed8b808D7CF4a1C30F488EB34a4202E4be5109);

    function getBalance() public view returns (uint256) {
        //get balance from safe
        return address(safeAddress).balance;
    }
}
