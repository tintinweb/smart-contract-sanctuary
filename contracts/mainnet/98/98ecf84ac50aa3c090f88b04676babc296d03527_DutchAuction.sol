pragma solidity ^0.4.18;



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




 // Pause functionality taken from OpenZeppelin. License below.
 /* The MIT License (MIT)
 Copyright (c) 2016 Smart Contract Solutions, Inc.
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions: */

 /**
  * @title Pausable
  * @dev Base contract which allows children to implement an emergency stop mechanism.
  */
contract Pausable is Ownable {

  event SetPaused(bool paused);

  // starts unpaused
  bool public paused = false;

  /* @dev modifier to allow actions only when the contract IS paused */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /* @dev modifier to allow actions only when the contract IS NOT paused */
  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    SetPaused(paused);
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    SetPaused(paused);
    return true;
  }
}

contract EtherbotsPrivileges is Pausable {
  event ContractUpgrade(address newContract);

}

// import "./contracts/CratePreSale.sol";
// Central collection of storage on which all other contracts depend.
// Contains structs for parts, users and functions which control their
// transferrence.
contract EtherbotsBase is EtherbotsPrivileges {


    function EtherbotsBase() public {
    //   scrapyard = address(this);
    }
    /*** EVENTS ***/

    ///  Forge fires when a new part is created - 4 times when a crate is opened,
    /// and once when a battle takes place. Also has fires when
    /// parts are combined in the furnace.
    event Forge(address owner, uint256 partID, Part part);

    ///  Transfer event as defined in ERC721.
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/
    ///  The main struct representation of a robot part. Each robot in Etherbots is represented by four copies
    ///  of this structure, one for each of the four parts comprising it:
    /// 1. Right Arm (Melee),
    /// 2. Left Arm (Defence),
    /// 3. Head (Turret),
    /// 4. Body.
    // store token id on this?
     struct Part {
        uint32 tokenId;
        uint8 partType;
        uint8 partSubType;
        uint8 rarity;
        uint8 element;
        uint32 battlesLastDay;
        uint32 experience;
        uint32 forgeTime;
        uint32 battlesLastReset;
    }

    // Part type - can be shared with other part factories.
    uint8 constant DEFENCE = 1;
    uint8 constant MELEE = 2;
    uint8 constant BODY = 3;
    uint8 constant TURRET = 4;

    // Rarity - can be shared with other part factories.
    uint8 constant STANDARD = 1;
    uint8 constant SHADOW = 2;
    uint8 constant GOLD = 3;


    // Store a user struct
    // in order to keep track of experience and perk choices.
    // This perk tree is a binary tree, efficiently encodable as an array.
    // 0 reflects no perk selected. 1 is first choice. 2 is second. 3 is both.
    // Each choice costs experience (deducted from user struct).

    /*** ~~~~~ROBOT PERKS~~~~~ ***/
    // PERK 1: ATTACK vs DEFENCE PERK CHOICE.
    // Choose
    // PERK TWO ATTACK/ SHOOT, or DEFEND/DODGE
    // PERK 2: MECH vs ELEMENTAL PERK CHOICE ---
    // Choose steel and electric (Mech path), or water and fire (Elemetal path)
    // (... will the mechs win the war for Ethertopia? or will the androids
    // be deluged in flood and fire? ...)
    // PERK 3: Commit to a specific elemental pathway:
    // 1. the path of steel: the iron sword; the burning frying pan!
    // 2. the path of electricity: the deadly taser, the fearsome forcefield
    // 3. the path of water: high pressure water blasters have never been so cool
    // 4. the path of fire!: we will hunt you down, Aang...


    struct User {
        // address userAddress;
        uint32 numShards; //limit shards to upper bound eg 10000
        uint32 experience;
        uint8[32] perks;
    }

    //Maintain an array of all users.
    // User[] public users;

    // Store a map of the address to a uint representing index of User within users
    // we check if a user exists at multiple points, every time they acquire
    // via a crate or the market. Users can also manually register their address.
    mapping ( address => User ) public addressToUser;

    // Array containing the structs of all parts in existence. The ID
    // of each part is an index into this array.
    Part[] parts;

    // Mapping from part IDs to to owning address. Should always exist.
    mapping (uint256 => address) public partIndexToOwner;

    //  A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count. REMOVE?
    mapping (address => uint256) addressToTokensOwned;

    // Mapping from Part ID to an address approved to call transferFrom().
    // maximum of one approved address for transfer at any time.
    mapping (uint256 => address) public partIndexToApproved;

    address auction;
    // address scrapyard;

    // Array to store approved battle contracts.
    // Can only ever be added to, not removed from.
    // Once a ruleset is published, you will ALWAYS be able to use that contract
    address[] approvedBattles;


    function getUserByAddress(address _user) public view returns (uint32, uint8[32]) {
        return (addressToUser[_user].experience, addressToUser[_user].perks);
    }

    //  Transfer a part to an address
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // No cap on number of parts
        // Very unlikely to ever be 2^256 parts owned by one account
        // Shouldn&#39;t waste gas checking for overflow
        // no point making it less than a uint --> mappings don&#39;t pack
        addressToTokensOwned[_to]++;
        // transfer ownership
        partIndexToOwner[_tokenId] = _to;
        // New parts are transferred _from 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            addressToTokensOwned[_from]--;
            // clear any previously approved ownership exchange
            delete partIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    function getPartById(uint _id) external view returns (
        uint32 tokenId,
        uint8 partType,
        uint8 partSubType,
        uint8 rarity,
        uint8 element,
        uint32 battlesLastDay,
        uint32 experience,
        uint32 forgeTime,
        uint32 battlesLastReset
    ) {
        Part memory p = parts[_id];
        return (p.tokenId, p.partType, p.partSubType, p.rarity, p.element, p.battlesLastDay, p.experience, p.forgeTime, p.battlesLastReset);
    }


    function substring(string str, uint startIndex, uint endIndex) internal pure returns (string) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    // helper functions adapted from  Jossie Calderon on stackexchange
    function stringToUint32(string s) internal pure returns (uint32) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return uint32(result);
    }

    function stringToUint8(string s) internal pure returns (uint8) {
        return uint8(stringToUint32(s));
    }

    function uintToString(uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s);
        return str;
    }
}


