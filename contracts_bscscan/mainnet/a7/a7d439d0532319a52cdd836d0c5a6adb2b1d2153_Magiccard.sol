// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Uniswap.sol";
import "./ReentrancyGuard.sol";
import "./Monster.sol";

contract Magiccard is Monster, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public maxSupply = 1000* 10**6 * 10**18;

    mapping (address => bool) private _isExcludedFromFees;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) bots;
    bool public blacklistEnabled;
    uint256 public blacklistDuration = 10 minutes;
    uint256 public blacklistTime;
    uint256 public blacklistAmount;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor(string memory name, string memory symbol)
        Monster(name, symbol)
    {
        excludeFromFees(owner(), true);
        
        //Mint only use for first deploy, farm and playToEarn, noone can control it.
        _mint(_msgSender(), maxSupply.sub(amountFarm).sub(amountPlayToEarn));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already 'excluded'");
        _isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    //Anti bots
    function setBlacklists(address _bots) external onlyOwner {
        require(!bots[_bots]);
        bots[_bots] = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            blacklistTime > block.timestamp &&
            amount > blacklistAmount &&
            bots[sender]
        ) {
            revert("You're bot");
        }

        uint256 transferFeeRate = recipient == uniswapV2Pair
            ? sellFeeRate
            : (sender == uniswapV2Pair ? buyFeeRate : 0);

        if (
            transferFeeRate > 0 &&
            sender != address(this) &&
            recipient != address(this) &&
            !_isExcludedFromFees[sender]
        ) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            super._transfer(sender, address(this), _fee); // Transfer fee to this token, we need money to mkt and alive
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function swapTokenForMkt() public nonReentrant {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenForMkt) {
            swapTokensForEth(tokenForMkt);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            addressForMkt, // Swap token for eth and transfer to mkt address
            block.timestamp
        );
    }

    // receive eth from uniswap swap
    receive() external payable {}

    function setAddressForMkt(address _addressForMkt) external onlyOwner {
        require(_addressForMkt != address(0), "invalid address");

        addressForMkt = _addressForMkt;
    }

    function blacklist(uint256 amount) external onlyOwner {
        require(amount > 0, "amount > 0");
        require(!blacklistEnabled);

        blacklistAmount = amount;
        blacklistTime = block.timestamp.add(blacklistDuration);
        blacklistEnabled = true;
    }
}