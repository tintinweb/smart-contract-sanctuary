/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /*
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /*
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface EloinChef {

    function stakedTimeOf(address _address) external view returns (uint[] memory);

    function stakesOf(address _address) external view returns (uint[] memory);

}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract leoCornLaunchPad is Ownable {
  using SafeMath for uint256;

    struct parameter{
        string nameOfProject; uint256 _saleStartTime; uint256 _saleEndTime; address payable _projectOwner; uint256 maxAllocTierOne;
        uint256 maxAllocTierTwo; uint256 maxAllocTierThree; uint256 maxAllocTierFour; uint256 minAllocTierOne; uint256 minAllocTierTwo;
        uint256 minAllocTierThree; uint256 minAllocTierFour; address tokenToIDO; uint256 tokenDecimals; uint256 _numberOfIdoTokensToSell; uint256 _tokenPriceInBNB;
        uint256 _tierOneMaxCap; uint256 _tierTwoMaxCap; uint256 _tierThreeMaxCap; uint256 _tierFourMaxCap;
        uint256 _firstIterationPercentage; uint256 _secondIterationPercentage;
        }


  //token attributes
  string public NAME_OF_PROJECT; //name of the contract
  
  IERC20 public token;          //token to do IDO of

  EloinChef public stakingContract = EloinChef(0x60082BcC631c461b733B2ce3bB1898E1a08897d2);         //staking contract of Eloin to check staked coins for tier 1,2,3
  IERC20 public eloinToken = IERC20(0x75BB1D27E72198C933c4EBCCfA6949C025623565);    //Eloin token contract to check balances for tier 4 
  
  uint256 public  maxCap; // Max cap in BNB       //18 decimals
  uint256 public numberOfIdoTokensToSell;         //18 decimals
  uint256 public tokenPriceInBNB;                 //18 decimals

  uint256 public vestingPeriod = now + 30 days;             //by default vesting period is 30 days since creation of contract can be altered later on

  uint256 public immutable saleStartTime; // start sale time
  uint256 public immutable saleEndTime; // end sale time
    
    uint256 public saleStartTimeTierOne; // start sale time
    uint256 public saleEndTimeTierOne; // end sale time
    
    uint256 public saleStartTimeTierTwo; // start sale time
    uint256 public saleEndTimeTierTwo; // end sale time

    uint256 public saleStartTimeTierThree; // start sale time
    uint256 public saleEndTimeTierThree; // end sale time

    uint256 public saleStartTimeTierFour; // start sale time
    uint256 public saleEndTimeTierFour; // end sale time

  uint256 public totalBnbReceivedInAllTier; // total bnb received
  
  uint256 public softCapInAllTiers; // softcap if not reached IDO Fails 

  uint256 public totalBnbInTierOne; // total bnb for tier One
  uint256 public totalBnbInTierTwo; // total bnb for tier Two
  uint256 public totalBnbInTierThree; // total bnb for tier Three
  uint256 public totalBnbInTierFour;  // total bnb for tier Four

  address payable public projectOwner; // project Owner
  
  // max cap per tier %'s of maxCap
  uint256 public tierOneMaxCap; 
  uint256 public tierTwoMaxCap;
  uint256 public tierThreeMaxCap;
  uint256 public tierFourMaxCap;
  
  //max allocations per user in a tier
  uint256 public maxAllocaPerUserTierOne;
  uint256 public maxAllocaPerUserTierTwo; 
  uint256 public maxAllocaPerUserTierThree;
  uint256 public maxAllocaPerUserTierFour;

  //min allocations per user in a tier
  uint256 public minAllocaPerUserTierOne;
  uint256 public minAllocaPerUserTierTwo; 
  uint256 public minAllocaPerUserTierThree;
  uint256 public minAllocaPerUserTierFour;
 
  // address for tier one whitelist
  mapping (address => bool) private whitelistTierOne; 
  
  // address for tier two whitelist
  mapping (address => bool) private whitelistTierTwo; 
  
  // address for tier three whitelist
  mapping (address => bool) private whitelistTierThree; 
  
  // address for tier Four whitelist
  mapping (address => bool) private whitelistTierFour;

  //mapping the user purchase per tier
  mapping(address => uint256) public buyInOneTier;
  mapping(address => uint256) public buyInTwoTier;
  mapping(address => uint256) public buyInThreeTier;
  mapping(address => uint256) public buyInFourTier;

  mapping(address => bool) public alreadyWhitelisted;

  uint256 public amountStakedRequiredTier1 = 240000000000 * (10 ** 9);
  uint256 public amountStakedRequiredTier2 = 120000000000 * (10 ** 9);
  uint256 public amountStakedRequiredTier3 = 60000000000 * (10 ** 9);
  uint256 public amountStakedRequiredTier4 = 30000000000 * (10 ** 9); 

  bool public tier1transfer = false;
  bool public tier2transfer = false;
  bool public tier3transfer = false;
  bool public tier4transfer = false;

  bool public successIDO = false;
  bool public failedIDO = false;

  bool public tokensCollected = false;
  
  address public tokenSender;    // the owner who sends the token in the contract

  bool public idoTokensDeposited = false;           //check if tokens to IDO is deposited before distribution

  uint256 public decimals;              //decimals of the IDO token

  bool public finalizedDone = false;        //check if sale is finalized and both bnb and tokens locked in contract to distribute afterwards

  mapping (address => bool) public alreadyClaimed;
  mapping (address => bool) public alreadyClaimedVested;

  uint256 public firstIterationPercentage;
  uint256 public secondIterationPercentage;

  // CONSTRUCTOR  
  constructor(
      parameter memory p
  ) public {

    NAME_OF_PROJECT = p.nameOfProject;                        // name of the project to do IDO of

    token = IERC20(p.tokenToIDO);                             //token to ido

    decimals = p.tokenDecimals;                               //decimals of ido token (no decimals)

    numberOfIdoTokensToSell = p._numberOfIdoTokensToSell;       //No decimals
    tokenPriceInBNB = p._tokenPriceInBNB;                       //18 decimals 

    maxCap = numberOfIdoTokensToSell * tokenPriceInBNB;       //18 decimals

    saleStartTime = p._saleStartTime;                           //main sale start time
    saleEndTime = p._saleEndTime;                               //main sale end time

    saleStartTimeTierOne= p._saleStartTime; // start sale time
    saleEndTimeTierOne= saleStartTimeTierOne + 8 hours; // end sale time

    saleStartTimeTierTwo= saleStartTimeTierOne + 18 hours; // start sale time
    saleEndTimeTierTwo= saleStartTimeTierTwo + 4 hours; // end sale time

    saleStartTimeTierThree= saleEndTimeTierTwo + 10 minutes; // start sale time
    saleEndTimeTierThree= saleStartTimeTierThree + 2 hours; // end sale time
    
    saleStartTimeTierFour= saleEndTimeTierThree + 10 minutes; // start sale time
    saleEndTimeTierFour= saleStartTimeTierFour + 1 hours; // end sale time

    projectOwner = p._projectOwner;

    //percentages of total distribution of all BNB participation
    tierOneMaxCap = maxCap.div(100).mul(p._tierOneMaxCap);        //65% of maxCap
    tierTwoMaxCap = maxCap.div(100).mul(p._tierTwoMaxCap);        //20% of maxCap
    tierThreeMaxCap = maxCap.div(100).mul(p._tierThreeMaxCap);      //10% of maxCap
    tierFourMaxCap = maxCap.div(100).mul(p._tierFourMaxCap);        //5% of maxCap


    //give values in wei amount 18 decimals BNB
    maxAllocaPerUserTierOne = p.maxAllocTierOne;
    maxAllocaPerUserTierTwo = p.maxAllocTierTwo; 
    maxAllocaPerUserTierThree = p.maxAllocTierThree;
    maxAllocaPerUserTierFour = p.maxAllocTierFour;
    
    //give values in wei amount 18 decimals BNB
    minAllocaPerUserTierOne= p.minAllocTierOne;
    minAllocaPerUserTierTwo= p.minAllocTierTwo;
    minAllocaPerUserTierThree= p.minAllocTierThree;
    minAllocaPerUserTierFour= p.minAllocTierFour;

    softCapInAllTiers = maxCap.div(100).mul(5);

    firstIterationPercentage = p._firstIterationPercentage;
    secondIterationPercentage = p._secondIterationPercentage;

  }

  // function to update the tiers value manually
  function updateTierValues(uint256 _tierOneValue, uint256 _tierTwoValue, uint256 _tierThreeValue, uint256 _tierFourValue) external onlyOwner {
    require(now < saleStartTime, 'The sale has started cannot change tier values now');
    
    tierOneMaxCap =_tierOneValue;
    tierTwoMaxCap = _tierTwoValue;
    tierThreeMaxCap =_tierThreeValue;
    tierFourMaxCap = _tierFourValue;
    
    maxCap = tierOneMaxCap + tierTwoMaxCap + tierThreeMaxCap + tierFourMaxCap;
    softCapInAllTiers = maxCap.div(100).mul(5);
  }
  

  //add the address in Whitelist tier One to invest
  function addWhitelistOne(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(alreadyWhitelisted[_address] == false, 'Already Whitelisted address cannot be whitelisted in another tier or this tier');
    alreadyWhitelisted[_address] = true;
    whitelistTierOne[_address] = true;
  }

  //add the address in Whitelist tier two to invest
  function addWhitelistTwo(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(alreadyWhitelisted[_address] == false, 'Already Whitelisted address cannot be whitelisted in another tier or this tier');
    alreadyWhitelisted[_address] = true;
    whitelistTierTwo[_address] = true;
  }

  //add the address in Whitelist tier three to invest
  function addWhitelistThree(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(alreadyWhitelisted[_address] == false, 'Already Whitelisted address cannot be whitelisted in another tier or this tier');
    alreadyWhitelisted[_address] = true;
    whitelistTierThree[_address] = true;
  }

 //add the address in Whitelist tier Four to invest
  function addWhitelistFour(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(alreadyWhitelisted[_address] == false, 'Already Whitelisted address cannot be whitelisted in another tier or this tier');
    alreadyWhitelisted[_address] = true;
    whitelistTierFour[_address] = true;
  }
    
  // check the address in whitelist tier one
  function getWhitelistOne(address _address) public view returns(bool) {
    return whitelistTierOne[_address];
  }

  // check the address in whitelist tier two
  function getWhitelistTwo(address _address) public view returns(bool) {
    return whitelistTierTwo[_address];
  }

  // check the address in whitelist tier three
  function getWhitelistThree(address _address) public view returns(bool) {
    return whitelistTierThree[_address];
  }
  
    // check the address in whitelist tier Four
  function getWhitelistFour(address _address) public view returns(bool) {
    return whitelistTierFour[_address];
  }

  function getAlreadyWhiteListed(address _address) public view returns(bool){
      return alreadyWhitelisted[_address];
  }
    
  
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 

    function checkStakingEligibility(address _address) internal {           //checking staking eligiblity and token holding eligibility to get whitelisted

        uint256 amountStaked = 0;
        uint256 noOfTokens = 0;

        if( !getAlreadyWhiteListed(_address) ){                               

            uint256[] memory amountStakedArray = stakingContract.stakesOf(_address);

            for(uint256 i = 0 ; i < amountStakedArray.length ; i++){
                amountStaked = amountStaked.add(amountStakedArray[i]);
            }

            noOfTokens = eloinToken.balanceOf(_address);
        }

        if( now >= saleStartTimeTierOne && now < saleEndTimeTierOne ){
            
            if( amountStaked >= amountStakedRequiredTier1 || whitelistTierOne[_address] == true ){
            
                if(alreadyWhitelisted[_address] == false){
                    whitelistTierOne[_address] = true;
                    alreadyWhitelisted[_address] = true;
                }
                return;
            }
            else{
                revert('You cannot participate in this Tier 1 due to No whitelisting');
            }

        }

        else if( now >= saleStartTimeTierTwo && now < saleEndTimeTierTwo ){

            if( amountStaked >= amountStakedRequiredTier2 || whitelistTierTwo[_address] == true ){
            
                if(alreadyWhitelisted[_address] == false){
                    whitelistTierTwo[_address] = true;
                    alreadyWhitelisted[_address] = true;
                }
                return;
            }
            else{
                revert('You cannot participate in this Tier 2 due to no whitelisting');
            }
            
        }

        else if( now >= saleStartTimeTierThree && now < saleEndTimeTierThree ){

            if( amountStaked >= amountStakedRequiredTier3 || whitelistTierThree[_address] == true ){
                
                if(alreadyWhitelisted[_address] == false){
                    whitelistTierThree[_address] = true;
                    alreadyWhitelisted[_address] = true;
                }
                return;
            }
            else{
                revert('You cannot participate in this Tier 3 due to no whitelisting');
            }
        }

        else if( now >= saleStartTimeTierFour && now < saleEndTimeTierFour ){

            if( noOfTokens >= amountStakedRequiredTier4 || whitelistTierFour[_address] == true ){
                
                if(alreadyWhitelisted[_address] == false){
                    whitelistTierFour[_address] = true;
                    alreadyWhitelisted[_address] = true;
                }
                return;
            }
            else{
                revert('You cannot participate in this Tier 4 due to no whitelisting');
            }
        }

        else{
            revert('No Tier Sale is currently running, the IDO has ended or not started yet');
        }    

    }

    function transferMaxCapPerTierToNextLevel() internal {          //transferring previous tier MaxCap to next tier after a tier has ended and maxcap is left

        if(now >= saleEndTimeTierOne && tier1transfer == false){                                
            tierTwoMaxCap = tierTwoMaxCap.add( tierOneMaxCap.sub(totalBnbInTierOne) ); 
            tier1transfer = true;
        }

        if(now >= saleEndTimeTierTwo && tier2transfer == false){                                
            tierThreeMaxCap = tierThreeMaxCap.add( tierTwoMaxCap.sub(totalBnbInTierTwo) ); 
            tier2transfer = true;
        }

        if(now >= saleEndTimeTierThree && tier3transfer == false){                              
            tierFourMaxCap = tierFourMaxCap.add( tierThreeMaxCap.sub(totalBnbInTierThree) ); 
            tier3transfer = true;
        }

    }

  receive() external payable {          // if BNB is sent to contract participateAndPay() function to run to participate
    participateAndPay();
  }


  //send bnb to the contract address
  //used to participate in the public sale according to your tier 
  //main logic of IDO called and implemented here
  function participateAndPay() public payable {

    require(now >= saleStartTime, "The sale is not started yet "); // solhint-disable
    require(now <= saleEndTime, "The sale is closed"); // solhint-disable
    require(totalBnbReceivedInAllTier.add(msg.value) <= maxCap, "buyTokens: purchase would exceed max cap");

    checkStakingEligibility(msg.sender);          //makes sure that all staking coin holders get whitelisted automatically
    transferMaxCapPerTierToNextLevel();           //transfers previous tier remaining cap to next tier

    if(!getWhitelistOne(msg.sender) && !getWhitelistTwo(msg.sender) && !getWhitelistThree(msg.sender) && !getWhitelistFour(msg.sender)) {
      revert('Not whitelisted for any Tier kindly whiteList then participate');
    }

    if (getWhitelistOne(msg.sender) && now >= saleStartTimeTierOne && now < saleEndTimeTierOne ) {
      require(totalBnbInTierOne.add(msg.value) <= tierOneMaxCap, "buyTokens: purchase would exceed Tier one max cap");
      require(buyInOneTier[msg.sender].add(msg.value) <= maxAllocaPerUserTierOne ,"buyTokens:You are investing more than your tier-1 limit!");
      require(buyInOneTier[msg.sender].add(msg.value) >= minAllocaPerUserTierOne ,"buyTokens:You are investing less than your tier-1 limit!");
      buyInOneTier[msg.sender] = buyInOneTier[msg.sender].add(msg.value);
      totalBnbReceivedInAllTier = totalBnbReceivedInAllTier.add(msg.value);
      totalBnbInTierOne = totalBnbInTierOne.add(msg.value);
      return;
      
    }
    if (getWhitelistTwo(msg.sender) && now >= saleStartTimeTierTwo && now < saleEndTimeTierTwo ) {
      require(totalBnbInTierTwo.add(msg.value) <= tierTwoMaxCap, "buyTokens: purchase would exceed Tier two max cap");
      require(buyInTwoTier[msg.sender].add(msg.value) <= maxAllocaPerUserTierTwo ,"buyTokens:You are investing more than your tier-2 limit!");
      require(buyInTwoTier[msg.sender].add(msg.value) >= minAllocaPerUserTierTwo ,"buyTokens:You are investing less than your tier-2 limit!");
      buyInTwoTier[msg.sender] = buyInTwoTier[msg.sender].add(msg.value);
      totalBnbReceivedInAllTier = totalBnbReceivedInAllTier.add(msg.value);
      totalBnbInTierTwo = totalBnbInTierTwo.add(msg.value);
      return;
      
    }
    if (getWhitelistThree(msg.sender) && now >= saleStartTimeTierThree && now < saleEndTimeTierThree ) { 
      require(totalBnbInTierThree.add(msg.value) <= tierThreeMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      require(buyInThreeTier[msg.sender].add(msg.value) <= maxAllocaPerUserTierThree ,"buyTokens:You are investing more than your tier-3 limit!");
      require(buyInThreeTier[msg.sender].add(msg.value) >= minAllocaPerUserTierThree ,"buyTokens:You are investing less than your tier-3 limit!");
      buyInThreeTier[msg.sender] = buyInThreeTier[msg.sender].add(msg.value);
      totalBnbReceivedInAllTier = totalBnbReceivedInAllTier.add(msg.value);
      totalBnbInTierThree = totalBnbInTierThree.add(msg.value);
      return;
    
    }
    if (getWhitelistFour(msg.sender) && now >= saleStartTimeTierFour && now < saleEndTimeTierFour ) { 
      require(totalBnbInTierFour.add(msg.value) <= tierFourMaxCap, "buyTokens: purchase would exceed Tier Four max cap");
      require(buyInFourTier[msg.sender].add(msg.value) <= maxAllocaPerUserTierFour ,"buyTokens:You are investing more than your tier-4 limit!");
      require(buyInFourTier[msg.sender].add(msg.value) >= minAllocaPerUserTierFour ,"buyTokens:You are investing less than your tier-4 limit!");
      buyInFourTier[msg.sender] = buyInFourTier[msg.sender].add(msg.value);
      totalBnbReceivedInAllTier = totalBnbReceivedInAllTier.add(msg.value);
      totalBnbInTierFour = totalBnbInTierFour.add(msg.value);
      return;
      
    }

  }

    function finalizeSale() public onlyOwner{
        require(now > saleEndTime, 'The Sale is still ongoing and finalization of results cannot be done');
        require(idoTokensDeposited == true, 'No IDO tokens have been added to the contract kindly send tokens by running function getTokensFromAccount(sender)');
        require(finalizedDone == false, 'Alread Sale has Been Finalized');

        if(totalBnbReceivedInAllTier > softCapInAllTiers){
            //allow tokens to be claimable
            // send bnb to investor or the owner
            // success IDO use case
            successIDO = true;
            failedIDO = false;

            uint256 toReturn = maxCap.sub(totalBnbReceivedInAllTier);
            toReturn = toReturn.div(tokenPriceInBNB);

            token.transfer(tokenSender, toReturn.mul(10 ** (decimals)) );  //converting to 9 decimals from 18 decimals //extra tokens

            sendValue( projectOwner, address(this).balance );     //sending amount spent by user to projectOwner wallet

            finalizedDone = true;
        }
        else{
            //allow bnb to be claimed back
            // send tokens back to token owner
            //failed IDO use case
            successIDO = false;
            failedIDO = true;

            uint256 toReturn = token.balanceOf(address(this));
            token.transfer(tokenSender, toReturn);  //converting to 9 decimals from 18 decimals             

            finalizedDone = true;
        }
    }

    function claimTokens() public {                 
        require(now > saleEndTime + 90 minutes, 'First Claim Vesting Period Active will open after 90 minutes of saleEndTime');
        require(finalizedDone == true, 'The Sale has not been finalized. First finalize the sale to enable claiming of tokens');
        require(alreadyClaimed[msg.sender] == false, 'Cannot Claim more than once. You have already claimed tokens');
        uint256 amountSpent = buyInOneTier[msg.sender].add(buyInTwoTier[msg.sender]).add(buyInThreeTier[msg.sender]).add(buyInFourTier[msg.sender]);

        if(amountSpent == 0){
          revert('You have not participated hence cannot claim tokens');
        }

        if(successIDO == true && failedIDO == false){
            //success case
            //send token according to rate*amountspend
            uint256 toSend = amountSpent.div(tokenPriceInBNB).mul(firstIterationPercentage).div(100);                      //only first iteration percentage tokens to distribute rest are vested
            token.transfer(msg.sender, toSend.mul(10 ** (decimals)) ); //converting to 9 decimals from 18 decimals 
            //send bnb to wallet
            // sendValue(projectOwner, amountSpent);     //sending amount spent by user to projectOwner wallet
            alreadyClaimed[msg.sender] = true;
        }
        if(successIDO == false && failedIDO == true){
            //failure case
            //send bnb back as amountSpent
            sendValue(msg.sender, amountSpent);

            // uint256 toSend = amountSpent.div(tokenPriceInBNB);
            //send tokens back to projectOwner
            // token.transfer(tokenSender, toSend.mul(10 ** (decimals)) );  //converting to 9 decimals from 18 decimals 
            alreadyClaimed[msg.sender] = true;
        }

    }

    function amountStakedInEloin(address _address) public view returns (uint256[] memory){
        return stakingContract.stakesOf(_address);
    }

    function amountStakedInEloinIterator (address _address) public view returns(uint256){
        
        uint256 amountStaked = 0;

        uint256[] memory amountStakedArray = stakingContract.stakesOf(_address);

            for(uint256 i = 0 ; i < amountStakedArray.length ; i++){
                amountStaked = amountStaked.add(amountStakedArray[i]);
            }

        return amountStaked;
    }

    function amountEloinTokens(address _address) public view returns (uint256){
        return eloinToken.balanceOf(_address);
    }

    function getTokensFromAccount(address sender) public onlyOwner returns (uint256){
        
        require( idoTokensDeposited == false, 'Tokens already deposited not needed to deposit again');
        
        // token.transferFrom(sender, address(this), numberOfIdoTokensToSell.mul(10 ** (18-decimals) ));      //converting to 9 decimals from 18 decimals 
        tokenSender = sender;
        idoTokensDeposited = true;

        uint256 toReturn = numberOfIdoTokensToSell.mul(10 ** (18 - decimals));

        return toReturn;
    }

    function claimVestedTokens() public {

        require(now > saleEndTime, 'The Sale is still ongoing and claiming of tokens cannot be done');
        require(finalizedDone == true, 'The Sale has not been finalized. First finalize the sale to enable claiming of tokens');
        require(now > vestingPeriod, 'Vesting Period is not over cannot claim before vesting period is completed');
        require(alreadyClaimed[msg.sender] == true, 'First Claimed should be done before claiming this');
        require(alreadyClaimedVested[msg.sender] == false, 'Cannot Claim more than once. You have already claimed tokens');
        uint256 amountSpent = buyInOneTier[msg.sender].add(buyInTwoTier[msg.sender]).add(buyInThreeTier[msg.sender]).add(buyInFourTier[msg.sender]);

        if(amountSpent == 0){
          revert('You have not participated hence cannot claim tokens');
        }

        if(successIDO == true && failedIDO == false){
            //success case
            //send token according to rate*amountspend
            uint256 toSend = amountSpent.div(tokenPriceInBNB).mul(secondIterationPercentage).div(100);  //sending rest secondIteration percentage tokens that were vested
            token.transfer(msg.sender, toSend.mul(10 ** (decimals)) ); //converting to 9 decimals from 18 decimals 
            alreadyClaimedVested[msg.sender] = true;
        }
        
    }

    function setTokenSenderAddress(address _tokenSender) public onlyOwner {
        tokenSender = _tokenSender;
    }

    function updateVestingPeriod(uint256 EPOCHTimeToSet) public onlyOwner{
        require(EPOCHTimeToSet > now, 'Time cannot be in the PAST');
        vestingPeriod = EPOCHTimeToSet;
    }

    function withdrawTokensEmergency(address recipient,uint256 amount) public onlyOwner{
        token.transfer(recipient, amount);
    }

    function isEligible(address toCheckAddress) public view returns (uint) {

        uint256 amountStaked = amountStakedInEloinIterator(toCheckAddress);
        uint256 amountTokens = amountEloinTokens(toCheckAddress);

        if( amountStaked >= amountStakedRequiredTier1){
            return 1;
        }
        else if( amountStaked >= amountStakedRequiredTier2){
            return 2;
        }
        else if( amountStaked >= amountStakedRequiredTier3){
            return 3;
        }
        else if( amountTokens >= amountStakedRequiredTier4){
            return 4;
        }
        else{
            return 0;
        }
    }

}