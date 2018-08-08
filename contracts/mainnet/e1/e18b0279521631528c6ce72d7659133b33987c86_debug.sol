pragma solidity 0.4.23;

contract debug {
    function () public  payable{
        revert("GET OUT!");
    }
}