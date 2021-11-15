// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IERC20.sol";
import "./core/Ownable.sol";

contract AvatarArtBase is Ownable, IERC721Receiver{
    uint256 public MULTIPLIER = 1000;
    
    IERC20 private _bnuToken;
    IERC721 private _avatarArtNFT;
    
    uint256 private _feePercent;       //Multipled by 1000
    
    constructor(address bnuTokenAddress, address avatarArtNFTAddress){
        _bnuToken = IERC20(bnuTokenAddress);
        _avatarArtNFT = IERC721(avatarArtNFTAddress);
        _feePercent = 100;        //0.1%
    }
    
    /**
     * @dev Get BNU token 
     */
    function getBnuToken() public view returns(IERC20){
        return _bnuToken;
    }
    
    /**
     * @dev Get AvatarArt NFT
     */
    function getAvatarArtNFT() public view returns(IERC721){
        return _avatarArtNFT;
    }
    
    /**
     * @dev Get fee percent, this fee is for seller
     */ 
    function getFeePercent() public view returns(uint){
        return _feePercent;
    }
    
    /**
     * @dev Set AvatarArtNFT contract 
     */
    function setAvatarArtNFT(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _avatarArtNFT = IERC721(newAddress);
    }
    
    /**
     * @dev Set BNU token 
     */
    function setBnuToken(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _bnuToken = IERC20(newAddress);
    }
    
    /**
     * @dev Set fee percent
     */
    function setFeePercent(uint feePercent) public onlyOwner{
        _feePercent = feePercent;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAvatarArtMarketPlace.sol";
import "./AvatarArtBase.sol";

contract AvatarArtMarketPlace is AvatarArtBase, IAvatarArtMarketPlace{
    struct MarketHistory{
        address buyer;
        address seller;
        uint256 price;
        uint256 time;
    }
    
    uint256[] internal _tokens;
    
    //Mapping between tokenId and token price
    mapping(uint256 => uint256) internal _tokenPrices;
    
    //Mapping between tokenId and owner of tokenId
    mapping(uint256 => address) internal _tokenOwners;
    
    mapping(uint256 => MarketHistory[]) internal _marketHistories;
    
    constructor(address bnuTokenAddress, address avatarArtNFTAddress) 
        AvatarArtBase(bnuTokenAddress, avatarArtNFTAddress){}
    
    /**
     * @dev Create a sell order to sell BNU category
     */
    function createSellOrder(uint256 tokenId, uint256 price) external onlyOwner override returns(bool){
        //Validate
        require(_tokenOwners[tokenId] == address(0), "Can not create sell order for this token");
        IERC721 avatarArtNFT = getAvatarArtNFT();
        address tokenOwner = avatarArtNFT.ownerOf(tokenId);
        
        //Transfer AvatarArtNFT to contract
        avatarArtNFT.safeTransferFrom(tokenOwner, address(this), tokenId);
        
        _tokenOwners[tokenId] = tokenOwner;
        _tokenPrices[tokenId] = price;
        _tokens.push(tokenId);
        
        emit NewSellOrderCreated(_msgSender(), _now(), tokenId, price);
        
        return true;
    }
    
    /**
     * @dev User that created sell order can cancel that order
     */ 
    function cancelSellOrder(uint256 tokenId) external override returns(bool){
        require(_tokenOwners[tokenId] == _msgSender(), "Forbidden to cancel sell order");

        IERC721 avatarArtNft = getAvatarArtNFT();
        //Transfer AvatarArtNFT from contract to sender
        avatarArtNft.safeTransferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        _tokens = _removeFromTokens(tokenId);
        
        return true;
    }
    
    /**
     * @dev Get all active tokens that can be purchased 
     */ 
    function getTokens() external view returns(uint256[] memory){
        return _tokens;
    }
    
    /**
     * @dev Get token info about price and owner
     */ 
    function getTokenInfo(uint tokenId) external view returns(address, uint){
        return (_tokenOwners[tokenId], _tokenPrices[tokenId]);
    }
    
    
    function getMarketHistories(uint256 tokenId) external view returns(MarketHistory[] memory){
        return _marketHistories[tokenId];
    }
    
    /**
     * @dev Get token price
     */ 
    function getTokenPrice(uint256 tokenId) external view returns(uint){
        return _tokenPrices[tokenId];
    }
    
    /**
     * @dev Get token's owner
     */ 
    function getTokenOwner(uint256 tokenId) external view returns(address){
        return _tokenOwners[tokenId];
    }
    
    /**
     * @dev User purchases a BNU category
     */ 
    function purchase(uint tokenId) external override returns(uint){
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0),"Token has not been added");
        
        uint256 tokenPrice = _tokenPrices[tokenId];
        
        if(tokenPrice > 0){
            IERC20 bnuTokenContract = getBnuToken();    
            require(bnuTokenContract.transferFrom(_msgSender(), address(this), tokenPrice));
            uint256 feeAmount = 0;
            uint256 feePercent = getFeePercent();
            if(feePercent > 0){
                feeAmount = tokenPrice * feePercent / 100 / MULTIPLIER;
                require(bnuTokenContract.transfer(_owner, feeAmount));
            }
            require(bnuTokenContract.transfer(tokenOwner, tokenPrice - feeAmount));
        }
        
        //Transfer AvatarArtNFT from contract to sender
        getAvatarArtNFT().transferFrom(address(this),_msgSender(), tokenId);
        
        _marketHistories[tokenId].push(MarketHistory({
            buyer: _msgSender(),
            seller: _tokenOwners[tokenId],
            price: tokenPrice,
            time: block.timestamp
        }));
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        _tokens = _removeFromTokens(tokenId);
        
        emit Purchased(_msgSender(), tokenId, tokenPrice);
        
        return tokenPrice;
    }
    
    /**
     * @dev Remove token item by value from _tokens and returns new list _tokens
    */ 
    function _removeFromTokens(uint tokenId) internal view returns(uint256[] memory){
        uint256 tokenCount = _tokens.length;
        uint256[] memory result = new uint256[](tokenCount-1);
        uint256 resultIndex = 0;
        for(uint tokenIndex = 0; tokenIndex < tokenCount; tokenIndex++){
            uint tokenItemId = _tokens[tokenIndex];
            if(tokenItemId != tokenId){
                result[resultIndex] = tokenItemId;
                resultIndex++;
            }
        }
        
        return result;
    }
    
    event NewSellOrderCreated(address indexed seller, uint256 time, uint256 tokenId, uint256 price);
    event Purchased(address indexed buyer, uint256 tokenId, uint256 price);
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
    
    function _now() internal view returns(uint){
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    
    modifier onlyOwner{
        require(_msgSender() == _owner, "Forbidden");
        _;
    }
    
    address internal _owner;
    address internal _newRequestingOwner;
    
    constructor(){
        _owner = _msgSender();
    }
    
    function getOwner() external virtual view returns(address){
        return _owner;
    }
    
    function requestChangeOwner(address newOwner) external  onlyOwner{
        require(_owner != newOwner, "New owner is current owner");
        _newRequestingOwner = newOwner;
    }
    
    function approveToBeOwner() external{
        require(_newRequestingOwner != address(0), "Zero address");
        require(_msgSender() == _newRequestingOwner, "Forbidden");
        
        address oldOwner = _owner;
        _owner = _newRequestingOwner;
        
        emit OwnerChanged(oldOwner, _owner);
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAvatarArtMarketPlace{
    /**
     * @dev User that created sell order can cancel that order
     */ 
    function cancelSellOrder(uint256 tokenId) external returns(bool);
    
    /**
     * @dev Create a sell order to sell BNU category
     */
    function createSellOrder(uint tokenId, uint price) external returns(bool);
    
    /**
     * @dev User purchases a BNU category
     */ 
    function purchase(uint tokenId) external returns(uint);
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

