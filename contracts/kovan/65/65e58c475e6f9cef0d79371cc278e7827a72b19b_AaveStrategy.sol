// SPDX-License-Identifier: UNLICENSED

// The BentoBox

//  ▄▄▄▄· ▄▄▄ . ▐ ▄ ▄▄▄▄▄      ▄▄▄▄·       ▐▄• ▄
//  ▐█ ▀█▪▀▄.▀·█▌▐█•██  ▪     ▐█ ▀█▪▪      █▌█▌▪
//  ▐█▀▀█▄▐▀▀▪▄▐█▐▐▌ ▐█.▪ ▄█▀▄ ▐█▀▀█▄ ▄█▀▄  ·██·
//  ██▄▪▐█▐█▄▄▌██▐█▌ ▐█▌·▐█▌.▐▌██▄▪▐█▐█▌.▐▌▪▐█·█▌
//  ·▀▀▀▀  ▀▀▀ ▀▀ █▪ ▀▀▀  ▀█▄▀▪·▀▀▀▀  ▀█▄▀▪•▀▀ ▀▀

// This contract stores funds, handles their transfers, supports flash loans and strategies.

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./interfaces/IFlashLoan.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "./MasterContractManager.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable not-rely-on-time

/// @title BentoBox
/// @author BoringCrypto, Keno
/// @notice The BentoBox is a vault for tokens. The stored tokens can be flash loaned and used in strategies.
/// Yield from this will go to the token depositors.
/// Rebasing tokens ARE NOT supported and WILL cause loss of funds.
/// Any funds transfered directly onto the BentoBox will be lost, use the deposit function instead.
contract BentoBox is MasterContractManager, BoringBatchable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    event LogDeposit(IERC20 indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogWithdraw(IERC20 indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogTransfer(IERC20 indexed token, address indexed from, address indexed to, uint256 share);

    event LogFlashLoan(address indexed borrower, IERC20 indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);

    event LogStrategyTargetPercentage(IERC20 indexed token, uint256 targetPercentage);
    event LogStrategyQueued(IERC20 indexed token, IStrategy indexed strategy);
    event LogStrategySet(IERC20 indexed token, IStrategy indexed strategy);
    event LogStrategyInvest(IERC20 indexed token, uint256 amount);
    event LogStrategyDivest(IERC20 indexed token, uint256 amount);
    event LogStrategyProfit(IERC20 indexed token, uint256 amount);
    event LogStrategyLoss(IERC20 indexed token, uint256 amount);

    // *************** //
    // *** STRUCTS *** //
    // *************** //

    struct StrategyData {
        uint64 strategyStartDate;
        uint64 targetPercentage;
        uint128 balance; // the balance of the strategy that BentoBox thinks is in there
    }

    // ******************************** //
    // *** CONSTANTS AND IMMUTABLES *** //
    // ******************************** //

    // V2 - Can they be private?
    // V2: Private to save gas, to verify it's correct, check the constructor arguments
    IERC20 private immutable wethToken;

    IERC20 private constant USE_ETHEREUM = IERC20(0);
    uint256 private constant FLASH_LOAN_FEE = 50; // 0.05%
    uint256 private constant FLASH_LOAN_FEE_PRECISION = 1e5;
    uint256 private constant STRATEGY_DELAY = 2 weeks;
    uint256 private constant MAX_TARGET_PERCENTAGE = 95; // 95%
    uint256 private constant MINIMUM_SHARE_BALANCE = 1000; // To prevent the ratio going off

    // ***************** //
    // *** VARIABLES *** //
    // ***************** //

    // Balance per token per address/contract in shares
    mapping(IERC20 => mapping(address => uint256)) public balanceOf;

    // Rebase from amount to share
    mapping(IERC20 => Rebase) public totals;

    mapping(IERC20 => IStrategy) public strategy;
    mapping(IERC20 => IStrategy) public pendingStrategy;
    mapping(IERC20 => StrategyData) public strategyData;

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    constructor(IERC20 wethToken_) public {
        wethToken = wethToken_;
    }

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'from' is the BentoBox itself, it's allowed. Any ETH, token balances (above the known balances) or BentoBox balances
    /// can be taken by anyone.
    /// This is to enable skimming, not just for deposits, but also for withdrawals or transfers, enabling better composability.
    /// If 'from' is a clone of a masterContract AND the 'from' address has approved that masterContract, it's allowed.
    modifier allowed(address from) {
        if (from != msg.sender && from != address(this)) {
            // From is sender or you are skimming
            address masterContract = masterContractOf[msg.sender];
            require(masterContract != address(0), "BentoBox: no masterContract");
            require(masterContractApproved[masterContract][from], "BentoBox: Transfer not approved");
        }
        _;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /// @dev Returns the total balance of `token` this contracts holds,
    /// plus the total amount this contract thinks the strategy holds.
    function _tokenBalanceOf(IERC20 token) internal view returns (uint256 amount) {
        amount = token.balanceOf(address(this)).add(strategyData[token].balance);
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share) {
        share = totals[token].toBase(amount, roundUp);
    }

    /// @dev Helper function represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount) {
        amount = totals[token].toElastic(share, roundUp);
    }

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public payable allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds

        // Effects
        IERC20 token = token_ == USE_ETHEREUM ? wethToken : token_;
        Rebase memory total = totals[token];

        // If a new token gets added, the tokenSupply call checks that this is a deployed contract. Needed for security.
        require(total.elastic != 0 || token.totalSupply() > 0, "BentoBox: No tokens");
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = total.toBase(amount, false);
            // Any deposit should lead to at least the minimum share balance, otherwise it's ignored (no amount taken)
            if (total.base.add(share.to128()) < MINIMUM_SHARE_BALANCE) {
                return (0, 0);
            }
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = total.toElastic(share, true);
        }

        // In case of skimming, check that only the skimmable amount is taken.
        // For ETH, the full balance is available, so no need to check.
        // During flashloans the _tokenBalanceOf is lower than 'reality', so skimming deposits will mostly fail during a flashloan.
        require(
            from != address(this) || token_ == USE_ETHEREUM || amount <= _tokenBalanceOf(token).sub(total.elastic),
            "BentoBox: Skim too much"
        );

        balanceOf[token][to] = balanceOf[token][to].add(share);
        total.base = total.base.add(share.to128());
        total.elastic = total.elastic.add(amount.to128());
        totals[token] = total;

        // Interactions
        // During the first deposit, we check that this token is 'real'
        if (token_ == USE_ETHEREUM) {
            // X2 - If there is an error, could it cause a DoS. Like balanceOf causing revert. (SWC-113)
            // X2: If the WETH implementation is faulty or malicious, it will block adding ETH (but we know the WETH implementation)
            IWETH(address(wethToken)).deposit{value: amount}();
        } else if (from != address(this)) {
            // X2 - If there is an error, could it cause a DoS. Like balanceOf causing revert. (SWC-113)
            // X2: If the token implementation is faulty or malicious, it may block adding tokens. Good.
            token.safeTransferFrom(from, address(this), amount);
        }
        emit LogDeposit(token, from, to, amount, share);
        amountOut = amount;
        shareOut = share;
    }

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds

        // Effects
        IERC20 token = token_ == USE_ETHEREUM ? wethToken : token_;
        Rebase memory total = totals[token];
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = total.toBase(amount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = total.toElastic(share, false);
        }

        balanceOf[token][from] = balanceOf[token][from].sub(share);
        total.elastic = total.elastic.sub(amount.to128());
        total.base = total.base.sub(share.to128());
        // There have to be at least 1000 shares left to prevent reseting the share/amount ratio (unless it's fully emptied)
        require(total.base >= MINIMUM_SHARE_BALANCE || total.base == 0, "BentoBox: cannot empty");
        totals[token] = total;

        // Interactions
        if (token_ == USE_ETHEREUM) {
            // X2, X3: A revert or big gas usage in the WETH contract could block withdrawals, but WETH9 is fine.
            IWETH(address(wethToken)).withdraw(amount);
            // X2, X3: A revert or big gas usage could block, however, the to address is under control of the caller.
            (bool success, ) = to.call{value: amount}("");
            require(success, "BentoBox: ETH transfer failed");
        } else {
            // X2, X3: A malicious token could block withdrawal of just THAT token.
            //         masterContracts may want to take care not to rely on withdraw always succeeding.
            token.safeTransfer(to, amount);
        }
        emit LogWithdraw(token, from, to, amount, share);
        amountOut = amount;
        shareOut = share;
    }

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    // Clones of master contracts can transfer from any account that has approved them
    // F3 - Can it be combined with another similar function?
    // F3: This isn't combined with transferMultiple for gas optimization
    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) public allowed(from) {
        // Checks
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds

        // Effects
        balanceOf[token][from] = balanceOf[token][from].sub(share);
        balanceOf[token][to] = balanceOf[token][to].add(share);

        emit LogTransfer(token, from, to, share);
    }

    /// @notice Transfer shares from a user account to multiple other ones.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param tos The receivers of the tokens.
    /// @param shares The amount of `token` in shares for each receiver in `tos`.
    // F3 - Can it be combined with another similar function?
    // F3: This isn't combined with transfer for gas optimization
    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) public allowed(from) {
        // Checks
        require(tos[0] != address(0), "BentoBox: to[0] not set"); // To avoid a bad UI from burning funds

        // Effects
        uint256 totalAmount;
        uint256 len = tos.length;
        for (uint256 i = 0; i < len; i++) {
            address to = tos[i];
            balanceOf[token][to] = balanceOf[token][to].add(shares[i]);
            totalAmount = totalAmount.add(shares[i]);
            emit LogTransfer(token, from, to, shares[i]);
        }
        balanceOf[token][from] = balanceOf[token][from].sub(totalAmount);
    }

    /// @notice Flashloan ability.
    /// @param borrower The address of the contract that implements and conforms to `IFlashBorrower` and handles the flashloan.
    /// @param receiver Address of the token receiver.
    /// @param token The address of the token to receive.
    /// @param amount of the tokens to receive.
    /// @param data The calldata to pass to the `borrower` contract.
    // F5 - Checks-Effects-Interactions pattern followed? (SWC-107)
    // F5: Not possible to follow this here, reentrancy has been reviewed
    // F6 - Check for front-running possibilities, such as the approve function (SWC-114)
    // F6: Slight grieving possible by withdrawing an amount before someone tries to flashloan close to the full amount.
    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) public {
        uint256 fee = amount.mul(FLASH_LOAN_FEE) / FLASH_LOAN_FEE_PRECISION;
        token.safeTransfer(receiver, amount);

        borrower.onFlashLoan(msg.sender, token, amount, fee, data);

        require(_tokenBalanceOf(token) >= totals[token].addElastic(fee.to128()), "BentoBox: Wrong amount");
        emit LogFlashLoan(address(borrower), token, amount, fee, receiver);
    }

    /// @notice Support for batched flashloans. Useful to request multiple different `tokens` in a single transaction.
    /// @param borrower The address of the contract that implements and conforms to `IBatchFlashBorrower` and handles the flashloan.
    /// @param receivers An array of the token receivers. A one-to-one mapping with `tokens` and `amounts`.
    /// @param tokens The addresses of the tokens.
    /// @param amounts of the tokens for each receiver.
    /// @param data The calldata to pass to the `borrower` contract.
    // F5 - Checks-Effects-Interactions pattern followed? (SWC-107)
    // F5: Not possible to follow this here, reentrancy has been reviewed
    // F6 - Check for front-running possibilities, such as the approve function (SWC-114)
    // F6: Slight grieving possible by withdrawing an amount before someone tries to flashloan close to the full amount.
    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        uint256[] memory fees = new uint256[](tokens.length);

        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 amount = amounts[i];
            fees[i] = amount.mul(FLASH_LOAN_FEE) / FLASH_LOAN_FEE_PRECISION;

            tokens[i].safeTransfer(receivers[i], amounts[i]);
        }

        borrower.onBatchFlashLoan(msg.sender, tokens, amounts, fees, data);

        for (uint256 i = 0; i < len; i++) {
            IERC20 token = tokens[i];
            require(_tokenBalanceOf(token) >= totals[token].addElastic(fees[i].to128()), "BentoBox: Wrong amount");
            emit LogFlashLoan(address(borrower), token, amounts[i], fees[i], receivers[i]);
        }
    }

    /// @notice Sets the target percentage of the strategy for `token`.
    /// @dev Only the owner of this contract is allowed to change this.
    /// @param token The address of the token that maps to a strategy to change.
    /// @param targetPercentage_ The new target in percent. Must be lesser or equal to `MAX_TARGET_PERCENTAGE`.
    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) public onlyOwner {
        // Checks
        require(targetPercentage_ <= MAX_TARGET_PERCENTAGE, "StrategyManager: Target too high");

        // Effects
        strategyData[token].targetPercentage = targetPercentage_;
        emit LogStrategyTargetPercentage(token, targetPercentage_);
    }

    /// @notice Sets the contract address of a new strategy that conforms to `IStrategy` for `token`.
    /// Must be called twice with the same arguments.
    /// A new strategy becomes pending first and can be activated once `STRATEGY_DELAY` is over.
    /// @dev Only the owner of this contract is allowed to change this.
    /// @param token The address of the token that maps to a strategy to change.
    /// @param newStrategy The address of the contract that conforms to `IStrategy`.
    // F5 - Checks-Effects-Interactions pattern followed? (SWC-107)
    // F5: Total amount is updated AFTER interaction. But strategy is under our control.
    // C4 - Use block.timestamp only for long intervals (SWC-116)
    // C4: block.timestamp is used for a period of 2 weeks, which is long enough
    function setStrategy(IERC20 token, IStrategy newStrategy) public onlyOwner {
        StrategyData memory data = strategyData[token];
        IStrategy pending = pendingStrategy[token];
        if (data.strategyStartDate == 0 || pending != newStrategy) {
            pendingStrategy[token] = newStrategy;
            // C1 - All math done through BoringMath (SWC-101)
            // C1: Our sun will swallow the earth well before this overflows
            data.strategyStartDate = (block.timestamp + STRATEGY_DELAY).to64();
            emit LogStrategyQueued(token, newStrategy);
        } else {
            require(data.strategyStartDate != 0 && block.timestamp >= data.strategyStartDate, "StrategyManager: Too early");
            if (address(strategy[token]) != address(0)) {
                int256 balanceChange = strategy[token].exit(data.balance);
                // Effects
                if (balanceChange > 0) {
                    uint256 add = uint256(balanceChange);
                    totals[token].addElastic(add);
                    emit LogStrategyProfit(token, add);
                } else if (balanceChange < 0) {
                    uint256 sub = uint256(-balanceChange);
                    totals[token].subElastic(sub);
                    emit LogStrategyLoss(token, sub);
                }

                emit LogStrategyDivest(token, data.balance);
            }
            strategy[token] = pending;
            data.strategyStartDate = 0;
            data.balance = 0;
            pendingStrategy[token] = IStrategy(0);
            emit LogStrategySet(token, newStrategy);
        }
        strategyData[token] = data;
    }

    /// @notice The actual process of yield farming. Executes the strategy of `token`.
    /// Optionally does housekeeping if `balance` is true.
    /// `maxChangeAmount` is relevant for skimming or withdrawing if `balance` is true.
    /// @param token The address of the token for which a strategy is deployed.
    /// @param balance True if housekeeping should be done.
    /// @param maxChangeAmount The maximum amount for either pulling or pushing from/to the `IStrategy` contract.
    // F5 - Checks-Effects-Interactions pattern followed? (SWC-107)
    // F5: Total amount is updated AFTER interaction. But strategy is under our control.
    // F5: Not followed to prevent reentrancy issues with flashloans and BentoBox skims?
    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) public {
        StrategyData memory data = strategyData[token];
        IStrategy _strategy = strategy[token];
        int256 balanceChange = _strategy.harvest(data.balance, msg.sender);
        if (balanceChange == 0 && !balance) {
            return;
        }

        uint256 totalElastic = totals[token].elastic;

        if (balanceChange > 0) {
            uint256 add = uint256(balanceChange);
            totalElastic = totalElastic.add(add);
            totals[token].elastic = totalElastic.to128();
            emit LogStrategyProfit(token, add);
        } else if (balanceChange < 0) {
            // C1 - All math done through BoringMath (SWC-101)
            // C1: balanceChange could overflow if it's max negative int128.
            // But tokens with balances that large are not supported by the BentoBox.
            uint256 sub = uint256(-balanceChange);
            totalElastic = totalElastic.sub(sub);
            totals[token].elastic = totalElastic.to128();
            data.balance = data.balance.sub(sub.to128());
            emit LogStrategyLoss(token, sub);
        }

        if (balance) {
            uint256 targetBalance = totalElastic.mul(data.targetPercentage) / 100;
            // if data.balance == targetBalance there is nothing to update
            if (data.balance < targetBalance) {
                uint256 amountOut = targetBalance.sub(data.balance);
                if (maxChangeAmount != 0 && amountOut > maxChangeAmount) {
                    amountOut = maxChangeAmount;
                }
                token.safeTransfer(address(_strategy), amountOut);
                data.balance = data.balance.add(amountOut.to128());
                _strategy.skim(amountOut);
                emit LogStrategyInvest(token, amountOut);
            } else if (data.balance > targetBalance) {
                uint256 amountIn = data.balance.sub(targetBalance.to128());
                if (maxChangeAmount != 0 && amountIn > maxChangeAmount) {
                    amountIn = maxChangeAmount;
                }

                uint256 actualAmountIn = _strategy.withdraw(amountIn);

                data.balance = data.balance.sub(actualAmountIn.to128());
                emit LogStrategyDivest(token, actualAmountIn);
            }
        }

        strategyData[token] = data;
    }

    // Contract should be able to receive ETH deposits to support deposit & skim
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
    
    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    } 

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.add(elastic.to128());
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.sub(elastic.to128());
    }
}