// This contract implements both the original ERC-721 standard and
// the proposed &#39;deed&#39; standard of 841
// I don&#39;t know which standard will eventually be adopted - support both for now


/// @title Interface for contracts conforming to ERC-721: Deed Standard
/// @author William Entriken (https://phor.net), et. al.
/// @dev Specification at https://github.com/ethereum/eips/841
/// can read the comments there
contract ERC721 {

    // COMPLIANCE WITH ERC-165 (DRAFT)

    /// @dev ERC-165 (draft) interface signature for itself
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    /// @dev ERC-165 (draft) interface signature for ERC721
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 =
         bytes4(keccak256("ownerOf(uint256)")) ^
         bytes4(keccak256("countOfDeeds()")) ^
         bytes4(keccak256("countOfDeedsByOwner(address)")) ^
         bytes4(keccak256("deedOfOwnerByIndex(address,uint256)")) ^
         bytes4(keccak256("approve(address,uint256)")) ^
         bytes4(keccak256("takeOwnership(uint256)"));

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

    // PUBLIC QUERY FUNCTIONS //////////////////////////////////////////////////

    function ownerOf(uint256 _deedId) public view returns (address _owner);
    function countOfDeeds() external view returns (uint256 _count);
    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count);
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

    // TRANSFER MECHANISM //////////////////////////////////////////////////////

    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed deedId);

    function approve(address _to, uint256 _deedId) external payable;
    function takeOwnership(uint256 _deedId) external payable;
}

