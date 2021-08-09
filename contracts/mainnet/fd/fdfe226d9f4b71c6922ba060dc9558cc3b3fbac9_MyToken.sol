pragma solidity ^0.8.0;
import "./ERC20.sol";
contract MyToken is ERC20{
    uint public INITIAL_SUPPLY = 20000000000000000000000000000;
    
    constructor() public ERC20("Apex Market Project","APEX"){
        _mint(msg.sender, INITIAL_SUPPLY); 
    }
}