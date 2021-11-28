// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Pausable.sol";

/// @title Advertisement Manager Contract
/// @author Mariona (seaona)
/// @notice Do not use this contract on production
contract AdsManager is Pausable {
    /// @dev Using SafeMath to protect from overflow and underflow
    using SafeMath for uint256;
    
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    /// @dev Advertisement variables
    mapping (uint => Ad) ads;
    uint256 public adsCounter;

    /// @dev Total Advertisement Area available is an abstract representation of the surface of the website available for Ads
    uint256 public totalAdAreaAvailable = 100;

    /// @dev Total Advertisement Taken is an abstract representation of the surface of the website dedicated to certains ad
    uint256 public totalAdAreaTaken = 0;

    /// @dev Total max area for advertisement cannot be updated as website space for advertisements is limited
    uint256 constant public totalAdMaxArea = 200;

    /// @dev Ads can be ForSale or Sold
    enum State { ForSale, Sold }

    /// @dev Big = 50 units of area, Medium = 25 units of area, Small = 10 units of area
    enum Size { Big, Medium, Small }

    /// @dev This is an Advertisement item
    struct Ad {
        State state;
        Size size;
        bytes32 brand;
        address payable owner;
        uint256 price;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    /// @dev Event that is emitted when Advertisement Area is put for sale
    event AdAreaForSale(uint32 _adId);

    /// @dev Event that is emitted when Advertisement Area is bought
    event AdAreaBought(uint32 _adId);

    /// @dev Event that is emitted when the owner of the website adds extra a Small Advertisement Area for sale
    event SmallAdAreaAdded(Size _size);

    /// @dev Event that is emitted when the owner of the website adds extra a Medium Advertisement Area for sale
    event MediumAdAreaAdded(Size _size);

    /// @dev Event that is emitted when the owner of the website adds extra a Big Advertisement Area for sale
    event BigAdAreaAdded(Size _size);


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/
    /// @dev Modifier that throws if called by any account other than the Advertisement Owner
    modifier onlyAdOwner(uint32 _adId) {
        require(msg.sender == ads[_adId].owner, "You are not the owner of this Ad Area");
        _;
    }

    /// @dev Modifier that throws if not paid enough for the Ad 
    modifier paidEnough(uint _adId) { 
        require(msg.value >= ads[_adId].price, "You haven't paid enough for buying this Ad space"); 
        _;
    }

    /// @dev Modifier that throws if there is not enough Advertisement area available
    modifier enoughAdArea(uint _area) { 
        require(_area <= totalAdMaxArea, "There is not enough Advertisement area available"); 
        _;
    }

    /********************************************************************************************/
    /*                                         UTIL FUNCTIONS                                   */
    /********************************************************************************************/
    /// @dev Get the total number of Ads Areas
    /// @return Total Ads Areas
    function getAdsCounter() public returns (uint256) {
        return adsCounter;
    }
    
    /// @dev Get the total Advertisement area for that website
    /// @return Total Advertisement Area
    function getTotalAdMaxArea() public view returns(uint256) {
        return totalAdMaxArea;
    }

    /// @dev Get the total Advertisement area taken for that website
    /// @return Total Advertisement Area taken by Brands
    function getTotalAdAreaTaken() public view returns(uint256) {
        return totalAdAreaAvailable;
    }

    /// @dev Get the total Advertisement area available for ads that website
    /// @return Total Advertisement Area available for Brands
    function getTotalAdAreaAvailable() public view returns(uint256) {
        return totalAdAreaTaken;
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
   
    /// @dev Website Owner Adds a Small Advertisement Area
    /// @return Total Advertisement Area available for Brands
    function addSmallAdvertisementSpace() public onlyOwner whenNotPaused returns (uint256) {
        require(totalAdAreaAvailable+totalAdAreaTaken+10 <= totalAdMaxArea, "Ads Area is already completed");

        ads[adsCounter].state = State.ForSale;
        ads[adsCounter].size = Size.Small;
        ads[adsCounter].brand = "For Sale";
        ads[adsCounter].owner = payable(msg.sender);
        ads[adsCounter].price = 100;

        adsCounter++;

        totalAdAreaAvailable = totalAdAreaAvailable + 10;

        emit SmallAdAreaAdded(Size.Small);
        return totalAdAreaAvailable;
    }

    /// @dev Website Owner Adds a Medium Advertisement Area
    /// @return Total Advertisement Area available for Brands
    function addMediumAdvertisementSpace() public onlyOwner whenNotPaused returns (uint256) {
        require(totalAdAreaAvailable+totalAdAreaTaken+25 <= totalAdMaxArea, "Ads Area is already completed");

        ads[adsCounter].state = State.ForSale;
        ads[adsCounter].size = Size.Medium;
        ads[adsCounter].brand = "For Sale";
        ads[adsCounter].owner = payable(msg.sender);
        ads[adsCounter].price = 250;

        adsCounter++;

        totalAdAreaAvailable = totalAdAreaAvailable + 25;

        emit MediumAdAreaAdded(Size.Medium);
        return totalAdAreaAvailable;
    }

    /// @dev Website Owner Adds a Big Advertisement Area
    /// @return Total Advertisement Area available for Brands
    function addBigAdvertisementSpace() public onlyOwner whenNotPaused returns (uint256) {
        require(totalAdAreaAvailable+totalAdAreaTaken+50 <= totalAdMaxArea, "Ads Area is already completed");

        ads[adsCounter].state = State.ForSale;
        ads[adsCounter].size = Size.Big;
        ads[adsCounter].brand = "For Sale";
        ads[adsCounter].owner = payable(msg.sender);
        ads[adsCounter].price = 500;

        adsCounter++;

        totalAdAreaAvailable = totalAdAreaAvailable + 50;

        emit BigAdAreaAdded(Size.Big);
        return totalAdAreaAvailable;
    }

    /// @dev Brand buys Advertisement Area
    function buyAdArea(uint32 _adId, bytes32 _brand) public payable paidEnough(_adId) whenNotPaused {
        require(ads[_adId].state == State.ForSale, "Ad Area is not for Sale");
        uint256 requiredSpace =0;

        if(ads[_adId].size==Size.Big) {
            requiredSpace = 50;
        }
        if(ads[_adId].size==Size.Medium) {
            requiredSpace = 25;
        }

        if(ads[_adId].size==Size.Small) {
            requiredSpace = 10;
        }
            
        totalAdAreaAvailable = totalAdAreaAvailable - requiredSpace;
        uint256 amountToRefund = msg.value - ads[_adId].price;
        ads[_adId].owner = payable(msg.sender);
        ads[_adId].owner.transfer(amountToRefund);
        ads[_adId].state = State.Sold;
        ads[_adId].brand = _brand;

        emit AdAreaBought(_adId);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title An Ownable Contract
/// @author Mariona (seaona)
/// @notice Do not use this contract on production

contract Ownable {

    address private _owner;

    /// @dev Get current contract owner
    /// @return Address of current contract owner
    function getOwner() public view returns(address) {
        return _owner;
    }

    /// @dev Constructor that sets the _owner var to the creater of the contract 
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /// @dev 'onlyOwner' modifier that throws if called by any account other than the owner.
    modifier onlyOwner {
        require(msg.sender == _owner, "You are not authorized to perform this action");
        _;
    }

    /// @dev Transfers ownership to a new address, only owner can call this function
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /// @dev Function for getting the contract owner
    /// @return Address with the current contract owner
    function getContractOwner() public view returns (address) {
        return _owner;
    }

    /// @dev Event that is throwed when contract ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/// @title A Pausable Contract
/// @author Mariona (seaona)
/// @notice Do not use this contract on production

contract Pausable is Ownable {

    bool private _paused;

    /// @dev Pause contract when it's running
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @dev Resume contract when it' not paused
    function resumeContract() public onlyOwner whenNotPaused {
        _paused = false;
        emit ResumeContract(msg.sender);
    }

    /// @dev Constructor that sets the _paused variable to false
    constructor() {
        _paused = false;
    }
    
    /// @dev 'whenNotPaused' modifier that throws if contract is Paused.
    modifier whenNotPaused () {
        require(_paused == false, "Contract Paused!");
        _;
    }

    /// @dev 'whenNotPaused' modifier that throws if contract is Not Paused.
    modifier paused() {
        require(_paused == true, "Contract not Paused!");
        _;

    }

    /// @dev Function that returns if Contract is Paused
    /// @return Boolean saying if contract is Paused or not
    function isContractPaused() public view returns (bool) {
        return _paused;
    }

    /// @dev Paused event that emits the address that triggered the event
    /// @param account The address that triggered the event
    event Paused(address indexed account);

    /// @dev ResumeContract event that emits the address that triggered the event
    /// @param account The address that triggered the event
    event ResumeContract(address indexed account);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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