/// @title Metadata extension to ERC-721 interface
/// @author William Entriken (https://phor.net)
/// @dev Specification at https://github.com/ethereum/eips/issues/XXXX
contract ERC721Metadata is ERC721 {

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("deedUri(uint256)"));

    function name() public pure returns (string n);
    function symbol() public pure returns (string s);

    /// @notice A distinct URI (RFC 3986) for a given token.
    /// @dev If:
    ///  * The URI is a URL
    ///  * The URL is accessible
    ///  * The URL points to a valid JSON file format (ECMA-404 2nd ed.)
    ///  * The JSON base element is an object
    ///  then these names of the base element SHALL have special meaning:
    ///  * "name": A string identifying the item to which `_deedId` grants
    ///    ownership
    ///  * "description": A string detailing the item to which `_deedId` grants
    ///    ownership
    ///  * "image": A URI pointing to a file of image/* mime type representing
    ///    the item to which `_deedId` grants ownership
    ///  Wallets and exchanges MAY display this to the end user.
    ///  Consider making any images at a width between 320 and 1080 pixels and
    ///  aspect ratio between 1.91:1 and 4:5 inclusive.
    function deedUri(uint256 _deedId) external view returns (string _uri);
}

/// @title Enumeration extension to ERC-721 interface
/// @author William Entriken (https://phor.net)
/// @dev Specification at https://github.com/ethereum/eips/issues/XXXX
contract ERC721Enumerable is ERC721Metadata {

    /// @dev ERC-165 (draft) interface signature for ERC721
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Enumerable =
        bytes4(keccak256("deedByIndex()")) ^
        bytes4(keccak256("countOfOwners()")) ^
        bytes4(keccak256("ownerByIndex(uint256)"));

    function deedByIndex(uint256 _index) external view returns (uint256 _deedId);
    function countOfOwners() external view returns (uint256 _count);
    function ownerByIndex(uint256 _index) external view returns (address _owner);
}

contract ERC721Original {

    bytes4 constant INTERFACE_SIGNATURE_ERC721Original =
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("takeOwnership(uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)"));

    // Core functions
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint _tokenId) public view returns (address _owner);
    function approve(address _to, uint _tokenId) external payable;
    function transferFrom(address _from, address _to, uint _tokenId) public;
    function transfer(address _to, uint _tokenId) public payable;

    // Optional functions
    function name() public pure returns (string _name);
    function symbol() public pure returns (string _symbol);
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint _tokenId);
    function tokenMetadata(uint _tokenId) public view returns (string _infoUrl);

    // Events
    // event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    // event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract ERC721AllImplementations is ERC721Original, ERC721Enumerable {

}


