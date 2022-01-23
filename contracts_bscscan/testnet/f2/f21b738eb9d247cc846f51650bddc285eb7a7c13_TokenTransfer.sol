/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

//pragma solidity ^0.4.21;
 
// interface token {
//     function transfer(address to, uint256 value) external returns (bool);
// } 
// contract Caller {
//     function staking(address to, uint256 value) public {
//         token func = token(0x82bbb8326c02a172ba927dff525b60e10dbdcc3a);
//         func.transfer(to, value);
//     }
// }


pragma solidity ^0.4.21;
interface token { 
    function transfer(address to, uint256 value) external returns (bool);
} //transfer方法的接口说明

contract TokenTransfer{
    token public wowToken;
    
    function TokenTransfer(){
       wowToken = token(0x82bbb8326c02a172ba927dff525b60e10dbdcc3a); //实例化一个token
    }
    
    function tokenTransfer(address _to, uint _amt) public {
        wowToken.transfer(_to,_amt); //调用token的transfer方法
    }
}