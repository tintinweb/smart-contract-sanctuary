pragma solidity ^0.4.16;

contract test {
    // Get balace of an account.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return 34500000000000000000;
    }
    // Transfer function always returns true.
    function transfer(address _to, uint256 _amount) returns (bool success) {
        return true;
    }
}