/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.5.0;

//Mutability and Visibility of some functions has been altered.

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x6466353c
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`

    // Changed mutability to implicit non-payable
    // Changed visibility to public
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    // Changed mutability to implicit non-payable
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    // Changed mutability to implicit non-payable
    // Changed visibility to public
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve

    // Changed mutability to implicit non-payable
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Throws unless `msg.sender` is the current NFT owner.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: @openzeppelin/contracts/math/Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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


interface INFTGovernance {
    function getListingActiveDelay() external view returns (uint256);
    function getBuyBonusResidual() external view returns (uint256);
    function getMarketFee() external view returns (uint256);
    function getAbsoluteMinPrice() external view returns (uint256);
    function getMinPrice() external view returns (uint256);
    function getMaxPrice() external view returns (uint256);
    function getTokensForPrice(uint256 price) external view returns (uint256);
    function getApproved(uint256 _tokenId) external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getNftAddress(uint256 _tokenId) external view returns (address);
}

contract NFTGovernance is INFTGovernance {
    using SafeMath for uint256;

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
    
    modifier unlocked(uint256 index) {
        require(!isTimelockActivated || block.number > unlockTimes[index], "Locked");
        _;
    }
    
    modifier timelockUnlocked() {
        require(!isTimelockActivated || block.number > timelockLengthUnlockTime, "Timelock variable Locked");
        _;
    }
    
    bool public isTimelockActivated = false;

    address public nftAddress;
    address public owner;

    uint256 constant DEFAULT_TIMELOCK_LENGTH = 44800; // length in blocks ~7 days;

    uint256 constant MARKET_FEE_INDEX = 0;
    uint256 constant MIN_PRICE_INDEX = 1;
    uint256 constant MAX_PRICE_INDEX = 2;
    uint256 constant TARGET_PRICE_INDEX = 3;
    uint256 constant BUY_BONUS_RESIDUAL_INDEX = 4;
    uint256 constant LISTING_DELAY_INDEX = 5;
    uint256 constant ABSOLUTE_MIN_PRICE_INDEX = 6;
    
    uint256 public timelockLengthUnlockTime = 0;
    uint256 public timelockLength = DEFAULT_TIMELOCK_LENGTH;
    uint256 public nextTimelockLength = DEFAULT_TIMELOCK_LENGTH;
        
    uint256 public PRICE_SCALE_FACTOR = 10;


    mapping(uint256 => uint256) public pendingValues;
    mapping(uint256 => uint256) public values;
    mapping(uint256 => uint256) public unlockTimes;

    constructor (
        uint256 marketFeeFactor, 
        uint256 minPrice, 
        uint256 maxPrice, 
        uint256 targetPrice, 
        uint256 buyBonusResidual, 
        uint256 listingActiveDelay, 
        uint256 absoluteMinPrice, 
        address _nftAddress
    ) public {
        values[MARKET_FEE_INDEX] = marketFeeFactor;
        values[MIN_PRICE_INDEX] = minPrice;
        values[MAX_PRICE_INDEX] = maxPrice;
        values[TARGET_PRICE_INDEX] = targetPrice;
        values[BUY_BONUS_RESIDUAL_INDEX] = buyBonusResidual;
        values[LISTING_DELAY_INDEX] = listingActiveDelay;
        values[ABSOLUTE_MIN_PRICE_INDEX] = absoluteMinPrice;
        
        nftAddress = _nftAddress;
        owner = msg.sender;
    }

    function activateTimelock() external onlyOwner {
        isTimelockActivated = true;
    }

    function setPendingValue(uint256 index, uint256 value) external onlyOwner {
        pendingValues[index] = value;
        unlockTimes[index] = timelockLength.add(block.number);
    }

    function certifyPendingValue(uint256 index) external onlyOwner unlocked(index) {
        values[index] = pendingValues[index];
        unlockTimes[index] = 0;
    }

    function proposeNextTimelockLength(uint256 value) public onlyOwner {
        nextTimelockLength = value;
        timelockLengthUnlockTime = block.number.add(timelockLength);
    }

    function certifyNextTimelockLength() public onlyOwner timelockUnlocked() {
        timelockLength = nextTimelockLength;
        timelockLengthUnlockTime = 0;
    }
    
    function getMarketFee() public view returns (uint256) {
        return values[MARKET_FEE_INDEX];
    }

    function getMinPrice() public view returns (uint256) {
        return values[MIN_PRICE_INDEX];    
    }

    function getMaxPrice() public view returns (uint256) {
        return values[MAX_PRICE_INDEX];    
    }

    function getTargetPrice() public view returns (uint256) {
        return values[TARGET_PRICE_INDEX];    
    }
    
    function getBuyBonusResidual() public view returns (uint256) {
        return values[BUY_BONUS_RESIDUAL_INDEX];    
    }
    
    function getListingActiveDelay() public view returns (uint256) {
        return values[LISTING_DELAY_INDEX];    
    }    

    function getAbsoluteMinPrice() public view returns (uint256) {
        return values[ABSOLUTE_MIN_PRICE_INDEX];    
    }
    
    function getTokensForPrice(uint256 price) external view returns (uint256) {
        uint256 max = getMaxPrice();
        uint256 min = getMinPrice();
        uint256 target = getTargetPrice();

        uint256 startRange = target.mul(1e18).div(min);
        uint256 endRange = target.mul(1e18).div(max);
        
        uint256 effectivePrice = price;
        if (price < min) {
            effectivePrice = min;
        } else if (price > max) {
            effectivePrice = max;
        }

        uint256 tokens = 0;
        if (effectivePrice < target) {
            tokens = (target.sub(effectivePrice)).mul(startRange).div(1e18).mul(PRICE_SCALE_FACTOR).add(1e18);
        } else {
            tokens = (max.sub(effectivePrice)).mul(endRange).div(1e18);
        }
        
        return tokens;
    }
    
    function getApproved(uint256 _tokenId) external view returns (address) {
        ERC721 token = ERC721(nftAddress);
        return token.getApproved(_tokenId);
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address) {
        ERC721 token = ERC721(nftAddress);
        return token.ownerOf(_tokenId);
    }
    
    function getNftAddress(uint256 _tokenId) external view returns (address) {
        return nftAddress;
    }
}