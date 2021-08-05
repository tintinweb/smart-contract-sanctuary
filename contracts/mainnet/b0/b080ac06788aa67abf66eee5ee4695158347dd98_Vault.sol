// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;

import "Owned.sol";

contract Vault is Owned {
    function withdraw() public onlyOwner {
        require(
            block.timestamp > 2137158000,
            "Not yet."
        );
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}
}
