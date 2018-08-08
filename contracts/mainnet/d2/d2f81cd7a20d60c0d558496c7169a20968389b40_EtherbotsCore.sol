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
        // payable for ERC721 --> don&#39;t actually send eth @<span class="__cf_email__" data-cfemail="663926">[email&#160;protected]</span>
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
        // payable for ERC721 --> don&#39;t actually send eth @<span class="__cf_email__" data-cfemail="d58a95">[email&#160;protected]</span>
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
        // payable for ERC721 --> don&#39;t actually send eth @<span class="__cf_email__" data-cfemail="b0eff0">[email&#160;protected]</span>
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

// the contract which all battles must implement
// allows for different types of battles to take place
contract PerkTree is EtherbotsNFT {
    // The perktree is represented in a uint8[32] representing a binary tree
    // see the number of perks active
    // buy a new perk
    // 0: Prestige level -> starts at 0;
    // next row of tree
    // 1: offensive moves 2: defensive moves
    // next row of tree
    // 3: melee attack 4: turret shooting 5: defend arm 6: body dodge
    // next row of tree
    // 7: mech melee 8: android melee 9: mech turret 10: android turret
    // 11: mech defence 12: android defence 13: mech body 14: android body
    //next row of tree
    // 15: melee electric 16: melee steel 17: melee fire 18: melee water
    // 19: turret electric 20: turret steel 21: turret fire 22: turret water
    // 23: defend electric 24: defend steel 25: defend fire 26: defend water
    // 27: body electric 28: body steel 29: body fire 30: body water
    function _leftChild(uint8 _i) internal pure returns (uint8) {
        return 2*_i + 1;
    }
    function _rightChild(uint8 _i) internal pure returns (uint8) {
        return 2*_i + 2;
    }
    function _parent(uint8 _i) internal pure returns (uint8) {
        return (_i-1)/2;
    }


    uint8 constant PRESTIGE_INDEX = 0;
    uint8 constant PERK_COUNT = 30;

    event PrintPerk(string,uint8,uint8[32]);

    function _isValidPerkToAdd(uint8[32] _perks, uint8 _index) internal pure returns (bool) {
        // a previously unlocked perk is not a valid perk to add.
        if ((_index==PRESTIGE_INDEX) || (_perks[_index] > 0)) {
            return false;
        }
        // perk not valid if any ancestor not unlocked
        for (uint8 i = _parent(_index); i > PRESTIGE_INDEX; i = _parent(i)) {
            if (_perks[i] == 0) {
                return false;
            }
        }
        return true;
    }

    // sum of perks (excluding prestige)
    function _sumActivePerks(uint8[32] _perks) internal pure returns (uint256) {
        uint32 sum = 0;
        //sum from after prestige_index, to count+1 (for prestige index).
        for (uint8 i = PRESTIGE_INDEX+1; i < PERK_COUNT+1; i++) {
            sum += _perks[i];
        }
        return sum;
    }

    // you can unlock a new perk every two levels (including prestige when possible)
    function choosePerk(uint8 _i) external {
        require((_i >= PRESTIGE_INDEX) && (_i < PERK_COUNT+1));
        User storage currentUser = addressToUser[msg.sender];
        uint256 _numActivePerks = _sumActivePerks(currentUser.perks);
        bool canPrestige = (_numActivePerks == PERK_COUNT);

        //add prestige value to sum of perks
        _numActivePerks += currentUser.perks[PRESTIGE_INDEX] * PERK_COUNT;
        require(_numActivePerks < getLevel(currentUser.experience) / 2);

        if (_i == PRESTIGE_INDEX) {
            require(canPrestige);
            _prestige();
        } else {
            require(_isValidPerkToAdd(currentUser.perks, _i));
            _addPerk(_i);
        }
        PerkChosen(msg.sender, _i);
    }

    function _addPerk(uint8 perk) internal {
        addressToUser[msg.sender].perks[perk]++;
    }

    function _prestige() internal {
        User storage currentUser = addressToUser[msg.sender];
        for (uint8 i = 1; i < currentUser.perks.length; i++) {
            currentUser.perks[i] = 0;
        }
        currentUser.perks[PRESTIGE_INDEX]++;
    }

    event PerkChosen(address indexed upgradedUser, uint8 indexed perk);

}

// Central collection of storage on which all other contracts depend.
// Contains structs for parts, users and functions which control their
// transferrence.


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

