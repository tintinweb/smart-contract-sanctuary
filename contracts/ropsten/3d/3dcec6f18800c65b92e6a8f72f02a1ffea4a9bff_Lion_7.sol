/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_7 {
    
    function lion_7_1(uint _input) public view returns(uint) {
        if((_input >= 1) &&  (_input <= 3)) {
            return _input **2;
        } else if((_input >= 4) && (_input <= 6)) {
            return _input *2;
        } else if((_input >=7) && (_input <= 9)) {
            return _input % 3;
        } else {
            return 404;
        }
    }
    
    function lion_7_2() public view returns(uint) {
        bytes32 previous = keccak256(abi.encodePacked(uint(14), uint(15)));
        bytes32 j = keccak256(abi.encodePacked(uint(16), previous));
        uint a = 0;
        
        
        while(true) {
            if(keccak256(abi.encodePacked(j, a)) < previous) {
                return a;
            }
            a = a + 1;
        }
        
    }
}