/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity >=0.4.22;

contract ShowCase {

    string[] internal links;
    uint[] internal amounts;

    uint public length = 0;

    address internal owner;


    constructor(){
        owner = msg.sender;
    }




    function addLink(string memory link) public payable {
        
        require(msg.value > 100000000000000000, "Minimum 0.1 Matic Require");

        links.push(link);
        length+=1;
        
        amounts.push(msg.value);

        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

    }

    function getLink(uint index) public view returns(string memory) {
        return links[index];
    }

    function getAmount(uint index) public view returns(uint) {
        return amounts[index];
    }


}