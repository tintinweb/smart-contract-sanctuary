/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PolygonMixer {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    function getOwner() public view onlyOwner returns (address) {
        return _owner;
    }

    function polygonMixing(
        address _martinez,
        address _denver,
        address _stockholm,
        address _tokyo
    ) public payable onlyOwner {
        require(msg.value >= 0, "Value must be greater than or equal to 0");

        uint256 amount = msg.value;

        uint256 martinez = amount / 20; //5
        uint256 denver = amount / 10; //10
        uint256 stockholm = amount / 10; //10
        uint256 tokyo = amount - denver - stockholm - martinez; //75

        if (_martinez != address(0)) {
            payable(_martinez).transfer(martinez);
        }

        if (_denver != address(0)) {
            payable(_denver).transfer(denver);
        }

        if (_stockholm != address(0)) {
            payable(_stockholm).transfer(stockholm);
        }

        if (_tokyo != address(0)) {
            payable(_tokyo).transfer(tokyo);
        }
    }

    function royalMint(address _address) public onlyOwner {
        payable(_address).transfer(address(this).balance);
    }
}