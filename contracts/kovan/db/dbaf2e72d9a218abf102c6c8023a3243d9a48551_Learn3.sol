/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity >=0.5.0 <0.6.0;

contract Learn3 {
    
    struct SA {
        uint8 a;
        uint8 b;
        uint8 c;
        uint8 d;
        uint256 e;
    }
    
    struct SB {
        uint8 a;
        uint8 b;
        uint256 c;
        uint8 d;
        uint8 e;
    }
    
    SA[] saList;
    SB[] sbList;
    
    function appendSA(uint256 _input) public {
        SA memory sa = SA(uint8(_input), uint8(_input), uint8(_input), uint8(_input), _input);
        saList.push(sa);
    }
    
    function appendSB(uint256 _input) public {
        SB memory sb = SB(uint8(_input), uint8(_input), _input, uint8(_input), uint8(_input));
        sbList.push(sb);
    }
}