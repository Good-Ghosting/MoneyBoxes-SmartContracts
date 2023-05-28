// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./MoneyBoxes.sol";

//Can also use clone factory on the future
contract MoneyBoxesFactory {
    event MoneyBoxesCreated(address indexed moneyBox, address indexed owner);

    mapping(address => MoneyBoxesModule[]) public moneyBoxes;

    function createMoneyBoxesContract(
        address _safeAddress,
        MoneyBoxesModule.MoneyBoxConfiguration[] memory _boxesConfiguration
    ) external returns (MoneyBoxesModule) {
        MoneyBoxesModule moneyBox = new MoneyBoxesModule(_safeAddress, _boxesConfiguration);

        moneyBox.transferOwnership(msg.sender);

        moneyBoxes[msg.sender].push(moneyBox);
        emit MoneyBoxesCreated(address(moneyBox), msg.sender);
        return moneyBox;
    }

    function getUserLatestMoneyBox(address _user) external view returns (MoneyBoxesModule) {
        return moneyBoxes[_user][moneyBoxes[_user].length - 1];
    }
}
