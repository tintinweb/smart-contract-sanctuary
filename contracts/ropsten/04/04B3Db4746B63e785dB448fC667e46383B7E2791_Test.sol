/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

contract Test {
    address owner;
    
    uint256 totalSuply = 1;
    uint256 public mintFee = 0.0001 ether;
    
    constructor(address _owner) {
        owner = _owner;
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setMintFee(uint256 _fee) public onlyOwner {
        mintFee = _fee;
    }

    function mint() payable public {
        require(msg.value >= mintFee, "fee is lower than mintFee");
        payable(owner).transfer(msg.value);
   }
}