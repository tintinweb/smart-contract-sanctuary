/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SampleProxy
pragma solidity >=0.6.0 <0.8.0;

contract Test {
    uint256[] public array;

    function add(uint256 val) public {
        array.push(val);
    }

    function getArray() public view returns (uint256[] memory) {
        return array;
    }
}