/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-19
*/

pragma solidity ^0.5.14;
pragma experimental ABIEncoderV2;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    
    function royaltyReceipt() public view returns (address payable _royaltyReceipt);
    function royaltyFee() public view returns (uint256 fee);


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
} 


library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes32  fullMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
         return ecrecover(fullMessage, v, r, s);
    }
}


contract OrderBook is Ownable{
    

    struct Asset {
        address token;
        uint tokenId;
    }

    struct OrderKey {
        /* who signed the order */
        address payable owner;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;
        /* fee for selling  secoundary sale*/
        uint sellerFee;
        /* random numbers*/
        uint salt;
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}

contract OrderState is OrderBook  {

    mapping(bytes32 => bool) public completed; // 1.completed

    function getCompleted(OrderBook.Order calldata order) view external returns (bool) {
        return completed[getCompletedKey(order)];
    }

    function setCompleted(OrderBook.Order memory order, bool newCompleted) internal  {
        completed[getCompletedKey(order)] = newCompleted;
    }

    function getCompletedKey(OrderBook.Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(order.key.owner,abi.encodePacked(order.key.sellAsset.token,order.key.sellAsset.tokenId,order.key.buyAsset.token,order.key.buyAsset.tokenId),order.selling,order.buying, order.sellerFee));
    }
}


contract TransferSafe {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) internal  {
        token.safeTransferFrom(from, to, tokenId);
    }

    // function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) internal  {
    //     token.safeTransferFrom(from, to, id, value, data);
    // }
}

contract QubeExchange is OrderState, TransferSafe {

    using BytesLibrary for bytes32;

    address payable public beneficiaryAddress;
    address public buyerFeeSigner;
    uint256 public beneficiaryFee; //
    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    event Buy(address indexed sellToken, uint256 indexed sellTokenId, uint256 sellValue, address owner,
              address buyToken, uint256 buyTokenId, uint256 buyValue, address buyer);

    event Cancel(address indexed sellToken, uint256 indexed sellTokenId,address owner, address buyToken, uint256 buyTokenId);

    constructor (address payable beneficiary, address buyerfeesigner, uint256 beneficiaryfee) public {

        beneficiaryAddress = beneficiary;
        buyerFeeSigner = buyerfeesigner;
        beneficiaryFee = beneficiaryfee;
    }
    
    function exchange(Order calldata order, Sig calldata sig, uint buyerFee, Sig calldata buyerFeeSig, address buyer) payable external {
        validateOrderSignature(order, sig);
        validateBuyerFeeSig(order, buyerFee, buyerFeeSig);
        
        require(msg.value == order.buying, "msg.value is invalid");
        setCompleted(order,true);
        transferFee(order.buying,IERC721(order.key.sellAsset.token), order.key.owner);
        erc721safeTransferFrom(IERC721(order.key.sellAsset.token) ,order.key.owner, buyer,order.key.sellAsset.tokenId);
        emitBuy(order, buyer);
    }
    
    function transferFee(uint256 amount, IERC721 token, address payable _seller) internal{
         uint256 protocalfee = (amount*beneficiaryFee)/1000;
         uint256 fee = (amount*token.royaltyFee())/1000;
        (token.royaltyReceipt()).transfer(fee);
        (beneficiaryAddress).transfer(protocalfee);
        _seller.transfer(amount - (protocalfee+fee));

    }
    
    function emitBuy(Order memory order, address buyer) internal {
        emit Buy(order.key.sellAsset.token, order.key.sellAsset.tokenId, order.selling,
            order.key.owner,
            order.key.buyAsset.token, order.key.buyAsset.tokenId, order.buying,
            buyer
        );
    }
    
    function cancel(Order calldata order) external {
        require(order.key.owner == msg.sender, "not an owner");
        setCompleted(order, true);
        emit Cancel(order.key.sellAsset.token, order.key.sellAsset.tokenId, msg.sender, order.key.buyAsset.token, order.key.buyAsset.tokenId);
    }
    
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiaryAddress = newBeneficiary;
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }
    
    function validateOrderSignature( Order memory order, Sig memory sig ) internal view {
        require(completed[getCompletedKey(order)] != true, "exist signature");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("incorrect signature");
        } else {
            require(prepareOrderHash(order).recover(sig.v, sig.r, sig.s) == order.key.owner, "incorrect signature");
        }
    }
    
    function validateOrderSignatureView( Order memory order, Sig memory sig ) public view {
        require(completed[getCompletedKey(order)] != true, "exist signature");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("incorrect signature");
        } else {
            require(prepareOrderHash(order).recover(sig.v, sig.r, sig.s) == order.key.owner, "incorrect signature");
        }
    }
    
    function prepareOrderHash(OrderBook.Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(order.key.owner,abi.encodePacked(order.key.sellAsset.token,order.key.sellAsset.tokenId,order.key.buyAsset.token,order.key.buyAsset.tokenId),order.selling,order.buying, order.sellerFee));
    }
    
    function validateBuyerFeeSig( Order memory order, uint buyerFee, Sig memory sig ) internal view {
        require(prepareBuyerFeeMessage(order, buyerFee).recover(sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
    }
    
    function prepareBuyerFeeMessage(Order memory order, uint fee) public pure returns (bytes32) {
       return keccak256(abi.encodePacked(abi.encodePacked(order.key.owner,abi.encodePacked(order.key.sellAsset.token,order.key.sellAsset.tokenId,order.key.buyAsset.token,order.key.buyAsset.tokenId),order.selling,order.buying, order.sellerFee),fee));
    }

    function toEthSignedMessageHash(bytes32 hash, Sig memory sig ) public pure returns (address signer) {
         signer = hash.recover(sig.v, sig.r, sig.s);
    }

}