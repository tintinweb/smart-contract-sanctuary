// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import { ILido } from './interfaces/ILido.sol';

/**
 * @title lido staking contract
 * @author danilo neves cruz
 * @notice this contract can be used to stake ETH and withdraw liquid stETH
 */
contract Staker {
  /** @notice lido+stETH contract address */
  ILido public immutable lido;

  /** @notice track each user share of the staking pool */
  mapping(address => uint256) public shares;

  /** @param lido_ lido+stETH contract address */
  constructor(ILido lido_) {
    lido = lido_;
  }

  /** @notice stakes all received ETH on lido and stores sender shares */
  receive() external payable {
    shares[msg.sender] += lido.submit{ value: msg.value }(address(0));
  }

  /** @notice stakes all received ETH on lido and stores sender shares */
  fallback() external payable {
    revert('no data for me, thanks');
  }

  /**
   * @notice transfers stETH to user and deduct it from their shares
   * @param amount stETH amount to withdraw
   */
  function withdraw(uint256 amount) external {
    uint256 totalShares = shares[msg.sender];
    uint256 withdrawShares = lido.getSharesByPooledEth(amount);
    require(totalShares >= withdrawShares, 'withdraw amount exceeds share');
    unchecked {
      shares[msg.sender] = totalShares - withdrawShares;
    }
    lido.transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ILido is IERC20 {
  function submit(address referral) external payable returns (uint256 stETH);

  function sharesOf(address account) external view returns (uint256 shares);

  function getSharesByPooledEth(uint256 amount) external view returns (uint256 shares);
}

{
  "evmVersion": "london",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}