contract EtherbotsAuction is PerkTree {

    // Sets the reference to the sale auction.

    function setAuctionAddress(address _address) external onlyOwner {
        require(_address != address(0));
        DutchAuction candidateContract = DutchAuction(_address);

        // Set the new contract address
        auction = candidateContract;
    }

    // list a part for auction.

    function createAuction(
        uint256 _partId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _duration ) external whenNotPaused 
    {


        // user must have current control of the part
        // will lose control if they delegate to the auction
        // therefore no duplicate auctions!
        require(owns(msg.sender, _partId));

        _approve(_partId, auction);

        // will throw if inputs are invalid
        // will clear transfer approval
        DutchAuction(auction).createAuction(_partId,_startPrice,_endPrice,_duration,msg.sender);
    }

    // transfer balance back to core contract
    function withdrawAuctionBalance() external onlyOwner {
        DutchAuction(auction).withdrawBalance();
    }

    // SCRAP FUNCTION
  
    // This takes scrapped parts and automatically relists them on the market.
    // Provides a good floor for entrance into the game, while keeping supply
    // constant as these parts were already in circulation.

    // uint public constant SCRAPYARD_STARTING_PRICE = 0.1 ether;
    uint scrapMinStartPrice = 0.05 ether; // settable minimum starting price for sanity
    uint scrapMinEndPrice = 0.005 ether;  // settable minimum ending price for sanity
    uint scrapAuctionDuration = 2 days;
    
    function setScrapMinStartPrice(uint _newMinStartPrice) external onlyOwner {
        scrapMinStartPrice = _newMinStartPrice;
    }
    function setScrapMinEndPrice(uint _newMinEndPrice) external onlyOwner {
        scrapMinEndPrice = _newMinEndPrice;
    }
    function setScrapAuctionDuration(uint _newScrapAuctionDuration) external onlyOwner {
        scrapAuctionDuration = _newScrapAuctionDuration;
    }
 
    function _createScrapPartAuction(uint _scrapPartId) internal {
        // if (scrapyard == address(this)) {
        _approve(_scrapPartId, auction);
        
        DutchAuction(auction).createAuction(
            _scrapPartId,
            _getNextAuctionPrice(), // gen next auction price
            scrapMinEndPrice,
            scrapAuctionDuration,
            address(this)
        );
        // }
    }

    function _getNextAuctionPrice() internal view returns (uint) {
        uint avg = DutchAuction(auction).averageScrapPrice();
        // add 30% to the average
        // prevent runaway pricing
        uint next = avg + ((30 * avg) / 100);
        if (next < scrapMinStartPrice) {
            next = scrapMinStartPrice;
        }
        return next;
    }

}

