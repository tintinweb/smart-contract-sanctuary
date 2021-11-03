/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity ^0.8.9;


contract WriteLable{
    mapping(address => uint256) public isWrite;
    address owner;
    
    
    ERC721 nft = ERC721(0x7917E7e5AA6a7F5782c0875a2c63FBd396B02a49);
    
    constructor(){
        owner = msg.sender;
    }
    
    
    function setWrite(address _user, uint256 _nftNum) public {
        require(owner == msg.sender, 'you are not the owner' );
        
        isWrite[_user] = _nftNum;
    }
    
    function nftTransfer() public{
        require(isWrite[msg.sender] != 0 , 'you are not on the list');
        
        for(uint256 i=0; i<isWrite[msg.sender]; i++){
            nft.transferFrom(address(this), msg.sender, nft.tokenByIndex(0));
        }
        
    }

    
}



contract ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) public{}
    function tokenByIndex(uint256 index) public view returns (uint256){}
    
}