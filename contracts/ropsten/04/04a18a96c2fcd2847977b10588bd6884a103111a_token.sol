// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract token is ERC20{
    uint32 private release_time = uint32(block.timestamp);
    uint128 public constant max_token_number = uint128(37800000000000 ether);

    mapping(address => bool) private if_calaim;
    address[] private yet_calaim;
    uint128 all_calaim = max_token_number/2;
    uint128 private yet_calaim_number;

    constructor() ERC20("random", "rd"){
        _mint(0x5F0bC7Aa98c15d1eA8C7e3a7AD3eE81D1f3DC260,max_token_number/100*12);
    }


    function claim() public returns(uint128){
        uint128 claim_number;

        if(return_if_calaim() == false){
            if(yet_calaim.length < 1010){
                claim_number = uint128((all_calaim/100*20)/1010);
            }

            else if(yet_calaim.length > 1010 && yet_calaim.length <= 101010){
                claim_number = uint128((claim_number-yet_calaim_number)/100000*1);
            }
            _mint(msg.sender,claim_number);
            yet_calaim_number += claim_number;
            if_calaim[msg.sender] = true;
            yet_calaim.push(msg.sender);
            return claim_number;
        }
        
    }

    function return_if_calaim() view private returns(bool){
        return if_calaim[msg.sender];
    }

}