/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

contract Tt {
    // address public addr1;
    
    // function test3() public{
    //     addr1 = msg.sender;
    // }

	uint256 public first 	= 5;
	uint256 public second   = 20;
	uint256 public third 	= 50;
	uint256 public fourth   = 100;
	
	uint256 public max_num;

	//抽中的奖项（ 1至5号一等奖，6至25号二等奖，26至75号三等奖，76至175号四等奖）
	string public prize;
    
    uint256 private constant MAX = uint256(0) - uint256(1);
    uint256 private OFFSET = 1;
    uint256 public random_num = 0;
    
    struct Data {
        uint256 first_num;
        uint256 second_num;
        uint256 third_num;
        uint256 fourth_num;
    }
    
    mapping(address => Data) public user_prizes;
    
    function random() public returns (uint256) {
        
        Data storage user_prize = user_prizes[msg.sender];
        
        max_num = first + second + third + fourth;
        
        uint256 SCALIFIER = MAX / max_num;
    
        uint256 seed = uint256(keccak256(abi.encodePacked(now)));
        uint256 scaled = seed / SCALIFIER;
        random_num = scaled + OFFSET;

    	if (random_num <= first) {
    		first = first - 1;
    		prize = "first";
    		user_prize.first_num = user_prize.first_num +1;
    	}
    	else if (random_num > first && random_num <= (first + second) ) {
    		second = second - 1;
    		prize = "second";
    		user_prize.second_num = user_prize.second_num +1;
    	}
    	else if (random_num > second && random_num <= (first + second + third)) {
    		third = third - 1;
    		prize = "third";
    		user_prize.third_num = user_prize.third_num +1;
    	}
    	else if (random_num > third && random_num <= (first + second + third + fourth)) {
    		fourth = fourth - 1;
    		prize = "fourth";
    		user_prize.fourth_num = user_prize.fourth_num +1;
    	}

        return random_num;
    }
    

}