contract PerksRewards is EtherbotsAuction {
    ///  An internal method that creates a new part and stores it. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Forge event
    ///  and a Transfer event.
   function _createPart(uint8[4] _partArray, address _owner) internal returns (uint) {
        uint32 newPartId = uint32(parts.length);
        assert(newPartId == parts.length);

        Part memory _part = Part({
            tokenId: newPartId,
            partType: _partArray[0],
            partSubType: _partArray[1],
            rarity: _partArray[2],
            element: _partArray[3],
            battlesLastDay: 0,
            experience: 0,
            forgeTime: uint32(now),
            battlesLastReset: uint32(now)
        });
        assert(newPartId == parts.push(_part) - 1);

        // emit the FORGING!!!
        Forge(_owner, newPartId, _part);

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newPartId);

        return newPartId;
    }

    uint public PART_REWARD_CHANCE = 995;
    // Deprecated subtypes contain the subtype IDs of legacy items
    // which are no longer available to be redeemed in game.
    // i.e. subtype ID 14 represents lambo body, presale exclusive.
    // a value of 0 represents that subtype (id within range)
    // as being deprecated for that part type (body, turret, etc)
    uint8[] public defenceElementBySubtypeIndex;
    uint8[] public meleeElementBySubtypeIndex;
    uint8[] public bodyElementBySubtypeIndex;
    uint8[] public turretElementBySubtypeIndex;
    // uint8[] public defenceElementBySubtypeIndex = [1,2,4,3,4,1,3,3,2,1,4];
    // uint8[] public meleeElementBySubtypeIndex = [3,1,3,2,3,4,2,2,1,1,1,1,4,4];
    // uint8[] public bodyElementBySubtypeIndex = [2,1,2,3,4,3,1,1,4,2,3,4,1,0,1]; // no more lambos :&#39;(
    // uint8[] public turretElementBySubtypeIndex = [4,3,2,1,2,1,1,3,4,3,4];

    function setRewardChance(uint _newChance) external onlyOwner {
        require(_newChance > 980); // not too hot
        require(_newChance <= 1000); // not too cold
        PART_REWARD_CHANCE = _newChance; // just right
        // come at me goldilocks
    }
    // The following functions DON&#39;T create parts, they add new parts
    // as possible rewards from the reward pool.


    function addDefenceParts(uint8[] _newElement) external onlyOwner {
        for (uint8 i = 0; i < _newElement.length; i++) {
            defenceElementBySubtypeIndex.push(_newElement[i]);
        }
        // require(defenceElementBySubtypeIndex.length < uint(uint8(-1)));
    }
    function addMeleeParts(uint8[] _newElement) external onlyOwner {
        for (uint8 i = 0; i < _newElement.length; i++) {
            meleeElementBySubtypeIndex.push(_newElement[i]);
        }
        // require(meleeElementBySubtypeIndex.length < uint(uint8(-1)));
    }
    function addBodyParts(uint8[] _newElement) external onlyOwner {
        for (uint8 i = 0; i < _newElement.length; i++) {
            bodyElementBySubtypeIndex.push(_newElement[i]);
        }
        // require(bodyElementBySubtypeIndex.length < uint(uint8(-1)));
    }
    function addTurretParts(uint8[] _newElement) external onlyOwner {
        for (uint8 i = 0; i < _newElement.length; i++) {
            turretElementBySubtypeIndex.push(_newElement[i]);
        }
        // require(turretElementBySubtypeIndex.length < uint(uint8(-1)));
    }
    // Deprecate subtypes. Once a subtype has been deprecated it can never be
    // undeprecated. Starting with lambo!
    function deprecateDefenceSubtype(uint8 _subtypeIndexToDeprecate) external onlyOwner {
        defenceElementBySubtypeIndex[_subtypeIndexToDeprecate] = 0;
    }

    function deprecateMeleeSubtype(uint8 _subtypeIndexToDeprecate) external onlyOwner {
        meleeElementBySubtypeIndex[_subtypeIndexToDeprecate] = 0;
    }

    function deprecateBodySubtype(uint8 _subtypeIndexToDeprecate) external onlyOwner {
        bodyElementBySubtypeIndex[_subtypeIndexToDeprecate] = 0;
    }

    function deprecateTurretSubtype(uint8 _subtypeIndexToDeprecate) external onlyOwner {
        turretElementBySubtypeIndex[_subtypeIndexToDeprecate] = 0;
    }

    // function _randomIndex(uint _rand, uint8 _startIx, uint8 _endIx, uint8 _modulo) internal pure returns (uint8) {
    //     require(_startIx < _endIx);
    //     bytes32 randBytes = bytes32(_rand);
    //     uint result = 0;
    //     for (uint8 i=_startIx; i<_endIx; i++) {
    //         result = result | uint8(randBytes[i]);
    //         result << 8;
    //     }
    //     uint8 resultInt = uint8(uint(result) % _modulo);
    //     return resultInt;
    // }


    // This function takes a random uint, an owner and randomly generates a valid part.
    // It then transfers that part to the owner.
    function _generateRandomPart(uint _rand, address _owner) internal {
        // random uint 20 in length - MAYBE 20.
        // first randomly gen a part type
        _rand = uint(keccak256(_rand));
        uint8[4] memory randomPart;
        randomPart[0] = uint8(_rand % 4) + 1;
        _rand = uint(keccak256(_rand));

        // randomPart[0] = _randomIndex(_rand,0,4,4) + 1; // 1, 2, 3, 4, => defence, melee, body, turret

        if (randomPart[0] == DEFENCE) {
            randomPart[1] = _getRandomPartSubtype(_rand,defenceElementBySubtypeIndex);
            randomPart[3] = _getElement(defenceElementBySubtypeIndex, randomPart[1]);

        } else if (randomPart[0] == MELEE) {
            randomPart[1] = _getRandomPartSubtype(_rand,meleeElementBySubtypeIndex);
            randomPart[3] = _getElement(meleeElementBySubtypeIndex, randomPart[1]);

        } else if (randomPart[0] == BODY) {
            randomPart[1] = _getRandomPartSubtype(_rand,bodyElementBySubtypeIndex);
            randomPart[3] = _getElement(bodyElementBySubtypeIndex, randomPart[1]);

        } else if (randomPart[0] == TURRET) {
            randomPart[1] = _getRandomPartSubtype(_rand,turretElementBySubtypeIndex);
            randomPart[3] = _getElement(turretElementBySubtypeIndex, randomPart[1]);

        }
        _rand = uint(keccak256(_rand));
        randomPart[2] = _getRarity(_rand);
        // randomPart[2] = _getRarity(_randomIndex(_rand,8,12,3)); // rarity
        _createPart(randomPart, _owner);
    }

    function _getRandomPartSubtype(uint _rand, uint8[] elementBySubtypeIndex) internal pure returns (uint8) {
        require(elementBySubtypeIndex.length < uint(uint8(-1)));
        uint8 subtypeLength = uint8(elementBySubtypeIndex.length);
        require(subtypeLength > 0);
        uint8 subtypeIndex = uint8(_rand % subtypeLength);
        // uint8 subtypeIndex = _randomIndex(_rand,4,8,subtypeLength);
        uint8 count = 0;
        while (elementBySubtypeIndex[subtypeIndex] == 0) {
            subtypeIndex++;
            count++;
            if (subtypeIndex == subtypeLength) {
                subtypeIndex = 0;
            }
            if (count > subtypeLength) {
                break;
            }
        }
        require(elementBySubtypeIndex[subtypeIndex] != 0);
        return subtypeIndex + 1;
    }


    function _getRarity(uint rand) pure internal returns (uint8) {
        uint16 rarity = uint16(rand % 1000);
        if (rarity >= 990) {  // 1% chance of gold
          return GOLD;
        } else if (rarity >= 970) { // 2% chance of shadow
          return SHADOW;
        } else {
          return STANDARD;
        }
    }

    function _getElement(uint8[] elementBySubtypeIndex, uint8 subtype) internal pure returns (uint8) {
        uint8 subtypeIndex = subtype - 1;
        return elementBySubtypeIndex[subtypeIndex];
    }

    mapping(address => uint[]) pendingPartCrates ;

    function getPendingPartCrateLength() external view returns (uint) {
        return pendingPartCrates[msg.sender].length;
    }

    /// Put shards together into a new part-crate
    function redeemShardsIntoPending() external {
        User storage user = addressToUser[msg.sender];
         while (user.numShards >= SHARDS_TO_PART) {
             user.numShards -= SHARDS_TO_PART;
             pendingPartCrates[msg.sender].push(block.number);
             // 256 blocks to redeem
         }
    }

    function openPendingPartCrates() external {
        uint[] memory crates = pendingPartCrates[msg.sender];
        for (uint i = 0; i < crates.length; i++) {
            uint pendingBlockNumber = crates[i];
            // can&#39;t open on the same timestamp
            require(block.number > pendingBlockNumber);

            var hash = block.blockhash(pendingBlockNumber);

            if (uint(hash) != 0) {
                // different results for all different crates, even on the same block/same user
                // randomness is already taken care of
                uint rand = uint(keccak256(hash, msg.sender, i)); // % (10 ** 20);
                _generateRandomPart(rand, msg.sender);
            } else {
                // Do nothing, no second chances to secure integrity of randomness.
            }
        }
        delete pendingPartCrates[msg.sender];
    }

    uint32 constant SHARDS_MAX = 10000;

    function _addShardsToUser(User storage _user, uint32 _shards) internal {
        uint32 updatedShards = _user.numShards + _shards;
        if (updatedShards > SHARDS_MAX) {
            updatedShards = SHARDS_MAX;
        }
        _user.numShards = updatedShards;
        ShardsAdded(msg.sender, _shards);
    }

    // FORGING / SCRAPPING
    event ShardsAdded(address caller, uint32 shards);
    event Scrap(address user, uint partId);

    uint32 constant SHARDS_TO_PART = 500;
    uint8 public scrapPercent = 60;
    uint8 public burnRate = 60; 

    function setScrapPercent(uint8 _newPercent) external onlyOwner {
        require((_newPercent >= 50) && (_newPercent <= 90));
        scrapPercent = _newPercent;
    }

    // function setScrapyard(address _scrapyard) external onlyOwner {
    //     scrapyard = _scrapyard;
    // }

    function setBurnRate(uint8 _rate) external onlyOwner {
        burnRate = _rate;
    }


    uint public scrapCount = 0;

    // scraps a part for shards
    function scrap(uint partId) external {
        require(owns(msg.sender, partId));
        User storage u = addressToUser[msg.sender];
        _addShardsToUser(u, (SHARDS_TO_PART * scrapPercent) / 100);
        Scrap(msg.sender, partId);
        // this doesn&#39;t need to be secure
        // no way to manipulate it apart from guaranteeing your parts are resold
        // or burnt
        if (uint(keccak256(scrapCount)) % 100 >= burnRate) {
            _transfer(msg.sender, address(this), partId);
            _createScrapPartAuction(partId);
        } else {
            _transfer(msg.sender, address(0), partId);
        }
        scrapCount++;
    }

}

