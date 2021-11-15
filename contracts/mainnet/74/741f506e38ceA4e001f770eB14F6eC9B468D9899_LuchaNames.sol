// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LuchaNames is Ownable, Pausable {
	uint256 public nameFee = 0;

	struct Name {
		string name;
	}

	mapping(address => mapping(address => bool)) public addressBlacklist;
	mapping(address => mapping(uint256 => Name)) public names;
	mapping(address => mapping(string => bool)) public nameExists;

	event SetName(
		address indexed _originContract,
		address indexed _sender,
		uint256 id,
		string name
	);

	modifier notBlacklisted(address _originContract) {
		require(!addressBlacklist[_originContract][msg.sender], "Address blacklisted");
		_;
	}

	function processName(address _originContract, uint256 _id, string memory _name) internal notBlacklisted(_originContract) whenNotPaused {
		IERC721 erc721 = IERC721(_originContract);
		address tokenOwner = erc721.ownerOf(_id);

		require(tokenOwner == msg.sender, "Caller must be token owner");
		require(bytes(names[_originContract][_id].name).length == 0, "Name is already set");
		require(bytes(_name).length > 0, "Name must not be empty");
		require(bytes(_name).length <= 32, "Name must contain 32 characters or less");
		require(!nameExists[_originContract][toLowerCase(_name)], "Name already exists");
		require(msg.value >= nameFee, "Not enough ETH to cover name fee");

		nameExists[_originContract][toLowerCase(_name)] = true;
		names[_originContract][_id].name = _name;

		emit SetName(_originContract, msg.sender, _id, _name);
	}

	function set1Name(address _originContract, uint256 _id, string memory _name) public payable {
		require(isSafeName(_name), "Name contains invalid characters");
		processName(_originContract, _id, _name);
	}

	function set2Names(address _originContract, uint256 _id, string memory _name1, string memory _name2) public payable {
		require(isSafeName(_name1) && isSafeName(_name2), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2));
		processName(_originContract, _id, name);
	}

	function set3Names(address _originContract, uint256 _id, string memory _name1, string memory _name2, string memory _name3) public payable {
		require(isSafeName(_name1) && isSafeName(_name2) && isSafeName(_name3), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2, ' ', _name3));
		processName(_originContract, _id, name);
	}

	function set4Names(address _originContract, uint256 _id, string memory _name1, string memory _name2, string memory _name3, string memory _name4) public payable {
		require(isSafeName(_name1) && isSafeName(_name2) && isSafeName(_name3) && isSafeName(_name4), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2, ' ', _name3, ' ', _name4));
		processName(_originContract, _id, name);
	}

	function set5Names(address _originContract, uint256 _id, string memory _name1, string memory _name2, string memory _name3, string memory _name4, string memory _name5) public payable {
		require(isSafeName(_name1) && isSafeName(_name2) && isSafeName(_name3) && isSafeName(_name4) && isSafeName(_name5), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2, ' ', _name3, ' ', _name4, ' ', _name5));
		processName(_originContract, _id, name);
	}

	function toLowerCase(string memory _name) internal pure returns (string memory) {
		bytes memory bytesName = bytes(_name);
		bytes memory lowerCase = new bytes(bytesName.length);

		for (uint i = 0; i < bytesName.length; i++) {
				if ((uint8(bytesName[i]) >= 65) && (uint8(bytesName[i]) <= 90)) {
					lowerCase[i] = bytes1(uint8(bytesName[i]) + 32);
				} else {
					lowerCase[i] = bytesName[i];
				}
		}
		return string(abi.encodePacked(lowerCase));
	}

	function isSafeName(string memory _name) public pure returns (bool) {
		bytes memory b = bytes(_name);

		for (uint i; i < b.length; i++) {
			bytes1 char = b[i];

			if (!(char >= 0x41 && char <= 0x5A) && // A-Z
					!(char >= 0x61 && char <= 0x7A)		 // a-z
			) { 
				return false; 
			}
		}
		return true;
	}

	function getName(address _originContract, uint256 _id) public view returns (string memory) {
		return names[_originContract][_id].name;
	}

	function blacklistName(address _originContract, uint256 _id) public onlyOwner {
		names[_originContract][_id].name = '';
	}

	function blacklistAddress (address _originContract, address _address, bool _bool) public onlyOwner {
		addressBlacklist[_originContract][_address] = _bool;
	}

	function setNameFee(uint256 _nameFee) public onlyOwner {
		nameFee = _nameFee;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function withdraw() public onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}('');
		require(success, "Withdrawal failed");
	}

	receive() external payable {}
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

