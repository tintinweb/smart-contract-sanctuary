/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity <0.6.5;
contract HelloRopsten {
    string public _string;
    constructor() public {
        _string = 'I will survive!';
    }

    function _updateString(string memory _newString) public {
        _string = string(abi.encodePacked(_newString, ' -: Modified by = ', msg.sender));
    }
}