contract Mint is PerksRewards {
    
    // Owner only function to give an address new parts.
    // Strictly capped at 5000.
    // This will ONLY be used for promotional purposes (i.e. providing items for Wax/OPSkins partnership)
    // which we don&#39;t benefit financially from, or giving users who win the prize of designing a part 
    // for the game, a single copy of that part.
    
    uint16 constant MINT_LIMIT = 5000;
    uint16 public partsMinted = 0;

    function mintParts(uint16 _count, address _owner) public onlyOwner {
        require(_count > 0 && _count <= 50);
        // check overflow
        require(partsMinted + _count > partsMinted);
        require(partsMinted + _count < MINT_LIMIT);
        
        addressToUser[_owner].numShards += SHARDS_TO_PART * _count;
        
        partsMinted += _count;
    }       

    function mintParticularPart(uint8[4] _partArray, address _owner) public onlyOwner {
        require(partsMinted < MINT_LIMIT);
        /* cannot create deprecated parts
        for (uint i = 0; i < deprecated.length; i++) {
            if (_partArray[2] == deprecated[i]) {
                revert();
            }
        } */
        _createPart(_partArray, _owner);
        partsMinted++;
    }

}




contract NewCratePreSale {
    
    // migration functions migrate the data from the previous contract in stages
    // all addresses are included for transparency and easy verification
    // however addresses with no robots (i.e. failed transaction and never bought properly) have been commented out.
    // to view the full list of state assignments, go to etherscan.io/address/{address} and you can view the verified
    mapping (address => uint[]) public userToRobots; 

    function _migrate(uint _index) external onlyOwner {
        bytes4 selector = bytes4(keccak256("setData()"));
        address a = migrators[_index];
        require(a.delegatecall(selector));
    }
    // source code - feel free to verify the migration
    address[6] migrators = [
        0x700FeBD9360ac0A0a72F371615427Bec4E4454E5, //0x97AE01893E42d6d33fd9851A28E5627222Af7BBB,
        0x72Cc898de0A4EAC49c46ccb990379099461342f6,
        0xc3cC48da3B8168154e0f14Bf0446C7a93613F0A7,
        0x4cC96f2Ddf6844323ae0d8461d418a4D473b9AC3,
        0xa52bFcb5FF599e29EE2B9130F1575BaBaa27de0A,
        0xe503b42AabdA22974e2A8B75Fa87E010e1B13584
    ];
    
    function NewCratePreSale() public payable {
        
            owner = msg.sender;
        // one time transfer of state from the previous contract
        // var previous = CratePreSale(0x3c7767011C443EfeF2187cf1F2a4c02062da3998); //MAINNET

        // oldAppreciationRateWei = previous.appreciationRateWei();
        oldAppreciationRateWei = 100000000000000;
        appreciationRateWei = oldAppreciationRateWei;
  
        // oldPrice = previous.currentPrice();
        oldPrice = 232600000000000000;
        currentPrice = oldPrice;

        // oldCratesSold = previous.cratesSold();
        oldCratesSold = 1075;
        cratesSold = oldCratesSold;

        // Migration Rationale
        // due to solidity issues with enumerability (contract calls cannot return dynamic arrays etc)
        // no need for trust -> can still use web3 to call the previous contract and check the state
        // will only change in the future if people send more eth
        // and will be obvious due to change in crate count. Any purchases on the old contract
        // after this contract is deployed will be fully refunded, and those robots bought will be voided. 
        // feel free to validate any address on the old etherscan:
        // https://etherscan.io/address/0x3c7767011C443EfeF2187cf1F2a4c02062da3998
        // can visit the exact contracts at the addresses listed above
    }

    // ------ STATE ------
    uint256 constant public MAX_CRATES_TO_SELL = 3900; // Max no. of robot crates to ever be sold
    uint256 constant public PRESALE_END_TIMESTAMP = 1518699600; // End date for the presale - no purchases can be made after this date - Midnight 16 Feb 2018 UTC

    uint256 public appreciationRateWei;
    uint32 public cratesSold;
    uint256 public currentPrice;

    // preserve these for later verification
    uint32 public oldCratesSold;
    uint256 public oldPrice;
    uint256 public oldAppreciationRateWei;
    // mapping (address => uint32) public userCrateCount; // replaced with more efficient method
    

    // store the unopened crates of this user
    // actually stores the blocknumber of each crate 
    mapping (address => uint[]) public addressToPurchasedBlocks;
    // store the number of expired crates for each user 
    // i.e. crates where the user failed to open the crate within 256 blocks (~1 hour)
    // these crates will be able to be opened post-launch
    mapping (address => uint) public expiredCrates;
    // store the part information of purchased crates



    function openAll() public {
        uint len = addressToPurchasedBlocks[msg.sender].length;
        require(len > 0);
        uint8 count = 0;
        // len > i to stop predicatable wraparound
        for (uint i = len - 1; i >= 0 && len > i; i--) {
            uint crateBlock = addressToPurchasedBlocks[msg.sender][i];
            require(block.number > crateBlock);
            // can&#39;t open on the same timestamp
            var hash = block.blockhash(crateBlock);
            if (uint(hash) != 0) {
                // different results for all different crates, even on the same block/same user
                // randomness is already taken care of
                uint rand = uint(keccak256(hash, msg.sender, i)) % (10 ** 20);
                userToRobots[msg.sender].push(rand);
                count++;
            } else {
                // all others will be expired
                expiredCrates[msg.sender] += (i + 1);
                break;
            }
        }
        CratesOpened(msg.sender, count);
        delete addressToPurchasedBlocks[msg.sender];
    }

    // ------ EVENTS ------
    event CratesPurchased(address indexed _from, uint8 _quantity);
    event CratesOpened(address indexed _from, uint8 _quantity);

    // ------ FUNCTIONS ------
    function getPrice() view public returns (uint256) {
        return currentPrice;
    }

    function getRobotCountForUser(address _user) external view returns(uint256) {
        return userToRobots[_user].length;
    }

    function getRobotForUserByIndex(address _user, uint _index) external view returns(uint) {
        return userToRobots[_user][_index];
    }

    function getRobotsForUser(address _user) view public returns (uint[]) {
        return userToRobots[_user];
    }

    function getPendingCratesForUser(address _user) external view returns(uint[]) {
        return addressToPurchasedBlocks[_user];
    }

    function getPendingCrateForUserByIndex(address _user, uint _index) external view returns(uint) {
        return addressToPurchasedBlocks[_user][_index];
    }

    function getExpiredCratesForUser(address _user) external view returns(uint) {
        return expiredCrates[_user];
    }

    function incrementPrice() private {
        // Decrease the rate of increase of the crate price
        // as the crates become more expensive
        // to avoid runaway pricing
        // (halving rate of increase at 0.1 ETH, 0.2 ETH, 0.3 ETH).
        if ( currentPrice == 100000000000000000 ) {
            appreciationRateWei = 200000000000000;
        } else if ( currentPrice == 200000000000000000) {
            appreciationRateWei = 100000000000000;
        } else if (currentPrice == 300000000000000000) {
            appreciationRateWei = 50000000000000;
        }
        currentPrice += appreciationRateWei;
    }

    function purchaseCrates(uint8 _cratesToBuy) public payable whenNotPaused {
        require(now < PRESALE_END_TIMESTAMP); // Check presale is still ongoing.
        require(_cratesToBuy <= 10); // Can only buy max 10 crates at a time. Don&#39;t be greedy!
        require(_cratesToBuy >= 1); // Sanity check. Also, you have to buy a crate. 
        require(cratesSold + _cratesToBuy <= MAX_CRATES_TO_SELL); // Check max crates sold is less than hard limit
        uint256 priceToPay = _calculatePayment(_cratesToBuy);
         require(msg.value >= priceToPay); // Check buyer sent sufficient funds to purchase
        if (msg.value > priceToPay) { //overpaid, return excess
            msg.sender.transfer(msg.value-priceToPay);
        }
        //all good, payment received. increment number sold, price, and generate crate receipts!
        cratesSold += _cratesToBuy;
      for (uint8 i = 0; i < _cratesToBuy; i++) {
            incrementPrice();
            addressToPurchasedBlocks[msg.sender].push(block.number);
        }

        CratesPurchased(msg.sender, _cratesToBuy);
    } 

    function _calculatePayment (uint8 _cratesToBuy) private view returns (uint256) {
        
        uint256 tempPrice = currentPrice;

        for (uint8 i = 1; i < _cratesToBuy; i++) {
            tempPrice += (currentPrice + (appreciationRateWei * i));
        } // for every crate over 1 bought, add current Price and a multiple of the appreciation rate
          // very small edge case of buying 10 when you the appreciation rate is about to halve
          // is compensated by the great reduction in gas by buying N at a time.
        
        return tempPrice;
    }


    //owner only withdrawal function for the presale
    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }

    function addFunds() onlyOwner external payable {

    }

  event SetPaused(bool paused);

  // starts unpaused
  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    SetPaused(paused);
    return true;
  }

  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    SetPaused(paused);
    return true;
  }


  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
    
}
contract EtherbotsMigrations is Mint {

    event CratesOpened(address indexed _from, uint8 _quantity);
    event OpenedOldCrates(address indexed _from);
    event MigratedCrates(address indexed _from, uint16 _quantity, bool isMigrationComplete);

    address presale = 0xc23F76aEa00B775AADC8504CcB22468F4fD2261A;
    mapping(address => bool) public hasMigrated;
    mapping(address => bool) public hasOpenedOldCrates;
    mapping(address => uint[]) pendingCrates;
    mapping(address => uint16) public cratesMigrated;

  
    // Element: copy for MIGRATIONS ONLY.
    string constant private DEFENCE_ELEMENT_BY_ID = "12434133214";
    string constant private MELEE_ELEMENT_BY_ID = "31323422111144";
    string constant private BODY_ELEMENT_BY_ID = "212343114234111";
    string constant private TURRET_ELEMENT_BY_ID = "43212113434";

    // Once only function.
    // Transfers all pending and expired crates in the old contract
    // into pending crates in the current one.
    // Users can then open them on the new contract.
    // Should only rarely have to be called.
    // event oldpending(uint old);

    function openOldCrates() external {
        require(hasOpenedOldCrates[msg.sender] == false);
        // uint oldPendingCrates = NewCratePreSale(presale).getPendingCrateForUserByIndex(msg.sender,0); // getting unrecognised opcode here --!
        // oldpending(oldPendingCrates);
        // require(oldPendingCrates == 0);
        _migrateExpiredCrates();
        hasOpenedOldCrates[msg.sender] = true;
        OpenedOldCrates(msg.sender);
    }

    function migrate() external whenNotPaused {
        
        // Can&#39;t migrate twice .
        require(hasMigrated[msg.sender] == false);
        
        // require(NewCratePreSale(presale).getPendingCrateForUserByIndex(msg.sender,0) == 0);
        // No pending crates in the new contract allowed. Make sure you open them first.
        require(pendingCrates[msg.sender].length == 0);
        
        // If the user has old expired crates, don&#39;t let them migrate until they&#39;ve
        // converted them to pending crates in the new contract.
        if (NewCratePreSale(presale).getExpiredCratesForUser(msg.sender) > 0) {
            require(hasOpenedOldCrates[msg.sender]); 
        }

        // have to make a ton of calls unfortunately 
        uint16 length = uint16(NewCratePreSale(presale).getRobotCountForUser(msg.sender));

        // gas limit will be exceeded with *whale* etherbot players!
        // let&#39;s migrate their robots in batches of ten.
        // they can afford it
        bool isMigrationComplete = false;
        var max = length - cratesMigrated[msg.sender];
        if (max > 9) {
            max = 9;
        } else { // final call - all robots will be migrated
            isMigrationComplete = true;
            hasMigrated[msg.sender] = true;
        }
        for (uint i = cratesMigrated[msg.sender]; i < cratesMigrated[msg.sender] + max; i++) {
            var robot = NewCratePreSale(presale).getRobotForUserByIndex(msg.sender, i);
            var robotString = uintToString(robot);
            // MigratedBot(robotString);

            _migrateRobot(robotString);
            
        }
        cratesMigrated[msg.sender] += max;
        MigratedCrates(msg.sender, cratesMigrated[msg.sender], isMigrationComplete);
    }

    function _migrateRobot(string robot) private {
        var (melee, defence, body, turret) = _convertBlueprint(robot);
        // blueprints event
        // blueprints(body, turret, melee, defence);
        _createPart(melee, msg.sender);
        _createPart(defence, msg.sender);
        _createPart(turret, msg.sender);
        _createPart(body, msg.sender);
    }

    function _getRarity(string original, uint8 low, uint8 high) pure private returns (uint8) {
        uint32 rarity = stringToUint32(substring(original,low,high));
        if (rarity >= 950) {
          return GOLD; 
        } else if (rarity >= 850) {
          return SHADOW;
        } else {
          return STANDARD; 
        }
    }
   
    function _getElement(string elementString, uint partId) pure private returns(uint8) {
        return stringToUint8(substring(elementString, partId-1,partId));
    }

    // Actually part type
    function _getPartId(string original, uint8 start, uint8 end, uint8 partCount) pure private returns(uint8) {
        return (stringToUint8(substring(original,start,end)) % partCount) + 1;
    }

    function userPendingCrateNumber(address _user) external view returns (uint) {
        return pendingCrates[_user].length;
    }    
    
    // convert old string representation of robot into 4 new ERC721 parts
  
    function _convertBlueprint(string original) pure private returns(uint8[4] body,uint8[4] melee, uint8[4] turret, uint8[4] defence ) {

        /* ------ CONVERSION TIME ------ */
        

        body[0] = BODY; 
        body[1] = _getPartId(original, 3, 5, 15);
        body[2] = _getRarity(original, 0, 3);
        body[3] = _getElement(BODY_ELEMENT_BY_ID, body[1]);
        
        turret[0] = TURRET;
        turret[1] = _getPartId(original, 8, 10, 11);
        turret[2] = _getRarity(original, 5, 8);
        turret[3] = _getElement(TURRET_ELEMENT_BY_ID, turret[1]);

        melee[0] = MELEE;
        melee[1] = _getPartId(original, 13, 15, 14);
        melee[2] = _getRarity(original, 10, 13);
        melee[3] = _getElement(MELEE_ELEMENT_BY_ID, melee[1]);

        defence[0] = DEFENCE;
        var len = bytes(original).length;
        // string of number does not have preceding 0&#39;s
        if (len == 20) {
            defence[1] = _getPartId(original, 18, 20, 11);
        } else if (len == 19) {
            defence[1] = _getPartId(original, 18, 19, 11);
        } else { //unlikely to have length less than 19
            defence[1] = uint8(1);
        }
        defence[2] = _getRarity(original, 15, 18);
        defence[3] = _getElement(DEFENCE_ELEMENT_BY_ID, defence[1]);

        // implicit return
    }

    // give one more chance
    function _migrateExpiredCrates() private {
        // get the number of expired crates
        uint expired = NewCratePreSale(presale).getExpiredCratesForUser(msg.sender);
        for (uint i = 0; i < expired; i++) {
            pendingCrates[msg.sender].push(block.number);
        }
    }
    // Users can open pending crates on the new contract.
    function openCrates() public whenNotPaused {
        uint[] memory pc = pendingCrates[msg.sender];
        require(pc.length > 0);
        uint8 count = 0;
        for (uint i = 0; i < pc.length; i++) {
            uint crateBlock = pc[i];
            require(block.number > crateBlock);
            // can&#39;t open on the same timestamp
            var hash = block.blockhash(crateBlock);
            if (uint(hash) != 0) {
                // different results for all different crates, even on the same block/same user
                // randomness is already taken care of
                uint rand = uint(keccak256(hash, msg.sender, i)) % (10 ** 20);
                _migrateRobot(uintToString(rand));
                count++;
            }
        }
        CratesOpened(msg.sender, count);
        delete pendingCrates[msg.sender];
    }

    
}

