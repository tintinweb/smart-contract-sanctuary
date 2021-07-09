/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

// import "@openzeppelin/contracts/ownership/Ownable.sol";

contract MintableToken {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function royalities(uint _tokenId) public view returns (uint);
    function creators(uint _tokenId) public view returns (address payable);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    
    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
 
contract Broker{
    
    MintableToken Token;
    address owner;
    uint brokerage;
    mapping(uint => bool) tokenOpenForSale;
    mapping (uint => uint) public prices;
    mapping (address => uint[]) public tokensForSalePerUser;
    uint[] public tokensForSale;
    
    constructor(uint _brokerage, address _mintableToken) public{
        owner = msg.sender;
        brokerage = _brokerage;
        Token = MintableToken(_mintableToken);
    } 
    
    function getTokensForSale() public view returns (uint[] memory) {
        return tokensForSale;
    }
    
    function getTokensForSalePerUser(address _user) public view returns (uint[] memory) {
        return tokensForSalePerUser[_user];
    }
    
    function buy(uint tokenID) payable public{
        require(tokenOpenForSale[tokenID]==true,'Token Not For Sale');
        require(msg.value>=prices[tokenID],'Insufficient Payment');
        address lastOwner = Token.ownerOf(tokenID);
        address payable lastOwner2 = address(uint160(lastOwner));
        uint royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        Token.safeTransferFrom(Token.ownerOf(tokenID), msg.sender, tokenID);
        creator.transfer(royalities*msg.value/10000);
        lastOwner2.transfer((10000-royalities-brokerage)*msg.value/10000);
        
        prices[tokenID] = uint(0);
        tokenOpenForSale[tokenID] = false;
        uint index;
        for(uint i=0; i<tokensForSale.length; i++){
            if(tokensForSale[i]==tokenID){
                index = i;
                break;
            }
        }
        
        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();
        
        uint index2;
        for(uint i=0; i<tokensForSalePerUser[lastOwner2].length; i++){
            if(tokensForSalePerUser[lastOwner2][i]==tokenID){
                index2 = i;
                break;
            }
        }
        
        tokensForSalePerUser[lastOwner2][index2] = tokensForSalePerUser[lastOwner2][tokensForSalePerUser[lastOwner2].length - 1];
        delete tokensForSalePerUser[lastOwner2][tokensForSalePerUser[lastOwner2].length - 1];
        tokensForSalePerUser[lastOwner2].pop();
    } 
    
    function withdrawETH() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
    
    function putOnSale(uint tokenID, uint _price) public{
        require(Token.ownerOf(tokenID)==msg.sender,'Permission Denied');
        require(Token.getApproved(tokenID)==address(this),'Broker Not approved');
        prices[tokenID] = _price;
        tokenOpenForSale[tokenID] = true;
        tokensForSale.push(tokenID);
        tokensForSalePerUser[msg.sender].push(tokenID);
    }
    
    function putSaleOff(uint tokenID) public{
        require(Token.ownerOf(tokenID)==msg.sender,'Permission Denied');
        prices[tokenID] = uint(0);
        tokenOpenForSale[tokenID] = false;
        uint index;
        for(uint i=0; i<tokensForSale.length; i++){
            if(tokensForSale[i]==tokenID){
                index = i;
                break;
            }
        }
        
        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();
        
        uint index2;
        for(uint i=0; i<tokensForSalePerUser[msg.sender].length; i++){
            if(tokensForSalePerUser[msg.sender][i]==tokenID){
                index2 = i;
                break;
            }
        }
        
        tokensForSalePerUser[msg.sender][index2] = tokensForSalePerUser[msg.sender][tokensForSalePerUser[msg.sender].length - 1];
        delete tokensForSalePerUser[msg.sender][tokensForSalePerUser[msg.sender].length - 1];
        tokensForSalePerUser[msg.sender].pop();
    }
         
    function getOnSaleStatus(uint _tokenId) public view returns (bool){
        return tokenOpenForSale[_tokenId];
    }
    
    modifier onlyOwner() {
        require(owner==msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function () payable external{
    //call your function here / implement your actions
    }

}