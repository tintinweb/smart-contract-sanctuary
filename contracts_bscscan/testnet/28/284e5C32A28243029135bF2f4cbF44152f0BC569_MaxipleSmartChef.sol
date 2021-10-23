/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: UNLICENSED

library SafeBEP20 {
    // using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor()  {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function preMineSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

contract MaxipleSmartChefState is Ownable {
    using SafeBEP20 for IBEP20;
    
    IBEP20 public rewardToken;
    
    uint public maxiplePerDay;
    uint public totalAllocation;
    
    uint public twoDecimal = 100;
    uint public fourDecimals = 10000;
    uint public poolPeriod = 2;
    uint[2] public withdrawFee = [2, 10];
    
    struct PoolInfo {
        IBEP20 _token;
        uint _allocation;
        uint _multiplier; // 10000 == 1x
        uint _totalDeposit;
        bool _isActive;
    }
    
    struct UserInfo {
        uint _amount;
        uint _depositTime;
    }
    
    struct variables {
        uint _amountOut;
        uint _rewardAmount;
        uint _currentTime;
        uint _feePercent;
        uint _feeAmount;
        uint _depositTime;
    }
    
    struct variableReward{
        uint _currentTime;
        uint _days;
        uint sharePerPool;
        uint sharePerMax;
        uint rewardPerShare;
    }
    
    mapping(address => uint) public poolID;
    mapping(address => mapping(uint => mapping(uint => UserInfo))) public user;
    
    PoolInfo[] public _PoolInfo;
    uint[] public _poolPeriod = [30 days, 60 days, 90 days];
    
    modifier _validateParams(uint _pid, uint _period) {
        require(_PoolInfo.length >= _pid, "MaxipleSmartChef :: pool does not exist");
        require(_period >= 0, "MaxipleSmartChef :: period must be greater than thirty");
        require(_period <= poolPeriod, "MaxipleSmartChef :: period must be less than ninty");
        _;
    }
    
    modifier isPoolExist( uint _pid) {
        require(_PoolInfo.length >= _pid,"MaxipleSmartChef :: is pool exist");
        _;
    }
    
    modifier isPoolPeriodExist( uint _periodID) {
        require(_poolPeriod.length >= _periodID,"MaxipleSmartChef :: is pool period exist");
        _;
    }
    
    modifier isPoolActive( uint _pid) {
        require(_PoolInfo[_pid]._isActive, "MaxipleSmartChef :: is pool active");
        _;
    }
    
    function viewUser( address _user, uint _pid, uint _period) public view returns (UserInfo memory) {
        return user[_user][_pid][_period];
    }
}

contract MaxipleSmartChefStateUpgradeable is MaxipleSmartChefState {
    
    function addPoolPeriod( uint _period) external onlyOwner {
        poolPeriod++;
        _poolPeriod.push(_period);
    }
    
    function setMaxiplePerDay( uint _maxiplePerDay) external onlyOwner {
        maxiplePerDay = _maxiplePerDay;
    }
    
    function setPoolPeriod( uint _periodID, uint _period) external onlyOwner isPoolPeriodExist(_periodID) {
        _poolPeriod[_periodID] = _period;
    }
    
    function setMultiplier( uint _pid, uint _multiplier) external onlyOwner isPoolExist(_pid) {
        require(_multiplier > fourDecimals, "MaxipleSmartChef :: _multiplier must be greater than zero");
        _PoolInfo[_pid]._multiplier = _multiplier;
    }
    
    function setRewardToken( IBEP20 _rewardToken) public onlyOwner {
        require(address(_rewardToken) != address(0), "MaxipleSmartChef :: reward token must not be zero address");
        rewardToken = _rewardToken;
    }
    
    function setWithdrawFee( uint _fee) public onlyOwner {
        withdrawFee[0] = _fee;
    }
    
    function setEmergencyWithdrawFee( uint _fee) public onlyOwner {
        withdrawFee[1] = _fee;
    }
    
    function setAllocPoint( uint _pid, uint _alloc) external onlyOwner isPoolExist(_pid) {
        require(_alloc > 0, "MaxipleSmartChef :: _alloc must not be a zero");
        
        totalAllocation -= _PoolInfo[_pid]._allocation;
        _PoolInfo[_pid]._allocation = _alloc;
        totalAllocation += _PoolInfo[_pid]._allocation;
    }
    
    function _pausePool( uint _pid) external  onlyOwner isPoolExist(_pid) {
        _PoolInfo[_pid]._isActive = false;
    }
    
    function _unPausePool( uint _pid) external  onlyOwner isPoolExist(_pid) {
        _PoolInfo[_pid]._isActive = true;
    }
}

contract MaxipleSmartChef is MaxipleSmartChefStateUpgradeable {
    // using SafeMath for uint256;
    
    constructor( uint _maxiplePerDay, IBEP20 _rewardToken) {
        maxiplePerDay = _maxiplePerDay;
        setRewardToken(_rewardToken);
    }
    
    function add( PoolInfo memory _poolInfo) external onlyOwner {
        require(address(_poolInfo._token) != address(0), "MaxipleSmartChef :: _token must not be 0x00");
        require(_poolInfo._allocation > 0, "MaxipleSmartChef :: _allocation must be greater than zero");
        require(_poolInfo._multiplier >= fourDecimals, "MaxipleSmartChef :: _multiplier must be greater than one");
        
        _PoolInfo.push(PoolInfo(
            _poolInfo._token,
            _poolInfo._allocation,
            _poolInfo._multiplier,
            0,
            true
        ));
        
        poolID[address(_poolInfo._token)] = _PoolInfo.length;
        totalAllocation += _poolInfo._allocation;
    }
    
    function deposit( uint _pid, uint _period, uint _amountIn) external _validateParams( _pid, _period) isPoolActive( _pid) {
        UserInfo storage _user = user[msg.sender][_pid][_period];
        
        require(_amountIn > 0, "MaxipleSmartChef :: _amountIn must be greater than zero");
        require(_user._amount == 0,"MaxipleSmartChef :: _user._amount must be greater than zero");
        require(_PoolInfo[_pid]._token.transferFrom(msg.sender, address(this), _amountIn), "MaxipleSmartChef :: _amountIn transfer failed");
        
        _user._amount = _amountIn; 
        _user._depositTime = block.timestamp;
        _PoolInfo[_pid]._totalDeposit += _amountIn;
    }
    
    function harvest(uint _pid, uint _period) external _validateParams( _pid, _period) {
        UserInfo storage _user = user[msg.sender][_pid][_period];
        PoolInfo storage _pool = _PoolInfo[_pid];
        
        require(_user._amount > 0,"MaxipleSmartChef :: _user._amount must not be zero");
        
        uint _reward = viewReward( msg.sender, _pid, _period);
        
        variables memory _var = variables(_user._amount, (_reward == 0) ? 0 : _reward, block.timestamp, (_reward > 0 ) ? withdrawFee[0] : 0, 0, _user._depositTime);
        
        _user._amount = 0;
        _user._depositTime = 0;
        _pool._totalDeposit -= _var._amountOut;
        
        if(_var._rewardAmount > 0){
            if((_var._depositTime+_poolPeriod[_period] > _var._currentTime)) _var._feePercent = withdrawFee[1];
                
            _var._feeAmount = _var._rewardAmount*_var._feePercent/twoDecimal;
            
            _var._rewardAmount -= _var._feeAmount;
            
            rewardToken.transfer(msg.sender, _var._rewardAmount); // ransfer reward
        }
        
        _pool._token.transfer(msg.sender, _var._amountOut); // transfer token
    }   
    
    function viewReward( address _userAdd, uint _pid, uint _period) public view returns (uint _reward) {
        UserInfo memory _user = user[_userAdd][_pid][_period];
        PoolInfo memory _pool = _PoolInfo[_pid];
        
        if(_user._amount == 0) return 0;
        
        variableReward memory _var;
        _var._currentTime = block.timestamp;
        _var.sharePerPool = maxiplePerDay*_pool._allocation/totalAllocation;
        _var.sharePerMax = _var.sharePerPool*1e15/_pool._totalDeposit;
        _var.rewardPerShare = (_user._amount*(_var.sharePerMax*_pool._multiplier/fourDecimals)/1e15);
        
        if(_var._currentTime > _user._depositTime+_poolPeriod[_period]) _var._currentTime = _user._depositTime+_poolPeriod[_period];
        
        _var._days = (_var._currentTime-_user._depositTime)/86400; 
        _reward = _var.rewardPerShare*_var._days;
    }   
}