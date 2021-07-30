/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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

contract DelegateProxy {
    address public user;
    mapping(address => bool) public approves;

    constructor(address _user) {
        user = _user;
        approves[_user] = true;
        approves[msg.sender] = true;
    }

    modifier onlyApprover {
        require(approves[msg.sender], 'DelegateProxy: unauthorized');
        _;
    }

    function setApprove(address _approver, bool _approve) onlyApprover public {
        approves[_approver] = _approve;
    }

    function proxyCall(address _target, bytes calldata _calldata) onlyApprover public returns(bool) {
        (bool result, ) = _target.call(_calldata);
        return result;
    }

    function proxyTransferFrom(address _target, address _from, address _to, uint256 _value) onlyApprover public returns(bool) {
        return IERC20(_target).transferFrom(_from, _to, _value);
    }
}

pragma experimental ABIEncoderV2;

struct Order {
    address user;
    address target;
    bytes targetCalldata;
    bytes targetCalldataReplacementMask;
    address paymentToken;
    uint256 priceAmount;
    uint256 feePercent;
    uint256 expirationBlock;
    uint256 nonce;
}

contract NFTFarmExchange is Ownable {
    using SafeMath for uint256;

    // Address of team
    address public team;

    // minimum exchange fee
    uint256 public minimumFeePercent;

    // cancel or ordered hashs
    mapping(bytes32 => bool) public closedOrders;

    // proxy for send nft
    mapping(address => DelegateProxy) public proxies;

    event Exchange(bytes32 sellHash, bytes32 buyHash, address paymentToken, uint256 priceAmount, uint256 paymentAmount, uint256 feeAmount);
    event CancelOrder(bytes32 indexed orderHash);

    constructor(address _team, uint256 _minimumFeePercent) public {
        team = _team;
        minimumFeePercent = _minimumFeePercent;
    }

    function exchange(
        address _target,
        bytes calldata _targetCalldata,
        address _paymentToken,
        uint256 _priceAmount,
        uint256 _feePercent,
        address[2] calldata _users,
        bytes[2] calldata _replacementCalldatas,
        uint256[2] calldata _expirationBlocks,
        uint256[2] calldata _nonces,
        bytes[2] calldata _signatures
    ) public {
        require(_users[0] == msg.sender || _users[1] == msg.sender, 'NFTFarmExchange: Unauthorized');

        // prevent stack limit error
        _exchangeTargetForToken(
            Order(_users[0], _target, _targetCalldata, _replacementCalldatas[0], _paymentToken, _priceAmount, _feePercent, _expirationBlocks[0], _nonces[0]),
            _signatures[0],
            Order(_users[1], _target, _targetCalldata, _replacementCalldatas[0], _paymentToken, _priceAmount, _feePercent, _expirationBlocks[1], _nonces[1]),
            _signatures[1],
            _replacementCalldatas[1]
        );
    }

    function _exchangeTargetForToken(Order memory _sellOrder, bytes memory _sellerSignature, Order memory _buyOrder, bytes memory _buyerSignature, bytes memory _targetCalldataReplacement) internal {
        bytes32 sellHash = keccak256(abi.encodePacked(_sellOrder.user, _sellOrder.target, _sellOrder.targetCalldata, _sellOrder.targetCalldataReplacementMask, _sellOrder.paymentToken, _sellOrder.priceAmount, _sellOrder.feePercent, _sellOrder.expirationBlock, _sellOrder.nonce));
        require(_validHash(_sellOrder.user, sellHash, _sellerSignature), 'NFTFarmExchange: invalid seller signature');
        require(closedOrders[sellHash] == false, 'NFTFarmExchange: closed seller order');
        require(_sellOrder.expirationBlock == 0 || _sellOrder.expirationBlock < block.timestamp, 'NFTFarmExchange: expired seller order');

        bytes32 buyHash = keccak256(abi.encodePacked(_buyOrder.user, _buyOrder.target, _buyOrder.targetCalldata, _buyOrder.targetCalldataReplacementMask, _buyOrder.paymentToken, _buyOrder.priceAmount, _buyOrder.feePercent, _buyOrder.expirationBlock, _buyOrder.nonce));
        require(_validHash(_buyOrder.user, buyHash, _buyerSignature), 'NFTFarmExchange: invalid buyer signature');
        require(closedOrders[buyHash] == false, 'NFTFarmExchange: closed buyer order');
        require(_buyOrder.expirationBlock == 0 || _buyOrder.expirationBlock < block.timestamp, 'NFTFarmExchange: expired buyer order');

        require(_sellOrder.user != _buyOrder.user, 'NFTFarmExchange: cannot match myself');
        require(_matchOrder(_sellOrder, _buyOrder), 'NFTFarmExchange: not matched order');

        require(_buyOrder.feePercent >= minimumFeePercent, 'NFTFarmExchange: fee percent too low');
        uint256 priceAmount = _buyOrder.priceAmount;
        uint256 feeAmount = priceAmount.div(100).mul(_buyOrder.feePercent);
        uint256 paymentAmount = priceAmount.sub(feeAmount);
        
        address paymentToken = _buyOrder.paymentToken;
        DelegateProxy buyerProxy = proxies[_buyOrder.user];
        require(buyerProxy.proxyTransferFrom(paymentToken, _buyOrder.user, _sellOrder.user, paymentAmount), 'NFTFarmExchange: failed to send payment amount');
        if (feeAmount > 0) {
            require(buyerProxy.proxyTransferFrom(paymentToken, _buyOrder.user, team, feeAmount), 'NFTFarmExchange: failed to send fee');
        }

        if (_sellOrder.targetCalldataReplacementMask.length > 0 && _targetCalldataReplacement.length > 0) {
            _replaceBytes(_sellOrder.targetCalldata, _targetCalldataReplacement, _sellOrder.targetCalldataReplacementMask);
        }

        DelegateProxy sellerProxy = proxies[_sellOrder.user];
        require(sellerProxy.proxyCall(_sellOrder.target, _sellOrder.targetCalldata), 'NFTFarmExchange: failed to send target');

        closedOrders[sellHash] = true;
        closedOrders[buyHash] = true;

        emit Exchange(sellHash, buyHash, paymentToken, priceAmount, paymentAmount, feeAmount);
    }

    function cancelOrder(
        address _target,
        bytes[2] calldata _targetCalldatas,
        address _paymentToken,
        uint256 _priceAmount,
        uint256 _feePercent,
        uint256 _expirationBlock,
        uint256 _nonce,
        bytes calldata _signature
    ) public {
        bytes32 orderHash = keccak256(abi.encodePacked(msg.sender, _target, _targetCalldatas[0], _targetCalldatas[1], _paymentToken, _priceAmount, _feePercent, _expirationBlock, _nonce));
        require(_validHash(msg.sender, orderHash, _signature), 'NFTFarmExchange: invalid signature');
        require(closedOrders[orderHash] == false, 'NFTFarmExchange: closed seller order');
        closedOrders[orderHash] = true;
        emit CancelOrder(orderHash);
    }

    function _validHash(address _signer, bytes32 _message, bytes memory _signature) internal pure returns(bool) {
        bytes32 signature = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _message));
        return ECDSA.recover(signature, _signature) == _signer;
    }

    function _matchOrder(Order memory orderA, Order memory orderB) internal pure returns(bool) {
        return orderA.target == orderB.target &&
               _equalBytes(orderA.targetCalldata, orderB.targetCalldata) &&
               _equalBytes(orderA.targetCalldataReplacementMask, orderB.targetCalldataReplacementMask) &&
               orderA.paymentToken == orderB.paymentToken &&
               orderA.priceAmount == orderB.priceAmount &&
               orderA.feePercent == orderB.feePercent;
    }

    function _equalBytes(bytes memory a, bytes memory b) internal pure returns(bool equal) {
        if (a.length != b.length) {
            return false;
        }

        uint addr;
        uint addr2;
        uint len = a.length;
        assembly {
            addr := add(a, /*BYTES_HEADER_SIZE*/32)
            addr2 := add(b, /*BYTES_HEADER_SIZE*/32)
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    function _replaceBytes(bytes memory target, bytes memory source, bytes memory mask) internal pure {
        for (uint256 i = 0; i < source.length; i++) {
            if (mask[i] > 0) {
                target[i] = source[i];
            }
        }
    }

    function createProxy() public {
        require(address(proxies[msg.sender]) == address(0), 'NFTFarmExchange: already created proxy');
        DelegateProxy proxy = new DelegateProxy(msg.sender);
        proxies[msg.sender] = proxy;
    }

    function changeTeam(address _team) public onlyOwner {
        team = _team;
    }

    function changeMinimumFeePercent(uint8 _minimumFeePercent) public onlyOwner {
        require(_minimumFeePercent <= 100, 'NFTFarmExchange: invalid percent');
        minimumFeePercent = _minimumFeePercent;
    }
}