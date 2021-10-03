/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint8 smallNumber;
    uint256 bigNumber;

    function squareSmall(uint8 x) public {
         smallNumber = x * x ;
    }

    function squareBig(uint256 x) public {
        bigNumber = x * x;
    }

    function store(uint8 x, uint256 y) public {
        smallNumber = x;
        bigNumber = y;
    }

    function retrieve() public view returns (uint8, uint256){
        return (smallNumber, bigNumber);
    }
}