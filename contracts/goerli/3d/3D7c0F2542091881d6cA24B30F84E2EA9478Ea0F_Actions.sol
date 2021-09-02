/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/actions.sol

pragma solidity >=0.5.15 <0.6.0;

////// src/actions.sol
// actions.sol -- Tinlake actions
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

/* pragma solidity >=0.5.15 <0.6.0; */

interface NFTLike_3 {
    function approve(address usr, uint token) external;
    function transferFrom(address src, address dst, uint token) external;
}

interface ERC20Like_6 {
    function approve(address usr, uint amount) external;
    function transfer(address dst, uint amount) external;
    function transferFrom(address src, address dst, uint amount) external;
}

interface ShelfLike_5 {
    function pile() external returns(address);
    function lock(uint loan) external;
    function unlock(uint loan) external;
    function issue(address registry, uint token) external returns(uint loan);
    function close(uint loan) external;
    function borrow(uint loan, uint amount) external;
    function withdraw(uint loan, uint amount, address usr) external;
    function repay(uint loan, uint amount) external;
    function shelf(uint loan) external returns(address registry,uint256 tokenId,uint price,uint principal, uint initial);
}

interface PileLike_5 {
    function debt(uint loan) external returns(uint);
}

contract Actions {

    // --- Events ---
    event Issue(address indexed shelf, address indexed registry, uint indexed token);
    event Transfer(address indexed registry, uint indexed token);
    event Lock(address indexed shelf, uint indexed loan);
    event BorrowWithdraw(address indexed shelf, uint indexed loan, uint amount, address indexed usr);
    event Repay(address indexed shelf, address indexed erc20, uint indexed loan, uint amount);
    event Unlock(address indexed shelf, address indexed registry, uint token, uint indexed loan);
    event Close(address indexed shelf, uint indexed loan);
    event ApproveNFT(address indexed registry, address indexed usr, uint tokenAmount);
    event ApproveERC20(address indexed erc20, address indexed usr, uint amount);
    event TransferERC20(address indexed erc20, address indexed dst, uint amount);

    // --- Borrower Actions ---
    function issue(address shelf, address registry, uint token) public returns (uint loan) {
        loan = ShelfLike_5(shelf).issue(registry, token);
        // proxy approve shelf to take nft
        NFTLike_3(registry).approve(shelf, token);
        
        emit Issue(shelf, registry, token);
        return loan;
    }

    function transfer(address registry, uint token) public {
        // transfer nft from borrower to proxy
        NFTLike_3(registry).transferFrom(msg.sender, address(this), token);
        emit Transfer(registry, token);
    }

    function lock(address shelf, uint loan) public {
        ShelfLike_5(shelf).lock(loan);
        emit Lock(shelf, loan);
    }

    function borrowWithdraw(address shelf, uint loan, uint amount, address usr) public {
        ShelfLike_5(shelf).borrow(loan, amount);
        ShelfLike_5(shelf).withdraw(loan, amount, usr);
        emit BorrowWithdraw(shelf, loan, amount, usr);
    }

    function repay(address shelf, address erc20, uint loan, uint amount) public {
        // don't allow repaying more than the debt as currency would get stuck in the proxy
        uint debt = PileLike_5(ShelfLike_5(shelf).pile()).debt(loan);
        if (amount > debt) {
            amount = debt;
        }

        _repay(shelf, erc20, loan, amount);
    }

    function repayFullDebt(address shelf, address pile, address erc20, uint loan) public {
        _repay(shelf, erc20, loan, PileLike_5(pile).debt(loan));
    }

    function _repay(address shelf, address erc20, uint loan, uint amount) internal {
        // transfer money from borrower to proxy
        ERC20Like_6(erc20).transferFrom(msg.sender, address(this), amount);
        ERC20Like_6(erc20).approve(address(shelf), amount);
        ShelfLike_5(shelf).repay(loan, amount);
        emit Repay(shelf, erc20, loan, amount);
    }

    function unlock(address shelf, address registry, uint token, uint loan) public {
        ShelfLike_5(shelf).unlock(loan);
        NFTLike_3(registry).transferFrom(address(this), msg.sender, token);
        emit Unlock(shelf, registry, token, loan);
    }

    function close(address shelf, uint loan) public {
        ShelfLike_5(shelf).close(loan);
        emit Close(shelf, loan);
    }

    // --- Borrower Wrappers ---
    function transferIssue(address shelf, address registry, uint token) public returns (uint loan) {
        transfer(registry, token);
        return issue(shelf, registry, token);
    }

    function lockBorrowWithdraw(address shelf, uint loan, uint amount, address usr) public {
        lock(shelf, loan);
        borrowWithdraw(shelf, loan, amount, usr);
    }

    function transferIssueLockBorrowWithdraw(address shelf, address registry, uint token, uint amount, address usr) public {
        uint loan = transferIssue(shelf, registry, token);
        lockBorrowWithdraw(shelf, loan, amount, usr);
    }

    function repayUnlockClose(address shelf, address pile, address registry, uint token, address erc20, uint loan) public {
        repayFullDebt(shelf, pile, erc20, loan);
        unlock(shelf, registry, token, loan);
        close(shelf, loan);
    }

    // --- Misc Functions ---
    function approveNFT(address registry, address usr, uint tokenAmount) public {
        NFTLike_3(registry).approve(usr, tokenAmount);
        emit ApproveNFT(registry, usr, tokenAmount);
    }

    function approveERC20(address erc20, address usr, uint amount) public {
        ERC20Like_6(erc20).approve(usr, amount);
        emit ApproveERC20(erc20, usr, amount);
    }

    function transferERC20(address erc20, address dst, uint amount) public {
        ERC20Like_6(erc20).transfer(dst, amount);
        emit TransferERC20(erc20, dst, amount);
    }

}