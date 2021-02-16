pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "this action is only for owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/*
   _________    __  _______  __    ____
  / ____/   |  /  |/  / __ )/ /   / __ \
 / / __/ /| | / /|_/ / __  / /   / /_/ /
/ /_/ / ___ |/ /  / / /_/ / /___/ _, _/
\____/_/  |_/_/  /_/_____/_____/_/ |_|

Gamblr.one is a nextgen community-driven gambling platform powered by blockchain technology

⚫ Texas Holdem Poker
⚫ Cash, Tournaments, Sit-n-Go, Speed Poker
⚫ Casino
⚫ Decentralized gambling network where games and profits belong to players

Features:

⚫ Cross-blockchain: Ethereum, EOS, Tron, WAX, Bitcoin and more
⚫ Cross-platform
⚫ Casual mode for non-blockchain players
⚫ Learn more on https://gamblr.one

Sale Stages:

+---------+-------+----------------+
|  Stage  | Bonus |      Date      |
+---------+-------+----------------+
| Presale |  30%  | until March 10 |
| Stage 1 |  20%  | until March 27 |
| Stage 2 |  10%  | until April 15 |
| Stage 3 |  0%   | until May 10   |
+---------+-------+----------------+

*/

pragma solidity ^0.4.21;
import "./Lib.sol";

// ERC20

contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint);

    function allowance(address owner, address spender) public constant returns (uint);

    function transfer(address to, uint value) public returns (bool ok);

    function transferFrom(address from, address to, uint value) public returns (bool ok);

    function approve(address spender, uint value) public returns (bool ok);

    function mintToken(address to, uint256 value) public returns (uint256);

    function changeTransfer(bool allowed) public;

    function getTotalSupply() public returns (uint256 supply);

    function burnUnused(uint256 _amount) public;
}


