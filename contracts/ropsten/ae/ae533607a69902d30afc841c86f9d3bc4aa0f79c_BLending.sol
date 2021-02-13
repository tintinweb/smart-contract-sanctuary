/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.6.0;

contract BLending {
    
    struct Borrowers{
        uint256 ethdeposited;
        bool withdraw;
    }
    
    mapping(address => Borrowers) borrower;
    address[] public borrowerAccts;
    
    event addFund(address, uint256);
    
    function addFunds(address _address, uint256 _ethdeposited) external payable {
        Borrowers storage brw = borrower[_address];
        brw.ethdeposited += msg.value;
        brw.withdraw=false;
        borrowerAccts.push(_address);
        emit addFund(_address, msg.value);
    }
    
    function withdrawFunds(address _tobrw) public {
        require(borrower[_tobrw].withdraw == false);
        uint256 _ethdeposited = borrower[_tobrw].ethdeposited;
        _tobrw.call.value(_ethdeposited)("");
        borrower[_tobrw].ethdeposited = 0;
        borrower[_tobrw].withdraw = true;
    }
    
    function getBorrower(address _address) view public returns (uint256, bool) {
        return(borrower[_address].ethdeposited, borrower[_address].withdraw);
    }
}