// SPDX-License-Identifier: UNLICENSED
// Audit on 5-Jan-2021 by Keno and BoringCrypto
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

// solhint-disable no-inline-assembly

contract MasterContractManager is BoringOwnable, BoringFactory {
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogRegisterProtocol(address indexed protocol);

    /// @notice masterContract to user to approval state
    mapping(address => mapping(address => bool)) public masterContractApproved;
    /// @notice masterContract to whitelisted state for approval without signed message
    mapping(address => bool) public whitelistedMasterContracts;
    /// @notice user nonces for masterContract approvals
    mapping(address => uint256) public nonces;

    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 private constant APPROVAL_SIGNATURE_HASH =
        keccak256("SetMasterContractApproval(string warning,address user,address masterContract,bool approved,uint256 nonce)");

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, keccak256("BentoBox V1"), chainId, address(this)));
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    /// @notice Other contracts need to register with this master contract so that users can approve them for the BentoBox.
    function registerProtocol() public {
        masterContractOf[msg.sender] = msg.sender;
        emit LogRegisterProtocol(msg.sender);
    }

    /// @notice Enables or disables a contract for approval without signed message.
    function whitelistMasterContract(address masterContract, bool approved) public onlyOwner {
        // Checks
        require(masterContract != address(0), "MasterCMgr: Cannot approve 0");

        // Effects
        whitelistedMasterContracts[masterContract] = approved;
        emit LogWhiteListMasterContract(masterContract, approved);
    }

    /// @notice Approves or revokes a `masterContract` access to `user` funds.
    /// @param user The address of the user that approves or revokes access.
    /// @param masterContract The address who gains or loses access.
    /// @param approved If True approves access. If False revokes access.
    /// @param v Part of the signature. (See EIP-191)
    /// @param r Part of the signature. (See EIP-191)
    /// @param s Part of the signature. (See EIP-191)
    // F4 - Check behaviour for all function arguments when wrong or extreme
    // F4: Don't allow masterContract 0 to be approved. Unknown contracts will have a masterContract of 0.
    // F4: User can't be 0 for signed approvals because the recoveredAddress will be 0 if ecrecover fails
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Checks
        require(masterContract != address(0), "MasterCMgr: masterC not set"); // Important for security

        // If no signature is provided, the fallback is executed
        if (r == 0 && s == 0 && v == 0) {
            require(user == msg.sender, "MasterCMgr: user not sender");
            require(masterContractOf[user] == address(0), "MasterCMgr: user is clone");
            require(whitelistedMasterContracts[masterContract], "MasterCMgr: not whitelisted");
        } else {
            // Important for security - any address without masterContract has address(0) as masterContract
            // So approving address(0) would approve every address, leading to full loss of funds
            // Also, ecrecover returns address(0) on failure. So we check this:
            require(user != address(0), "MasterCMgr: User cannot be 0");

            // C10 - Protect signatures against replay, use nonce and chainId (SWC-121)
            // C10: nonce + chainId are used to prevent replays
            // C11 - All signatures strictly EIP-712 (SWC-117 SWC-122)
            // C11: signature is EIP-712 compliant
            // C12 - abi.encodePacked can't contain variable length user input (SWC-133)
            // C12: abi.encodePacked has fixed length parameters
            bytes32 digest =
                keccak256(
                    abi.encodePacked(
                        EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                APPROVAL_SIGNATURE_HASH,
                                approved
                                    ? keccak256("Give FULL access to funds in (and approved to) BentoBox?")
                                    : keccak256("Revoke access to BentoBox?"),
                                user,
                                masterContract,
                                approved,
                                nonces[user]++
                            )
                        )
                    )
                );
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress == user, "MasterCMgr: Invalid Signature");
        }

        // Effects
        masterContractApproved[masterContract][user] = approved;
        emit LogSetMasterContractApproval(masterContract, user, approved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../BentoBox.sol";

// solhint-disable not-rely-on-time

// IDEA: Make changes to salaries, funder or recipient
// IDEA: Enable partial withdrawals

contract Salary is BoringBatchable {
    using BoringMath for uint256;

    BentoBox public bentoBox;

    event LogCreate(
        address indexed funder,
        address indexed recipient,
        IERC20 indexed token,
        uint32 cliffTimestamp,
        uint32 endTimestamp,
        uint32 cliffPercent,
        uint128 totalShares,
        uint256 salaryId
    );
    event LogWithdraw(uint256 indexed salaryId, address indexed to, uint256 shares);
    event LogCancel(uint256 indexed salaryId, address indexed to, uint256 shares);

    constructor(BentoBox _bentoBox) public {
        bentoBox = _bentoBox;
        _bentoBox.registerProtocol();
    }

    // Included to be able to approve BentoBox and create in the same transaction (using batch)
    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bentoBox.setMasterContractApproval(user, address(this), approved, v, r, s);
    }

    ///     now                      cliffTimestamp
    ///      |                             |     endTimestamp
    ///      V                             V          |
    ///      -------------------------------          |
    ///      |        ^             ^      |          V
    ///      |        |       cliffPercent |
    ///      |        |             V      |
    ///      |        |             -----> |
    ///      |        |                      \
    ///      |   totalShares                   \
    ///      |        |                          \
    ///      |        |                            \
    ///      |        V                              \
    ///      -----------------------------------------
    struct UserSalary {
        // The recipient of the salary
        address recipient;
        // The ERC20 token
        IERC20 token;
        // The amount of shares that the recipient has already withdrawn
        uint256 withdrawnShares;
        // The timestamp of the cliff (also the start of the slope)
        uint32 cliffTimestamp;
        // The timestamp of the end of vesting (the end of the slope)
        uint32 endTimestamp;
        // The cliff payout in percent of the shares, 1e18 = 100%
        uint64 cliffPercent;
        // The total payout in shares
        uint128 shares;
    }

    /// Array of all salaries managed by the contract
    UserSalary[] public salaries;
    /// The funder of each salary, separated out for gas optimization
    address[] public funder;

    uint8 private constant MODE_BENTO = 0; // Use BentoBox balance
    uint8 private constant MODE_ERC20_SKIM = 1; // Use ERC20 tokens deposited onto the BentoBox contract
    uint8 private constant MODE_ERC20 = 2; // Use ERC20 tokens in the users wallet (transferFrom with approval)

    /// Create a salary
    function create(
        address recipient,
        IERC20 token,
        uint32 cliffTimestamp,
        uint32 endTimestamp,
        uint32 cliffPercent,
        uint8 mode,
        uint128 amount
    ) public returns (uint256 salaryId, uint256 shares) {
        // Check that the end if after or equal to the cliff
        // If they are equal, all shares become payable at once, use this for a fixed term lockup
        require(cliffTimestamp <= endTimestamp, "Salary: cliff > end");
        // You cannot have a cliff greater than 100%, important check, without the contract will lose funds
        require(cliffPercent <= 1e18, "Salary: cliff too large");

        if (mode == MODE_BENTO) {
            // Fund this salary using the funder's BentoBox balance. Convert the amoutn to shares, then transfer the shares
            shares = bentoBox.toShare(token, amount, false);
            bentoBox.transfer(token, msg.sender, address(this), shares);
        } else {
            // Fund this salary with ERC20 tokens
            // This is a potential reentrancy target, funds in this contract could be higher than the total of salaries during this call
            // Since this contract doesn't have a skim function, this is ok
            (, shares) = bentoBox.deposit(token, mode == MODE_ERC20_SKIM ? address(bentoBox) : msg.sender, address(this), amount, 0);
        }

        salaryId = salaries.length;
        UserSalary memory salary;
        salary.recipient = recipient;
        salary.token = token;
        salary.cliffTimestamp = cliffTimestamp;
        salary.endTimestamp = endTimestamp;
        salary.cliffPercent = cliffPercent;
        salary.shares = shares.to128();
        salaries.push(salary);
        funder.push(msg.sender);

        emit LogCreate(msg.sender, recipient, token, cliffTimestamp, endTimestamp, cliffPercent, shares.to128(), salaryId);
    }

    function _available(UserSalary memory salary) internal view returns (uint256 shares) {
        if (block.timestamp < salary.cliffTimestamp) {
            // Before the cliff, none is available
            shares = 0;
        } else if (block.timestamp >= salary.endTimestamp) {
            // After the end, all is available
            shares = salary.shares;
        } else {
            // In between, cliff is available, rest according to slope

            // Time that has passed since the cliff
            uint256 timeSinceCliff = block.timestamp.sub(salary.cliffTimestamp);
            // Total time period of the slope
            uint256 timeSlope = uint256(salary.endTimestamp).sub(salary.cliffTimestamp);
            uint256 payablePercent = salary.cliffPercent;
            if (timeSinceCliff > 0) {
                // The percentage paid out during the slope
                uint256 slopePercent = uint256(1e18).sub(uint256(salary.cliffPercent));
                // The percentage payable on the slope added to the cliff percentage
                payablePercent = payablePercent.add(slopePercent.mul(timeSinceCliff) / timeSlope);
            }
            // The share payable
            shares = uint256(salary.shares).mul(payablePercent) / 1e18;
        }

        // Remove any shares already wiythdrawn, if negative, return 0
        if (shares > salary.withdrawnShares) {
            shares = shares.sub(salary.withdrawnShares);
        } else {
            shares = 0;
        }
    }

    // Get the number of shares currently available for withdrawal by salaryId
    function available(uint256 salaryId) public view returns (uint256 shares) {
        shares = _available(salaries[salaryId]);
    }

    // Withdraw the maximum amount possible for a salaryId
    function withdraw(
        uint256 salaryId,
        address to,
        bool toBentoBox
    ) public {
        UserSalary memory salary = salaries[salaryId];
        // Only pay out to the recipient
        require(salary.recipient == msg.sender, "Salary: not recipient");

        uint256 pendingShares = _available(salary);
        salaries[salaryId].withdrawnShares = salary.withdrawnShares.add(pendingShares);
        if (toBentoBox) {
            bentoBox.transfer(salary.token, address(this), to, pendingShares);
        } else {
            bentoBox.withdraw(salary.token, address(this), to, 0, pendingShares);
        }
        emit LogWithdraw(salaryId, to, pendingShares);
    }

    // Modifier for functions only allowed by the funder
    modifier onlyFunder(uint256 salaryId) {
        require(funder[salaryId] == msg.sender, "Salary: not funder");
        _;
    }

    // Cancel a salary, can only be done by the funder
    function cancel(
        uint256 salaryId,
        address to,
        bool toBentoBox
    ) public onlyFunder(salaryId) {
        uint256 sharesLeft = uint256(salaries[salaryId].shares).sub(salaries[salaryId].withdrawnShares);
        if (toBentoBox) {
            bentoBox.transfer(salaries[salaryId].token, address(this), to, sharesLeft);
        } else {
            bentoBox.withdraw(salaries[salaryId].token, address(this), to, 0, sharesLeft);
        }
        emit LogCancel(salaryId, to, sharesLeft);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../BentoBox.sol";

// An example a contract that stores tokens in the BentoBox.
// A single contract that users can approve for the BentoBox, hence the registerProtocol call.
// PS. This isn't good code, just kept it simple to illustrate usage.
contract HelloWorld {
    BentoBox public bentoBox;
    IERC20 public token;

    constructor(BentoBox _bentoBox, IERC20 _token) public {
        bentoBox = _bentoBox;
        token = _token;
        bentoBox.registerProtocol();
    }

    mapping(address => uint256) public bentoBoxShares;

    // Deposits an amount of token into the BentoBox. BentoBox shares are given to the HelloWorld contract and
    // assigned to the user in bentoBoxShares.
    // Don't deposit twice, you'll lose the first deposit ;)
    function deposit(uint256 amount) public {
        (, bentoBoxShares[msg.sender]) = bentoBox.deposit(token, msg.sender, address(this), amount, 0);
    }

    // This will return the current value in amount of the BentoBox shares.
    // Through flash loans and maybe a strategy, the value can go up over time.
    function balance() public view returns (uint256 amount) {
        return bentoBox.toAmount(token, bentoBoxShares[msg.sender], false);
    }

    // Withdraw all shares from the BentoBox and receive the token.
    function withdraw() public {
        bentoBox.withdraw(token, address(this), msg.sender, 0, bentoBoxShares[msg.sender]);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "../BentoBox.sol";

contract MasterContractMock is IMasterContract {
    BentoBox public immutable bentoBox;

    constructor(BentoBox _bentoBox) public {
        bentoBox = _bentoBox;
    }

    function deposit(IERC20 token, uint256 amount) public {
        bentoBox.deposit(token, msg.sender, address(this), 0, amount);
    }

    function init(bytes calldata) external payable override {
        return;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "../BentoBox.sol";

contract MaliciousMasterContractMock is IMasterContract {
    function init(bytes calldata) external payable override {
        return;
    }

    function attack(BentoBox bentoBox) public {
        bentoBox.setMasterContractApproval(address(this), address(this), true, 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../../../interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable not-rely-on-time
// solhint-disable no-empty-blocks
// solhint-disable avoid-tx-origin

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IcToken is IERC20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);
}

contract CompoundStrategy is IStrategy, BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for IcToken;

    address public immutable bentobox;
    IERC20 public immutable token;
    IcToken public immutable cToken;
    IERC20 public immutable compToken;
    IERC20 public immutable weth;
    IFactory public immutable factory;
    bool public exited;

    constructor(
        address bentobox_,
        IFactory factory_,
        IERC20 token_,
        IcToken cToken_,
        IERC20 compToken_,
        IERC20 weth_
    ) public {
        bentobox = bentobox_;
        factory = factory_;
        token = token_;
        cToken = cToken_;
        compToken = compToken_;
        weth = weth_;

        token_.approve(address(cToken_), type(uint256).max);
    }

    modifier onlyBentobox() {
        // Only the bentobox can call harvest on this strategy
        require(msg.sender == bentobox, "CompoundStrategy: only bento");
        require(!exited, "CompoundStrategy: exited");
        _;
    }

    function _swapAll(
        IERC20 fromToken,
        IERC20 toToken,
        address to
    ) internal returns (uint256 amountOut) {
        IPair pair = IPair(factory.getPair(address(fromToken), address(toToken)));
        require(address(pair) != address(0), "CompoundStrategy: Cannot convert");

        uint256 amountIn = fromToken.balanceOf(address(this));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        IERC20(fromToken).safeTransfer(address(pair), amountIn);
        if (fromToken < toToken) {
            amountOut = amountIn.mul(997).mul(reserve1) / reserve0.mul(1000).add(amountInWithFee);
            pair.swap(0, amountOut, to, new bytes(0));
        } else {
            amountOut = amountIn.mul(997).mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
            pair.swap(amountOut, 0, to, new bytes(0));
        }
    }

    // Send the assets to the Strategy and call skim to invest them
    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override onlyBentobox {
        require(cToken.mint(amount) == 0, "CompoundStrategy: mint error");
    }

    // Harvest any profits made converted to the asset and pass them to the caller
    /// @inheritdoc IStrategy
    function harvest(uint256 balance, address sender) external override onlyBentobox returns (int256 amountAdded) {
        // To prevent anyone from using flash loans to 'steal' part of the profits, only EOA is allowed to call harvest
        require(sender == tx.origin, "CompoundStrategy: EOA only");
        // Get the amount of tokens that the cTokens currently represent
        uint256 tokenBalance = cToken.balanceOfUnderlying(address(this));
        // Convert enough cToken to take out the profit
        // If the amount is negative due to rounding (near impossible), just revert. Should be positive soon enough.
        require(cToken.redeemUnderlying(tokenBalance.sub(balance)) == 0, "CompoundStrategy: profit fail");

        // Find out how much has been added (+ sitting on the contract from harvestCOMP)
        uint256 amountAdded_ = token.balanceOf(address(this));
        // Transfer the profit to the bentobox, the amountAdded at this point matches the amount transferred
        token.safeTransfer(bentobox, amountAdded_);

        return int256(amountAdded_);
    }

    function harvestCOMP(uint256 minAmount) public onlyOwner {
        // To prevent flash loan sandwich attacks to 'steal' the profit, only the owner can harvest the COMP
        // Swap all COMP to WETH
        _swapAll(compToken, weth, address(this));
        // Swap all WETH to token and leave it on the contract to be swept up in the next harvest
        require(_swapAll(weth, token, address(this)) >= minAmount, "CompoundStrategy: not enough");
    }

    // Withdraw assets.
    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external override onlyBentobox returns (uint256 actualAmount) {
        // Convert enough cToken to take out 'amount' tokens
        require(cToken.redeemUnderlying(amount) == 0, "CompoundStrategy: redeem fail");

        // Make sure we send and report the exact same amount of tokens by using balanceOf
        actualAmount = token.balanceOf(address(this));
        token.safeTransfer(bentobox, actualAmount);
    }

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @inheritdoc IStrategy
    function exit(uint256 balance) external override onlyBentobox returns (int256 amountAdded) {
        // Get the amount of tokens that the cTokens currently represent
        uint256 tokenBalance = cToken.balanceOfUnderlying(address(this));
        // Get the actual token balance of the cToken contract
        uint256 available = token.balanceOf(address(cToken));

        // Check that the cToken contract has enough balance to pay out in full
        if (tokenBalance <= available) {
            // If there are more tokens available than our full position, take all based on cToken balance (continue if unsuccesful)
            try cToken.redeem(cToken.balanceOf(address(this))) {} catch {}
        } else {
            // Otherwise redeem all available and take a loss on the missing amount (continue if unsuccesful)
            try cToken.redeemUnderlying(available) {} catch {}
        }

        // Check balance of token on the contract
        uint256 amount = token.balanceOf(address(this));
        // Calculate tokens added (or lost)
        amountAdded = int256(amount) - int256(balance);
        // Transfer all tokens to bentobox
        token.safeTransfer(bentobox, amount);
        // Flag as exited, allowing the owner to manually deal with any amounts available later
        exited = true;
    }

    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (bool success) {
        // After exited, the owner can perform ANY call. This is to rescue any funds that didn't get released during exit or
        // got earned afterwards due to vesting or airdrops, etc.
        require(exited, "CompoundStrategy: Not exited");
        (success, ) = to.call{value: value}(data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IBentoBoxMinimal.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable not-rely-on-time
// solhint-disable no-empty-blocks
// solhint-disable avoid-tx-origin

library DataTypes {
    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }
}

interface IaToken {
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address token,
        uint256 amount,
        address destination
    ) external;
}

interface IStakedAave {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;
}

contract AaveStrategyOld is IStrategy, BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for IaToken;

    address public immutable aave;
    address public immutable aToken;
    IBentoBoxMinimal public immutable bentobox;
    address public immutable factory;
    address public immutable underlying;
    bool public exited;
    uint256 public maxBentoBalance;

    event LogConvert(address indexed server, address indexed token0, address indexed token1, uint256 amount0, uint256 amount1);

    constructor(
        address aave_,
        address factory_,
        IBentoBoxMinimal bentobox_,
        address underlying_
    ) public {
        aave = aave_;
        factory = factory_;
        bentobox = bentobox_;
        underlying = underlying_;
        IERC20(underlying_).approve(aave_, type(uint256).max);
        aToken = IaToken(aave_).getReserveData(underlying_).aTokenAddress;
    }

    modifier onlyBentobox() {
        // @dev Only the bentobox can call harvest on this strategy.
        require(msg.sender == address(bentobox), "AaveStrategy: only bento");
        require(!exited, "AaveStrategy: exited");
        _;
    }

    /// **** REWARD MGMT **** ///
    function cooldown(IStakedAave stkAave) external {
        stkAave.cooldown();
    }

    function stake(IStakedAave stkAave, uint256 amount) external {
        stkAave.stake(address(this), amount);
    }

    function redeem(IStakedAave stkAave, uint256 amount) external {
        stkAave.redeem(address(this), amount);
    }

    function claimRewards(IStakedAave stkAave, uint256 amount) external {
        stkAave.claimRewards(address(this), amount);
    }

    /// **** ///

    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override onlyBentobox {
        IaToken(aave).deposit(underlying, amount, address(this), 0);
    }

    function safeHarvest(
        uint256 maxBentoTokenShare,
        bool rebalance,
        uint256 maxChangeAmount
    ) external onlyOwner {
        maxBentoBalance = maxBentoTokenShare;
        bentobox.harvest(underlying, rebalance, maxChangeAmount);
    }

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @inheritdoc IStrategy
    function harvest(uint256 balance, address sender) public override onlyBentobox returns (int256 amountAdded) {
        // do not revert if conditions fail
        if (sender == address(this) && IBentoBoxMinimal(bentobox).totals(underlying).elastic <= maxBentoBalance) {
            // @dev Get the amount of tokens that the aTokens currently represent.
            uint256 tokenBalance = IERC20(aToken).safeBalanceOf(address(this));
            // @dev Convert enough aToken to take out the profit.
            // If the amount is negative due to rounding (near impossible), just revert (should be positive soon enough).
            IaToken(aave).withdraw(underlying, tokenBalance.sub(balance), address(this));
            uint256 amountAdded_ = IERC20(underlying).safeBalanceOf(address(this));
            // @dev Transfer the profit to the bentobox, the amountAdded at this point matches the amount transferred.
            IERC20(underlying).safeTransfer(address(bentobox), amountAdded_);
            maxBentoBalance = 0; // nullify maxShare
            return int256(amountAdded_);
        }

        return 0;
    }

    /// @notice Withdraw assets.
    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external override onlyBentobox returns (uint256 actualAmount) {
        // @dev Convert enough aToken to take out 'amount' tokens.
        IaToken(aave).withdraw(underlying, amount, address(this));
        // @dev Make sure we send and report the exact same amount of tokens by using balanceOf.
        actualAmount = IERC20(underlying).safeBalanceOf(address(this));
        IERC20(underlying).safeTransfer(address(bentobox), actualAmount);
    }

    /// @notice Withdraw all assets in the safest way possible - this shouldn't fail.
    /// @inheritdoc IStrategy
    function exit(uint256 balance) external override onlyBentobox returns (int256 amountAdded) {
        // @dev Get the amount of tokens that the aTokens currently represent.
        uint256 tokenBalance = IERC20(aToken).safeBalanceOf(address(this));
        // @dev Get the actual token balance of the aToken contract.
        uint256 available = IERC20(underlying).safeBalanceOf(aToken);
        // @dev Check that the aToken contract has enough balance to pay out in full.
        if (tokenBalance <= available) {
            // @dev If there are more tokens available than our full position, take all based on aToken balance (continue if unsuccessful).
            try IaToken(aave).withdraw(underlying, tokenBalance, address(this)) {} catch {}
        } else {
            // @dev Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try IaToken(aave).withdraw(underlying, available, address(this)) {} catch {}
        }
        // @dev Check balance of token on the contract.
        uint256 amount = IERC20(underlying).safeBalanceOf(address(this));
        // @dev Calculate tokens added (or lost).
        amountAdded = int256(amount) - int256(balance);
        // @dev Transfer all tokens to bentobox.
        IERC20(underlying).safeTransfer(address(bentobox), amount);
        // @dev Flag as exited, allowing the owner to manually deal with any amounts available later.
        exited = true;
    }

    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (bool success) {
        // @dev After exited, the owner can perform ANY call. This is to rescue any funds that didn't get released during exit or
        // got earned afterwards due to vesting or airdrops, etc.
        require(exited, "AaveStrategy: not exited");
        (success, ) = to.call{value: value}(data);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function swapExactTokensForTokens(uint256 amountOutMin, address[] calldata path) public onlyOwner returns (uint256[] memory amounts) {
        uint256 amountIn = IERC20(path[0]).safeBalanceOf(address(this));
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "AaveStrategy: insufficient output");
        IERC20(path[0]).safeTransfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        emit LogConvert(msg.sender, path[0], path[path.length - 1], amountIn, amounts[amounts.length - 1]);
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

/// @notice Minimal interface for BentoBox token vault interactions - `token` is aliased as `address` from `IERC20` for code simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for the BentoBox.
    function registerProtocol() external;

    function totals(address token) external view returns (Rebase memory);

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IStrategy.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol";

//// @title Base contract which custom BentoBox strategies should extend.
//// @notice Abstract BentoBox interactions away from the strategy implementation. Minimizes risk of sandwich attacks.
//// @dev Implement _skim, _harvest, _withdraw and _exit functions in your strategy.
abstract contract BaseStrategy is IStrategy, BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    struct BaseStrategyParams {
        address token;
        address bentoBox;
        address strategyExecutor;
        address factory;
        address bridgeToken;
    }

    IERC20 public immutable strategyToken;
    IBentoBoxMinimal public immutable bentoBox;
    address public immutable factory;
    address public immutable bridgeToken;

    bool public exited;
    uint256 public maxBentoBoxBalance;
    mapping(address => bool) public strategyExecutors;

    event LogConvert(address indexed server, address indexed token0, address indexed token1, uint256 amount0, uint256 amount1);
    event LogSetStrategyExecutor(address indexed executor, bool allowed);

    /** @param baseStrategyParams.token Address of the underlying token the strategy invests.
        @param baseStrategyParams.bentoBox BentoBox address.
        @param baseStrategyParams.strategyExecutor EOA that will execute the safeHarvest function.
        @param baseStrategyParams.factory SushiSwap factory.
        @param baseStrategyParams.bridgeToken An intermedieary token for swapping any rewards into the underlying token.*/
    constructor(BaseStrategyParams memory baseStrategyParams) public {
        strategyToken = IERC20(baseStrategyParams.token);
        bentoBox = IBentoBoxMinimal(baseStrategyParams.bentoBox);
        strategyExecutors[baseStrategyParams.strategyExecutor] = true;
        factory = baseStrategyParams.factory;
        bridgeToken = baseStrategyParams.bridgeToken;
    }

    //** Strategy implementation: override the following functions: */

    /// @notice Invests the underlying asset.
    /// @param amount The amount of tokens to invest.
    /// @dev Assume the contract's balance is greater than the amount
    function _skim(uint256 amount) internal virtual;

    /// @notice Harvest any profits made and transfer them to address(this) or report a loss
    /// @param balance The amount of tokens that have been invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    /// @dev amountAdded can be left at 0 when reporting profits (gas savings).
    /// amountAdded should not reflect any rewards or tokens the strategy received.
    /// Calcualte the amount added based on what the current deposit is worth.
    /// (The Base Strategy harvest function accounts for rewards).
    function _harvest(uint256 balance) internal virtual returns (int256 amountAdded);

    /// @dev Withdraw the requested amount of the underlying tokens to address(this).
    /// @param amount The requested amount we want to withdraw.
    function _withdraw(uint256 amount) internal virtual;

    /// @notice Withdraw the maximum amount of the invested assets to address(this).
    /// @dev This shouldn't revert (use try catch).
    function _exit() internal virtual;

    /// @notice Claim any rewards reward tokens and optionally sell them for the underlying token.
    /// @dev Doesn't need to be implemented if we don't expect any rewards.
    function _harvestRewards() internal virtual {}

    //** End strategy implementation */

    modifier onlyBentobox() {
        require(msg.sender == address(bentoBox), "BentoBox Strategy: only bento");
        require(!exited, "BentoBox Strategy: exited");
        _;
    }

    modifier onlyExecutor() {
        require(strategyExecutors[msg.sender], "BentoBox Strategy: only executor");
        _;
    }

    function setStrategyExecutor(address executor, bool value) external onlyOwner {
        strategyExecutors[executor] = value;
        emit LogSetStrategyExecutor(executor, strategyExecutors[executor]);
    }

    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override {
        _skim(amount);
    }

    /// @notice Harvest profits while preventing a sandwich attack exploit.
    /// @param maxBalance The maximum balance of the underlying token that is allowed to be in BentoBox.
    /// @param rebalance Whether BentoBox should rebalance the strategy assets to acheive it's target allocation.
    /// @param maxChangeAmount When rebalancing - the maximum amount that will be deposited to or withdrawn from a strategy.
    /// @param harvestRewards If we want to claim any accrued reward tokens
    /// @dev maxBalance can be set to 0 to keep the previous value.
    /// @dev maxChangeAmount can be set to 0 to allow for full rebalancing.
    function safeHarvest(
        uint256 maxBalance,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external onlyExecutor {
        if (harvestRewards) {
            _harvestRewards();
        }

        if (maxBalance > 0) {
            maxBentoBoxBalance = maxBalance;
        }

        bentoBox.harvest(address(strategyToken), rebalance, maxChangeAmount);
    }

    /** @inheritdoc IStrategy
    @dev Only BentoBox can call harvest on this strategy.
    @dev Ensures that (1) the caller was this contract (called through the safeHarvest function)
        and (2) that we are not being frontrun by a large BentoBox deposit when harvesting profits. */
    function harvest(uint256 balance, address sender) external override onlyBentobox returns (int256) {
        /** @dev Don't revert if conditions aren't met in order to allow
            BentoBox to continiue execution as it might need to do a rebalance. */

        if (sender == address(this) && IBentoBoxMinimal(bentoBox).totals(address(strategyToken)).elastic <= maxBentoBoxBalance) {
            int256 amount = _harvest(balance);

            /** @dev Since harvesting of rewards is accounted for seperately we might also have
            some underlying tokens in the contract that the _harvest call doesn't report. 
            E.g. reward tokens that have been sold into the underlying tokens which are now sitting in the contract.
            Meaning the amount returned by the internal _harvest function isn't necessary the final profit/loss amount */

            uint256 contractBalance = strategyToken.safeBalanceOf(address(this));

            if (amount >= 0) {
                // _harvest reported a profit

                if (contractBalance > 0) {
                    strategyToken.safeTransfer(address(bentoBox), contractBalance);
                }
                return int256(contractBalance);
            } else if (contractBalance > 0) {
                // _harvest reported a loss but we have some tokens sitting in the contract

                int256 diff = amount + int256(contractBalance);

                if (diff > 0) {
                    // we still made some profit
                    // send the profit to BentoBox and reinvest the rest
                    strategyToken.safeTransfer(address(bentoBox), uint256(diff));
                    _skim(uint256(-amount));
                    return diff;
                } else {
                    // we made a loss but we have some tokens we can reinvest
                    _skim(contractBalance);
                    return diff;
                }
            } else {
                // we made a loss
                return amount;
            }
        }
        return int256(0);
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external override onlyBentobox returns (uint256 actualAmount) {
        _withdraw(amount);
        /// @dev Make sure we send and report the exact same amount of tokens by using balanceOf.
        actualAmount = strategyToken.safeBalanceOf(address(this));
        strategyToken.safeTransfer(address(bentoBox), actualAmount);
    }

    /// @inheritdoc IStrategy
    function exit(uint256 balance) external override onlyBentobox returns (int256 amountAdded) {
        _exit();
        /// @dev Check balance of token on the contract.
        uint256 actualBalance = strategyToken.safeBalanceOf(address(this));
        /// @dev Calculate tokens added (or lost).
        amountAdded = int256(actualBalance) - int256(balance);
        /// @dev Transfer all tokens to bentoBox.
        strategyToken.safeTransfer(address(bentoBox), actualBalance);
        /// @dev Flag as exited, allowing the owner to manually deal with any amounts available later.
        exited = true;
    }

    /** @dev After exited, the owner can perform ANY call. This is to rescue any funds that didn't
        get released during exit or got earned afterwards due to vesting or airdrops, etc. */
    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (bool success) {
        require(exited, "BentoBox Strategy: not exited");
        (success, ) = to.call{value: value}(data);
    }

    /// @notice Swap some tokens in the contract for the underlying and deposits them to address(this)
    function swapExactTokensForUnderlying(uint256 amountOutMin, address inputToken) public onlyExecutor returns (uint256 amountOut) {
        require(factory != address(0), "BentoBox Strategy: cannot swap");
        require(inputToken != address(strategyToken), "BentoBox Strategy: invalid swap");

        ///@dev Construct a path array consisting of the input (reward token),
        /// underlying token and a potential bridge token
        bool useBridge = bridgeToken != address(0);

        address[] memory path = new address[](useBridge ? 3 : 2);

        path[0] = inputToken;

        if (useBridge) {
            path[1] = bridgeToken;
        }

        path[path.length - 1] = address(strategyToken);

        uint256 amountIn = IERC20(path[0]).safeBalanceOf(address(this));

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);

        amountOut = amounts[amounts.length - 1];

        require(amountOut >= amountOutMin, "BentoBox Strategy: insufficient output");

        IERC20(path[0]).safeTransfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);

        _swap(amounts, path, address(this));

        emit LogConvert(msg.sender, inputToken, address(strategyToken), amountIn, amountOut);
    }

    /// @dev requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../BaseStrategy.sol";

interface ISushiBar is IERC20 {
    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;
}

contract SushiStrategy is BaseStrategy {
    ISushiBar public immutable sushiBar;

    constructor(ISushiBar _sushiBar, BaseStrategyParams memory baseStrategyParams) public BaseStrategy(baseStrategyParams) {
        sushiBar = _sushiBar;
        IERC20(baseStrategyParams.token).approve(address(_sushiBar), type(uint256).max);
    }

    function _skim(uint256 amount) internal override {
        sushiBar.enter(amount);
    }

    function _harvest(uint256 balance) internal override returns (int256) {
        uint256 keep = toShare(balance);
        uint256 total = sushiBar.balanceOf(address(this));
        if (total > keep) sushiBar.leave(total - keep);
        // xSUSHI can't report a loss so no need to check for keep < total case
        return int256(0);
    }

    function _withdraw(uint256 amount) internal override {
        uint256 requested = toShare(amount);
        uint256 actual = sushiBar.balanceOf(address(this));
        sushiBar.leave(requested > actual ? actual : requested);
    }

    function _exit() internal override {
        sushiBar.leave(sushiBar.balanceOf(address(this)));
    }

    function toShare(uint256 amount) internal view returns (uint256) {
        uint256 totalShares = sushiBar.totalSupply();
        uint256 totalSushi = strategyToken.safeBalanceOf(address(sushiBar));
        return amount.mul(totalShares) / totalSushi;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../BaseStrategy.sol";

library DataTypes {
    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }
    struct ReserveConfigurationMap {
        uint256 data;
    }
}

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

interface IAaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract AaveStrategy is BaseStrategy {
    IERC20 public immutable rewardToken;
    ILendingPool public immutable aaveLendingPool;
    IAaveIncentivesController public immutable incentiveController;
    IERC20 public immutable aToken;

    constructor(
        IERC20 _rewardToken,
        ILendingPool _aaveLendingPool,
        IAaveIncentivesController _incentiveController,
        BaseStrategyParams memory baseStrategyParams
    ) public BaseStrategy(baseStrategyParams) {
        rewardToken = _rewardToken;
        aaveLendingPool = _aaveLendingPool;
        incentiveController = _incentiveController;
        aToken = IERC20(_aaveLendingPool.getReserveData(address(baseStrategyParams.token)).aTokenAddress);
        IERC20(baseStrategyParams.token).approve(address(_aaveLendingPool), type(uint256).max);
    }

    function _skim(uint256 amount) internal override {
        aaveLendingPool.deposit(address(strategyToken), amount, address(this), 0);
    }

    function _harvest(uint256 balance) internal override returns (int256 amountAdded) {
        uint256 currentBalance = IERC20(aToken).safeBalanceOf(address(this));
        amountAdded = int256(currentBalance) - int256(balance);
        if (amountAdded > 0) aaveLendingPool.withdraw(address(strategyToken), currentBalance - balance, address(this));
    }

    function _withdraw(uint256 amount) internal override {
        aaveLendingPool.withdraw(address(strategyToken), amount, address(this));
    }

    function _exit() internal override {
        uint256 tokenBalance = aToken.safeBalanceOf(address(this));
        uint256 available = strategyToken.safeBalanceOf(address(aToken));
        if (tokenBalance <= available) {
            /// @dev If there are more tokens available than our full position, take all based on aToken balance (continue if unsuccessful).
            try aaveLendingPool.withdraw(address(strategyToken), tokenBalance, address(this)) {} catch {}
        } else {
            /// @dev Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try aaveLendingPool.withdraw(address(strategyToken), available, address(this)) {} catch {}
        }
    }

    function _harvestRewards() internal override {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(aToken);
        uint256 reward = incentiveController.getRewardsBalance(rewardTokens, address(this));
        incentiveController.claimRewards(rewardTokens, reward, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseStrategy.sol";

/*  Example implementation stub to simplify strategy development.
	Please refer to the BaseStrategy contract natspec comments for
	further tips and clarifications. Also see the SushiStrategy and the
	AavePolygonStrategy for reference implementations. */
contract ExampleImplementation is BaseStrategy {
    // BaseStrategy initializes a immutable storage variable 'strategyToken' of type IERC20 we can use

    constructor(address investmentContract, BaseStrategy.BaseStrategyParams memory baseStrategyParams) public BaseStrategy(baseStrategyParams) {
        IERC20(baseStrategyParams.token).approve(investmentContract, type(uint256).max);
    }

    function _skim(uint256 amount) internal override {
        // assume strategyToken.balanceOf(address(this)) >= amount
        // invest the token
    }

    function _harvest(uint256 investedAmount) internal override returns (int256 delta) {
        // calculate the current amount we get if we withdraw the principal (not accounting for any received rewards)
        // if profitable, withdraw the surplus
        // return the difference between invested and current amount
    }

    function _harvestRewards() internal override {
        // implement the logic for claiming rewards and transfering them to address(this)
        // does not need to report the profits
        // skip if we expect no rewards
    }

    function _withdraw(uint256 amount) internal override {
        // withdraw the requested amount of tokens from the investment to address(this)
    }

    function _exit() internal override {
        // see what the available amount of tokens to withdraw is
        // withdraw as much tokens as possible from the investment to address(this)
        // should not revert
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

// solhint-disable const-name-snakecase

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBarMock is ERC20 {
    using BoringMath for uint256;
    ERC20 public sushi;
    uint256 public override totalSupply;
    string public constant name = "SushiBar";
    string public constant symbol = "xSushi";

    // Define the Sushi token contract
    constructor(ERC20 _sushi) public {
        sushi = _sushi;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply;
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime,
        // as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares) / totalSushi;
            _mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unclocks the staked + gained Sushi and burns xSushi
    function leave(uint256 _share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply;
        // Calculates the amount of Sushi the xSushi is worth
        uint256 what = _share.mul(sushi.balanceOf(address(this))) / totalShares;
        _burn(msg.sender, _share);
        sushi.transfer(msg.sender, what);
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        balanceOf[account] = balanceOf[account].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity 0.6.12;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;    

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_SIGNATURE_HASH,
                chainId,
                address(this)
            )
        );
    }

    constructor() public {
        uint256 chainId; assembly {chainId := chainid()}
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId; assembly {chainId := chainid()}
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    _domainSeparator(),
                    dataHash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IFlashLoan.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

contract SneakyFlashLoanerMock is IFlashBorrower, IBatchFlashBorrower {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256,
        uint256,
        bytes calldata
    ) external override {
        uint256 money = token.balanceOf(address(this));
        token.safeTransfer(sender, money);
    }

    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override {
        IERC20 token = tokens[0];
        uint256 money = token.balanceOf(address(this));
        token.safeTransfer(sender, money);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IFlashLoan.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

contract FlashLoanerMock is IFlashBorrower, IBatchFlashBorrower {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata
    ) external override {
        address bentoBox = address(msg.sender);
        uint256 payback = amounts[0].add(fees[0]);
        IERC20 token = tokens[0];
        uint256 money = token.balanceOf(address(this));
        token.safeTransfer(address(bentoBox), payback);
        uint256 winnings = money.sub(payback);
        token.safeTransfer(sender, winnings);
    }

    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external override {
        address bentoBox = address(msg.sender);
        uint256 payback = amount.add(fee);
        uint256 money = token.balanceOf(address(this));
        token.safeTransfer(address(bentoBox), payback);
        uint256 winnings = money.sub(payback);
        token.safeTransfer(sender, winnings);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";

contract ERC20Mock is ERC20WithSupply {
    constructor(uint256 _initialAmount) public {
        // Give the creator all initial tokens
        balanceOf[msg.sender] = _initialAmount;
        // Update total supply
        totalSupply = _initialAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// solhint-disable not-rely-on-time

contract SimpleStrategyMock is IStrategy {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    IERC20 private immutable token;
    address private immutable bentoBox;

    modifier onlyBentoBox() {
        require(msg.sender == bentoBox, "Ownable: caller is not the owner");
        _;
    }

    constructor(address bentoBox_, IERC20 token_) public {
        bentoBox = bentoBox_;
        token = token_;
    }

    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256) external override onlyBentoBox {
        // Leave the tokens on the contract
        return;
    }

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address) external override onlyBentoBox returns (int256 amountAdded) {
        amountAdded = int256(token.balanceOf(address(this)).sub(balance));
        token.safeTransfer(bentoBox, uint256(amountAdded)); // Add as profit
    }

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding or if the request was more than there is.
    function withdraw(uint256 amount) external override onlyBentoBox returns (uint256 actualAmount) {
        token.safeTransfer(bentoBox, uint256(amount)); // Add as profit
        actualAmount = amount;
    }

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external override onlyBentoBox returns (int256 amountAdded) {
        amountAdded = 0;
        token.safeTransfer(bentoBox, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "../interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// solhint-disable not-rely-on-time

interface ISushiBar is IERC20 {
    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;
}

contract MoneySink is IStrategy, BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    IERC20 public immutable sushi;
    address public immutable bentoBox;

    constructor(address _bentoBox, IERC20 _sushi) public {
        sushi = _sushi;
        bentoBox = _bentoBox;
    }

    function lose(uint256 amount) public {
        sushi.safeTransfer(0xdEad000000000000000000000000000000000000, amount);
    }

    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256) external override {
        return;
    }

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address) external override onlyOwner returns (int256 amountAdded) {
        uint256 realBalance = sushi.balanceOf(address(this));
        if (realBalance < balance) {
            amountAdded = -int256(balance.sub(realBalance));
        } else {
            amountAdded = int256(realBalance.sub(balance));
            sushi.safeTransfer(bentoBox, uint256(amountAdded));
        }
    }

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding or if the request was more than there is.
    function withdraw(uint256 amount) external override onlyOwner returns (uint256 actualAmount) {
        sushi.safeTransfer(owner, amount);
        actualAmount = amount;
    }

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external override onlyOwner returns (int256 amountAdded) {
        uint256 realBalance = sushi.balanceOf(address(this));
        if (realBalance < balance) {
            amountAdded = -int256(balance.sub(realBalance));
        } else {
            amountAdded = int256(realBalance.sub(balance));
        }
        sushi.safeTransfer(bentoBox, realBalance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// solhint-disable not-rely-on-time

contract DummyStrategyMock is IStrategy {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    IERC20 private immutable token;
    address private immutable bentoBox;

    int256 public _harvestProfit;

    modifier onlyBentoBox() {
        require(msg.sender == bentoBox, "Ownable: caller is not the owner");
        _;
    }

    constructor(address bentoBox_, IERC20 token_) public {
        bentoBox = bentoBox_;
        token = token_;
    }

    function setHarvestProfit(int256 val) public {
        _harvestProfit = val;
    }

    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256) external override onlyBentoBox {
        return;
    }

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(
        uint256 balance,
        address /*sender*/
    ) external override onlyBentoBox returns (int256 amountAdded) {
        if (_harvestProfit > 0) {
            amountAdded = int256(balance) + _harvestProfit;
        } else {
            amountAdded = int256(balance) - _harvestProfit;
        }
    }

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding or if the request was more than there is.
    function withdraw(uint256 amount) external override onlyBentoBox returns (uint256 actualAmount) {
        actualAmount = token.balanceOf(address(this));
        if (amount > actualAmount) {
            actualAmount = amount;
        }
        token.safeTransfer(msg.sender, actualAmount);
    }

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external override onlyBentoBox returns (int256 amountAdded) {
        uint256 moneyToBeTransferred = token.balanceOf(address(this));
        amountAdded = int256(moneyToBeTransferred) - int256(balance);
        // that is here to reach some branches in BentoBox
        if (_harvestProfit > 0) {
            amountAdded += _harvestProfit;
        } else {
            amountAdded -= _harvestProfit;
        }
        token.safeTransfer(msg.sender, moneyToBeTransferred);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

contract ExternalFunctionMock {
    using BoringMath for uint256;

    event Result(uint256 output);

    function sum(uint256 a, uint256 b) external returns (uint256 c) {
        c = a.add(b);
        emit Result(c);
    }
}

// SPDX-License-Identifier: MIT

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ISafeStrategy {
    function safeHarvest(
        uint256 maxBalance,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external;

    function swapExactTokensForUnderlying(uint256 amountOutMin, address inputToken) external;
}

contract CombineHarvester is BoringOwnable {
    function sellRewardTokens(
        ISafeStrategy[] memory strategies,
        uint256[] memory minOutAmounts,
        address[] memory inputTokens
    ) external onlyOwner {
        for (uint256 i = 0; i < strategies.length; i++) {
            strategies[i].swapExactTokensForUnderlying(minOutAmounts[i], inputTokens[i]);
        }
    }

    function executeSafeHarvests(
        ISafeStrategy[] memory strategies,
        uint256[] memory maxBalances,
        bool[] memory rebalance,
        uint256[] memory maxChangeAmounts,
        bool[] memory harvestRewards
    ) external onlyOwner {
        for (uint256 i = 0; i < strategies.length; i++) {
            strategies[i].safeHarvest(maxBalances[i], rebalance[i], maxChangeAmounts[i], harvestRewards[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../BentoBox.sol";

contract BentoBoxMock is BentoBox {
    constructor(IERC20 weth) public BentoBox(weth) {
        return;
    }

    function addProfit(IERC20 token, uint256 amount) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        totals[token].addElastic(amount);
    }
}

