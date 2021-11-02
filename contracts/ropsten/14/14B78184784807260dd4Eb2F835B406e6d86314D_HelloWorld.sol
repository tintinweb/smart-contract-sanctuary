/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

pragma solidity >=0.4.22 <0.6.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract HelloWorld {
    
    string private name = "yushu";
    
    event HelloWorldEvent(address from);
    
    function setName(string memory _name) public {
        emit HelloWorldEvent(msg.sender);
        emit HelloWorldEvent(address(this));
        name = _name;
    }
    
    function getName() public view returns(string memory _name) {
        return name;
    }
    
}