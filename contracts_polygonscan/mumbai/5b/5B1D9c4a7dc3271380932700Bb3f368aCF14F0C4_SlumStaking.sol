// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract SlumStaking is ERC721Holder, ERC1155Holder, Ownable {
	// constants
	uint8 public constant MAX_SLUMBO_TICKETS = 3;
	uint8 public constant MAX_SLUMDOGE_TICKETS = 3;
	uint8 public constant MAX_BURNED_TICKETS = 3;

	address public BURN_ADDRESS = address(this); /// fill here, need a burn address, both 721 contract not support burn.

	uint16 public constant SLUMBO_DAILY_REWARD_RATE = 5;
	uint16 public constant SLUMDOGE_DAILY_REWARD_RATE = 20;
	uint16 public constant SLUMBO_BURN_REWARD = 20;
	uint16 public constant SLUMDOGE_BURN_REWARD = 200;

	// events
	event Staked(address indexed sender, uint256[] slumboIds, uint256[] slumdogeIds);
	event UnStaked(address indexed sender, uint256[] slumboIds, uint256[] slumdogeIds);
	event WithdrawReward(address indexed receiver, uint256 reward);
	event BurnSlumbo(address indexed sender, uint256 slumboId, uint256 reward);
	event BurnSlumdoge(address indexed sender, uint256 slumboId, uint256 reward);

	// structs
	struct Ticket {
    	uint256 startTime; // staking start time
		uint256 id; // token id
	}

	struct Stake {
		Ticket[] slumboTickets;
		Ticket[] slumdogeTickets;
	}

	// interfaces
	ISLC public ISLCToken; // ERC20
	ISlumboginis public ISBOToken; // ERC721
	ISlumdogeBillionaires public ISDBToken; // ERC721

	// variables
  	mapping(address => Stake) private investors;
	mapping(address => uint256[2]) public burnts;  // 0 = slumbo, 1 = slumdoge

	constructor() {}

	// stake multiples slumbos and slumdoges
	function stakes(uint256[] calldata _slumboIds, uint256[] calldata _slumdogeIds) external {
		Stake storage staked = investors[msg.sender];
		require(staked.slumboTickets.length + _slumboIds.length <= MAX_SLUMBO_TICKETS, "Stake: Max Slumboginis is 3");
		require(staked.slumdogeTickets.length + _slumdogeIds.length <= MAX_SLUMDOGE_TICKETS, "Stake: Max SlumdogeBillionaires is 3");
		for (uint256 i = 0; i < _slumboIds.length; i++) {
			ISBOToken.safeTransferFrom(msg.sender, address(this), _slumboIds[i]);
			staked.slumboTickets.push(Ticket(block.timestamp, _slumboIds[i]));
		}
		for (uint256 i = 0; i < _slumdogeIds.length; i++) {
			ISDBToken.safeTransferFrom(msg.sender, address(this), _slumdogeIds[i]);
			staked.slumdogeTickets.push(Ticket(block.timestamp, _slumdogeIds[i]));
		}
		emit Staked(msg.sender, _slumboIds, _slumdogeIds);
	}

	// verified
	function unStake() external {
		Stake storage staked = investors[msg.sender];

		uint256 reward = computeDailyReward(msg.sender); // compute reward first

		uint256 slumbos = staked.slumboTickets.length;
		uint256[] memory slumboIds = new uint256[](slumbos);
		for (uint256 i = slumbos; i > 0; i--) {
			ISBOToken.safeTransferFrom(address(this), msg.sender, staked.slumboTickets[i - 1].id); // transfer
			slumboIds[i - 1] = staked.slumboTickets[i - 1].id;
			staked.slumboTickets.pop(); // burn stock
		}

		uint256 slumdoges = staked.slumdogeTickets.length;
		uint256[] memory slumdogeIds = new uint256[](slumdoges);
		for (uint256 i = slumdoges; i > 0; i--) { // transfer
			ISDBToken.safeTransferFrom(address(this), msg.sender, staked.slumdogeTickets[i - 1].id); // transfer
			slumdogeIds[i - 1] = staked.slumdogeTickets[i - 1].id;
			staked.slumdogeTickets.pop(); // burn stock
		}
		if (reward > 0) {
			ISLCToken.transfer(msg.sender, reward); // send remaining reward
		}
		emit UnStaked(msg.sender, slumboIds, slumdogeIds);
	}

	// verified
	function computeDailyReward(address _account) public view returns(uint256) {
		Stake memory staked = investors[_account];
		uint256 reward = 0;

		// slumbo
		uint256 slumbos = staked.slumboTickets.length;
		for (uint256 i = 0; i < slumbos; i++) {
			Ticket memory ticket = staked.slumboTickets[i];
			uint256 unitDays = (block.timestamp - ticket.startTime) / (1 days); // round down.
			reward += SLUMBO_DAILY_REWARD_RATE * unitDays;
		}

		// slumdoge
		uint256 slumdoges = staked.slumdogeTickets.length;
		for (uint256 i = 0; i < slumdoges; i++) {
			Ticket memory ticket = staked.slumdogeTickets[i];
			uint256 unitDays = (block.timestamp - ticket.startTime) / (1 days); // round down.
			reward += SLUMDOGE_DAILY_REWARD_RATE * unitDays;
		}

		return reward;
	}

	// verified
	function resetTimeTicket(address _account) private {
		Stake storage staked = investors[_account];

		uint256 slumbos = staked.slumboTickets.length;
		for (uint256 i = 0; i < slumbos; i++) {
			uint256 unitDays = (block.timestamp - staked.slumboTickets[i].startTime) / (1 days);
			staked.slumboTickets[i].startTime += (unitDays * (1 days));
		}

		uint256 slumdoges = staked.slumdogeTickets.length;
		for (uint256 i = 0; i < slumdoges; i++) {
			uint256 unitDays = (block.timestamp - staked.slumdogeTickets[i].startTime) / (1 days);
			staked.slumdogeTickets[i].startTime += (unitDays * (1 days));
		}
	}

	// verified
	function withdrawReward() external {
		uint256 reward = computeDailyReward(msg.sender);
		require(reward > 0, "Withdraw: Not enough reward");
		ISLCToken.transfer(msg.sender, reward);
		resetTimeTicket(msg.sender);
		emit WithdrawReward(msg.sender, reward);
	}

	// verified
	function withdraw() external onlyOwner {
		uint256 balance = ISLCToken.balanceOf(address(this));
		require(balance > 0, "Withdraw: Not enoungh balance");
		ISLCToken.transfer(msg.sender, balance);
	}



	// verified
	function burnSlumbo(uint256 _slumboId) external {
		require(burnts[msg.sender][0] < MAX_BURNED_TICKETS, 'Burn: Can not burn more than 3 Slumboginis');

		ISBOToken.safeTransferFrom(msg.sender, BURN_ADDRESS, _slumboId);
		ISLCToken.transfer(msg.sender, SLUMBO_BURN_REWARD);
		burnts[msg.sender][0] += 1;
		emit BurnSlumbo(msg.sender, _slumboId, SLUMBO_BURN_REWARD);
	}

	// verified
	function burnSlumdoge(uint256 _slumdogeId) external {
		require(burnts[msg.sender][1] < MAX_BURNED_TICKETS, 'Burn: Can not burn more than 3 SlumdogeBillionaires');

		ISDBToken.safeTransferFrom(msg.sender, BURN_ADDRESS, _slumdogeId);
		ISLCToken.transfer(msg.sender, SLUMDOGE_BURN_REWARD);
		burnts[msg.sender][1] += 1;
		emit BurnSlumdoge(msg.sender, _slumdogeId, SLUMDOGE_BURN_REWARD);
	}

	// verified
	function setRelatedContract(address _slc, address _slumbo, address _slumdoge) external onlyOwner {
		ISLCToken = ISLC(_slc);
		ISBOToken = ISlumboginis(_slumbo);
		ISDBToken = ISlumdogeBillionaires(_slumdoge);
	}

	// view function
	function getTokensStaked() public view returns (Ticket[] memory slumbo, Ticket[] memory slumdoge) {
		return (investors[msg.sender].slumboTickets, investors[msg.sender].slumdogeTickets);
	}
}

interface ISLC is IERC20 {}
interface ISlumboginis is IERC721 {}
interface ISlumdogeBillionaires is IERC721 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}