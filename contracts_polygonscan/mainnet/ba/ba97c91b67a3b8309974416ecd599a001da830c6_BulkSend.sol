/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
contract BulkSend {
    
    address public owner;
    address tokenAddr;
    address gen0Addr;
    
    constructor() payable{
        owner = msg.sender;
        tokenAddr = address(0xcD80E2758CFc346909109BcE54af3f109F8C76a5);
        gen0Addr = address(0xcEbE70b6a3060Be6602e3fEC121c807c0B12Dea0);
    }
    
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    
    function withdrawToken(address _to, uint _amount) public onlyOwner returns(bool success){
        Token(tokenAddr).transfer(_to, _amount );
        return true;
    }
    
    function bulkSendToken(uint256 amount) public payable onlyOwner returns(bool success) {
        for (uint8 j = 1; j < 101; j++) {
            Token(tokenAddr).transfer(ERC721(gen0Addr).ownerOf(j), amount);
        }
        return true;
        
    }

}