/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Flashmint.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0 >=0.8.6 <0.9.0;

////// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

/* pragma solidity ^0.8.0; */

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

////// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

/* pragma solidity ^0.8.0; */

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

////// src/Flashmint.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; */
/* import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; */
/* import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; */

contract Flashmint is IERC721Receiver, ReentrancyGuard {

    /// -------------------------
    /// === TOKEN INFORMATION ===
    /// -------------------------

    /// @notice the ERC721 token address of this vault's token
    address public token;
    
    /// @notice the erc721 token ID of this vault's token
    uint256 public id;
    
    /// -------------------------
    /// === VAULT INFORMATION ===
    /// -------------------------

    /// @notice the user who initially deposited the NFT
    address public depositor;

    /// @notice the price a lender must pay to loan the NFT. in ether, ie 18 decimals (10**18 = 1)
    uint256 public fee;

    enum State { NOT_ACTIVE, ACTIVE, FINISHED } 
    State public vaultState;
    
    /// -------------------------
    /// === MINT INFORMATION ===
    /// -------------------------

    enum FlightStatus {
        READY,
        INFLIGHT,
        LANDED
    }
    struct MintRequest {
        FlightStatus flightStatus;
        address expectedNFTContractAddress;
        uint256 newid; // @notice this is only defined if flightStatus != READY
    }
    /// @notice state variable is needed to track a mint request because 
    /// we're reliant on the ERC721Receiver callback to get id
    MintRequest private req;

    /// -------------------------
    /// ======== EVENTS ========
    /// -------------------------

    /// @notice Emitted when `minter` borrows this NFT to mint `minted`
    event Flashminted(address indexed minter, address indexed minted, uint256 tokenId, uint256 fee);
    
    /// @notice Emitted when initial depositor reclaims their NFT and ends this contract.
    event Closed(address depositor);

    /// @notice Emitted when the claimer cashes out their fees
    event Cash(address depositor, uint256 amount);

    /// @notice Emitted when the cost is updated
    event FeeUpdated(uint256 amount);

    constructor () {
        vaultState = State.NOT_ACTIVE;
    }

    /// ---------------------------
    /// === LIFECYCLE FUNCTIONS ===
    /// ---------------------------

    function initializeWithNFT(address _token, uint256 _id, address _depositor, uint256 _fee) external {
        require(vaultState == State.NOT_ACTIVE, "already active");
        token = _token;
        id = _id;
        vaultState = State.ACTIVE;
        depositor = _depositor;
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /// @notice allow the depositor to reclaim their NFT, ending this flashmint
    function withdrawNFT() external nonReentrant {
        require(msg.sender == depositor, "Not authorized");
        vaultState = State.FINISHED;

        IERC721(token).safeTransferFrom(address(this), msg.sender, id);

        emit Closed(msg.sender);
    }

    /// @notice allow anyone to forward payments to the depositor
    function withdrawEth() external nonReentrant {
        require(vaultState != State.NOT_ACTIVE);
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(depositor).call{value: amount}("");
        require(sent, "send call failed");

        emit Cash(depositor, amount);
    }

    /// @notice allow the depositor to update their fee
    function updateFee(uint256 _fee) external nonReentrant {
        require(msg.sender == depositor, "not depositor");
        
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /// ---------------------------
    /// === FLASHMINT FUNCTIONS ===
    /// ---------------------------

    /// @notice mint a derivative NFT and send it to the caller
    /// @notice derivative must use `_safeMint` because need onERC721Received callback
    /// @param _derivativeNFT the NFT user would like to mint
    /// @param _mintData data for the mint function ie abi.encodeWithSignature(...)
    function lendToMint (
        address _derivativeNFT, 
        bytes calldata _mintData
    ) external payable nonReentrant {
        require(vaultState == State.ACTIVE, "vault not active");
        require(msg.value >= fee, "didn't send enough eth");

        require(_derivativeNFT != address(this), "must call another contract");
        require(_derivativeNFT != token, "must call another contract");
        require(_derivativeNFT != depositor, "must call another contract");

        // request data is updated by nested functions, ie onERC721Received
        req = MintRequest({
            flightStatus: FlightStatus.INFLIGHT,
            expectedNFTContractAddress: _derivativeNFT,
            newid: 0
        });

        // mint the derivative and make sure we got it
        (bool success, ) = _derivativeNFT.call{value: msg.value - fee}(_mintData);
        require(success, "call to mint from derivative failed");
        require(req.flightStatus == FlightStatus.LANDED, "Haven't gotten onERC721 callback. Contract might not use safeTransfer");

        // Note: also asserts token _exists() and that we own it.
        IERC721(_derivativeNFT).safeTransferFrom(address(this), msg.sender, req.newid);

        emit Flashminted(msg.sender, _derivativeNFT, req.newid, fee);
        // reset state variable for next calls.
        req = MintRequest({
            flightStatus: FlightStatus.READY,
            expectedNFTContractAddress: address(0),
            newid: 0
        });
        require(IERC721(token).ownerOf(id) == address(this), "attempted steal");
    }

    function onERC721Received(
        address, 
        address, 
        uint256 _id, 
        bytes calldata
    ) external virtual override returns (bytes4) {
        if (req.flightStatus == FlightStatus.INFLIGHT
            && msg.sender == req.expectedNFTContractAddress
        ){
            // we're receiving the expected derivative
            req.flightStatus = FlightStatus.LANDED;
            req.newid   = _id;
        }

        // Note: can still receive other NFTs
        return this.onERC721Received.selector;
    }

    receive() external payable{}
}