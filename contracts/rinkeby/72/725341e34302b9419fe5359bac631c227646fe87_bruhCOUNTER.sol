/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity ^0.4.18;

contract bruhETH {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
}

contract bruhCOUNTER {
    mapping (address => uint256) public bruhCOUNT;
    
    address bethADDR = 0x87f105bf52Ee58C88486fC7416bB66de2DBD25ef;
    
    function increment() public {
        bruhETH beth = bruhETH(bethADDR);
        
        if (beth.transferFrom(msg.sender, address(this), 1 ether)) {
            bruhCOUNT[msg.sender] += 1;
        }
    }
}