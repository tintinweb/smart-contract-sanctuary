// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IERC20} from "./IERC20.sol";
import {ICorePool} from "./ICorePool.sol";

contract VotingIlluvium {
    string public constant name = "Voting Illuvium";
    string public constant symbol = "vILV";

    uint256 public constant decimals = 18;

    address public constant ILV = 0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E;
    address public constant ILV_POOL = 0x25121EDDf746c884ddE4619b573A7B10714E2a36;
    address public constant LP_POOL = 0x8B4d8443a0229349A9892D4F7CbE89eF5f843F72;
    address public constant TOKEN_LOCKING = 0xd3b23dBDC485E7559235aBC58c0a3e737e4Aa592;

    function balanceOf(address _account) external view returns (uint256 balance) {
        uint256 ilvBalance = IERC20(ILV).balanceOf(_account);
        uint256 ilvPoolBalance = ICorePool(ILV_POOL).balanceOf(_account);
        uint256 lpPoolBalance = _lpToILV(ICorePool(LP_POOL).balanceOf(_account));
        uint256 lockedBalance = IERC20(TOKEN_LOCKING).balanceOf(_account);

        balance = ilvBalance + ilvPoolBalance + lpPoolBalance + lockedBalance;
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(ILV).totalSupply();
    }

    function _lpToILV(uint256 _lpBalance) internal view returns (uint256 ilvAmount) {
          address _poolToken = ICorePool(LP_POOL).poolToken();

          uint256 totalLP = IERC20(_poolToken).totalSupply();
          uint256 ilvInLP = IERC20(ILV).balanceOf(_poolToken);
          ilvAmount= (ilvInLP * _lpBalance) / totalLP;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPool.sol";

interface ICorePool is IPool {
    function vaultRewardsPerToken() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);

    function stakeAsPool(address _staker, uint256 _amount) external;

    function receiveVaultRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
        // @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    // for the rest of the functions see Soldoc in IlluviumPoolBase

    function silv() external view returns (address);

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function pendingYieldRewards(address _user) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function stake(
        uint256 _amount,
        uint64 _lockedUntil,
        bool useSILV
    ) external;

    function unstake(
        uint256 _depositId,
        uint256 _amount,
        bool useSILV
    ) external;

    function sync() external;

    function processRewards(bool useSILV) external;

    function setWeight(uint32 _weight) external;
}

{
  "optimizer": {
    "enabled": false,
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
  "libraries": {}
}