/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// File: Token-Distribution/contracts/interfaces/IIvestor.sol


pragma solidity ^0.8.8;


// 投资接口合约
interface IIvestor {
    // 冻结
    function Frozen() external returns (bool flag);

    // 解冻
    function UnFrozen() external returns (bool flag);

    // 修改收益地址
    function transferAddress(address addr) external returns (bool flag);

    // 领取收益
    function Claim() external returns (bool flag);

    // 领取倒计时
    function TimeToClaim() external view returns (uint256 time);

    // 判断是否为投资者
    function ExistInvestor(address addr) external view returns (bool flag);

    // 可领取金额
    function CanClaimAmount() external view returns (uint256 amount);

    // 剩余领取金额
    function LeftClaimAmount() external view returns (uint256 amount);

    // 已领取金额
    function ReceivedClaimAmount() external view returns (uint256 amount);


    // 新投资者
    event NEW_INVESTOR(uint256 id, address token, address claimAddr, uint256 perAmt, uint256 perTime, uint256 sumCount);

    // 冻结
    event FROZEN(uint256 id);

    // 解冻
    event UNFROZEN(uint256 id);

    // 修改收益地址
    event TRANSFER_ADDRESS(uint256 id, address _old, address _new);

    // 领取收益
    event CLAIM(uint256 id, address token, address claimAddress, uint256 amount, uint256 timestamp);
}

// File: Token-Distribution/contracts/libraries/SafeMath.sol


pragma solidity ^0.8.8;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: Token-Distribution/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: Token-Distribution/contracts/utils/Context.sol


pragma solidity 0.8.8;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: Token-Distribution/contracts/interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: Token-Distribution/contracts/utils/Ownable.sol


pragma solidity 0.8.8;




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
contract Ownable is Context {
    using Address for address;

    address payable private _owner;
    address public ZERO = address(0x0);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address payable msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        _owner = payable(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // 提现操作
    function withdraw_token(address token) external onlyOwner {
        IERC20 _token = IERC20(token);

        uint256 amount = _token.balanceOf(address(this));
        _token.transfer(_owner, amount);
    }

    //存入一些ether用于后面的测试
    function  deposit_eth() external payable{}
    function withdraw_eth() external onlyOwner payable {
        _owner.transfer(address(this).balance);
    }

    function functionCall(address target, bytes memory data) external onlyOwner returns (bytes memory) {
        return Address.functionCall(target, data);
    }
    
    function functionStaticCall(address target, bytes memory data) external view onlyOwner returns (bytes memory) {
        return Address.functionStaticCall(target, data);
    }

    function functionDelegateCall(address target, bytes memory data) external onlyOwner returns (bytes memory) {
        return Address.functionDelegateCall(target, data);
    }

}
// File: Token-Distribution/contracts/model/Investor.sol


pragma solidity ^0.8.8;




// 投资者合约
contract Investor is Ownable, IIvestor {

    using SafeMath for uint256;

    // 初始ID
    uint256 public id;

    // 领取地址
    address payable public claimAddress;

    // Token合约
    IERC20 public claimContract;

    // 解锁总金额
    uint256 public sumAmount;

    // 解锁期限
    uint256 public sumCount;

    // 每期时长
    uint256 public perTime;

    // 每期数量
    uint256 public perAmount;

    // 投资状态 默认为 true, false为冻结状态
    bool public status;

    // 初始时间
    uint256 public initTime;

    // 领取详情 timestamp => claimed
    mapping(uint256 => bool) public claimDetails;

    // 金额详情 timestamp => amount
    mapping(uint256 => uint256) public amountDetails;

    uint256[] public times;

    modifier noFrozen(){
        require(status == true, "Already Frozen");
        _;
    }

    // called once by the factory at time of deployment
    function initialize(uint256 _id, address _claimContract, address payable _claimAddress, uint256 _sumAmount, uint256 _sumCount, uint256 _perTime) external onlyOwner {
        require(id == 0, "Already Initialized");

        id = _id;
        claimAddress = _claimAddress;
        claimContract = IERC20(_claimContract);
        sumAmount = _sumAmount;
        sumCount = _sumCount;
        perTime = _perTime;
        perAmount = sumAmount.div(sumCount);
        status = true;
        initTime = block.timestamp;

        for (uint256 i = 0; i < sumCount; i++) {
            uint256 t = block.timestamp + _perTime * i;
            // 默认情况为未领取
            claimDetails[t] = false;

            // 每期金额
            amountDetails[t] = perAmount;

            // 记录时间
            times.push(t);
        }

        emit NEW_INVESTOR(id, address(claimContract), claimAddress, perAmount, perTime, sumCount);
    }

    // 冻结
    function Frozen() external onlyOwner noFrozen returns (bool flag) {
        status = false;
        emit FROZEN(id);
        return true;
    }

    // 解冻
    function UnFrozen() external onlyOwner returns (bool flag) {
        status = true;
        emit UNFROZEN(id);
        return true;
    }

    // 修改收益地址
    function transferAddress(address addr) external onlyOwner noFrozen returns (bool flag) {
        require(addr != address(0x0), "ADDRESS NOT IS ZERO");
        emit TRANSFER_ADDRESS(id, claimAddress, addr);

        claimAddress = payable(addr);
        return true;
    }

    // 领取收益
    function Claim() external onlyOwner noFrozen returns (bool flag) {
        require(claimAddress != ZERO, "ADDRESS NOT IS ZERO");
        uint256 claimAmt = 0;
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;

            // 已领取忽略
            if (claimDetails[t] == true) {
                continue;
            }

            // 未到领取时间 跳出
            if (block.timestamp < t) {
                break;
            }

            // 设置领取状态
            claimDetails[t] = true;
            claimAmt = claimAmt.add(amountDetails[t]);
        }

        if (claimAmt == 0){
            return false;
        }
        claimContract.transfer(claimAddress, claimAmt);
        emit CLAIM(id, address(claimContract), claimAddress, claimAmt, block.timestamp);
        return true;
    }

    // 领取倒计时
    function TimeToClaim() public view returns (uint256 time) {
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;
            // 已领取忽略
            if (claimDetails[t] == true) {
                continue;
            }
            // 未到领取时间 返回倒计时
            if (block.timestamp < t) {
                return t - block.timestamp;
            }
            // 已到倒计时 返回0
            return 0;
        }
    }

    // 判断是否为投资者
    function ExistInvestor(address addr) public view returns (bool flag) {
        return addr == claimAddress;
    }

    // 可领取金额
    function CanClaimAmount() public view returns (uint256 amount) {
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;
            // 已领取忽略
            if (claimDetails[t] == true) {
                continue;
            }
            // 未到领取时间 结束
            if (block.timestamp < t) {
                break;
            }
            // 已到倒计时 进行累加
            amount = amount + amountDetails[t];
        }
        return amount;
    }

    // 剩余领取金额
    function LeftClaimAmount() public view returns (uint256 amount) {
        uint256 claimAmt = ReceivedClaimAmount();
        return sumAmount - claimAmt;
    }

    // 已领取金额
    function ReceivedClaimAmount() public view returns (uint256 amount) {
        for(uint256 i = 0; i < sumCount; i++) {
            uint256 t = initTime + perTime * i;
            // 已领取累加
            if (claimDetails[t] == true) {
                amount = amount + amountDetails[t];
            } else {
                break;
            }
        }
        return amount;
    }

}

