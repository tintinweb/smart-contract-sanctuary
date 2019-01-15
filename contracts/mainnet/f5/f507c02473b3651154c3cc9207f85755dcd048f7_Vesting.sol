pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    address public newOwner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
  
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
     * @dev Throws if called by any account other than the specific function owner.
     */
    modifier ownedBy(address _a) {
        require( msg.sender == _a );
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
  
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to. Needs to be accepted by
     * the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnershipAtomic(address _newOwner) public onlyOwner {
        owner = _newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, _newOwner);
    }
  
    /**
     * @dev Completes the ownership transfer by having the new address confirm the transfer.
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }
  
    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        newOwner = _newOwner;
        emit OwnershipTransferInitiated(owner, _newOwner);
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract Vesting is Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;

    ERC20 public token;
    mapping (address => Holding) public holdings;
    address internal founders;

    uint constant internal PERIOD_INTERVAL = 30 days;
    uint constant internal FOUNDERS_HOLDING = 365 days;
    uint constant internal BONUS_HOLDING = 0;
    uint constant internal TOTAL_PERIODS = 12;

    uint public additionalHoldingPool = 0;
    uint internal totalTokensCommitted = 0;

    bool internal vestingStarted = false;
    uint internal vestingStart = 0;

    struct Holding {
        uint tokensCommitted;
        uint tokensRemaining;
        uint batchesClaimed;
        bool updatedForFinalization;
        bool isFounder;
        bool isValue;
    }

    event TokensReleased(address _to, uint _tokensReleased, uint _tokensRemaining);
    event VestingInitialized(address _to, uint _tokens);
    event VestingUpdated(address _to, uint _totalTokens);

    constructor(address _token, address _founders) public {
        require( _token != 0x0);
        require(_founders != 0x0);
        token = ERC20(_token);
        founders = _founders;
    }

    function claimTokens() external {
        require( holdings[msg.sender].isValue );
        require( vestingStarted );
        uint personalVestingStart = 
            (holdings[msg.sender].isFounder) ? (vestingStart.add(FOUNDERS_HOLDING)) : (vestingStart);

        require( now > personalVestingStart );

        uint periodsPassed = now.sub(personalVestingStart).div(PERIOD_INTERVAL);

        uint batchesToClaim = periodsPassed.sub(holdings[msg.sender].batchesClaimed);
        require( batchesToClaim > 0 );

        if (!holdings[msg.sender].updatedForFinalization) {
            holdings[msg.sender].updatedForFinalization = true;
            holdings[msg.sender].tokensRemaining = (holdings[msg.sender].tokensRemaining).add(
                (holdings[msg.sender].tokensCommitted).mul(additionalHoldingPool).div(totalTokensCommitted)
            );
        }

        uint tokensPerBatch = (holdings[msg.sender].tokensRemaining).div(
            TOTAL_PERIODS.sub(holdings[msg.sender].batchesClaimed)
        );
        uint tokensToRelease = 0;

        if (periodsPassed >= TOTAL_PERIODS) {
            tokensToRelease = holdings[msg.sender].tokensRemaining;
            delete holdings[msg.sender];
        } else {
            tokensToRelease = tokensPerBatch.mul(batchesToClaim);
            holdings[msg.sender].tokensRemaining = (holdings[msg.sender].tokensRemaining).sub(tokensToRelease);
            holdings[msg.sender].batchesClaimed = holdings[msg.sender].batchesClaimed.add(batchesToClaim);
        }

        require( token.transfer(msg.sender, tokensToRelease) );
        emit TokensReleased(msg.sender, tokensToRelease, holdings[msg.sender].tokensRemaining);
    }

    function tokensRemainingInHolding(address _user) public view returns (uint) {
        return holdings[_user].tokensRemaining;
    }
    
    function initializeVesting(address _beneficiary, uint _tokens) public onlyOwner {
        bool isFounder = (_beneficiary == founders);
        _initializeVesting(_beneficiary, _tokens, isFounder);
    }

    function finalizeVestingAllocation(uint _holdingPoolTokens) public onlyOwner {
        additionalHoldingPool = _holdingPoolTokens;
        vestingStarted = true;
        vestingStart = now;
    }

    function _initializeVesting(address _to, uint _tokens, bool _isFounder) internal {
        require( !vestingStarted );

        if (!_isFounder) totalTokensCommitted = totalTokensCommitted.add(_tokens);

        if (!holdings[_to].isValue) {
            holdings[_to] = Holding({
                tokensCommitted: _tokens, 
                tokensRemaining: _tokens,
                batchesClaimed: 0, 
                updatedForFinalization: _isFounder, 
                isFounder: _isFounder,
                isValue: true
            });

            emit VestingInitialized(_to, _tokens);
        } else {
            holdings[_to].tokensCommitted = (holdings[_to].tokensCommitted).add(_tokens);
            holdings[_to].tokensRemaining = (holdings[_to].tokensRemaining).add(_tokens);

            emit VestingUpdated(_to, holdings[_to].tokensRemaining);
        }
    }
}