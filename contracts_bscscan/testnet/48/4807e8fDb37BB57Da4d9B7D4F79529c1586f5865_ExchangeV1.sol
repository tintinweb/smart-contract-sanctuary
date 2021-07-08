/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
// interface IERC165 {
//     /**
//      * @dev Returns true if this contract implements the interface defined by
//      * `interfaceId`. See the corresponding
//      * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
//      * to learn more about how these ids are created.
//      *
//      * This function call must use less than 30 000 gas.
//      */
//     function supportsInterface(bytes4 interfaceId) external view returns (bool);
// }

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 /*is IERC165*/ {
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
    
    function checkFeeDistributionPercentage(address[] memory _fee_receivers, uint256[] memory percentage) public;
    
    function getFeePercentage() public view returns (uint256);
    
    function getDeployer() public view returns (address);
    
    function getFeeReceivers() public returns(address[] memory);
    
    function getFeeDistribution(address fee_receiver) public returns(uint256);
}

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
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract OperatorRole is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor () internal {

    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
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

contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        _removeOperator(account);
    }
}

contract TransferProxy is OwnableOperatorRole {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }
}

// contract TransferProxyForDeprecated is OwnableOperatorRole {

//     function erc721TransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
//         token.transferFrom(from, to, tokenId);
//     }
// }

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

contract ERC20TransferProxy is OwnableOperatorRole {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}

