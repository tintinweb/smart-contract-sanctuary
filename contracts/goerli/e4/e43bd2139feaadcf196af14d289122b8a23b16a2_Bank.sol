//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./libraries/Math.sol";

contract Bank is IBank {
    using DSMath for uint256;

    address private constant etherTokenAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address private priceOracleAddress;
    address private hakTokenAddress;

    // wallet address -> token address -> Account
    mapping(address => mapping(address => Account)) private deposits;
    // wallet address -> Account (this is only ETH debt!)
    mapping(address => Account) private borrowedEth;

    constructor(address _priceOracle, address _hakToken) {
        priceOracleAddress = _priceOracle;
        hakTokenAddress = _hakToken;
    }

    function _calcInterest(uint256 lastInterestBlock, uint256 deposit)
        internal
        view
        returns (uint256)
    {
        if (deposit == 0) return 0;
        uint256 currentBlock = block.number;
        uint256 blocksDiff = currentBlock.sub(lastInterestBlock);
        if (blocksDiff <= 0) return 0;
        uint256 interest = deposit.mul(blocksDiff).mul(3).div(10000);
        return interest;
    }

    function _calcDebtInterest(uint256 lastInterestBlock, uint256 deposit)
        internal
        view
        returns (uint256)
    {
        if (deposit == 0) return 0;
        uint256 currentBlock = block.number;
        uint256 blocksDiff = currentBlock.sub(lastInterestBlock);
        if (blocksDiff <= 0) return 0;
        uint256 interest = deposit.mul(blocksDiff).mul(5).div(10000);
        return interest;
    }

    function _recalcInterest(address token) internal {
        deposits[msg.sender][token].interest = deposits[msg.sender][token]
            .interest
            .add(
                _calcInterest(
                    deposits[msg.sender][token].lastInterestBlock,
                    deposits[msg.sender][token].deposit
                )
            );
        deposits[msg.sender][token].lastInterestBlock = block.number;
    }

    function _recalcDebtInterest() internal {
        borrowedEth[msg.sender].interest = borrowedEth[msg.sender].interest.add(
            _calcDebtInterest(
                borrowedEth[msg.sender].lastInterestBlock,
                borrowedEth[msg.sender].deposit
            )
        );
        borrowedEth[msg.sender].lastInterestBlock = block.number;
    }

    function deposit(address token, uint256 amount)
        external
        payable
        override
        returns (bool)
    {
        require(amount > 0, "cannot deposit zero or less");
        if (token == etherTokenAddress) {
            // eth case
            require(msg.value == amount);
        } else if (token == hakTokenAddress) {
            // hak case
            IERC20 hakTokenInstance = IERC20(token);
            // check if there's sufficient balance
            require(
                hakTokenInstance.balanceOf(msg.sender) >= amount,
                "insufficient balance"
            );
            // check if there's sufficient allowance
            require(
                hakTokenInstance.allowance(msg.sender, address(this)) >= amount,
                "insufficient allowance"
            );
            // transfer token
            if (
                !hakTokenInstance.transferFrom(
                    msg.sender,
                    address(this),
                    amount
                )
            ) {
                revert("transaction failed");
            }
        } else {
            // unknown token case
            revert("token not supported");
        }

        // update account
        _recalcInterest(token);
        deposits[msg.sender][token].deposit = deposits[msg.sender][token]
            .deposit
            .add(amount);

        // if we reach this, then it's all good
        emit Deposit(msg.sender, token, amount);

        return true;
    }

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256)
    {
        require(amount >= 0, "cannot withdraw a negative value");
        uint256 clientBalance = getBalance(token);

        if (amount == 0) {
            amount = clientBalance;
        }

        require(clientBalance > 0, "no balance");
        require(clientBalance >= amount, "amount exceeds balance");

        // check local contract balance sufficience
        if (token == etherTokenAddress) {
            // eth case
            require(
                address(this).balance >= amount,
                "insuffucient balance in contract"
            );
        } else if (token == hakTokenAddress) {
            // hak case
            IERC20 hakTokenInstance = IERC20(token);
            require(
                hakTokenInstance.balanceOf(address(this)) >= amount,
                "insuffucient balance in contract"
            );
        }

        // update interest size to reduce headache
        _recalcInterest(token);

        uint256 interestSize = deposits[msg.sender][token].interest.add(
            _calcInterest(
                deposits[msg.sender][token].lastInterestBlock,
                deposits[msg.sender][token].deposit
            )
        );
        deposits[msg.sender][token].interest = interestSize;

        if (amount <= interestSize) {
            // just deduct the interest
            deposits[msg.sender][token].interest = deposits[msg.sender][token]
                .interest
                .sub(amount);
        } else {
            // set interest to zero
            // and deduct remainder from deposit
            uint256 remainderForDepositPart = amount.sub(interestSize);
            deposits[msg.sender][token].deposit = deposits[msg.sender][token]
                .deposit
                .sub(remainderForDepositPart);
            deposits[msg.sender][token].interest = 0;
        }

        if (token == etherTokenAddress) {
            // eth case
            msg.sender.transfer(amount);
        } else if (token == hakTokenAddress) {
            // hak case
            IERC20 hakTokenInstance = IERC20(token);
            if (!hakTokenInstance.transfer(msg.sender, amount)) {
                revert("transfer failed");
            }
        }

        emit Withdraw(msg.sender, token, amount);

        return amount;
    }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256)
    {
        // we only allow ETH borrowing
        require(token == etherTokenAddress, "token not supported");
        require(amount >= 0, "cannot withdraw a negative value");

        // update interest size to reduce headache
        _recalcInterest(token);
        _recalcDebtInterest();

        uint256 currentHakBalance = getBalance(hakTokenAddress);
        uint256 currentHakBalanceInEth = _hakToEth(currentHakBalance);

        if (amount == 0) {
            amount = currentHakBalanceInEth.mul(10000).div(15000).sub(
                _getEthDebtBalance()
            );
        }

        // now check is the user has enough collateral
        // TODO: Disallow collateral withdrawal!?
        require(currentHakBalance > 0, "no collateral deposited");

        uint256 ratio = currentHakBalanceInEth.mul(10000).div(
            _getEthDebtBalance().add(amount)
        );

        require(ratio >= 15000, "borrow would exceed collateral ratio");

        // now check if the bank has enough eth to lend
        require(
            address(this).balance >= amount,
            "insuffucient balance in contract"
        );

        // update account
        _recalcDebtInterest();
        borrowedEth[msg.sender].deposit = borrowedEth[msg.sender].deposit.add(
            amount
        );

        uint256 newCollateral = getCollateralRatio(hakTokenAddress, msg.sender);

        // if we reach this, then it's all good
        emit Borrow(msg.sender, token, amount, newCollateral);

        // now we can send
        if (!msg.sender.send(amount)) {
            revert("transaction failed");
        }

        return newCollateral;
    }

    function repay(address token, uint256 amount)
        external
        payable
        override
        returns (uint256)
    {
        // we only allow ETH borrowing
        require(token == etherTokenAddress, "token not supported");
        if (amount == 0) {
            // max amount then
            amount = _getEthDebtBalance();
        }
        require(amount > 0, "cannot repay zero or less");
        require(_getEthDebtBalance() > 0, "nothing to repay");
        require(msg.value >= amount, "msg.value < amount to repay");
        require(msg.value <= amount, "msg.value > amount to repay");

        uint256 interestSize = borrowedEth[msg.sender].interest.add(
            _calcDebtInterest(
                borrowedEth[msg.sender].lastInterestBlock,
                borrowedEth[msg.sender].deposit
            )
        );
        borrowedEth[msg.sender].interest = interestSize;

        if (amount <= interestSize) {
            // just deduct the interest
            borrowedEth[msg.sender].interest = borrowedEth[msg.sender]
                .interest
                .sub(amount);
        } else {
            // set interest to zero
            // and deduct remainder from deposit
            uint256 remainderForDepositPart = amount.sub(interestSize);
            borrowedEth[msg.sender].deposit = borrowedEth[msg.sender]
                .deposit
                .sub(remainderForDepositPart);
            borrowedEth[msg.sender].interest = 0;
        }

        emit Repay(msg.sender, token, borrowedEth[msg.sender].deposit);
        return borrowedEth[msg.sender].deposit;
    }

    function liquidate(address token, address account)
        external
        payable
        override
        returns (bool)
    {
        // we only allow ETH borrowing
        require(token == hakTokenAddress, "token not supported");
        require(account != msg.sender, "cannot liquidate own position");

        uint256 debtorsRatio = getCollateralRatio(token, account);
        require(debtorsRatio < 15000, "healty position");

        uint256 debtorsDebt = _getEthDebtBalance(account);
        uint256 debtorsBalanceHak = _getBalance(account, hakTokenAddress);

        require(
            debtorsDebt <= msg.value,
            "insufficient ETH sent by liquidator"
        );

        uint256 amountSentBack = msg.value;
        amountSentBack = amountSentBack.sub(debtorsDebt);
        uint256 amountOfCollateral = debtorsBalanceHak;

        borrowedEth[account].deposit = 0;
        borrowedEth[account].interest = 0;
        borrowedEth[account].lastInterestBlock = block.number;

        emit Liquidate(
            msg.sender,
            account,
            token,
            amountOfCollateral, // amount of collateral token which is sent to the liquidator
            amountSentBack // amount of borrowed token that is sent back to the
            // liquidator in case the amount that the liquidator
            // sent for liquidation was higher than the debt of the liquidated account
        );

        // actually transfer now
        IERC20 hakTokenInstance = IERC20(hakTokenAddress);
        // check if there's sufficient balance
        require(
            hakTokenInstance.balanceOf(address(this)) >= debtorsBalanceHak,
            "insufficient balance"
        );
        hakTokenInstance.transfer(msg.sender, debtorsBalanceHak);

        if (!msg.sender.send(amountSentBack)) {
            revert("transaction failed");
        }

        return true;
    }

    function getCollateralRatio(address token, address account)
        public
        view
        override
        returns (uint256)
    {
        require(token == hakTokenAddress, "token not supported");

        if (_getEthDebtBalance(account) == 0) return type(uint256).max;
        uint256 currentHakBalance = _getBalance(account, hakTokenAddress);
        if (currentHakBalance == 0) return 0;
        return
            _hakToEth(currentHakBalance).mul(10000).div(
                _getEthDebtBalance(account)
            );
    }

    function _getBalance(address account, address token)
        internal
        view
        returns (uint256)
    {
        require(
            token == etherTokenAddress || token == hakTokenAddress,
            "token not supported"
        );

        return
            deposits[account][token]
                .interest
                .add(
                    _calcInterest(
                        deposits[account][token].lastInterestBlock,
                        deposits[account][token].deposit
                    )
                )
                .add(deposits[account][token].deposit);
    }

    function getBalance(address token) public view override returns (uint256) {
        return _getBalance(msg.sender, token);
    }

    function _getEthDebtBalance(address account)
        internal
        view
        returns (uint256)
    {
        return
            borrowedEth[account]
                .interest
                .add(
                    _calcDebtInterest(
                        borrowedEth[account].lastInterestBlock,
                        borrowedEth[account].deposit
                    )
                )
                .add(borrowedEth[account].deposit);
    }

    function _getEthDebtBalance() internal view returns (uint256) {
        return _getEthDebtBalance(msg.sender);
    }

    function _hakToEth(uint256 amount) internal view returns (uint256) {
        IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
        return
            amount.mul(priceOracle.getVirtualPrice(hakTokenAddress)).div(
                1 ether
            );
    }

    function _ethToHak(uint256 amount) internal view returns (uint256) {
        IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
        return
            amount.div(priceOracle.getVirtualPrice(hakTokenAddress)).mul(
                1 ether
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

interface IBank {
    struct Account {
        // Note that token values have an 18 decimal precision
        uint256 deposit; // accumulated deposits made into the account
        uint256 interest; // accumulated interest
        uint256 lastInterestBlock; // block at which interest was last computed
    }
    // Event emitted when a user makes a deposit
    event Deposit(
        address indexed _from, // account of user who deposited
        address indexed token, // token that was deposited
        uint256 amount // amount of token that was deposited
    );
    // Event emitted when a user makes a withdrawal
    event Withdraw(
        address indexed _from, // account of user who withdrew funds
        address indexed token, // token that was withdrawn
        uint256 amount // amount of token that was withdrawn
    );
    // Event emitted when a user borrows funds
    event Borrow(
        address indexed _from, // account who borrowed the funds
        address indexed token, // token that was borrowed
        uint256 amount, // amount of token that was borrowed
        uint256 newCollateralRatio // collateral ratio for the account, after the borrow
    );
    // Event emitted when a user (partially) repays a loan
    event Repay(
        address indexed _from, // accout which repaid the loan
        address indexed token, // token that was borrowed and repaid
        uint256 remainingDebt // amount that still remains to be paid (including interest)
    );
    // Event emitted when a loan is liquidated
    event Liquidate(
        address indexed liquidator, // account which performs the liquidation
        address indexed accountLiquidated, // account which is liquidated
        address indexed collateralToken, // token which was used as collateral
        // for the loan (not the token borrowed)
        uint256 amountOfCollateral, // amount of collateral token which is sent to the liquidator
        uint256 amountSentBack // amount of borrowed token that is sent back to the
        // liquidator in case the amount that the liquidator
        // sent for liquidation was higher than the debt of the liquidated account
    );

    /**
     * The purpose of this function is to allow end-users to deposit a given
     * token amount into their bank account.
     * @param token - the address of the token to deposit. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then
     *                the token to deposit is ETH.
     * @param amount - the amount of the given token to deposit.
     * @return - true if the deposit was successful, otherwise revert.
     */
    function deposit(address token, uint256 amount)
        external
        payable
        returns (bool);

    /**
     * The purpose of this function is to allow end-users to withdraw a given
     * token amount from their bank account. Upon withdrawal, the user must
     * automatically receive a 3% interest rate per 100 blocks on their deposit.
     * @param token - the address of the token to withdraw. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then
     *                the token to withdraw is ETH.
     * @param amount - the amount of the given token to withdraw. If this param
     *                 is set to 0, then the maximum amount available in the
     *                 caller's account should be withdrawn.
     * @return - the amount that was withdrawn plus interest upon success,
     *           otherwise revert.
     */
    function withdraw(address token, uint256 amount) external returns (uint256);

    /**
     * The purpose of this function is to allow users to borrow funds by using their
     * deposited funds as collateral. The minimum ratio of deposited funds over
     * borrowed funds must not be less than 150%.
     * @param token - the address of the token to borrow. This address must be
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, otherwise
     *                the transaction must revert.
     * @param amount - the amount to borrow. If this amount is set to zero (0),
     *                 then the amount borrowed should be the maximum allowed,
     *                 while respecting the collateral ratio of 150%.
     * @return - the current collateral ratio.
     */
    function borrow(address token, uint256 amount) external returns (uint256);

    /**
     * The purpose of this function is to allow users to repay their loans.
     * Loans can be repaid partially or entirely. When repaying a loan, an
     * interest payment is also required. The interest on a loan is equal to
     * 5% of the amount lent per 100 blocks. If the loan is repaid earlier,
     * or later then the interest should be proportional to the number of
     * blocks that the amount was borrowed for.
     * @param token - the address of the token to repay. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then
     *                the token is ETH.
     * @param amount - the amount to repay including the interest.
     * @return - the amount still left to pay for this loan, excluding interest.
     */
    function repay(address token, uint256 amount)
        external
        payable
        returns (uint256);

    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan.
     * @param token - the address of the token used as collateral for the loan.
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account)
        external
        payable
        returns (bool);

    /**
     * The purpose of this function is to return the collateral ratio for any account.
     * The collateral ratio is computed as the value deposited divided by the value
     * borrowed. However, if no value is borrowed then the function should return
     * uint256 MAX_INT = type(uint256).max
     * @param token - the address of the deposited token used a collateral for the loan.
     * @param account - the account that took out the loan.
     * @return - the value of the collateral ratio with 2 percentage decimals, e.g. 1% = 100.
     *           If the account has no deposits for the given token then return zero (0).
     *           If the account has deposited token, but has not borrowed anything then
     *           return MAX_INT.
     */
    function getCollateralRatio(address token, address account)
        external
        view
        returns (uint256);

    /**
     * The purpose of this function is to return the balance that the caller
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalance(address token) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

interface IPriceOracle {
    /**
     * The purpose of this function is to retrieve the price of the given token
     * in ETH. For example if the price of a HAK token is worth 0.5 ETH, then
     * this function will return 500000000000000000 (5e17) because ETH has 18 
     * decimals. Note that this price is not fixed and might change at any moment,
     * according to the demand and supply on the open market.
     * @param token - the ERC20 token for which you want to get the price in ETH.
     * @return - the price in ETH of the given token at that moment in time.
     */
    function getVirtualPrice(address token) view external returns (uint256);
}

//SPDX-License-Identifier: AGPL-3.0-or-later
/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.0;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    // TODO: verify this div
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "division by zero");
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}