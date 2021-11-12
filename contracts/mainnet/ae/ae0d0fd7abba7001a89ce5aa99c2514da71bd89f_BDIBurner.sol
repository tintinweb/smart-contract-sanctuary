// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

import "./IUniswapV2.sol";
import "./IWETH.sol";
import "./IBasket.sol";

import "./BDIMarketMaker.sol";

contract BDIBurner is MarketMakerBurner {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Deployer
    address public governance;

    // Blacklist
    mapping(address => bool) public isBlacklisted;

    constructor(address _governance) {
        governance = _governance;

        IERC20(WETH).safeApprove(SUSHISWAP_ROUTER, uint256(-1));
        IERC20(WETH).safeApprove(UNIV2_ROUTER, uint256(-1));
    }

    receive() external payable {}

    // **** Modifiers ****

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!eoa");
        _;
    }

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "blacklisted");
        _;
    }

    // **** Restricted functions ****

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    function rescueERC20(address _token) public onlyGov {
        require(_token != address(BDPI), "!bdpi");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(governance, _amount);
    }

    function rescueERC20s(address[] memory _tokens) public onlyGov {
        for (uint256 i = 0; i < _tokens.length; i++) {
            rescueERC20(_tokens[i]);
        }
    }

    // **** Burn **** //

    function burnToETH(
        uint256 _amount,
        address[] memory routers,
        bytes[] memory routerCalldata,
        address[] memory constituents,
        address[] memory underlyings,
        uint256[] memory underlyingsWeights,
        uint256 _minETHAmount
    ) public onlyEOA notBlacklisted returns (uint256) {
        require(_amount > 0, "!amount");

        IERC20(address(BDPI)).safeTransferFrom(msg.sender, address(this), _amount);

        // Memory
        bytes memory mmParams =
            abi.encode(
                MMParams({
                    routers: routers,
                    routerCalldata: routerCalldata,
                    constituents: constituents,
                    underlyings: underlyings,
                    underlyingsWeights: underlyingsWeights
                })
            );
            
        _burnBDIToWETH(_amount, mmParams);
        uint256 totalWETH = IERC20(WETH).balanceOf(address(this));
        require(totalWETH >= _minETHAmount, "!min-eth-amount");
        IWETH(WETH).withdraw(totalWETH);

        (bool success, ) = msg.sender.call{ value: totalWETH }("");
        require(success, "!eth-transfer");

        return totalWETH;
    }
}