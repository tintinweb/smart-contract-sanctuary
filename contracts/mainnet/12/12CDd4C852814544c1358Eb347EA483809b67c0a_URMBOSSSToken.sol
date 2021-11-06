pragma solidity ^0.8.0;

import "ERC20.sol";

contract URMBOSSSToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20 ("URMBOSSSToken", "UBT"){
        _mint(msg.sender, initialSupply);
    }
}