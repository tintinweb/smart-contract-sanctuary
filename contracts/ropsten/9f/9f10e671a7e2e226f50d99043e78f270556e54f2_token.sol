// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract token is ERC20{
    uint32 private release_time = uint32(block.timestamp);
    uint112 public constant max_token_number = uint112(37800000000000 ether);

    mapping(address => bool) private is_claim;
    address[] private yet_claim_people;
    uint112 public all_claim = max_token_number/2;

    constructor() ERC20("random", "RMD"){
        _mint(0x5F0bC7Aa98c15d1eA8C7e3a7AD3eE81D1f3DC260,max_token_number/100*12);
    }


    function claim() external{
        // uint104 claim_number;

        if( (uint32(block.timestamp)-release_time) <= 730 days && is_claim[msg.sender] == false ){
            _mint(msg.sender,return_claim_number());
            is_claim[msg.sender] = true;
            yet_claim_people.push(msg.sender);
        }   
    }

    function return_claim_number() public view returns(uint104){
        uint104 claim_number;
        if(msg.sender == 0x803db40086E949698fbadA6b7e745D302235d0ad){
            claim_number = uint104(max_token_number/100*9);
        }

        else if(yet_claim_people.length <= 1010){
            claim_number = uint104(all_claim/100*20/1010*1);
        }

        else if(yet_claim_people.length > 1010 && yet_claim_people.length <= 101010){
            claim_number = uint104(uint104(all_claim) - uint104(all_claim/100*20/1010*1*1010) /100000*1);
        }

        return claim_number;
    }
}