contract EtherbotsNFT is EtherbotsBase, ERC721Enumerable, ERC721Original {
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return (_interfaceID == ERC721Original.INTERFACE_SIGNATURE_ERC721Original) ||
            (_interfaceID == ERC721.INTERFACE_SIGNATURE_ERC721) ||
            (_interfaceID == ERC721Metadata.INTERFACE_SIGNATURE_ERC721Metadata) ||
            (_interfaceID == ERC721Enumerable.INTERFACE_SIGNATURE_ERC721Enumerable);
    }
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function name() public pure returns (string _name) {
      return "Etherbots";
    }

    function symbol() public pure returns (string _smbol) {
      return "ETHBOT";
    }

    // total supply of parts --> as no parts are ever deleted, this is simply
    // the total supply of parts ever created
    function totalSupply() public view returns (uint) {
        return parts.length;
    }

    /// @notice Returns the total number of deeds currently in existence.
    /// @dev Required for ERC-721 compliance.
    function countOfDeeds() external view returns (uint256) {
        return parts.length;
    }

    //--/ internal function    which checks whether the token with id (_tokenId)
    /// is owned by the (_claimant) address
    function owns(address _owner, uint256 _tokenId) public view returns (bool) {
        return (partIndexToOwner[_tokenId] == _owner);
    }

    /// internal function    which checks whether the token with id (_tokenId)
    /// is owned by the (_claimant) address
    function ownsAll(address _owner, uint256[] _tokenIds) public view returns (bool) {
        require(_tokenIds.length > 0);
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (partIndexToOwner[_tokenIds[i]] != _owner) {
                return false;
            }
        }
        return true;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        partIndexToApproved[_tokenId] = _approved;
    }

    function _approvedFor(address _newOwner, uint256 _tokenId) internal view returns (bool) {
        return (partIndexToApproved[_tokenId] == _newOwner);
    }

    function ownerByIndex(uint256 _index) external view returns (address _owner){
        return partIndexToOwner[_index];
    }

    // returns the NUMBER of tokens owned by (_owner)
    function balanceOf(address _owner) public view returns (uint256 count) {
        return addressToTokensOwned[_owner];
    }

    function countOfDeedsByOwner(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

    // transfers a part to another account
    function transfer(address _to, uint256 _tokenId) public whenNotPaused payable {
        // payable for ERC721 --> don&#39;t actually send eth @<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="217e61">[email&#160;protected]</a>
        require(msg.value == 0);

        // Safety checks to prevent accidental transfers to common accounts
        require(_to != address(0));
        require(_to != address(this));
        // can&#39;t transfer parts to the auction contract directly
        require(_to != address(auction));
        // can&#39;t transfer parts to any of the battle contracts directly
        for (uint j = 0; j < approvedBattles.length; j++) {
            require(_to != approvedBattles[j]);
        }

        // Cannot send tokens you don&#39;t own
        require(owns(msg.sender, _tokenId));

        // perform state changes necessary for transfer
        _transfer(msg.sender, _to, _tokenId);
    }
    // transfers a part to another account

    function transferAll(address _to, uint256[] _tokenIds) public whenNotPaused payable {
        require(msg.value == 0);

        // Safety checks to prevent accidental transfers to common accounts
        require(_to != address(0));
        require(_to != address(this));
        // can&#39;t transfer parts to the auction contract directly
        require(_to != address(auction));
        // can&#39;t transfer parts to any of the battle contracts directly
        for (uint j = 0; j < approvedBattles.length; j++) {
            require(_to != approvedBattles[j]);
        }

        // Cannot send tokens you don&#39;t own
        require(ownsAll(msg.sender, _tokenIds));

        for (uint k = 0; k < _tokenIds.length; k++) {
            // perform state changes necessary for transfer
            _transfer(msg.sender, _to, _tokenIds[k]);
        }


    }


    // approves the (_to) address to use the transferFrom function on the token with id (_tokenId)
    // if you want to clear all approvals, simply pass the zero address
    function approve(address _to, uint256 _deedId) external whenNotPaused payable {
        // payable for ERC721 --> don&#39;t actually send eth @<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="055a45">[email&#160;protected]</a>
        require(msg.value == 0);
// use internal function?
        // Cannot approve the transfer of tokens you don&#39;t own
        require(owns(msg.sender, _deedId));

        // Store the approval (can only approve one at a time)
        partIndexToApproved[_deedId] = _to;

        Approval(msg.sender, _to, _deedId);
    }

    // approves many token ids
    function approveMany(address _to, uint256[] _tokenIds) external whenNotPaused payable {

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint _tokenId = _tokenIds[i];

            // Cannot approve the transfer of tokens you don&#39;t own
            require(owns(msg.sender, _tokenId));

            // Store the approval (can only approve one at a time)
            partIndexToApproved[_tokenId] = _to;
            //create event for each approval? _tokenId guaranteed to hold correct value?
            Approval(msg.sender, _to, _tokenId);
        }
    }

    // transfer the part with id (_tokenId) from (_from) to (_to)
    // (_to) must already be approved for this (_tokenId)
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {

        // Safety checks to prevent accidents
        require(_to != address(0));
        require(_to != address(this));

        // sender must be approved
        require(partIndexToApproved[_tokenId] == msg.sender);
        // from must currently own the token
        require(owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    // returns the current owner of the token with id = _tokenId
    function ownerOf(uint256 _deedId) public view returns (address _owner) {
        _owner = partIndexToOwner[_deedId];
        // must result false if index key not found
        require(_owner != address(0));
    }

    // returns a dynamic array of the ids of all tokens which are owned by (_owner)
    // Looping through every possible part and checking it against the owner is
    // actually much more efficient than storing a mapping or something, because
    // it won&#39;t be executed as a transaction
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 totalParts = totalSupply();

        return tokensOfOwnerWithinRange(_owner, 0, totalParts);
  
    }

    function tokensOfOwnerWithinRange(address _owner, uint _start, uint _numToSearch) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tmpResult = new uint256[](tokenCount);
        if (tokenCount == 0) {
            return tmpResult;
        }

        uint256 resultIndex = 0;
        for (uint partId = _start; partId < _start + _numToSearch; partId++) {
            if (partIndexToOwner[partId] == _owner) {
                tmpResult[resultIndex] = partId;
                resultIndex++;
                if (resultIndex == tokenCount) { //found all tokens accounted for, no need to continue
                    break;
                }
            }
        }

        // copy number of tokens found in given range
        uint resultLength = resultIndex;
        uint256[] memory result = new uint256[](resultLength);
        for (uint i=0; i<resultLength; i++) {
            result[i] = tmpResult[i];
        }
        return result;
    }



    //same issues as above
    // Returns an array of all part structs owned by the user. Free to call.
    function getPartsOfOwner(address _owner) external view returns(bytes24[]) {
        uint256 totalParts = totalSupply();

        return getPartsOfOwnerWithinRange(_owner, 0, totalParts);
    }
    
    // This is public so it can be called by getPartsOfOwner. It should NOT be called by another contract
    // as it is very gas hungry.
    function getPartsOfOwnerWithinRange(address _owner, uint _start, uint _numToSearch) public view returns(bytes24[]) {
        uint256 tokenCount = balanceOf(_owner);

        uint resultIndex = 0;
        bytes24[] memory result = new bytes24[](tokenCount);
        for (uint partId = _start; partId < _start + _numToSearch; partId++) {
            if (partIndexToOwner[partId] == _owner) {
                result[resultIndex] = _partToBytes(parts[partId]);
                resultIndex++;
            }
        }
        return result; // will have 0 elements if tokenCount == 0
    }


    function _partToBytes(Part p) internal pure returns (bytes24 b) {
        b = bytes24(p.tokenId);

        b = b << 8;
        b = b | bytes24(p.partType);

        b = b << 8;
        b = b | bytes24(p.partSubType);

        b = b << 8;
        b = b | bytes24(p.rarity);

        b = b << 8;
        b = b | bytes24(p.element);

        b = b << 32;
        b = b | bytes24(p.battlesLastDay);

        b = b << 32;
        b = b | bytes24(p.experience);

        b = b << 32;
        b = b | bytes24(p.forgeTime);

        b = b << 32;
        b = b | bytes24(p.battlesLastReset);
    }

    uint32 constant FIRST_LEVEL = 1000;
    uint32 constant INCREMENT = 1000;

    // every level, you need 1000 more exp to go up a level
    function getLevel(uint32 _exp) public pure returns(uint32) {
        uint32 c = 0;
        for (uint32 i = FIRST_LEVEL; i <= FIRST_LEVEL + _exp; i += c * INCREMENT) {
            c++;
        }
        return c;
    }

    string metadataBase = "https://api.etherbots.io/api/";


    function setMetadataBase(string _base) external onlyOwner {
        metadataBase = _base;
    }

    // part type, subtype,
    // have one internal function which lets us implement the divergent interfaces
    function _metadata(uint256 _id) internal view returns(string) {
        Part memory p = parts[_id];
        return strConcat(strConcat(
            metadataBase,
            uintToString(uint(p.partType)),
            "/",
            uintToString(uint(p.partSubType)),
            "/"
        ), uintToString(uint(p.rarity)), "", "", "");
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    /// @notice A distinct URI (RFC 3986) for a given token.
    /// @dev If:
    ///  * The URI is a URL
    ///  * The URL is accessible
    ///  * The URL points to a valid JSON file format (ECMA-404 2nd ed.)
    ///  * The JSON base element is an object
    ///  then these names of the base element SHALL have special meaning:
    ///  * "name": A string identifying the item to which `_deedId` grants
    ///    ownership
    ///  * "description": A string detailing the item to which `_deedId` grants
    ///    ownership
    ///  * "image": A URI pointing to a file of image/* mime type representing
    ///    the item to which `_deedId` grants ownership
    ///  Wallets and exchanges MAY display this to the end user.
    ///  Consider making any images at a width between 320 and 1080 pixels and
    ///  aspect ratio between 1.91:1 and 4:5 inclusive.
    function deedUri(uint256 _deedId) external view returns (string _uri){
        return _metadata(_deedId);
    }

    /// returns a metadata URI
    function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl) {
        return _metadata(_tokenId);
    }

    function takeOwnership(uint256 _deedId) external payable {
        // payable for ERC721 --> don&#39;t actually send eth @<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b5eaf5">[email&#160;protected]</a>
        require(msg.value == 0);

        address _from = partIndexToOwner[_deedId];

        require(_approvedFor(msg.sender, _deedId));

        _transfer(_from, msg.sender, _deedId);
    }

    // parts are stored sequentially
    function deedByIndex(uint256 _index) external view returns (uint256 _deedId){
        return _index;
    }

    function countOfOwners() external view returns (uint256 _count){
        // TODO: implement this
        return 0;
    }

