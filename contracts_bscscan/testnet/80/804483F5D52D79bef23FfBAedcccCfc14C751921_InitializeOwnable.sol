/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

contract InitializeOwnable {
    address internal _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not owner");
        _;
    }

    function setOwner(address _who) public onlyOwner {
        _owner = _who;
    }

    function initializeOwner(address _who) internal {
        _owner = _who;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}