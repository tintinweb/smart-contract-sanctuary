//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

// TODO: Remove again
// import "@nomiclabs/buidler/console.sol";

import "./IBank.sol";
import "./IPriceOracle.sol";

// struct Account {
//     uint256 balance;
//     uint lastInterestUpdate;
// }

contract Bank is IBank {
    mapping(address => Account) accountBalancesEth;
    mapping(address => Account) accountBalancesHak;

    mapping(address => uint256) accountBorrowedEth;
    mapping(address => uint256) accountBorrowesHak;

    // modifier updatesInterest {
    //     if (token == hakToken) {
    //     let blocksPassed = msg.block - 
    //     _;
    // }

    function getAccount(address token) private view returns (Account storage) {
        Account storage account;
        if (token == hakToken) {
            account = accountBalancesHak[msg.sender];
        // TODO: is this compare secure?
        } else if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            account = accountBalancesEth[msg.sender];
        } else {
            revert("token not supported");
        }
        return account;
    }

    function calculateNewInterest(Account storage account) private view returns (uint256) {
        uint delta = block.number - account.lastInterestBlock;
        // console.log("delta", delta);
        return (account.deposit * delta * 3) / 10000;
    }

    function updateInterest(Account storage account) private {
        account.interest += calculateNewInterest(account);
        account.lastInterestBlock = block.number;
    }

    address payable hakToken;
    // TODO: Move eth address to a constant

    constructor(address _priceOracle, address payable _hakToken) {
        hakToken = _hakToken;
    }

    // TODO: Where does msg come from??
    // TODO: What is amount???
    // TODO: Comparison `==` secure??
    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            Account storage account = getAccount(token);
            updateInterest(account);
            if (token == hakToken) {
                account.deposit += amount;
                // TODO: Check that the sender has the amount?
                hakToken.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
            } else  {
                require(amount == msg.value, "amount != msg.value");
                // TODO: is this secure??? no transfer?
                // TODO: Do we have the ETH in our wallet automatically now?
                account.deposit += msg.value;
            }
            emit Deposit(msg.sender, token, amount);
            return true;
        }

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {
            Account storage account = getAccount(token);
            updateInterest(account);
            // console.log("withdraw", amount, "balance", getBalance(token));
            if (getBalance(token) == 0) {
                revert("no balance");
            }
            // revert(uintToString(getBalance(token)));
            if (amount > getBalance(token)) {
                revert("amount exceeds balance");
            }
            if (amount == 0) {
                amount = getBalance(token);
            }
            // Prioritize withdrawing from deposit
            uint256 amountFromDeposit = amount;
            if (amount > account.deposit) {
                uint256 amountFromInterest = amount - account.deposit;
                account.interest -= amountFromInterest;
                amountFromDeposit -= amountFromInterest;
            }
            account.deposit -= amountFromDeposit;
            if (token == hakToken) {
                // TODO: Check that the sender has the amount?
                hakToken.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
            } else  {
                // TODO: Payout ETH
            }
            emit Withdraw(msg.sender, token, amount);
        }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {
            // if (token == hakToken) {
            //     if (accountBalancesHak[msg.sender] * 100/amount > 150) {
            //         revert("no colletaral");
            //     }
            //     else {
            //         accountBorrowesHak[msg.sender] + amount;
            //         payable(token).transfer(amount);
            //     }
            // }
            // else {
            //     if (accountBalancesEth[msg.sender] * 100/amount > 150) {
            //         revert("no colletaral");
            //     }
            //     else {
            //         accountBorrowedEth[msg.sender] + amount;
            //         payable(token).transfer(amount);
            //     }
            // }
        }

    function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) {}

    function liquidate(address token, address account)
        payable
        external
        override
        returns (bool) {}

    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) {}

    function getBalance(address token)
        view
        public
        override
        returns (uint256) {
            Account storage account = getAccount(token);
            return account.deposit + account.interest + calculateNewInterest(account);
        }
}