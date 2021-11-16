//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
import {LockedSavings} from "./LockedSavings.sol";
import {IERC20} from "./IERC20.sol";

contract LockSavingProxy {
    struct Deposit {
        uint256 dueDate;
        LockedSavings vault;
    }

    IERC20 USDC;
    address lendingPoolAddress;
    address USDAddress;
    address aUSDAddress;

    mapping(address => Deposit[]) userDeposits;

    constructor(
        address _lendingPoolAddress,
        address _USDAddress,
        address _aUSDAddress
    ) public {
        lendingPoolAddress = _lendingPoolAddress;
        USDAddress = _USDAddress;
        aUSDAddress = _aUSDAddress;
        USDC = IERC20(USDAddress);
    }

    function userDepositsCount(address addr) public view returns (uint256) {
        return userDeposits[addr].length;
    }

    function deposit(uint256 amount, uint256 dueDate) public {
        LockedSavings newVault = new LockedSavings(
            lendingPoolAddress,
            USDAddress,
            aUSDAddress
        );
        USDC.transferFrom(msg.sender, address(this), amount);
        USDC.approve(address(newVault), amount);
        newVault.deposit(amount);
        Deposit memory newDeposit = Deposit(dueDate, newVault);
        userDeposits[msg.sender].push(newDeposit);
    }

    function withdraw(uint256 depositIndex, uint256 amount) public {
        LockedSavings withdrawableVault = userDeposits[msg.sender][depositIndex]
            .vault;
        withdrawableVault.withdraw(msg.sender, amount);
    }
}