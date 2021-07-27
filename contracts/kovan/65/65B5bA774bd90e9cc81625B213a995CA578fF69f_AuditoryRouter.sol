// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IAuditoryAssetPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuditoryRouter {
    event LiquidityAdded(address user, uint256 amount, address token);
    event LiquidityWithdrawn(address user, uint256 amount);

    receive() external payable {}

    function addLiquidity(
        address _auditoryAssetPool,
        uint256 _amount,
        address _token
    ) external {
        address _senderAddress = msg.sender;
        require(_amount > 0 ether, "Invalid amount: CANNOT BE ZERO");
        //  TODO: check for the exceeding transfer amount
        // uint256 remainingPoolFund = IAuditoryAssetPool(_auditoryAssetPool)
        // .remainingPoolValue();
        // uint256 _amountToDeposit;
        // require(
        //     remainingPoolFund > 0,
        //     "AssetPool is alread been Liquidated enough!"
        // );
        // if (_amount > remainingPoolFund) {
        //     _amountToDeposit = remainingPoolFund;
        // }
        IERC20(_token).transferFrom(
            _senderAddress,
            _auditoryAssetPool,
            _amount
        );
        IAuditoryAssetPool(_auditoryAssetPool).deposit(_senderAddress, _amount);
        emit LiquidityAdded(_senderAddress, _amount, _token);
        // if (_amount > remainingPoolFund)
        //     payable(_senderAddress).transfer(_amount - remainingPoolFund);
    }

    function removeLiquidity(
        address _auditoryAssetPool,
        uint256 _amount,
        address _token
    ) external {
        address _sender = msg.sender;

        IAuditoryAssetPool(_auditoryAssetPool).withdraw(
            _sender,
            _amount,
            _token
        );
        emit LiquidityWithdrawn(_sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAuditoryAssetPool {
    function deposit(address sender, uint256 amount) external;

    function withdraw(
        address recipient,
        uint256 amount,
        address token
    ) external;

    function initialize(address artist, uint256 bondValue) external;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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