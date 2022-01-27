// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "Strings.sol";

contract RateSupervisor{
    mapping(string => string[]) public comments;
    string[] public names;
    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }

    function getComments(string memory name) public view returns (string[] memory)  {
        return comments[name];
    }
    function addComment(string memory name, string memory comment) public{
        comments[name].push(comment);
        names.push(name);
    }
    function addCommentsTest(uint nameN, uint commentN) public{
        for(uint namei=0;namei<nameN;namei++){
            string memory name=Strings.toString(namei);
            name=string(abi.encodePacked("sup-", name));
            names.push(name);
            for(uint comi=0;comi<commentN;comi++){
                string memory com=Strings.toString(comi);
                com=string(abi.encodePacked("com-", com));
                addComment(name,com);
            }
        }
    }
}