// OwnTheDay-Token Source code
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

    /* Withdraw */
    /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract. User funds are immediately sent to the old
    owner in `claimDay`, no user funds are left in the contract.
    */
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) public onlyOwner {
        require(_amount <= this.balance);
        owner.transfer(_amount);
    }

    function contractBalance() public view returns (uint256) {
        return this.balance;
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
* @author Remco Bloemen <r<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="62070f010d2250">[email&#160;protected]</a>π.com>
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


/**
* @title ERC721 interface
* @dev see https://github.com/ethereum/eips/issues/721
*/
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
}


/// @title Own the Day!
/// @author xeroblood (https://owntheday.io)
contract OwnTheDayContract is ERC721, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    event Bought (uint256 indexed _dayIndex, address indexed _owner, uint256 _price);
    event Sold (uint256 indexed _dayIndex, address indexed _owner, uint256 _price);

    // Total amount of tokens
    uint256 private totalTokens;
    bool private migrationFinished = false;

    // Mapping from token ID to owner
    mapping (uint256 => address) public tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) public tokenApprovals;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint256[]) public ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) public ownedTokensIndex;

    /// @dev A mapping from Day Index to Current Price.
    ///  Initial Price set at 1 finney (1/1000th of an ether).
    mapping (uint256 => uint256) public dayIndexToPrice;

    /// @dev A mapping from Day Index to the address owner. Days with
    ///  no valid owner address are assigned to contract owner.
    //mapping (uint256 => address) public dayIndexToOwner;      // <---  redundant with tokenOwner

    /// @dev A mapping from Account Address to Nickname.
    mapping (address => string) public ownerAddressToName;

    /**
    * @dev Guarantees msg.sender is owner of the given token
    * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    modifier onlyDuringMigration() {
        require(!migrationFinished);
        _;
    }

    function name() public pure returns (string _name) {
        return "OwnTheDay.io Days";
    }

    function symbol() public pure returns (string _symbol) {
        return "DAYS";
    }

    /// @dev Assigns initial days to owners during minting period.
    /// This is only used during migration from old contract to new contract (this one).
    function assignInitialDays(address _to, uint256 _tokenId, uint256 _price) public onlyOwner onlyDuringMigration {
        require(msg.sender != address(0));
        require(_to != address(0));
        require(_tokenId >= 0 && _tokenId < 366);
        require(_price >= 1 finney);
        dayIndexToPrice[_tokenId] = _price;
        _mint(_to, _tokenId);
    }

    function finishMigration() public onlyOwner {
        require(!migrationFinished);
        migrationFinished = true;
    }

    function isMigrationFinished() public view returns (bool) {
        return migrationFinished;
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedTokens[_owner].length;
    }

    /**
    * @dev Gets the list of tokens owned by a given address
    * @param _owner address to query the tokens of
    * @return uint256[] representing the list of tokens owned by the passed address
    */
    function tokensOf(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }

    /**
    * @dev Gets the owner of the specified token ID
    * @param _tokenId uint256 ID of the token to query the owner of
    * @return owner address currently marked as the owner of the given token ID
    */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        return owner;
    }

    /**
    * @dev Gets the approved address to take ownership of a given token ID
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return address currently approved to take ownership of the given token ID
    */
    function approvedFor(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
    * @dev Transfers the ownership of a given token ID to another address
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }

    /**
    * @dev Approves another address to claim for the ownership of the given token ID
    * @param _to address to be approved for the given token ID
    * @param _tokenId uint256 ID of the token to be approved
    */
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (approvedFor(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            Approval(owner, _to, _tokenId);
        }
    }

    /**
    * @dev Claims the ownership of a given token ID
    * @param _tokenId uint256 ID of the token being claimed by the msg.sender
    */
    function takeOwnership(uint256 _tokenId) public {
        require(isApprovedFor(msg.sender, _tokenId));
        clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    /// @dev Calculate the Final Sale Price after the Owner-Cut has been calculated
    function calculateOwnerCut(uint256 _price) public pure returns (uint256) {
        if (_price > 5000 finney) {
            return _price.mul(2).div(100);
        } else if (_price > 500 finney) {
            return _price.mul(3).div(100);
        } else if (_price > 250 finney) {
            return _price.mul(4).div(100);
        }
        return _price.mul(5).div(100);
    }

    /// @dev Calculate the Price Increase based on the current Purchase Price
    function calculatePriceIncrease(uint256 _price) public pure returns (uint256) {
        if (_price > 5000 finney) {
            return _price.mul(15).div(100);
        } else if (_price > 2500 finney) {
            return _price.mul(18).div(100);
        } else if (_price > 500 finney) {
            return _price.mul(26).div(100);
        } else if (_price > 250 finney) {
            return _price.mul(36).div(100);
        }
        return _price; // 100% increase
    }

    /// @dev Gets the Current (or Default) Price of a Day
    function getPriceByDayIndex(uint256 _dayIndex) public view returns (uint256) {
        require(_dayIndex >= 0 && _dayIndex < 366);
        uint256 price = dayIndexToPrice[_dayIndex];
        if (price == 0) { price = 1 finney; }
        return price;
    }

    /// @dev Sets the Nickname for an Account Address
    function setAccountNickname(string _nickname) public whenNotPaused {
        require(msg.sender != address(0));
        require(bytes(_nickname).length > 0);
        ownerAddressToName[msg.sender] = _nickname;
    }

    /// @dev Claim a Day for Your Very Own!
    /// The Purchase Price is Paid to the Previous Owner
    function claimDay(uint256 _dayIndex) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0));
        require(_dayIndex >= 0 && _dayIndex < 366);

        address buyer = msg.sender;
        address seller = tokenOwner[_dayIndex];
        require(msg.sender != seller); // Prevent buying from self

        uint256 amountPaid = msg.value;
        uint256 purchasePrice = dayIndexToPrice[_dayIndex];
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
        dayIndexToPrice[_dayIndex] = newPurchasePrice;

        // Calculate Sale Price after Dev-Cut
        //  - Dev-Cut is left in the contract
        //  - Sale Price is transfered to seller immediately
        uint256 ownerCut = calculateOwnerCut(amountPaid);
        uint256 salePrice = amountPaid.sub(ownerCut);

        // Fire Claim Events
        Bought(_dayIndex, buyer, purchasePrice);
        Sold(_dayIndex, seller, purchasePrice);

        // Transfer token
        if (seller == address(0)) {
            _mint(buyer, _dayIndex);
        } else {
            clearApprovalAndTransfer(seller, buyer, _dayIndex);
        }

        // Transfer Funds
        if (seller != address(0)) {
            seller.transfer(salePrice);
        }
        if (changeToReturn > 0) {
            buyer.transfer(changeToReturn);
        }
    }

    /**
    * @dev Mint token function
    * @param _to The address that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addToken(_to, _tokenId);
        Transfer(0x0, _to, _tokenId);
    }

    /**
    * @dev Tells whether the msg.sender is approved for the given token ID or not
    * This function is not private so it can be extended in further implementations like the operatable ERC721
    * @param _owner address of the owner to query the approval of
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return bool whether the msg.sender is approved for the given token ID or not
    */
    function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
        return approvedFor(_tokenId) == _owner;
    }

    /**
    * @dev Internal function to clear current approval and transfer the ownership of a given token ID
    * @param _from address which you want to send tokens from
    * @param _to address which you want to transfer the token to
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        clearApproval(_from, _tokenId);
        removeToken(_from, _tokenId);
        addToken(_to, _tokenId);
        Transfer(_from, _to, _tokenId);
    }

    /**
    * @dev Internal function to clear current approval of a given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApproval(address _owner, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] = 0;
        Approval(_owner, 0, _tokenId);
    }

    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addToken(address _to, uint256 _tokenId) private {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        totalTokens = totalTokens.add(1);
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeToken(address _from, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _from);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are
        // going to be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we
        // are first swapping the lastToken to the first position, and then dropping the element placed in the last
        // position of the list

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        totalTokens = totalTokens.sub(1);
    }
}