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

    uint256 public totalStockLowb = 0;

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

    event SwapDaoTokenToLowb(address swapper, uint lowbAmount, uint daoTokenAmount);
    event SwapLowbToDaoToken(address swapper, uint lowbAmount, uint daoTokenAmount);
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

    function startUpLoserDao(uint256 amount) public onlyOwner {
        require(amount > 0, "You startUpLoserDao nothing!");
        IERC20 token = IERC20(loserDaoToken);
        require(
            token.transferFrom(tx.origin, address(this), amount),
            "DaoToken transfer failed"
        );
        totalStockDaoToken += amount;
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

    function swapLowbToLoserDaoToken(uint256 amount) public {
        require(
            amount <= pendingWithdrawals[tx.origin],
            "amount larger than that pending to swapLoserDaoToken"
        );
        uint256 loserDaoTokenAmount = amount / 1000;
        require(totalStockDaoToken >= loserDaoTokenAmount, "stock do not have enough LoserDaoToken");

        pendingWithdrawals[tx.origin] -= amount;
        IERC20 token = IERC20(loserDaoToken);
        require(
            token.transfer(tx.origin, loserDaoTokenAmount),
            "LoserDaoToken transfer failed"
        );
        totalStockDaoToken -= loserDaoTokenAmount;
        totalStockLowb += amount;
        emit SwapLowbToDaoToken(tx.origin, amount, loserDaoTokenAmount);
    }

    function swapLoserDaoTokenToLowb(uint256 amount) public {
        uint256 lowbAmount = amount * 1000;
        require(totalStockLowb >= lowbAmount, "stock do not have enough lowb");
        IERC20 token = IERC20(loserDaoToken);
        require(
            token.transferFrom(tx.origin, address(this), amount),
            "LoserDaoToken transfer failed"
        );
        
        pendingWithdrawals[tx.origin] += lowbAmount;
        totalStockDaoToken += amount;
        totalStockLowb -= lowbAmount;
        emit SwapDaoTokenToLowb(tx.origin, lowbAmount, amount);
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