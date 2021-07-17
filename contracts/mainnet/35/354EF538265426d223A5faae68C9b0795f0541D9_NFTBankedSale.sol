/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity 0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract NFTBankedSale {

    struct SwapDeal {
        // Buyer's info: ERC-20
        address token;
        address buyer;
        uint price;

        // Bank's info: same ERC-20
        address bank;
        uint transferred;

        // Seller's info: ERC-721
        address collection;
        address seller;
        uint tokenId;
    }

    SwapDeal public swapDeal;

    /**
     * @dev Creates the contract instance and saves the parameters of the swap.
     * @param token address The address of the ERC20 token used to buy.
     * @param buyer address The address of the buyer using ERC20 tokens.
     * @param price uint The quantity of ERC20 tokens given by the buyer when buying.
     * @param bank address The address of the bank that provides additional ERC20 tokens when buying.
     * @param transferred uint The quantity of ERC20 tokens given by the bank when buying.
     * @param collection address The address of the ERC721 token collection exchanged.
     * @param seller address The address of the seller of the ERC721 token.
     * @param tokenId uint The id of the ERC721 token sold.
     */
    constructor(address token, address buyer, uint price, address bank, uint transferred, address collection, address seller, uint tokenId) public {
        require(token != address(0), "NFTBankedSale: ERC20 token is missing");
        require(buyer != address(0), "NFTBankedSale: buyer is missing");
        require(price != 0, "NFTBankedSale: price is missing");
        require(bank != address(0), "NFTBankedSale: bank is missing");
        require(transferred != 0, "NFTBankedSale: transferred is missing");
        require(collection != address(0), "NFTBankedSale: ERC721 collection is missing");
        require(seller != address(0), "NFTBankedSale: seller is missing");
        require(tokenId != 0, "NFTBankedSale: tokenId is missing");
        swapDeal = SwapDeal({
            token: token,
            buyer: buyer,
            price: price,
            bank: bank,
            transferred: transferred,
            collection: collection,
            seller: seller,
            tokenId: tokenId
        });
    }

    /**
     * @dev Does the 3 transfers constituting the swap.
     * All seller, bank and buyer must have approved this swap contract as a spender of their respective tokens
     * for the swap to proceed.
     * The function can be called by anyone.
     */
    function swap() public {
        SwapDeal memory deal = swapDeal;
        delete swapDeal;
        IERC721(deal.collection).safeTransferFrom(deal.seller, deal.buyer, deal.tokenId);
        require(IERC20(deal.token).transferFrom(deal.buyer, deal.seller, deal.price), "NFTBankedSale: ERC20 transfer failed");
        require(IERC20(deal.token).transferFrom(deal.bank, deal.seller, deal.transferred), "NFTBankedSale: ERC20 bank transfer failed");
    }

}