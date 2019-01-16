pragma solidity 0.4.24;


contract Test1123581321 {
    
    event TransferFunds(address indexed to, uint indexed funds);
    
    function test() public {
        emit TransferFunds(msg.sender, 10000);
    }
    
}