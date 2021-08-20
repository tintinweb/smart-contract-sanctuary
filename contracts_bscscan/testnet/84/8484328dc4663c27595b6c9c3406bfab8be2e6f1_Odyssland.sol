// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ReentrancyGuard.sol";
import "./Uniswap.sol";
import "./OdysslandFeature.sol";

contract Odyssland is OdysslandFeature, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) bots;
    uint256 public maxSupply = 100 * 10**6 * 10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;

    constructor(string memory name, string memory symbol)
        OdysslandFeature(name, symbol)
    {
        _mint(_msgSender(), maxSupply.sub(amountFarm).sub(amountPlayToEarn));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D    // uniswap ropsten testnet
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 // pancakeswap testnet
            //0x10ED43C718714eb63d5aA57B78B54704E256024E // pancakeswap mainnet
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
            revert("Odyssland: Please wait 10 minutes before transfer again."); 
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
            super._transfer(sender, address(this), _fee); // transfer fee
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function teamSwapToken() public nonReentrant {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenForTeam) {
            swapTokensForEth(tokenForTeam);
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
            teamWallet, // The contract
            block.timestamp
        );
    }

    function setTeamWalletAddress(address _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "Odyssland: 0x is not accepted here");

        teamWallet = _teamWallet;
    }

    function antiBot(uint256 amount) external onlyOwner {
        require(amount > 0, "Odyssland: not accept 0 value");
        require(!antiBotEnabled);

        antiBotAmount = amount;
        antiBotTime = block.timestamp.add(antiBotDuration);
        antiBotEnabled = true;
    }
}