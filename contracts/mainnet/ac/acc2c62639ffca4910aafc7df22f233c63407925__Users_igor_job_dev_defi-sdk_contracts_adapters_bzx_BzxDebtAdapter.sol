// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ProtocolAdapter } from "../ProtocolAdapter.sol";


interface TheProtocol {
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        LoanType loanType,
        bool isLender,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData);

    function getActiveLoansCount()
        external
        view
        returns (uint256);
}


enum LoanType {
    All,
    Margin,
    NonMargin
}


struct LoanReturnData {
    bytes32 loanId;
    uint96 endTimestamp;
    address loanToken;
    address collateralToken;
    uint256 principal;
    uint256 collateral;
    uint256 interestOwedPerDay;
    uint256 interestDepositRemaining;
    uint256 startRate;
    uint256 startMargin;
    uint256 maintenanceMargin;
    uint256 currentMargin;
    uint256 maxLoanTerm;
    uint256 maxLiquidatable;
    uint256 maxSeizable;
}
 

/**
 * @title Debt adapter for bZx protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Roman Iftodi <romeo8881@gmail.com>
 */
contract BzxDebtAdapter is ProtocolAdapter {

    address internal constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f;

    string public constant override adapterType = "Debt";

    string public constant override tokenType = "ERC20";

    /**
     * @return Amount of debt of the given account for the protocol.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        LoanReturnData[] memory loans;
        loans = TheProtocol(bZxContract).getUserLoans(
            account, 
            0, 
            TheProtocol(bZxContract).getActiveLoansCount(), 
            LoanType.All, 
            false, 
            false
        );

        uint256 principal = 0;
        uint256 loanLenght = loans.length;
        for(uint256 i = 0; i < loanLenght; i++) {
            if (loans[i].loanToken == token) {
                principal += loans[i].principal;
            }
        }
        return principal;
    }
}
