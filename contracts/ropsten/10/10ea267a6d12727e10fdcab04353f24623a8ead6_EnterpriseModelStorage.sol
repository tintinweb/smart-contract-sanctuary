/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity >=0.7.0 <0.8.0;

contract EnterpriseModelStorage {

    mapping(address => string) private ledger;

    function store(string memory _value) public {
        ledger[msg.sender] = _value;
    }
    
    function retrieve() public view returns(string memory) {
        return ledger[msg.sender];
    }
}