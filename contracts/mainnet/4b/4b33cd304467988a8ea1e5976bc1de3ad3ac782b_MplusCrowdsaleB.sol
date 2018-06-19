/**
 *  Crowdsale for m+plus coin phase 2
 *
 *  Based on OpenZeppelin framework.
 *  https://openzeppelin.org
 **/

pragma solidity ^0.4.18;

/**
 * Safe Math library from OpenZeppelin framework
 * https://openzeppelin.org
 *
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Crowdsale for m+plus coin phase 1
 */
contract MplusCrowdsaleB {
    using SafeMath for uint256;

    // Number of stages
    uint256 internal constant NUM_STAGES = 4;

    // 05/02 - 05/16
    uint256 internal constant ICO_START1 = 1525190400;
    // 05/17 - 06/01
    uint256 internal constant ICO_START2 = 1526486400;
    // 06/02 - 06/16
    uint256 internal constant ICO_START3 = 1527868800;
    // 06/17 - 07/01
    uint256 internal constant ICO_START4 = 1529164800;
    // 07/01
    uint256 internal constant ICO_END = 1530460799;

    // Exchange rate for each term periods
    uint256 internal constant ICO_RATE1 = 13000;
    uint256 internal constant ICO_RATE2 = 12500;
    uint256 internal constant ICO_RATE3 = 12000;
    uint256 internal constant ICO_RATE4 = 11500;

    // Funding goal and soft cap in Token
    //uint256 internal constant HARD_CAP = 2000000000 * (10 ** 18);
    // Cap for each term periods in ETH
    // Exchange rate for each term periods
    uint256 internal constant ICO_CAP1 = 8000 * (10 ** 18);
    uint256 internal constant ICO_CAP2 = 16000 * (10 ** 18);
    uint256 internal constant ICO_CAP3 = 24000 * (10 ** 18);
    uint256 internal constant ICO_CAP4 = 32000 * (10 ** 18);

    // Caps per a purchase
    uint256 internal constant MIN_CAP = (10 ** 17);
    uint256 internal constant MAX_CAP = 1000 * (10 ** 18);

    // Owner of this contract
    address internal owner;

    // The token being sold
    ERC20 public tokenReward;

    // Tokens will be transfered from this address
    address internal tokenOwner;

    // Address where funds are collected
    address internal wallet;

    // Stage of ICO
    uint256 public stage = 0;

    // Amount of tokens sold
    uint256 public tokensSold = 0;

    // Amount of raised money in wei
    uint256 public weiRaised = 0;

    /**
     * Event for token purchase logging
     *
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event IcoStageStarted(uint256 stage);
    event IcoEnded();

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function MplusCrowdsaleB(address _tokenAddress, address _wallet) public {
        require(_tokenAddress != address(0));
        require(_wallet != address(0));

        owner = msg.sender;
        tokenOwner = msg.sender;
        wallet = _wallet;

        tokenReward = ERC20(_tokenAddress);
    }

    // Fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // Low level token purchase function
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(msg.value >= MIN_CAP);
        require(msg.value <= MAX_CAP);
        require(now >= ICO_START1);
        require(now <= ICO_END);
        require(stage <= NUM_STAGES);

        determineCurrentStage();
//        require(stage >= 1 && stage <= NUM_STAGES);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);
        require(tokens > 0);

        // Update totals
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        checkCap();

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        require(tokenReward.transferFrom(tokenOwner, _beneficiary, tokens));
        forwardFunds();
    }

    // Send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function determineCurrentStage() internal {
//        uint256 prevStage = stage;
        if (stage < 4 && now >= ICO_START4) {
            stage = 4;
            emit IcoStageStarted(4);
        } else if (stage < 3 && now >= ICO_START3) {
            stage = 3;
            emit IcoStageStarted(3);
        } else if (stage < 2 && now >= ICO_START2) {
            stage = 2;
            emit IcoStageStarted(2);
        } else if (stage < 1 && now >= ICO_START1) {
            stage = 1;
            emit IcoStageStarted(1);
        }
    }

    function checkCap() internal {
        if (weiRaised >= ICO_CAP4) {
            stage = 5;
            emit IcoEnded();
        } else if (stage < 4 && weiRaised >= ICO_CAP3) {
            stage = 4;
            emit IcoStageStarted(4);
        } else if (stage < 3 && weiRaised >= ICO_CAP2) {
            stage = 3;
            emit IcoStageStarted(3);
        } else if (stage < 2 && weiRaised >= ICO_CAP1) {
            stage = 2;
            emit IcoStageStarted(2);
        }
    }

    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 rate = 0;

        if (stage == 1) {
            rate = ICO_RATE1;
        } else if (stage == 2) {
            rate = ICO_RATE2;
        } else if (stage == 3) {
            rate = ICO_RATE3;
        } else if (stage == 4) {
            rate = ICO_RATE4;
        }

        return rate.mul(_weiAmount);
    }
}