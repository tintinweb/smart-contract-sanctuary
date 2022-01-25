/**
 *Submitted for verification at FtmScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Extended {
	function setExtended(address _extended) external;
}

contract rarity_extended_proxy_deployer {

    event Deployed(address);

    fallback() external payable {}
    receive() external payable {}

    function deploy(bytes memory _code, address _extended) public payable returns (address addr) {
        assembly {
            // create(v, p, n)
            // v = amount of ETH to send
            // p = pointer in memory to start of code
            // n = size of code
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }

        // return address 0 on error
        require(addr != address(0), "failed");
		Extended(addr).setExtended(_extended);
        emit Deployed(addr);
    }
}