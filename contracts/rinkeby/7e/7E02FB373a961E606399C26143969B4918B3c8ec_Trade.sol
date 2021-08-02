/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract Ownable is Context{
    
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_msgSender() == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract Trade is Ownable {
    
    using SafeMath for uint256;
    
    struct OrderInfo{
        uint256 id;
        uint256 price;
        address seller;
    }
    OrderInfo[] orderInfos;
    mapping(uint256=>uint256) indexOfID;
    address coinAddress;
    address nftAddress;
    uint256 free;
   
   
   
    event SetAddress(address coinAddress,address nftAddress);
    event SetFree(uint256 newFree);
    event Sell(address indexed seller,uint256 id,uint256 price);
    event SellCancel(address indexed seller,uint256 id);
    event ChangePrice(address indexed seller,uint256 id,uint256 newPrice);
    event Buy(address indexed buyer,uint256 id);
    
    

    constructor() public{
        owner = _msgSender();
        coinAddress = 0x37499d24288248A620C74DafC62711e04193dAB2;
        nftAddress = 0x2D6Bc71953263d7c75caE1648B96F6EEf9dB8d76;
        free = 20; //2%
        orderInfos.push(OrderInfo(0,uint256(-1),_msgSender()));
        emit Sell(_msgSender(),0,uint256(-1));
    }
    
    
    
    function setAddress(address coinAdd,address nftAdd) external onlyOwner{
        coinAddress = coinAdd;
        nftAddress = nftAdd;
        
        emit SetAddress(coinAdd,nftAdd);
    }
    function setFree(uint256 newFree) external onlyOwner{
        free = newFree;
        
        emit SetFree(newFree);
    }
    
    
    function sell(uint256 nftID,uint256 price) external{
        IERC721 nftContract = IERC721(nftAddress);
        require(nftContract.ownerOf(nftID) == _msgSender());
        require(nftContract.isApprovedForAll(_msgSender(),address(this)) == true);
        
        if(indexOfID[nftID] == 0){
            indexOfID[nftID] = orderInfos.length;
            orderInfos.push(OrderInfo(nftID,price,_msgSender()));
        }else{
            orderInfos[indexOfID[nftID]].id = nftID;
            orderInfos[indexOfID[nftID]].price = price;
            orderInfos[indexOfID[nftID]].seller = _msgSender();
        }
        
        emit Sell(_msgSender(),nftID,price);
    }
    function sellCancel(uint256 nftID) external{
        IERC721 nftContract = IERC721(nftAddress);
        require(nftContract.ownerOf(nftID) == _msgSender());
        
        emit SellCancel(_msgSender(),nftID);
        delete orderInfos[indexOfID[nftID]];
    }
    function changePrice(uint256 nftID,uint256 newPrice) external{
        IERC721 nftContract = IERC721(nftAddress);
        OrderInfo storage order = orderInfos[indexOfID[nftID]];
        require(nftContract.ownerOf(nftID) == _msgSender());
        require(order.seller == _msgSender());
        
        order.price = newPrice;
        
        emit ChangePrice(_msgSender(),nftID,newPrice);
    }
    function buy(uint256 nftID) external{
        IERC20 coinContract = IERC20(coinAddress);
        IERC721 nftContract = IERC721(nftAddress);
        OrderInfo memory order = orderInfos[indexOfID[nftID]];
        require(nftContract.ownerOf(order.id) == order.seller);
        require(nftContract.isApprovedForAll(order.seller,address(this)));
        require(coinContract.balanceOf(_msgSender()) >= order.price);
        require(coinContract.allowance(_msgSender(),address(this)) >= order.price);
        
        uint256 finalFree = order.price.mul(free).div(1000);
        uint256 finalIncome = order.price - finalFree;
        coinContract.transferFrom(_msgSender(),owner,finalFree);
        coinContract.transferFrom(_msgSender(),order.seller,finalIncome);
        nftContract.safeTransferFrom(order.seller,_msgSender(),nftID);
        
        emit Buy(_msgSender(),nftID);
        delete orderInfos[indexOfID[nftID]];
    }
    
    
    function getIndexByID(uint256 id) external view returns(uint256){
        return indexOfID[id];
    }
    function getInfoByIndex(uint256 index) public view returns(uint256,uint256,address){
        OrderInfo memory order = orderInfos[index];
        return (order.id,order.price,order.seller);
    }
    function getInfoByID(uint256 id) external view returns(uint256,uint256,address){
        OrderInfo memory order = orderInfos[indexOfID[id]];
        return (order.id,order.price,order.seller);
    }
    function getOrderCount() external view returns(uint256){
        return orderInfos.length;
    }
    
    
}