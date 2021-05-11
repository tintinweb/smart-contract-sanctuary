/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//JInseon Moon
pragma solidity 0.8.0;

contract Lion_10 {
    bytes32 hash = keccak256(abi.encodePacked(uint(0), uint(4), uint(2), uint(9)));
    
    function matching() public view returns(bool, uint, uint) {
        for(uint a = 0; a < 10; a++) {
            for(uint b = 0; b < 10; b++) {
                bytes32 password = keccak256(abi.encodePacked(uint(0), uint(4),a,b));
                if(password == hash) {
                    return (true, a, b);
                }
            }
        }
        
        return (false, 404, 404);
    }
    /*
    function lion_10(uint pw) public view returns(uint, uint, uint, uint) {
        uint a;
        uint b;
        uint c;
        uint d;
        
        d = pw % 10;
        pw = uint(pw / 10);
        
        c = pw % 10;
        pw = uint(pw / 10);
        
        b = pw % 10;
        pw = uint(pw / 10);
        
        a = pw %10;
        
        return(a, b, c, d);
        
    }
    */
}