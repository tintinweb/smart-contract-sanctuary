/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Imetal{
    function _mint(address account, uint256 amount) external;

}
contract SpaceGame{
    address private ercmetal = 0xF266A75FeAB5ADB0a1637178b5f75665b379FAfe;

    function miningMetal(address miner, uint minedAmount) public{
        address _ercmetal = ercmetal;
        Imetal(_ercmetal)._mint(miner, minedAmount);
    }


}