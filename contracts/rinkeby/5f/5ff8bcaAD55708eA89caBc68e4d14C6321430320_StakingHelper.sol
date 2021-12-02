/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// SPDX-License-Identifier: MIT

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


// File contracts/interfaces/IStaking.sol

pragma solidity ^0.7.6;

interface IStaking {
  function stake(uint256 _amount, address _recipient) external returns (bool);

  function claim(address _recipient) external;
}


// File contracts/StakingHelper.sol

pragma solidity ^0.7.6;


contract StakingHelper {
  address public immutable staking;
  address public immutable SATO;

  constructor(address _staking, address _SATO) {
    require(_staking != address(0));
    staking = _staking;
    require(_SATO != address(0));
    SATO = _SATO;
  }

  function stake(uint256 _amount) external {
    IERC20(SATO).transferFrom(msg.sender, address(this), _amount);
    IERC20(SATO).approve(staking, _amount);
    IStaking(staking).stake(_amount, msg.sender);
    IStaking(staking).claim(msg.sender);
  }
}