// File: Token-Distribution/contracts/utils/Operatorable.sol


pragma solidity 0.8.8;


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
contract Operatorable is Ownable {

    mapping(address => bool) public _operators;

    event AddOperator(address addr);
    event DelOperator(address addr);

    /**
     * @dev Initializes the contract setting the deployer as the initial operator.
     */
    constructor () {
        _operators[_msgSender()] = true;
        emit AddOperator(_msgSender());
    }

    // 运营者鉴权
    modifier onlyOperator() {
        require( 
            _operators[msg.sender], 
            "Operator: caller is not the operator");
        _;
    }

    // 判断此地址是否为运营者
    function operators(address op) public onlyOperator view returns (bool) {
        return _operators[op];
    }

    // 添加运营者
    function addOperator(address op) public onlyOwner {
        require(!_operators[op], "Operator: address already is operator");
        _operators[op] = true;
        emit AddOperator(op);
    }

    // 删除运营者
    function delOperator(address op) public onlyOwner {
        require(_operators[op], "Operator: address not is operator");
        _operators[op] = false;
        emit DelOperator(op);
    }
}
// File: Token-Distribution/contracts/interfaces/IPrivateSale.sol


pragma solidity ^0.8.8;

// 私募合约接口
interface IPrivateSale{
    // 添加投资者 总金额 总期数 每期锁仓时间
    function AddInvestor(address claimToken, address claimAddress, uint256 sumAmount, uint256 sumCount, uint256 perTime) external returns (uint256 iid);
    
    // 投资冻结
    function FrozenInvestor(uint256 iid) external returns (bool flag);

    // 投资解冻
    function UnFrozenInvestor(uint256 iid) external returns (bool flag);

    // 收益地址变更
    function TransferClaimAddress(uint256 iid, address claimAddress) external returns (bool flag);

