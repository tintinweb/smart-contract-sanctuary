/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract shzo {
    
    address public owner;
    
    //Define a NFT object
    struct Drop {
        string imageUrl;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    
    // ["https://testtest.com/3.png", "Test collection", "This my drop for the month", "twitter", "https://testtest.com","fasfas","0.03", "22",1635790237,1635790237,1,false]
    
    //Create a list of same sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not a owner.");
        _;
    }
    
    //Get the NFT drop objects list
    function getGrops() public view returns (Drop[] memory) {
        return drops;
    }
    
    //Add to the NFT drop objects list
    function addDrop(
        Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length -1;
        users[id] = msg.sender;
    }
    //Update to the NFT drop objects list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not a owner of this Drop.");
            _drop.approved = false;
            drops[_index] = _drop;
        
    }
    //Remove from the NFT drop objects list
    //Approve on NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}