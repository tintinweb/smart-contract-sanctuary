/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity 0.8.0;

contract Likelion_9 {

    uint x;
    uint y;

    
    function getPW2(uint) public view returns(uint) {
        for(uint x = 0; x <= 9; x++) {
            if(x == 2) {
            return x;
            }
        }
    }
    
    function getPW3(uint) public view returns(uint) {
        for(uint y = 0; y <= 9; y++) {
            if(y == 9) {
            return y;
            }
            
        }
}
    function setPW() public view returns(uint, uint, uint, uint) {
        return (0, 4, x, y);
    }
}