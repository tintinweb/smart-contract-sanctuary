/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity 0.6.12;


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
/**
 * @dev Interface of the ERC20 , add some function for gToken and cToken
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


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol







/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



contract Ownable {
    address public owner;
    address public newowner;
    address public admin;
    address public dev;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNewOwner {
        require(msg.sender == newowner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newowner = _newOwner;
    }
    
    function takeOwnership() public onlyNewOwner {
        owner = newowner;
    }    
    
    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }
    
    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    modifier onlyDev {
        require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
        _;
    }    
}


contract PledgeDeposit is Ownable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    struct PoolInfo {
        IERC20 token;
        string symbol;
    }

    struct DepositInfo {
        uint256 userOrderId;
        uint256 depositAmount;
        uint256 pledgeAmount;
        uint256 depositTime;
        uint256 depositBlock;
        uint256 expireBlock;
    }
    

    IERC20 public zild;

    /**
     * @dev  Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    uint256 public minDepositBlock = 1;

 
    PoolInfo[] public poolArray;


    // poolId , user address, DepositInfo
    mapping (uint256 => mapping (address => DepositInfo[])) public userDepositMap;

    mapping (address => uint256) public lastUserOrderIdMap;

    uint256 public pledgeBalance;    

    event NewPool(address addr, string symbol);

    event UpdateMinDepositBlock(uint256 dblock,address  who,uint256 time);

    event ZildBurnDeposit(address  userAddress,uint256 userOrderId, uint256 burnAmount);
    event Deposit(address  userAddress,uint256 userOrderId, uint256 poolId,string symbol,uint256 depositId, uint256 depositAmount,uint256 pledgeAmount);
    event Withdraw(address  userAddress,uint256 userOrderId, uint256 poolId,string symbol,uint256 depositId, uint256 depositAmount,uint256 pledgeAmount);
    
    constructor(address _zild,address _usdt) public {
        zild = IERC20(_zild);

        // poolArray[0] :  ETH 
        addPool(address(0),'ETH');  

        // poolArray[1] : ZILD  
        addPool(_zild,'ZILD');  

        // poolArray[2] : USDT  
        addPool(_usdt,'USDT');  

        _notEntered = true;
  
    }

        /*** Reentrancy Guard ***/

    /**
     * Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
    

    function addPool(address  _token, string memory _symbol) public onlyAdmin {
        poolArray.push(PoolInfo({token: IERC20(_token),symbol: _symbol}));
        emit NewPool(_token, _symbol);
    }

    function poolLength() external view returns (uint256) {
        return poolArray.length;
    }

    function updateMinDepositBlock(uint256 _minDepositBlock) public onlyAdmin {
        require(_minDepositBlock > 0,"Desposit: New deposit time must be greater than 0");
        minDepositBlock = _minDepositBlock;
        emit UpdateMinDepositBlock(minDepositBlock,msg.sender,now);
    }
      
    function tokenDepositCount(address _user, uint256 _poolId)  view public returns(uint256) {
        require(_poolId < poolArray.length, "invalid _poolId");
        return userDepositMap[_poolId][_user].length;
    }

    function burnDeposit(uint256 _userOrderId, uint256 _burnAmount) public{
       require(_userOrderId > lastUserOrderIdMap[msg.sender], "_userOrderId should greater than lastUserOrderIdMap[msg.sender]");
       
       lastUserOrderIdMap[msg.sender]  = _userOrderId;
       
       zild.transferFrom(address(msg.sender), address(1024), _burnAmount);       
  
       emit ZildBurnDeposit(msg.sender, _userOrderId, _burnAmount);
    }

    function deposit(uint256 _userOrderId, uint256 _poolId, uint256 _depositAmount,uint256 _pledgeAmount) public nonReentrant  payable{
       require(_poolId < poolArray.length, "invalid _poolId");
       require(_userOrderId > lastUserOrderIdMap[msg.sender], "_userOrderId should greater than lastUserOrderIdMap[msg.sender]");
       
       lastUserOrderIdMap[msg.sender]  = _userOrderId;
       PoolInfo storage poolInfo = poolArray[_poolId];

       // ETH
       if(_poolId == 0){
            require(_depositAmount == msg.value, "invald  _depositAmount for ETH");
            zild.safeTransferFrom(address(msg.sender), address(this), _pledgeAmount);
       }
       // ZILD
       else if(_poolId == 1){
            uint256 zildAmount = _pledgeAmount.add(_depositAmount);
            zild.safeTransferFrom(address(msg.sender), address(this), zildAmount);
       }
       else{
            zild.safeTransferFrom(address(msg.sender), address(this), _pledgeAmount);
            poolInfo.token.safeTransferFrom(address(msg.sender), address(this), _depositAmount);
       }

       pledgeBalance = pledgeBalance.add(_pledgeAmount);

       uint256 depositId = userDepositMap[_poolId][msg.sender].length;
       userDepositMap[_poolId][msg.sender].push(
            DepositInfo({
                userOrderId: _userOrderId,
                depositAmount: _depositAmount,
                pledgeAmount: _pledgeAmount,
                depositTime: now,
                depositBlock: block.number,
                expireBlock: block.number.add(minDepositBlock)
            })
        );
    
        emit Deposit(msg.sender, _userOrderId, _poolId, poolInfo.symbol, depositId, _depositAmount, _pledgeAmount);
    }

    function getUserDepositInfo(address _user, uint256 _poolId,uint256 _depositId) public view returns (
        uint256 _userOrderId, uint256 _depositAmount,uint256 _pledgeAmount,uint256 _depositTime,uint256 _depositBlock,uint256 _expireBlock) {
        require(_poolId < poolArray.length, "invalid _poolId");
        require(_depositId < userDepositMap[_poolId][_user].length, "invalid _depositId");

        DepositInfo memory depositInfo = userDepositMap[_poolId][_user][_depositId];
        
        _userOrderId = depositInfo.userOrderId;
        _depositAmount = depositInfo.depositAmount;
        _pledgeAmount = depositInfo.pledgeAmount;
        _depositTime = depositInfo.depositTime;
        _depositBlock = depositInfo.depositBlock;
        _expireBlock = depositInfo.expireBlock;
    }

    function withdraw(uint256 _poolId,uint256 _depositId) public nonReentrant {
        require(_poolId < poolArray.length, "invalid _poolId");
        require(_depositId < userDepositMap[_poolId][msg.sender].length, "invalid _depositId");

        PoolInfo storage poolInfo = poolArray[_poolId];
        DepositInfo storage depositInfo = userDepositMap[_poolId][msg.sender][_depositId];

        require(block.number > depositInfo.expireBlock, "The withdrawal block has not arrived");
        uint256 depositAmount =  depositInfo.depositAmount;
        require( depositAmount > 0, "There is no deposit available!");

        uint256 pledgeAmount = depositInfo.pledgeAmount;

        pledgeBalance = pledgeBalance.sub(pledgeAmount);
        depositInfo.depositAmount =  0;    
        depositInfo.pledgeAmount = 0;

        // ETH
        if(_poolId == 0) {
            msg.sender.transfer(depositAmount);
            zild.safeTransfer(msg.sender,pledgeAmount);
        }
        // ZILD
        else if(_poolId == 1){
            zild.safeTransfer(msg.sender, depositAmount.add(pledgeAmount));
        }
        else{
            poolInfo.token.safeTransfer(msg.sender, depositAmount);
            zild.safeTransfer(msg.sender,pledgeAmount);
        }   
      
        emit Withdraw(msg.sender, depositInfo.userOrderId, _poolId, poolInfo.symbol, _depositId, depositAmount, pledgeAmount);
      }
}