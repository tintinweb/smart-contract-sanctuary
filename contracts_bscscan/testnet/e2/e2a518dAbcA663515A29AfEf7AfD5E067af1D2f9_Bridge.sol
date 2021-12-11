// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IERC20MintableBurnable.sol";

contract Bridge is Ownable {
    struct TokenInfo {
        address otherToken;
        bool isOrigin;
    }

    struct Message {
        uint256 claimId;
        address token;
        address toAddress;
        uint256 amount;
    }

    /**
     * @dev Emitted when tokens have been teleported
     */
    event Teleport(
        uint256 indexed claimId,
        address indexed token,
        address from,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted when tokens have been claimed
     */
    event Claim(uint256 indexed claimId, address indexed to, uint256 amount);

    mapping(address => TokenInfo) public tokens;
    mapping(address => bool) public validators;
    uint256 public minRequiredValidators;
    mapping(uint256 => bool) public claimed;
    uint256 public fee; // 1000 => 100%, 500 => 50%, 1 => 0.1%
    address public feeReceiver;
    mapping(address => bool) public noFeeAddresses;
    uint256 claimIdCounter = 0;

    constructor(
        uint256 _minRequiredValidators,
        uint256 _fee,
        address _feeReceiver
    ) {
        require(_minRequiredValidators > 0, "Min required validators too low");
        minRequiredValidators = _minRequiredValidators;
        fee = _fee;
        feeReceiver = _feeReceiver;
    }

    function addToken(
        address token,
        address otherToken,
        bool isOtherTokenOrigin
    ) public onlyOwner {
        TokenInfo memory tokenInfo = tokens[token];
        require(tokenInfo.otherToken == address(0), "Token does already exist");
        tokens[token] = TokenInfo({
            otherToken: otherToken,
            isOrigin: isOtherTokenOrigin
        });
    }

    /**
     * @dev Adds an additialnal validator. Validators are used to sign messages for claiming tokens.
     */
    function addValidator(address validator) public onlyOwner {
        require(!validators[validator], "Validator is already registered");

        validators[validator] = true;
    }

    /**
     * @dev Removes a validator.
     */
    function removeValidator(address validator) public onlyOwner {
        require(validators[validator] == true, "Validator is not registered");

        delete validators[validator];
    }

    function setMinRequiredValidators(uint256 _minRequiredValidators)
        public
        onlyOwner
    {
        require(_minRequiredValidators > 0, "Min required validators too low");
        minRequiredValidators = _minRequiredValidators;
    }

    function verifyValidatorAddresses(address[] memory addresses) public view {
        require(
            addresses.length >= minRequiredValidators,
            "Insufficient number of signatures"
        );

        for (uint256 i = 0; addresses.length > i; i++) {
            for (uint256 k = i + 1; addresses.length > k; k++) {
                require(addresses[i] != addresses[k], "Duplicate signature");
            }
            require(validators[addresses[i]], "Invalid signature");
        }
    }

    function parseSignature(bytes memory signatures, uint256 index)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        uint256 offset = index * 0x41;

        assembly {
            r := mload(add(add(signatures, offset), add(0x20, 0x0)))
            s := mload(add(add(signatures, offset), add(0x20, 0x20)))
            v := mload(add(add(signatures, offset), add(0x1, 0x40)))
        }
    }

    function recoverAddresses(bytes memory signatures, bytes32 hash)
        public
        pure
        returns (address[] memory addresses)
    {
        require(signatures.length % 0x41 == 0, "Invalid signatures length");
        uint256 signaturesNum = signatures.length / 0x41;
        addresses = new address[](signaturesNum);
        for (uint256 i = 0; signaturesNum > i; i++) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            (r, s, v) = parseSignature(signatures, i);
            addresses[i] = ecrecover(hash, v, r, s);
        }
    }

    function verifySignatures(bytes memory signatures, bytes32 hash)
        public
        view
    {
        address[] memory addresses = recoverAddresses(signatures, hash);
        verifyValidatorAddresses(addresses);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function addToNoFeeList(address wallet) public onlyOwner {
        noFeeAddresses[wallet] = true;
    }

    function removeFromNoFeeList(address wallet) public onlyOwner {
        delete noFeeAddresses[wallet];
    }

    /**
     * @dev Splits the message into seperate fields.
     */
    function decodeMessage(bytes memory message)
        public
        pure
        returns (Message memory)
    {
        require(message.length == 0x54, "Invalid message length");

        uint256 claimId;
        address token;
        address toAddress;
        uint256 amount;

        assembly {
            claimId := mload(add(message, add(0x20, 0x0)))
            token := mload(add(message, add(0x14, 0x20)))
            toAddress := mload(add(message, add(0x14, 0x34)))
            amount := mload(add(message, add(0x20, 0x48)))
        }

        Message memory decodedMessage;
        decodedMessage.claimId = claimId;
        decodedMessage.token = token;
        decodedMessage.toAddress = toAddress;
        decodedMessage.amount = amount;

        return decodedMessage;
    }

    function createClaimId() private returns (uint256) {
        return ++claimIdCounter;
    }

    /**
     * @dev Locks or burns the sender's tokens to transfer them to the primary side.
     */
    function teleport(
        address token,
        address to,
        uint256 amount
    ) public returns (uint256 claimId) {
        TokenInfo memory tokenInfo = tokens[token];
        require(tokenInfo.otherToken != address(0), "Unknown token");

        uint256 teleportAmount = amount;

        if (!noFeeAddresses[_msgSender()]) {
            uint256 feeAmount = (amount * fee) / 1000;
            teleportAmount = amount - feeAmount;
            IERC20(token).transferFrom(_msgSender(), feeReceiver, feeAmount);
        }

        if (tokenInfo.isOrigin) {
            IERC20MintableBurnable(token).burnFrom(
                _msgSender(),
                teleportAmount
            );
        } else {
            IERC20(token).transferFrom(
                _msgSender(),
                address(this),
                teleportAmount
            );
        }

        claimId = createClaimId();

        emit Teleport(
            claimId,
            tokenInfo.otherToken,
            _msgSender(),
            to,
            teleportAmount
        );
    }

    /**
     * @dev Accepts an validator signed message to transfer/mint tokens to the destination address.
     * A message cannot be used more than once.
     */
    function claim(bytes memory message, bytes memory signatures)
        public
        returns (address toAddress)
    {
        bytes32 messageHash = keccak256(message);
        verifySignatures(signatures, messageHash);
        Message memory decodedMessage = decodeMessage(message);

        require(!claimed[decodedMessage.claimId], "Already claimed");
        claimed[decodedMessage.claimId] = true;

        TokenInfo memory tokenInfo = tokens[decodedMessage.token];
        require(
            tokenInfo.otherToken != address(0),
            "Unknown destination token"
        );

        if (tokenInfo.isOrigin) {
            IERC20MintableBurnable(decodedMessage.token).mint(
                decodedMessage.toAddress,
                decodedMessage.amount
            );
        } else {
            IERC20(decodedMessage.token).transfer(
                decodedMessage.toAddress,
                decodedMessage.amount
            );
        }

        emit Claim(
            decodedMessage.claimId,
            decodedMessage.toAddress,
            decodedMessage.amount
        );

        return decodedMessage.toAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}