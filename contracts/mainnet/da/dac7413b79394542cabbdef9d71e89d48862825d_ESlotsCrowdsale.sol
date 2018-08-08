pragma solidity ^0.4.18;

// File: contracts/math/SafeMath.sol

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
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: contracts/Dividends.sol

contract DividendContract {
  using SafeMath for uint256;
  event Dividends(uint256 round, uint256 value);
  event ClaimDividends(address investor, uint256 value);

  uint256 totalDividendsAmount = 0;
  uint256 totalDividendsRounds = 0;
  uint256 totalUnPayedDividendsAmount = 0;
  mapping(address => uint256) payedDividends;


  function getTotalDividendsAmount() public constant returns (uint256) {
    return totalDividendsAmount;
  }

  function getTotalDividendsRounds() public constant returns (uint256) {
    return totalDividendsRounds;
  }

  function getTotalUnPayedDividendsAmount() public constant returns (uint256) {
    return totalUnPayedDividendsAmount;
  }

  function dividendsAmount(address investor) public constant returns (uint256);
  function claimDividends() payable public;

  function payDividends() payable public {
    require(msg.value > 0);
    totalDividendsAmount = totalDividendsAmount.add(msg.value);
    totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.add(msg.value);
    totalDividendsRounds += 1;
    Dividends(totalDividendsRounds, msg.value);
  }
}

// File: contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ESlotsICOToken.sol

contract ESlotsICOToken is ERC20, DividendContract {

    string public constant name = "Ethereum Slot Machine Token";
    string public constant symbol = "EST";
    uint8 public constant decimals = 18;

    function maxTokensToSale() public view returns (uint256);
    function availableTokens() public view returns (uint256);
    function completeICO() public;
    function connectCrowdsaleContract(address crowdsaleContract) public;
}

// File: contracts/ESlotsICOTokenDeployed.sol

contract ESlotsICOTokenDeployed {

    // address of token contract (for dividend payments)
    address internal tokenContractAddress;
    ESlotsICOToken icoContract;

    function ESlotsICOTokenDeployed(address tokenContract) public {
        require(tokenContract != address(0));
        tokenContractAddress = tokenContract;
        icoContract = ESlotsICOToken(tokenContractAddress);
    }
}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/ESlotsCrowdsale.sol

contract ESlotsCrowdsale is Ownable, ESlotsICOTokenDeployed {
    using SafeMath for uint256;

    enum State { PrivatePreSale, PreSale, ActiveICO, ICOComplete }
    State public state;

    // start and end timestamps for dates when investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address for funds collecting
    address public wallet = 0x7b97B31E12f7d029769c53cB91c83d29611A4F7A;

    // how many token units a buyer gets per wei
    uint256 public rate = 1000; //base price: 1 EST token costs 0.001 Ether

    // amount of raised money in wei
    uint256 public weiRaised;

    mapping (address => uint256) public privateInvestors;

    /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function ESlotsCrowdsale(address tokenContract) public
    ESlotsICOTokenDeployed(tokenContract)
    {
        state = State.PrivatePreSale;
        startTime = 0;
        endTime = 0;
        weiRaised = 0;
        //do not forget to call
        //icoContract.connectCrowdsaleContract(this);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());


        uint256 weiAmount = msg.value;
        // calculate amount of tokens to be created
        uint256 tokens = getTokenAmount(weiAmount);
        uint256 av_tokens = icoContract.availableTokens();
        require(av_tokens >= tokens);
        if(state == State.PrivatePreSale) {
            require(privateInvestors[beneficiary] > 0);
            //restrict sales in private period
            if(privateInvestors[beneficiary] < tokens) {
                tokens = privateInvestors[beneficiary];
            }
        }
            // update state
        weiRaised = weiRaised.add(weiAmount);
        //we can get only 75% to development, 25% will be unlocked after 2 months to fill out casino contract bankroll
        wallet.transfer(percents(weiAmount, 75));
        icoContract.transferFrom(owner, beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function addPrivateInvestor(address beneficiary, uint256 value) public onlyOwner {
        require(state == State.PrivatePreSale);
        privateInvestors[beneficiary] = privateInvestors[beneficiary].add(value);
    }

    function startPreSale() public onlyOwner {
        require(state == State.PrivatePreSale);
        state = State.PreSale;
    }

    function startICO() public onlyOwner {
        require(state == State.PreSale);
        state = State.ActiveICO;
        startTime = now;
        endTime = startTime + 7 weeks;
    }

    function stopICO() public onlyOwner {
        require(state == State.ActiveICO);
        require(icoContract.availableTokens() == 0 || (endTime > 0 && now >= endTime));
        require(weiRaised > 0);
        state = State.ICOComplete;
        endTime = now;
    }

    // Allow getting slots bankroll after 60 days only
    function cleanup() public onlyOwner {
        require(state == State.ICOComplete);
        require(now >= (endTime + 60 days));
        wallet.transfer(this.balance);
    }

    // @return true if crowdsale ended
    function hasEnded() public view returns (bool) {
        return state == State.ICOComplete || icoContract.availableTokens() == 0 || (endTime > 0 && now >= endTime);
    }

    // Calculate amount of tokens depending on crowdsale phase and time
    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        uint256 totalTokens = weiAmount.mul(rate);
        uint256 bonus = getLargeAmountBonus(weiAmount);
        if(state == State.PrivatePreSale ||  state == State.PreSale) {
            //PreSale has 50% bonus!
            bonus = bonus.add(50);
        } else if(state == State.ActiveICO) {
            if((now - startTime) < 1 weeks) {
                //30% first week
                bonus = bonus.add(30);
            } else if((now - startTime) < 3 weeks) {
                //15% second and third weeks
                bonus = bonus.add(15);
            }
        }
        return addPercents(totalTokens, bonus);
    }

    function addPercents(uint256 amount, uint256 percent) internal pure returns(uint256) {
        if(percent == 0) return amount;
        return amount.add(percents(amount, percent));
    }

    function percents(uint256 amount, uint256 percent) internal pure returns(uint256) {
        if(percent == 0) return 0;
        return amount.mul(percent).div(100);
    }

    function getLargeAmountBonus(uint256 weiAmount) internal pure returns(uint256) {
        if(weiAmount >= 1000 ether) {
            return 50;
        }
        if(weiAmount >= 500 ether) {
            return 30;
        }
        if(weiAmount >= 100 ether) {
            return 15;
        }
        if(weiAmount >= 50 ether) {
            return 10;
        }
        if(weiAmount >= 10 ether) {
            return 5;
        }
       return 0;
    }

    // return true if the transaction is suitable for buying tokens
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return hasEnded() == false && nonZeroPurchase;
    }

}