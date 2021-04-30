/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: 
// File: @openzeppelin\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: library\NameFilter.sol

pragma solidity ^0.5.0;

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string memory _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint8(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

// File: interface\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function mint(address account, uint amount) external;
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

// File: @openzeppelin\contracts\utils\Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: library\SafeERC20.sol

pragma solidity ^0.5.0;





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }
    // function safeTransfer(IERC20 token, address to, uint256 value) internal {
    //     callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    // }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: library\Governance.sol

pragma solidity ^0.5.0;

contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

// File: interface\IPlayerBook.sol

pragma solidity ^0.5.0;


interface IPlayerBook {
    function settleReward( address from,uint256 amount ) external returns (uint256);
    function bindRefer( address from,string calldata  affCode )  external returns (bool);
    function hasRefer(address from) external returns(bool);

    function addPool(address poolAddr, address rewardToken) external;
}

// File: referral\PlayerBook.sol

pragma solidity ^0.5.0;






interface IERC20Lock {
    function lockOf(address account) view external returns(uint256);
    function increaseLock(address account,uint256 amount)  external;
    function increaseUnlock(address account, uint256 amount) external;
}

contract PlayerBook is Governance, IPlayerBook {
    using NameFilter for string;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // register pools       
    mapping (address => address) public _pools;
    address[] public _allpools;

    // (addr => pID) returns player id by address
    mapping (address => uint256) public _pIDxAddr;
    // (name => pID) returns player id by name      
    mapping (bytes32 => uint256) public _pIDxName;
    // (pID => data) player data     
    mapping (uint256 => Player) private _plyr;
    // (pID => name => bool) list of names a player owns.  (used so you can change your display name amoungst any name you own)
    mapping (uint256 => mapping (bytes32 => bool)) public _plyrNames;

    // the  of refrerrals
    mapping (address => uint256) public _totalReferReward;
    // total number of players
    uint256 public _pID;
    // total register name count
    uint256 public _totalRegisterCount = 0;

    // the direct refer's reward rate
    mapping (address => uint256) public _refer1RewardRate;
    // the second direct refer's reward rate
    mapping (address => uint256) public _refer2RewardRate;
    // the third direct refer's reward rate
    mapping (address => uint256) public _refer3RewardRate;
    // the forth direct refer's reward rate
    mapping (address => uint256) public _refer4RewardRate;
    // the fifth direct refer's reward rate
    mapping (address => uint256) public _refer5RewardRate;

    mapping (address => uint256[]) public _referRewardMinReleaseToken;
    
    mapping (address => address) public _poolOwner;

    // base rate
    uint256 public _baseRate = 10000;

    // base price to register a name
    uint256 public _registrationBaseFee = 50 finney;
    // register fee count step
    uint256 public _registrationStep = 200;
    // add base price for one step
    uint256 public _stepFee = 50 finney;
    uint256 public _registrationFeeRatio = 100;

    bytes32 public _defaulRefer ="dmsw";

    address public _teamWallet = 0x6666666666666666666666666666666666666666;
    address payable public _ETHFeeWallet;
    address public factoryAddress;

    struct PlayerStats {
        uint256 amount;
        uint256 rreward;
        uint256 allReward;
    }

    struct Player {
        address addr;
        bytes32 name;
        uint8 nameCount;
        uint256 laff;
        mapping (address => PlayerStats) stats;
        uint256 lv1Count;
        uint256 lv2Count;
        uint256 lv3Count;
        uint256 lv4Count;
        uint256 lv5Count;
    }

    event eveClaim(uint256 pID, address addr, uint256 reward, uint256 balance );
    event eveBindRefer(uint256 pID, address addr, bytes32 name, uint256 affID, address affAddr, bytes32 affName);
    event eveDefaultPlayer(uint256 pID, address addr, bytes32 name);
    event eveNewName(uint256 pID, address addr, bytes32 name, uint256 affID, address affAddr, bytes32 affName, uint256 balance  );
    event eveSettle(uint256 pID, uint256[] ancestors, uint256[] rewards,uint256 amount);
    event eveAddPool(address addr);
    event eveRemovePool(address addr);


    constructor()
    public
    {
        _ETHFeeWallet = tx.origin;
        factoryAddress = tx.origin;
        _pID = 0;
        addDefaultPlayer(_teamWallet,_defaulRefer);
    }

    /**
     * check address
     */
    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        _;
    }

    /**
     * check pool
     */
    modifier isRegisteredPool(){
        require(_pools[msg.sender] != address(0) ,"invalid pool address!");
        _;
    }

    function setETHFeeAddress(address payable _feeAddress) public onlyGovernance {
        _ETHFeeWallet = _feeAddress;
    }

    function setFactoryAddress(address _factoryAddress) public onlyGovernance {
        factoryAddress = _factoryAddress;
    }

    function setRegistrationFeeRatio(uint256 registrationFeeRatio) public onlyGovernance{
        require(registrationFeeRatio>=0 && registrationFeeRatio<=100,"PlayerBook:INVALID PARAMETER!");
        _registrationFeeRatio = registrationFeeRatio;
    }

    /**
     * contract dego balances
     */
    function balances(address poolAddr)
    public
    view
    returns(uint256)
    {
        require(_pools[poolAddr] != address(0),"invalid pool address!");

        return (IERC20(_pools[poolAddr]).balanceOf(address(this)));
    }

    function withdrawTeamAssets(address poolAddr,address toAccount) external onlyGovernance returns (uint256 reward) {
        require(_pools[poolAddr] != address(0),"invalid pool address!");

        uint256 pid = _pIDxAddr[_teamWallet];
        reward = _plyr[pid].stats[poolAddr].rreward;

        require(reward > 0,"only have reward");

        _plyr[pid].stats[poolAddr].allReward = _plyr[pid].stats[poolAddr].allReward.add(reward);
        _plyr[pid].stats[poolAddr].rreward = 0;

        IERC20(_pools[poolAddr]).safeTransfer(toAccount, reward);

        emit eveClaim(_pIDxAddr[_teamWallet], toAccount, reward, balances(poolAddr));
    }

    // get register fee
    function seizeEth() external  {
        uint256 _currentBalance =  address(this).balance;
        _ETHFeeWallet.transfer(_currentBalance);
    }

    /**
     * revert invalid transfer action
     */
    function() external payable {
        revert();
    }

    function addPools(address[] calldata poolAddrs, address[] calldata rewardToken) external {
        require(poolAddrs.length == rewardToken.length, "PoolAddrs and rewardToken lengths mismatch");
        require(msg.sender == _governance, "not governance or factory");

        for (uint i = 0; i < poolAddrs.length; i++) {
            address poolAddr = poolAddrs[i];
            require( _pools[poolAddr] == address(0), "derp, that pool already been registered");

            _pools[poolAddr] = rewardToken[i];
            _refer1RewardRate[poolAddr] = 150;
            _refer2RewardRate[poolAddr] = 100;
            _refer3RewardRate[poolAddr] = 100;
            _refer4RewardRate[poolAddr] = 100;
            _refer5RewardRate[poolAddr] = 150;
            
            _referRewardMinReleaseToken[poolAddr].push(0*10**18);
            _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
            _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
            _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
            _referRewardMinReleaseToken[poolAddr].push(1000*10**18);

            _poolOwner[poolAddr] = tx.origin;
            _allpools.push(poolAddr);

            emit eveAddPool(poolAddr);
        }
    }

    /**
     * registe a pool
     */
    function addPool(address poolAddr, address rewardToken)
    external
    {
        require(msg.sender == _governance || msg.sender == factoryAddress, "not governance or factory");
        require( _pools[poolAddr] == address(0), "derp, that pool already been registered");

        _pools[poolAddr] = rewardToken;
        _refer1RewardRate[poolAddr] = 150;
        _refer2RewardRate[poolAddr] = 100;
        _refer3RewardRate[poolAddr] = 100;
        _refer4RewardRate[poolAddr] = 100;
        _refer5RewardRate[poolAddr] = 150;
        
        _referRewardMinReleaseToken[poolAddr].push(0*10**18);
        _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
        _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
        _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
        _referRewardMinReleaseToken[poolAddr].push(1000*10**18);
        
        _poolOwner[poolAddr] = tx.origin;
        _allpools.push(poolAddr);

        emit eveAddPool(poolAddr);
    }

    /**
     * remove a pool
     */
    function removePool(address poolAddr)
    onlyGovernance
    public
    {
        require( _pools[poolAddr] != address(0), "derp, that pool must be registered");

        _pools[poolAddr] = address(0);

        emit eveRemovePool(poolAddr);
    }

    /**
     * resolve the refer's reward from a player
     */
    function settleReward(address from, uint256 amount)
    isRegisteredPool()
    validAddress(from)
    external
    returns (uint256)
    {
        // set up our tx event data and determine if player is new or not
        _determinePID(from);

        uint256 pID = _pIDxAddr[from];
        uint256 affID = _plyr[pID].laff;

        if(affID <= 0 ){
            affID = _pIDxName[_defaulRefer];
            _plyr[pID].laff = affID;
        }

        if(amount <= 0){
            return 0;
        }

        uint256 fee = 0;

        address poolAddr = msg.sender;

        
        uint256[] memory affRewards = new uint256[](5);
        
        affRewards[0] = amount.mul(_refer1RewardRate[poolAddr]).div(_baseRate);
        affRewards[1] = amount.mul(_refer2RewardRate[poolAddr]).div(_baseRate);
        affRewards[2] = amount.mul(_refer3RewardRate[poolAddr]).div(_baseRate);
        affRewards[3] = amount.mul(_refer4RewardRate[poolAddr]).div(_baseRate);
        affRewards[4] = amount.mul(_refer5RewardRate[poolAddr]).div(_baseRate);
        
        uint256[] memory ancestors = new uint256[](5);
        ancestors[0]  = affID;
        for(uint i = 1; i < ancestors.length; i++){
            ancestors[i] = _plyr[ancestors[i - 1]].laff;
            if(ancestors[i] <= 0){
                ancestors[i] = _pIDxName[_defaulRefer];
            }
        }
        
        for(uint256 i = 0; i < ancestors.length;i++){
            if (ancestors[i] !=_pIDxName[_defaulRefer]&&_referRewardMinReleaseToken[from].length > i&&_referRewardMinReleaseToken[from][i] > 0){
                if(IERC20(_pools[poolAddr]).balanceOf(from) < IERC20Lock(_pools[poolAddr]).lockOf(from)){
                    ancestors[i] = _pIDxName[_defaulRefer];
                } else if(IERC20(_pools[poolAddr]).balanceOf(from).sub(IERC20Lock(_pools[poolAddr]).lockOf(from)) < _referRewardMinReleaseToken[from][i]){
                    ancestors[i] = _pIDxName[_defaulRefer]; 
                }
            }
            
            _settleReward(poolAddr, ancestors[i], affRewards[i]);
            fee = fee.add(affRewards[i]);
        }

        _plyr[pID].stats[poolAddr].amount = _plyr[pID].stats[poolAddr].amount.add( amount);
        emit eveSettle( pID,ancestors,affRewards,amount);

        return fee;
    }
    
    function _settleReward(address poolAddr,uint256 ancestorPid, uint256 reward) private{
        _plyr[ancestorPid].stats[poolAddr].rreward = _plyr[ancestorPid].stats[poolAddr].rreward.add(reward);
         _totalReferReward[poolAddr] = _totalReferReward[poolAddr].add(reward);
    }


    /**
     * claim all of the refer reward.
     */
    function claim(address poolAddr)
    public
    {
        require(_pools[poolAddr] != address(0),"invalid pool address!");

        address addr = msg.sender;
        uint256 pid = _pIDxAddr[addr];
        uint256 reward = _plyr[pid].stats[poolAddr].rreward;

        require(reward > 0,"only have reward");

        //reset
        _plyr[pid].stats[poolAddr].allReward = _plyr[pid].stats[poolAddr].allReward.add(reward);
        _plyr[pid].stats[poolAddr].rreward = 0;

        //get reward
        IERC20(_pools[poolAddr]).safeTransfer(addr, reward);

        // fire event
        emit eveClaim(_pIDxAddr[addr], addr, reward, balances(poolAddr));
    }
    
    function claimAllPool() public {
        address addr = msg.sender;
        uint256 pid = _pIDxAddr[addr];
        
        require(pid != 0, "you are not register");
        
        for(uint256 i = 0; i < _allpools.length;i++){
            address poolAddr = _allpools[i];
            if(_pools[poolAddr] != address(0)){
                uint256 reward = _plyr[pid].stats[poolAddr].rreward;
                if(reward > 0){
                    claim(poolAddr);
                }
            }
        }
    }


    /**
     * check name string
     */
    function checkIfNameValid(string memory nameStr)
    public
    view
    returns(bool)
    {
        bytes32 name = nameStr.nameFilter();
        if (_pIDxName[name] == 0)
            return (true);
        else
            return (false);
    }

    /**
     * @dev add a default player
     */
    function addDefaultPlayer(address addr, bytes32 name)
    private
    {
        _pID++;

        _plyr[_pID].addr = addr;
        _plyr[_pID].name = name;
        _plyr[_pID].nameCount = 1;
        _pIDxAddr[addr] = _pID;
        _pIDxName[name] = _pID;
        _plyrNames[_pID][name] = true;

        //fire event
        emit eveDefaultPlayer(_pID,addr,name);
    }

    /**
     * @dev set refer reward rate
     */
    function setReferRewardRate(address poolAddr, uint256 refer1Rate, uint256 refer2Rate, uint256 refer3Rate,uint256 refer4Rate,uint256 refer5Rate) public
    {
        require(msg.sender == _governance || msg.sender == _poolOwner[poolAddr], "not governance or owner");

        require(_pools[poolAddr] != address(0),"invalid pool address!");

        _refer1RewardRate[poolAddr] = refer1Rate;
        _refer2RewardRate[poolAddr] = refer2Rate;
        _refer3RewardRate[poolAddr] = refer3Rate;
        _refer4RewardRate[poolAddr] = refer4Rate;
        _refer5RewardRate[poolAddr] = refer5Rate;
    }
    
    function setReferRewardMinReleaseToken(address poolAddr, uint256 refer1ReleaseToken, uint256 refer2ReleaseToken, uint256 refer3ReleaseToken, uint256 refer4ReleaseToken, uint256 refer5ReleaseToken) public
    {
        require(msg.sender == _governance || msg.sender == _poolOwner[poolAddr], "not governance or owner");
        
        require(_pools[poolAddr] != address(0),"invalid pool address!");
        
        _referRewardMinReleaseToken[poolAddr][0] = refer1ReleaseToken;
        _referRewardMinReleaseToken[poolAddr][1] = refer2ReleaseToken;
        _referRewardMinReleaseToken[poolAddr][2] = refer3ReleaseToken;
        _referRewardMinReleaseToken[poolAddr][3] = refer4ReleaseToken;
        _referRewardMinReleaseToken[poolAddr][4] = refer5ReleaseToken;
    }
    
    /**
     * @dev set registration step count
     */
    function setRegistrationStep(uint256 registrationStep) public
    onlyGovernance
    {
        _registrationStep = registrationStep;
    }

    /**
     * @dev set rewardtoken contract address
     */
    function setRewardContract(address poolAddr, address rewardToken)  public
    onlyGovernance{
        require(_pools[poolAddr] != address(0),"invalid pool address!");

        _pools[poolAddr] = rewardToken;
    }


    /**
     * @dev registers a name.  UI will always display the last name you registered.
     * but you will still own all previously registered names to use as affiliate
     * links.
     * - must pay a registration fee.
     * - name must be unique
     * - names will be converted to lowercase
     * - cannot be only numbers
     * - cannot start with 0x
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9
     * -functionhash- 0x921dec21 (using ID for affiliate)
     * -functionhash- 0x3ddd4698 (using address for affiliate)
     * -functionhash- 0x685ffd83 (using name for affiliate)
     * @param nameString players desired name
     * @param affCode affiliate name of who refered you
     * (this might cost a lot of gas)
     */

    function registerNameXName(string memory nameString, string memory affCode)
    public
    payable
    {

        // make sure name fees paid
        uint regisFee = this.getRegistrationFee();
        require (msg.value >= regisFee, "umm.....  you have to pay the name fee");

        // filter name + condition checks
        bytes32 name = NameFilter.nameFilter(nameString);
        // if names already has been used
        require(_pIDxName[name] == 0, "sorry that names already taken");

        // set up address
        address addr = msg.sender;
        // set up our tx event data and determine if player is new or not
        _determinePID(addr);
        // fetch player id
        uint256 pID = _pIDxAddr[addr];
        // if names already has been used
        require(_plyrNames[pID][name] == false, "sorry that names already taken");

        // add name to player profile, registry, and name book
        _plyrNames[pID][name] = true;
        _pIDxName[name] = pID;
        _plyr[pID].name = name;
        _plyr[pID].nameCount++;

        _totalRegisterCount++;


        //try bind a refer
        if(_plyr[pID].laff == 0){

            bytes memory tempCode = bytes(affCode);
            bytes32 affName = 0x0;
            if (tempCode.length >= 0) {
                assembly {
                    affName := mload(add(tempCode, 32))
                }
            }

            _bindRefer(addr,affName);
        }
        uint256 affID = _plyr[pID].laff;

        // fire event
        emit eveNewName(pID, addr, name, affID, _plyr[affID].addr, _plyr[affID].name, regisFee );
    }

    /**
     * @dev bind a refer,if affcode invalid, use default refer
     */
    function bindRefer( address from, string calldata  affCode )
    isRegisteredPool()
    external
    returns (bool)
    {

        bytes memory tempCode = bytes(affCode);
        bytes32 affName = 0x0;
        if (tempCode.length >= 0) {
            assembly {
                affName := mload(add(tempCode, 32))
            }
        }

        return _bindRefer(from, affName);
    }


    /**
     * @dev bind a refer,if affcode invalid, use default refer
     */
    function _bindRefer( address from, bytes32  name )
    validAddress(msg.sender)
    validAddress(from)
    private
    returns (bool)
    {
        // set up our tx event data and determine if player is new or not
        _determinePID(from);

        // fetch player id
        uint256 pID = _pIDxAddr[from];
        if( _plyr[pID].laff != 0){
            return false;
        }

        if (_pIDxName[name] == 0){
            //unregister name
            name = _defaulRefer;
        }

        uint256 affID = _pIDxName[name];
        if( affID == pID){
            affID = _pIDxName[_defaulRefer];
        }

        _plyr[pID].laff = affID;

        //lvcount
        _plyr[affID].lv1Count++;
        uint256 aff_affID = _plyr[affID].laff;
        uint256 nextAff_affID = aff_affID;
        if(nextAff_affID != 0 ){
            _plyr[nextAff_affID].lv2Count++;
            nextAff_affID = _plyr[nextAff_affID].laff;
            if(nextAff_affID != 0){
                _plyr[nextAff_affID].lv3Count++;
                nextAff_affID = _plyr[nextAff_affID].laff;
                if(nextAff_affID != 0){
                    _plyr[nextAff_affID].lv4Count++;
                    nextAff_affID = _plyr[nextAff_affID].laff;
                    if(nextAff_affID != 0){
                        _plyr[nextAff_affID].lv5Count++;
                    }
                }
            }
            
        }

        // fire event
        emit eveBindRefer(pID, from, name, affID, _plyr[affID].addr, _plyr[affID].name);

        return true;
    }

    //
    function _determinePID(address addr)
    private
    returns (bool)
    {
        if (_pIDxAddr[addr] == 0)
        {
            _pID++;
            _pIDxAddr[addr] = _pID;
            _plyr[_pID].addr = addr;

            // set the new player bool to true
            return (true);
        } else {
            return (false);
        }
    }

    function hasRefer(address from)
    isRegisteredPool()
    external
    returns(bool)
    {
        _determinePID(from);
        uint256 pID =  _pIDxAddr[from];
        return (_plyr[pID].laff > 0);
    }


    function getPlayerName(address from)
    external
    view
    returns (bytes32)
    {
        uint256 pID =  _pIDxAddr[from];
        if(_pID==0){
            return "";
        }
        return (_plyr[pID].name);
    }

    function getPlayerLaffNameAndAddress(address from)
    external
    view
    returns (bytes32,address)
    {
        uint256 pID =  _pIDxAddr[from];
        if(_pID==0){
            return ("", address(0));
        }

        uint256 aID=_plyr[pID].laff;
        if( aID== 0){
            return ("", address(0));
        }

        return (_plyr[aID].name, _plyr[aID].addr);
    }

    function getPlayerInvterCount(address from)
    external view
    returns (uint256 lv1Count,uint256 lv2Count,uint256 lv3Count,uint256 lv4Count,uint256 lv5Count)
    {
        uint256 pID = _pIDxAddr[from];
        if(_pID==0){
            return (0,0,0,0,0);
        }
        lv1Count = _plyr[pID].lv1Count;
        lv2Count = _plyr[pID].lv2Count;
        lv3Count = _plyr[pID].lv3Count;
        lv4Count = _plyr[pID].lv4Count;
        lv5Count = _plyr[pID].lv5Count;
    }

    function getPlayerInfo(address from, address poolAddr)
    external
    view
    returns (uint256 rreward,uint256 allReward,uint256 lv1Count,uint256 lv2Count,uint256 lv3Count,uint256 lv4Count,uint256 lv5Count)
    {
        uint256 pID = _pIDxAddr[from];
        if(_pID==0){
            return (0,0,0,0,0,0,0);
        }
        rreward = _plyr[pID].stats[poolAddr].rreward;
        allReward = _plyr[pID].stats[poolAddr].allReward;
        lv1Count = _plyr[pID].lv1Count;
        lv2Count = _plyr[pID].lv2Count;
        lv3Count = _plyr[pID].lv3Count;
        lv4Count = _plyr[pID].lv4Count;
        lv5Count = _plyr[pID].lv5Count;
    }

    function getRewardPools(address account,uint256 pageindex,uint256 pagecount)
    external
    view
    returns (address[] memory,uint256)
    {
        if(pagecount == 0){
            pagecount = 10;
        }
        address[] memory pools;
        pools = new address[](pagecount);
        uint256 pID = _pIDxAddr[account];
        if(_pID==0){
            return (pools,0);
        }
        uint256 index = 0;
        uint256 count = 0;
        uint256 offset = pageindex.mul(pagecount);
        for (uint i = 0; i < _allpools.length; i++) {
            if(_pools[_allpools[i]] == address(0)){
                continue;
            }
            if(_plyr[pID].stats[_allpools[i]].rreward > 0 ||
            _plyr[pID].stats[_allpools[i]].allReward > 0){
                if(index >= offset ){
                    pools[count] = _allpools[i];
                    count++;
                    if(count >= pagecount){
                        break;
                    }
                }
                index++;
            }
        }
        return (pools, count);
    }

    function getTotalReferReward(address poolAddr)
    external
    view
    returns (uint256)
    {
        return(_totalReferReward[poolAddr]);
    }

    function getRegistrationFee()
    external
    view
    returns (uint256 registrationBaseFee)
    {

        if( _totalRegisterCount <_registrationStep || _registrationStep == 0){
            registrationBaseFee = _registrationBaseFee;
        }
        else{
            uint256 step = _totalRegisterCount.div(_registrationStep);
            registrationBaseFee = _registrationBaseFee.add(step.mul(_stepFee));
        }
        registrationBaseFee = registrationBaseFee.mul(_registrationFeeRatio).div(100);
    }
}