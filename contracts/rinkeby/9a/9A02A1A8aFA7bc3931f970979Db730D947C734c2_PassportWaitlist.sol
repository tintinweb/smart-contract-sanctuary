// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {IPermittableERC20} from "../token/IPermittableERC20.sol";

contract PassportWaitlist is Ownable {

    /* ========== Events ========== */

    event UserApplied(
        address indexed _user,
        address _paymentToken,
        uint256 _paymentAmount,
        uint256 _timestamp
    );

    event PaymentSet(
        address _paymentToken,
        uint256 _paymentAmount,
        address _paymentReceiver
    );

    /* ========== Storage ========== */

    IPermittableERC20 public paymentToken;
    uint256           public paymentAmount;
    address payable   public paymentReceiver;

    constructor(
        address _paymentToken,
        uint256 _paymentAmount,
        address payable _paymentReceiver
    ) public {
        setPayment(
            _paymentToken,
            _paymentAmount,
            _paymentReceiver
        );
    }

    /* ========== Admin ========== */

    function setPayment(
        address _paymentToken,
        uint256 _paymentAmount,
        address payable _paymentReceiver
    )
        public
        onlyOwner
    {
        require(
            _paymentAmount > 0,
            "PassportWaitlist: the payment amount must be higher than 0"
        );

        require(
            _paymentReceiver != address(0),
            "PassportWaitlist: payment receiver cannot be address 0"
        );

        paymentToken    = IPermittableERC20(_paymentToken);
        paymentAmount   = _paymentAmount;
        paymentReceiver = _paymentReceiver;

        emit PaymentSet(
            address(paymentToken),
            paymentAmount,
            paymentReceiver
        );
    }

    /* ========== Public Functions ========== */

    /**
     * @notice Pays the fee and signs up for the passport. This action is only recorded at the logs level and not in the storage.
     */
    function applyForPassport() public
    {
        SafeERC20.safeTransferFrom(
            paymentToken,
            msg.sender,
            paymentReceiver,
            paymentAmount
        );

        emit UserApplied(
            msg.sender,
            address(paymentToken),
            paymentAmount,
            currentTimestamp()
        );
    }

    /**
     * @notice Same as `applyForPassport()` but with a permit to avoid making 2 transactions
     */
    function permitApplyForPassport (
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        paymentToken.permit(
            msg.sender,
            address(this),
            paymentAmount,
            _deadline,
            _v,
            _r,
            _s
        );
        applyForPassport();
    }

    function payableApplyForPassport()
        public
        payable
    {
        require(
            address(paymentToken) == address(0),
            "PassportWaitlist: the payment is an erc20"
        );

        require(
            msg.value == paymentAmount,
            "PassportWaitlist: wrong payment amount"
        );

        paymentReceiver.transfer(msg.value);

        emit UserApplied(
            msg.sender,
            address(0),
            paymentAmount,
            currentTimestamp()
        );
    }

    /* ========== Dev Functions ========== */

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract IPermittableERC20 is IERC20 {

    /**
     * @notice Approve token with signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
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

