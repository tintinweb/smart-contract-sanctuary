/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IComptroller {
    function getAccountLiquidity(address account) view external returns (uint error, uint liquidity, uint shortfall);
    function closeFactorMantissa() view external returns (uint);
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint actualRepayAmount)
        external view returns (uint error , uint ctokenAmount);
}

interface CToken {
    function borrowBalanceStored(address account) external view returns (uint);
    function balanceOf(address account) view external returns (uint);
    function underlying() view external returns(address);
}

interface BAMMLike {
    function LUSD() view external returns(uint);
    function cBorrow() view external returns(address);
    function collaterals(uint i) view external returns(address);

}

contract LiquidationBotHelper {
    struct Account {
        address account;
        address bamm;
        address ctoken;
        uint repayAmount;
        bool underwater;
    }

    function getAccountInfo(address account, IComptroller comptroller, BAMMLike bamm) public view returns(Account memory a) {
        CToken cBorrow = CToken(bamm.cBorrow());

        for(uint i = 0; true ; i++) {
            try bamm.collaterals(i) returns(address ctoken) {
                CToken cETH = CToken(ctoken);

                a.account = account;
                a.bamm = address(bamm);

                uint debt = cBorrow.borrowBalanceStored(account);

                uint repayAmount = debt * comptroller.closeFactorMantissa() / 1e18;
                
                uint bammBalance = CToken(cBorrow.underlying()).balanceOf(address(bamm));
                if(repayAmount > bammBalance) repayAmount = bammBalance;

                if(repayAmount == 0) continue;
                
                uint cETHBalance = cETH.balanceOf(account);
                if(cETHBalance == 0) continue;

                (uint err, uint cETHAmount) = comptroller.liquidateCalculateSeizeTokens(address(cBorrow), address(cETH), repayAmount);
                if(cETHAmount == 0 || err != 0) continue;

                if(cETHBalance < cETHAmount) {
                    repayAmount = cETHBalance * repayAmount / cETHAmount;
                }

                a.repayAmount = repayAmount;
                a.ctoken = ctoken;
                break;
            }
            catch {
                break;
            }
        }
    }

    function getInfo(address[] memory accounts, address comptroller, address[] memory bamms) public view returns(Account[] memory unsafeAccounts) {
        if(accounts.length == 0) return unsafeAccounts;

        Account[] memory actions = new Account[](accounts.length);
        uint numUnsafe = 0;
        
        for(uint i = 0 ; i < accounts.length ; i++) {
            (uint err,, uint shortfall) = IComptroller(comptroller).getAccountLiquidity(accounts[i]);
            if(shortfall == 0 || err != 0) continue;

            Account memory a;
            a.underwater = true;
            for(uint j = 0 ; j < bamms.length ; j++) {
                a = getAccountInfo(accounts[i], IComptroller(comptroller), BAMMLike(bamms[j]));
                if(a.repayAmount > 0) {
                    actions[numUnsafe++] = a;
                    break;
                }
            }
        }

        unsafeAccounts = new Account[](numUnsafe);
        for(uint k = 0 ; k < numUnsafe ; k++) {
            unsafeAccounts[k] = actions[k];
        }
    }
}