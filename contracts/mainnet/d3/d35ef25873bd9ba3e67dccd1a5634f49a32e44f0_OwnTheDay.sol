// OwnTheDay Source code
// copyright 2018 xeroblood <https://owntheday.io>

pragma solidity 0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


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
    function Ownable() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
* @title Pausable
* @dev Base contract which allows children to implement an emergency stop mechanism.
*/
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


/**
* @title Helps contracts guard agains reentrancy attacks.
* @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="97e5f2faf4f8d7a5">[email&#160;protected]</a>π.com>
* @notice If you mark a function `nonReentrant`, you should also
* mark it `external`.
*/
contract ReentrancyGuard {

    /**
    * @dev We use a single lock for the whole contract.
    */
    bool private reentrancyLock = false;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * @notice If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one nonReentrant function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and a `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}


/// @title Own the Day!
/// @author xeroblood (https://owntheday.io)
contract OwnTheDay is Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    event DayClaimed(address buyer, address seller, uint16 dayIndex, uint256 newPrice);

    /// @dev A mapping from Day Index to Current Price.
    ///  Initial Price set at 1 finney (1/1000th of an ether).
    mapping (uint16 => uint256) public dayIndexToPrice;

    /// @dev A mapping from Day Index to the address owner. Days with
    ///  no valid owner address are assigned to contract owner.
    mapping (uint16 => address) public dayIndexToOwner;

    /// @dev A mapping from Account Address to Nickname.
    mapping (address => string) public ownerAddressToName;

    /// @dev Calculate the Final Sale Price after the Owner-Cut has been calculated
    function calculateOwnerCut(uint256 price) public pure returns (uint256) {
        uint8 percentCut = 5;
        if (price > 5000 finney) {
            percentCut = 2;
        } else if (price > 500 finney) {
            percentCut = 3;
        } else if (price > 250 finney) {
            percentCut = 4;
        }
        return price.mul(percentCut).div(100);
    }

    /// @dev Calculate the Price Increase based on the current Purchase Price
    function calculatePriceIncrease(uint256 price) public pure returns (uint256) {
        uint8 percentIncrease = 100;
        if (price > 5000 finney) {
            percentIncrease = 15;
        } else if (price > 2500 finney) {
            percentIncrease = 18;
        } else if (price > 500 finney) {
            percentIncrease = 26;
        } else if (price > 250 finney) {
            percentIncrease = 36;
        }
        return price.mul(percentIncrease).div(100);
    }

    /// @dev Gets the Current (or Default) Price of a Day
    function getPriceByDayIndex(uint16 dayIndex) public view returns (uint256) {
        require(dayIndex >= 0 && dayIndex < 366);
        uint256 price = dayIndexToPrice[dayIndex];
        if (price == 0) { price = 1 finney; }
        return price;
    }

    /// @dev Sets the Nickname for an Account Address
    function setAccountNickname(string nickname) public whenNotPaused {
        require(msg.sender != address(0));
        require(bytes(nickname).length > 0);
        ownerAddressToName[msg.sender] = nickname;
    }

    /// @dev Claim a Day for Your Very Own!
    /// The Purchase Price is Paid to the Previous Owner
    function claimDay(uint16 dayIndex) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0));
        require(dayIndex >= 0 && dayIndex < 366);

        // Prevent buying from self
        address buyer = msg.sender;
        address seller = dayIndexToOwner[dayIndex];
        require(buyer != seller);

        // Get Amount Paid
        uint256 amountPaid = msg.value;

        // Get Current Purchase Price from Index and ensure enough was Paid
        uint256 purchasePrice = dayIndexToPrice[dayIndex];
        if (purchasePrice == 0) {
            purchasePrice = 1 finney; // == 0.001 ether or 1000000000000000 wei
        }
        require(amountPaid >= purchasePrice);

        // If too much was paid, track the change to be returned
        uint256 changeToReturn = 0;
        if (amountPaid > purchasePrice) {
            changeToReturn = amountPaid.sub(purchasePrice);
            amountPaid -= changeToReturn;
        }

        // Calculate New Purchase Price and update storage
        uint256 priceIncrease = calculatePriceIncrease(purchasePrice);
        uint256 newPurchasePrice = purchasePrice.add(priceIncrease);
        dayIndexToPrice[dayIndex] = newPurchasePrice;

        // Calculate Sale Price after Owner-Cut and update Owner Balance
        uint256 ownerCut = calculateOwnerCut(amountPaid);
        uint256 salePrice = amountPaid.sub(ownerCut);

        // Assign Day to New Owner
        dayIndexToOwner[dayIndex] = buyer;

        // Fire Claim Event
        DayClaimed(buyer, seller, dayIndex, newPurchasePrice);

        // Transfer Funds (Initial sales are made to owner)
        if (seller != address(0)) {
            owner.transfer(ownerCut);
            seller.transfer(salePrice);
        } else {
            owner.transfer(salePrice.add(ownerCut));
        }
        if (changeToReturn > 0) {
            buyer.transfer(changeToReturn);
        }
    }
}