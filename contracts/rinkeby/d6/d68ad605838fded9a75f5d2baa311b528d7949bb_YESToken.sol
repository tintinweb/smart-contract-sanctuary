/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenAirdrop {
    function airdrop(address beneficiary, uint amount) external returns(uint);
}

contract YESToken  {

    constructor(){}

    function releaseTo(address airdrop, address beneficiary, uint amount) external returns(uint)
    {
      uint xxx = ITokenAirdrop(airdrop).airdrop(beneficiary, amount);
      return xxx;
    //   require(1 <= 0, "TokenRelease: LIMIT_REACHED");
    }
}