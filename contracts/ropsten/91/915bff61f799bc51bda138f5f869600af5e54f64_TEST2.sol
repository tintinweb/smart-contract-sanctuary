// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.0;


import "./ERC20Pausable.sol";
import "./Ownable.sol";

// 72000000000000000000000000 = 72*10**6 * 10**18 - CONFIRMED 2021.06.13 
contract TEST2 is ERC20Pausable, Ownable {
       constructor (
           uint256 initialSupply
           ) ERC20("TestPausable","TESTPAUSABLE") {
               _mint(msg.sender, initialSupply);
           }
           
    function salePause () public onlyOwner {
        // pause the sale
        _pause();
    }
    //function UnPause
    function saleUnPause() public onlyOwner {
        _unpause();
    }
    /*
    function Paused () public view returns (bool) {
        return paused();
    }
    */
}