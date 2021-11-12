/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity 0.5.1;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
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
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
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
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * [`eth_sign`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign)
     * JSON-RPC method.
     *
     * See `recover`.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they not should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, with should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // -----------------------------------------
    // MODIFIERS
    // -----------------------------------------

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // -----------------------------------------
    // SETTERS
    // -----------------------------------------

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @title BlackList
 * @dev Contract where the owner of contract can add or remove addresses from black list
 */
contract BlackList is Context, Ownable {
    mapping(address => bool) private _blackList;

    event AccountBlocked(address indexed account);
    event AccountUnblocked(address indexed account);

    // -----------------------------------------
    // MODIFIERS
    // -----------------------------------------

    modifier isNotBlocked() {
        require(!_blackList[_msgSender()], "isNotBlocked: caller is blocked");
        _;
    }

    modifier isBlocked() {
        require(_blackList[_msgSender()], "isBlocked: caller is not blocked");
        _;
    }

    // -----------------------------------------
    // SETTERS
    // -----------------------------------------

    function blockAccount(address account) public onlyOwner isNotBlocked {
        _blockAccount(account);
    }

    function unblockAccount(address account) public onlyOwner isBlocked {
        _unblockAccount(account);
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    function isAccountBlocked(address account) public view returns (bool) {
        return _blackList[account];
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    function _blockAccount(address account) internal {
        _blackList[account] = true;
        emit AccountBlocked(account);
    }

    function _unblockAccount(address account) internal {
        _blackList[account] = false;
        emit AccountUnblocked(account);
    }
}

/**
 * @dev Stixex main smart contract for receiving investments
 */
contract Stixex is BlackList, Pausable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    uint256 private _minAllowedAmount = 10 finney;      // 0.01 ETH

    struct Session {
        bool open;
        uint256 amount;
    }

    struct User {
        uint256 totalFunded;
        uint256 totalProfit;
        uint256 activeSessionId;
        mapping(uint256 => Session) sessions;
    }

    mapping(address => User) private _users;

    modifier amountAllowed {
        require(msg.value >= _minAllowedAmount, "allowedAmount: deposited amount is smaller than minimum allowed limit");
        _;
    }

    event Deposited(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

    // -----------------------------------------
    // FALLBACK
    // -----------------------------------------

    function () external payable {
        deposit(msg.sender);
    }

    // -----------------------------------------
    // SETTERS
    // -----------------------------------------

    function deposit(address sender) public payable isNotBlocked whenNotPaused amountAllowed {
        // close previues session if its exist
        _closeCurrentSession(sender);

        // init new session
        _initNewSession(sender, msg.value);

        // update total funded amount of sender
        _updateUserTotalFunds(sender, msg.value);

        emit Deposited(sender, msg.value);
    }

    function withdraw(uint256 amount, uint256 userSessionId, bytes memory signature) public {
        address payable receiver = msg.sender;
        address signer = getSignerAddress(receiver, amount, userSessionId, signature);

        require(signer == owner(), "withdraw: only the owners' signed messages can been processed");
        require(_users[receiver].sessions[userSessionId].open == true, "withdraw: amount for this session already payed or not active yet");

        //  close current session
        _closeCurrentSession(receiver);

        // update user total profit with amount
        _updateUserTotalProfit(receiver, amount);

        // transfer eth to user
        _withdrawEth(receiver, amount);
    }

    function changeMinLimit(uint256 newMinAllowedAmount) public onlyOwner {
        _minAllowedAmount = newMinAllowedAmount;
    }

    function withdrawAdmin(uint256 amount) public onlyOwner {
        _withdrawEth(msg.sender, amount);
    }

    function depositAdmin() public payable onlyOwner {
        emit Deposited(msg.sender, msg.value);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    function _initNewSession(address user, uint256 amount) private {
        uint256 activeSessionId = _getUserActiveSession(user);

        // update session information
        _users[user].sessions[activeSessionId] = Session(true, amount);
    }

    function _closeCurrentSession(address user) private {
        uint256 activeSessionId = _getUserActiveSession(user);
        bool isOpen = _users[user].sessions[activeSessionId].open == true;
        if (isOpen) {
            // update session state
            _users[user].sessions[activeSessionId].open = false;

            // update active session id
            _users[user].activeSessionId += 1;
        }
    }

    function _getUserActiveSession(address user) private view returns (uint256) {
        return  _users[user].activeSessionId;
    }

    function _withdrawEth(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
        emit Withdraw(receiver, amount);
    }

    function _updateUserTotalProfit(address user, uint256 amount) private {
        // update user profit amount
        _users[user].totalProfit = _users[user].totalProfit.add(amount);
    }

    function _updateUserTotalFunds(address user, uint256 amount) private {
        // update user total funded amount
        _users[user].totalFunded = _users[user].totalFunded.add(amount);
    }


    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    function getAllowedMinLimit() external view returns (uint256) {
        return _minAllowedAmount;
    }

    function getUserActiveSessionId(address user) external view returns (uint256) {
        return _getUserActiveSession(user);
    }

    function getUserTotalProfit(address user) external view returns (uint256) {
        return _users[user].totalProfit;
    }

    function getUserTotalFunded(address user) external view returns (uint256) {
        return _users[user].totalFunded;
    }

    function getUserSessionData(address user, uint256 sessionId) external view returns (uint256, bool) {
        return (
            _users[user].sessions[sessionId].amount,
            _users[user].sessions[sessionId].open
        );
    }

    // -----------------------------------------
    // ECDSA GETTERS
    // -----------------------------------------

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return hash.toEthSignedMessageHash();
    }

    function getSignerAddress(
        address receiver,
        uint256 amount,
        uint256 userSessionId,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                receiver,
                amount,
                userSessionId
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }
}