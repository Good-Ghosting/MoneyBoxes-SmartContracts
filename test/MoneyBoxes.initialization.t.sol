// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MoneyBoxes.sol";

import "./MoneyBoxes.base.t.sol";

contract MoneyBoxesInitialization is MoneyBoxesModuleBaseTest {
    function createBoxesWithPercentage(uint256[] memory percentagesBoxes)
        internal
        pure
        returns (MoneyBoxesModule.MoneyBoxConfiguration[] memory)
    {
        MoneyBoxesModule.MoneyBoxConfiguration[] memory moneyBoxesConfigArray =
            new MoneyBoxesModule.MoneyBoxConfiguration[](percentagesBoxes.length);

        for (uint256 i = 0; i < percentagesBoxes.length; i++) {
            moneyBoxesConfigArray[i] = MoneyBoxesModule.MoneyBoxConfiguration(percentagesBoxes[i], vm.toString(i), true);
        }

        return moneyBoxesConfigArray;
    }

    function test_initialization_success() public {
        uint256[] memory percentagesBoxes = new uint256[](3);
        percentagesBoxes[0] = 10;
        percentagesBoxes[1] = 40;
        percentagesBoxes[2] = 20;

        MoneyBoxesModule.MoneyBoxConfiguration[] memory moneyBoxesConfigArray =
            createBoxesWithPercentage(percentagesBoxes);
        moneyBoxesModule = new MoneyBoxesModule(address(safe),moneyBoxesConfigArray);
    }

    function test_initialization_fail_percentage_sum_more_than_100() public {
        uint256[] memory percentagesBoxes = new uint256[](3);
        percentagesBoxes[0] = 21;
        percentagesBoxes[1] = 40;
        percentagesBoxes[2] = 40;

        MoneyBoxesModule.MoneyBoxConfiguration[] memory moneyBoxesConfigArray =
            createBoxesWithPercentage(percentagesBoxes);

        vm.expectRevert(MoneyBoxesModule.InvalidBoxPercentage.selector);
        moneyBoxesModule = new MoneyBoxesModule(address(safe),moneyBoxesConfigArray);
    }

    function test_initialization_fail_more_than_max_number_of_boxes() public {
        uint256[] memory percentagesBoxes = new uint256[](11);

        for (uint256 i = 0; i < percentagesBoxes.length; i++) {
            percentagesBoxes[i] = 1;
        }

        MoneyBoxesModule.MoneyBoxConfiguration[] memory moneyBoxesConfigArray =
            createBoxesWithPercentage(percentagesBoxes);

        vm.expectRevert(MoneyBoxesModule.InvalidNumberOfBoxes.selector);
        moneyBoxesModule = new MoneyBoxesModule(address(safe),moneyBoxesConfigArray);
    }

    function test_initialization_fail_zero_boxes() public {
        uint256[] memory percentagesBoxes = new uint256[](0);

        MoneyBoxesModule.MoneyBoxConfiguration[] memory moneyBoxesConfigArray =
            createBoxesWithPercentage(percentagesBoxes);

        vm.expectRevert(MoneyBoxesModule.InvalidNumberOfBoxes.selector);
        moneyBoxesModule = new MoneyBoxesModule(address(safe),moneyBoxesConfigArray);
    }

    function test_initialization_fail_safeAddress_zero() public {
        vm.expectRevert(MoneyBoxesModule.InvalidSafeAddress.selector);
        moneyBoxesModule = new MoneyBoxesModule(address(0),boxConfiguration);
    }
}
