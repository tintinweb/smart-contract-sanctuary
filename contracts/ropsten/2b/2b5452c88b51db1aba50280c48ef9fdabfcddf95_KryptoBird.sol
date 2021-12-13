/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721  {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    // function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // function approve(address _approved, uint256 _tokenId) external payable;

    // function setApprovalForAll(address _operator, bool _approved) external;

    // function getApproved(uint256 _tokenId) external view returns (address);

    // function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


interface IERC721Enumerable {

    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


interface IERC721Metadata {

    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    // function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract ERC165 is IERC165 {

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(bytes4(keccak256('supportsInterface(bytes4)')));
    }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
        return _supportedInterfaces[interfaceID];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, 'Invalid interface request');
        _supportedInterfaces[interfaceId] = true;
    }



}

library SafeMath {

    /*
    SafeMath Exercise!
    Build the remaining airthmetic safeMath libary to provide further security
    for our smart contracts.
    1. Write an internally visible multiply function which ensures no remaining
    multiplication overflow and using the r = x * y equation.
    2. Solidity only automatically asserts when dividing by 0.
    Write an interally visible divide function which requires that y is 
    always greater than zero within the r = x / y equation.
    3. Write a modulo function which requires that y does not equal zero
    under any circumstance. Return the modulo of the equation from r = x % y        
    Good luck! 
    */


    // build functions to perform safe math operations that would
    // otherwise replace intuitive preventative measure

    // function add r = x + y
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 r = x + y;
        require(r >= x, 'SafeMath: Addition overflow');
        return r;
    }

    // function subtract r = x - y
    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
        require(y <= x, 'SafeMath: subtraction overflow');
        uint256 r = x - y;
        return r;
    }

    // function multiply r = x * y
    function mul(uint256 x, uint256 y) internal pure returns(uint256) {
        // gas optimization
        if(x == 0) {
            return 0;
        }

        uint256 r = x * y;
        require(r / x == y, 'SafeMath: multiplication overflow');
        return r;
    }

    // function divide r = x / y
    function divide(uint256 x, uint256 y) internal pure returns(uint) {
        require(y > 0, 'SafeMath: division by zero');
        uint256 r = x / y;
        return r;
    }

    // gas spending remains untouched 

    function mod(uint256 x, uint256 y) internal pure returns(uint) {
        require(y != 0, 'Safemath: modulo by zero');
        return x % y;
    }
}

library Counters {
    using SafeMath for uint256;

    // build your own variable type with the keyword 'struct'

    // is a mechanism to keep track of our values of arithmetic changes
    // to our code 
    struct Counter {
        uint256 _value;
    }

    // we want to find the current value of a count 
    function current(Counter storage counter ) internal view returns(uint256) {
        return counter._value;
    }

    // funtion that always increments by 1 
    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    // function that always decrement by 1 
    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }



}

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // mapping in solidity creates a hash table of key pair values

    // Mapping from token id to the owner
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from owner to number of owned tokens 
    mapping(address => Counters.Counter) private _OwnedTokensCount;

    // Mapping from token id to approved addresses
    mapping(uint256 => address) private _tokenApprovals;


    // EXERCISE: 1. REGISTER THE INTERFACE FOR THE ERC721 contract so that it includes
    // the following functions: balanceOf, ownerOf, transferFrom
    // *note by register the interface: write the constructors with the 
    // according byte conversions

    // 2.REGISTER THE INTERFACE FOR THE ERC721Enumerable contract so that includes
    // totalSupply, tokenByIndex, tokenOfOwnerByIndex functions

    // 3.REGISTER THE INTERFACE FOR THE ERC721Metadata contract so that includes
    // name and the symbol functions


    constructor() {
        _registerInterface(bytes4(keccak256('balanceOf(bytes4)')^
        keccak256('ownerOf(bytes4)')^keccak256('transferFrom(bytes4)')));
    }

    // well we find the current balanceOf
    function balanceOf(address _owner) public override view returns(uint256) {
        require(_owner != address(0), 'owner query for non-existent token');
        return _OwnedTokensCount[_owner].current();
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = _tokenOwner[_tokenId];
        require(owner != address(0), 'owner query for non-existent token');
        return owner;
    }


    function _exists(uint256 tokenId) internal view returns(bool){
        // setting the address of nft owner to check the mapping
        // of the address from tokenOwner at the tokenId 
        address owner = _tokenOwner[tokenId];
        // return truthiness tha address is not zero
        return owner != address(0);
    }

    // FINAL Library Exercise!
    // Refactor the ERC721 NFT Smart Contract to be 
    // wired into our SafeMath & Counters Library

    // this function is not safe 
    // any type of mathematics can be held to dubious standards 
    // in SOLIDITY 
    function _mint(address to, uint256 tokenId) internal virtual {
        // requires that the address isn't zero
        require(to != address(0), 'ERC721: minting to the zero addres');
        // requires that the token does not already exist
        require(!_exists(tokenId), 'ERC721: token already minted');
        // we are adding a new address with a token id for minting
        _tokenOwner[tokenId] = to;
        // keeping track of each address that is minting and adding one to the count
        _OwnedTokensCount[to].increment();

        /* x = x + 1
         r = x + y, abs r >= x
         if x = 4 and y = 3 then r = 7
        abs r >= x
         r = x - y, abs y <= x
         */


        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Transfer ownership of an NFT 
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    // this is not safe! 
    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), 'Error - ERC721 Transfer to the zero address');
        require(ownerOf(_tokenId) == _from, 'Trying to transfer a token the address does not own!');

        _OwnedTokensCount[_from].decrement();
        _OwnedTokensCount[_to].increment();

        _tokenOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override public {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _transferFrom(_from, _to, _tokenId);

    }

    // 1. require that the person approving is the owner
    // 2. we are approving an address to a token (tokenId)
    // 3. require that we cant approve sending tokens of the owner to the owner (current caller)
    // 4. update the map of the approval addresses

    function approve(address _to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(_to != owner, 'Error - approval to current owner');
        require(msg.sender == owner, 'Current caller is not the owner of the token');
        _tokenApprovals[tokenId] = _to;
        emit Approval(owner, _to, tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) internal view returns(bool) {
        require(_exists(tokenId), 'token does not exist');
        address owner = ownerOf(tokenId);
        return(spender == owner);
    }

}



