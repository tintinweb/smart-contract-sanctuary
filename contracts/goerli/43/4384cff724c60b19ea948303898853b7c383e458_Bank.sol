//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "./IBank.sol";
import "./IPriceOracle.sol";
import "./ERC20.sol";

contract Bank is IBank {
    address owner;

    mapping(address => bool) public whitelist;
   
    mapping(address => uint256) public borrows;

    mapping(address => mapping (address => Account) ) public accounts;

    IPriceOracle private oracle;
    address hakAddress;

    constructor(address _priceOracle, address _hakToken) {
        owner = msg.sender;

        hakAddress = _hakToken;

        whitelist[_hakToken] = true;
        whitelist[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = true; // TODO: put this address in a const
        oracle = IPriceOracle(_priceOracle);
    }
    
    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            // TODO: review if this is correct
            require(isTokenAccepted(token), "token not supported");
            
            user = msg.sender;
            require(amount > 0, "incorrect amount");
            // require(msg.value == amount);

            Account storage a = accounts[token][user];
            
            // Create a memory copy to make it cheaper to execute
            Account memory updatedAccount = Account(a.deposit, a.interest, a.lastInterestBlock);
            
            // Update the interest before updating the deposit
            uint256 blocksPassed = block.number - updatedAccount.lastInterestBlock; // TODO: add require statement guarding the assumption that at least 1 block has passed
            uint256 gainedInterest = updatedAccount.deposit * blocksPassed * 3 / 10000;
            updatedAccount.interest += gainedInterest;
            updatedAccount.lastInterestBlock = block.number;

            // Update the deposit
            updatedAccount.deposit += amount;

            // Put memory values back into storage
            a.deposit = updatedAccount.deposit;
            a.interest = updatedAccount.interest;
            a.lastInterestBlock = updatedAccount.lastInterestBlock;

            if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                 ERC20(token).transferFrom(user, address(this), amount);
            }
            
            emit Deposit(user, token, amount);
            return true;
        }

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {
            if (!isTokenAccepted(token)) {
                revert("token not supported");
            }
            user = msg.sender;
            // TODO: make sure if needed, also this is impossible here since func is not payable require(msg.value == amount);

            Account storage a = accounts[token][user];
            if (a.deposit == 0) {
                revert("no balance");
            }

            // todo also check if ((amount + a.deposit > a.deposit)) to prevent overflow
            if (amount > a.deposit) {
                revert("amount exceeds balance");
            }

            // Create a new in memory variable on which we will be working
            Account memory updatedAccount = Account(a.deposit, a.interest, a.lastInterestBlock);
            
            // Calculate the interest from the last interest block until now
            uint256 blocksPassed = block.number - updatedAccount.lastInterestBlock; // TODO: add require statement guarding the assumption that at least 1 block has passed
            uint256 gainedInterest = updatedAccount.deposit * blocksPassed * 3 / 10000;
            uint256 totalReturnedInterest = updatedAccount.interest + gainedInterest;
            uint256 withdrawedDeposit = 0;
            
            if(amount == 0) {
                // Withdraw all of the money in the account
                withdrawedDeposit = updatedAccount.deposit;
                a.deposit = 0;
            } else {
                // Withdraw only a subset of money from the account
                withdrawedDeposit = amount;
                a.deposit = updatedAccount.deposit - amount;
            }
            
            // After a successful withdrawal the interest is always resetted
            a.interest = 0;
            a.lastInterestBlock = block.number;

            payable(user).transfer(withdrawedDeposit + totalReturnedInterest);
            emit Withdraw(user, token, withdrawedDeposit + totalReturnedInterest);
            return amount;
        }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {
            if (token != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                revert("only eth can be borrowed");
            }
            user = msg.sender;
            Account storage a = accounts[hakAddress][user];

            if (a.deposit == 0) {
                revert("no collateral deposited");
            }

            uint256 price = oracle.getVirtualPrice(token);

            uint256 maxAmount = (a.deposit * price - borrows[msg.sender] * price) / 150;

            if (amount * price > maxAmount) {
                revert("borrow would exceed collateral ratio");
            }
            borrows[user] += amount;
            accounts[token][user].deposit += amount;
            payable(user).transfer(amount);
            emit Borrow(user, token, amount, (accounts[token][user].deposit - borrows[user])/(borrows[user]));
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
        returns (bool) {
            /**
            * The purpose of this function is to allow so called keepers to collect bad
            * debt, that is in case the collateral ratio goes below 150% for any loan. 
            * @param token - the address of the token used as collateral for the loan. 
            * @param account - the account that took out the loan that is now undercollateralized.
            * @return - true if the liquidation was successful, otherwise revert.
            */

            if (getCollateralRatio(token, account) < 150) {

                address liquidator = msg.sender;
                uint256 amountReceived = msg.value;
                uint256 debt = 50; // TODO: change

                Account storage a = accounts[token][account];


                uint256 collatTotal = a.deposit + a.interest;

                if (amountReceived <= debt) {
                    revert("too little liquidation money");
                }

                uint256 toReturn = amountReceived - debt;

                // remove the person being liquidated's collateral
                a.deposit = 0;
                a.interest = 0;
                a.lastInterestBlock = block.number;

                // remove debtor's debt
                borrows[account] = 0;

                // transfer collateral token to liquidator
                ERC20(token).transferFrom(address(this), user, collatTotal);
                // transfer bonus
                payable(user).transfer(toReturn);

                emit Liquidate(liquidator, account, token, collatTotal, toReturn);

                return true;
            }

            revert("unable to liquidate");
        }

    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) {
            return (getBalance(token) - borrows[msg.sender]) / borrows[msg.sender]; // TODO: Safemath!!!
        }

    function getBalance(address token)
        view
        public
        override
        returns (uint256) {
            address user = msg.sender;
            // Compute the interest collected until now also to return it in the balance
            Account storage a = accounts[token][user];
            // Create a memory copy to make it cheaper to execute
            Account memory updatedAccount = Account(a.deposit, a.interest, a.lastInterestBlock);
            
            uint256 blocksPassed = block.number - updatedAccount.lastInterestBlock; // TODO: add require statement guarding the assumption that at least 1 block has passed
            uint256 gainedInterestUntilNow = updatedAccount.deposit * blocksPassed * 3 / 10000;
            return updatedAccount.deposit + updatedAccount.interest + gainedInterestUntilNow;
        }
        address user;
    
    // HELPER FUNCTIONS
    
    // Restrict currencies to ETH & HAK
    function isTokenAccepted(address tokenAddress) private returns (bool){
        return whitelist[tokenAddress];
    }
}