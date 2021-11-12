/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ShillPortal {

    // ATTRIBUTES

    struct Shill {
        uint id;
        uint timestamp;
        string emoji;
        string title;
        string body;
        address shiller;
    }

    Shill[] public shills;

    event newShill(uint id, uint timestamp, address indexed from, string emoji, string title, string body);
    event newAllowance(uint timestamp, address indexed from, uint shillId);

    address public owner;
    uint public totalShills;
    
    uint public shillCost = 0.1 ether;
    uint public viewCost = 0.1 ether;
    uint public usernameCost = 0.1 ether;

    mapping (address => string) public usernames;
    mapping (address => uint[]) public allowedShills;
    mapping (address => uint) public publications;
    mapping (address => uint) public upvotes;
    mapping (address => uint) public downvotes;

    // FUNCTIONS

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function shill(string memory _emoji, string memory _title, string memory _body) public payable {
        require(msg.value >= shillCost);
        shills.push(Shill(totalShills, block.timestamp, _emoji, _title, _body, msg.sender));
        emit newShill(totalShills, block.timestamp, msg.sender, _emoji, _title, _body);  
        publications[msg.sender]++;
        totalShills++;
    }

    // function tip(address _to) public payable {
    //     payable(_to).transfer(msg.value);
    // }

    function viewShill(uint _shillId) public payable {
        require(msg.value >= viewCost);
        allowedShills[msg.sender].push(_shillId);
        emit newAllowance(block.timestamp,  msg.sender, _shillId);
    }

    function upvote(uint _shillId) public {
        upvotes[shills[_shillId].shiller]++;
    }

    function downvote(uint _shillId) public {
        downvotes[shills[_shillId].shiller]++;
    }

    function getRating(address _from) public view returns (uint) {
        return upvotes[_from] / downvotes[_from];
    }

    // function getShillsFrom(address _from) public view returns(Shill[] memory) {
    //     Shill[] memory shillsFrom;
    //     for (uint i = 0; i < shills.length; i++) {
    //         if (shills[i].shiller == _from) {
    //             shillsFrom.push(shills[i]);
    //         }
    //     }
    //     return shillsFrom;
    // }

    function getAllowedShills() public view returns(Shill[] memory) {
        uint size = allowedShills[msg.sender].length;
        Shill[] memory allowed = new Shill[](size);
        for (uint i = 0; i < size; i++) {
            allowed[i] = shills[allowedShills[msg.sender][i]];
        }
        return allowed;
    }

    function getAllShills() public view returns(Shill[] memory) {
        return shills;
    }

    function getTotalShills() public view returns(uint) {
        return totalShills;
    }

    function getUsername(address _from) public view returns (string memory) {
        return usernames[_from];
    }

    function setUsername(string memory _username) public payable {
        require(msg.value >= usernameCost);
        usernames[msg.sender] = _username;
    }

    // ADMIN SECTION

    function setShillCost(uint _shillCost) public onlyOwner {
        shillCost = _shillCost;
    }

    function setViewCost(uint _viewCost) public onlyOwner {
        viewCost = _viewCost;
    }

    function setUsernameCost(uint _usernameCost) public onlyOwner {
        usernameCost = _usernameCost;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}