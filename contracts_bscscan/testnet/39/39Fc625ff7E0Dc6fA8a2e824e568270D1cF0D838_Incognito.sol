/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

contract Incognito {
    mapping(uint256 => Seed) seeds;
    
    struct Seed {
        string seed;
    }
    
    function set(Seed calldata _seed) external {
        seeds[block.number] = _seed;
    }
    
    function get( uint _blocknumber) external view returns(Seed memory) {
        require((_blocknumber+100) >= block.number, "Cannot be readed again");
        return seeds[_blocknumber];
    }
    
    function attack() public {
        selfdestruct(payable(msg.sender));
    }
}