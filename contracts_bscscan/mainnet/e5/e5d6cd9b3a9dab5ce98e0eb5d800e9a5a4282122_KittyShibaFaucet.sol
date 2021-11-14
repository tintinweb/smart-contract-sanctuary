/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// KittyShiba Faucet

 pragma solidity 0.4.18;


// pragma solidity 0.5.12;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


interface IERC20 {
    function totalSupply() pure external returns (uint256 supply);
    function balanceOf(address _owner) pure external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) pure external returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract KittyShibaFaucet{
    using SafeMath for uint256;

    uint256 public maxAllowanceInclusive;
    mapping (address => uint256) public claimedTokens;
    IERC20 public erc20Contract;
    
    address private mOwner;
    bool private mIsPaused = false;
    bool private mReentrancyLock = false;
    
    event GetTokens(address requestor, uint256 amount);
    event ReclaimTokens(address owner, uint256 tokenAmount);
    event SetPause(address setter, bool newState, bool oldState);
    event SetMaxAllowance(address setter, uint256 newState, uint256 oldState);
    
    modifier notPaused() {
        require(!mIsPaused);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == mOwner);
        _;
    }
    
    modifier nonReentrant() {
        require(!mReentrancyLock);
        mReentrancyLock = true;
        _;
        mReentrancyLock = false;
    }
    
    function ERC20Faucet(IERC20 _erc20ContractAddress, uint256 _maxAllowanceInclusive) public {
        mOwner = msg.sender;
        maxAllowanceInclusive = _maxAllowanceInclusive;
        erc20Contract = _erc20ContractAddress;
    }
    
    function getTokens(uint256 amount) notPaused nonReentrant public returns (bool) {
        require(claimedTokens[msg.sender].add(amount) <= maxAllowanceInclusive);
        require(erc20Contract.balanceOf(this) >= amount);
        
        claimedTokens[msg.sender] = claimedTokens[msg.sender].add(amount);

        if (!erc20Contract.transfer(msg.sender, amount)) {
            claimedTokens[msg.sender] = claimedTokens[msg.sender].sub(amount);
            return false;
        }
        
        GetTokens(msg.sender, amount);
        return true;
    }
    
    function setMaxAllowance(uint256 _maxAllowanceInclusive) onlyOwner nonReentrant public {
        SetMaxAllowance(msg.sender, _maxAllowanceInclusive, maxAllowanceInclusive);
        maxAllowanceInclusive = _maxAllowanceInclusive;
    }
    
    function reclaimTokens() onlyOwner nonReentrant public returns (bool) {
        uint256 tokenBalance = erc20Contract.balanceOf(this);
        if (!erc20Contract.transfer(msg.sender, tokenBalance)) {
            return false;
        }

        ReclaimTokens(msg.sender, tokenBalance);
        return true;
    }
    
    function setPause(bool isPaused) onlyOwner nonReentrant public {
        SetPause(msg.sender, isPaused, mIsPaused);
        mIsPaused = isPaused;
    }
}