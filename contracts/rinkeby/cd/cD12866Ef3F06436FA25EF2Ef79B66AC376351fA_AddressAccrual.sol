// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import {Ownable} from "../lib/Ownable.sol";

import {IERC20} from "../token/IERC20.sol";

import {Accrual} from "./Accrual.sol";

contract AddressAccrual is Ownable, Accrual {

    uint256 public _supply = 0;

    mapping(address => uint256) public balances;

    constructor(
        address _claimableToken
    )
        public
        Accrual(_claimableToken)
    {}

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _supply;
    }

    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
        return balances[account];
    }

    function getTotalBalance()
        public
        view
        returns (uint256)
    {
        return totalSupply();
    }

    function getUserBalance(
        address owner
    )
        public
        view
        returns (uint256)
    {
        return balanceOf(owner);
    }

    function increaseShare(
        address to,
        uint256 value
    )
        public
        onlyOwner
    {
        require(to != address(0), "Cannot add zero address");

        balances[to] = balances[to].add(value);
        _supply = _supply.add(value);
    }

    function decreaseShare(
        address from,
        uint256 value
    )
        public
        onlyOwner
    {
        require(from != address(0), "Cannot remove zero address");

        balances[from] = balances[from].sub(value);
        _supply = _supply.sub(value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

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
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
// Modified from https://github.com/iearn-finance/audit/blob/master/contracts/yGov/YearnGovernanceBPT.sol

pragma solidity ^0.5.16;

import {IERC20} from "../token/IERC20.sol";

import {SafeMath} from "../lib/SafeMath.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";

/**
 * @title Accrual is an abstract contract which allows users of some
 *        distribution to claim a portion of tokens based on their share.
 */
contract Accrual {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public accrualToken;

    uint256 public accruedIndex = 0; // previously accumulated index
    uint256 public accruedBalance = 0; // previous calculated balance

    mapping(address => uint256) public supplyIndex;

    constructor(
        address _accrualToken
    )
        public
    {
        accrualToken = IERC20(_accrualToken);
    }

    function getUserBalance(
        address owner
    )
        public
        view
        returns (uint256);

    function getTotalBalance()
        public
        view
        returns (uint256);

    function updateFees()
        public
    {
        if (getTotalBalance() == 0) {
            return;
        }

        uint256 contractBalance = accrualToken.balanceOf(address(this));

        if (contractBalance == 0) {
            return;
        }

        // Find the difference since the last balance stored in the contract
        uint256 difference = contractBalance.sub(accruedBalance);

        if (difference == 0) {
            return;
        }

        // Use the difference to calculate a ratio
        uint256 ratio = difference.mul(1e18).div(getTotalBalance());

        if (ratio == 0) {
            return;
        }

        // Update the index by adding the existing index to the ratio index
        accruedIndex = accruedIndex.add(ratio);

        // Update the accrued balance
        accruedBalance = contractBalance;
    }

    function claimFees()
        public
    {
        claimFor(msg.sender);
    }

    function claimFor(
        address recipient
    )
        public
    {
        updateFees();

        uint256 userBalance = getUserBalance(recipient);

        if (userBalance == 0) {
            supplyIndex[recipient] = accruedIndex;
            return;
        }

        // Store the existing user's index before updating it
        uint256 existingIndex = supplyIndex[recipient];

        // Update the user's index to the current one
        supplyIndex[recipient] = accruedIndex;

        // Calculate the difference between the current index and the old one
        // The difference here is what the user will be able to claim against
        uint256 delta = accruedIndex.sub(existingIndex);

        require(
            delta > 0,
            "TokenAccrual: no tokens available to claim"
        );

        // Get the user's current balance and multiply with their index delta
        uint256 share = userBalance.mul(delta).div(1e18);

        // Transfer the tokens to the user
        accrualToken.safeTransfer(recipient, share);

        // Update the accrued balance
        accruedBalance = accrualToken.balanceOf(address(this));
    }

}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.16;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
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