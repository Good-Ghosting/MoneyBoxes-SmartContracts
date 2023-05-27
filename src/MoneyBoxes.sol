// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Safe.sol";
import "./IERC20.sol";
import "forge-std/console2.sol";

contract MoneyBoxesModule {
    // added box percentage should be between 0 and 100
    error InvalidBoxPercentage();

    // native or erc20 token transfer failed
    error TokenTransferReverted();

    // not enough funds in box for withdraw operation
    error NotEnoughFundsInBox(uint256 boxIndex, uint256 amount);

    // Invalid safe address
    error InvalidSafeAddress();

    struct MoneyBoxConfiguration {
        uint256 percentage;
        string name;
        bool isActive;
    }

    struct MoneyBox {
        MoneyBoxConfiguration config;
        //Zero address is used for contract balance
        mapping(address => uint256) boxBalance;
    }

    string public constant NAME = "Money Box Module";
    string public constant VERSION = "0.0.1";

    MoneyBox[] public boxes;

    Safe public immutable safeAddress;

    receive() external payable {}

    fallback() external payable {}

    constructor(address _safeAddress, MoneyBoxConfiguration[] memory _boxesConfiguration) {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _boxesConfiguration.length; i++) {
            totalPercentage += _boxesConfiguration[i].percentage;
            boxes.push().config = _boxesConfiguration[i];
        }

        if (totalPercentage > 100 || totalPercentage == 0) {
            revert InvalidBoxPercentage();
        }

        if (_safeAddress == address(0)) {
            revert InvalidSafeAddress();
        }

        safeAddress = Safe(_safeAddress);
    }

    function transferFromSafeToBoxes(uint256 amount, address token) external {
        uint256 totalAmountToTransfer = 0;

        for (uint256 i = 0; i < boxes.length; i++) {
            uint256 boxAmount = (boxes[i].config.percentage * amount) / 100;

            boxes[i].boxBalance[token] += boxAmount;
            totalAmountToTransfer += boxAmount;
        }

        bool result;
        if (token == address(0)) {
            result =
                safeAddress.execTransactionFromModule(address(this), totalAmountToTransfer, "", Enum.Operation.Call);
        } else {
            bytes memory data =
                abi.encodeWithSignature("transfer(address,uint256)", address(this), totalAmountToTransfer);
            result = safeAddress.execTransactionFromModule(token, 0, data, Enum.Operation.Call);
        }

        if (!result) {
            revert TokenTransferReverted();
        }
    }

    function _boxHasEnoughBalance(uint256 boxIndex, uint256 amount, address token) internal view {
        if (boxes[boxIndex].boxBalance[token] < amount) {
            revert NotEnoughFundsInBox(boxIndex, amount);
        }
    }

    function _transferFromBoxesToAddress(uint256 amount, address token, address toAddress) internal {
        bool result;
        if (token == address(0)) {
            console2.log("amount to transfer", amount);
            (result,) = address(toAddress).call{value: amount}("");
        } else {
            result = IERC20(token).transfer(address(toAddress), amount);
        }

        if (!result) {
            revert TokenTransferReverted();
        }
    }

    function transferFromBoxToSafe(uint256 boxIndex, uint256 amount, address token) external {
        _boxHasEnoughBalance(boxIndex, amount, token);

        boxes[boxIndex].boxBalance[token] -= amount;
        _transferFromBoxesToAddress(amount, token, address(safeAddress));
    }

    function transferFromBoxToBox(uint256 fromBoxId, uint256 toBoxId, uint256 amount, address token) external {
        _boxHasEnoughBalance(fromBoxId, amount, token);

        boxes[fromBoxId].boxBalance[token] -= amount;
        boxes[toBoxId].boxBalance[token] += amount;
    }

    function getBalanceOfBox(uint256 boxId, address token) public view returns (uint256) {
        return boxes[boxId].boxBalance[token];
    }

    function withdrawFromBoxToAddress(uint256 boxIndex, uint256 amount, address token, address toAddress) external {
        _boxHasEnoughBalance(boxIndex, amount, token);

        boxes[boxIndex].boxBalance[token] -= amount;
        _transferFromBoxesToAddress(amount, token, toAddress);
    }
}
