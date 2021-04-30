/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: ERC721
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

 *                                                                by Alejandro Velez Eslava && Juan David Peña Melo
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
        string prefix = "https://api.jsonbin.io/b/606936810412507e65052dcc/2";
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
    
    
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Generated(uint indexed index, address indexed a, string value);
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
    
/*    function tokenUri (uint256 _tokenId) public view returns (string memory){
        return "https://api.jsonbin.io/b/606936810412507e65052dcc/2";
    }*/
    
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
   
    function Tax_Payment(address from, uint256 id) external payable{
        uint amount = PRICE;
        require(msg.value >= amount);
        if(msg.value > amount){
            BENEFICIARY.transfer(amount);
        }
        emit Transfer(from, address(0), id);
    }
   
   
    function tokenURI(uint256 id) public view returns (string){
         require(totalSupply() >= id, "ERC721Metadata: URI query for nonexistent token");
         return _tokenURIs[id];
    }
   
   
    function mintNFT(address receiver, string tokenUri) external returns (bool){
        uint256 id = numTokens + 1;
        _tokenURIs[id] = tokenUri;
        _mint(receiver, id);
        return true;
    }
     
    function _mint(address _to, uint256 id) internal returns(uint256){
        require(_to != address(0));
        //emit Generated(id, _to, tokenURI);
        emit Transfer(address(0), _to, id);
        numTokens = numTokens + 1;
        _addNFToken(_to, id);
        return id;
    }
    
    
        //// Enumerable

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < numTokens);
        return index;
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }
    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }
    
}