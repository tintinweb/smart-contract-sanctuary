// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMonNFT.sol";

contract MonBase is Ownable, IERC721Receiver{
    uint256 public MULTIPLIER = 1000;
    
    IERC20 private _monToken;
    IMonNFT private _monNFT;
    
    uint256 private _feePercent;    //Multipled by 1000
    
    constructor(address monTokenAddress, address monNFTAddress){
        _monToken = IERC20(monTokenAddress);
        _monNFT = IMonNFT(monNFTAddress);
        _feePercent = 5000;    //5%
    }
    
    /**
     * @dev Get MON token 
     */
    function getMonToken() public view returns(IERC20){
        return _monToken;
    }
    
    /**
     * @dev Get MON NFT
     */
    function getMonNFT() public view returns(IMonNFT){
        return _monNFT;
    }

    function getFeePercent() public view returns(uint){
        return _feePercent;
    }
    
    function setTokenNFT(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _monNFT = IMonNFT(newAddress);
    }
    
    function setMonToken(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _monToken = IERC20(newAddress);
    }
    
    function setFeePercent(uint feePercent) public onlyOwner{
        _feePercent = feePercent;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IMonNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IMonMarketPlace.sol";
import "./MonBase.sol";

contract MonMarketPlace is MonBase, IMonMarketPlace{
    struct MarketHistory{
        address buyer;
        address seller;
        uint256 price;
        uint256 time;
    }
    
    uint256[] internal _tokens;
    
    //Mapping tokenId to token price
    mapping(uint256 => uint256) internal _tokenPrices;
    
    //Mapping tokenId to owner of tokenId
    mapping(uint256 => address) internal _tokenOwners;
    
    //Mapping tokenId to market
    mapping(uint256 => MarketHistory[]) internal _marketHistories;
    
    constructor(address monTokenAddress, address monNFTAddress) 
        MonBase(monTokenAddress, monNFTAddress){}
    
    /**
     * @dev Create a sell order to sell NFT
     */
    function createSellOrder(uint256 tokenId, uint256 price) external override returns(bool){
        //Validate
        require(_tokenOwners[tokenId] == address(0), "Can not create sell order for this token");
        IMonNFT monNFT = getMonNFT();
        
        address tokenOwner = monNFT.ownerOf(tokenId);
        require(tokenOwner == _msgSender(), "Forbidden to create sell NFT");
        
        //Transfer monNFT to this contract
        monNFT.safeTransferFrom(tokenOwner, address(this), tokenId);
        
        _tokenOwners[tokenId] = tokenOwner;
        _tokenPrices[tokenId] = price;
        _tokens.push(tokenId);
        
        emit NewSellOrderCreated(_msgSender(), block.timestamp, tokenId, price);
        
        return true;
    }
    
    /**
     * @dev User that created sell order can cancel that order
     */ 
    function cancelSellOrder(uint256 tokenId) external override returns(bool){
        require(_tokenOwners[tokenId] == _msgSender(), "Forbidden to cancel sell order");

        IMonNFT monNFT = getMonNFT();
        //Transfer monNFT from contract to sender
        monNFT.safeTransferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        _tokens = _removeFromTokens(tokenId);
        
        emit CancelOrder(tokenId);

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
     * @dev User purchases a nft
     */ 
    function purchase(uint tokenId) external override returns(uint){
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0), "Token has not been added");
        
        uint256 tokenPrice = _tokenPrices[tokenId];
        
        if(tokenPrice > 0){
            IERC20 monTokenContract = getMonToken();    
            require(monTokenContract.transferFrom(_msgSender(), address(this), tokenPrice));
            uint256 feeAmount = 0;
            // fee for owner
            uint256 feePercent = getFeePercent();
            if(feePercent > 0){
                feeAmount = tokenPrice * feePercent / 100 / MULTIPLIER;
                require(monTokenContract.transfer(owner(), feeAmount));
            }
            // fee for author
            uint256 feeCopyright = 0;
            IMonNFT monNFT = getMonNFT();
            address author = monNFT.getTokenAuthor(tokenId);
            uint256 feePercentCopyright = monNFT.getFeeCopyright(tokenId);
            if (feePercentCopyright > 0) {
                feeCopyright = tokenPrice * feePercentCopyright / 100 / MULTIPLIER;
                require(monTokenContract.transfer(author, feeCopyright));
            }
            // transfer token for owner nft
            require(monTokenContract.transfer(tokenOwner, tokenPrice - feeAmount - feeCopyright));
        }
        
        //Transfer monNFT from contract to sender
        getMonNFT().transferFrom(address(this), _msgSender(), tokenId);
        
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
    
    event CancelOrder(uint256 indexed tokenId);
    event Purchased(address indexed buyer, uint256 tokenId, uint256 price);
    event NewSellOrderCreated(address indexed seller, uint256 time, uint256 tokenId, uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMonMarketPlace{
     
    function cancelSellOrder(uint256 tokenId) external returns(bool);

    function createSellOrder(uint tokenId, uint price) external returns(bool);
    
    function purchase(uint tokenId) external returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMonNFT is IERC721{

    function getTokenAuthor(uint tokenId) external view returns(address);

    function getFeeCopyright(uint tokenId) external view returns(uint);
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

