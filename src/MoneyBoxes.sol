// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Safe.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "forge-std/console2.sol";

/// @title Good Ghosting Badge NFTs
/// @author camolezi
/* @notice Using owner for now, but should move to SignatureDecoder */
contract MoneyBoxesModule is Ownable {
    ///@dev added box percentage should be between 0 and 100
    error InvalidBoxPercentage();

    ///@dev number of boxes should be between 1 and 10
    error InvalidNumberOfBoxes();

    ///@dev native or erc20 token transfer failed
    error TokenTransferReverted();

    ///@dev not enough funds in box for withdraw operation
    error NotEnoughFundsInBox(uint256 boxIndex, uint256 amount);

    ///@dev Invalid safe address
    error InvalidSafeAddress();

    ///@dev When trying to transfer unaccounted funds to safe, but there are no unaccounted funds
    error AmountIsAlreadyAccountedFor();

    /**
     * @dev MoneyBoxConfiguration, used to configure the money boxes behavior
     * @param percentage percentage of the total amount that will be allocated to this box
     * @param name box name
     * @param isActive (not used yet) if box is active or not
     */
    struct MoneyBoxConfiguration {
        uint256 percentage;
        string name;
        bool isActive;
    }

    /**
     * @dev MoneyBox, used to store the box balance and configuration
     * @param config box configuration
     * @param boxBalance box balance
     */
    struct MoneyBox {
        MoneyBoxConfiguration config;
        //Zero address is used for contract balance
        mapping(address => uint256) boxBalance;
    }

    string public constant NAME = "Money Box Module";
    string public constant VERSION = "0.0.1";

    MoneyBox[] public boxes;

    Safe public immutable safeAddress;

    /**
     * @dev Initialize contract state
     * @param _safeAddress address of the Safe contract
     * @param _boxesConfiguration initial configuration for the boxes
     */
    constructor(address _safeAddress, MoneyBoxConfiguration[] memory _boxesConfiguration) {
        if (_boxesConfiguration.length < 1 || _boxesConfiguration.length > 10) {
            revert InvalidNumberOfBoxes();
        }

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

    /**
     * @dev Verify if the box has enough balance to cover a certain amount
     * @param boxIndex index of the box
     * @param amount amount to verify
     * @param token address of the token, use 0x0 for native token
     */
    function _boxHasEnoughBalance(uint256 boxIndex, uint256 amount, address token) internal view {
        if (boxes[boxIndex].boxBalance[token] < amount) {
            revert NotEnoughFundsInBox(boxIndex, amount);
        }
    }

    /**
     * @dev Safely transfer tokens or Native token to a specific address
     * @param amount amount to transfer
     * @param token address of the token to transfer, use 0x0 for native token
     * @param toAddress address to transfer to
     */
    function _transferFromBoxesToAddress(uint256 amount, address token, address toAddress) internal {
        bool result;
        if (token == address(0)) {
            (result,) = address(toAddress).call{value: amount}("");
        } else {
            result = IERC20(token).transfer(address(toAddress), amount);
        }

        if (!result) {
            revert TokenTransferReverted();
        }
    }

    /**
     * @notice Get the balance of a token in a box
     * @param boxId ID of the box
     * @param token Address of the token, use 0x0 for native token
     * @return The balance of the token in the box with boxId
     */
    function getBalanceOfBox(uint256 boxId, address token) public view returns (uint256) {
        return boxes[boxId].boxBalance[token];
    }

    /**
     * @notice Get the total number of boxes
     * @return The total number of boxes
     */
    function getNumberOfBoxes() public view returns (uint256) {
        return boxes.length;
    }

    /**
     * @notice Transfer funds from the safe to the boxes and distribute them according to the boxes configuration
     * @param amount The amount to transfer from safe
     * @param token The address of the token to transfer , use 0x0 for native token
     */
    function transferFromSafeToBoxes(uint256 amount, address token) external onlyOwner {
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

    /**
     * @notice Transfer funds from a box back to the safe
     * @param boxIndex The index of the box
     * @param amount The amount to transfer
     * @param token The address of the token to transfer , use 0x0 for native token
     */
    function transferFromBoxToSafe(uint256 boxIndex, uint256 amount, address token) external onlyOwner {
        _boxHasEnoughBalance(boxIndex, amount, token);

        boxes[boxIndex].boxBalance[token] -= amount;
        _transferFromBoxesToAddress(amount, token, address(safeAddress));
    }

    /**
     * @notice Transfer funds from one box to another
     * @param fromBoxId The ID of the box to transfer from
     * @param toBoxId The ID of the box to transfer to
     * @param amount The amount to transfer
     * @param token The address of the token to transfer , use 0x0 for native token
     */
    function transferFromBoxToBox(uint256 fromBoxId, uint256 toBoxId, uint256 amount, address token)
        external
        onlyOwner
    {
        _boxHasEnoughBalance(fromBoxId, amount, token);

        boxes[fromBoxId].boxBalance[token] -= amount;
        boxes[toBoxId].boxBalance[token] += amount;
    }

    /**
     * @notice Transfer funds from a box to a given address
     * @param boxIndex The index of the box
     * @param amount The amount to transfer
     * @param token The address of the token to transfer , use 0x0 for native token
     * @param toAddress The address to transfer the funds to
     */
    function transferFromBoxToAddress(uint256 boxIndex, uint256 amount, address token, address toAddress)
        external
        onlyOwner
    {
        _boxHasEnoughBalance(boxIndex, amount, token);

        boxes[boxIndex].boxBalance[token] -= amount;
        _transferFromBoxesToAddress(amount, token, toAddress);
    }

    /**
     * @notice Transfer funds that were sent directly to the contract (not accounted for) to the safe
     * @notice Should be used if funds are sent directly to the contract without using the transferFromSafeToBoxes function
     * @param token The address of the token to transfer
     */
    function transferNotAccountedFundsToSafe(address token) external onlyOwner {
        uint256 totalAmountAccounted = 0;
        for (uint256 i = 0; i < boxes.length; i++) {
            totalAmountAccounted += boxes[i].boxBalance[token];
        }

        uint256 totalAmountInTheContract =
            token == address(0) ? address(this).balance : IERC20(token).balanceOf(address(this));

        if (totalAmountAccounted >= totalAmountInTheContract) {
            revert AmountIsAlreadyAccountedFor();
        }

        uint256 totalAmountToTransfer = totalAmountInTheContract - totalAmountAccounted;
        _transferFromBoxesToAddress(totalAmountToTransfer, token, address(safeAddress));
    }

    receive() external payable {}
    fallback() external payable {}
}
