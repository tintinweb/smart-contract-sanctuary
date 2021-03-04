pragma solidity ^0.7.0;

import "Context.sol";
import "IERC20.sol";
import "ERC20.sol";
import "Ownable.sol";
import "SWNStake.sol";



contract SWNToken is Context, ERC20, SWNStake {
  constructor() ERC20("SweneToken","SWN") {
  }
}