// thirsty function
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint _tokenId){
        return _tokenOfOwnerByIndex(_owner, _index);
    }

// code duplicated
    function _tokenOfOwnerByIndex(address _owner, uint _index) private view returns (uint _tokenId){
        // The index should be valid.
        require(_index < balanceOf(_owner));

        // can loop through all without
        uint256 seen = 0;
        uint256 totalTokens = totalSupply();

        for (uint i = 0; i < totalTokens; i++) {
            if (partIndexToOwner[i] == _owner) {
                if (seen == _index) {
                    return i;
                }
                seen++;
            }
        }
    }

    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId){
        return _tokenOfOwnerByIndex(_owner, _index);
    }
}





// Auction contract, facilitating statically priced sales, as well as 
// inflationary and deflationary pricing for items.
// Relies heavily on the ERC721 interface and so most of the methods
// are tightly bound to that implementation
contract NFTAuctionBase is Pausable {

    ERC721AllImplementations public nftContract;
    uint256 public ownerCut;
    uint public minDuration;
    uint public maxDuration;

    // Represents an auction on an NFT (in this case, Robot part)
    struct Auction {
        // address of part owner
        address seller;
        // wei price of listing
        uint256 startPrice;
        // wei price of floor
        uint256 endPrice;
        // duration of sale in seconds.
        uint64 duration;
        // Time when sale started
        // Reset to 0 after sale concluded
        uint64 start;
    }

    function NFTAuctionBase() public {
        minDuration = 60 minutes;
        maxDuration = 30 days; // arbitrary
    }

    // map of all tokens and their auctions
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startPrice, uint256 endPrice, uint64 duration, uint64 start);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // returns true if the token with id _partId is owned by the _claimant address
    function _owns(address _claimant, uint256 _partId) internal view returns (bool) {
        return nftContract.ownerOf(_partId) == _claimant;
    }

   // returns false if auction start time is 0, likely from uninitialised struct
    function _isActiveAuction(Auction _auction) internal pure returns (bool) {
        return _auction.start > 0;
    }
    
    // assigns ownership of the token with id = _partId to this contract
    // must have already been approved
    function _escrow(address, uint _partId) internal {
        // throws on transfer fail
        nftContract.takeOwnership(_partId);
    }

    // transfer the token with id = _partId to buying address
    function _transfer(address _purchasor, uint256 _partId) internal {
        // successful purchaseder must takeOwnership of _partId
        // nftContract.approve(_purchasor, _partId); 
               // actual transfer
                nftContract.transfer(_purchasor, _partId);

    }

    // creates
    function _newAuction(uint256 _partId, Auction _auction) internal {

        require(_auction.duration >= minDuration);
        require(_auction.duration <= maxDuration);

        tokenIdToAuction[_partId] = _auction;

        AuctionCreated(uint256(_partId),
            uint256(_auction.startPrice),
            uint256(_auction.endPrice),
            uint64(_auction.duration),
            uint64(_auction.start)
        );
    }

    function setMinDuration(uint _duration) external onlyOwner {
        minDuration = _duration;
    }

    function setMaxDuration(uint _duration) external onlyOwner {
        maxDuration = _duration;
    }

    /// Removes auction from public view, returns token to the seller
    function _cancelAuction(uint256 _partId, address _seller) internal {
        _removeAuction(_partId);
        _transfer(_seller, _partId);
        AuctionCancelled(_partId);
    }

    event PrintEvent(string, address, uint);

    // Calculates price and transfers purchase to owner. Part is NOT transferred to buyer.
    function _purchase(uint256 _partId, uint256 _purchaseAmount) internal returns (uint256) {

        Auction storage auction = tokenIdToAuction[_partId];

        // check that this token is being auctioned
        require(_isActiveAuction(auction));

        // enforce purchase >= the current price
        uint256 price = _currentPrice(auction);
        require(_purchaseAmount >= price);

        // Store seller before we delete auction.
        address seller = auction.seller;

        // Valid purchase. Remove auction to prevent reentrancy.
        _removeAuction(_partId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            
            // Calculate and take fee from purchase

            uint256 auctioneerCut = _computeFee(price);
            uint256 sellerProceeds = price - auctioneerCut;

            PrintEvent("Seller, proceeds", seller, sellerProceeds);

            // Pay the seller
            seller.transfer(sellerProceeds);
        }

        // Calculate excess funds and return to buyer.
        uint256 purchaseExcess = _purchaseAmount - price;

        PrintEvent("Sender, excess", msg.sender, purchaseExcess);
        // Return any excess funds. Reentrancy again prevented by deleting auction.
        msg.sender.transfer(purchaseExcess);

        AuctionSuccessful(_partId, price, msg.sender);

        return price;
    }

    // returns the current price of the token being auctioned in _auction
    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        uint256 secsElapsed = now - _auction.start;
        return _computeCurrentPrice(
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            secsElapsed
        );
    }

    // Checks if NFTPart is currently being auctioned.
    // function _isBeingAuctioned(Auction storage _auction) internal view returns (bool) {
    //     return (_auction.start > 0);
    // }

    // removes the auction of the part with id _partId
    function _removeAuction(uint256 _partId) internal {
        delete tokenIdToAuction[_partId];
    }

    // computes the current price of an deflating-price auction 
    function _computeCurrentPrice( uint256 _startPrice, uint256 _endPrice, uint256 _duration, uint256 _secondsPassed ) internal pure returns (uint256 _price) {
        _price = _startPrice;
        if (_secondsPassed >= _duration) {
            // Has been up long enough to hit endPrice.
            // Return this price floor.
            _price = _endPrice;
            // this is a statically price sale. Just return the price.
        }
        else if (_duration > 0) {
            // This auction contract supports auctioning from any valid price to any other valid price.
            // This means the price can dynamically increase upward, or downard.
            int256 priceDifference = int256(_endPrice) - int256(_startPrice);
            int256 currentPriceDifference = priceDifference * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startPrice) + currentPriceDifference;

            _price = uint256(currentPrice);
        }
        return _price;
    }

    // Compute percentage fee of transaction

    function _computeFee (uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000; 
    }

}

