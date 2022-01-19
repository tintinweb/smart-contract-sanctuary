/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
    */
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */

    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function lastTokenId()external returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function contractOwner() external view returns(address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mintAndTransfer(address from, address to, uint256 itemId, uint256 fee, string memory _tokenURI, bytes memory data)external returns(uint256);

}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function contractOwner() external view returns(address owner);
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);
    function lastTokenId()external returns(uint256);
    function mintAndTransfer(address from, address to, uint256 itemId, uint256 fee, uint256 _supply, string memory _tokenURI, uint256 qty, bytes memory data)external returns(uint256);
}
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */    

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */    

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */    

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */    

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */    

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}    

interface IBaseNFT721 {

    function createCollectible(address creator, string memory tokenURI, uint256 fee) external returns (uint256);

}

interface IBaseNFT1155 {

    function mint(address creator, string memory tokenURI, uint256 supply, uint256 fee) external;

}

contract TransferProxy {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
    
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external  {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }

    function erc721mintAndTransfer(IERC721 token, address from, address to, uint256 tokenId, uint256 fee, string memory tokenURI, bytes calldata data) external {
        token.mintAndTransfer(from, to,tokenId, fee, tokenURI, data);
    }

    function erc721mint(IBaseNFT721 token, address creator, string memory tokenURI, uint256 fee) external {
        token.createCollectible(creator, tokenURI, fee);
    }

    function erc1155mint(IBaseNFT1155 token, address creator, string memory tokenURI, uint256 supply, uint256 fee) external {
        token.mint(creator, tokenURI, supply, fee);
    }

    function erc1155mintAndTransfer(IERC1155 token, address from, address to, uint256 tokenId, uint256 fee , uint256 supply, string memory tokenURI, uint256 qty, bytes calldata data) external {
        token.mintAndTransfer(from, to, tokenId, fee, supply, tokenURI, qty, data);
    }  
}

