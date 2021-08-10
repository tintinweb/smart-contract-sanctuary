// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TokenHelper.sol";

library RewardStreamerLib {
	struct RewardStreamInfo {
		RewardStream[] rewardStreams;
		uint256 deployedAtBlock;
		address rewardToken;
	}

	struct RewardStream {
		uint256[] periodRewards;
		uint256[] periodEnds;
		uint256 rewardStreamCursor;
	}

	/**
	* @notice Will setup the token to use for reward
	* @param rewardTokenAddress The reward token address
	*/
	function setRewardToken(RewardStreamInfo storage rewardStreamInfo, address rewardTokenAddress) public {
		rewardStreamInfo.rewardToken = address(rewardTokenAddress);
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param rewardPerBlock The amount of tokens rewarded per block
	* @param rewardLastBlock The last block of the period
	*/
	function addRewardStream(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint256 rewardPerBlock,
		uint256 rewardLastBlock
	)
		public
		returns (uint256)
	{
		// e.g. current length = 0
		require(rewardStreamIndex <= rewardStreamInfo.rewardStreams.length, "RewardStreamer: you cannot skip an index");

		uint256 tokensInReward;

		if(rewardStreamInfo.rewardStreams.length > rewardStreamIndex) {
			RewardStream storage rewardStream = rewardStreamInfo.rewardStreams[rewardStreamIndex];
			uint256[] storage periodEnds = rewardStream.periodEnds;

			uint periodStart = periodEnds.length == 0
				? rewardStreamInfo.deployedAtBlock
				: periodEnds[periodEnds.length - 1];

			require(periodStart < rewardLastBlock, "RewardStreamer: periodStart must be smaller than rewardLastBlock");

			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds.push(rewardLastBlock);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.push(rewardPerBlock);

			tokensInReward = (rewardLastBlock - periodStart) * rewardPerBlock;
		} else {
			RewardStream memory rewardStream;

			uint periodStart = rewardStreamInfo.deployedAtBlock;
			require(periodStart < rewardLastBlock, "RewardStreamer: periodStart must be smaller than rewardLastBlock");

			rewardStreamInfo.rewardStreams.push(rewardStream);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds.push(rewardLastBlock);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.push(rewardPerBlock);

			tokensInReward = (rewardLastBlock - periodStart) * rewardPerBlock;
		}

		TokenHelper.ERC20TransferFrom(address(rewardStreamInfo.rewardToken), msg.sender, address(this), tokensInReward);

		return tokensInReward;
	}

	/**
	* @notice Get the rewards for a period
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @return (uint256) the total reward
	*/
	function unsafeGetRewardsFromRange(
		RewardStreamInfo storage rewardStreamInfo,
		uint fromBlock,
		uint toBlock
	)
		public
		view
		returns (uint256)
	{
		require(tx.origin == msg.sender, "StakingReward: unsafe function for contract call");

		uint256 currentReward;

		for(uint256 i; i < rewardStreamInfo.rewardStreams.length; i++) {
			currentReward = currentReward + iterateRewards(
				rewardStreamInfo,
				i,
				Math.max(fromBlock, rewardStreamInfo.deployedAtBlock),
				toBlock,
				0
			);
		}

		return currentReward;
	}

	/**
	* @notice Iterate the rewards
	* @param rewardStreamIndex the index of the reward stream
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @param rewardIndex the reward index
	* @return (uint256) the calculate reward
	*/
	function iterateRewards(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint fromBlock,
		uint toBlock,
		uint256 rewardIndex
	)
		public
		view
		returns (uint256)
	{
		// the start block is bigger than
		if(rewardIndex >= rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			return 0;
		}

		uint currentPeriodEnd = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardIndex];
		uint currentPeriodReward = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards[rewardIndex];

		uint256 totalReward = 0;

		// what's the lowest block in current period?
		uint currentPeriodStart = rewardIndex == 0
			? rewardStreamInfo.deployedAtBlock
			: rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardIndex - 1];
		// is the fromBlock included in period?
		if(fromBlock <= currentPeriodEnd) {
			uint256 lower = Math.max(fromBlock, currentPeriodStart);
			uint256 upper = Math.min(toBlock, currentPeriodEnd);

			uint256 blocksInPeriod = upper - lower;
			totalReward = blocksInPeriod * currentPeriodReward;
		} else {
			return iterateRewards(
				rewardStreamInfo,
				rewardStreamIndex,
				fromBlock,
				toBlock,
				rewardIndex + 1
			);
		}

		if(toBlock > currentPeriodEnd) {
			// we need to move to next reward period
			totalReward += iterateRewards(
				rewardStreamInfo,
				rewardStreamIndex,
				fromBlock,
				toBlock,
				rewardIndex + 1
			);
		}

		return totalReward;
	}

	/**
	* @notice Iterate the rewards and updates the cursor
	* @notice NOTE: once the cursor is updated, the next call will start from the cursor
	* @notice making it impossible to calculate twice the reward in a period
	* @param rewardStreamInfo the struct holding  current reward info
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @return (uint256) the calculated reward
	*/
	function getRewardAndUpdateCursor (
		RewardStreamInfo storage rewardStreamInfo,
		uint256 fromBlock,
		uint256 toBlock
	)
		public
		returns (uint256)
	{
		uint256 currentReward;

		for(uint256 i; i < rewardStreamInfo.rewardStreams.length; i++) {
			currentReward = currentReward + iterateRewardsWithCursor(
				rewardStreamInfo,
				i,
				Math.max(fromBlock, rewardStreamInfo.deployedAtBlock),
				toBlock,
				rewardStreamInfo.rewardStreams[i].rewardStreamCursor
			);
		}

		return currentReward;
	}

	function bumpStreamCursor(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex
	)
		public
	{
		// this step is important to avoid going out of index
		if(rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor < rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor = rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor + 1;
		}
	}

	function iterateRewardsWithCursor(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint fromBlock,
		uint toBlock,
		uint256 rewardPeriodIndex
	)
		public
		returns (uint256)
	{
		if(rewardPeriodIndex >= rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			return 0;
		}

		uint currentPeriodEnd = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardPeriodIndex];
		uint currentPeriodReward = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards[rewardPeriodIndex];

		uint256 totalReward = 0;

		// what's the lowest block in current period?
		uint currentPeriodStart = rewardPeriodIndex == 0
			? rewardStreamInfo.deployedAtBlock
			: rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardPeriodIndex - 1];

		// is the fromBlock included in period?
		if(fromBlock <= currentPeriodEnd) {
			uint256 lower = Math.max(fromBlock, currentPeriodStart);
			uint256 upper = Math.min(toBlock, currentPeriodEnd);

			uint256 blocksInPeriod = upper - lower;

			totalReward = blocksInPeriod * currentPeriodReward;
		} else {
			// the fromBlock passed this reward period, we can start
			// skipping it for next reads
			bumpStreamCursor(rewardStreamInfo, rewardStreamIndex);

			return iterateRewards(rewardStreamInfo, rewardStreamIndex, fromBlock, toBlock, rewardPeriodIndex + 1);
		}

		if(toBlock > currentPeriodEnd) {
			// we need to move to next reward period
			totalReward += iterateRewards(rewardStreamInfo, rewardStreamIndex, fromBlock, toBlock, rewardPeriodIndex + 1);
		}

		return totalReward;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import "../Raffle/IRaffleTicket.sol";

