// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";

contract STE is ERC20 {
    uint public totalDeposits;
    uint public totalWithdrawals;

    event Deposit(address indexed sender, uint wad);
    event Withdrawal(address indexed recipient, uint wad);

    constructor() ERC20("Stored Ethereum", "STE") {}

    receive() external payable {
        uint tokens;
        if (totalSupply() == 0) {
            tokens = msg.value;
        }
        else {
            uint netDeposit = (msg.value*95)/100;
            uint priorBalance = address(this).balance - netDeposit;
            tokens = (totalSupply()*netDeposit)/priorBalance;
        }

        _mint(_msgSender(), tokens);

        totalDeposits += msg.value;
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw(uint tokens) external {
        uint grossWithdrawal = (address(this).balance*tokens)/totalSupply();
        uint netWithdrawal;
        if (tokens == totalSupply()) {
            netWithdrawal = grossWithdrawal;
        }
        else {
            netWithdrawal = (grossWithdrawal*95)/100;
        }

        _burn(_msgSender(), tokens);

        (bool success, ) = _msgSender().call{value: netWithdrawal}("");
        require(success, "ETH transfer failed");

        totalWithdrawals += netWithdrawal;
        emit Withdrawal(_msgSender(), netWithdrawal);
    }

    function withdrawable(address addr) external view returns(uint) {
        if (totalSupply() == 0) {
            return 0;
        }

        uint tokens = balanceOf(addr);
        uint grossBalance = (address(this).balance*tokens)/totalSupply();
        if (tokens == totalSupply()) {
            return grossBalance;
        }
        else {
            return (grossBalance*95)/100;
        }
    }
}