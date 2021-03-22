// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC20Mintable.sol";

import "./ISetToken.sol";
import "./IBasicIssuanceModule.sol";
import "./IUniswapV2.sol";

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Logic.sol";

contract Migrator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public constant dpi = IERC20(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b);
    IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapV2Pair public constant univ2_dpi = IUniswapV2Pair(0x4d5ef58aAc27d99935E5b6B4A6778ff292059991);

    IBasicIssuanceModule public constant dpi_issuer = IBasicIssuanceModule(0xd8EF3cACe8b4907117a45B0b125c68560532F94D);

    IUniswapV2Factory public constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Factory public constant sushiswapFactory = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

    IUniswapV2Router02 public constant sushiswapRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Router02 public constant uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public governance;
    address public masterchef;

    // New bdpi token
    Logic public bdpi;

    /// @notice Migrates DPI token
    /// @param  _masterchef  Address of the masterchef contract
    /// @param  _bdpi Address of the basket dpi
    constructor(
        address _governance,
        address _masterchef,
        address _bdpi
    ) {
        masterchef = _masterchef;
        governance = _governance;

        bdpi = Logic(_bdpi);
    }

    modifier onlyMasterchef() {
        require(msg.sender == masterchef, "!masterchef");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /// @notice Rescues trapped ERC20 tokens
    /// @param  _asset  Token to migrate
    /// @param  _amount Amount to transfer
    function rescueERC20(address _asset, uint256 _amount) external onlyGovernance {
        IERC20(_asset).safeTransfer(msg.sender, _amount);
    }

    /// @notice Migrates DPI/LP token
    /// @param  _token  Token to migrate
    /// @return (address of the new token)
    function migrate(address _token) external onlyMasterchef returns (address) {
        if (_token == address(dpi)) {
            return _migrateDPI();
        }

        if (_token == address(univ2_dpi)) {
            return _migrateUNIV2DPI();
        }

        revert("!valid-token");
    }

    // **** Internal functions **** //

    /// @notice Redeems DPI token from underlying and wraps them into bdpi
    /// @param  _amount Amount of DPI to redeem
    function _redeemDPIAndWrapIntoBDPI(uint256 _amount) internal {
        // Redeem them from DPI Basic Issuance Module
        dpi.approve(address(dpi_issuer), _amount);
        dpi_issuer.redeem(address(dpi), _amount, address(this));

        // Get all components
        address[] memory dpi_components = ISetToken(address(dpi)).getComponents();
        uint256[] memory amounts_in = new uint256[](dpi_components.length);

        IERC20 currentComponent;
        uint256 currentComponentBalance;

        // Approve
        for (uint256 i = 0; i < dpi_components.length; i++) {
            currentComponent = IERC20(dpi_components[i]);
            currentComponentBalance = currentComponent.balanceOf(address(this));

            // Approve bdpi to take it
            currentComponent.approve(address(bdpi), currentComponentBalance);

            // Logs balance
            amounts_in[i] = currentComponentBalance;
        }

        // Initial Mint
        bdpi.mintExact(dpi_components, amounts_in, _amount);
    }

    /// @notice Migrates all DPI tokens from masterchef
    function _migrateDPI() internal returns (address) {
        // Balance of the token
        uint256 bal = dpi.balanceOf(masterchef);

        // Get tokens from master chef
        dpi.safeTransferFrom(masterchef, address(this), bal);

        // Unwrap underlying and convert dpi to bdpi
        _redeemDPIAndWrapIntoBDPI(bal);

        // Transfer to masterchef
        bdpi.transfer(masterchef, bal);

        return address(bdpi);
    }

    /// @notice Migrates all UNI-WETH lp tokens from uniswap to sushiswap
    function _migrateUNIV2DPI() internal returns (address) {
        // Original liquidity and tokens
        uint256 lpBal = univ2_dpi.balanceOf(masterchef);

        // Get tokens from master chef
        IERC20(address(univ2_dpi)).safeTransferFrom(masterchef, address(this), lpBal);

        // Remove liquidity from uniswap
        univ2_dpi.approve(address(uniswapRouter), lpBal);
        uniswapRouter.removeLiquidity(address(weth), address(dpi), lpBal, 0, 0, address(this), block.timestamp + 60);

        // Get token balances
        uint256 dpiBal = dpi.balanceOf(address(this));
        uint256 wethBal = weth.balanceOf(address(this));

        // Unwrap underlying and convert dpi to bdpi
        _redeemDPIAndWrapIntoBDPI(dpiBal);

        // Resupply LP to sushiswap
        bdpi.approve(address(sushiswapRouter), dpiBal);
        weth.approve(address(sushiswapRouter), wethBal);

        if (sushiswapFactory.getPair(address(bdpi), address(weth)) == address(0)) {
            sushiswapFactory.createPair(address(bdpi), address(weth));
        }

        // New sushiswap LP token address
        address sushi_bdpi = sushiswapFactory.getPair(address(bdpi), address(weth));

        sushiswapRouter.addLiquidity(
            address(bdpi),
            address(weth),
            dpiBal,
            wethBal,
            dpiBal,
            wethBal,
            address(this),
            block.timestamp + 60
        );

        // Transfer to masterchef
        IERC20(sushi_bdpi).transfer(masterchef, lpBal);

        // Return address
        return sushi_bdpi;
    }
}