contract Sale is Ownable {
    using SafeMath for uint256;

    ERC20 public Token;

    uint256 public maxSupply;
    uint256 public maxSale;
    uint256 public maxBounty;
    uint256 public maxSwap;
    uint public swapTimelimit;

    uint256 public totalSold;
    uint256[4] public curStageSold;
    uint256 public totalBounty;
    uint256 public totalSwapped;
    uint256 public unSwapped;
    uint256 public burnedOnFinish;

    uint256 public ratio;
    uint256 public minToBuy;

    uint256[4] public bonus;
    uint256[4] public hardCap;
    uint256 public curStage;

    bool public isPaused;
    bool public isFinished;
    bool private configSet;

    address public ETHWallet;
    address public DEVWallet;

    event Contribution(address to, uint256 amount);
    event Swap(address to, uint256 amount, uint currenTimestamp, uint edgeTimestamp);
    event Finish(uint256 burned);

    constructor() public {
        isPaused = true;
        isFinished = false;
        configSet = false;
    }

    function setup(address _token, address _DEVWallet) external onlyOwner {
        require(!configSet, "config is already set");

        Token = ERC20(_token);

        //  100M tokens available to mint (hardcoded in a token contract)
        //  75M tokens for sale
        //      5% is reserved for EOS token swap
        //      3% is reserved for Bounty program
        //      10% of sold tokens will be minted to developers
        //      7% of sold tokens will be minted to operating costs
        //  Once sale is finished, contract will burn:
        //      - Unsold tokens
        //      - Unused bounty tokens
        //  At the end of 2021 contract will burn unclaimed EOS tokens
        maxSupply = Token.getTotalSupply();
        maxSale = 75000000000000000000000000;
        maxBounty = maxSupply * 3 / 100;
        maxSwap = maxSupply * 5 / 100;

        //  Bonus program
        //  Pre-sale: +30%
        //  Stage 1:  +20%
        //  Stage 2:  +10%
        //  Stage 3:  +0%
        bonus[0] = 30;
        bonus[1] = 20;
        bonus[2] = 10;
        bonus[3] = 0;

        //  Minimum amount to buy is 500 tokens
        minToBuy = 500000000000000000000;

        //  EOS token swap is available till 30 Dec 2021 12:00:01
        swapTimelimit = 1640865601;

        //  Developers
        DEVWallet = _DEVWallet;
        //  Tokens can't be transferred due the sale period
        changeTransferStats(false);

        //  Calls only once
        configSet = true;
    }

    //  Run next stage
    function runStage(uint256 _curStage, uint256 _ratio, address _ETHWallet, uint256 _hardCap) external onlyOwner {
        require(isPaused);
        require(!isFinished);
        curStage = _curStage;
        ETHWallet = _ETHWallet;
        ratio = _ratio;
        hardCap[curStage] = _hardCap;
        curStageSold[curStage] = 0;
    }

    //  Pause sale
    function pause(bool _isPaused) external onlyOwner {
        require(!isFinished);
        isPaused = _isPaused;
    }

    //  Receive ETH, convert and mint tokens to sender
    function() public payable {
        require(msg.value > 0, "ETH amount should be greater than 0");
        require(!isPaused, "Sale is paused");
        require(!isFinished, "Sale is finished");
        uint256 amount = msg.value.mul(ratio);
        require(amount >= minToBuy, "ETH amount doesn't met minimum tokens to buy");
        uint256 amount_with_bonus = amount.add(amount.mul(bonus[curStage]).div(100));
        require(curStageSold[curStage].add(amount_with_bonus) <= hardCap[curStage], "ETH amount exceeds hardcap, try to decrease ETH amount");
        totalSold = totalSold.add(amount_with_bonus);
        curStageSold[curStage] = curStageSold[curStage].add(amount_with_bonus);
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount_with_bonus);
        emit Contribution(msg.sender, amount_with_bonus);
    }

    // Change transfer status for tokens once sale is finished
    function changeTransferStats(bool _allowed) internal {
        Token.changeTransfer(_allowed);
    }

    // Bounty rewards
    function mintBounty(address _bountyHunter, uint256 _amount) external onlyOwner {
        require(_amount > 0);
        require(!isFinished, "Bounty period is finished");
        require(totalBounty + _amount <= maxBounty);
        totalBounty += _amount;
        Token.mintToken(_bountyHunter, _amount);
        emit Contribution(_bountyHunter, _amount);
    }

    // EOS tokens swap will be available until the end of 2021
    function mintSwap(address _swapHolder, uint256 _amount) external onlyOwner {
        require(_amount > 0);
        //Swap is available till 30 Dec 2021 12:00:01
        require(block.timestamp <= swapTimelimit, "Swap period finished");
        //Swap is limited to 5% of total supply
        require(totalSwapped + _amount <= maxSwap);
        totalSwapped += _amount;
        if(isFinished) {
            unSwapped -= _amount;
        }
        Token.mintToken(_swapHolder, _amount);
        emit Swap(_swapHolder, _amount, block.timestamp, swapTimelimit);
    }

    //  Will burn unclaimed tokens on 30 Dec 2021
    function burnUnswapped() external onlyOwner {
        if(unSwapped > 0) {
            Token.burnUnused(unSwapped);
            unSwapped = 0;
        }
    }

    //  Rates might be updated
    function updateRate(uint256 _rate) external onlyOwner {
        require(!isFinished);
        ratio = _rate;
    }

    //  Once sale is finished
    function finishSale() external onlyOwner {
        require(!isFinished);

        //  Allow token transferring
        changeTransferStats(true);

        //  Mint 15% of sold tokens to devs
        uint256 to_dev = totalSold * 10 / 100;
        Token.mintToken(DEVWallet, to_dev);

        //  Mint 7% of sold tokens to operating costs
        uint256 to_operating = totalSold * 7 / 100;
        Token.mintToken(DEVWallet, to_operating);

        //  Swap from EOS is available till the end of 2021
        unSwapped = maxSwap - totalSwapped;

        //  Burn tokens
        burnedOnFinish = maxSupply - totalSold - totalBounty - totalSwapped - to_dev - to_operating - unSwapped;
        if(burnedOnFinish > 0) {
            Token.burnUnused(burnedOnFinish);
        }

        isFinished = true;
        emit Finish(burnedOnFinish);
    }
}