/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.3.2 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.3.2 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
    
    
     function getCreators(uint256 _tokenId) external view returns (address[] memory);
     
     function getCreatorsShare(uint256 _tokenId) external view returns (uint256[] memory);
}

pragma solidity >=0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
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




pragma solidity >=0.6.0;

contract ERC721Marketplace is Ownable {
    //SafeMath
    using SafeMath for uint256;

    //Token and NFT Token
    IERC20 public HymoToken;
    IERC721 private erc721Address;
    
    uint256 immutable private UNIT = 10 ** 18;
    
    address payable public feeAddress;
    uint256 public feePercentage = 15; // 1 = 1%
    uint256 public feePercentageAddUp = 3;
    uint256 private limit;
    uint256 private royalties = 10;
    
    uint256 public saleIncrementId = 0;
    
    uint256 public soldIncrementId = 0;
    
    mapping(uint256 => Sale) public sales; // maps saleid => Sale
    mapping(uint256 => uint256) public salesById; // maps tokenId => Sale
    mapping(uint256 => uint256) public tokenNumberSales; // maps tokeid => number of times Nft was sold
    

    // Represents the status of the Sale
    enum Status { 
        ForSale,     // The token is for sale
        Sold,        // The token was sold
        Canceled    // The token sale was canceled
    }

    struct Sale {
        uint256 saleId;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        address buyer;
        uint256 datePostForSale;
        uint256 date;
        Status status;
    }

    constructor(IERC20 _erc20Address, IERC721 _erc721Address, uint256 amount, address payable _feeAddress, uint256 _feePercentage){
        
        require(_feeAddress != address(0), "Address cant be null");
        require(_feePercentage < 100 && _feePercentage > 0, "Fee Percentage has to be lower than 100 and higher than 0");
        
        HymoToken = _erc20Address;
        erc721Address = _erc721Address;
        
        feeAddress = _feeAddress;
        feePercentage = _feePercentage;
        
        limit = amount;
            
    }

    event SaleCreated(uint256 indexed tokenId, uint256 price, address indexed creator);
    event SaleCanceled(uint256 indexed tokenId, address indexed creator);
    event SaleDone(uint256 indexed tokenId, address indexed buyer,  address indexed creator, uint256 price);


     function approve(uint256 _tokenId) public {
         erc721Address.approve(address(this), _tokenId);
    }

    function approveAndPutERC721OnSale(uint256 _tokenId, uint256 _price)public {
         erc721Address.approve(address(this), _tokenId);
         putERC721OnSale(_tokenId, _price);
    }
    

    function putERC721OnSale(uint256 _tokenId, uint256 _price) public {
        require(erc721Address.ownerOf(_tokenId) == msg.sender, "Not Owner of the NFT");
       
        // Create Sale Object
        Sale memory sale = sales[_tokenId];
        sale.saleId = saleIncrementId;
        sale.tokenId = _tokenId;
        sale.price = _price;
        sale.status = Status.ForSale;
        sale.seller = payable(msg.sender);
        sale.date = block.timestamp;
        sales[saleIncrementId] = sale;
      
        emit SaleCreated(_tokenId, _price, msg.sender);
        saleIncrementId = saleIncrementId.add(1);
    }


    function removeERC721FromSale(uint256 _saleId) public {
        require(sales[_saleId].seller == msg.sender, "Not Owner of the NFT");
        require(sales[_saleId].status== Status.Canceled, "NFT is not in sale");
        sales[_saleId].status = Status.Canceled;
        emit SaleCanceled(_saleId, msg.sender);
        delete sales[_saleId];
    }
    
    function removeERC721FromSaleAdmin(uint256 _saleId) public onlyOwner {
        require(sales[_saleId].status == Status.ForSale, "NFT is not in sale");
        sales[_saleId].status = Status.Canceled;
        emit SaleCanceled(_saleId, sales[_saleId].seller);
        delete sales[_saleId];
    }
    
    function getBalanceOfTokens(address sender) public view returns (uint256){
        return HymoToken.balanceOf(sender);
    }
    
    function getFee(address addr) public view returns(uint256){
        if (getBalanceOfTokens(addr) >= (limit * UNIT)){
            return feePercentage;
        }
        return feePercentage.add(feePercentageAddUp);

    }

    function buyERC721(uint256 _saleId) payable public virtual {
        require(sales[_saleId].status == Status.ForSale, "NFT is not in sale");
        require(sales[_saleId].status != Status.Sold, "NFT has to be available for purchase" );
        
        uint256 nft = sales[_saleId].tokenId;
        //Transfer Native ETH to contract
        require(sales[_saleId].price == msg.value, "Require Amount to be equal to the price");
        
        uint256 fee = getFee(msg.sender);
        
        if(tokenNumberSales[sales[_saleId].tokenId] == 0){
          
            // Transfer fee to fee address
            require(feeAddress.send(fee.mul(sales[_saleId].price).div(100)), "Contract was not allowed to do the transfer");

        }else{
            require(sales[_saleId].seller.send(feePercentageAddUp.mul(sales[_saleId].price).div(100)), "Contract was not allowed to do the transfer");
            
            address[] memory creators = erc721Address.getCreators(nft);
            uint256[] memory creatorsShare = erc721Address.getCreatorsShare(nft);
            uint256 ctrl = 0;
            while(ctrl < creators.length){
                require(payable(creators[ctrl]).send(creatorsShare[ctrl].mul(sales[_saleId].price).div(100)), "Contract was not allowed to do the transfer");
                ctrl++;
            }
            
            fee = royalties.add(feePercentageAddUp);
            
        }
    
        require(sales[_saleId].seller.send(((100 - fee) * sales[_saleId].price) / 100), "Wasnt able to transfer the amount to the seller");
    
    
        //Transfer ERC721 to buyer
        erc721Address.transferFrom(sales[_saleId].seller, msg.sender, sales[_saleId].tokenId);

        sales[_saleId].status = Status.Sold;
        tokenNumberSales[sales[_saleId].tokenId] = tokenNumberSales[_saleId].add(1);
        soldIncrementId = soldIncrementId.add(1);
        emit SaleDone(_saleId, msg.sender, sales[_saleId].seller, sales[_saleId].price);
        delete sales[_saleId];
    }

    function changeERC20(IERC20 _erc20Address) public onlyOwner {
        HymoToken = _erc20Address;
    }

    function changeERC721(IERC721 _erc721Address) public onlyOwner {
        erc721Address = _erc721Address;
    }
    
    function setLimit(uint256 amount) public onlyOwner{
        limit = amount;
    }
    
    function getLimit() public view returns(uint256){
        return limit;
    }

    function setFixedFees(address payable _feeAddress, uint256 _feePercentage) public onlyOwner {
        require(_feeAddress != address(0), "Address cant be null");
        require(_feePercentage < 100, "Fee Percentage has to be lower than 100");
        feeAddress = _feeAddress;
        feePercentage = _feePercentage;
    }

}

interface HymoNFT is IERC721 {
    function getMarketplaceDistributionForERC721(uint256 tokenId) external returns(uint256[] memory, address[] memory);
}

contract HymoMarketplaceV2 is ERC721Marketplace {
    
   // HymoNFT public erc721Address;

    constructor(IERC20 _erc20Address, HymoNFT _erc721Address, uint256 limit, address payable _feeAddress, uint256 _feePercentage ) ERC721Marketplace(_erc20Address, _erc721Address, limit, _feeAddress, _feePercentage) {

    }
}