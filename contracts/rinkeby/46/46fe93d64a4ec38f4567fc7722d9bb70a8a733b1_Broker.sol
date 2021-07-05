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
    
    constructor(uint _brokerage, address _mintableToken) public{
        owner = msg.sender;
        brokerage = _brokerage;
        Token = MintableToken(_mintableToken);
    } 
    
    
    function buy(uint tokenID) payable public{
        require(tokenOpenForSale[tokenID]==true,'Token Not For Sale');
        require(msg.value>=prices[tokenID],'Insufficient Payment');
        address lastOwner = Token.ownerOf(tokenID);
        address payable lastOwner2 = address(uint160(lastOwner));
        uint royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        Token.safeTransferFrom(Token.ownerOf(tokenID), msg.sender, tokenID);
        creator.transfer(royalities*msg.value/100);
        lastOwner2.transfer((100-royalities-brokerage)*msg.value/100);
    } 
    
    function withdrawETH() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
    
    function putOnSale(uint tokenID, uint _price) public{
        require(Token.ownerOf(tokenID)==msg.sender,'Permission Denied');
        require(Token.getApproved(tokenID)==address(this),'Broker Not approved');
        prices[tokenID] = _price;
        tokenOpenForSale[tokenID] = true;
    }
    
    function putSaleOff(uint tokenID) public{
        require(Token.ownerOf(tokenID)==msg.sender,'Permission Denied');
        prices[tokenID] = uint(0);
        tokenOpenForSale[tokenID] = false;
    }
     
    
    modifier onlyOwner() {
        require(owner==msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function () payable external{
    //call your function here / implement your actions
    }

}