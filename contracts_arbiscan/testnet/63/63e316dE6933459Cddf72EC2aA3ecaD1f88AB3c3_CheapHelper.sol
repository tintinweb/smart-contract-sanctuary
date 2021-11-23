/**
 *Submitted for verification at arbiscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface Comptroller {
    function getAccountLiquidity(address account) view external returns (uint error, uint liquidity, uint shortfall);
    function closeFactorMantissa() view external returns (uint);
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint actualRepayAmount)
        external view returns (uint error , uint ctokenAmount);
}

interface CToken {
    function borrowBalanceCurrent(address account) view external returns (uint);
    function balanceOf(address account) view external returns (uint);
    function underlying() view external returns(address);
}

interface BAMMLike {
    function LUSD() view external returns(uint);
    function cBorrow() view external returns(address);
    function cETH() view external returns(address);
}

interface ILiquidationBotHelper {
    function getInfoFlat(address[] memory accounts, address comptroller, address[] memory bamms)
        external view returns(address[] memory users, address[] memory bamm, uint[] memory repayAmount);
}

contract LiquidationBotHelper {
    struct Account {
        address account;
        address bamm;
        uint repayAmount;
    }

    function getAccountInfo(address account, Comptroller comptroller, BAMMLike bamm) public view returns(Account memory a) {
        CToken cBorrow = CToken(bamm.cBorrow());
        CToken cETH = CToken(bamm.cETH());

        a.account = account;
        a.bamm = address(bamm);        

        uint debt = cBorrow.borrowBalanceCurrent(account);

        uint repayAmount = debt * comptroller.closeFactorMantissa() / 1e18;
        uint bammBalance = CToken(cBorrow.underlying()).balanceOf(address(bamm));
        if(repayAmount > bammBalance) repayAmount = bammBalance;

        if(repayAmount == 0) return a;
        (uint err, uint cETHAmount) = comptroller.liquidateCalculateSeizeTokens(address(cBorrow), address(cETH), repayAmount);
        if(cETHAmount == 0 || err != 0) return a;

        uint cETHBalance = cETH.balanceOf(account);
        if(cETHBalance < cETHAmount) {
            repayAmount = cETHBalance * repayAmount / cETHAmount;
        }

        a.repayAmount = repayAmount;
    }

    function getInfo(address[] memory accounts, address comptroller, address[] memory bamms) external view returns(Account[] memory unsafeAccounts) {
        Account[] memory actions = new Account[](accounts.length);
        uint numUnsafe = 0;
        
        for(uint i = 0 ; i < accounts.length ; i++) {
            (uint err,, uint shortfall) = Comptroller(comptroller).getAccountLiquidity(accounts[i]);
            if(shortfall == 0 || err != 0) continue;

            Account memory a;
            for(uint j = 0 ; j < bamms.length ; j++) {
                a = getAccountInfo(accounts[i], Comptroller(comptroller), BAMMLike(bamms[j]));
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

contract CheapHelper {
    function getInfo(bytes memory code, address[] calldata accounts, address comptroller, address[] calldata bamms)
        external returns(address[] memory users, address[] memory bamm, uint[] memory repayAmount)
    {
        address proxy;
        bytes32 salt = bytes32(0);
        assembly {
            proxy := create2(0, add(code, 0x20), mload(code), salt)
        }

        return ILiquidationBotHelper(proxy).getInfoFlat(accounts, comptroller, bamms);        
    }
}