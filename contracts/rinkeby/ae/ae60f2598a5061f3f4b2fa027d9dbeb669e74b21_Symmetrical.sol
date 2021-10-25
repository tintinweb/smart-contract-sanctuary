//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './ERC721Connector.sol';

contract Symmetrical is ERC721Connector {

//array to store our nfts
 string[] public symmetricalz;

mapping (string => bool) _symmetricalzExists;
constructor () ERC721Connector('Symmetrical', 'SymmetricalNFT') {
}

function mint (string memory _symmetrical, uint256 _mintAmount) public {
   require(!paused,'coffee time...paused for some reason!');
   require(!_symmetricalzExists[_symmetrical],'error ..Symmetricalz already exists');
   uint256 _tokenNum = totalSupply()+1;
   
   // uint256 _id = Symmetrical.push(_Symmetrical) deprecated
    symmetricalz.push(_symmetrical);
    require(_mintAmount >0,'you need to mint at least one token');
    require(_mintAmount <= maxMintAmount, 'you cannot mint that many at a time');
    require(_tokenNum + _mintAmount <= maxSupply,'There are not enough tokens available, we have landing on the moon');
    
    
    _mint(msg.sender, _tokenNum);
    _symmetricalzExists[_symmetrical] = true;
}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './ERC721Metadata.sol';
import './ERC721Enumerable.sol';

contract ERC721Connector is ERC721Metadata, ERC721Enumerable {


 constructor (string memory name, string memory symbol) ERC721Metadata(name, symbol) {



    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './ERC721.sol';
import './interfaces/IERC721Enumerable.sol';

contract ERC721Enumerable is IERC721Enumerable, ERC721{
    string private baseURI;
    string public baseURIExtension = ".json";
    uint256 public cost = 0.06 ether;
    uint256 public maxSupply = 10000;
    uint256 public reserveSupply = 200;
    uint256 public maxMintAmount = 20;
    uint256 public nftPerAddressLimit = 3;
    uint256[] private _allTokens;
    bool public paused = true;
    bool public onlyWhiteListed = false;
    address[] public WhiteListedUsers;
    
    ///mapping from tokenId to position in _allTokens
    mapping (uint256 => uint256) private _allTokensIndex;

    ///mapping of owner to list of all owner token ids
    mapping (address => uint256[]) private _ownedTokens;

    ///mapping from token id to index of the owner token list
    mapping (uint256 => uint256) private _ownedTokensIndex;

constructor () {

        _registerInterface(bytes4(keccak256('totalSupply(bytes4)')^
        keccak256('tokenByIndex(bytes4)')^
         keccak256('tokenOfOwnerByIndex(bytes4)')));
    }


    //function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);
    /// 2 things - add tokens to the owner
    /// all tokens to our total supply - to allTokens
        _addTokensToAllTokenEnumerations(tokenId);
        _addTokensToOwnerEnumerations(to,tokenId);

    }
    //add tokens to allTokens array and set position of tokens index
    function _addTokensToAllTokenEnumerations(uint256 tokenId) private{
        _allTokensIndex[tokenId]=_allTokens.length;
        _allTokens.push(tokenId);

    }
    
    function _addTokensToOwnerEnumerations (address to, uint256 tokenId) private {
    //add address and tokenId to the _ownedTokens
    //ownedTokensIndex tokenId set to address of ownedToken
    //we want to execute the function with mintion
        _ownedTokensIndex[tokenId]= _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function tokenByIndex (uint256 index) public view override returns (uint256){
        require (index < totalSupply(),'token index is out of range of owned tokens');
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex (address owner, uint256 index) public view override returns (uint256){
        require (index < balanceOf(owner),'owner index is out of range of total supply');
        return _ownedTokens[owner][index];
    }

    ///Count NFTs tracked by this contract
    ///A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply () public view override returns(uint256) {

        return _allTokens.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import './interfaces/IERC721Metadata.sol';
import './ERC165.sol';

contract ERC721Metadata is IERC721Metadata, ERC165 {
    
    string private _name;
    string private _symbol;

constructor (string memory _named, string memory _symbolified) {

     _registerInterface(bytes4(keccak256('name(bytes4)')^keccak256('symbol(bytes4)')));
    _name = _named;
    _symbol = _symbolified;
     
}


function name () external view override returns (string memory ) {

    return _name;
}

function symbol () external view override returns (string memory ) {

    return _symbol;
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IERC165.sol';

contract ERC165 is IERC165 {

    mapping (bytes4 => bool) private _supportedInterfaces;
    /// uery if a contract implements an interface
    /// The interface identifier, as specified in ERC-165
    /// Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise

    constructor () {

        _registerInterface(bytes4(keccak256('supportsInterface(bytes4)')));
    }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool){
        return _supportedInterfaces[interfaceID];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require (interfaceId != 0xffffffff, 'Error: invalid interface request');
        _supportedInterfaces[interfaceId]=true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Metadata {
 
    function name() external view returns (string memory _name);


    function symbol() external view returns (string memory _symbol);


    //function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;




interface IERC721Enumerable {

    function totalSupply() external view returns (uint256);


    function tokenByIndex(uint256 _index) external view returns (uint256);


    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC165.sol';
import './interfaces/IERC721.sol';

contract ERC721 is ERC165, IERC721{


//mapping from token Id to Owner
mapping (uint256 => address) private _tokenOwner;
mapping (address => uint256 ) private _ownedTokensCount;
mapping (uint256 => address) private _tokenApprovals;

constructor () {

        _registerInterface(bytes4(keccak256('balanceOf(bytes4)')^
        keccak256('transferFrom(bytes4)')^
         keccak256('ownerOf(bytes4)')));
    }



function balanceOf (address _owner) public view override returns(uint256)  {
    require (_owner != address(0),'Owner address does not exist');
    return _ownedTokensCount[_owner];
    

}

function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
    require (isApprovedOrOwner(msg.sender, _tokenId));
    require (_to != address(0),'the to address does not exist');
    require (ownerOf(_tokenId) == _from,'the sender does not own tokenId');
    _ownedTokensCount[_from] -=1;
    _ownedTokensCount[_to] +=1;

    _tokenOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);

}

//require the approval is from the owner
//we are approvind an address to a token
//do not need the approval of the owner to the owner
//update map of approval addresses
function approve(address _to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require (_to != owner, 'cannot approve owner to owner');
    require (msg.sender == owner, 'current caller is not the owner');
    _tokenApprovals[tokenId] = _to;

    emit Approval(owner, _to, tokenId);
}

function transferFrom (address _from, address _to, uint256 _tokenId) public override {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _transferFrom(_from, _to, _tokenId);
}

function isApprovedOrOwner(address spender, uint256 tokenId) internal view returns(bool){
    require(_exists(tokenId),'token does not exist');
    address owner= ownerOf(tokenId);
    return (spender == owner);

}

function ownerOf (uint256 _tokenId) public view override returns(address)  {
    address owner = _tokenOwner[_tokenId];
    require (owner != address(0),'Owner address does not exist');
    return owner;
}

function _exists (uint256 tokenId) internal view returns (bool) {
    //setting the address of nft token owner to check the mapping of the address
    // from tokenowner at the tokenId
    address owner = _tokenOwner[tokenId];
    //return truthiness the address is not zero
   return owner != address(0);    

}

function _mint (address to, uint256 tokenId) internal virtual{
    //requires that the address isnt zero
 require (to != address(0), 'address is not valid');
//requires that the token does not already exist
 require (!_exists(tokenId), 'the token has been minted' );
 //we are adding a new address with a token id for minting
 _tokenOwner[tokenId] = to;
 //we are keeeping track of each token that is minted and adding one to the owners address total
 _ownedTokensCount[to] += 1;

emit Transfer (address(0), to, tokenId);


}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721  {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

 
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);


   



    function balanceOf(address _owner) external view returns (uint256);


    function ownerOf(uint256 _tokenId) external view returns (address);


    //function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

 
    //function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;


    function transferFrom(address _from, address _to, uint256 _tokenId) external;


    //function approve(address _approved, uint256 _tokenId) external payable;


    //function setApprovalForAll(address _operator, bool _approved) external;


    //function getApproved(uint256 _tokenId) external view returns (address);


    //function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
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