// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity >=0.8.0;

contract DMSTokenTimelock {
    address public recipient =
        address(0xAe2d8BF6333b00f7e3675Ad30Db0565cD7A29e8A);
    uint256 public start = 0;
    uint256 public cycle = 0;
    uint256 public total = 1500;
    uint256 public released = 0;
    uint256 public lock = 60 * 1;
    IERC20 private _dmsToken =
        IERC20(address(0x1275b8448ED49730b1F897AB5a3E2995B237E3d9));

    uint256[8] amounts = [uint256(0), 300, 200, 200, 200, 200, 200, 200];
    uint256[8] times = [
        uint256(0),
        4 * lock,
        (4 + 3 * 1) * lock,
        (4 + 3 * 2) * lock,
        (4 + 3 * 3) * lock,
        (4 + 3 * 4) * lock,
        (4 + 3 * 5) * lock,
        (4 + 3 * 6) * lock
    ];

    constructor() {
        start = block.timestamp + (lock * 2);
    }

    function setRecipient(address _recipient) public returns (bool) {
        recipient = _recipient;
        return true;
    }

    function setStart(uint256 _start) public returns (bool) {
        start = block.timestamp + (lock * _start);
        return true;
    }

    function calc() public view returns (uint256, uint256) {
        if (released >= total) {
            return (0, cycle);
        }
        if (block.timestamp <= start) {
            return (0, cycle);
        }
        uint256 sub = block.timestamp - start;
        uint256 curr = 0;
        uint256 len = times.length - 1;
        for (uint256 i = 0; i <= len; i++) {
            if (sub > times[len - i]) {
                curr = len - i;
                break;
            }
        }
        uint256 amount = amounts[curr];
        if (amount == 0) {
            return (0, cycle);
        }
        if (curr <= cycle && cycle > 0) {
            return (0, cycle);
        }
        return (amount, curr);
    }

    function release() external payable returns (uint256) {
        uint256 _unreleased;
        uint256 _cycle;
        (_unreleased, _cycle) = calc();
        require(_unreleased > 0, "unreleased is zero");
        cycle = _cycle;
        released = released + _unreleased;
        bool sent = _dmsToken.transfer(recipient, _unreleased * (10**6));
        require(sent, "Token transfer failed");
        return _unreleased;
    }

    function balance() public view returns (uint256) {
        return _dmsToken.balanceOf(address(this));
    }

    function complete() external payable returns (bool) {
        require(cycle >= 7, "time lock not end");
        uint256 _balance = balance();
        require(_balance > 0, "balance is zero");
        bool sent = _dmsToken.transfer(recipient, _balance);
        require(sent, "Token transfer failed");
        return true;
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

