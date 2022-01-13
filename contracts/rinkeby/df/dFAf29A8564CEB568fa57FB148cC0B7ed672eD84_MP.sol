/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

contract MP {

    uint256  price; //to store price of token
    address  owner ; // to address of owner
    address  tokenContract; //address of deployed contract

    constructor(uint256 _price, address _contract) {
        owner = msg.sender;
        price = _price;
        tokenContract = _contract;
    }



    mapping (address =>uint256) soldToken; //to find number of token of sold to address
    mapping (uint256 =>address) tokenOwner; //to find owner of token
    uint256  tokenNum = 201; //Token number

    KGT kg = KGT(tokenContract);



    function setPrice(uint256 _price) public returns(bool){
        require(msg.sender == owner,"Only owner can set price");
        price = _price;
        return(true);
    }

    function priceOfToken()public view returns(uint256){
        return(price);
    }

    function ownerOfToken(uint256 tokenid) public view returns(address){
        require(tokenOwner[tokenid] != address(0),"Invalid Token");
        return(tokenOwner[tokenid]);
    }

    function buy() public payable returns(string memory, uint256){
        require(msg.value >= price  ,"Value less then the price" );
        address _to = msg.sender;
        kg.mint(_to,tokenNum);
        soldToken[_to] += 1 ;
        tokenOwner[tokenNum] =_to;
        tokenNum += 1;
        return ("TokenID is ",tokenNum);
    }

    function checkOutMoney() public returns(uint256){
        require(msg.sender == owner,"You are not the owner");
        payable(owner).transfer(address(this).balance);
        return(address(this).balance);
    }

}


interface KGT{

    function mint(address _to, uint256 _tokenId) external;
}