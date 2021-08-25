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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IAddressList {
    function add(address a) external returns (bool);

    function remove(address a) external returns (bool);

    function get(address a) external view returns (uint256);

    function contains(address a) external view returns (bool);

    function length() external view returns (uint256);

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IVesperPool.sol";

interface IVFRCoveragePool is IVesperPool {
    function buffer() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IVesperPool.sol";

interface IVFRStablePool is IVesperPool {
    function targetAPY() external view returns (uint256);

    function buffer() external view returns (address);

    function targetPricePerShare() external view returns (uint256);

    function amountToReachTarget(address _strategy) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../bloq/IAddressList.sol";

interface IVesperPool is IERC20 {
    function deposit() external payable;

    function deposit(uint256 _share) external;

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool);

    function excessDebt(address _strategy) external view returns (uint256);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function poolRewards() external returns (address);

    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external;

    function reportLoss(uint256 _loss) external;

    function resetApproval() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function withdrawETH(uint256 _amount) external;

    function whitelistedWithdraw(uint256 _amount) external;

    function governor() external view returns (address);

    function keepers() external view returns (IAddressList);

    function maintainers() external view returns (IAddressList);

    function feeCollector() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function strategy(address _strategy)
        external
        view
        returns (
            bool _active,
            uint256 _interestFee,
            uint256 _debtRate,
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio
        );

    function stopEverything() external view returns (bool);

    function token() external view returns (IERC20);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/vesper/IVFRCoveragePool.sol";
import "../interfaces/vesper/IVFRStablePool.sol";
import "../interfaces/vesper/IVesperPool.sol";

contract VFRBuffer {
    address public token;
    address public stablePool;
    address public coveragePool;
    // Specifies for how long (in seconds) the buffer should be
    // able to cover the stable pool's target APY requirements
    uint256 public coverageTime;

    event CoverageTimeUpdated(uint256 oldCoverageTime, uint256 newCoverageTime);

    constructor(
        address _stablePool,
        address _coveragePool,
        uint256 _coverageTime
    ) {
        address stablePoolToken = address(IVesperPool(_stablePool).token());
        address coveragePoolToken = address(IVesperPool(_coveragePool).token());
        require(stablePoolToken == coveragePoolToken, "non-matching-tokens");

        token = stablePoolToken;
        stablePool = _stablePool;
        coveragePool = _coveragePool;
        coverageTime = _coverageTime;
    }

    function target() external view returns (uint256 amount) {
        uint256 targetAPY = IVFRStablePool(stablePool).targetAPY();
        // Get the current price per share
        uint256 fromPricePerShare = IVFRStablePool(stablePool).pricePerShare();
        // Get the price per share that would cover the stable pool's APY requirements
        uint256 toPricePerShare =
            fromPricePerShare + (fromPricePerShare * targetAPY * coverageTime) / (365 * 24 * 3600 * 1e18);
        // Get the amount needed to increase the current price per share to the coverage target
        uint256 totalSupply = IVFRStablePool(stablePool).totalSupply();
        uint256 fromTotalValue = (fromPricePerShare * totalSupply) / 1e18;
        uint256 toTotalValue = (toPricePerShare * totalSupply) / 1e18;
        if (toTotalValue > fromTotalValue) {
            amount = toTotalValue - fromTotalValue;
        }
    }

    function request(uint256 _amount) public {
        // Make sure the requester is a valid strategy (either a stable pool one or a coverage pool one)
        (bool activeInStablePool, , , , , , , ) = IVFRStablePool(stablePool).strategy(msg.sender);
        (bool activeInCoveragePool, , , , , , , ) = IVFRCoveragePool(coveragePool).strategy(msg.sender);
        require(activeInStablePool || activeInCoveragePool, "invalid-strategy");
        // Make sure enough funds are available
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= _amount, "insufficient-balance");
        IERC20(token).transfer(msg.sender, _amount);
    }

    function flush() public {
        require(IVFRStablePool(stablePool).keepers().contains(msg.sender), "not-a-keeper");
        // Transfer any outstanding funds to the coverage pool
        IERC20(token).transfer(coveragePool, IERC20(token).balanceOf(address(this)));
    }

    function updateCoverageTime(uint256 _coverageTime) external {
        require(IVFRStablePool(stablePool).keepers().contains(msg.sender), "not-a-keeper");
        emit CoverageTimeUpdated(coverageTime, _coverageTime);
        coverageTime = _coverageTime;
    }
}

{
  "evmVersion": "istanbul",
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