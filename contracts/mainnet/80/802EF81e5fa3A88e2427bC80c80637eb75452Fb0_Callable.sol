/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Callable {
    address public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() payable {
        owner = msg.sender;
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}