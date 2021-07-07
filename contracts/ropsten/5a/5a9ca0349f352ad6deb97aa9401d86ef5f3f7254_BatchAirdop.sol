/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.7.0;

contract BatchAirdop {

    function distribute(address[] memory _users, uint256[] memory _values) public payable {
        require(msg.value > 0, "invalid value");
        require(_users.length > 0, "invalid user size");
        require(_users.length == _values.length, "invalid size");


        for(uint256 i = 0; i < _users.length; i++) {
           payable( _users[i]).transfer(_values[i]);
        }
    }


}