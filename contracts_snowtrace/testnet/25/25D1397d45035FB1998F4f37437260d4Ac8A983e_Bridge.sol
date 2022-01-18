// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../interfaces/IERC20MintBurnable.sol';

contract Bridge is Ownable {
	struct TokenInfo {
		address otherToken;
		uint256 originChainId;
	}

	struct Message {
		bytes32 claimId;
		uint256 srcChainId;
		uint256 destChainId;
		address destToken;
		address srcAddress;
		address destAddress;
		uint256 amount;
	}

	mapping(address => mapping(uint256 => TokenInfo)) public tokens; // token => otherChainId => tokenInfo
	mapping(address => bool) public validators;
	uint256 public minRequiredValidators;
	mapping(bytes32 => bool) public claimed;
	uint256 public fee; // 1000 => 100%, 500 => 50%, 1 => 0.1%
	address public feeReceiver;
	mapping(address => bool) public noFeeAddresses;
	uint256 claimIdCounter = 0;

	/**
	 * @dev Emitted when tokens have been teleported
	 */
	event Teleport(
		bytes32 indexed claimId,
		uint256 indexed destChainId,
		address srcToken,
		address indexed destToken,
		address srcAddress,
		address destAddress,
		uint256 amount,
		uint256 decimals
	);

	/**
	 * @dev Emitted when tokens have been claimed
	 */
	event Claim(
		bytes32 indexed claimId,
		uint256 indexed srcChainId,
		address indexed srcToken,
		address destToken,
		address srcAddress,
		address destAddress,
		uint256 amount,
		uint256 decimals
	);

	constructor(
		uint256 _minRequiredValidators,
		uint256 _fee,
		address _feeReceiver
	) {
		require(_minRequiredValidators > 0, 'MIN VALIDATORS TOO LOW');
		require(_fee <= 1000, 'INVALID FEE');
		require(_feeReceiver != address(0), 'ZERO ADDRESS');
		minRequiredValidators = _minRequiredValidators;
		fee = _fee;
		feeReceiver = _feeReceiver;
	}

	/**
	 * @dev Locks or burns the sender's tokens to transfer them to the primary side.
	 */
	function teleport(
		uint256 destChainId,
		address srcToken,
		address destAddress,
		uint256 amount
	) external {
		require(destChainId > 0, 'ZERO CHAIN ID');
		require(srcToken != address(0) && destAddress != address(0), 'ZERO ADDRESS');
		require(amount > 0, 'ZERO AMOUNT');
		TokenInfo memory destTokenInfo = tokens[srcToken][destChainId];
		require(destTokenInfo.otherToken != address(0), 'UNKNOWN TOKEN');

		uint256 teleportAmount = amount;

		if (!noFeeAddresses[_msgSender()]) {
			uint256 feeAmount = (amount * fee) / 1000;
			teleportAmount = amount - feeAmount;
			require(IERC20(srcToken).transferFrom(_msgSender(), feeReceiver, feeAmount), 'TRANSFER FAILED');
		}

		if (destTokenInfo.originChainId == getChainId()) {
			require(IERC20(srcToken).transferFrom(_msgSender(), address(this), teleportAmount), 'TRANSFER FAILED');
		} else {
			IERC20MintBurnable(srcToken).burnFrom(_msgSender(), teleportAmount);
		}

		bytes32 claimId = createClaimId();

		emit Teleport(
			claimId,
			destChainId,
			srcToken,
			destTokenInfo.otherToken,
			_msgSender(),
			destAddress,
			teleportAmount,
			IERC20Metadata(srcToken).decimals()
		);
	}

	/**
	 * @dev Accepts an validator signed message to transfer/mint tokens to the destination address.
	 * A message cannot be used more than once.
	 */
	function claim(bytes memory message, bytes[] memory signatures) external {
		bytes32 messageHash = keccak256(message);
		verifySignatures(signatures, messageHash);
		Message memory decodedMessage = decodeMessage(message);

		require(decodedMessage.srcChainId > 0, 'ZERO CHAIN ID');
		require(decodedMessage.destChainId == getChainId(), 'INVALID CHAIN ID');
		require(
			decodedMessage.destToken != address(0) &&
				decodedMessage.srcAddress != address(0) &&
				decodedMessage.destAddress != address(0),
			'ZERO ADDRESS'
		);
		require(decodedMessage.amount > 0, 'ZERO AMOUNT');

		require(!claimed[decodedMessage.claimId], 'ALREADY CLAIMED');
		claimed[decodedMessage.claimId] = true;

		TokenInfo memory srcTokenInfo = tokens[decodedMessage.destToken][decodedMessage.srcChainId];
		require(srcTokenInfo.otherToken != address(0), 'UNKNOWN TOKEN');

		if (srcTokenInfo.originChainId == getChainId()) {
			require(
				IERC20(decodedMessage.destToken).transfer(decodedMessage.destAddress, decodedMessage.amount),
				'TRANSFER FAILED'
			);
		} else {
			IERC20MintBurnable(decodedMessage.destToken).mint(decodedMessage.destAddress, decodedMessage.amount);
		}

		emit Claim(
			decodedMessage.claimId,
			decodedMessage.srcChainId,
			srcTokenInfo.otherToken,
			decodedMessage.destToken,
			decodedMessage.srcAddress,
			decodedMessage.destAddress,
			decodedMessage.amount,
			IERC20Metadata(decodedMessage.destToken).decimals()
		);
	}

	/**
	 * @dev Adds an additialnal validator. Validators are used to sign messages for claiming tokens.
	 */
	function addValidator(address validator) external onlyOwner {
		validators[validator] = true;
	}

	/**
	 * @dev Removes a validator.
	 */
	function removeValidator(address validator) external onlyOwner {
		delete validators[validator];
	}

	function setMinRequiredValidators(uint256 _minRequiredValidators) external onlyOwner {
		require(_minRequiredValidators > 0, 'ZERO MIN VALIDATORS');
		minRequiredValidators = _minRequiredValidators;
	}

	function addToken(
		address token,
		uint256 otherChainId,
		address otherToken,
		uint256 originChainId
	) external onlyOwner {
		require(otherChainId > 0 && originChainId > 0, 'ZERO CHAIN ID');
		require(token != address(0) && otherToken != address(0), 'ZERO ADDRESS');
		TokenInfo memory tokenInfo = tokens[token][otherChainId];
		require(tokenInfo.otherToken == address(0), 'TOKEN EXISTS');
		tokens[token][otherChainId] = TokenInfo({otherToken: otherToken, originChainId: originChainId});
	}

	function removeToken(address token, uint256 otherChainId) external onlyOwner {
		delete tokens[token][otherChainId];
	}

	function setFee(uint256 _fee) external onlyOwner {
		require(_fee <= 1000, 'INVALID FEE');
		fee = _fee;
	}

	function setFeeReceiver(address _feeReceiver) external onlyOwner {
		require(_feeReceiver != address(0), 'ZERO ADDRESS');
		feeReceiver = _feeReceiver;
	}

	function addToNoFeeList(address wallet) external onlyOwner {
		noFeeAddresses[wallet] = true;
	}

	function removeFromNoFeeList(address wallet) external onlyOwner {
		delete noFeeAddresses[wallet];
	}

	function createClaimId() private returns (bytes32) {
		return keccak256(abi.encodePacked(address(this), getChainId(), ++claimIdCounter));
	}

	function getChainId() private view returns (uint256 chainId) {
		assembly {
			chainId := chainid()
		}
	}

	function verifySignatures(bytes[] memory signatures, bytes32 hash) private view {
		address[] memory addresses = recoverAddresses(signatures, hash);
		verifyValidatorAddresses(addresses);
	}

	function recoverAddresses(bytes[] memory signatures, bytes32 hash)
		private
		pure
		returns (address[] memory addresses)
	{
		addresses = new address[](signatures.length);
		for (uint256 i = 0; signatures.length > i; i++) {
			bytes32 r;
			bytes32 s;
			uint8 v;
			(r, s, v) = parseSignature(signatures[i]);
			addresses[i] = ecrecover(hash, v, r, s);
		}
	}

	function parseSignature(bytes memory signature)
		private
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		assembly {
			r := mload(add(signature, add(0x20, 0x0)))
			s := mload(add(signature, add(0x20, 0x20)))
			v := mload(add(signature, add(0x1, 0x40)))
		}
	}

	function verifyValidatorAddresses(address[] memory addresses) private view {
		require(addresses.length >= minRequiredValidators, 'SIGNATURE NUMBER TOO LOW');

		for (uint256 i = 0; minRequiredValidators > i; i++) {
			for (uint256 k = i + 1; minRequiredValidators > k; k++) {
				require(addresses[i] != addresses[k], 'DUPLICATE SIGNATURE');
			}
			require(validators[addresses[i]], 'INVALID SIGNATURE');
		}
	}

	/**
	 * @dev Splits the message into seperate fields.
	 */
	function decodeMessage(bytes memory message) private pure returns (Message memory decodedMessage) {
		require(message.length == 4 * 0x20 + 3 * 0x14, 'MESSAGE LENGTH');

		bytes32 claimId;
		uint256 srcChainId;
		uint256 destChainId;
		address destToken;
		address srcAddress;
		address destAddress;
		uint256 amount;

		assembly {
			claimId := mload(add(message, add(0x20, 0x0)))
			srcChainId := mload(add(message, add(0x20, 0x20)))
			destChainId := mload(add(message, add(0x20, 0x40)))
			destToken := mload(add(message, add(0x14, 0x60)))
			srcAddress := mload(add(message, add(0x14, 0x74)))
			destAddress := mload(add(message, add(0x14, 0x88)))
			amount := mload(add(message, add(0x20, 0x9c)))
		}

		decodedMessage.claimId = claimId;
		decodedMessage.srcChainId = srcChainId;
		decodedMessage.destChainId = destChainId;
		decodedMessage.destToken = destToken;
		decodedMessage.srcAddress = srcAddress;
		decodedMessage.destAddress = destAddress;
		decodedMessage.amount = amount;

		return decodedMessage;
	}
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20MintBurnable is IERC20 {
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