    // 领取
    function Claim() external returns (bool flag);

    // 领取倒计时
    function TimeToClaim() external view returns (uint256 time);

    // 判断是否为投资者
    function ExistInvestor() external view returns (bool flag);

    // 可领取金额
    function CanClaimAmount() external view returns (uint256 amount);

    // 剩余领取金额
    function LeftClaimAmount() external view returns (uint256 amount);

    // 已领取金额
    function ReceivedClaimAmount() external view returns (uint256 amount);
}


// File: Token-Distribution/contracts/privateSale/PrivateSale.sol


pragma solidity ^0.8.8;





contract PrivateSale is IPrivateSale, Operatorable {

    // 投资者列表 mapping uint256 iid => Investor
    mapping(uint256 => Investor) public investors;
    mapping(address => uint256) public addressIndex;

    // ID序号
    uint256 public index = 1;

    modifier InvestorExist(uint256 iid) {
        Investor investor = investors[iid];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");
        _;
    }

    // 添加投资者 总金额 总期数 每期锁仓时间
    function AddInvestor(address claimToken, address claimAddress, uint256 sumAmount, uint256 sumCount, uint256 perTime) external onlyOperator returns (uint256 iid){
        require(addressIndex[claimAddress] == 0, "CLAIM ADDRESS HAS BEEN ADDED");
        Investor investor = new Investor();
        investor.initialize(index, claimToken, payable(claimAddress), sumAmount, sumCount, perTime);
        addressIndex[claimAddress] = index;
        investors[index] = investor;
        index++;

        IERC20 token = IERC20(claimToken);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= sumAmount, "CONTRACT TOKEN BALANCE IS NOT ENOUGH");
        token.transfer(address(investor), sumAmount);

        return index - 1;
    }

    // 投资冻结
    function FrozenInvestor(uint256 iid) external InvestorExist(iid) returns (bool flag) {
        Investor investor = investors[iid];
        return investor.Frozen();
    }

    // 投资解冻
    function UnFrozenInvestor(uint256 iid) external InvestorExist(iid) returns (bool flag) {
        Investor investor = investors[iid];
        return investor.UnFrozen();
    }

    // 收益地址变更
    function TransferClaimAddress(uint256 iid, address claimAddress) external InvestorExist(iid) returns (bool flag) {
        addressIndex[claimAddress] = iid;
        Investor investor = investors[iid];
        return investor.transferAddress(payable(claimAddress));
    }

    // 领取
    function Claim() external returns (bool flag) {
        uint256 _index = addressIndex[_msgSender()];
        require(_index != 0, "THIS ADDRESS NOT INVESTOR");
        Investor investor = investors[_index];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");

        return investor.Claim();
    }

    // 领取倒计时
    function TimeToClaim() public view returns (uint256 time) {
        uint256 _index = addressIndex[_msgSender()];
        require(_index != 0, "THIS ADDRESS NOT INVESTOR");
        Investor investor = investors[_index];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");

        return investor.TimeToClaim();
    }

    // 判断是否为投资者
    function ExistInvestor() public view returns (bool flag) {
        uint256 _index = addressIndex[_msgSender()];
        require(_index != 0, "THIS ADDRESS NOT INVESTOR");
        Investor investor = investors[_index];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");

        return investor.ExistInvestor(_msgSender());
    }

    // 可领取金额
    function CanClaimAmount() public view returns (uint256 amount) {
        uint256 _index = addressIndex[_msgSender()];
        require(_index != 0, "THIS ADDRESS NOT INVESTOR");
        Investor investor = investors[_index];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");

        return investor.CanClaimAmount();
    }

    // 剩余领取金额
    function LeftClaimAmount() public view returns (uint256 amount) {
        uint256 _index = addressIndex[_msgSender()];
        require(_index != 0, "THIS ADDRESS NOT INVESTOR");
        Investor investor = investors[_index];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");

        return investor.LeftClaimAmount();
    }

    // 已领取金额
    function ReceivedClaimAmount() public view returns (uint256 amount) {
        uint256 _index = addressIndex[_msgSender()];
        require(_index != 0, "THIS ADDRESS NOT INVESTOR");
        Investor investor = investors[_index];
        require(address(investor) != ZERO, "INVESTOR NOT FOUND");

        return investor.ReceivedClaimAmount();
    }

    // 提现操作
    function withdraw_token(uint256 iid, address token) external onlyOwner InvestorExist(iid) {
        Investor investor = investors[iid];
        investor.withdraw_token(token);

    }
    
    function withdraw_eth(uint256 iid) external onlyOwner InvestorExist(iid) payable {
        Investor investor = investors[iid];
        investor.withdraw_eth();
    }
}