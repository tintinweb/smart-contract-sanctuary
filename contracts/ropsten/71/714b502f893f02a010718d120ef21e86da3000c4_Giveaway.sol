/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Giveaway {

    address private owner;
    address private winnerA;
    string private winnerT;
    bool paid;

    uint256 number;
    uint256 prize;
    int entries;
    int maxEntries;

    mapping(string => address) private addresses;
    mapping(address=> string) private handles;
    string[] private list;




    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor(uint256 _prize) payable {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        maxEntries = 10;
        paid = false;
        prize = _prize;
    }
    

    function enterGivaway(string memory handle) public {
        require(entries <= maxEntries, "Maximum number of entries reached");
        require(bytes(handle).length > 0, "Please enter your twitter handle");
        require(addresses[handle] == address(0x0), "This Handle already entered the giveaway");
        require(bytes(handles[msg.sender]).length == 0, "This Address already entered the giveaway");
 
        handles[msg.sender] = handle;
        addresses[handle] = msg.sender;
        list.push(handle);
        entries += 1;

    }

    function getEntries() public view returns (int){
        return entries;
    }

    function getAllHandles() public view returns (string [] memory){
        return list;
    }

    function chooseWinner(uint256 index) public isOwner{

        winnerT = list[index];
        winnerA = addresses[winnerT];

    }

    function payWinner() public isOwner{
        require(winnerA != address(0x0), "Winner has not been chosen");

        payable(winnerA).transfer(0.01 ether);

        paid = true;

    }

    function setPrize(uint256 _prize) public isOwner{
        prize = _prize;
    }

    function resetGivaway() public isOwner{
        require(paid, "Giveaway not complete");

        winnerA = address(0x0);
        winnerT = '';
        delete list;

    }

    function withdrawAll() public isOwner{
        payable(owner).transfer(address(this).balance);
    }



}