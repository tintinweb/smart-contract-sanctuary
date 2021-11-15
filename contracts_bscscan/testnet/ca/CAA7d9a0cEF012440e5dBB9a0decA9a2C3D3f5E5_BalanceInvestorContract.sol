//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract BalanceInvestorContract {

     struct Payment {
        uint tokenAmount;
        uint weiAmount;
        uint timestamp;
    }

    struct Balance {
        address token;
        uint tokenBalance;
        uint weiBalance;
        uint numPayments;
        mapping(uint => Payment) payments;
    }


    mapping (address => bool) Claimed;
    mapping (address => Balance) public balanceInitial;
    mapping (address => Balance) public balanceUpdated;



    function registerBalances(address token,address beneficiary, uint256 weiAmount, uint256 tokenAmount) public {
        if(balanceUpdated[beneficiary].numPayments > 0) {
            updateBalances(token,beneficiary, weiAmount, tokenAmount);
        } else {
            // Balance Initial
            balanceInitial[beneficiary].token = token;
            balanceInitial[beneficiary].tokenBalance += tokenAmount;
            balanceInitial[beneficiary].weiBalance += weiAmount;

            Payment memory payment = Payment(tokenAmount,weiAmount, block.timestamp);
            balanceInitial[beneficiary].payments[balanceInitial[beneficiary].numPayments] = payment;
            balanceInitial[beneficiary].numPayments++;
                                    
            updateBalances(token,beneficiary, weiAmount, tokenAmount);
        }
    }

    function updateBalances(address token,address beneficiary, uint256 weiAmount, uint256 tokenAmount) public {
        //  Balance Updated
        balanceUpdated[beneficiary].token = token;
        balanceUpdated[beneficiary].tokenBalance += tokenAmount;
        balanceUpdated[beneficiary].weiBalance += weiAmount;

        Payment memory payment = Payment(tokenAmount,weiAmount, block.timestamp);
        balanceUpdated[beneficiary].payments[balanceUpdated[beneficiary].numPayments] = payment;
        balanceUpdated[beneficiary].numPayments++;
    }

    

}

