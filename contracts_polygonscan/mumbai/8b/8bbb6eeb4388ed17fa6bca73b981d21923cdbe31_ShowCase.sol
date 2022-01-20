/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity >=0.4.22;

contract ShowCase {

    string[] internal links;
    uint public length = 0;

    function addLink(string memory link) public {
        
        links.push(link);
        length+=1;
    }

    function getLink(uint index) public view returns(string memory) {
        return links[index];
    }


}