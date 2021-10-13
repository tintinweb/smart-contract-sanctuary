// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract SeaBattle is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    mapping(address => uint256) private airdropList;

    address public addressForMarketing;
    address public addressForFee;
    
    uint256 public tokensSupply = 100000000 * 10 ** 9;
    uint256 public tokensForMarketing = 8000000 * 10 ** 9;
    uint256 public tokensForAirdrop   = 5000000 * 10 ** 9;

    // Anti bot-trade
    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotAmount = 1;

    mapping(address => bool)    botAddresses;
    mapping(address => uint256) public botTransactionTime;
    
    // Transfer fee
    uint256 public feeForSell = 3;
    uint256 public feeForBuy = 3;
    mapping(address => bool) excludedFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    constructor() ERC20("SeaBattle", "SBT") {
        addressForMarketing = 0x231782a90dd2eE0B9d64b8c9C5fe9c7C6c3E1635;
        addressForFee = 0x1acFe19a1FFc1366BA655B9C6d6afaA7fe804021;

        _mint(_msgSender(), tokensSupply.sub(tokensForAirdrop).sub(tokensForMarketing));
        _mint(addressForMarketing, tokensForMarketing);
        _mint(address(this), tokensForAirdrop);

        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IUniswapV2Factory  _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        uniswapV2Pair   = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function addAirdrop(address[] memory to, uint256[] memory amount)
        public
        onlyOwner
    {
        require(to.length == amount.length, "Invalid arguments");

        for (uint256 index = 0; index < to.length; index++) {
            airdropList[address(to[index])] = amount[index];
        }
    }

    function setAddressForMarketing(address _address) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");

        addressForMarketing = _address;
    }

    function setAddressForFee(address _address) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");

        addressForFee = _address;
    }
    
    function setExcludedFee (address[] memory _addresses, bool _isExcluded) external onlyOwner {
        require(_addresses.length > 0);

        for (uint256 index = 0; index < _addresses.length; index++) {
            excludedFee[address(_addresses[index])] = _isExcluded;
        }
    }
    
    function setFeeForSell (uint256 _feeForSell) external onlyOwner {
        require(_feeForSell < 10, 'Cannot set fee for sell more than 10%');
        
        feeForSell = _feeForSell;
    }
    
    function setFeeForBuy (uint256 _feeForBuy) external onlyOwner {
        require(_feeForBuy < 10, 'Cannot set fee for buy more than 10%');
        
        feeForBuy = _feeForBuy;
    }

    /**
     * Allows users to claim tokens from an airdrop.
     */
    function claimAirdrop () public {
        require(airdropList[_msgSender()] > 0, "It's not possible to claim an airdrop at this address.");
        require(balanceOf(address(this)) >= airdropList[_msgSender()], "The amount of tokens available for the airdrop has been exhausted.");
        
        _transfer(address(this), _msgSender(), airdropList[_msgSender()]);
        airdropList[_msgSender()] = 0;
    }

    function setBotAddresses (address[] memory _addresses, bool _isBot) external onlyOwner {
        require(_addresses.length > 0);

        for (uint256 index = 0; index < _addresses.length; index++) {
            botAddresses[address(_addresses[index])] = _isBot;
        }
    }

    function setAntiBotEnabled (bool _enabled) external onlyOwner {
        antiBotEnabled = _enabled;
    }
    
    /**
     * Add a bot prevention feature by overriding the _transfer function.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (antiBotEnabled && botAddresses[sender]) {
            if (botTransactionTime[sender] + antiBotDuration > block.timestamp) {
                revert("Anti Bot");
            }

            uint256 balance = balanceOf(sender);
            uint256 maxAmount = balance.mul(antiBotAmount).div(100);

            if (amount > maxAmount) {
                revert("Anti Bot");
            }
            
            botTransactionTime[sender] = block.timestamp;
        }

        uint256 feeRate = recipient == uniswapV2Pair
            ? feeForSell
            : (sender == uniswapV2Pair ? feeForBuy : 0);

        if (excludedFee[sender]) {
            feeRate = 0;
        }

        if (
            feeRate > 0 &&
            sender != address(this) &&
            recipient != address(this)
        ) {
            uint256 _fee = amount.mul(feeRate).div(100);
            super._transfer(sender, addressForFee, _fee);
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function rescue(address _token) external onlyOwner {
        uint256 _amount = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransfer(owner(), _amount);
    }
    
    // receive eth from uniswap swap
    receive() external payable {}
}