pragma solidity ^0.4.18;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
 * @title Hex Pre-Sale
 * @dev 
 */
contract LobefyCrowdsale is Ownable {
    
    using SafeMath for uint256;
    
    event TokenPurchase(address indexed from, address indexed to, uint256 amount);
    event InitialRateChange(uint256 rate);
    
    ERC20   public _token;               // The token being sold
    address public _wallet;              // Address where funds are collected
    address public _addressIcoSupply;    // Address where ICO supply is allocated
    uint256 public _rate = 3000;         // How many token units investor gets per wei
    uint256 public etherRaised = 0;     // Amount of wei raised
    uint256 public tokensSold = 0;      // Amount of tokens sold
    bool    public paused = false;      // Sale is open by default (use toggle to change)
    
    
    // Statistics
    
    uint256  soldPhaseone = 0;
    uint256  soldPhaseTwo = 0;
    uint256  soldPhaseThree = 0;
  
  
    // Dates
    uint public preSaleStart = now;
    uint public preSaleEnd   = now + 20 minutes;
    
    uint public phaseOneStart = now;
    uint public phaseOneEnd   = now + 10 minutes;
    
    uint public phaseTwoStart = now + 15 minutes;
    uint public phaseTwoEnd   = now + 20 minutes;
    
    uint public phaseThreeStart = now +25 minutes;
    uint public phaseThreeEnd   = now +30 minutes;
    
    //uint public preSaleStart           = 1525856400; // 09-May-2018 09:00:00 GMT
    //uint public preSaleEnd             = preSaleStart + 7 days; // 16-Jun-2018 11:00:00 GMT
    
    // Controllers
    
    modifier onSaleRunning() {
        // Checks, if ICO is running and has not been stopped
        require(!paused && now >= phaseOneStart && now <= phaseThreeEnd);
        _;
    }
    
    function saleToggle(bool toggle) onlyOwner public returns(bool) {
        paused = toggle;
        
    }
    
    // Constructor
    
    constructor(address wallet, address addressIcoSupply, ERC20 token) public {
        require(wallet != address(0));
        require(token != address(0));
        require(addressIcoSupply != address(0));
        
        _wallet = wallet;
        _token = token;
        _addressIcoSupply = addressIcoSupply;
    }
    
    
    // Token Exchange
    
    function buyTokens(address investor, uint256 weiAmount) public payable {
        _preValidatePurchase(investor, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
      
        _processPurchase(investor, tokens);
        _forwardFunds();
        
        // update statistics
        etherRaised = etherRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        
        emit TokenPurchase(_addressIcoSupply, investor, tokens);
    }
  
    // Fallback function
    
    function () public onSaleRunning payable {
        buyTokens(msg.sender, msg.value);
    }
    
    // Token Rate change
    
    function setRate(uint256 newRate) public onlyOwner returns (bool) {
        _rate = newRate;

        emit InitialRateChange(_rate);
        return true;
    }
    
    
    // Pre validation
    
    function _preValidatePurchase(address investor, uint256 weiAmount) internal view {
        require(investor != address(0));
        require(weiAmount != 0);
        bool available = isAvailable();  // token allocation checks
        require(available);
    }
    
    function isAvailable() public view returns (bool){
        if (now >= phaseOneStart && now <=phaseOneEnd) {
            require(soldPhaseone < 100 * (10 ** 6) * (10 ** 18));
            return true;
            }   if (now >= phaseTwoStart && now <=phaseTwoEnd) {
                    require(soldPhaseTwo < 50 * (10 ** 6) * (10 ** 18));
                    return true;
                }   if (now >= phaseThreeStart && now <=phaseThreeEnd) {
                        require(soldPhaseThree < 50 * (10 ** 6) * (10 ** 18));
                        return true;
                    } else {
                        return false;
                      }
    }
    
    
    // Get token amount and bonuses
    
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 bonusRate;
        if (now >= phaseOneStart && now <=phaseOneEnd) {
            bonusRate = _rate.mul(2);
            return weiAmount.mul(bonusRate);
        }
            if (now >= phaseTwoStart && now <=phaseTwoEnd) {
                bonusRate = _rate.add((_rate.mul(5)).div(10));
                return weiAmount.mul(bonusRate);
            }
                else {
                    return weiAmount.mul(_rate);
                }
    }
    
    
    // Token transfer

    function _processPurchase(address investor, uint256 tokenAmount) public {
        _token.transferFrom(_addressIcoSupply, investor, tokenAmount);
    }
    
    
    // Raised Ether transfer
    
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }


}