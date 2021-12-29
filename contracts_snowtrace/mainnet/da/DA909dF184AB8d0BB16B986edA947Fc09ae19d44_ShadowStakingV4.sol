/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface IMilk2Token {

    function transfer(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address _to) external returns (uint256);

}

contract MultiplierMath {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function getInterval(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? a - b : 0;
    }

}

interface LastShadowContract {

    function getRewards(address _user) external view returns(uint256);

    function getTotalRewards(address _user) external view returns(uint256);

    function getLastBlock(address _user) external view returns(uint256);

    function getUsersCount() external view returns(uint256);

    function getUser(uint256 _userId) external view returns(address);
}

contract ShadowStakingV4 is Ownable,  MultiplierMath {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    struct UserInfo {
        uint256 rewardDebt;
        uint256 lastBlock;
    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPointAmount;
        uint256 blockCreation;
    }

    IMilk2Token public milk;

    LastShadowContract public lastShadowContract;

    mapping (address => UserInfo) private userInfo;
    mapping (address => bool) public trustedSigner;

    address[] internal users;

    uint256 internal previousUsersCount;

    mapping (address => uint256) public newUsersId;

    PoolInfo[] private poolInfo;

    uint256 private totalPoints;

    uint256[5] internal epochs;

    uint256[5] internal multipliers;

    event Harvest(address sender, uint256 amount, uint256 blockNumber);
    event AddNewPool(address token, uint256 pid);
    event PoolUpdate(uint256 poolPid, uint256 previusPoints, uint256 newPoints);
    event AddNewKey(bytes keyHash, uint256 id);
    event EmergencyRefund(address sender, uint256 amount);

    constructor(IMilk2Token _milk, uint256[5] memory _epochs, uint256[5] memory _multipliers, LastShadowContract _lastShadowContract) public {
        milk = _milk;
        epochs = _epochs;
        multipliers = _multipliers;
        lastShadowContract = _lastShadowContract;
        previousUsersCount = lastShadowContract.getUsersCount();
    }


    function addNewPool(IERC20 _lpToken, uint256 _newPoints) public onlyOwner {
        totalPoints = totalPoints.add(_newPoints);
        poolInfo.push(PoolInfo({lpToken: _lpToken, allocPointAmount: _newPoints, blockCreation:block.number}));
        emit AddNewPool(address(_lpToken), _newPoints);
    }


    function setPoll(uint256 _poolPid, uint256 _newPoints) public onlyOwner {
        totalPoints = totalPoints.sub(poolInfo[_poolPid].allocPointAmount).add(_newPoints);
        poolInfo[_poolPid].allocPointAmount = _newPoints;
    }


    function setTrustedSigner(address _signer, bool _isValid) public onlyOwner {
        trustedSigner[_signer] = _isValid;
    }


    function getPool(uint256 _poolPid) public view returns(address _lpToken, uint256 _block, uint256 _weight) {
        _lpToken = address(poolInfo[_poolPid].lpToken);
        _block = poolInfo[_poolPid].blockCreation;
        _weight = poolInfo[_poolPid].allocPointAmount;
    }


    function getPoolsCount() public view returns(uint256) {
        return poolInfo.length;
    }


    function getRewards(address _user) public view returns(uint256) {
        if (newUsersId[_user] == 0) {
            return  lastShadowContract.getRewards(_user);
        } else {
            return  userInfo[_user].rewardDebt;
        }
    }


    function getLastBlock(address _user) public view returns(uint256) {
        if (newUsersId[_user] == 0) {
            return lastShadowContract.getLastBlock(_user);
        } else {
            return userInfo[_user].lastBlock;
        }
    }


    function getTotalPoints() public view returns(uint256) {
        return totalPoints;
    }


    function registration() public {
        require(getLastBlock(msg.sender) == 0, "User already exist");

        _registration(msg.sender, 0, block.number);
    }


    function getData(uint256 _amount, uint256 _lastBlockNumber, uint256 _currentBlockNumber, address _sender) public pure returns(bytes32) {
        return sha256(abi.encode(_amount, _lastBlockNumber, _currentBlockNumber, _sender));
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    ///// Refactored items
    /////////////////////////////////////////////////////////////////////////////////////
    /**
    *@dev Prepare abi encoded message
    */
    function getMsgForSign(uint256 _amount, uint256 _lastBlockNumber, uint256 _currentBlockNumber, address _sender) public pure returns(bytes32) {
        return keccak256(abi.encode(_amount, _lastBlockNumber, _currentBlockNumber, _sender));
    }

    /**
    * @dev prepare hash for sign with Ethereum comunity convention
    *see links below
    *https://ethereum.stackexchange.com/questions/24547/sign-without-x19ethereum-signed-message-prefix?rq=1
    *https://github.com/ethereum/EIPs/pull/712
    *https://programtheblockchain.com/posts/2018/02/17/signing-and-verifying-messages-in-ethereum/
    */
    function preSignMsg(bytes32 _msg) public pure returns(bytes32) {
        return _msg.toEthSignedMessageHash();
    }


    /**
    * @dev Check signature and transfer tokens
    * @param  _amount - subj
    * @param  _lastBlockNumber - subj
    * @param  _currentBlockNumber - subj
    * @param  _msgForSign - hash for sign with Ethereum style prefix!!!
    * @param  _signature  - signature
    */
    function harvest(uint256 _amount, uint256 _lastBlockNumber, uint256 _currentBlockNumber, bytes32 _msgForSign, bytes memory _signature) public {
        require(_currentBlockNumber <= block.number, "currentBlockNumber cannot be larger than the last block");

        if (newUsersId[msg.sender] == 0) {
            _registration(msg.sender, getRewards(msg.sender), getLastBlock(msg.sender));
        }

        //Double spend check
        require(getLastBlock(msg.sender) == _lastBlockNumber, "lastBlockNumber must be equal to the value in the storage");

        //1. Lets check signer
        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy] == true, "Signature check failed!");

        //2. Check signed msg integrety
        bytes32 actualMsg = getMsgForSign(
            _amount,
            _lastBlockNumber,
            _currentBlockNumber,
            msg.sender
        );
        require(actualMsg.toEthSignedMessageHash() == _msgForSign,"Integrety check failed!");

        //Actions

        userInfo[msg.sender].rewardDebt = userInfo[msg.sender].rewardDebt.add(_amount);
        userInfo[msg.sender].lastBlock = _currentBlockNumber;
        if (_amount > 0) {
            milk.transfer(msg.sender, _amount);
        }
        emit Harvest(msg.sender, _amount, _currentBlockNumber);
    }



    function getUsersCount() public view returns(uint256) {
        return users.length.add(previousUsersCount);
    }


    function getUser(uint256 _userId) public view returns(address) {
        if (_userId < previousUsersCount) {
            return lastShadowContract.getUser(_userId);
        }
        else {
            return users[_userId.sub(previousUsersCount)];
        }
    }


    function getTotalRewards(address _user) public view returns(uint256) {
        if (newUsersId[_user] == 0) {
            return lastShadowContract.getTotalRewards(_user);
        }
        else {
            return userInfo[_user].rewardDebt;
        }
    }


    function _registration(address _user, uint256 _rewardDebt, uint256 _lastBlock) internal {
        UserInfo storage _userInfo = userInfo[_user];
        _userInfo.rewardDebt = _rewardDebt;
        _userInfo.lastBlock = _lastBlock;
        users.push(_user);
        newUsersId[_user] = users.length;
    }


    function getValueMultiplier(uint256 _id) public view returns(uint256) {
        return multipliers[_id];
    }


    function getValueEpoch(uint256 _id) public view returns(uint256) {
        return epochs[_id];
    }


    function getMultiplier(uint256 f, uint256 t) public view returns(uint256) {
        return getInterval(min(t, epochs[1]), max(f, epochs[0])) * multipliers[0] +
        getInterval(min(t, epochs[2]), max(f, epochs[1])) * multipliers[1] +
        getInterval(min(t, epochs[3]), max(f, epochs[2])) * multipliers[2] +
        getInterval(min(t, epochs[4]), max(f, epochs[3])) * multipliers[3] +
        getInterval(max(t, epochs[4]), max(f, epochs[4])) * multipliers[4];
    }


    function getCurrentMultiplier() public view returns(uint256) {
        if (block.number < epochs[0]) {
            return 0;
        }
        if (block.number < epochs[1]) {
            return multipliers[0];
        }
        if (block.number < epochs[2]) {
            return multipliers[1];
        }
        if (block.number < epochs[3]) {
            return multipliers[2];
        }
        if (block.number < epochs[4]) {
            return multipliers[3];
        }
        if (block.number > epochs[4]) {
            return multipliers[4];
        }
    }


    function setEpoch(uint256 _id, uint256 _amount) public onlyOwner {
        epochs[_id] = _amount;
    }


    function setMultiplier(uint256 _id, uint256 _amount) public onlyOwner {
        multipliers[_id] = _amount;
    }


    function emergencyRefund() public onlyOwner {
        emit EmergencyRefund(msg.sender, milk.balanceOf(address(this)));
        milk.transfer(owner(), milk.balanceOf(address(this)));
    }

}