library TokenHelper {
	function ERC20Transfer(
		address token,
		address to,
		uint256 amount
	)
		public
	{
		(bool success, bytes memory data) =
				token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20: transfer amount exceeds balance');
	}

    function ERC20TransferFrom(
			address token,
			address from,
			address to,
			uint256 amount
    )
			public
		{
			(bool success, bytes memory data) =
					token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
			require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20: transfer amount exceeds balance or allowance');
    }

    function transferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    )
            public
            returns (bool)
        {
                (bool success,) = token.call(abi.encodeWithSelector(IERC721.transferFrom.selector, from, to, tokenId));

                // in the ERC721 the transfer doesn't return a bool. So we need to check explicitly.
                return success;
    }

    function _mintTickets(
        address ticket,
        address to,
        uint256 amount
    ) public {
        (bool success,) = ticket.call(abi.encodeWithSelector(IRaffleTicket.mint.selector, to, 0, amount));

        require(success, 'ERC1155: mint failed');
    }
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

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


/// @title A mintable NFT ticket for Coinburp Raffle
/// @author Valerio Leo @valerioHQ
interface IRaffleTicket is IERC1155 {
	function mint(address to, uint256 tokenId, uint256 amount) external;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "contracts/Staking/TokenHelper.sol": {
      "TokenHelper": "0xaa7aaa0c937c7af76559c30958773f207a7baab5"
    }
  }
}