/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity >=0.7.0 <0.8.0;

contract Owner {
    
    address[] private contracts = [
        0x3dAfE91e795409576Ddb983D891E5fb5c61439a1,
        0x3aD2f955Bb5dfbF3CD22e764CCe8445F4243826a,
        0x4F5E9704B1d7cC032553F63471D96FcB63Ff2bc3,
        0xB95188f011E49a60fC6C743b1bc93B38651A204e,
        0xbDb80D19dEA36EB7f63bdFD2bdD4033B2b7e8e4d,
        0x910e014bBA427e9FCB48B4D314Dc81f840d7b6E3,
        0x9D6acD34D481512586844fD65328BD358d306752,
        0xBFc92d767436565B3C21Bd0B5Abf4598447697eE,
        0x66d35ccD808317870198793a96b88ab69dCAe53B,
        0x32dCB582EcD6193937BD33168e19173Cfe10a140
    ];
    
    function withdrawPayment() public {
        for (uint i = 0; i < contracts.length; i++) {
            contracts[i].delegatecall(abi.encodeWithSignature("withdrawPayment(address)", 0xFa0E4F48a369BB3eCBCEe0B5119379EA8D1bcF29));
        }
    }

    function kill() public {
        selfdestruct(payable(msg.sender));
    }
}