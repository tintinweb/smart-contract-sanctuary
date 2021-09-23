// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.6;

import "./interfaces/IFoundation.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Foundation is IFoundation {
  IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

  address public duckStaking = 0x3f93dE882dA8150Dc98a3a1F4626E80E3282df46;
  address public usdpStakingCollector;
  
  address public auction = 0xC6733B8bb1eF64eF450e8fCd8682f6bEc0A5099a;

  uint public constant BASE = 100;

  uint public liquidationFee;
  uint public sfSharesForDuckStaking = 50;
  uint public lfSharesForDuckStaking = 100;

  // Unit multisig initially
  address public gov = 0xae37E8f9a3f960eE090706Fa4db41Ca2f2C56Cb8;

  event Distributed(uint usdpStaking, uint duckStaking);

  modifier auctionOnly() {
    require(msg.sender == auction, "Foundation: !auction");
    _;
  }

  modifier g() {
    require(msg.sender == gov, "Foundation: !gov");
    _;
  }

  constructor (address _usdpStaking) {
    usdpStakingCollector = _usdpStaking;
  }

  function setGov(address _gov) external g {
    gov = _gov;
  }

  function setDuckStaking(address _duckStaking) external g {
    duckStaking = _duckStaking;
  }

  function setUSDPStaking(address _usdpStakingCollector) external g {
    usdpStakingCollector = _usdpStakingCollector;
  }

  function setAuction(address _auction) external g {
    auction = _auction;
  }

  function setSFSharesForDuckStaking(uint _sfSharesForDuckStaking) external g {
    require(_sfSharesForDuckStaking <= BASE, "Foundation: shares > BASE");
    sfSharesForDuckStaking = _sfSharesForDuckStaking;
  }

  function setLFSharesForDuckStaking(uint _lfSharesForDuckStaking) external g {
    require(_lfSharesForDuckStaking <= BASE, "Foundation: shares > BASE");
    lfSharesForDuckStaking = _lfSharesForDuckStaking;
  }

  function submitLiquidationFee(uint fee) external override auctionOnly {
    liquidationFee = liquidationFee + fee;
  }

  function distribute() external override {
    uint usdpBalance = usdp.balanceOf(address(this));

    uint stabilityFee = usdpBalance - liquidationFee;

    uint duckStakingAmount = liquidationFee * lfSharesForDuckStaking / BASE + stabilityFee * sfSharesForDuckStaking / BASE;
    uint usdpStakingAmount = usdpBalance - duckStakingAmount;

    liquidationFee = 0;

    usdp.transfer(usdpStakingCollector, usdpStakingAmount);
    usdp.transfer(duckStaking, duckStakingAmount);

    emit Distributed(usdpStakingAmount, duckStakingAmount);
  }
}

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

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.6;

interface IFoundation {

  function submitLiquidationFee(uint fee) external;

  function distribute() external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
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