contract Battle {
    // This struct does not exist outside the context of a battle

    // the name of the battle type
    function name() external view returns (string);
    // the number of robots currently battling
    function playerCount() external view returns (uint count);
    // creates a new battle, with a submitted user string for initial input/
    function createBattle(address _creator, uint[] _partIds, bytes32 _commit, uint _revealLength) external payable returns (uint);
    // cancels the battle at battleID
    function cancelBattle(uint battleID) external;
    
    function winnerOf(uint battleId, uint index) external view returns (address);
    function loserOf(uint battleId, uint index) external view returns (address);

    event BattleCreated(uint indexed battleID, address indexed starter);
    event BattleStage(uint indexed battleID, uint8 moveNumber, uint8[2] attackerMovesDefenderMoves, uint16[2] attackerDamageDefenderDamage);
    event BattleEnded(uint indexed battleID, address indexed winner);
    event BattleConcluded(uint indexed battleID);
    event BattlePropertyChanged(string name, uint previous, uint value);
}
contract EtherbotsBattle is EtherbotsMigrations {

    // can never remove any of these contracts, can only add
    // once we publish a contract, you&#39;ll always be able to play by that ruleset
    // good for two player games which are non-susceptible to collusion
    // people can be trusted to choose the most beneficial outcome, which in this case
    // is the fairest form of gameplay.
    // fields which are vulnerable to collusion still have to be centrally controlled :(
    function addApprovedBattle(Battle _battle) external onlyOwner {
        approvedBattles.push(_battle);
    }

    function _isApprovedBattle() internal view returns (bool) {
        for (uint8 i = 0; i < approvedBattles.length; i++) {
            if (msg.sender == address(approvedBattles[i])) {
                return true;
            }
        }
        return false;
    }

    modifier onlyApprovedBattles(){
        require(_isApprovedBattle());
        _;
    }


    function createBattle(uint _battleId, uint[] partIds, bytes32 commit, uint revealLength) external payable {
        // sanity check to make sure _battleId is a valid battle
        require(_battleId < approvedBattles.length);
        //if parts are given, make sure they are owned
        if (partIds.length > 0) {
            require(ownsAll(msg.sender, partIds));
        }
        //battle can decide number of parts required for battle

        Battle battle = Battle(approvedBattles[_battleId]);
        // Transfer all to selected battle contract.
        for (uint i=0; i<partIds.length; i++) {
            _approve(partIds[i], address(battle));
        }
        uint newDuelId = battle.createBattle.value(msg.value)(msg.sender, partIds, commit, revealLength);
        NewDuel(_battleId, newDuelId);
    }

    event NewDuel(uint battleId, uint duelId);


    mapping(address => Reward[]) public pendingRewards;
    // actually probably just want a length getter here as default public mapping getters
    // are pretty expensive

    function getPendingBattleRewardsCount(address _user) external view returns (uint) {
        return pendingRewards[_user].length;
    } 

    struct Reward {
        uint blocknumber;
        int32 exp;
    }

    function addExperience(address _user, uint[] _partIds, int32[] _exps) external onlyApprovedBattles {
        address user = _user;
        require(_partIds.length == _exps.length);
        int32 sum = 0;
        for (uint i = 0; i < _exps.length; i++) {
            sum += _addPartExperience(_partIds[i], _exps[i]);
        }
        _addUserExperience(user, sum);
        _storeReward(user, sum);
    }

    // store sum.
    function _storeReward(address _user, int32 _battleExp) internal {
        pendingRewards[_user].push(Reward({
            blocknumber: 0,
            exp: _battleExp
        }));
    }

    /* function _getExpProportion(int _exp) returns(int) {
        // assume max/min of 1k, -1k
        return 1000 + _exp + 1; // makes it between (1, 2001)
    } */
    uint8 bestMultiple = 3;
    uint8 mediumMultiple = 2;
    uint8 worstMultiple = 1;
    uint8 minShards = 1;
    uint8 bestProbability = 97;
    uint8 mediumProbability = 85;
    function _getExpMultiple(int _exp) internal view returns (uint8, uint8) {
        if (_exp > 500) {
            return (bestMultiple,mediumMultiple);
        } else if (_exp > 0) {
            return (mediumMultiple,mediumMultiple);
        } else {
            return (worstMultiple,mediumMultiple);
        }
    }

    function setBest(uint8 _newBestMultiple) external onlyOwner {
        bestMultiple = _newBestMultiple;
    }
    function setMedium(uint8 _newMediumMultiple) external onlyOwner {
        mediumMultiple = _newMediumMultiple;
    }
    function setWorst(uint8 _newWorstMultiple) external onlyOwner {
        worstMultiple = _newWorstMultiple;
    }
    function setMinShards(uint8 _newMin) external onlyOwner {
        minShards = _newMin;
    }
    function setBestProbability(uint8 _newBestProb) external onlyOwner {
        bestProbability = _newBestProb;
    }
    function setMediumProbability(uint8 _newMinProb) external onlyOwner {
        mediumProbability = _newMinProb;
    }



    function _calculateShards(int _exp, uint rand) internal view returns (uint16) {
        var (a, b) = _getExpMultiple(_exp);
        uint16 shards;
        uint randPercent = rand % 100;
        if (randPercent > bestProbability) {
            shards = uint16(a * ((rand % 20) + 12) / b);
        } else if (randPercent > mediumProbability) {
            shards = uint16(a * ((rand % 10) + 6) / b);  
        } else {
            shards = uint16((a * (rand % 5)) / b);       
        }

        if (shards < minShards) {
            shards = minShards;
        }

        return shards;
    }

    // convert wins into pending battle crates
    // Not to pending old crates (migration), nor pending part crates (redeemShards)
    function convertReward() external {

        Reward[] storage rewards = pendingRewards[msg.sender];

        for (uint i = 0; i < rewards.length; i++) {
            if (rewards[i].blocknumber == 0) {
                rewards[i].blocknumber = block.number;
            }
        }

    }

    // in PerksRewards
    function redeemBattleCrates() external {
        uint8 count = 0;
        uint len = pendingRewards[msg.sender].length;
        require(len > 0);
        for (uint i = 0; i < len; i++) {
            Reward memory rewardStruct = pendingRewards[msg.sender][i];
            // can&#39;t open on the same timestamp
            require(block.number > rewardStruct.blocknumber);
            // ensure user has converted all pendingRewards
            require(rewardStruct.blocknumber != 0);

            var hash = block.blockhash(rewardStruct.blocknumber);

            if (uint(hash) != 0) {
                // different results for all different crates, even on the same block/same user
                // randomness is already taken care of
                uint rand = uint(keccak256(hash, msg.sender, i));
                _generateBattleReward(rand,rewardStruct.exp);
                count++;
            } else {
                // Do nothing, no second chances to secure integrity of randomness.
            }
        }
        CratesOpened(msg.sender, count);
        delete pendingRewards[msg.sender];
    }

    function _generateBattleReward(uint rand, int32 exp) internal {
        if (((rand % 1000) > PART_REWARD_CHANCE) && (exp > 0)) {
            _generateRandomPart(rand, msg.sender);
        } else {
            _addShardsToUser(addressToUser[msg.sender], _calculateShards(exp, rand));
        }
    }

    // don&#39;t need to do any scaling
    // should already have been done by previous stages
    function _addUserExperience(address user, int32 exp) internal {
        // never allow exp to drop below 0
        User memory u = addressToUser[user];
        if (exp < 0 && uint32(int32(u.experience) + exp) > u.experience) {
            u.experience = 0;
            return;
        } else if (exp > 0) {
            // check for overflow
            require(uint32(int32(u.experience) + exp) > u.experience);
        }
        addressToUser[user].experience = uint32(int32(u.experience) + exp);
        //_addUserReward(user, exp);
    }

    function setMinScaled(int8 _min) external onlyOwner {
        minScaled = _min;
    }

    int8 minScaled = 25;

    function _scaleExp(uint32 _battleCount, int32 _exp) internal view returns (int32) {
        if (_battleCount <= 10) {
            return _exp; // no drop off
        }
        int32 exp =  (_exp * 10)/int32(_battleCount);

        if (exp < minScaled) {
            return minScaled;
        }
        return exp;
    }

    function _addPartExperience(uint _id, int32 _baseExp) internal returns (int32) {
        // never allow exp to drop below 0
        Part storage p = parts[_id];
        if (now - p.battlesLastReset > 24 hours) {
            p.battlesLastReset = uint32(now);
            p.battlesLastDay = 0;
        }
        p.battlesLastDay++;
        int32 exp = _baseExp;
        if (exp > 0) {
            exp = _scaleExp(p.battlesLastDay, _baseExp);
        }

        if (exp < 0 && uint32(int32(p.experience) + exp) > p.experience) {
            // check for wrap-around
            p.experience = 0;
            return;
        } else if (exp > 0) {
            // check for overflow
            require(uint32(int32(p.experience) + exp) > p.experience);
        }

        parts[_id].experience = uint32(int32(parts[_id].experience) + exp);
        return exp;
    }

    function totalLevel(uint[] partIds) public view returns (uint32) {
        uint32 total = 0;
        for (uint i = 0; i < partIds.length; i++) {
            total += getLevel(parts[partIds[i]].experience);
        }
        return total;
    }

    //requires parts in order
    function hasOrderedRobotParts(uint[] partIds) external view returns(bool) {
        uint len = partIds.length;
        if (len != 4) {
            return false;
        }
        for (uint i = 0; i < len; i++) {
            if (parts[partIds[i]].partType != i+1) {
                return false;
            }
        }
        return true;
    }

}

contract EtherbotsCore is EtherbotsBattle {

    // The structure of Etherbots is modelled on CryptoKitties for obvious reasons:
    // ease of implementation, tried + tested etc.
    // it elides some features and includes some others.

    // The full system is implemented in the following manner:
    //
    // EtherbotsBase    | Storage and base types
    // EtherbotsAccess  | Access Control - who can change which state vars etc.
    // EtherbotsNFT     | ERC721 Implementation
    // EtherbotsBattle  | Battle interface contract: only one implementation currently, but could add more later.
    // EtherbotsAuction | Auction interface contract


    function EtherbotsCore() public {
        // Starts paused.
        paused = true;
        owner = msg.sender;
    }
    
    
    function() external payable {
    }

    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }
}