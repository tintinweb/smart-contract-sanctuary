/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity 0.5.17;


contract GovernanceTester {
    address public gov;
    uint256 public value;

    event valueUpdated(
        address indexed governance,
        address indexed sender,
        uint256 v
    );

    modifier onlyGov() {
        require(msg.sender == gov, "Only Governance should be able to hit");
        _;
    }

    constructor(address _gov, uint256 _val) public {
        gov = _gov;
        value = _val;
    }

    function update(uint256 _value) public onlyGov() {
        value = _value;
        emit valueUpdated(gov, msg.sender, _value);
    }
}