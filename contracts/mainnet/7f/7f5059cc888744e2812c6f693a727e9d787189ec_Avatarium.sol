pragma solidity ^0.4.18;



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


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
    address public owner;
    function Ownable() {
    owner = msg.sender;
    }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

// @title Interface for contracts conforming to ERC-721 Non-Fungible Tokens
// @author Dieter Shirley <span class="__cf_email__" data-cfemail="aacecfdecfeacbd2c3c5c7d0cfc484c9c5">[email&#160;protected]</span> (httpsgithub.comdete)
contract ERC721 {
    //Required methods
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    //Optional
    //function name() public view returns (string name);
    //function symbol() public view returns (string symbol);
    //function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    //function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract Avatarium is Ownable, ERC721 {


    // --- Events --- //


    // @dev The Birth event is fired, whenever a new Avatar has been created.
    event Birth(
        uint256 tokenId, 
        string name, 
        address owner);

    // @dev The TokenSold event is fired, whenever a token is sold.
    event TokenSold(
        uint256 tokenId, 
        uint256 oldPrice, 
        uint256 newPrice, 
        address prevOwner, 
        address winner, 
        string name);
    
    
    // --- Constants --- //


    // The name and the symbol of the NFT, as defined in ERC-721.
    string public constant NAME = "Avatarium";
    string public constant SYMBOL = "ΛV";

    // Prices and iteration steps
    uint256 private startingPrice = 0.02 ether;
    uint256 private firstIterationLimit = 0.05 ether;
    uint256 private secondIterationLimit = 0.5 ether;

    // Addresses that can execute important functions.
    address public addressCEO;
    address public addressCOO;


    // --- Storage --- //


    // @dev A mapping from Avatar ID to the owner&#39;s address.
    mapping (uint => address) public avatarIndexToOwner;

    // @dev A mapping from the owner&#39;s address to the tokens it owns.
    mapping (address => uint256) public ownershipTokenCount;

    // @dev A mapping from Avatar&#39;s ID to an address that has been approved
    // to call transferFrom().
    mapping (uint256 => address) public avatarIndexToApproved;

    // @dev A private mapping from Avatar&#39;s ID to its price.
    mapping (uint256 => uint256) private avatarIndexToPrice;


    // --- Datatypes --- //


    // The main struct
    struct Avatar {
        string name;
    }

    Avatar[] public avatars;


    // --- Access Modifiers --- //


    // @dev Access only to the CEO-functionality.
    modifier onlyCEO() {
        require(msg.sender == addressCEO);
        _;
    }

    // @dev Access only to the COO-functionality.
    modifier onlyCOO() {
        require(msg.sender == addressCOO);
        _;
    }

    // @dev Access to the C-level in general.
    modifier onlyCLevel() {
        require(msg.sender == addressCEO || msg.sender == addressCOO);
        _;
    }


    // --- Constructor --- //


    function Avatarium() public {
        addressCEO = msg.sender;
        addressCOO = msg.sender;
    }


    // --- Public functions --- //


    //@dev Assigns a new address as the CEO. Only available to the current CEO.
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        addressCEO = _newCEO;
    }

    // @dev Assigns a new address as the COO. Only available to the current COO.
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        addressCOO = _newCOO;
    }

    // @dev Grants another address the right to transfer a token via 
    // takeOwnership() and transferFrom()
    function approve(address _to, uint256 _tokenId) public {
        // Check the ownership
        require(_owns(msg.sender, _tokenId));

        avatarIndexToApproved[_tokenId] = _to;

        // Fire the event
        Approval(msg.sender, _to, _tokenId);
    }

    // @dev Checks the balanse of the address, ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    // @dev Creates a new Avatar
    function createAvatar(string _name, uint256 _rank) public onlyCLevel {
        _createAvatar(_name, address(this), _rank);
    }

    // @dev Returns the information on a certain Avatar
    function getAvatar(uint256 _tokenId) public view returns (
        string avatarName,
        uint256 sellingPrice,
        address owner
    ) {
        Avatar storage avatar = avatars[_tokenId];
        avatarName = avatar.name;
        sellingPrice = avatarIndexToPrice[_tokenId];
        owner = avatarIndexToOwner[_tokenId];
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    // @dev Queries the owner of the token.
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = avatarIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function payout(address _to) public onlyCLevel {
        _payout(_to);
    }

    // @dev Allows to purchase an Avatar for Ether.
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = avatarIndexToOwner[_tokenId];
        address newOwner = msg.sender;

        uint256 sellingPrice = avatarIndexToPrice[_tokenId];

        require(oldOwner != newOwner);
        require(_addressNotNull(newOwner));
        require(msg.value == sellingPrice);

        uint256 payment = uint256(SafeMath.div(
                                  SafeMath.mul(sellingPrice, 94), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

        // Updating prices
        if (sellingPrice < firstIterationLimit) {
        // first stage
            avatarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
        } else if (sellingPrice < secondIterationLimit) {
        // second stage
            avatarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
        } else {
        // third stage
            avatarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
        }

        _transfer(oldOwner, newOwner, _tokenId);

        // Pay previous token Owner, if it&#39;s not the contract
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        // Fire event
        
        TokenSold(
            _tokenId,
            sellingPrice,
            avatarIndexToPrice[_tokenId],
            oldOwner,
            newOwner,
            avatars[_tokenId].name);

        // Transferring excessess back to the sender
        msg.sender.transfer(purchaseExcess);
    }

    // @dev Queries the price of a token.
    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return avatarIndexToPrice[_tokenId];
    }
    
    //@dev Allows pre-approved user to take ownership of a token.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = avatarIndexToOwner[_tokenId];

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        //Making sure transfer is approved
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    // @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256 total) {
        return avatars.length;
    }

    // @dev Owner initates the transfer of the token to another account.
    function transfer(
        address _to,
        uint256 _tokenId
    ) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    // @dev Third-party initiates transfer of token from address _from to
    // address _to.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }


    // --- Private Functions --- // 


    // Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    // For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId)
    private 
    view 
    returns (bool) {
        return avatarIndexToApproved[_tokenId] == _to;
    }

    // For creating Avatars.
    function _createAvatar(
        string _name,
        address _owner, 
        uint256 _rank) 
        private {
    
    // Getting the startingPrice
    uint256 _price;
    if (_rank == 1) {
        _price = startingPrice;
    } else if (_rank == 2) {
        _price = 2 * startingPrice;
    } else if (_rank == 3) {
        _price = SafeMath.mul(4, startingPrice);
    } else if (_rank == 4) {
        _price = SafeMath.mul(8, startingPrice);
    } else if (_rank == 5) {
        _price = SafeMath.mul(16, startingPrice);
    } else if (_rank == 6) {
        _price = SafeMath.mul(32, startingPrice);
    } else if (_rank == 7) {
        _price = SafeMath.mul(64, startingPrice);
    } else if (_rank == 8) {
        _price = SafeMath.mul(128, startingPrice);
    } else if (_rank == 9) {
        _price = SafeMath.mul(256, startingPrice);
    } 

    Avatar memory _avatar = Avatar({name: _name});

    uint256 newAvatarId = avatars.push(_avatar) - 1;

    avatarIndexToPrice[newAvatarId] = _price;

    // Fire event
    Birth(newAvatarId, _name, _owner);

    // Transfer token to the contract
    _transfer(address(0), _owner, newAvatarId);
    }

    // @dev Checks for token ownership.
    function _owns(address claimant, uint256 _tokenId) 
    private 
    view 
    returns (bool) {
        return claimant == avatarIndexToOwner[_tokenId];
    }

    // @dev Pays out balance on contract
    function _payout(address _to) private {
        if (_to == address(0)) {
            addressCEO.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

    // @dev Assigns ownership of a specific Avatar to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        avatarIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete avatarIndexToApproved[_tokenId];
        }

        // Fire event
        Transfer(_from, _to, _tokenId);
    }
}