pragma solidity ^0.4.24;

import "./TokenVesting.sol";


/**
 * @title TokenVestingFactory
 * @dev A factory to deploy instances of TokenVesting for RSR, nothing more. 
 */
contract TokenVestingFactory  {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokenVestingDeployed(address indexed location, address indexed recipient);


  constructor() public {}

  function deployVestingContract(address recipient, uint256 startVestingInThisManySeconds, uint256 vestForThisManySeconds) public returns (address) {
    TokenVesting vesting = new TokenVesting(
        recipient, 
        block.timestamp, 
        startVestingInThisManySeconds, 
        vestForThisManySeconds
    );

    emit TokenVestingDeployed(address(vesting), recipient);
  }
}