contract ExchangeV1 is Ownable {
    using SafeMath for uint;
    // using UintLibrary for uint;
    // using StringLibrary for string;
    // using BytesLibrary for bytes32;
    
    struct DistributionItem {
        address _address;
        uint256 _amount;
    }

    TransferProxy public transferProxy;
    ERC20TransferProxy public erc20TransferProxy;
    
    mapping (address => mapping(uint256 => uint256)) public buyOrder;
    mapping (address => mapping(uint256 => address)) public auctionOrder;
    mapping (address => mapping(uint256 => mapping(address => mapping(address => uint256)))) public bidOrder;
    mapping (address => mapping(uint256 => address[])) public bidMembers;
    
    uint256 public listingFee = 15 * 10** 15;
    uint256 public serviceFee = 25; // 25 / 1000 => 2.5%
    
    address payable public serviceAddress;
    address public erc1155Address;

    constructor(
        TransferProxy _transferProxy, ERC20TransferProxy _erc20TransferProxy
    ) public {
        transferProxy = _transferProxy;
        erc20TransferProxy = _erc20TransferProxy;
        
        serviceAddress = _msgSender();
    }

    function exchange(
        address sellToken, uint256 sellTokenId,
        address owner,
        address buyToken, uint256 buyValue,
        address buyer
    ) payable external {
        require(owner == _msgSender(), "Exchange: The only token owner can accept bid.");
        
        validateBidRequest(sellToken, sellTokenId, buyer, buyToken, buyValue);
        
        uint256 serviceFeeAmount = buyValue.mul(serviceFee).div(1000);
        uint256 amount = buyValue - serviceFeeAmount;
        
        address[] memory fee_receivers = IERC721(sellToken).getFeeReceivers();
        
        uint256 feePercentage = IERC721(sellToken).getFeePercentage();
        
        if (feePercentage == 0) {
            transferProxy.erc721safeTransferFrom(IERC721(sellToken), owner, buyer, sellTokenId);
            erc20TransferProxy.erc20safeTransferFrom(IERC20(buyToken), buyer, owner, amount);
        } else {
            DistributionItem[] memory distributions = getDistributions(sellToken, owner, fee_receivers, feePercentage, amount);
            
            transferProxy.erc721safeTransferFrom(IERC721(sellToken), owner, buyer, sellTokenId);
            for (uint256 i = 0; i < distributions.length; i++) {
                if (distributions[i]._amount > 0) {
                    erc20TransferProxy.erc20safeTransferFrom(IERC20(buyToken), buyer, distributions[i]._address, distributions[i]._amount);
                }
            }
        }
        
        if (serviceFeeAmount > 0) {
            erc20TransferProxy.erc20safeTransferFrom(IERC20(buyToken), buyer, serviceAddress, serviceFeeAmount);
        }
        
        CancelAllBid(sellToken, sellTokenId, buyToken);
        
        auctionOrder[sellToken][sellTokenId] = address(0);
        
        // emit Buy(sellToken, sellTokenId, owner, buyToken, buyValue, buyer);
    }
    
    function getDistributions(address sellToken, address owner, address[] memory fee_receivers, uint256 feePercentage, uint256 amount) internal returns (DistributionItem[] memory) {
        DistributionItem[] memory distributions = new DistributionItem[](fee_receivers.length + 1);
            
            uint256 feeAmount = amount.mul(feePercentage).div(100);
            
            uint256 total = 0;
            for (uint256 i = 0; i < fee_receivers.length; i++) {
                total += IERC721(sellToken).getFeeDistribution(fee_receivers[i]);
            }
            
            for (uint256 i = 0; i < fee_receivers.length; i++) {
                uint256 distributionAmount = 0;
                
                {
                
                    distributionAmount = IERC721(sellToken).getFeeDistribution(fee_receivers[i]) * feeAmount;
                }
                
                {
                    distributionAmount = distributionAmount / total;
                }
                    
                distributions[i] = DistributionItem(fee_receivers[i], distributionAmount);
            }
            
            distributions[fee_receivers.length] = DistributionItem(owner, amount - feeAmount);
            
            return distributions;
    }
    
    function buy(
        address sellToken, uint256 sellTokenId,
        address owner,
        uint256 buyValue,
        address buyer
    ) payable external {
        validateBuyRequest(sellToken, sellTokenId, buyValue);
        
        uint256 serviceFeeAmount = buyValue.mul(serviceFee).div(1000);
        uint256 amount = buyValue - serviceFeeAmount;
        
        address[] memory fee_receivers = IERC721(sellToken).getFeeReceivers();
        
        uint256 feePercentage = IERC721(sellToken).getFeePercentage();
        
        if (feePercentage == 0) {
            transferProxy.erc721safeTransferFrom(IERC721(sellToken), owner, buyer, sellTokenId);
            address payable to_address = address(uint160(owner));
            to_address.send(amount);
        } else {
            DistributionItem[] memory distributions = getDistributions(sellToken, owner, fee_receivers, feePercentage, amount);
            
            transferProxy.erc721safeTransferFrom(IERC721(sellToken), owner, buyer, sellTokenId);
            for (uint256 i = 0; i < distributions.length; i++) {
                if (distributions[i]._amount > 0) {
                    address payable to_address = address(uint160(distributions[i]._address));
                    to_address.transfer(distributions[i]._amount);
                }
            }
        }
        
        if (serviceFeeAmount > 0) {
            serviceAddress.transfer(serviceFeeAmount);
        }
        
        buyOrder[sellToken][sellTokenId] = 0;
    }
    
    function BuyRequest(address token, uint256 tokenId, uint256 amount) public payable {
        require(IERC721(token).getApproved(tokenId) == address(transferProxy), "Not approved yet.");
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "Only owner can request.");
        
        require(msg.value == listingFee, "Incorrect listing fee.");
        
        buyOrder[token][tokenId] = amount;
    }
    
    function AuctionRequest(address token, uint256 tokenId, address buytoken) public payable {
        require(IERC721(token).getApproved(tokenId) == address(transferProxy), "Not approved yet.");
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "Only owner can request.");
        
        require(msg.value == listingFee, "Incorrect listing fee.");
        
        auctionOrder[token][tokenId] = buytoken;
    }
    
    function CancelBuyRequest(address token, uint256 tokenId) public {
        require(IERC721(token).getApproved(tokenId) == address(transferProxy), "Not approved yet.");
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "Only owner can request.");
        buyOrder[token][tokenId] = 0;
    }
    
    function validateBuyRequest(address token, uint256 tokenId, uint256 amount) internal {
        require(buyOrder[token][tokenId] == amount, "Amount is incorrect.");
    }
    
    function BidRequest(address sellToken, uint256 tokenId, address buyToken, uint256 amount) public {
        require(IERC20(buyToken).allowance(msg.sender, address(erc20TransferProxy)) >= amount, "Not allowed yet.");
        require(auctionOrder[sellToken][tokenId] == buyToken, "Not acceptable asset.");
        
        bidOrder[sellToken][tokenId][msg.sender][buyToken] = amount;
        bidMembers[sellToken][tokenId].push(msg.sender);
    }
    
    function validateBidRequest(address sellToken, uint256 tokenId, address buyer, address buyToken, uint256 amount) internal {
        require(bidOrder[sellToken][tokenId][buyer][buyToken] == amount, "Amount is incorrect.");
    }
    
    function CancelBid(address sellToken, uint256 tokenId, address buyToken) public {
        bidOrder[sellToken][tokenId][msg.sender][buyToken] = 0;
        for (uint256 i  = 0; i < bidMembers[sellToken][tokenId].length; i++) {
            if (bidMembers[sellToken][tokenId][i] == msg.sender) {
                bidMembers[sellToken][tokenId][i] = bidMembers[sellToken][tokenId][bidMembers[sellToken][tokenId].length - 1];
                bidMembers[sellToken][tokenId].pop();
                break;
            }
        }
    }
    
    function CancelAllBid(address sellToken, uint256 tokenId, address buyToken) internal {
        while (bidMembers[sellToken][tokenId].length != 0) {
            address member = bidMembers[sellToken][tokenId][bidMembers[sellToken][tokenId].length - 1];
            bidOrder[sellToken][tokenId][member][buyToken] = 0;
            bidMembers[sellToken][tokenId].pop();
        }
    }
    
    function CancelAuctionRequests(address sellToken, uint256 tokenId, address buyToken) public {
        require(IERC721(sellToken).getApproved(tokenId) == address(transferProxy), "Not approved nft token.");
        require(IERC721(sellToken).ownerOf(tokenId) == msg.sender, "Only owner can request.");
        
        CancelAllBid(sellToken, tokenId, buyToken);
        auctionOrder[sellToken][tokenId] = address(0);
    }
    
    function setListingFee(uint256 fee) public onlyOwner {
        listingFee = fee;
    }
}