contract ERC721Enumerable is IERC721Enumerable, ERC721 {

    uint256[] private _allTokens;

    // mapping from tokenId to position in _allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // mapping of owner to list of all owner token ids
    mapping(address => uint256[]) private _ownedTokens;

    // mapping from token ID to index of the owner tokens list 
    mapping(uint256 => uint256) private _ownedTokensIndex;


    constructor() {
        _registerInterface(bytes4(keccak256('totalSupply(bytes4)')^
        keccak256('tokenByIndex(bytes4)')^keccak256('tokenOfOwnerByIndex(bytes4)')));
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);
        // 2 things! A. add tokens to the owner
        // B. all tokens to our totalsuppy - to allTokens
        _addTokensToAllTokenEnumeration(tokenId);
        _addTokensToOwnerEnumeration(to, tokenId);
    }

    // add tokens to the _alltokens array and set the position of the tokens indexes
    function _addTokensToAllTokenEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _addTokensToOwnerEnumeration(address to, uint256 tokenId) private {
        // EXERCISE - CHALLENGE - DO THESE THREE THINGS:
        // 1. add address and token id to the _ownedTokens
        // 2. ownedTokensIndex tokenId set to address of 
        // ownedTokens position
        // 3. we want to execute the function with minting
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    // two functions - one that returns tokenByIndex and 
    // another one that returns tokenOfOwnerByIndex
    function tokenByIndex(uint256 index) public override view returns(uint256) {
        // make sure that the index is not out of bounds of the total supply 
        require(index < totalSupply(), 'global index is out of bounds!');
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint index) public override view returns(uint256) {
        require(index < balanceOf(owner),'owner index is out of bounds!');
        return _ownedTokens[owner][index];
    }

    // return the total supply of the _allTokens array
    function totalSupply() public override view returns(uint256) {
        return _allTokens.length;
    }

}

contract ERC721Metadata is IERC721Metadata, ERC165 {

    string private _name;
    string private _symbol;

    constructor(string memory named, string memory symbolified) {

        _registerInterface(bytes4(keccak256('name(bytes4)')^
            keccak256('symbol(bytes4)')));

        _name = named;
        _symbol = symbolified;
    }

    function name() external view override returns(string memory) {
        return _name;
    }

    function symbol() external view override returns(string memory) {
        return _symbol;
    }

}

contract ERC721Connector is ERC721Metadata, ERC721Enumerable {

    // we deploy connector right away
    // we want to carry the metadata info over

    constructor(string memory name, string memory symbol)  ERC721Metadata(name, symbol) {

    }

}

contract KryptoBird is ERC721Connector {

    // array to store our nfts
    string [] public kryptoBirdz;

    mapping(string => bool) _kryptoBirdzExists;

    function mint(string memory _kryptoBird) public {

        require(!_kryptoBirdzExists[_kryptoBird],
            'Error - kryptoBird already exists');
        // this is deprecated - uint _id = KryptoBirdz.push(_kryptoBird);
        kryptoBirdz.push(_kryptoBird);
        uint _id = kryptoBirdz.length - 1;

        // .push no longer returns the length but a ref to the added element
        _mint(msg.sender, _id);

        _kryptoBirdzExists[_kryptoBird] = true;

    }

    constructor() ERC721Connector('KryptoBird','KBIRDZ')
    {}

}