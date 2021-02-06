/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity >=0.7.0 <0.8.0;

contract CorporateSharedLedger {

    mapping(address => string) private ledger;

    function store(string memory _value) public {
        ledger[msg.sender] = _value;
    }
    
    function retrieve(address _user) public view returns(string memory) {
        return ledger[_user];
    }
    
    function share() public view returns(address) {
        return msg.sender;
    }
}