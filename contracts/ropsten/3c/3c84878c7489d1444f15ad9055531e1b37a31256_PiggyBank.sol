/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract PiggyBank {
    
    address payable public user = payable(0x552C92e041d6eb45b310BB33330d65056a011BB1); // indirizzo dell'utente proprietario (es: nipotino)
    uint256 public last_deposit_time; // data e ora dell'ultimo deposito
    
    function deposit() public payable {
        last_deposit_time = block.timestamp;
    }
    
    function withdraw() public {
        require( block.timestamp > last_deposit_time + 2 minutes, "Hai troppa fretta!" );
        user.transfer( address(this).balance );
    }
}