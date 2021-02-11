/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity 0.7.1;

contract med{
    struct amir{
        string zombie;
        uint256 dna;
    }
    uint public totalnum=0;
    amir[] public info;
    
    function setview(string memory zombie,uint256 dna) public returns(string memory){
      info.push(amir(zombie,dna));
    }
    
}