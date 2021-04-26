/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

contract test{
    
    struct data{
        string content;
        string what;
        string link;
        string description;
    }
    
    mapping(uint256 => data) public readData;
    uint256[] private ids;
    
    function add(uint256 id,string memory _content,string memory _what,string memory _link,string memory _description) public {
        readData[id] = data({
            content : _content,
            what : _what,
            link : _link,
            description : _description
        });
        
        ids.push(id);
    }
    
    function viewIds() public view returns(uint256[] memory){
        return ids;
    }
}