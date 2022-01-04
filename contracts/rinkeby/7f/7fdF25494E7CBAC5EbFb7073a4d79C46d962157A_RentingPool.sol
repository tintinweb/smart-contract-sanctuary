// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IOperable.sol";
import "./IFlashRenter.sol";

contract RentingPool is ERC721Holder {
    event AddNft(
        address indexed nftAddress,
        uint256 indexed nftId,
        uint256 flashFee,
        uint256 pricePerBlock,
        uint256 maxLongTermBlocks
    );

    event EditNft(
        address indexed nftAddress,
        uint256 indexed nftId,
        uint256 flashFee,
        uint256 pricePerBlock,
        uint256 maxLongTermBlocks
    );

    event RemoveNft(address indexed nftAddress, uint256 indexed nftId);

    event WithdrawEarnings(address indexed initiator, uint256 earnings);

    event FlashLoan(
        address indexed nftAddress,
        uint256 indexed nftId,
        address indexed initiator
    );

    event LongTermRent(
        address indexed nftAddress,
        uint256 indexed nftId,
        uint256 blocks,
        address indexed retner
    );

    event TokenOperatorSet(
        address indexed nftAddress,
        uint256 indexed nftId,
        address indexed operator
    );

    struct Key {
        address nftAddress;
        uint256 nftId;
    }

    struct PoolNFT {
        address originalOwner;
        address operator;
        uint256 flashFee;
        uint256 pricePerBlock;
        uint256 maxLongTermBlocks;
        uint256 rentedUntil;
        bool isRentable;
        uint256 index;
    }

    // Mapping from NFT to details
    mapping(address => mapping(uint256 => PoolNFT)) public poolNft;

    // Array for enumarating the NFT collection
    Key[] public poolIndex;

    // Mapping of earnings of each user of the pool
    mapping(address => uint256) private earnings;

    function numberOfNFTsInPool() external view returns (uint256 count) {
        return poolIndex.length;
    }

    /**
     * @dev Add your NFT to the pool
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token you want to add
     * @param flashFee - The fee user has to pay for a single flash loan
     * @param pricePerBlock - The price per block for long term renting
     * @param maxLongTermBlocks - Maximum amount of blocks for longterm rent
     * Requirements:
     *
     * - Caller should be owner of the nft
     * Emits an {AddNft} event.
     */
    function addNft(
        address nftAddress,
        uint256 nftId,
        uint256 flashFee,
        uint256 pricePerBlock,
        uint256 maxLongTermBlocks
    ) external {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), nftId);

        bool isRentable = IERC165(nftAddress).supportsInterface(
            type(IOperable).interfaceId
        );

        uint256 index = poolIndex.length;

        poolNft[nftAddress][nftId] = PoolNFT(
            msg.sender,
            msg.sender,
            flashFee,
            pricePerBlock,
            maxLongTermBlocks,
            0,
            isRentable,
            index
        );

        poolIndex.push(Key(nftAddress, nftId));

        // When the token is transfered the protocol becomes the operator
        if (isRentable) {
            IOperable(nftAddress).setOperator(nftId, msg.sender);
        }

        emit AddNft(
            nftAddress,
            nftId,
            flashFee,
            pricePerBlock,
            maxLongTermBlocks
        );
    }

    /**
     * @dev Edit your NFT prices
     *
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token you have in the pool
     * @param flashFee - The fee user has to pay for a flash loan
     * @param pricePerBlock - The price per block for long term renting
     * @param maxLongTermBlocks - Maximum amount of blocks for longterm rent
     * Requirements:
     *
     * - Caller should be originalOwner of the nft
     * Emits an {EditNft} event.
     */
    function editNft(
        address nftAddress,
        uint256 nftId,
        uint256 flashFee,
        uint256 pricePerBlock,
        uint256 maxLongTermBlocks
    ) external {
        PoolNFT storage nft = poolNft[nftAddress][nftId];

        require(
            nft.originalOwner == msg.sender,
            "Caller should be original owner of the nft"
        );

        nft.flashFee = flashFee;
        nft.pricePerBlock = pricePerBlock;
        nft.maxLongTermBlocks = maxLongTermBlocks;

        emit EditNft(
            nftAddress,
            nftId,
            flashFee,
            pricePerBlock,
            maxLongTermBlocks
        );
    }

    /**
     * @dev Remove your NFT from the pool
     *
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token you have in the pool
     * Requirements:
     *
     * - Caller should be originalOwner of the nft
     * Emits an {RemoveNft} event.
     */
    function removeNft(address nftAddress, uint256 nftId) external {
        PoolNFT storage nft = poolNft[nftAddress][nftId];

        require(
            nft.originalOwner == msg.sender,
            "Caller should be original owner of the nft"
        );

        require(
            nft.rentedUntil < block.number,
            "Can't remove nft from the pool while it is rented"
        );

        uint256 nftToDelete = poolNft[nftAddress][nftId].index;
        Key storage keyToMove = poolIndex[poolIndex.length - 1];
        poolIndex[nftToDelete] = keyToMove;
        poolNft[keyToMove.nftAddress][keyToMove.nftId].index = nftToDelete;
        poolIndex.pop();
        delete poolNft[nftAddress][nftId];

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, nftId);

        emit RemoveNft(nftAddress, nftId);
    }

    /**
     * @dev Withdraw earnings of your NFT
     *
     * Emits an {EditNft} event.
     */
    function withdrawEarnings() external {
        uint256 transferAmount = earnings[msg.sender];
        earnings[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: transferAmount}("");
        require(success, "Transfer failed");

        emit WithdrawEarnings(msg.sender, transferAmount);
    }

    /**
     * @dev Execute a Flashloan of NFT
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token you want to flashloan
     * @param receiverAddress - the contract that will receive the NFT (has to implement IFlashRenter interface)
     * @param data - calldata that will be passed to the receiver contract (optional)
     * Requirments:
     *
     * - you are operator or flashFee is sent
     * Emits a {FlashLoan} event
     */
    function flashLoan(
        address nftAddress,
        uint256 nftId,
        address receiverAddress,
        bytes calldata data
    ) external payable {
        PoolNFT storage nft = poolNft[nftAddress][nftId];

        bool isRented = nft.rentedUntil >= block.number;

        if (isRented) {
            require(
                nft.operator == msg.sender,
                "This NFT is rented and only the operator can flash loan it"
            );
        }

        uint256 flashFee = nft.operator == msg.sender ? 0 : nft.flashFee;

        require(
            msg.value >= flashFee,
            "You can't take the flashloan for the indicated price"
        );

        IERC721(nftAddress).safeTransferFrom(
            address(this),
            receiverAddress,
            nftId
        );

        if (!isRented && nft.isRentable) {
            IOperable(nftAddress).setOperator(nftId, receiverAddress);
        }

        require(
            IFlashRenter(receiverAddress).onFlashLoan(
                nftAddress,
                nftId,
                flashFee,
                msg.sender,
                data
            ),
            "Error during FlashRenter execution"
        );

        if (!isRented && nft.isRentable) {
            IOperable(nftAddress).setOperator(nftId, nft.operator);
        }

        IERC721(nftAddress).safeTransferFrom(
            receiverAddress,
            address(this),
            nftId
        );

        earnings[nft.originalOwner] += msg.value;

        emit FlashLoan(nftAddress, nftId, msg.sender);
    }

    /**
     * @dev Rent nft for number of blocks
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token you want to rent
     * @param receiverAddress - who is renting the NFT
     * Requirments:
     *
     * - the NFT is not currently rented
     * - you pay the price
     * Emits a {LongTermRent} event
     */
    function rentLong(
        address nftAddress,
        uint256 nftId,
        address receiverAddress,
        uint256 blocks
    ) external payable {
        PoolNFT storage nft = poolNft[nftAddress][nftId];

        require(nft.pricePerBlock > 0, "The nft is not available");

        require(nft.rentedUntil < block.number, "The nft is currently rented");

        require(
            nft.maxLongTermBlocks <= blocks,
            "You can't rent this nft for so long"
        );

        require(
            nft.pricePerBlock * blocks <= msg.value,
            "Payment is not enough"
        );

        nft.operator = receiverAddress;
        nft.rentedUntil = block.number + blocks;

        earnings[nft.originalOwner] += msg.value;

        if (nft.isRentable) {
            IOperable(nftAddress).setOperator(nftId, receiverAddress);
        }

        emit LongTermRent(nftAddress, nftId, blocks, receiverAddress);
    }

    /**
     * @dev Get current nft operator
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token
     */
    function operatorOf(address nftAddress, uint256 nftId)
        external
        view
        returns (address operator)
    {
        return poolNft[nftAddress][nftId].operator;
    }

    /**
     * @dev Set token operator
     * @param nftAddress - The address of NFT contract
     * @param nftId - Id of the NFT token
     * @param operator - who becomes the next operator
     * Requirments:
     *
     * - msg.sender is the original token owner
     * - the nft is not currently rented
     * Emits {TokenOperatorSet} event
     */
    function setTokenOperator(
        address nftAddress,
        uint256 nftId,
        address operator
    ) external {
        PoolNFT storage nft = poolNft[nftAddress][nftId];

        require(
            msg.sender == nft.originalOwner,
            "Caller should be original owner of the nft"
        );

        require(
            nft.rentedUntil < block.number,
            "Can't set operator while token is rented"
        );

        nft.operator = operator;

        if (nft.isRentable) {
            IOperable(nftAddress).setOperator(nftId, operator);
        }

        emit TokenOperatorSet(nftAddress, nftId, operator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IOperable is IERC165 {
    event OperatorChanged(uint256 indexed tokenId, address indexed operator);

    /**
     * @dev Returns the operator of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function operatorOf(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns the number of tokens `operator` operates.
     */
    function operatingBalance(address operator)
        external
        view
        returns (uint256 balance);

    /**
     * @dev Sets operator to `tokenId`
     *
     * The operator is automatically set to owner when token is transfered
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {OperatorChanged} event.
     */
    function setOperator(uint256 tokenId, address operator) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFlashRenter {
    function onFlashLoan(
        address nftAddress,
        uint256 nftId,
        uint256 fee,
        address initiator,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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