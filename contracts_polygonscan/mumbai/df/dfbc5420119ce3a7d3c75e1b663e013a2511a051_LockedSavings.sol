//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
import {ILendingPool} from "./ILendingPool.sol";
import {IERC20} from "./IERC20.sol";
import {Ownable} from "./Ownable.sol";
contract LockedSavings is Ownable {
    ILendingPool lendingPool;
    IERC20 aUSDC;
    IERC20 USDC;

    constructor(
        address lendingPoolAddress,
        address USDAddress,
        address aUSDAddress
    ) public {
        lendingPool = ILendingPool(lendingPoolAddress);
        aUSDC = IERC20(aUSDAddress);
        USDC = IERC20(USDAddress);
        USDC.approve(lendingPoolAddress, type(uint256).max);
    }

    function deposit(uint256 amount) public onlyOwner {
        USDC.transferFrom(msg.sender, address(this), amount);
        lendingPool.deposit(address(USDC), amount, address(this), 0);
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        lendingPool.withdraw(address(USDC), amount, to);
    }

    function getOwner() public view returns (address) {
        return owner();
    }

}