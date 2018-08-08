// v7

/**
 * Crowdsale.sol
 */

pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   * @param a First number
   * @param b Second number
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
   * @param a First number
   * @param b Second number
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param a First number
   * @param b Second number
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   * @param a First number
   * @param b Second number
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
  constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title TokenContract
 * @dev Token contract interface with transfer and balanceOf functions which need to be implemented
 */
interface TokenContract {

  /**
   * @dev Transfer funds to recipient address
   * @param _recipient Recipients address
   * @param _amount Amount to transfer
   */
  function transfer(address _recipient, uint256 _amount) external returns (bool);

  /**
   * @dev Return balance of holders address
   * @param _holder Holders address
   */
  function balanceOf(address _holder) external view returns (uint256);
}

/**
 * @title InvestorsStorage
 * @dev InvestorStorage contract interface with newInvestment, getInvestedAmount and investmentRefunded functions which need to be implemented
 */
interface InvestorsStorage {
  function newInvestment(address _investor, uint256 _amount) external;
  function getInvestedAmount(address _investor) external view returns (uint256);
  function investmentRefunded(address _investor) external;
}

/**
 * @title CrowdSale
 * @dev Main Crowdsale Contract which executes and handles crowdsale of the tokens
 */
contract CrowdSale is Ownable {
  using SafeMath for uint256;
  // variables

  TokenContract public tkn;

  InvestorsStorage public investorsStorage;
  uint256 public levelEndDate;
  uint256 public currentLevel;
  uint256 public levelTokens = 1500000;
  uint256 public tokensSold;
  uint256 public weiRised;
  uint256 public ethPrice;
  address[] public investorsList;
  bool public crowdSalePaused;
  bool public crowdSaleEnded;
  uint256[10] private tokenPrice = [52, 54, 56, 58, 60, 62, 64, 66, 68, 70];
  uint256 private baseTokens = 1500000;
  uint256 private usdCentValue;
  uint256 private minInvestment;
  address public affiliatesAddress = 0xFD534c1Fd8f9F230deA015B31B77679a8475052A;

  /**
   * @dev Constructor of CrowdSale contract
   */
   constructor() public {
    levelEndDate = block.timestamp + (1 * 7 days);
    tkn = TokenContract(0x5313E9783E5b56389b14Cd2a99bE9d283a03f8c6);                    // address of the token contract
    investorsStorage = InvestorsStorage(0x15c7c30B980ef442d3C811A30346bF9Dd8906137);      // address of the storage contract
    minInvestment = 100 finney;
    updatePrice(5000);
  }

  /**
   * @dev Fallback payable function which executes additional checks and functionality when tokens need to be sent to the investor
   */
  function() payable public {
    require(msg.value >= minInvestment); // check for minimum investment amount
    require(!crowdSalePaused);
    require(!crowdSaleEnded);
    if (currentLevel < 9) { // there are 10 levels, array start with 0
      if (levelEndDate < block.timestamp) { // if the end date of the level is reached
        currentLevel += 1; // next level
        levelTokens += baseTokens; // add remaining tokens to next level
        levelEndDate = levelEndDate.add(1 * 7 days); // restart end date
        }
      prepareSell(msg.sender, msg.value);
    } else {
      if (levelEndDate < block.timestamp) { // on last level, ask for extension, if the crowd sale is not extended then end
        crowdSaleEnded = true;
        msg.sender.transfer(msg.value);
        } else {
        prepareSell(msg.sender, msg.value);
        }
      }
  }

  /**
   * @dev Prepare sell of the tokens
   * @param _investor Investors address
   * @param _amount Amount invested
   */
  function prepareSell(address _investor, uint256 _amount) private {
    uint256 remaining;
    uint256 pricePerCent;
    uint256 pricePerToken;
    uint256 toSell;
    uint256 amount = _amount;
    uint256 sellInWei;
    address investor = _investor;

    pricePerCent = getUSDPrice();
    pricePerToken = pricePerCent.mul(tokenPrice[currentLevel]);
    toSell = _amount.div(pricePerToken);

    if (toSell < levelTokens) { // if there is enough tokens left in the current level, sell from it
      levelTokens = levelTokens.sub(toSell);
      weiRised = weiRised.add(_amount);
      executeSell(investor, toSell, _amount);
      owner.transfer(_amount);
    } else {  // if not, sell from 2 or more different levels
      while (amount > 0) {
        if (toSell > levelTokens) {
          toSell = levelTokens; // sell all the remaining in the level
          sellInWei = toSell.mul(pricePerToken);
          amount = amount.sub(sellInWei);
          if (currentLevel < 9) {
            currentLevel += 1;
            levelTokens = baseTokens;
            if (currentLevel == 9) {
              baseTokens = tkn.balanceOf(address(this));  // on last level, sell the remaining from presale
            }
          } else {
            remaining = amount;
            amount = 0;
          }
        } else {
          sellInWei = amount;
          amount = 0;
        }

        executeSell(investor, toSell, sellInWei);
        weiRised = weiRised.add(sellInWei);
        owner.transfer(amount);
        if (amount > 0) {
          toSell = amount.div(pricePerToken);
        }
        if (remaining > 0) {
          investor.transfer(remaining);
          owner.transfer(address(this).balance);
          crowdSaleEnded = true;
        }
      }
    }
  }

  /**
   * @dev Execute sell of the tokens - send investor to investors storage and transfer tokens
   * @param _investor Investors address
   * @param _tokens Amount of tokens to be sent
   * @param _weiAmount Amount invested in wei
   */
  function executeSell(address _investor, uint256 _tokens, uint256 _weiAmount) private {
    uint256 totalTokens = _tokens * (10 ** 18);
    tokensSold += _tokens; // update tokens sold
    investorsStorage.newInvestment(_investor, _weiAmount);

    require(tkn.transfer(_investor, totalTokens)); // transfer the tokens to the investor
    emit NewInvestment(_investor, totalTokens);
  }

  /**
   * @dev When the crowdsale ends, tokens left are sent to the affiliate address and crowdsale is terminated
   */
  function terminateCrowdSale() onlyOwner public {
    require(crowdSaleEnded);
    uint256 remainingTokens = tkn.balanceOf(address(this));
    require(tkn.transfer(affiliatesAddress, remainingTokens));
    selfdestruct(owner);
  }

  /**
   * @dev Getter for USD price of tokens
   */
  function getUSDPrice() private view returns (uint256) {
    return usdCentValue;
  }

  /**
   * @dev Change USD price of tokens
   * @param _ethPrice New Ether price
   */
  function updatePrice(uint256 _ethPrice) private {
    uint256 centBase = 1 * 10 ** 16;
    require(_ethPrice > 0);
    ethPrice = _ethPrice;
    usdCentValue = centBase.div(_ethPrice);
  }

  /**
   * @dev Set USD to ETH value
   * @param _ethPrice New Ether price
   */
  function setUsdEthValue(uint256 _ethPrice) onlyOwner external { // set the ETH value in USD
    updatePrice(_ethPrice);
  }

  /**
   * @dev Set the crowdsale contract address
   * @param _investorsStorage InvestorsStorage contract address
   */
  function setStorageAddress(address _investorsStorage) onlyOwner public { // set the storage contract address
    investorsStorage = InvestorsStorage(_investorsStorage);
  }

  /**
   * @dev Pause the crowdsale
   * @param _paused Paused state - true/false
   */
  function pauseCrowdSale(bool _paused) onlyOwner public { // pause the crowdsale
    crowdSalePaused = _paused;
  }

  /**
   * @dev Get funds
   */
  function getFunds() onlyOwner public { // claim the funds
    owner.transfer(address(this).balance);
  }

  event NewInvestment(address _investor, uint256 tokens);
}