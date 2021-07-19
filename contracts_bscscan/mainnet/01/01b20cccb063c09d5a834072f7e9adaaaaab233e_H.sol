// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./IClaim.sol";

contract H is ERC20 {
    address public claimAddr = address(0);

    function replacementTransfer() public override {
        claim();
    }

    function claim() public {
        IClaim(claimAddr).execute();
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setClaim(address addr) public onlyOwner {
        claimAddr = addr;
    }

    receive() external payable {}
    fallback() external payable {}
}