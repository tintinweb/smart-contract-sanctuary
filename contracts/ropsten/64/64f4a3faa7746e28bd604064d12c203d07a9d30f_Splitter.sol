pragma solidity ^0.4.24;

contract Splitter {
    address bruno = 0x12b42cbA8c2b12bFFf784C817a7b1Fb6bf6d6C7b;
    address charlie = 0x200DF4951eE68C571Cf8A4c29129D2F561BABd4D;
    
    function splitEther() external payable {
        //This will split the amount in half.
        //For an uneven amount of Ether there will be 1 wei leftover, which the contract will retain.
        //This is OK for this practice contract.
        bruno.transfer(msg.value / 2);
        charlie.transfer(msg.value / 2);
    }
}