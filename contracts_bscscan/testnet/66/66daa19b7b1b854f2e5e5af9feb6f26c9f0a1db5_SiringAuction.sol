/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// 

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 

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
}


// File contracts/8/IHorse.sol

pragma solidity ^0.8.0;

interface IHorse is IERC721 {

    enum Gender { stallion,  mare }

    enum Bloodline {Nakamoto, Szabo, Finney, Buterin}

    enum BreedType {Genesis, Legendary, Exclusive, Elite, Cross, Pacer}
    


    struct Horse {
        string name;

        uint256 genes;

        Gender gender;

        Bloodline bloodline;

        uint256 genotype;
        
        BreedType breedtype;

        uint256 coatcolour;

        uint256 birthTime;

        uint256 matronId;
        uint256 sireId;

        // uint256 siringWithId;  

        // uint256 breedCount;
        // uint256 lastBreedTime;  
    }

    function transfer(address _to,uint256 _tokenId) external;

    function getHorse(uint256 _tokenId) external view returns(Horse memory);

    function getGenes(uint256 _genes) external view returns(uint256, uint256, uint256);
}


// File contracts/8/AuctionBase.sol

pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



contract AuctionBase {

    using SafeMath for uint256;

    struct Auction {
        // address seller;
        uint256 price;
        uint256 duration;
        uint256 startedAt;
    }

    // ERC721 public nonFungibleContract;
    IHorse public nonFungibleContract;
    mapping (uint256 => Auction) public tokenIdToAuction;

    IERC20 public ticketToken;

    address public prizePoolAddr;
    address public zedFeeAddr;


    // function _escrow(address _owner, uint256 _tokenId) internal {
    //     nonFungibleContract.transferFrom(_owner, address(this), _tokenId);
    // }

    // function _transfer(address _receiver, uint256 _tokenId) internal {
    //     nonFungibleContract.transfer(_receiver, _tokenId);
    // }


    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    // function _cancelAuction(address _sender, uint256 _tokenId) internal {
    //     Auction memory auction = tokenIdToAuction[_tokenId];
    //     require(_sender == auction.seller,"AuctionBase:_sender != auction.seller");
    //     // require(auction.startedAt + auction.duration <= block.timestamp, "AuctionBase:auction.startedAt + auction.duration > block.timestamp");
    //     _removeAuction(_tokenId);
    //     _transfer(_sender, _tokenId);
    // }


    function _bid(address _buyer, uint256 _tokenId)
        internal
        returns (uint256)
    {
        
        Auction memory auction = tokenIdToAuction[_tokenId];
        
        // address seller = auction.seller;
        address seller = nonFungibleContract.ownerOf(_tokenId);

        // require(isOnAuction(_tokenId));

        // uint256 price = getPrice(_tokenId);
        uint256 price = auction.price;

        if(address(ticketToken) != address(0)){
            // ticketToken.transferFrom(msg.sender,address(this),price);
            // ticketToken.transferFrom(_buyer,seller,price);
            if(_buyer == seller){
                ticketToken.transferFrom(_buyer, prizePoolAddr, price.mul(65).mul(70).div(10000));
                ticketToken.transferFrom(_buyer, zedFeeAddr, price.mul(65).mul(30).div(10000));
            }
            else{
                uint256 duration = auction.duration;
                if(duration == 7 days){
                    ticketToken.transferFrom(_buyer, seller, price.mul(56).div(100));
                    ticketToken.transferFrom(_buyer, prizePoolAddr, price.mul(29).div(100));
                }
                else if(duration == 3 days){
                    ticketToken.transferFrom(_buyer, seller, price.mul(48).div(100));
                    ticketToken.transferFrom(_buyer, prizePoolAddr, price.mul(37).div(100));
                }
                else if(duration == 1 days){
                    ticketToken.transferFrom(_buyer, seller, price.mul(40).div(100));
                    ticketToken.transferFrom(_buyer, prizePoolAddr, price.mul(45).div(100));
                }
                ticketToken.transferFrom(_buyer, zedFeeAddr, price.mul(15).div(100));
            }
        }

        _removeAuction(_tokenId);
        // _transfer(seller, _tokenId);

        return price;
    }


    function isOnAuction(uint256 _tokenId) public view returns (bool) {
        Auction memory _auction = tokenIdToAuction[_tokenId];
        return (_auction.startedAt > 0 && block.timestamp <= _auction.startedAt + _auction.duration);
    }

    function getPrice(uint256 _tokenId) public view returns (uint256){
        Auction memory _auction = tokenIdToAuction[_tokenId];
        return _auction.price;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// 

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// 

pragma solidity ^0.8.0;

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


// File contracts/8/SiringAuction.sol

pragma solidity ^0.8.0;




contract SiringAuction is AuctionBase,Ownable {

    

    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);
    

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);

    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    event AuctionCancelled(uint256 tokenId);



    constructor(address _nftAddress, address _ticketToken, address _prizePoolAddr, address _zedFeeAddr) {
        // ERC721 candidateContract = ERC721(_nftAddress);
        // require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        // nonFungibleContract = candidateContract;
        nonFungibleContract = IHorse(_nftAddress);
        ticketToken = IERC20(_ticketToken);
        prizePoolAddr = _prizePoolAddr;
        zedFeeAddr = _zedFeeAddr;
    }


    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 auctionDuration,
        address _seller
    )
        external
    {
        require(msg.sender == address(nonFungibleContract),"SiringAuction:msg.sender != address(nonFungibleContract)");
        require(nonFungibleContract.ownerOf(_tokenId) == _seller,"SiringAuction:nonFungibleContract.ownerOf(_tokenId) != _seller");
        // _escrow(_seller, _tokenId);
        
        Auction memory auction = Auction(
            // _seller,
            _price,
            auctionDuration,
            block.timestamp
        );
        _addAuction(_tokenId, auction);
    }

    // function cancelAuction(address _sender, uint256 _tokenId) external {
    //     require(msg.sender == address(nonFungibleContract),"SiringAuction:msg.sender != address(nonFungibleContract)");
    //     require(nonFungibleContract.ownerOf(_tokenId) == address(this),"nonFungibleContract.ownerOf(_tokenId) != address(this)");
        
    //     require(!isOnAuction(_tokenId),"SiringAuction:_isOnAuction(_tokenId)");
    //     _cancelAuction(_sender, _tokenId);
    // }


    function bid(
        address _buyer, 
        uint256 _tokenId 
        // uint256 _ticketPrice
    ) external
    {
        require(msg.sender == address(nonFungibleContract),"msg.sender != address(nonFungibleContract)");
        // require(nonFungibleContract.ownerOf(_tokenId) == address(this),"nonFungibleContract.ownerOf(_tokenId) != address(this)");
    
        // _transferTicket(_buyer,_ticketPrice);
        // require(isOnAuction(_tokenId),"SiringAuction:!_isOnAuction(_tokenId)");

        // address seller = tokenIdToAuction[_tokenId].seller;
        // _bid(_buyer, _tokenId);
        // _transfer(seller, _tokenId);
        _bid(_buyer, _tokenId);
    }

}