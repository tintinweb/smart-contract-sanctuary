/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity >=0.5.0 <0.6.0;

contract Learn2 {
    
    struct SA {
        uint8 a;
        uint8 b;
        uint8 c;
        uint8 d;
        uint8 e;
    }
    
    struct SB {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 e;
    }
    
    SA[] saList;
    SB[] sbList;
    
    function appendSA(uint8 _input) public {
        SA memory sa = SA(_input, _input, _input, _input, _input);
        saList.push(sa);
    }
    
    function appendSB(uint256 _input) public {
        SB memory sb = SB(_input, _input, _input, _input, _input);
        sbList.push(sb);
    }
}