// Copyright (C) 2020 Centrifuge
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "./auth.sol";
import "./math.sol";
import "./fixed_point.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function mint(address, uint) external;
    function burn(address, uint) external;
    function totalSupply() external view returns (uint);
    function approve(address usr, uint amount) external;
}

interface ReserveLike {
    function deposit(uint amount) external;
    function payout(uint amount) external;
    function totalBalanceAvailable() external returns (uint);
}

interface EpochTickerLike {
    function currentEpoch() external view returns (uint);
    function lastEpochExecuted() external view returns(uint);
}

contract Tranche is Math, Auth, FixedPoint {
    mapping(uint => Epoch) public epochs;

    struct Epoch {
        // denominated in 10^27
        // percentage ONE == 100%
        Fixed27 redeemFulfillment;
        // denominated in 10^27
        // percentage ONE == 100%
        Fixed27 supplyFulfillment;
        // tokenPrice after end of epoch
        Fixed27 tokenPrice;
    }

    struct UserOrder {
        uint orderedInEpoch;
        uint supplyCurrencyAmount;
        uint redeemTokenAmount;
    }

    mapping(address => UserOrder) public users;

    uint public  totalSupply;
    uint public  totalRedeem;

    ERC20Like public currency;
    ERC20Like public token;
    ReserveLike public reserve;
    EpochTickerLike public epochTicker;

    // additional requested currency if the reserve could not fulfill a tranche request
    uint public requestedCurrency;
    address self;

    bool public waitingForUpdate = false;

    modifier orderAllowed(address usr) {
        require((users[usr].supplyCurrencyAmount == 0 && users[usr].redeemTokenAmount == 0)
        || users[usr].orderedInEpoch == epochTicker.currentEpoch(), "disburse required");
        _;
    }

    constructor(address currency_, address token_) public {
        wards[msg.sender] = 1;
        token = ERC20Like(token_);
        currency = ERC20Like(currency_);
        self = address(this);
    }

    function balance() external view returns (uint) {
        return currency.balanceOf(self);
    }

    function tokenSupply() external view returns (uint) {
        return token.totalSupply();
    }

    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "token") {token = ERC20Like(addr);}
        else if (contractName == "currency") {currency = ERC20Like(addr);}
        else if (contractName == "reserve") {reserve = ReserveLike(addr);}
        else if (contractName == "epochTicker") {epochTicker = EpochTickerLike(addr);}
        else revert();
    }

    // supplyOrder function can be used to place or revoke an supply
    function supplyOrder(address usr, uint newSupplyAmount) public auth orderAllowed(usr) {
        users[usr].orderedInEpoch = epochTicker.currentEpoch();

        uint currentSupplyAmount = users[usr].supplyCurrencyAmount;

        users[usr].supplyCurrencyAmount = newSupplyAmount;

        totalSupply = safeAdd(safeTotalSub(totalSupply, currentSupplyAmount), newSupplyAmount);

        if (newSupplyAmount > currentSupplyAmount) {
            uint delta = safeSub(newSupplyAmount, currentSupplyAmount);
            require(currency.transferFrom(usr, self, delta), "currency-transfer-failed");
            return;
        }
        uint delta = safeSub(currentSupplyAmount, newSupplyAmount);
        if (delta > 0) {
            _safeTransfer(currency, usr, delta);
        }
    }

    // redeemOrder function can be used to place or revoke a redeem
    function redeemOrder(address usr, uint newRedeemAmount) public auth orderAllowed(usr) {
        users[usr].orderedInEpoch = epochTicker.currentEpoch();

        uint currentRedeemAmount = users[usr].redeemTokenAmount;
        users[usr].redeemTokenAmount = newRedeemAmount;
        totalRedeem = safeAdd(safeTotalSub(totalRedeem, currentRedeemAmount), newRedeemAmount);

        if (newRedeemAmount > currentRedeemAmount) {
            uint delta = safeSub(newRedeemAmount, currentRedeemAmount);
            require(token.transferFrom(usr, self, delta), "token-transfer-failed");
            return;
        }

        uint delta = safeSub(currentRedeemAmount, newRedeemAmount);
        if (delta > 0) {
            _safeTransfer(token, usr, delta);
        }
    }

    function calcDisburse(address usr) public view returns(uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency, uint remainingRedeemToken) {
        return calcDisburse(usr, epochTicker.lastEpochExecuted());
    }

    ///  calculates the current disburse of a user starting from the ordered epoch until endEpoch
    function calcDisburse(address usr, uint endEpoch) public view returns(uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency, uint remainingRedeemToken) {
        uint epochIdx = users[usr].orderedInEpoch;
        uint lastEpochExecuted = epochTicker.lastEpochExecuted();

        // no disburse possible in this epoch
        if (users[usr].orderedInEpoch == epochTicker.currentEpoch()) {
            return (payoutCurrencyAmount, payoutTokenAmount, users[usr].supplyCurrencyAmount, users[usr].redeemTokenAmount);
        }

        if (endEpoch > lastEpochExecuted) {
            // it is only possible to disburse epochs which are already over
            endEpoch = lastEpochExecuted;
        }

        remainingSupplyCurrency = users[usr].supplyCurrencyAmount;
        remainingRedeemToken = users[usr].redeemTokenAmount;
        uint amount = 0;

        // calculates disburse amounts as long as remaining tokens or currency is left or the end epoch is reached
        while(epochIdx <= endEpoch && (remainingSupplyCurrency != 0 || remainingRedeemToken != 0 )){
            if(remainingSupplyCurrency != 0) {
                amount = rmul(remainingSupplyCurrency, epochs[epochIdx].supplyFulfillment.value);
                // supply currency payout in token
                if (amount != 0) {
                    payoutTokenAmount = safeAdd(payoutTokenAmount, safeDiv(safeMul(amount, ONE), epochs[epochIdx].tokenPrice.value));
                    remainingSupplyCurrency = safeSub(remainingSupplyCurrency, amount);
                }
            }

            if(remainingRedeemToken != 0) {
                amount = rmul(remainingRedeemToken, epochs[epochIdx].redeemFulfillment.value);
                // redeem token payout in currency
                if (amount != 0) {
                    payoutCurrencyAmount = safeAdd(payoutCurrencyAmount, rmul(amount, epochs[epochIdx].tokenPrice.value));
                    remainingRedeemToken = safeSub(remainingRedeemToken, amount);
                }
            }
            epochIdx = safeAdd(epochIdx, 1);
        }

        return (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken);
    }

    // the disburse function can be used after an epoch is over to receive currency and tokens
    function disburse(address usr) public auth returns (uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency, uint remainingRedeemToken) {
        return disburse(usr, epochTicker.lastEpochExecuted());
    }

    function _safeTransfer(ERC20Like erc20, address usr, uint amount) internal returns(uint) {
        uint max = erc20.balanceOf(self);
        if(amount > max) {
            amount = max;
        }
        require(erc20.transferFrom(self, usr, amount), "token-transfer-failed");
        return amount;
    }

    // the disburse function can be used after an epoch is over to receive currency and tokens
    function disburse(address usr,  uint endEpoch) public auth returns (uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency, uint remainingRedeemToken) {
        require(users[usr].orderedInEpoch <= epochTicker.lastEpochExecuted(), "epoch-not-executed-yet");

        uint lastEpochExecuted = epochTicker.lastEpochExecuted();

        if (endEpoch > lastEpochExecuted) {
            // it is only possible to disburse epochs which are already over
            endEpoch = lastEpochExecuted;
        }

        (payoutCurrencyAmount, payoutTokenAmount,
        remainingSupplyCurrency, remainingRedeemToken) = calcDisburse(usr, endEpoch);
        users[usr].supplyCurrencyAmount = remainingSupplyCurrency;
        users[usr].redeemTokenAmount = remainingRedeemToken;
        // if lastEpochExecuted is disbursed, orderInEpoch is at the current epoch again
        // which allows to change the order. This is only possible if all previous epochs are disbursed
        users[usr].orderedInEpoch = safeAdd(endEpoch, 1);


        if (payoutCurrencyAmount > 0) {
            payoutCurrencyAmount = _safeTransfer(currency, usr, payoutCurrencyAmount);
        }

        if (payoutTokenAmount > 0) {
            payoutTokenAmount = _safeTransfer(token, usr, payoutTokenAmount);
        }
        return (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken);
    }


    // called by epoch coordinator in epoch execute method
    function epochUpdate(uint epochID, uint supplyFulfillment_, uint redeemFulfillment_, uint tokenPrice_, uint epochSupplyOrderCurrency, uint epochRedeemOrderCurrency) public auth {
        require(waitingForUpdate == true);
        waitingForUpdate = false;

        epochs[epochID].supplyFulfillment.value = supplyFulfillment_;
        epochs[epochID].redeemFulfillment.value = redeemFulfillment_;
        epochs[epochID].tokenPrice.value = tokenPrice_;

        // currency needs to be converted to tokenAmount with current token price
        uint redeemInToken = 0;
        uint supplyInToken = 0;
        if(tokenPrice_ > 0) {
            supplyInToken = rdiv(epochSupplyOrderCurrency, tokenPrice_);
            redeemInToken = safeDiv(safeMul(epochRedeemOrderCurrency, ONE), tokenPrice_);
        }

        // calculates the delta between supply and redeem for tokens and burn or mint them
        adjustTokenBalance(epochID, supplyInToken, redeemInToken);
        // calculates the delta between supply and redeem for currency and deposit or get them from the reserve
        adjustCurrencyBalance(epochID, epochSupplyOrderCurrency, epochRedeemOrderCurrency);

        // the unfulfilled orders (1-fulfillment) is automatically ordered
        totalSupply = safeAdd(safeTotalSub(totalSupply, epochSupplyOrderCurrency), rmul(epochSupplyOrderCurrency, safeSub(ONE, epochs[epochID].supplyFulfillment.value)));
        totalRedeem = safeAdd(safeTotalSub(totalRedeem, redeemInToken), rmul(redeemInToken, safeSub(ONE, epochs[epochID].redeemFulfillment.value)));
    }
    function closeEpoch() public auth returns (uint totalSupplyCurrency_, uint totalRedeemToken_) {
        require(waitingForUpdate == false);
        waitingForUpdate = true;
        return (totalSupply, totalRedeem);
    }

    function safeBurn(uint tokenAmount) internal {
        uint max = token.balanceOf(self);
        if(tokenAmount > max) {
            tokenAmount = max;
        }
        token.burn(self, tokenAmount);
    }

    function safePayout(uint currencyAmount) internal returns(uint payoutAmount) {
        uint max = reserve.totalBalanceAvailable();

        if(currencyAmount > max) {
            // currently reserve can't fulfill the entire request
            currencyAmount = max;
        }
        reserve.payout(currencyAmount);
        return currencyAmount;
    }

    function payoutRequestedCurrency() public {
        if(requestedCurrency > 0) {
            uint payoutAmount = safePayout(requestedCurrency);
            requestedCurrency = safeSub(requestedCurrency, payoutAmount);
        }
    }
    // adjust token balance after epoch execution -> min/burn tokens
    function adjustTokenBalance(uint epochID, uint epochSupplyToken, uint epochRedeemToken) internal {
        // mint token amount for supply

        uint mintAmount = 0;
        if (epochs[epochID].tokenPrice.value > 0) {
            mintAmount = rmul(epochSupplyToken, epochs[epochID].supplyFulfillment.value);
        }

        // burn token amount for redeem
        uint burnAmount = rmul(epochRedeemToken, epochs[epochID].redeemFulfillment.value);
        // burn tokens that are not needed for disbursement
        if (burnAmount > mintAmount) {
            uint diff = safeSub(burnAmount, mintAmount);
            safeBurn(diff);
            return;
        }
        // mint tokens that are required for disbursement
        uint diff = safeSub(mintAmount, burnAmount);
        if (diff > 0) {
            token.mint(self, diff);
        }
    }

    // additional minting of tokens produces a dilution of all token holders
    // interface is required for adapters
    function mint(address usr, uint amount) public auth {
        token.mint(usr, amount);
    }

    // adjust currency balance after epoch execution -> receive/send currency from/to reserve
    function adjustCurrencyBalance(uint epochID, uint epochSupply, uint epochRedeem) internal {
        // currency that was supplied in this epoch
        uint currencySupplied = rmul(epochSupply, epochs[epochID].supplyFulfillment.value);
        // currency required for redemption
        uint currencyRequired = rmul(epochRedeem, epochs[epochID].redeemFulfillment.value);

        if (currencySupplied > currencyRequired) {
            // send surplus currency to reserve
            uint diff = safeSub(currencySupplied, currencyRequired);
            currency.approve(address(reserve), diff);
            reserve.deposit(diff);
            return;
        }
        uint diff = safeSub(currencyRequired, currencySupplied);
        if (diff > 0) {
            // get missing currency from reserve
            uint payoutAmount = safePayout(diff);
            if(payoutAmount < diff) {
                // reserve couldn't fulfill the entire request
                requestedCurrency = safeAdd(requestedCurrency, safeSub(diff, payoutAmount));
            }
        }
    }

    // recovery transfer can be used by governance to recover funds if tokens are stuck
    function authTransfer(address erc20, address usr, uint amount) public auth {
        ERC20Like(erc20).transferFrom(self, usr, amount);
    }

    // due to rounding in token & currency conversions currency & token balances might be off by 1 wei with the totalSupply/totalRedeem amounts.
    // in order to prevent an underflow error, 0 is returned when amount to be subtracted is bigger then the total value.
    function safeTotalSub(uint total, uint amount) internal returns (uint) {
        if (total < amount) {
            return 0;
        }
        return safeSub(total, amount);
    }
}