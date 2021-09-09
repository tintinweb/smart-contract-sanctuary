/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Litest {

    uint256 count = 0;
    bool smart_done = false;
    bool game_done = false;
    
    constructor() payable {
    }
    
    function get_count() public view returns (uint256) {
        return count;
    }
    
    function inc_count() public {
        count += 1;
    }
    
    function steal() public {
        if (count > 5) {
            payable(msg.sender).transfer(0.1 ether);
        }
        count = 0;
    }
    
    function im_smart(uint256 x) public {
        if (x * x * x == 295408296 && !smart_done) {
            smart_done = true;
            payable(msg.sender).transfer(0.3 ether);
        }
    }
    
    function best_game(bytes memory x) public {
        if (keccak256(x) == 0x9d0ad7cc09fe1061561f7b9459c01318174cc8c3ad5bfeb2a05c10db6eece5ad && !game_done) {
            game_done = true;
            payable(msg.sender).transfer(0.5 ether);
        }
    }

}