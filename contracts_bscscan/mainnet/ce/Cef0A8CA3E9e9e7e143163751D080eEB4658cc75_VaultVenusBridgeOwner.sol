// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./WhitelistUpgradeable.sol";
import "./SafeToken.sol";

import "./IPancakeRouter02.sol";
import "./IVenusDistribution.sol";
import "./VaultVenusBridge.sol";


contract VaultVenusBridgeOwner is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IPancakeRouter02 private constant PANCAKE_ROUTER = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IVenusDistribution private constant VENUS_UNITROLLER = IVenusDistribution(0xfD36E2c2a6789Db23113685031d7F16329158384);
    VaultVenusBridge private constant VENUS_BRIDGE = VaultVenusBridge(0x8e58C983fe27c559403b1a8eA09c81f3B2d9eFcF); // require mainnet

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 private constant XVS = IBEP20(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        XVS.safeApprove(address(PANCAKE_ROUTER), uint(- 1));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addVaultBehalf(address vault, address token, address vToken) public onlyOwner {
        VENUS_BRIDGE.addVault(vault, token, vToken);
        VENUS_BRIDGE.setWhitelist(vault, true);
    }

    function setWhitelistBehalf(address _address, bool _on) external onlyOwner {
        VENUS_BRIDGE.setWhitelist(_address, _on);
    }

    function deposit(address vault, uint amount) external payable onlyOwner {
        VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
        address[] memory vTokens = new address[](1);
        vTokens[0] = market.vToken;
        if (market.token == WBNB) {
            amount = msg.value;
            VENUS_BRIDGE.deposit{value : amount}(vault, amount);
        } else {
            IBEP20(market.token).safeTransferFrom(owner(), address(VENUS_BRIDGE), amount);
            VENUS_BRIDGE.deposit(vault, amount);
        }
    }

    function harvestBehalf(address vault) public onlyWhitelisted {
        VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
        address[] memory vTokens = new address[](1);
        vTokens[0] = market.vToken;

        uint xvsBefore = XVS.balanceOf(address(VENUS_BRIDGE));
        VENUS_UNITROLLER.claimVenus(address(VENUS_BRIDGE), vTokens);
        uint xvsBalance = XVS.balanceOf(address(VENUS_BRIDGE)).sub(xvsBefore);

        if (xvsBalance > 0) {
            VENUS_BRIDGE.recoverToken(address(XVS), xvsBalance);
            if (market.token == WBNB) {
                uint swapBefore = address(this).balance;
                address[] memory path = new address[](2);
                path[0] = address(XVS);
                path[1] = WBNB;
                PANCAKE_ROUTER.swapExactTokensForETH(xvsBalance, 0, path, address(this), block.timestamp);

                uint swapAmount = address(this).balance.sub(swapBefore);
                VENUS_BRIDGE.deposit{value : swapAmount}(vault, swapAmount);
            } else {
                uint swapBefore = IBEP20(market.token).balanceOf(address(this));
                address[] memory path = new address[](3);
                path[0] = address(XVS);
                path[1] = WBNB;
                path[2] = market.token;
                PANCAKE_ROUTER.swapExactTokensForTokens(xvsBalance, 0, path, address(this), block.timestamp);

                uint swapAmount = IBEP20(market.token).balanceOf(address(this)).sub(swapBefore);
                IBEP20(market.token).safeTransfer(address(VENUS_BRIDGE), swapAmount);
                VENUS_BRIDGE.deposit(vault, swapAmount);
            }
        }
    }
}