pragma solidity ^0.8.0;

import "./Loan.sol";

contract LoanFactory {

    event LoanCreated(address owner, address nftContract, uint nftId, uint duration);
    function requestLoan(address _nftContract, uint _nftId, uint _duration) external {
        require(_duration > block.timestamp, "Loans cannot be settled in the past. Well, unless you are Edgar");
        Loan loan = new Loan(msg.sender, _nftContract, _nftId, _duration);

        emit LoanCreated(msg.sender, _nftContract, _nftId, _duration);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Loan is IERC721Receiver {

    // The address of the loan recipient
    address payable public immutable owner;
    address public immutable nftContract;
    uint256 public immutable nftId;
    // The duration of loan specified by the loan recipient
    uint public immutable duration;

    // Toggled when contract holds NFT
    bool public nftOwned;
    // Current Highest bid
    uint public highestBid = 0;
    // Current highest bidder
    address payable public highestBidder;
    // Amount of loan paid back
    uint public amtRepaid = 0;
    // Toggled when loan is fully paid back or recepient is no longer in need of higher bids
    bool public acceptingBids = false;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // EVENTS
    // Address of new highest bidder and the amount
    event NewHighestBid(address _bidder, uint256 _amount);

    constructor(address _owner, address _nftContract, uint _nftId, uint _duration) public {
        owner = payable(_owner);
        nftContract = _nftContract;
        nftId = _nftId;
        duration = _duration;
    }

    /// @notice Lets people bid on the NFT. The highest bid's amount is transferred to the owner
    function provideLoan() public payable {
        require(acceptingBids, "Currently not accepting bids");
        require(nftOwned, "Contract not in contol of the NFT");
        // Bids lower than the current highest bid are ignored
        require(msg.value > highestBid, "Loan amount less than the one already provided");

        // Logic for the first bidder
        if (highestBidder == address(0)) {
            highestBid = msg.value;
            highestBidder = payable(msg.sender);
            // Transfer the amount to the owner
            owner.transfer(msg.value);
        }
        // From 2nd highest bidder onwards
        else {
            // Transfer the amount of the previous bid to the previously highest bidder
            highestBidder.transfer(highestBid);
            // Tranfer the remaining amount to the owner
            owner.transfer(msg.value - highestBid);
            highestBid = msg.value;
            highestBidder = payable(msg.sender);
        }

        emit NewHighestBid(msg.sender, msg.value);
    }

    /// @notice Let's the owner repay the loan
    function repayLoan() public payable {
        require(nftOwned == true, "No loan was taken");
        require(amtRepaid < highestBid, "Loan already repaid");
        amtRepaid += msg.value;
    }

    /// @notice To be called when duration of the loan has expired. 2 possible scenarios - 
    ///         1. The owner repays the loan and gets the nft back, and he amout is transferred to the highest bidder
    ///         2. The owner does not repay the loan and the nft is transferred to the highest bidder 
    ///            and any amt. repaid by owner is transferred back to the owner
    function liquidate() public {
        require(nftOwned == true, "No loan was taken");
        require(duration < block.timestamp, "Loan still valid");

        // If the owner has not repaid the loan, transfer the nft to the highest bidder
        if (amtRepaid < highestBid) {
            // Transfer NFT to highestBidder
            IERC721(nftContract).safeTransferFrom(address(this), highestBidder, nftId);
            nftOwned = false;
            // Transfer loan repaid amount to owner
            owner.transfer(amtRepaid);
            
            acceptingBids = false;
        }
        // If the owner has repaid the loan, transfer the loan amount to the owner
        else {
            // Transfer NFT to owner
            IERC721(nftContract).safeTransferFrom(address(this), owner, nftId);
            nftOwned = false;
            // Transfer loan amount to highestBidder
            highestBidder.transfer(amtRepaid);

            acceptingBids = false;
        }
    }

    function stopAcceptingBids() public onlyOwner {
        acceptingBids = false;
    }

    function startAcceptingBids() public onlyOwner {
        require(acceptingBids == false, "Already accepting bids");
        require(nftOwned == true, "Not in control of NFT");
        acceptingBids = true;
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == nftContract, "Incorrect NFT contract");
        require(tokenId == nftId, "Incorrect NFT ID");
        require(IERC721(nftContract).ownerOf(tokenId) == address(this), "Did not tranfer the NFT");

        nftOwned = true;

        acceptingBids = true;

        return 0x150b7a02;
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

