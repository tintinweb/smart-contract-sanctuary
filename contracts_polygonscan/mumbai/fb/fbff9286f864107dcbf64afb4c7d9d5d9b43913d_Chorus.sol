/**
 *Submitted for verification at polygonscan.com on 2021-11-20
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: UNLICENSED

contract Chorus {

    // TODO: check for duplicates
    string [] all_singers;

    struct Singer {
        string name;
        string song;
        string [] following;
        string [] followers;
        bool member_p;
    }

    mapping(address => Singer) chorus;

    // this is trash
    mapping(string => address) name_to_address;

    function join_chorus(string memory name) public returns (bool){
        address who = msg.sender;
        chorus[who].name = name;
        chorus[who].song = "this is my first song";
        chorus[who].member_p = true;
        name_to_address[name] = who;
        all_singers.push(name);
        return chorus[who].member_p;
    }

    function listen_to_song(string memory name) public view returns (string memory){
        return chorus[name_to_address[name]].song;
    }

    function sing(string calldata song) public returns (bool){
        address who = msg.sender;
        if (!(chorus[who].member_p)) return false;
        chorus[who].song = song;
        return true;
    }

    function get_address_from_name(string memory name) public view returns (address){
        return name_to_address[name];
    }

    function get_all_singers() public view returns (string [] memory){
        return all_singers;
    }

    function whoami() public view returns (string memory){
        return chorus[msg.sender].name;
    }

    ///////

    // TODO: check for multiple
    // TODO: check for non-existent chorus member
    function follow(string memory friend) public returns (bool){
        address who = msg.sender;
        address indirect_object = name_to_address[friend];
        chorus[who].following.push(friend);
        chorus[indirect_object].followers.push(chorus[who].name);
        return true;
    }

    function get_following() public view returns (string [] memory){
        address who = msg.sender;
        return chorus[who].following;
    }

    function get_followers() public view returns (string [] memory){
        address who = msg.sender;
        return chorus[who].followers;
    }

}