contract Trade {
    using SafeMath for uint256;

    enum BuyingAssetType {ERC1155, ERC721 , LazyMintERC1155, LazyMintERC721}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event MintingFeeUpdated(uint256 mintingFee);

    uint8 private buyerFeePermille;
    uint8 private _previousBuyerFeePermille;
    uint8 private sellerFeePermille;
    uint8 private _previousSellerFeePermille;
    uint8 private buyerFeePermilleForWETH;
    uint8 private _previousBuyerFeePermilleForWETH;
    uint8 private sellerFeePermilleForWETH;
    uint8 private _previousSellerFeePermilleForWETH;
    uint8 private secondaryBuyerFee;
    uint8 private secondarySellerFee;
    uint8 private secondaryBuyerFeeForWETH;
    uint8 private secondarySellerFeeForWETH;
    TransferProxy public transferProxy;
    IERC20 public WETH;
    IERC20 MFGToken;
    address public owner;
    uint256 mintingFee = 1000 * 10 ** 18;

    mapping(address => mapping(uint256 => bool)) private _exculdedFromFee;

    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint256 supply;
        string tokenURI;
        uint256 fee;
        uint qty;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee, uint8 _buyerFeeForWETH, uint8 _sellerFeeForWETH, uint8 _secondaryBuyerFee, uint8 _secondarySellerFee, uint8 _secondaryBuyerFeeForWETH, uint8 _secondarySellerFeeForWETH,TransferProxy _transferProxy, IERC20 _WETH, IERC20 _MFGtoken) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        buyerFeePermilleForWETH = _buyerFeeForWETH;
        sellerFeePermilleForWETH = _sellerFeeForWETH;
        _previousBuyerFeePermille =_buyerFee;
        _previousSellerFeePermille = _sellerFee;
        _previousBuyerFeePermilleForWETH = _buyerFeeForWETH;
        _previousSellerFeePermilleForWETH = _sellerFeeForWETH;
        secondaryBuyerFee = _secondaryBuyerFee;
        secondarySellerFee = _secondarySellerFee;
        secondaryBuyerFeeForWETH = _secondaryBuyerFeeForWETH;
        secondarySellerFeeForWETH = _secondarySellerFeeForWETH;
        transferProxy = _transferProxy;
        WETH = _WETH;
        MFGToken = _MFGtoken;
        owner = msg.sender;
    }

    function buyerServiceFee() public view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() public view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function buyerServiceFeeForWETH() public view virtual returns (uint8) {
        return buyerFeePermilleForWETH;
    }
    
    function sellerServiceFeeForWETH() public view virtual returns (uint8) {
        return sellerFeePermilleForWETH;
    }

    function secondaryBuyerServiceFee() public view virtual returns (uint8) {
        return secondarySellerFee;
    }
    
    function secondarySellerServiceFee() public view virtual returns (uint8) {
        return secondaryBuyerFee;
    }

    function secondaryBuyerServiceFeeForWETH() public view virtual returns (uint8) {
        return secondaryBuyerFeeForWETH;
    }

    function secondarySellerServiceFeeForWETH() public view virtual returns (uint8) {
        return secondarySellerFeeForWETH;
    }

    function setBuyerServiceFee(uint8 _buyerFee) public onlyOwner returns(bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) public onlyOwner returns(bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function setBuyerServiceFeeForWETH(uint8 _buyerFee) public onlyOwner returns(bool) {
        buyerFeePermilleForWETH = _buyerFee;
        emit BuyerFee(buyerFeePermilleForWETH);
        return true;
    }
    
    function setSellerServiceFeeForWETH(uint8 _sellerFee) public onlyOwner returns(bool) {
        sellerFeePermilleForWETH = _sellerFee;
        emit SellerFee(sellerFeePermilleForWETH);
        return true;
    }

    function setSecondarySellerServiceFee(uint8 _secondarySellerFee) public onlyOwner returns(bool) {
        secondarySellerFeeForWETH = _secondarySellerFee;
        emit SellerFee(secondarySellerFeeForWETH);
        return true;
    }

    function setSecondaryBuyerServiceFee(uint8 _secondaryBuyerFee) public onlyOwner returns(bool) {
        secondaryBuyerFee = _secondaryBuyerFee;
        emit BuyerFee(secondaryBuyerFee);
        return true;
    }

    function setSecondarySellerServiceFeeForWETH(uint8 _secondarySellerFee) public onlyOwner returns(bool) {
        secondarySellerFee = _secondarySellerFee;
        emit SellerFee(secondarySellerFeeForWETH);
        return true;
    }

    function setSecondaryBuyerServiceFeeForWETH(uint8 _secondaryBuyerFee) public onlyOwner returns(bool) {
        secondaryBuyerFeeForWETH = _secondaryBuyerFee;
        emit BuyerFee(secondaryBuyerFeeForWETH);
        return true;
    }

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s);
    }

    function verifySellerSign(address seller, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount));
        require(seller == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifyBuyerSign(address buyer, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, uint qty, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, qty));
        require(buyer == getSigner(hash, sign), "buyer sign verification failed");
    }

    function verifyOwnerSign(address buyingAssetAddress, address caller, string memory tokenURI, Sign memory sign) internal view {
        address _owner = IERC721(buyingAssetAddress).contractOwner();
        bytes32 hash = keccak256(abi.encodePacked(buyingAssetAddress, caller, tokenURI));
        require(_owner == getSigner(hash, sign), "Owner sign verification failed");
    }

    function getTokenId(Order memory order) internal returns(uint256){
        uint256 tokenId;
        if(order.nftType == BuyingAssetType.LazyMintERC721) {
            tokenId = (IERC721(order.nftAddress).lastTokenId());
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155) {
            tokenId = (IERC1155(order.nftAddress).lastTokenId());
        }
        return tokenId;
    
    }

    function getFees( Order memory order) internal returns(Fee memory){
        address tokenCreator;
        uint platformFee;
        uint royaltyFee;
        uint assetFee;
        uint royaltyPermille;
   
        if(_exculdedFromFee[order.nftAddress][order.tokenId]) {
            removeAllFee();
        }

        uint buyerfee = WETH == IERC20(order.erc20Address) ? buyerFeePermilleForWETH : buyerFeePermille;
        uint sellerfee = WETH == IERC20(order.erc20Address) ? sellerFeePermilleForWETH : sellerFeePermille;

        uint price = order.amount.mul(1000).div((1000+buyerfee));
        uint buyerFee = order.amount.sub(price);
        uint sellerFee = price.mul(sellerfee).div(1000);
        platformFee = buyerFee.add(sellerFee);
        if(order.nftType == BuyingAssetType.ERC721) {
            royaltyPermille = ((IERC721(order.nftAddress).royaltyFee(order.tokenId)));
            tokenCreator = ((IERC721(order.nftAddress).getCreator(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.ERC1155)  {
            royaltyPermille = ((IERC1155(order.nftAddress).royaltyFee(order.tokenId)));
            tokenCreator = ((IERC1155(order.nftAddress).getCreator(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.LazyMintERC721) {
            royaltyPermille = order.fee;
            tokenCreator = order.seller;
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155) {
            royaltyPermille = order.fee;
            tokenCreator = order.seller;
        }
        royaltyFee = price.mul(royaltyPermille).div(1000);
        assetFee = price.sub(royaltyFee).sub(sellerFee);

        restoreAllFee();

        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function removeAllFee() private {

        if(sellerFeePermille == secondarySellerFee && buyerFeePermille == secondaryBuyerFee && buyerFeePermilleForWETH == secondaryBuyerFeeForWETH && sellerFeePermilleForWETH == secondarySellerFeeForWETH) return;

            _previousSellerFeePermille = sellerFeePermille;
            _previousBuyerFeePermille = buyerFeePermille;
            _previousBuyerFeePermilleForWETH = buyerFeePermilleForWETH;
            _previousSellerFeePermilleForWETH = sellerFeePermilleForWETH;
        
            sellerFeePermille = secondarySellerFee;
            buyerFeePermille = secondaryBuyerFee;
            sellerFeePermilleForWETH = secondaryBuyerFeeForWETH;
            buyerFeePermilleForWETH = secondarySellerFeeForWETH;
    }

    function restoreAllFee() private {
        sellerFeePermille = _previousSellerFeePermille;
        buyerFeePermille = _previousBuyerFeePermille;
        buyerFeePermilleForWETH = _previousBuyerFeePermilleForWETH;
        sellerFeePermilleForWETH = _previousSellerFeePermilleForWETH;
    }

    function tradeAsset(Order memory order, Fee memory fee) internal virtual {

        if(order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(order.nftAddress), order.seller, order.buyer, order.tokenId);
        }
        if(order.nftType == BuyingAssetType.ERC1155)  {     
            transferProxy.erc1155safeTransferFrom(IERC1155(order.nftAddress), order.seller, order.buyer, order.tokenId, order.qty, ""); 
        }
        if(order.nftType == BuyingAssetType.LazyMintERC721){
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, owner, mintingFee);
            transferProxy.erc721mintAndTransfer(IERC721(order.nftAddress), order.seller, order.buyer, order.tokenId, order.fee,order.tokenURI,"" );
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155){
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, owner, mintingFee);
            transferProxy.erc1155mintAndTransfer(IERC1155(order.nftAddress), order.seller, order.buyer, order.tokenId, order.fee, order.supply,order.tokenURI,order.qty,"" );
        }
        if(fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, owner, fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, fee.tokenCreator, fee.royaltyFee);
        }
        transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, order.seller, fee.assetFee);
    }

    function mint(address nftAddress, BuyingAssetType nftType, string memory tokenURI, uint256 fee, uint256 supply, Sign memory sign) public returns(bool) {
        transferProxy.erc20safeTransferFrom(IERC20(MFGToken), msg.sender, owner, mintingFee);
        if(nftType == BuyingAssetType.ERC721) {
            verifyOwnerSign(nftAddress, msg.sender, tokenURI, sign);
            transferProxy.erc721mint(IBaseNFT721(nftAddress), msg.sender, tokenURI, fee);
        }
        if(nftType == BuyingAssetType.ERC1155) {
            verifyOwnerSign(nftAddress, msg.sender, tokenURI, sign);
            transferProxy.erc1155mint(IBaseNFT1155(nftAddress), msg.sender, tokenURI, supply, fee);
        }
        return true;
    }

    function mintAndBuyAsset(Order memory order, Sign memory ownerSign, Sign memory sign) public returns(bool){
        transferProxy.erc20safeTransferFrom(IERC20(MFGToken), msg.sender, owner, mintingFee);
        Fee memory fee = getFees(order);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifyOwnerSign(order.nftAddress, order.seller, order.tokenURI, ownerSign);
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        order.tokenId = getTokenId(order);
        tradeAsset(order, fee);
        _exculdedFromFee[order.nftAddress][order.tokenId] = true;
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;
    }

    function mintAndExecuteBid(Order memory order, Sign memory ownerSign, Sign memory sign) public returns(bool){
        transferProxy.erc20safeTransferFrom(IERC20(MFGToken), msg.sender, owner, mintingFee);
        Fee memory fee = getFees(order);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifyOwnerSign(order.nftAddress,order.seller, order.tokenURI, ownerSign);
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty,sign);
        order.tokenId = getTokenId(order);
        order.seller = msg.sender;
        tradeAsset(order, fee);
        _exculdedFromFee[order.nftAddress][order.tokenId] = true;
        emit ExecuteBid(order.seller , order.tokenId, order.qty, msg.sender);
        return true;
    }

    function buyAsset(Order memory order, Sign memory sign) public returns(bool) {
        Fee memory fee = getFees(order);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        tradeAsset(order, fee);
        _exculdedFromFee[order.nftAddress][order.tokenId] = true;
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;
    }

    function executeBid(Order memory order, Sign memory sign) public returns(bool) {
        Fee memory fee = getFees(order);
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty, sign);
        order.seller = msg.sender;
        tradeAsset(order, fee);
        _exculdedFromFee[order.nftAddress][order.tokenId] = true;
        emit ExecuteBid(msg.sender , order.tokenId, order.qty, order.buyer);
        return true;
    }

    function setMintingFee(uint256 _mintingFee) public onlyOwner returns(bool) {
        mintingFee = _mintingFee;
        emit MintingFeeUpdated(mintingFee);
        return true;
    }
}