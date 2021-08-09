pragma solidity ^0.8.0;
import "./ERC20.sol";

contract FinnToken is ERC20
{ 
    uint public INITIAL_SUPPLY =  5000000000 * (10  ** 18); 
    constructor() public ERC20("Finn Token","Finn")
    { 
        _mint(msg.sender, INITIAL_SUPPLY); 
    } 
}