// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Ownable.sol";

import "./CycleSign.sol";
import "./Deposit.sol";
import "./Send.sol";
import "./Withdraw.sol";
contract Staking is Ownable,CycleSign,Deposit,Send,Withdraw{
    using SafeMath for uint256;
  
}