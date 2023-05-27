// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MoneyBoxes.sol";
import "../src/Safe.sol";
import "forge-std/console2.sol";
import "openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MoneyBoxesModuleBaseTest is Test {
    MoneyBoxesModule public moneyBoxesModule;
    Safe public constant safe = Safe(0x57Ed8b808D7CF4a1C30F488EB34a4202E4be5109);

    ERC20PresetMinterPauser erc20Token;

    MoneyBoxesModule.MoneyBoxConfiguration[] boxConfiguration;

    function setUp() public virtual {
        boxConfiguration.push(MoneyBoxesModule.MoneyBoxConfiguration(10, "Box 1", true));
        boxConfiguration.push(MoneyBoxesModule.MoneyBoxConfiguration(20, "Box 2", true));
        boxConfiguration.push(MoneyBoxesModule.MoneyBoxConfiguration(30, "Box 3", true));

        moneyBoxesModule = new MoneyBoxesModule(address(safe),boxConfiguration);

        //Add module- using prank to bypass safe check
        vm.prank(address(safe));
        safe.enableModule(address(moneyBoxesModule));

        deployERC20();
    }

    function deployERC20() internal {
        ERC20PresetMinterPauser erc20 = new ERC20PresetMinterPauser("TestToken", "TST");
        erc20.mint(address(safe), 10000000000000000000);

        erc20Token = erc20;
    }

    function getTokenBalance(address from, address tokenAddress) internal view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(from).balance;
        } else {
            return IERC20(tokenAddress).balanceOf(address(from));
        }
    }

    receive() external payable {}
    fallback() external payable {}
}
