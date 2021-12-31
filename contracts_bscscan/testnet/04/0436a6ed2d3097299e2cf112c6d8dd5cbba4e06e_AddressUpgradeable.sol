/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IERC20Upgradeable {
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


contract WodContract {

    using SafeMathUpgradeable for uint;
    using AddressUpgradeable for address;

    address public admin;
    address public teamAddr;
    IERC20Upgradeable public EBK;
    IERC20Upgradeable public RV;
    IERC20Upgradeable public HPTO;
    IERC20Upgradeable public FGO;
    IERC20Upgradeable public FTO;
    IERC20Upgradeable public OCO;
    IERC20Upgradeable public OIO;

    uint public poolRate;
    uint public teamRate;
    uint public userRate;
    uint public team2Rate;
    bool initialized;
    mapping(address => uint) public deposits;

    event WithdrawEBK(address, uint);
    event WithdrawRV(address, uint);
    event WithdrawHPTO(address, uint);
    event WithdrawFGO(address, uint);
    event WithdrawFTO(address, uint);
    event WithdrawOCO(address, uint);
    event WithdrawOIO(address, uint);
    event Deposit(address, uint);
    event Burn(address, uint);

    modifier onlyAdmin {
        require(msg.sender == admin,"You Are not admin");
        _;
    }

    /**
     * 初始化方法
     */
    function initialize(address _admin, address _teamAddr, address _ebkAddr, address _rvAddr, address _hptoAddr, address _fgoAddr, address _ftoAddr, address _ocoAddr, address _oioAddr) external {
        require(!initialized,"initialized");
        admin = _admin;
        teamAddr = _teamAddr;
        EBK = IERC20Upgradeable(_ebkAddr);
        RV = IERC20Upgradeable(_rvAddr);
        HPTO = IERC20Upgradeable(_hptoAddr);
        FGO = IERC20Upgradeable(_fgoAddr);
        FTO = IERC20Upgradeable(_ftoAddr);
        OCO = IERC20Upgradeable(_ocoAddr);
        OIO = IERC20Upgradeable(_oioAddr);
        poolRate = 90;
        teamRate = 10;
        userRate = 97;
        team2Rate = 3;
        initialized = true;
    }

/**
*设置参数
*/
    function setParam(
        address _admin,
        address _teamAddr,
        uint _poolRate,
        uint _teamRate,
        uint _userRate,
        uint _team2Rate
        ) external onlyAdmin {
        admin = address(_admin);
        teamAddr = address(_teamAddr);
        poolRate = _poolRate;
        teamRate = _teamRate;
        userRate = _userRate;
        team2Rate = _team2Rate;
    }

/**
* 转入池子
*/
    function deposit(uint _amount) external {
        EBK.transferFrom(msg.sender, address(this), _amount.mul(poolRate).div(100));
        EBK.transferFrom(msg.sender, teamAddr, _amount.mul(teamRate).div(100));
        deposits[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

/**
*EBK池子提现
*/
    function withdrawEBKFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        EBK.transfer(_userAddr, _amount.mul(userRate).div(100));
        EBK.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawEBK(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现EBK
*/
    function batchAdminWithdrawEBK(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            EBK.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现EBK
*/
    function adminWithdrawEBK(uint _amount) external onlyAdmin {
        EBK.transfer(admin, _amount);
    }

/**
*RV池子提现
*/
    function withdrawRVFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        RV.transfer(_userAddr, _amount.mul(userRate).div(100));
        RV.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawRV(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现RV
*/
    function batchAdminWithdrawRV(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            RV.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现RV
*/
    function adminWithdrawRV(uint _amount) external onlyAdmin {
        RV.transfer(admin, _amount);
    }

/**
*HPTO池子提现
*/
    function withdrawHPTOFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        HPTO.transfer(_userAddr, _amount.mul(userRate).div(100));
        HPTO.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawHPTO(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现HPTO
*/
    function batchAdminWithdrawHPTO(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            HPTO.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现HPTO
*/
    function adminWithdrawHPTO(uint _amount) external onlyAdmin {
        HPTO.transfer(admin, _amount);
    }

/**
*FGO池子提现
*/
    function withdrawFGOFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        FGO.transfer(_userAddr, _amount.mul(userRate).div(100));
        FGO.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawFGO(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现FGO
*/
    function batchAdminWithdrawFGO(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            FGO.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现FGO
*/
    function adminWithdrawFGO(uint _amount) external onlyAdmin {
        FGO.transfer(admin, _amount);
    }

/**
*FTO池子提现
*/
    function withdrawFTOFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        FTO.transfer(_userAddr, _amount.mul(userRate).div(100));
        FTO.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawFTO(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现FTO
*/
    function batchAdminWithdrawFTO(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            FTO.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现FTO
*/
    function adminWithdrawFTO(uint _amount) external onlyAdmin {
        FTO.transfer(admin, _amount);
    }

/**
*OCO池子提现
*/
    function withdrawOCOFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        OCO.transfer(_userAddr, _amount.mul(userRate).div(100));
        OCO.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawOCO(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现OCO
*/
    function batchAdminWithdrawOCO(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            OCO.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现OCO
*/
    function adminWithdrawOCO(uint _amount) external onlyAdmin {
        OCO.transfer(admin, _amount);
    }

/**
*OIO池子提现
*/
    function withdrawOIOFromPool(address _userAddr, uint _amount) external onlyAdmin {
        require(_userAddr!=address(0),"Can not withdraw to Blackhole");
        OIO.transfer(_userAddr, _amount.mul(userRate).div(100));
        OIO.transfer(teamAddr, _amount.mul(team2Rate).div(100));

        emit WithdrawOIO(_userAddr, _amount.mul(userRate));
    }

/**
* 管理员批量提现OIO
*/
    function batchAdminWithdrawOIO(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            OIO.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

/**
* 管理员提现OIO
*/
    function adminWithdrawOIO(uint _amount) external onlyAdmin {
        OIO.transfer(admin, _amount);
    }

    receive () external payable {}
}