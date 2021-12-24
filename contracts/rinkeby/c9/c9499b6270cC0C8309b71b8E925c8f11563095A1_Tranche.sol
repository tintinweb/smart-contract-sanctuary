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

pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

import "../../lib/galaxy-auth/src/auth.sol";
import "../../lib/galaxy-math/src/math.sol";
import "./../fixed_point.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function mint(address, uint256) external;

    function burn(address, uint256) external;

    function totalSupply() external view returns (uint256);

    function approve(address usr, uint256 amount) external;
}

interface ReserveLike {
    function deposit(uint256 amount) external;

    function payout(uint256 amount) external;

    function totalBalance() external returns (uint256);
}

interface EpochTickerLike {
    function currentEpoch() external view returns (uint256);

    function lastEpochExecuted() external view returns (uint256);
}

contract Tranche is Math, Auth, FixedPoint {
    mapping(uint256 => Epoch) public epochs;

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
        uint256 orderedInEpoch;
        uint256 supplyCurrencyAmount;
        uint256 redeemTokenAmount;
    }

    mapping(address => UserOrder) public users;

    uint256 public totalSupply;
    uint256 public totalRedeem;

    ERC20Like public currency;
    ERC20Like public token;
    ReserveLike public reserve;
    EpochTickerLike public epochTicker;

    address self;

    bool public waitingForUpdate = false;

    modifier orderAllowed(address usr) {
        require((users[usr].supplyCurrencyAmount == 0 && users[usr].redeemTokenAmount == 0) || users[usr].orderedInEpoch == epochTicker.currentEpoch(), "disburse required");
        _;
    }

    constructor(address currency_, address token_) public {
        wards[msg.sender] = 1;
        token = ERC20Like(token_);
        currency = ERC20Like(currency_);
        self = address(this);
    }

    function balance() external view returns (uint256) {
        return currency.balanceOf(self);
    }

    function tokenSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    function getTokenPriceByEpoch(uint256 _epoch) external view returns (uint256) {
        return epochs[_epoch].tokenPrice.value;
    }

    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "token") {
            token = ERC20Like(addr);
        } else if (contractName == "currency") {
            currency = ERC20Like(addr);
        } else if (contractName == "reserve") {
            reserve = ReserveLike(addr);
        } else if (contractName == "epochTicker") {
            epochTicker = EpochTickerLike(addr);
        } else revert();
    }

    // supplyOrder function can be used to place or revoke an supply
    function supplyOrder(address usr, uint256 newSupplyAmount) external auth orderAllowed(usr) {
        users[usr].orderedInEpoch = epochTicker.currentEpoch();

        uint256 currentSupplyAmount = users[usr].supplyCurrencyAmount;

        users[usr].supplyCurrencyAmount = newSupplyAmount;

        totalSupply = safeAdd(safeTotalSub(totalSupply, currentSupplyAmount), newSupplyAmount);

        if (newSupplyAmount > currentSupplyAmount) {
            uint256 delta = safeSub(newSupplyAmount, currentSupplyAmount);
            require(currency.transferFrom(usr, self, delta), "currency-transfer-failed");
            return;
        }
        uint256 delta = safeSub(currentSupplyAmount, newSupplyAmount);
        if (delta > 0) {
            _safeTransfer(currency, usr, delta);
        }
    }

    // redeemOrder function can be used to place or revoke a redeem
    function redeemOrder(address usr, uint256 newRedeemAmount) external auth orderAllowed(usr) {
        users[usr].orderedInEpoch = epochTicker.currentEpoch();

        uint256 currentRedeemAmount = users[usr].redeemTokenAmount;
        users[usr].redeemTokenAmount = newRedeemAmount;
        totalRedeem = safeAdd(safeTotalSub(totalRedeem, currentRedeemAmount), newRedeemAmount);

        if (newRedeemAmount > currentRedeemAmount) {
            uint256 delta = safeSub(newRedeemAmount, currentRedeemAmount);
            require(token.transferFrom(usr, self, delta), "token-transfer-failed");
            return;
        }

        uint256 delta = safeSub(currentRedeemAmount, newRedeemAmount);
        if (delta > 0) {
            _safeTransfer(token, usr, delta);
        }
    }

    function calcDisburse(address usr)
        public
        view
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        return calcDisburse(usr, epochTicker.lastEpochExecuted());
    }

    ///  calculates the current disburse of a user starting from the ordered epoch until endEpoch
    function calcDisburse(address usr, uint256 endEpoch)
        public
        view
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        uint256 epochIdx = users[usr].orderedInEpoch;
        uint256 lastEpochExecuted = epochTicker.lastEpochExecuted();

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
        uint256 amount = 0;

        // calculates disburse amounts as long as remaining tokens or currency is left or the end epoch is reached
        while (epochIdx <= endEpoch && (remainingSupplyCurrency != 0 || remainingRedeemToken != 0)) {
            if (remainingSupplyCurrency != 0) {
                amount = rmul(remainingSupplyCurrency, epochs[epochIdx].supplyFulfillment.value);
                // supply currency payout in token
                if (amount != 0) {
                    payoutTokenAmount = safeAdd(payoutTokenAmount, safeDiv(safeMul(amount, ONE), epochs[epochIdx].tokenPrice.value));
                    remainingSupplyCurrency = safeSub(remainingSupplyCurrency, amount);
                }
            }

            if (remainingRedeemToken != 0) {
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
    function disburse(address usr)
        external
        auth
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        return disburse(usr, epochTicker.lastEpochExecuted());
    }

    function _safeTransfer(
        ERC20Like erc20,
        address usr,
        uint256 amount
    ) internal {
        uint256 max = erc20.balanceOf(self);
        if (amount > max) {
            amount = max;
        }
        require(erc20.transfer(usr, amount), "token-transfer-failed");
    }

    // the disburse function can be used after an epoch is over to receive currency and tokens
    function disburse(address usr, uint256 endEpoch)
        public
        auth
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        require(users[usr].orderedInEpoch <= epochTicker.lastEpochExecuted(), "epoch-not-executed-yet");

        uint256 lastEpochExecuted = epochTicker.lastEpochExecuted();

        if (endEpoch > lastEpochExecuted) {
            // it is only possible to disburse epochs which are already over
            endEpoch = lastEpochExecuted;
        }

        (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken) = calcDisburse(usr, endEpoch);
        users[usr].supplyCurrencyAmount = remainingSupplyCurrency;
        users[usr].redeemTokenAmount = remainingRedeemToken;
        // if lastEpochExecuted is disbursed, orderInEpoch is at the current epoch again
        // which allows to change the order. This is only possible if all previous epochs are disbursed
        users[usr].orderedInEpoch = safeAdd(endEpoch, 1);

        if (payoutCurrencyAmount > 0) {
            _safeTransfer(currency, usr, payoutCurrencyAmount);
        }

        if (payoutTokenAmount > 0) {
            _safeTransfer(token, usr, payoutTokenAmount);
        }
        return (payoutCurrencyAmount, payoutTokenAmount, remainingSupplyCurrency, remainingRedeemToken);
    }

    // called by epoch coordinator in epoch execute method
    function epochUpdate(
        uint256 epochID,
        uint256 supplyFulfillment_,
        uint256 redeemFulfillment_,
        uint256 tokenPrice_,
        uint256 epochSupplyOrderCurrency,
        uint256 epochRedeemOrderCurrency
    ) external auth {
        require(waitingForUpdate);
        waitingForUpdate = false;

        epochs[epochID].supplyFulfillment.value = supplyFulfillment_;
        epochs[epochID].redeemFulfillment.value = redeemFulfillment_;
        epochs[epochID].tokenPrice.value = tokenPrice_;

        // currency needs to be converted to tokenAmount with current token price
        uint256 redeemInToken = 0;
        uint256 supplyInToken = 0;
        if (tokenPrice_ > 0) {
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

    function closeEpoch() external auth returns (uint256 totalSupplyCurrency_, uint256 totalRedeemToken_) {
        require(!waitingForUpdate);
        waitingForUpdate = true;
        return (totalSupply, totalRedeem);
    }

    function safeBurn(uint256 tokenAmount) internal {
        uint256 max = token.balanceOf(self);
        if (tokenAmount > max) {
            tokenAmount = max;
        }
        token.burn(self, tokenAmount);
    }

    function safePayout(uint256 currencyAmount) internal {
        uint256 max = reserve.totalBalance();
        if (currencyAmount > max) {
            currencyAmount = max;
        }
        reserve.payout(currencyAmount);
    }

    // adjust token balance after epoch execution -> min/burn tokens
    function adjustTokenBalance(
        uint256 epochID,
        uint256 epochSupplyToken,
        uint256 epochRedeemToken
    ) internal {
        // mint token amount for supply

        uint256 mintAmount = 0;
        if (epochs[epochID].tokenPrice.value > 0) {
            mintAmount = rmul(epochSupplyToken, epochs[epochID].supplyFulfillment.value);
        }

        // burn token amount for redeem
        uint256 burnAmount = rmul(epochRedeemToken, epochs[epochID].redeemFulfillment.value);
        // burn tokens that are not needed for disbursement
        if (burnAmount > mintAmount) {
            uint256 diff = safeSub(burnAmount, mintAmount);
            safeBurn(diff);
            return;
        }
        // mint tokens that are required for disbursement
        uint256 diff = safeSub(mintAmount, burnAmount);
        if (diff > 0) {
            token.mint(self, diff);
        }
    }

    // additional minting of tokens produces a dilution of all token holders
    // interface is required for adapters
    function mint(address usr, uint256 amount) public auth {
        token.mint(usr, amount);
    }

    // adjust currency balance after epoch execution -> receive/send currency from/to reserve
    function adjustCurrencyBalance(
        uint256 epochID,
        uint256 epochSupply,
        uint256 epochRedeem
    ) internal {
        // currency that was supplied in this epoch
        uint256 currencySupplied = rmul(epochSupply, epochs[epochID].supplyFulfillment.value);
        // currency required for redemption
        uint256 currencyRequired = rmul(epochRedeem, epochs[epochID].redeemFulfillment.value);

        if (currencySupplied > currencyRequired) {
            // send surplus currency to reserve
            uint256 diff = safeSub(currencySupplied, currencyRequired);
            currency.approve(address(reserve), diff);
            reserve.deposit(diff);
            return;
        }
        uint256 diff = safeSub(currencyRequired, currencySupplied);
        if (diff > 0) {
            // get missing currency from reserve
            safePayout(diff);
        }
    }

    // recovery transfer can be used by governance to recover funds if tokens are stuck
    function authTransfer(
        address erc20,
        address usr,
        uint256 amount
    ) external auth {
        ERC20Like(erc20).transfer(usr, amount);
    }

    // due to rounding in token & currency conversions currency & token balances might be off by 1 wei with the totalSupply/totalRedeem amounts.
    // in order to prevent an underflow error, 0 is returned when amount to be subtracted is bigger then the total value.
    function safeTotalSub(uint256 total, uint256 amount) internal returns (uint256) {
        if (total < amount) {
            return 0;
        }
        return safeSub(total, amount);
    }
}

// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
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

pragma solidity 0.5.15;

import "../../ds-note/src/note.sol";

contract Auth is DSNote {
    mapping(address => uint256) public wards;

    function rely(address usr) public auth note {
        wards[usr] = 1;
    }

    function deny(address usr) public auth note {
        wards[usr] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1);
        _;
    }
}

// Copyright (C) 2018 Rain <[email protected]>
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

pragma solidity 0.5.15;

contract Math {
    uint256 constant ONE = 10**27;

    function safeAdd(uint256 x, uint256 y) public pure returns (uint256 z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint256 x, uint256 y) public pure returns (uint256 z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint256 x, uint256 y) public pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = x / y;
    }

    function rmul(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint256 x, uint256 y) public pure returns (uint256 z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }
}

// Copyright (C) 2020 Centrifuge
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

pragma solidity 0.5.15;

contract FixedPoint {
    struct Fixed27 {
        uint256 value;
    }
}

/// note.sol -- the `note' modifier, for logging calls as events

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
pragma solidity 0.5.15;

contract DSNote {
    event LogNote(bytes4 indexed sig, address indexed guy, bytes32 indexed foo, bytes32 indexed bar, uint256 wad, bytes fax) anonymous;

    modifier note() {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}