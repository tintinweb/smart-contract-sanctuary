pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./interface/IVault.sol";
import "./interface/INoMintRewardPool.sol";

contract Reader {

  function getAllInformation(address who, address[] memory vaults, address[] memory pools)
  public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    return (unstakedBalances(who, vaults), stakedBalances(who, pools), vaultSharePrices(vaults));
  }

  function unstakedBalances(address who, address[] memory vaults) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IVault(vaults[i]).balanceOf(who);
    }
    return result;
  }

  function stakedBalances(address who, address[] memory pools) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](pools.length);
    for (uint256 i = 0; i < pools.length; i++) {
      result[i] = INoMintRewardPool(pools[i]).balanceOf(who);
    }
    return result;
  }

  function underlyingBalances(address who, address[] memory vaults) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IERC20(IVault(vaults[i]).underlying()).balanceOf(who);
    }
    return result;
  }

  function vaultSharePrices(address[] memory vaults) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IVault(vaults[i]).getPricePerFullShare();
    }
    return result;
  }

  function underlyingBalanceWithInvestmentForHolder(address who, address[] memory vaults)
  public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IVault(vaults[i]).underlyingBalanceWithInvestmentForHolder(who);
    }
    return result;
  }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.5.16;

import "../../public/contracts/base/interface/IVault.sol";

pragma solidity 0.5.16;

import "../../public/contracts/base/interface/INoMintRewardPool.sol";

pragma solidity 0.5.16;

interface IVault {

    function initializeVault(
      address _storage,
      address _underlying,
      uint256 _toInvestNumerator,
      uint256 _toInvestDenominator
    ) external ;

    function balanceOf(address) external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function announceStrategyUpdate(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

pragma solidity 0.5.16;

interface INoMintRewardPool {
    function withdraw(uint) external;
    function getReward() external;
    function stake(uint) external;
    function balanceOf(address) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function exit() external;

    function rewardDistribution() external view returns (address);
    function lpToken() external view returns(address);
    function rewardToken() external view returns(address);

    // only owner
    function setRewardDistribution(address _rewardDistributor) external;
    function transferOwnership(address _owner) external;
    function notifyRewardAmount(uint256 _reward) external;
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
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}