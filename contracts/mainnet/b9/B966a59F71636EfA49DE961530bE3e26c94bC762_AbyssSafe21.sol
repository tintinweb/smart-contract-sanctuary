/*
░█████╗░██████╗░██╗░░░██╗░██████╗░██████╗  ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔════╝██╔════╝  ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
███████║██████╦╝░╚████╔╝░╚█████╗░╚█████╗░  █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
██╔══██║██╔══██╗░░╚██╔╝░░░╚═══██╗░╚═══██╗  ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║░░██║██████╦╝░░░██║░░░██████╔╝██████╔╝  ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═════╝░╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AbyssSafeBase.sol";

/**
 * Abyss Finance's AbyssSafe Contract
 * The main smart contract that is responsible for deposits and withdrawal of tokens.
 */
contract AbyssSafe21 is AbyssSafeBase {
    uint256 public override constant unlockTime = 1814400; // mainnet
    // uint256 public override constant unlockTime = 1260; // testnet

    constructor(address token, address lockup, uint256 abyssRequired) AbyssSafeBase(token, lockup, unlockTime, abyssRequired) {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../contracts/interfaces/IAbyssLockup.sol";

/**
 * Abyss Finance's AbyssSafeBase Contract
 * The main smart contract that is responsible for deposits and withdrawal of tokens.
 */
contract AbyssSafeBase is ReentrancyGuard, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    IERC20 public tokenContract;
    IAbyssLockup public lockupContract;
    uint256 private _unlockTime;
    uint256 private _abyssRequired;

    /**
     * @dev The parameter responsible for global disabling and enabling of new deposits.
     */
    bool public disabled;

    /**
     * @dev Here we store data for each locked token address of a specific wallet.
     *
     * - deposited - Amount of deposited tokens.
     * - requested - Amount of requested tokens for withdrawing.
     * - timestamp - Token deposit time or token unlock time established at an active withdrawal request
     */
    struct Data {
        uint256 deposited;
        uint256 divFactorDeposited;
        uint256 requested;
        uint256 divFactorRequested;
        uint256 timestamp;
    }

    /**
     * @dev Here we store data for every ever locked token on this smart contract.
     *
     * - disabled - A true value implies that this token cannot be deposited on the smart contract, while all other actions are allowed.
     * - approved - A true value implies that lockupContract is approved on transferFrom this smart contract.
     * - deposited - A total deposited token amount on the smart contract for the token address.
     * - requested - A total requested token amount from the smart contract.
     */
    struct Token {
        bool disabled;
        bool approved;
        uint256 deposited;
        uint256 divFactorDeposited;
        uint256 requested;
        uint256 divFactorRequested;
    }

    mapping (address => mapping (address => Data)) private _data;
    mapping (address => Token) private _tokens;

    /**
     * @dev Stores the amount of Abyss required for withdrawals after deposit for the caller's address.
     */
    mapping (address => uint256) private _rates;

    constructor(address token, address lockup, uint256 unlockTime_, uint256 abyssRequired_) {
        tokenContract = IERC20(address(token));
        lockupContract = IAbyssLockup(address(lockup));
        _unlockTime = unlockTime_;
        _abyssRequired = abyssRequired_;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Amount of Abyss required for service usage.
     */
    function abyssRequired() public view returns (uint256) {
        return _abyssRequired;
    }

    /**
     * @dev Amount of Abyss required for withdrawal requests and withdraw after deposit is made.
     */
    function rate(address account) public view returns (uint256) {
        return _rates[account];
    }

    /**
     * @dev Time of possible `token` withdrawal for the `account` if withdrawal request was made.
     * Time of `token` deposit if there were no withdrawal requests by the `account`.
     */
    function timestamp(address account, address token) public view returns (uint256) {
        return _data[account][token].timestamp;
    }

    /**
     * @dev Amount of `token` deposited by the `account`.
     */
    function deposited(address account, address token) public view returns (uint256) {
        return _data[account][token].deposited;
    }

    /**
     * @dev Amount of `token` requested for withdrawal by the `account`.
     */
    function requested(address account, address token) public view returns (uint256) {
        return _data[account][token].requested;
    }

    /**
     * @dev divFactor (rebase support) for specific `account` and `token` deposited.
     */
    function divFactorDeposited(address account, address token) public view returns (uint256) {
        return _data[account][token].divFactorDeposited;
    }

    /**
     * @dev divFactor (rebase support) for specific `account` and `token` requested.
     */
    function divFactorRequested(address account, address token) public view returns (uint256) {
        return _data[account][token].divFactorRequested;
    }

    /**
     * @dev Total mount of `token` deposited to this smart contract.
     */
    function totalDeposited(address token) public view returns (uint256) {
        return _tokens[token].deposited;
    }

    /**
     * @dev Total mount of `token` requested for withdrawal from this smart contract.
     */
    function totalRequested(address token) public view returns (uint256) {
        return _tokens[token].requested;
    }

    /**
     * @dev divFactor (rebase support) for specific `token` deposited.
     */
    function totalDivFactorDeposited(address token) public view returns (uint256) {
        return _tokens[token].divFactorDeposited;
    }

    /**
     * @dev divFactor (rebase support) for specific `token` requested.
     */
    function totalDivFactorRequested(address token) public view returns (uint256) {
        return _tokens[token].divFactorRequested;
    }

    /**
     * @dev Shows if specific `token` is disabled in this smart contract.
     */
    function isTokenDisabled(address token) public view returns (bool) {
        return _tokens[token].disabled;
    }

    /**
     * @dev Shows if specific `address` is a manager of this smart contract.
     */
    function isManager(address manager) public view returns (bool) {
        return _tokens[manager].approved;
    }

    /**
     * @dev Shows the unlock period that you need to wait after withdrawal request.
     */
    function unlockTime() external virtual view returns (uint256) {
        return _unlockTime;
    }

    // ACTION FUNCTIONS

    /**
     * @dev Moves `amount` of `token` from the caller's account to this smart contract.
     *
     * Requirements:
     *
     * - Contract is active and deposits for a specific token are not prohibited.
     * - Required Abyss amount is available on the account.
     * - Token smart contract has the right to move the tokens intended for deposit.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function deposit(address token, uint256 amount, address receiver) public nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(disabled == false && _tokens[token].disabled == false, "AbyssSafe: disabled");
        if (receiver == 0x0000000000000000000000000000000000000000) {
            receiver = msg.sender;
        }
        require(Address.isContract(receiver) == false, "AbyssSafe: receiver cannot be a smart contract");
        require(Address.isContract(token) == true, "AbyssSafe: token must be a smart contract");

        uint256 _tempFreeDeposits;

        if (_abyssRequired > 0 && token != address(tokenContract)) {
            _tempFreeDeposits = lockupContract.freeDeposits();
            require(_tempFreeDeposits > 0 || tokenContract.balanceOf(msg.sender) >= _abyssRequired, "AbyssSafe: not enough Abyss");
        }

        require(IERC20(address(token)).allowance(msg.sender, address(lockupContract)) > amount, "AbyssSafe: you need to approve token first");
        require(IERC20(address(token)).balanceOf(msg.sender) >= amount && amount > 0, "AbyssSafe: you cannot lock this amount");

        /**
         * @dev Verifies that the `lockupContract` has permission to move a given token located on this contract.
         */
        if (_tokens[token].approved == false) {

            /**
             * @dev Add permission to move `token` from this contract for `lockupContract`.
             */
            SafeERC20.safeApprove(IERC20(address(token)), address(lockupContract), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
            /**
             * @dev Verify that the permission was correctly applied to exclude any future uncertainties.
             */
            require(IERC20(address(token)).allowance(address(this), address(lockupContract)) > 0, "AbyssSafe: allowance issue");
            /**
             * @dev Add verification flag to improve efficiency and avoid revisiting the token smart contract, for gas economy.
             */
            _tokens[token].approved = true;
        }

        uint256 _tempBalanceSafe = IERC20(address(token)).balanceOf(address(this));

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tokens[token].deposited != _tempBalanceSafe) {
            if (_tokens[token].deposited > 0) {
                calcDivFactorDepositedTotal(token, _tempBalanceSafe);
            } else {
                lockupContract.externalTransfer(token, address(this), owner(), _tempBalanceSafe, 0);
                _tempBalanceSafe = 0;
            }
        }

        if (_tokens[token].divFactorDeposited == 0) {
            _tokens[token].divFactorDeposited = 1e36;
        }

        if (_data[receiver][token].divFactorDeposited == 0) {
            _data[receiver][token].divFactorDeposited = _tokens[token].divFactorDeposited;
        } else if (_data[receiver][token].divFactorDeposited != _tokens[token].divFactorDeposited) {
            calcDivFactorDeposited(receiver, token);
        }

        /**
         * @dev Writes down the cost of using the service so that any future amount requirement
         * increases won’t affect pre-existing users until they make a new deposit.
         */
        if (_tempFreeDeposits > 0) {
            _rates[receiver] = 0;
        } else {
            _rates[receiver] = _abyssRequired;
        }

        /**
         * @dev Moves `amount` of `token` from the caller's account to this smart contract with the help of `lockupContract` smart contract.
         */
        lockupContract.externalTransfer(token, msg.sender, address(this), amount, _abyssRequired);

        uint256 _tempBalanceSafeAfter = IERC20(address(token)).balanceOf(address(this));

        if (_tempBalanceSafe + amount != _tempBalanceSafeAfter) {
            amount = _tempBalanceSafeAfter - _tempBalanceSafe;
        }

        /**
         * @dev Increases the number of deposited User tokens.
         */
        _data[receiver][token].deposited = _data[receiver][token].deposited + amount;

        /**
         * @dev Changes the total amount of deposited tokens.
         */
        _tokens[token].deposited = _tokens[token].deposited + amount;

        emit Deposit(receiver, msg.sender, token, amount);
        return true;
    }

    /**
     * @dev Creates withdrawal request for the full amount of `token` deposited to this smart contract by the caller's account.
     *
     * Requirements:
     *
     * - Required Abyss amount is available on the account.
     * - There is no pending active withdrawal request for `token` by the caller's account.
     * - The caller has any amount of `token` deposited to this smart contract.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function request(address token, uint256 amount) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(
            _rates[msg.sender] == 0 ||
            token == address(tokenContract) ||
            tokenContract.balanceOf(msg.sender) >= _rates[msg.sender],
            "AbyssSafe: not enough Abyss");
        require(_data[msg.sender][token].requested == 0, "AbyssSafe: you already requested");
        require(_data[msg.sender][token].deposited > 0, "AbyssSafe: nothing to withdraw");

        uint256 _tempBalanceSafe = IERC20(address(token)).balanceOf(address(this));

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tokens[token].deposited != _tempBalanceSafe) {
                calcDivFactorDepositedTotal(token, _tempBalanceSafe);
        }

        if (_data[msg.sender][token].divFactorDeposited != _tokens[token].divFactorDeposited) {
            calcDivFactorDeposited(msg.sender, token);

            if (_data[msg.sender][token].deposited == 0) {
                delete _data[msg.sender][token].divFactorDeposited;
                delete _data[msg.sender][token].divFactorRequested;
                return true;
            }
        }

        uint256 _tempLockupBalance = IERC20(address(token)).balanceOf(address(lockupContract));
        uint256 _tempDepositedLockup = IAbyssLockup(address(lockupContract)).deposited(token);
        uint256 _tempLockupDivFactor = IAbyssLockup(address(lockupContract)).divFactor(token);

        if (_tempLockupBalance == 0) {
            delete _tokens[token].requested;
            delete _tokens[token].divFactorRequested;
            lockupContract.resetData(token);
        }
        if (_tempDepositedLockup != _tempLockupBalance) {
            if (_tempDepositedLockup > 0) {
                _tempLockupDivFactor = calcDivFactorLockup(_tempLockupDivFactor, _tempLockupBalance, _tempDepositedLockup);
            } else {
                lockupContract.externalTransfer(token, address(lockupContract), owner(), _tempLockupBalance, 0);
                _tempLockupBalance = 0;
            }
        }

        if (_tokens[token].divFactorRequested != _tempLockupDivFactor) {
            if (_tokens[token].divFactorRequested != 0) {
                _tokens[token].requested = _tokens[token].requested * _tempLockupDivFactor / _tokens[token].divFactorRequested;
            }
            _tokens[token].divFactorRequested = _tempLockupDivFactor;
        } else if (_tempLockupDivFactor == 0) {
            _tempLockupDivFactor = 1e36;
            _tokens[token].divFactorRequested = 1e36;
        }

        _data[msg.sender][token].divFactorRequested = _tokens[token].divFactorRequested;

        if (_data[msg.sender][token].deposited < amount || amount == 0) {
            amount = _data[msg.sender][token].deposited;
        }

        /**
         * @dev Changes the total amount of deposited `token` by the amount of withdrawing request in the decreasing direction.
         */
        _tokens[token].deposited = _tokens[token].deposited - amount;

        /**
         * @dev Changes the caller's amount of deposited `token` by the amount of withdrawing request in the decreasing direction.
         */
        if (amount == _data[msg.sender][token].deposited) {
            delete _data[msg.sender][token].deposited;
            delete _data[msg.sender][token].divFactorDeposited;
            if (_tokens[token].deposited == 0) {
                delete _tokens[token].divFactorDeposited;
            }
        } else {
            _data[msg.sender][token].deposited = _data[msg.sender][token].deposited - amount;
        }

        /**
         * @dev Sets a date for `lockupTime` seconds from the current date.
         */
        _data[msg.sender][token].timestamp = block.timestamp + _unlockTime;

        /**
         * @dev If `token` balance on this smart contract is greater than zero,
         * sends tokens to the 'lockupContract' smart contract.
         */
        lockupContract.externalTransfer(token, address(this), address(lockupContract), amount, 0);

        uint256 _tempLockupBalanceAfter = IERC20(address(token)).balanceOf(address(lockupContract));

        if (_tempLockupBalance + amount != _tempLockupBalanceAfter) {
            amount = _tempLockupBalanceAfter - _tempLockupBalance;
        }

        _tempLockupBalance = _tempLockupBalance + amount;

        lockupContract.updateData(token, _tempLockupBalance, _tempLockupDivFactor);

        /**
         * @dev Changes the total amount of requested `token by the sum of the withdrawing request in the increasing direction.
         */
        _tokens[token].requested = _tokens[token].requested + amount;

        /**
         * @dev The requested amount of the caller's tokens for withdrawal request becomes equal to the amount requested.
         */
        _data[msg.sender][token].requested = amount;

        _tempLockupBalance = _tempLockupBalance + amount;

        emit Request(msg.sender, token, amount, _data[msg.sender][token].timestamp);
        return true;
    }

    /**
     * @dev Cancels withdrawal request for the full amount of `token` requested from this smart contract by the caller's account.
     *
     * Requirement:
     *
     * - There is a pending active withdrawal request for `token` by the caller's account.
     */
    function cancel(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(_data[msg.sender][token].requested > 0, "AbyssSafe: nothing to cancel");

        uint256 _tempAmount = _data[msg.sender][token].requested;

        uint256 _tempLockupBalance = IERC20(address(token)).balanceOf(address(lockupContract));
        uint256 _tempLockupBalance2;
        uint256 _tempBalanceSafe = IERC20(address(token)).balanceOf(address(this));
        uint256 _tempDepositedLockup = IAbyssLockup(address(lockupContract)).deposited(token);
        uint256 _tempLockupDivFactor = IAbyssLockup(address(lockupContract)).divFactor(token);
        uint256 _tempTimestamp = _data[msg.sender][token].timestamp;

        if (_tempLockupBalance == 0) {
            delete _data[msg.sender][token].requested;
            delete _data[msg.sender][token].divFactorRequested;
            delete _tokens[token].requested;
            delete _tokens[token].divFactorRequested;
            lockupContract.resetData(token);
            return true;
        }

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tokens[token].deposited != _tempBalanceSafe) {
            if (_tokens[token].deposited > 0) {
                calcDivFactorDepositedTotal(token, _tempBalanceSafe);
            } else {
                lockupContract.externalTransfer(token, address(this), owner(), _tempBalanceSafe, 0);
                _tempBalanceSafe = 0;
            }
        }

        if (_tokens[token].divFactorDeposited == 0) {
            _tokens[token].divFactorDeposited = 1e36;
        }

        if (_data[msg.sender][token].divFactorDeposited != _tokens[token].divFactorDeposited) {
            if (_data[msg.sender][token].divFactorDeposited == 0) {
                _data[msg.sender][token].divFactorDeposited = _tokens[token].divFactorDeposited;
            } else {
                calcDivFactorDeposited(msg.sender, token);
            }
        }

        if (_tempDepositedLockup != _tempLockupBalance) {
            _tempLockupDivFactor = calcDivFactorLockup(_tempLockupDivFactor, _tempLockupBalance, _tempDepositedLockup);
        }

        if (_tokens[token].divFactorRequested != _tempLockupDivFactor) {
            calcDivFactorRequestedTotal(token, _tempLockupDivFactor);
        }

        if (_data[msg.sender][token].divFactorRequested != _tokens[token].divFactorRequested) {
            _tempAmount = calcDivFactorRequested(_tempLockupDivFactor, _data[msg.sender][token].divFactorRequested, _tempAmount);

            if (_tokens[token].requested < _tempAmount) {
                _tempAmount = _tokens[token].requested;
            }
            _data[msg.sender][token].divFactorRequested = _tokens[token].divFactorRequested;
        }

        delete _data[msg.sender][token].divFactorRequested;

        /**
         * @dev Changes the total amount of requested `token` by the cancelation withdrawal amount in the decreasing direction.
         */
        _tokens[token].requested = _tokens[token].requested - _tempAmount;

        /**
         * @dev Removes `token` divFactor if balance of the requested `token` is 0 after withdraw cancelation.
         */
        if (_tokens[token].requested == 0) {
            delete _tokens[token].divFactorRequested;
        }

        /**
         * @dev Taking withdrawal request cancellation into account, restores the caller's `token` balance.
         */
        _data[msg.sender][token].deposited = _data[msg.sender][token].deposited + _tempAmount;

        /**
         * @dev Resets information on the number of `token` requested by the caller for withdrawal request.
         */
        delete _data[msg.sender][token].requested;

        /**
         * @dev Calculates the new balance of `token` on `lockup` smart contract.
         */
        _tempLockupBalance2 = _tempLockupBalance - _tempAmount;

        /**
         * @dev Removes divFactor on `lockup` smart contract if balane of the `token` is 0 after withdraw.
         */
        if (_tempLockupBalance2 == 0) {
            _tempLockupDivFactor = 1;
        }

        /**
         * @dev Reset the unblocking time to zero.
         */
        delete _data[msg.sender][token].timestamp;

        lockupContract.externalTransfer(token, address(lockupContract), address(this), _tempAmount, 0);
        lockupContract.updateData(token, _tempLockupBalance2, _tempLockupDivFactor);


        _tempLockupBalance2 = IERC20(address(token)).balanceOf(address(this));

        if (_tempBalanceSafe + _tempAmount != _tempLockupBalance2) {
            _tempAmount = _tempLockupBalance2 - _tempBalanceSafe;
        }

        /**
         * @dev Changes the total amount of deposited `token` by the amount of withdrawing request in the increasing direction.
         */
        _tokens[token].deposited = _tokens[token].deposited + _tempAmount;

        emit Cancel(msg.sender, token, _tempAmount, _tempTimestamp);
        return true;
    }

    /**
     * @dev Withdraws the full amount of `token` requested from this smart contract by the caller's account.
     *
     * Requirement:
     *
     * - Required Abyss amount is available on the account.
     * - There is pending active withdrawal request for `token` by the caller's account.
     * - Required amount of time has already passed since withrawal request execution.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function withdraw(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(
            _rates[msg.sender] == 0 ||
            token == address(tokenContract) ||
            tokenContract.balanceOf(msg.sender) >= _rates[msg.sender],
            "AbyssSafe: not enough Abyss");
        require(_data[msg.sender][token].requested > 0, "AbyssSafe: request withdraw first");
        require(_data[msg.sender][token].timestamp <= block.timestamp, "AbyssSafe: patience you must have!");

        uint256 _tempAmount = _data[msg.sender][token].requested;
        uint256 _tempLockupBalance = IERC20(address(token)).balanceOf(address(lockupContract));
        uint256 _tempLockupBalance2;
        uint256 _tempDepositedLockup = IAbyssLockup(address(lockupContract)).deposited(token);
        uint256 _tempLockupDivFactor = IAbyssLockup(address(lockupContract)).divFactor(token);

        /**
         * @dev Code that supports rebase of specific `token`.
         */
        if (_tempLockupBalance == 0) {
            delete _data[msg.sender][token].requested;
            delete _data[msg.sender][token].divFactorRequested;
            delete _tokens[token].requested;
            delete _tokens[token].divFactorRequested;
            lockupContract.resetData(token);
            return true;
        }

        if (_tempDepositedLockup != _tempLockupBalance) {
            _tempLockupDivFactor = calcDivFactorLockup(_tempLockupDivFactor, _tempLockupBalance, _tempDepositedLockup);
        }

        if (_tokens[token].divFactorRequested != _tempLockupDivFactor) {
            calcDivFactorRequestedTotal(token, _tempLockupDivFactor);
        }

        if (_data[msg.sender][token].divFactorRequested != _tokens[token].divFactorRequested) {
            _tempAmount = calcDivFactorRequested(_tempLockupDivFactor, _data[msg.sender][token].divFactorRequested, _tempAmount);

            if (_tokens[token].requested < _tempAmount) {
                _tempAmount = _tokens[token].requested;
            }

        }

        delete _data[msg.sender][token].divFactorRequested;

        /**
         * @dev Changes the total amount of requested `token` by the cancelation withdrawal amount in the decreasing direction.
         */
        _tokens[token].requested = _tokens[token].requested - _tempAmount;

        /**
         * @dev Removes `token` divFactor if balance of the requested `token` is 0 after withdraw.
         */
        if (_tokens[token].requested == 0) {
            delete _tokens[token].divFactorRequested;
        }

        /**
         * @dev Removes information about amount of requested `token`.
         */
        delete _data[msg.sender][token].requested;

        if (_tempAmount == 0) {
            delete _data[msg.sender][token].timestamp;
            return true;
        }

        /**
         * @dev Calculates the new balance of token on lockup smart contract.
         */
        _tempLockupBalance2 = _tempLockupBalance - _tempAmount;

        /**
         * @dev Removes divFactor on `lockup` smart contract if balane of the `token` is 0 after withdraw.
         */
        if (_tempLockupBalance2 == 0) {
            _tempLockupDivFactor = 1;
        }

        /**
         * @dev Withdraws tokens to the caller's address.
         */
        lockupContract.externalTransfer(token, address(lockupContract), msg.sender, _tempAmount, 0);
        lockupContract.updateData(token, _tempLockupBalance2, _tempLockupDivFactor);

        _tempLockupBalance2 = IERC20(address(token)).balanceOf(address(lockupContract));

        if (_tempLockupBalance != _tempLockupBalance2 + _tempAmount) {
            _tempAmount = _tempLockupBalance - _tempLockupBalance2;
        }

        emit Withdraw(msg.sender, token, _tempAmount, _data[msg.sender][token].timestamp);

        /**
         * @dev Reset the unblocking time to zero.
         */
        delete _data[msg.sender][token].timestamp;
        return true;

    }

    // REBASE CALCULATION FUNCTIONS

    function calcDivFactorDepositedTotal(address _token, uint256 _balanceSafe) internal {
        _tokens[_token].divFactorDeposited = _tokens[_token].divFactorDeposited * _balanceSafe / _tokens[_token].deposited;
        _tokens[_token].deposited = _balanceSafe;
    }

    function calcDivFactorRequestedTotal(address _token, uint256 _lockupDivFactor) internal {
        _tokens[_token].requested = _tokens[_token].requested * _lockupDivFactor / _tokens[_token].divFactorRequested;
        _tokens[_token].divFactorRequested = _lockupDivFactor;
    }

    function calcDivFactorDeposited(address _owner, address _token) internal {
        _data[_owner][_token].deposited = _data[_owner][_token].deposited * _tokens[_token].divFactorDeposited / _data[_owner][_token].divFactorDeposited;
        _data[_owner][_token].divFactorDeposited = _tokens[_token].divFactorDeposited;
    }

    function calcDivFactorRequested(uint256 _lockupDivFactor, uint256 _divFactorRequested, uint256 _amount) internal pure returns (uint256) {
        return _amount * _lockupDivFactor / _divFactorRequested;
    }

    function calcDivFactorLockup(uint256 _lockupDivFactor, uint256 _lockupBalance, uint256 _lockupDeposited) internal pure returns (uint256) {
        return _lockupDivFactor * _lockupBalance / _lockupDeposited;
    }

    // ADMIN FUNCTIONS

    /**
     * @dev Initializes configuration of a given smart contract, with a specified
     * address for the `lockupContract` smart contract.
     *
     * This value is immutable: it can only be set once.
     */
    function initialize(address lockupContract_) external onlyOwner returns (bool) {
        require(address(lockupContract) == address(0), "AbyssSafe: already initialized");
        lockupContract = IAbyssLockup(lockupContract_);
        return true;
    }

    /**
     * @dev Configurates smart contract allowing modification in the amount of
     * required Abyss to use the smart contract.
     *
     * NOTE: The price for pre-existing users will remain unchanged until
     * a new token deposit is made. This aspect has been considered to prevent
     * possibility of increase pricing for already made deposits.
     *
     * Also, this function allows disabling of deposits, both globally and for a specific token.
     */
    function setup(address token, bool tokenDisabled, bool globalDisabled, uint256 abyssRequired_) external onlyManager(msg.sender) returns (bool) {
        disabled = globalDisabled;
        if (token != address(this)) {
            _tokens[token].disabled = tokenDisabled;
        }
        _abyssRequired = abyssRequired_;
        return true;
    }

    /**
     * @dev Allows the `owner` to assign managers who can use the setup function.
     */
    function setManager(address manager) external onlyOwner returns (bool) {

        if (_tokens[manager].approved == false) {
            _tokens[manager].approved = true;
        } else {
            _tokens[manager].approved = false;
        }
        return true;
    }

    /**
     * @dev A function that allows the `owner` to withdraw any locked and lost tokens
     * from the smart contract if such `token` is not yet deposited.
     *
     * NOTE: Embedded in the function is verification that allows for token withdrawal
     * only if the token balance is greater than the token balance deposited on the smart contract.
     */
    function withdrawLostTokens(address token) external onlyOwner returns (bool) {
        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(this));

        if (_tokens[token].deposited == 0 && _tempBalance > 0) {
            SafeERC20.safeTransfer(IERC20(address(token)), msg.sender, _tempBalance);
        }

        return true;
    }

    /**
     * @dev A function that allows to set allowance between this and lockup smart contract if something went wrong.
     */
    function manualApprove(address token) external returns (bool) {
        SafeERC20.safeApprove(IERC20(address(token)), address(lockupContract), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        return true;
    }

    /**
     * @dev Modifier that prohibits execution of this smart contract from `token` address
     */
    modifier isAllowed(address account, address token) {
        require(account != token, "AbyssSafe: you shall not pass!");
        _;
    }

    /**
     * @dev Modifier that allows usage only for managers chosen by the `owner`.
    */
    modifier onlyManager(address account) {
        require(_tokens[account].approved || account == owner(), "AbyssSafe: you shall not pass!");
        _;
    }

    event Deposit(address indexed user, address indexed depositor, address token, uint256 amount);
    event Request(address indexed user, address token, uint256 amount, uint256 timestamp);
    event Cancel(address indexed user, address token, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, address token, uint256 amount, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the AbyssLockup smart contract.
 */
interface IAbyssLockup {

    /**
     * @dev Returns amount requested for the `token` withdrawal
     * on all `safeContract` smart contracts.
     */
    function deposited(address token) external view returns (uint256);

    /**
     * @dev Returns divFactor requested for the specific `token`.
     */
    function divFactor(address token) external view returns (uint256);

    /**
     * @dev Returns the amount of free deposits left.
     */
    function freeDeposits() external returns (uint256);

    /**
     * @dev Moves `amount` tokens from the `sender` account to `recipient`.
     *
     * This function can be called only by `safeContract` smart contracts: {onlyContract} modifier.
     *
     * All tokens are moved only from `AbyssLockup`smart contract so only one
     * token approval is required.
     *
     * Sets divFactor and deposit amount of specific `token`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount, uint256 abyssRequired) external returns (bool);

    /**
     * @dev Removes deposited and divfactor data for specific token. Used by Safe smart contract only.
     */
    function resetData(address token) external returns (bool);

    /**
     * @dev Updates deposited and divfactor data for specific token. Used by Safe smart contract only.
     */
    function updateData(address token, uint256 balance, uint256 divFactor_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
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