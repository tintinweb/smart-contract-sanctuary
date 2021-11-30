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

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract LoserDaoTreasury {
    address public contractOwner;

    address public loserDaoToken;
    address public lowbToken;

    uint256 public totalStockDaoToken = 0;

    uint256 public totalLoserDaoBonus = 0;

    uint256 public remainBonus;

    mapping(uint256 => uint256) public treasuryMap;

    mapping(address => uint256) public pendingWithdrawals;

    mapping(address => uint256) public loserDaoTokenPendingWithdrawals;


    mapping(address => uint256) public claimBonus;

    uint public claimTimeStamp;

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address loserDaoToken_, address lowbToken_) {
        loserDaoToken = loserDaoToken_;
        lowbToken = lowbToken_;
        contractOwner = msg.sender;
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "You deposit nothing!");
        IERC20 token = IERC20(lowbToken);
        require(
            token.transferFrom(tx.origin, address(this), amount),
            "Lowb transfer failed"
        );
        pendingWithdrawals[tx.origin] += amount;
    }

    function withdraw(uint256 amount) public {
        require(
            amount <= pendingWithdrawals[tx.origin],
            "amount larger than that pending to withdraw"
        );
        pendingWithdrawals[tx.origin] -= amount;
        IERC20 token = IERC20(lowbToken);
        require(token.transfer(tx.origin, amount), "Lowb transfer failed");
    }

    function depositLoserDaoToken(uint256 amount) public {
        require(amount > 0, "You deposit nothing!");
        IERC20 token = IERC20(loserDaoToken);
        require(
            token.transferFrom(tx.origin, address(this), amount),
            "Lowb transfer failed"
        );
        loserDaoTokenPendingWithdrawals[tx.origin] += amount;
    }

    function withdrawLoserDaoToken(uint256 amount) public {
        require(block.timestamp - claimTimeStamp > 1 weeks, "you can not withdraw now");
        require(
                amount <= loserDaoTokenPendingWithdrawals[tx.origin],
                "amount larger than that pending to withdraw"
            );

        loserDaoTokenPendingWithdrawals[tx.origin] -= amount;
        IERC20 token = IERC20(loserDaoToken);
        require(token.transfer(tx.origin, amount), "LoserDao Token transfer failed");
    }

    function swapLoserDaoTokenFromLowb(uint256 amount) public {
        require(
            amount <= pendingWithdrawals[tx.origin],
            "amount larger than that pending to swapLoserDaoToken"
        );
        pendingWithdrawals[tx.origin] -= amount;
        uint256 loserDaoTokenAmount = amount / 1000;
        IERC20 token = IERC20(loserDaoToken);
        require(
            token.transfer(tx.origin, loserDaoTokenAmount),
            "LoserDaoToken transfer failed"
        );
        totalStockDaoToken -= loserDaoTokenAmount;
    }

    function swapLowbformLoserDao(uint256 amount) public {
        IERC20 token = IERC20(loserDaoToken);
        require(
            token.transfer(address(this), amount),
            "LoserDaoToken transfer failed"
        );
        uint256 lowbAmount = amount * 1000;
        pendingWithdrawals[tx.origin] += lowbAmount;
        totalStockDaoToken += amount;
    }

    function sendLoserDaoBonus(uint256 balance_) public {
        require(balance_ > 0, "balance need > 0");
        require(
            pendingWithdrawals[tx.origin] >= balance_,
            "you do not desposit enough lowb"
        );
        pendingWithdrawals[tx.origin] -= balance_;
        totalLoserDaoBonus += balance_;
        remainBonus += balance_;
    }

    function claimLoserDaoBonus(uint256 amount) public {
        require(block.timestamp - claimTimeStamp > 0, "now you can not claim"); 
        require(block.timestamp - claimTimeStamp < 1 weeks, "now you can not claim, time is over"); 
        require(
            loserDaoTokenPendingWithdrawals[tx.origin] >= amount,
            "you do not desposit enough loserdaoToken"
        );

        IERC20 token = IERC20(loserDaoToken);
        uint256 claimLowb = (totalLoserDaoBonus * amount) / token.totalSupply();
        require(
            remainBonus >= claimLowb,
            "do not remain enough lowb"
        );
        
        pendingWithdrawals[tx.origin] += claimLowb;
        remainBonus -= claimLowb;
    }

    function startClaim(bool start) public onlyOwner {
        if (start) {
            claimTimeStamp = block.timestamp;
        } else {
            claimTimeStamp = 0;
        }
    }
}