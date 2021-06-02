// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

import "./IUniswapV2.sol";
import "./IWETH.sol";
import "./IBasket.sol";

import "./BDIMarketMaker.sol";

contract DelayedBurner is MarketMakerBurner {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Can only burn after 20 mins, and only has a 20 mins window to burn
    // 20 min window to burn
    uint256 public burnDelaySeconds = 1200;
    uint256 public maxBurnDelaySeconds = 2400;

    // Deployer
    address public governance;

    // User deposited
    mapping(address => uint256) public deposits;

    // When user deposited
    mapping(address => uint256) public timestampWhenDeposited;

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

    function setBurnDelaySeconds(uint256 _seconds) public onlyGov {
        burnDelaySeconds = _seconds;
    }

    function setMaxBurnDelaySeconds(uint256 _seconds) public onlyGov {
        maxBurnDelaySeconds = _seconds;
    }

    function setBlacklist(address _user, bool _b) public onlyGov {
        isBlacklisted[_user] = _b;
    }

    // **** Deposit **** //

    function deposit(uint256 _amount) public {
        IERC20(address(BDPI)).safeTransferFrom(msg.sender, address(this), _amount);

        deposits[msg.sender] = deposits[msg.sender].add(_amount);
        timestampWhenDeposited[msg.sender] = block.timestamp;
    }

    // **** Withdraw **** //

    function withdraw(uint256 _amount) public {
        deposits[msg.sender] = deposits[msg.sender].sub(_amount);

        IERC20(address(BDPI)).safeTransfer(msg.sender, _amount);
    }

    // **** Burn **** //

    function burn() public onlyEOA notBlacklisted returns (uint256[] memory) {
        uint256 _amount = deposits[msg.sender];

        require(_amount > 0, "!amount");
        require(_canBurn(timestampWhenDeposited[msg.sender]), "!timestamp");

        deposits[msg.sender] = 0;

        (address[] memory assets, ) = IBasket(BDPI).getAssetsAndBalances();
        uint256[] memory deltas = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this));
        }
        IBasket(BDPI).burn(_amount);
        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this)).sub(deltas[i]);
            IERC20(assets[i]).transfer(msg.sender, deltas[i]);
        }

        return deltas;
    }

    function burnToETH(address[] memory routers, uint256 _minETHAmount)
        public
        onlyEOA
        notBlacklisted
        returns (uint256)
    {
        uint256 _amount = deposits[msg.sender];

        require(_amount > 0, "!amount");
        require(_canBurn(timestampWhenDeposited[msg.sender]), "!timestamp");

        deposits[msg.sender] = 0;

        _burnToWETH(routers, _amount, 0);
        uint256 totalWETH = IERC20(WETH).balanceOf(address(this));
        require(totalWETH >= _minETHAmount, "!min-eth-amount");
        IWETH(WETH).withdraw(totalWETH);

        (bool success, ) = msg.sender.call{ value: totalWETH }("");
        require(success, "!eth-transfer");

        return totalWETH;
    }

    // **** Internals **** //

    function _canBurn(uint256 _depositTime) public view returns (bool) {
        return
            block.timestamp >= _depositTime + burnDelaySeconds && block.timestamp <= _depositTime + maxBurnDelaySeconds;
    }
}