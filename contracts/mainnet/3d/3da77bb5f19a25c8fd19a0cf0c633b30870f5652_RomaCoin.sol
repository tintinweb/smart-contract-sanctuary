pragma solidity ^0.8.0;

import "ERC20.sol";
contract RomaCoin is ERC20 {
    constructor (uint256  initialsupply) public ERC20 ("RomaCoin", "ROMA"){
        _mint (msg.sender,initialsupply);
    }
}