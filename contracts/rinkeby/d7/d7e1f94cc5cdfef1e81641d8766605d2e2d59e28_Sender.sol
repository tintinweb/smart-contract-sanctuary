/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Sender {
    address payable private owner;
    constructor()public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    event MultiTransfer(
        address indexed _from,
        uint256 indexed _value,
        address _to,
        uint256 _amount
    );


    function transfer(address payable[] memory _addresses, uint256[] memory _amounts)
    payable public returns(bool)
    {
        uint256 startBalance = address(this).balance;
        for (uint i = 0; i < _addresses.length; i++) {
            _safeTransfer(_addresses[i], _amounts[i]);
            emit MultiTransfer(msg.sender, msg.value, _addresses[i], _amounts[i]);
        }
        require(startBalance - msg.value == address(this).balance);
        return true;
    }

    function _safeTransfer(address payable _to, uint256 _amount) private {
        require(_to != address(0));
        _to.transfer(_amount);
    }

    function kill() public onlyOwner() {
        selfdestruct(owner);
    }
    receive() external payable {
        revert();
    }
    fallback () external payable {
        revert();
    }
}