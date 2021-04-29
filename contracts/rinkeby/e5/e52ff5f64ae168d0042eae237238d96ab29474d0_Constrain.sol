/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: ERC7212
pragma solidity ^0.4.24;


/**
 *
 *  
        ██████╗░██████╗░░█████╗░██████╗░░█████╗░░██████╗░░█████╗░███╗░░██╗██████╗░░█████╗░
        ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝░██╔══██╗████╗░██║██╔══██╗██╔══██╗
        ██████╔╝██████╔╝██║░░██║██████╔╝███████║██║░░██╗░███████║██╔██╗██║██║░░██║███████║
        ██╔═══╝░██╔══██╗██║░░██║██╔═══╝░██╔══██║██║░░╚██╗██╔══██║██║╚████║██║░░██║██╔══██║
        ██║░░░░░██║░░██║╚█████╔╝██║░░░░░██║░░██║╚██████╔╝██║░░██║██║░╚███║██████╔╝██║░░██║
        ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═╝░░╚═╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝

 *                                                                by Juan David Peña Melo
 *
**/

interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}

contract Constrain {
        mapping(bytes4 => bool) internal supportedInterfaces;
        address public constant BENEFICIARY = 0x27E3940341A6B9EF89A45665Da2bb419E638FF15;
        bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
        uint internal numTokens = 0;
        mapping (uint256 => address) internal idToOwner;
        mapping (uint256 => address) internal idToApproval;
        mapping(uint256 => uint256) internal idToOwnerIndex;
        mapping(address => uint256[]) internal ownerToIds;
        mapping (uint256 => string) private _tokenURIs;
        uint public constant PRICE = 1000 finney;
        string internal nftName = "Constrain";
        
        
        string internal nftSymbol = "▒";
    
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    function name() external view returns (string memory _name) {
        _name = nftName;
    }
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
    
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }
    
    function tokenUri (uint256 _tokenId) public view returns (string memory){
        return "https://api.jsonbin.io/b/606936810412507e65052dcc/2";
    }
    
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].length--;
    }
    
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;
        uint256 length = ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = length - 1;
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);
        emit Transfer(from, _to, _tokenId);
}

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal  {
        require((tokenId) != 0, "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _mint(address _to ) external returns(string){
        uint id = numTokens + 1;
        //_setTokenURI(id, tokenUri);
        emit Transfer(address(0), _to, id);
        return "https://api.jsonbin.io/b/606936810412507e65052dcc/2";
    }
}