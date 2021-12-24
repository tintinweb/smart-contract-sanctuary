// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.10;

import "./HyperDeFiToken.sol";


contract HyperDeFi is HyperDeFiToken {
    function getMetadata() public view
        returns (
            string[3]   memory tokenNames,
            string[3]   memory tokenSymbols,
            uint8[3]    memory tokenDecimals,
            uint256[3]  memory tokenPrices,
            uint256[9]  memory supplies,
            address[10] memory accounts,

            uint256 holders,
            uint256 usernames
        )
    {
        tokenNames[0]     = _name;
        tokenSymbols[0]   = _symbol;
        tokenDecimals[0]  = _decimals;

        (tokenNames[1], tokenSymbols[1], tokenDecimals[1]) = BUFFER.metaWRAP();
        (tokenNames[2], tokenSymbols[2], tokenDecimals[2]) = BUFFER.metaUSD();

        tokenPrices[0] = BUFFER.priceWRAP2USD(); // WRAP      => USD
        tokenPrices[1] = _priceToken2WRAP();     // HyperDeFi => WRAP
        tokenPrices[2] = _priceToken2USD();      // HyperDeFi => USD

        // supplies
        supplies[0] = TOTAL_SUPPLY_CAP;                // cap
        supplies[1] = TOTAL_SUPPLY_CAP - _totalSupply; // gate

        supplies[2] = _totalSupply;                 // totalSupply
        supplies[3] = _totalFarm;                   // totalTax
        supplies[4] = balanceOf(address(DEX_PAIR)); // liquidity
        supplies[5] = balanceOf(address(BUFFER));   // buffer
        supplies[6] = balanceOf(FARM);              // farm
        supplies[7] = balanceOf(FOMO);              // fomo
        supplies[8] = balanceOf(BLACK_HOLE);        // dead

        // accounts
        accounts[0] = address(DEX);      // DEX
        accounts[1] = address(WRAP);     // WRAP
        accounts[2] = BUFFER.USD();      // USD
        accounts[3] = address(DEX_PAIR); // pair
        accounts[4] = address(BUFFER);   // BUFFER
        accounts[5] = address(IDO);      // IDO
        accounts[6] = FARM;              // farm
        accounts[7] = FOMO;              // fomo
        accounts[8] = owner();           // fund
        accounts[9] = BLACK_HOLE;        // burn

        //
        holders = _holders.length;
        usernames = _totalUsername;
    }

    function getGlobal() public view
        returns (
            address fomoNext,

            uint16[10]  memory uint16s,
            uint256[19] memory uint256s,

            uint8[6] memory takerTax,
            uint8[6] memory makerTax,
            uint8[6] memory whaleTax,
            uint8[6] memory robberTax,
            
            address[] memory flats,
            address[] memory slots
        )
    {
        fomoNext   = _fomoNextAccount;

        uint16s[0] = WHALE_NUMERATOR;
        uint16s[1] = WHALE_DENOMINATOR;
        uint16s[2] = ROBBER_PERCENTAGE;
        uint16s[3] = AUTO_SWAP_NUMERATOR_MIN; // autoSwapNumeratorMin
        uint16s[4] = AUTO_SWAP_NUMERATOR_MAX; // autoSwapNumeratorMax
        uint16s[5] = AUTO_SWAP_DENOMINATOR;   // autoSwapDenominator
        uint16s[6] = FOMO_PERCENTAGE;         // fomoPercentage

        uint16s[7] = BONUS[0]; // BONUS Lv.0
        uint16s[8] = BONUS[1]; // BONUS Lv.1
        uint16s[9] = BONUS[2]; // BONUS Lv.2

        uint256s[0] = TIMESTAMP_LAUNCH; // launch timestamp
        uint256s[1] = INIT_LIQUIDITY;   // init   liquidity
        uint256s[2] = DIST_AMOUNT;      // dist   amount

        uint256s[3] = AIRDROP_THRESHOLD;     // airdrop threshold
        uint256s[4] = _getWhaleThreshold();  // whale   threshold
        uint256s[5] = _getRobberThreshold(); // robber  threshold

        uint256s[6] = _getAutoSwapAmountMin();  // autoSwapAmountMin
        uint256s[7] = _getAutoSwapAmountMax();  // autoSwapAmountMax

        uint256s[8] = _getFomoAmount();     // fomo amount
        uint256s[9] = _fomoTimestamp;       // fomo timestamp
        uint256s[10] = FOMO_TIMESTAMP_STEP; // fomo timestampStep


        takerTax[0] = TAKER_TAX.farm;
        takerTax[1] = TAKER_TAX.airdrop;
        takerTax[2] = TAKER_TAX.fomo;
        takerTax[3] = TAKER_TAX.liquidity;
        takerTax[4] = TAKER_TAX.fund;
        takerTax[5] = TAKER_TAX.destroy;

        makerTax[0] = MAKER_TAX.farm;
        makerTax[1] = MAKER_TAX.airdrop;
        makerTax[2] = MAKER_TAX.fomo;
        makerTax[3] = MAKER_TAX.liquidity;
        makerTax[4] = MAKER_TAX.fund;
        makerTax[5] = MAKER_TAX.destroy;

        whaleTax[0] = WHALE_TAX.farm;
        whaleTax[1] = WHALE_TAX.airdrop;
        whaleTax[2] = WHALE_TAX.fomo;
        whaleTax[3] = WHALE_TAX.liquidity;
        whaleTax[4] = WHALE_TAX.fund;
        whaleTax[5] = WHALE_TAX.destroy;
        
        robberTax[0] = ROBBER_TAX.farm;
        robberTax[1] = ROBBER_TAX.airdrop;
        robberTax[2] = ROBBER_TAX.fomo;
        robberTax[3] = ROBBER_TAX.liquidity;
        robberTax[4] = ROBBER_TAX.fund;
        robberTax[5] = ROBBER_TAX.destroy;

        flats = _flats;
        slots = _slots;

        uint256s[11] = IDO_DEPOSIT_MAX;
        uint256s[12] = IDO_DEPOSIT_CAP;
        uint256s[13] = IDO_TIMESTAMP_FROM;
        uint256s[14] = IDO_TIMESTAMP_TO;
        uint256s[15] = INIT_LIQUIDITY;
        uint256s[16] = _timestampLiquidityCreated;
        uint256s[17] = balanceOf(address(IDO));
        uint256s[18] = IDO.getDepositTotal();
    }

    function getAccount(address account) public view
        returns (
            string memory username,
            bool[5] memory bools,
            uint256[10] memory uint256s
        )
    {
        username = _username[account];

        bools[0] = _isHolder[account];                        // isHolder
        bools[1] = balanceOf(account) > _getWhaleThreshold(); // isWhale
        bools[2] = _isFlat[account];                          // isFlat
        bools[3] = _isSlot[account];                          // isSlot

        uint256s[0] = balanceOf(account);      // balance
        uint256s[1] = harvestOf(account);      // harvest
        uint256s[2] = _totalHarvest[account];  // totalHarvest
        uint256s[3] = _totalFarmSnap[account]; // totalTaxSnap

        uint256s[4] = _couponUsed[account]; // coupon used
        uint256s[5] = _coupon[account];     // coupon
        uint256s[6] = _visitors[account];   // visitors
        uint256s[7] = account.balance;      // BNB balance
        
        // amountBNB, amountToken, redeemed
        (uint256s[8], uint256s[9], bools[4]) = IDO.getAccount(account);
    }

    function getCoupon(uint256 coupon) public view
        returns (
            bool valid,
            uint256 visitors
        )
    {
        address inviter = _inviter[coupon];
        
        valid = inviter != address(0);
        if (valid) {
            visitors = _visitors[inviter];
        }
    }

    function getAccountByUsername(string calldata value) public view
        returns (
            address account,
            bool[5] memory bools,
            uint256[10] memory uint256s
        )
    {
        account = _username2address[value];

        bools[0] = _isHolder[account];                        // isHolder
        bools[1] = balanceOf(account) > _getWhaleThreshold(); // isWhale
        bools[2] = _isFlat[account];                          // isFlat
        bools[3] = _isSlot[account];                          // isSlot

        uint256s[0] = balanceOf(account);     // balance
        uint256s[1] = harvestOf(account);     // harvest
        uint256s[2] = _totalHarvest[account]; // totalHarvest
        uint256s[3] = _totalFarmSnap[account]; // totalTaxSnap

        uint256s[4] = _couponUsed[account]; // coupon used
        uint256s[5] = _coupon[account];     // coupon
        uint256s[6] = _visitors[account];   // visitors
        uint256s[7] = account.balance;      // BNB balance
        
        // amountBNB, amountToken, redeemed
        (uint256s[8], uint256s[9], bools[4]) = IDO.getAccount(account);
    }

    function getHolders(uint256 offset) public view
        returns (
            uint256[250] memory ids,
            address[250] memory holders,
            string[250]  memory usernames,
            uint256[250] memory balances,
            bool[250]    memory isWhales
        )
    {
        uint8 counter;
        for (uint256 i = offset; i < _holders.length; i++) {
            counter++;
            if (counter > 250) break;
            ids[i] = i;
            holders[i] = _holders[i];
            usernames[i] = _username[_holders[i]];
            balances[i] = balanceOf(holders[i]);
            isWhales[i] = balanceOf(holders[i]) > _getWhaleThreshold();
        }
    }
}