// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

import "./IUniswapV2.sol";
import "./IWETH.sol";
import "./IBasket.sol";

import "./DelayedBurnerHelper.sol";

contract DelayedBurner is DelayedBurnerHelper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant BLOCK_DELAY = 5;

    // Deployer
    address public governance;

    // User deposited
    mapping(address => uint256) public deposits;

    // When user deposited
    mapping(address => uint256) public blockWhenDeposited;

    constructor(address _governance) {
        governance = _governance;
    }

    receive() external payable {}

    // **** Modifiers ****

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    // **** Restricted functions ****

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    function rescueERC20(address _token) public {
        require(_token != address(BDPI), "!bdpi");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(governance, _amount);
    }

    function rescueERC20s(address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            rescueERC20(_tokens[i]);
        }
    }

    // **** Deposit **** //

    function deposit(uint256 _amount) public {
        IERC20(BDPI).safeTransferFrom(msg.sender, address(this), _amount);

        deposits[msg.sender] = deposits[msg.sender].add(_amount);
        blockWhenDeposited[msg.sender] = block.number;
    }

    // **** Withdraw **** //

    function withdraw(uint256 _amount) public {
        deposits[msg.sender] = deposits[msg.sender].sub(_amount);

        IERC20(BDPI).safeTransfer(msg.sender, _amount);
    }

    // **** Burn **** //

    function burn() public returns (uint256[] memory) {
        uint256 _amount = deposits[msg.sender];

        require(_amount > 0, "!amount");
        require(block.number > blockWhenDeposited[msg.sender] + BLOCK_DELAY, "!block");

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

    function burnToETH(uint256 _minETHAmount) public returns (uint256) {
        uint256 _amount = deposits[msg.sender];

        require(_amount > 0, "!amount");
        require(block.number > blockWhenDeposited[msg.sender] + BLOCK_DELAY, "!block");

        deposits[msg.sender] = 0;

        (address[] memory underlyings, uint256[] memory underlyingAmounts) =
            _burnBDPIAndGetUnderlyingAndAmounts(_amount);

        // Convert underlying to WETH
        for (uint256 i = 0; i < underlyings.length; i++) {
            _swap(underlyings[i], WETH, underlyingAmounts[i], address(this));
        }
        uint256 totalWETH = IERC20(WETH).balanceOf(address(this));

        require(totalWETH >= _minETHAmount, "!min-eth-amount");
        IWETH(WETH).withdraw(totalWETH);

        (bool success, ) = msg.sender.call{ value: totalWETH }("");
        require(success, "!eth-transfer");

        return totalWETH;
    }

    // **** Internals **** //

    function _burnBDPIAndGetUnderlyingAndAmounts(uint256 _amount)
        internal
        returns (address[] memory, uint256[] memory)
    {
        (address[] memory assets, ) = IBasket(BDPI).getAssetsAndBalances();
        uint256[] memory deltas = new uint256[](assets.length);
        address[] memory underlyings = new address[](assets.length);
        uint256[] memory underlyingAmounts = new uint256[](assets.length);

        address underlying;
        uint256 underlyingAmount;

        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this));
        }
        IBasket(BDPI).burn(_amount);
        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this)).sub(deltas[i]);

            (underlying, underlyingAmount) = _toUnderlying(assets[i], deltas[i]);

            underlyings[i] = underlying;
            underlyingAmounts[i] = underlyingAmount;
        }

        return (underlyings, underlyingAmounts);
    }
}