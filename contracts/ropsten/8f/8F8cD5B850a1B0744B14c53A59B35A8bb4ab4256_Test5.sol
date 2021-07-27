/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity 0.8.6;

contract Test5 {
    
    mapping(address => uint) count;

    uint nonce;
    
    constructor(uint _n) payable {
        nonce = _n;
    }
    
    function getCount() view public returns (uint){
        return count[msg.sender];
    }
    
    function getNonce() view public returns (uint){
        return nonce;
    }
    
    function addCount() public {
        count[msg.sender]++;
    }
    
    function withdraw() public {
        require(count[msg.sender] == nonce);
        payable(msg.sender).transfer(address(this).balance);
    }
    
    fallback() external {
        
    }
    
}