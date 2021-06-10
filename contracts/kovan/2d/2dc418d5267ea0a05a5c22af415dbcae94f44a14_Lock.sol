/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^ 0.5.1;

contract Lock {
    address payable beneficiary;
    uint256 releaseTime;
    
    constructor (address payable _beneficiary, uint256 _releaseTime) public payable{
        require(_releaseTime > block.timestamp);
        beneficiary= _beneficiary;
        releaseTime= _releaseTime;
    }
    
    function release()public payable {
        require(block.timestamp >= releaseTime );
        address(beneficiary).transfer(address(this).balance);
        
    }
}