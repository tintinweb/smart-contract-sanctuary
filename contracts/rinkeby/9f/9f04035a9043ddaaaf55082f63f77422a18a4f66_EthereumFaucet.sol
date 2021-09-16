/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EthereumFaucet {

    function donate() public payable {
        
    }

    function getEther(address payable _receiver, uint amount) public {
        require(address(this).balance >= amount);
        
        bool sent = _receiver.send(amount);
        require(sent);

    }
}