/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/interfaces/IERC20.sol

pragma solidity ^0.7.6;

interface IERC20 {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/StakingWarmup.sol

pragma solidity ^0.7.6;

contract StakingWarmup {
  address public immutable staking;
  address public immutable xSATO;

  constructor(address _staking, address _xSATO) {
    require(_staking != address(0));
    staking = _staking;
    require(_xSATO != address(0));
    xSATO = _xSATO;
  }

  function retrieve(address _staker, uint256 _amount) external {
    require(msg.sender == staking);
    IERC20(xSATO).transfer(_staker, _amount);
  }
}