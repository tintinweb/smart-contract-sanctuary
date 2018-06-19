pragma solidity 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Moneda {
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function burn() public;
}

contract MonedaICO {
    using SafeMath for uint256;
    
    struct DateRate {
        uint256 date;
        uint256 rate;
    }

    // PreICO
    uint256 constant public preICOLimit = 20000000e18; // Pre-ICO limit 5%, 20mil
    DateRate public preICO = DateRate(1525132799, 6750); // Monday, April 30, 2018 11:59:59 PM --- 35% Bonus
    uint256 public pre_tokensSold = 0;
    
    // ICO
    DateRate public icoStarts = DateRate(1526342400, 5750); // Tuesday, May 15, 2018 12:00:00 AM --- 15% Bonus
    DateRate public icoEndOfStageA = DateRate(1529020800, 5500); // Friday, June 15, 2018 12:00:00 AM --- 10% Bonus
    DateRate public icoEndOfStageB = DateRate(1530316800, 5250); // Saturday, June 30, 2018 12:00:00 AM --- 5% Bonus
    DateRate public icoEnds = DateRate(1531699199, 5000); // Sunday, July 15, 2018 11:59:59 PM --- 0% Bonus
    uint256 constant public icoLimit = 250000000e18; // ICO limit 62.5%, 250mil
    uint256 public tokensSold = 0;

    // If the funding goal is not reached, token holders may withdraw their funds
    uint constant public fundingGoal = 10000000e18; // 10mil
    // How much has been raised by crowdale (in ETH)
    uint public amountRaised;
    // The balances (in ETH) of all token holders
    mapping(address => uint) public balances;
    // Indicates if the crowdsale has been ended already
    bool public crowdsaleEnded = false;
    // Tokens will be transfered from this address
    address public tokenOwner;
    // The address of the token contract
    Moneda public tokenReward;
    // The wallet on which the funds will be stored
    address public wallet;
    // Notifying transfers and the success of the crowdsale
    event GoalReached(address tokenOwner, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution, uint amountRaised);
    
    function MonedaICO(Moneda token, address walletAddr, address tokenOwnerAddr) public {
        tokenReward = token;
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }

    function () external payable {
        require(msg.sender != wallet);
        exchange(msg.sender);
    }

    function exchange(address receiver) public payable {
        uint256 amount = msg.value;
        uint256 price = getRate();
        uint256 numTokens = amount.mul(price);
        
        bool isPreICO = (now <= preICO.date);
        bool isICO = (now >= icoStarts.date && now <= icoEnds.date);
        
        require(isPreICO || isICO);
        require(numTokens > 500);
        
        if (isPreICO) {
            require(!crowdsaleEnded && pre_tokensSold.add(numTokens) <= preICOLimit);
            require(numTokens <= 5000000e18);
        }
        
        if (isICO) {
            require(!crowdsaleEnded && tokensSold.add(numTokens) <= icoLimit);
        }

        wallet.transfer(amount);
        balances[receiver] = balances[receiver].add(amount);
        amountRaised = amountRaised.add(amount);

        if (isPreICO)
            pre_tokensSold = pre_tokensSold.add(numTokens);
        if (isICO)
            tokensSold = tokensSold.add(numTokens);
        
        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        emit FundTransfer(receiver, amount, true, amountRaised);
    }

    function getRate() public view returns (uint256) {
        if (now <= preICO.date)
            return preICO.rate;
            
        if (now < icoEndOfStageA.date)
            return icoStarts.rate;
            
        if (now < icoEndOfStageB.date)
            return icoEndOfStageA.rate;
            
        if (now < icoEnds.date)
            return icoEndOfStageB.rate;
        
        return icoEnds.rate;
    }
    
    // Checks if the goal or time limit has been reached and ends the campaign
    function checkGoalReached() public {
        require(now >= icoEnds.date);
        if (pre_tokensSold.add(tokensSold) >= fundingGoal){
            tokenReward.burn(); // Burn remaining tokens but the reserved ones
            emit GoalReached(tokenOwner, amountRaised);
        }
        crowdsaleEnded = true;
    }
    
    // Allows the funders to withdraw their funds if the goal has not been reached.
    // Only works after funds have been returned from the wallet.
    function safeWithdrawal() public {
        require(now >= icoEnds.date);
        uint amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}