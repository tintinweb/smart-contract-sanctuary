//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

import './base/Operation.sol';
import './lib/SafeMath.sol';
import './lib/EnumerableSet.sol';
import './lib/Address.sol';
import './lib/SafeERC20.sol';
import './interfaces/IYouSwapVault.sol';
// import 'hardhat/console.sol';

contract YouSwapVault is Operation, IYouSwapVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public challengeDuration = 12 hours; // 提款挑战期，默认：12h
    uint256 public passRates; //多签批准率，60~100通过
    address private _ZERO_ADDRESS = address(0);
    uint256 public withdrawLimit; //单次提现限额

    // 存款
    event DepositFunds(address token, address sender, uint256 amount);
    // 创建提款
    event WithdrawCreated(address creator, address token, address recipient, uint256 amount, uint256 withdrawId, uint256 transId);
    // 提款交易多签
    event WithdrawSigned(address signer, address token, address recipient, uint256 signatureCount, uint256 withdrawId, uint256 transId);
    // 提款多签通过
    event WithdrawApproved(address token, address recipient, uint256 signatureCount, uint256 withdrawId, uint256 transId);
    // 提款成功
    event WithdrawFunds(address token, address recipient, uint256 amount);
    // 修改挑战期
    event ChangeChallengeDuration(uint256 preDuration, uint256 newDuration);
    // 修改提现限额
    event ChangeWithdrawLimitation(uint256 preLimit, uint256 newLimit);
    // 修改签名通过率
    event ChangePassRate(uint256 preRate, uint256 newRate);
    // Token白名单
    event ChangeWhiteList(address token, uint8 state);
    // 撤销提现
    event RevokeWithdraw(address caller, address token, address recipient, uint256 withdrawId);

    enum WithdrawalState {CREATED, SIGNING, CHALLENGING}

    struct Withdrawal {
        uint256 transId;
        address creator;
        address token;
        address recipient;
        uint256 amount;
        uint256 signatureCount;
        mapping(address => uint256) signatures;
        uint256 updateTime;
        uint256 createTime;
        uint256 challengeStartTime;
        WithdrawalState state;
        bool auditResult;
    }

    mapping(address => uint8) private _tokenWhiteList;
    mapping(uint256 => Withdrawal) public withdrawals;
    EnumerableSet.UintSet private _withdrawIds;
    uint256 private _base = 10 ** 8;

    mapping (address => EnumerableSet.UintSet) private _mySigningIds; //address=>多签状态的订单
    mapping (address => EnumerableSet.UintSet) private _myChallengingIds; //address=>挑战期的订单

    modifier exists (uint256 withdrawId){
        require(_withdrawIds.contains(withdrawId), 'YouSwap::ORDER_NOT_EXISTS');
        _;
    }

    /**
    @notice 
    @param _passRates 多签批准率
     */
    constructor(uint256 _passRates) {
        require(60 <= _passRates && _passRates <= 100);
        passRates = _passRates;
    }

    uint8 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'YouSwap::LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier inWhiteList(address token) {
        require(_tokenWhiteList[token] == 1, "YouSwap::UNSUPPORTED_TOKEN");
        _;
    }

    modifier notInWhiteList(address token) {
        require(token != _ZERO_ADDRESS, "YouSwap::INVALID_TOKEN");
        require(_tokenWhiteList[token] == 0, "YouSwap::ALREADY_SUPPORTED_TOKEN");
        _;
    }

    function addToWhiteList(address token) external notInWhiteList(token) onlyGovernance {
        _tokenWhiteList[token] = 1;
        emit ChangeWhiteList(token, 1);
    }

    function removeFromWhiteList(address token) external inWhiteList(token) onlyGovernance {
        _tokenWhiteList[token] = 0;
        emit ChangeWhiteList(token, 0);
    }

    function isInWhiteList(address token) external view returns(bool) {
       return _tokenWhiteList[token] == 1;
    }

    function deposit(address token, uint256 amount) inWhiteList(token) external override {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit DepositFunds(token, msg.sender, amount);
    }

    /**
    @notice 创建提现订单，然后进入多签环节
    @param transId 订单id，由发起人维护
    @param token 提现币种
    @param recipient 提现用户
    @param amount 提现金额
     */
    function withdraw(uint256 transId, address token, address recipient, uint256 amount) inWhiteList(token) isOperator external override {
        require(recipient != _ZERO_ADDRESS, "YouSwap::INVALID_RECIPIENT");
        require(amount > 0, "YouSwap::INVALID_AMOUNT");
        _withdraw(transId.add(_base), transId, token, recipient, amount);
    }

    /**
    @notice 创建提现订单，然后进入多签环节（internal）
    @param withdrawId 提现id，由发起人维护，与transId一一对应
    @param transId 订单id，由发起人维护
    @param token 提现币种
    @param recipient 提现用户
    @param amount 提现金额
     */
    function _withdraw(uint256 withdrawId, uint256 transId, address token, address recipient, uint256 amount) internal {
        require(!_withdrawIds.contains(withdrawId), 'YouSwap::ORDER_EXISTS');
        Withdrawal storage w = withdrawals[withdrawId];
        w.transId = transId;
        w.creator = msg.sender;
        w.token = token;
        w.recipient = recipient;
        w.amount = amount;
        w.signatureCount = 1;
        w.signatures[msg.sender] = 1;
        w.createTime = block.timestamp;
        w.updateTime = block.timestamp;
        w.state = WithdrawalState.CREATED;

        _withdrawIds.add(withdrawId);
        _mySigningIds[w.recipient].add(withdrawId);
        emit WithdrawCreated(msg.sender, w.token, recipient, amount, withdrawId, transId);
    }

    /**
    @notice 获取所有提现订单id，多签服务遍历进行多签
    @return ids 所有提现订单id
     */
    function withdrawIds() external view override returns (uint256[] memory ids){
        ids = _withdrawIds.values();
    }

    /**
    @notice 由多签服务调用，满足多签批准率后订单进入挑战期
    @param withdrawId 提现id
     */
    function sign(uint256 withdrawId) exists(withdrawId) isOperator lock external override {
        Withdrawal storage w = withdrawals[withdrawId];
        require(w.signatures[msg.sender] != 1, "YouSwap::SIGNED_ALREADY");
        w.signatures[msg.sender] = 1;
        w.signatureCount++;
        w.updateTime = block.timestamp;
        emit WithdrawSigned(msg.sender, w.token, w.recipient, w.signatureCount, withdrawId, w.transId);

        if (w.state == WithdrawalState.CHALLENGING) {
            return;
        }

        w.state = WithdrawalState.SIGNING;
        if (w.signatureCount.mul(100).div(operatorCount) >= passRates) {
            w.state = WithdrawalState.CHALLENGING;
            w.challengeStartTime = block.timestamp;
            _myChallengingIds[w.recipient].add(withdrawId);
            _mySigningIds[w.recipient].remove(withdrawId);
            emit WithdrawApproved(w.token, w.recipient, w.signatureCount, withdrawId, w.transId);
        }
    }
    
    /**
    @notice 获取用户所有提现请求数量
    @param token 提现币种
    @param account 提现金额
    @return claimableAmount 可提现金额
    @return pendingAmount 挑战期金额
    @return signingAmount 带签名金额
     */
    function getClaimableInfo(address token, address account) external view override returns(uint256 claimableAmount, uint256 pendingAmount, uint256 signingAmount) {
        EnumerableSet.UintSet storage ids = _myChallengingIds[account];
        for (uint256 index = 0; index < ids.length(); index++) {
            uint256 id = ids.at(index);
            Withdrawal storage w = withdrawals[id];
            if (token == w.token) {
                // if (WithdrawalState.CHALLENGING == w.state && block.timestamp >= w.challengeStartTime.add(challengeDuration)) {
                if (WithdrawalState.CHALLENGING == w.state && w.auditResult) {
                    claimableAmount = claimableAmount.add(w.amount); //可领取
                } else {
                    pendingAmount = pendingAmount.add(w.amount); //挑战期
                }
            }
        }

        EnumerableSet.UintSet storage _ids = _mySigningIds[account];
        for (uint256 index = 0; index < _ids.length(); index++) {
            uint256 id = _ids.at(index);
            Withdrawal storage w = withdrawals[id];
            if (token == w.token) {
                signingAmount = signingAmount.add(withdrawals[id].amount); //签名期
            }
        }
    }

    /**
    @notice 用户实际提现操作
    @param token 提现币种
     */
    function claim(address token) external inWhiteList(token) override {
        EnumerableSet.UintSet storage ids = _myChallengingIds[msg.sender];
        uint256 claimableAmount;
        uint256 lastest;
        for (uint256 index = 0; index < ids.length(); index++) {
            uint256 id = ids.at(index);
            Withdrawal storage w = withdrawals[id];
            if (token == w.token) {
                lastest = lastest > w.challengeStartTime ? lastest : w.challengeStartTime;
                // if (WithdrawalState.CHALLENGING == w.state && block.timestamp >= w.challengeStartTime.add(challengeDuration)) {
                if (WithdrawalState.CHALLENGING == w.state && w.auditResult) {
                    claimableAmount = claimableAmount.add(w.amount);
                    ids.remove(id);
                    _deleteWithdrawal(id);
                }
            }
        }

        require(claimableAmount > 0, "YouSwap::CLAIMABLE_AMOUNT_SHOULD_GT_ZERO");
        if (claimableAmount > withdrawLimit) {
            //如果提现金额超过限制，则需要经过挑战期，即使已经审核通过
            require(block.timestamp >= lastest.add(challengeDuration), "YouSwap::REACH_WITHDRAWLIMIT_SHOULD_WAITUNTIL_CHALLENGE_FINISH!");
        }
        IERC20(token).safeTransfer(msg.sender, claimableAmount);
        emit WithdrawFunds(token, msg.sender, claimableAmount);
    }

    /**
    @notice 撤销指定取款交易 
    @param withdrawId 撤销交易
    */
    function revoke(uint256 withdrawId) exists(withdrawId) external override isOperator {
        Withdrawal storage w = withdrawals[withdrawId];
        require(w.token != _ZERO_ADDRESS, "YouSwap::INVALID_WITHDRAWID");
        // if (WithdrawalState.CHALLENGING == w.state) {
        //     require(block.timestamp < w.challengeStartTime.add(challengeDuration), "YouSwap::CHALLENGE_DURATION_EXPIRED");
        // }

        _myChallengingIds[w.recipient].remove(withdrawId);
        _mySigningIds[w.recipient].remove(withdrawId);
        _deleteWithdrawal(withdrawId);
        emit RevokeWithdraw(msg.sender, w.token, w.recipient, withdrawId);
    }

    function _deleteWithdrawal(uint256 withdrawId) exists(withdrawId) internal {
        _withdrawIds.remove(withdrawId);
        delete withdrawals[withdrawId];
    }
    
    function getBalance(address token) external view override returns(uint256 amount) {
        amount = IERC20(token).balanceOf(address(this));
    }

    ///////////////////////////////////////////////////////

    /**
    @notice 挑战期设置，在此期间用户无法提取资金
    @param newDuration 新通挑战期
     */
    function setChallengeDuration(uint256 newDuration) external onlyGovernance {
        uint256 pre = challengeDuration;
        challengeDuration = newDuration;
        emit ChangeChallengeDuration(pre, newDuration);
    }

    /**
    @notice 设置单次提现限额
    @param newLimitation 新通挑战期
     */
    function setWithdrawLimitation(uint256 newLimitation) external onlyGovernance {
        uint256 pre = withdrawLimit;
        withdrawLimit = newLimitation;
        emit ChangeWithdrawLimitation(pre, withdrawLimit);
    }

    /**
    @notice 多签通过率
    @param newRate 新通过率
     */
    function setPassRate(uint256 newRate) external onlyGovernance {
        uint256 preRate = passRates;
        passRates = newRate;
        emit ChangePassRate(preRate, passRates);
    }

    /**
    @notice 审核结果
    @param withdrawId 矿池ID
    @param state 审核状态
     */
    function updateAuditResult(uint256 withdrawId, bool state) external isOperator {
        Withdrawal storage w = withdrawals[withdrawId];
        w.auditResult = state;
    }
}

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;
import "./Governance.sol";