// Clock auction for NFTParts.
// Only timed when pricing is dynamic (i.e. startPrice != endPrice).
// Else, this becomes an infinite duration statically priced sale,
// resolving when succesfully purchase for or cancelled.

contract DutchAuction is NFTAuctionBase, EtherbotsPrivileges {

    // The ERC-165 interface signature for ERC-721.
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0xda671b9b);
 
    function DutchAuction(address _nftAddress, uint256 _fee) public {
        require(_fee <= 10000);
        ownerCut = _fee;

        ERC721AllImplementations candidateContract = ERC721AllImplementations(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nftContract = candidateContract;
    }

    // Remove all ether from the contract. This will be marketplace fees.
    // Transfers to the NFT contract. 
    // Can be called by owner or NFT contract.

    function withdrawBalance() external {
        address nftAddress = address(nftContract);

        require(msg.sender == owner || msg.sender == nftAddress);

        nftAddress.transfer(this.balance);
    }

    event PrintEvent(string, address, uint);

    // Creates an auction and lists it.
    function createAuction( uint256 _partId, uint256 _startPrice, uint256 _endPrice, uint256 _duration, address _seller ) external whenNotPaused {
        // Sanity check that no inputs overflow how many bits we&#39;ve allocated
        // to store them in the auction struct.
        require(_startPrice == uint256(uint128(_startPrice)));
        require(_endPrice == uint256(uint128(_endPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(_startPrice >= _endPrice);

        require(msg.sender == address(nftContract));
        _escrow(_seller, _partId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startPrice),
            uint128(_endPrice),
            uint64(_duration),
            uint64(now) //seconds uint 
        );
        PrintEvent("Auction Start", 0x0, auction.start);
        _newAuction(_partId, auction);
    }


    // SCRAPYARD PRICING LOGIC

    uint8 constant LAST_CONSIDERED = 5;
    uint8 public scrapCounter = 0;
    uint[5] public lastScrapPrices;
    
    // Purchases an open auction
    // Will transfer ownership if successful.
    
    function purchase(uint256 _partId) external payable whenNotPaused {
        address seller = tokenIdToAuction[_partId].seller;

        // _purchase will throw if the purchase or funds transfer fails
        uint256 price = _purchase(_partId, msg.value);
        _transfer(msg.sender, _partId);
        
        // If the seller is the scrapyard, track price information.
        if (seller == address(nftContract)) {

            lastScrapPrices[scrapCounter] = price;
            if (scrapCounter == LAST_CONSIDERED - 1) {
                scrapCounter = 0;
            } else {
                scrapCounter++;
            }
        }
    }

    function averageScrapPrice() public view returns (uint) {
        uint sum = 0;
        for (uint8 i = 0; i < LAST_CONSIDERED; i++) {
            sum += lastScrapPrices[i];
        }
        return sum / LAST_CONSIDERED;
    }

    // Allows a user to cancel an auction before it&#39;s resolved.
    // Returns the part to the seller.

    function cancelAuction(uint256 _partId) external {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_partId, seller);
    }

    // returns the current price of the auction of a token with id _partId
    function getCurrentPrice(uint256 _partId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        return _currentPrice(auction);
    }

    //  Returns the details of an auction from its _partId.
    function getAuction(uint256 _partId) external view returns ( address seller, uint256 startPrice, uint256 endPrice, uint256 duration, uint256 startedAt ) {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        return ( auction.seller, auction.startPrice, auction.endPrice, auction.duration, auction.start);
    }

    // Allows owner to cancel an auction.
    // ONLY able to be used when contract is paused,
    // in the case of emergencies.
    // Parts returned to seller as it&#39;s equivalent to them 
    // calling cancel.
    function cancelAuctionWhenPaused(uint256 _partId) whenPaused onlyOwner external {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        _cancelAuction(_partId, auction.seller);
    }
}