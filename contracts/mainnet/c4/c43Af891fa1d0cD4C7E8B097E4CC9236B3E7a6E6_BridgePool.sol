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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IBridgePool.sol';

contract BridgePool is IBridgePool {

    address public owner;

    /*
      operator modes:
        1 - contract:creator
        2 - contract:withdrawer
        4 - withdrawer
        8 - taker
    */
    mapping(address => uint8) public operator;
    mapping(bytes32 => bool) public withdrawn;

    bool private entered = false;
    modifier nonReentrant() {
        require(!entered, 'reentrant call');
        entered = true;
        _;
        entered = false;
    }

    constructor () {
        owner = tx.origin;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, 'forbidden');
        owner = newOwner;
    }

    function setOperatorMode(address account, uint8 mode) external {
        require(msg.sender == owner, 'forbidden');
        operator[account] = mode;
    }

    function deposit(IERC20 token, uint amount, uint8 to, bool bonus, bytes calldata recipient) override external payable nonReentrant() {
        // allowed only direct call or 'contract:creator' or 'contract:withdrawer'
        require(tx.origin == msg.sender || (operator[msg.sender] & (1 | 2) > 0), 'call from unauthorized contract');
        require(address(token) != address(0) && amount > 0 && recipient.length > 0, 'invalid input');

        if (address(token) == address(1)) {
            require(amount == msg.value, 'value must equal amount');
        } else {
            safeTransferFrom(token, msg.sender, address(this), amount);
        }

        emit Deposited(msg.sender, address(token), to, amount, bonus, recipient);
    }

    function withdraw(Withdraw[] calldata ws) override external nonReentrant() {
        // allowed only 'withdrawer' or 'withdrawer' through 'contract:withdrawer'
        require(operator[msg.sender] == 4 || (operator[tx.origin] == 4 && operator[msg.sender] == 2), 'forbidden');

        for (uint i = 0; i < ws.length; i++) {
            Withdraw memory w = ws[i];

            require(!withdrawn[w.id], 'already withdrawn');
            withdrawn[w.id] = true;

            if (address(w.token) == address(1)) {
                require(address(this).balance >= w.amount + w.bonus, 'too low token balance');
                (bool success, ) = w.recipient.call{value: w.amount}('');
                require(success, 'native transfer error');
            } else {
                require(
                    w.token.balanceOf(address(this)) >= w.amount && address(this).balance >= w.bonus,
                    'too low token balance'
                );
                safeTransfer(w.token, w.recipient, w.amount);
            }

            if (w.bonus > 0) {
                // may fail on contracts
                w.recipient.call{value: w.bonus}('');
            }

            if (address(w.token) != address(1) && w.feeAmounts.length > 0) {
                for (uint j = 0; j < w.feeAmounts.length; j++) {
                    require(w.token.balanceOf(address(this)) >= w.feeAmounts[i], 'too low token balance');
                    safeTransfer(w.token, w.feeTargets[i], w.feeAmounts[i]);
                }
            }

            emit Withdrawn(w.id, address(w.token), w.recipient, w.amount);
        }
    }

    function take(IERC20 token, uint amount, address payable to) external override nonReentrant() {
        // allowed only 'taker'
        require(operator[msg.sender] == 8, 'forbidden');
        if (address(token) == address(1)) {
            to.transfer(amount);
        } else {
            safeTransfer(token, to, amount);
        }
    }

    receive() external payable {}

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBridgePool {
    struct Withdraw {
        bytes32 id;
        IERC20 token;
        uint amount;
        uint bonus;
        address payable recipient;
        uint[] feeAmounts;
        address[] feeTargets;
    }

    event Deposited(address indexed sender, address indexed token, uint8 indexed to, uint amount, bool bonus, bytes recipient);
    event Withdrawn(bytes32 indexed id, address indexed token, address indexed recipient, uint amount);

    function operator(address account) external view returns (uint8 mode);
    function deposit(IERC20 token, uint amount, uint8 to, bool bonus, bytes calldata recipient) external payable;
    function withdraw(Withdraw[] memory ws) external;
    function take(IERC20 token, uint amount, address payable to) external;
}