contract Operation is Governance{
    mapping(address => uint8) private _operators;
    uint256 public operatorCount;

    modifier isOperator{
        require(_operators[msg.sender] == 1,"NOT_AN_OPERATOR");
        _;
    }

    constructor() {
        _operators[msg.sender] = 1;
        operatorCount++;
    }

    function addOperator(address account) external onlyGovernance {
        if(0 == _operators[account]) {
            _operators[account] = 1;
            operatorCount++;
        }
    }

    function removeOperator(address account) external onlyGovernance {
        if(1 == _operators[account]) {
            _operators[account] = 0;
            operatorCount--;
        }
    }

    function canOperate(address account) external view returns (bool) {
        return _operators[account] == 1;
    }
}

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

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

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

library EnumerableSet {
    struct Set {
        // Storage of set values
        uint256[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(uint256 => uint256) _indexes;//[value,index]
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, uint256 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, uint256 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex;
                // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, uint256 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (uint256) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (uint256[] memory) {
        return set._values;
    }

    function _clear(Set storage set) private returns (bool) {
        uint256 len = set._values.length;
        for(uint256 i = 0; i < len; i++){
            _remove(set,set._values[i]);
        }

        return true;
    }

    // UintSet
    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        return _values(set._inner);
    }

    function clear(UintSet storage set) internal returns (bool) {
        return _clear(set._inner);
    }
}

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isNotZero(address account) internal pure returns (bool) {
        return account != address(0);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;
import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

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

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

interface IYouSwapVault {
    function deposit(address token, uint256 amount) external;

    function withdraw(uint256 transId, address token, address recipient, uint256 amount) external;

    function withdrawIds() external view returns (uint256[] memory ids);

    function sign(uint256 withdrawId) external;

    function getClaimableInfo(address token, address account) external view returns(uint256 claimableAmount, uint256 pendingAmount, uint256 signingAmount);

    function claim(address token) external;

    function revoke(uint256 withdrawId) external;

    function getBalance(address token) external view returns(uint256 amount);
}

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

contract Governance {
    address internal _governance;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance.
     */
    constructor () {
        _governance = msg.sender;
        emit GovernanceTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(_governance == msg.sender, "NOT_Governance");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function transferGovernance(address newGovernance) public onlyGovernance {
        require(newGovernance != address(0), "ZERO_ADDRESS");
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * another (`recipient`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}