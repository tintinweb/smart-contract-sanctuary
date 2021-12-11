// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "Interfaces.sol";
import { SafeMath } from "Libraries.sol";
import "./Ownable.sol";

/*
* A contract that executes the following logic in a single atomic transaction:
*
*   1. Gets a batch flash loan of AAVE, DAI and LINK
*   2. Deposits all of this flash liquidity onto the Aave V2 lending pool
*   3. Borrows 100 LINK based on the deposited collateral
*   4. Repays 100 LINK and unlocks the deposited collateral
*   5. Withdrawls all of the deposited collateral (AAVE/DAI/LINK)
*   6. Repays batch flash loan including the 9bps fee
*
*/
contract BatchFlashDemo is FlashLoanReceiverBase, Ownable {
    
    ILendingPoolAddressesProvider provider;
    using SafeMath for uint256;
    uint256 flashAaveAmt0;
    uint256 flashDaiAmt1;
    uint256 flashLinkAmt2;
    address lendingPoolAddr;
    
    // kovan reserve asset addresses
    address kovanAave = 0xB597cd8D3217ea6477232F9217fa70837ff667Af;
    address kovanDai = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
    address kovanLink = 0xAD5ce863aE3E4E9394Ab43d4ba0D80f419F61789;
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
        provider = _addressProvider;
        lendingPoolAddr = provider.getLendingPool();
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        
        // initialise lending pool instance
        //ILendingPool lendingPool = ILendingPool(lendingPoolAddr);
        
        // deposits the flashed AAVE, DAI and Link liquidity onto the lending pool
        //flashDeposit(lendingPool);

        //uint256 borrowAmt = 100 * 1e18; // to borrow 100 units of x asset
        
        // borrows 'borrowAmt' amount of LINK using the deposited collateral
        //flashBorrow(lendingPool, kovanLink, borrowAmt);
        
        // repays the 'borrowAmt' mount of LINK to unlock the collateral
        //flashRepay(lendingPool, kovanLink, borrowAmt);
 
        // withdraws the AAVE, DAI and LINK collateral from the lending pool
        //flashWithdraw(lendingPool);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        // i.e. AAVE V2's way of repaying the flash loan
        //for (uint i = 0; i < assets.length; i++) {
        //    uint amountOwing = amounts[i].add(premiums[i]);
        //    IERC20(assets[i]).approve(address(_lendingPool), amountOwing);
        //}

        return true;
    }

    /*
    * Deposits the flashed AAVE, DAI and LINK liquidity onto the lending pool as collateral
    */
    function flashDeposit(ILendingPool _lendingPool) public {
        
        // approve lending pool
        IERC20(kovanDai).approve(lendingPoolAddr, flashDaiAmt1);
        IERC20(kovanAave).approve(lendingPoolAddr, flashAaveAmt0);
        IERC20(kovanLink).approve(lendingPoolAddr, flashLinkAmt2);
        
        // deposit the flashed AAVE, DAI and LINK as collateral
        _lendingPool.deposit(kovanDai, flashDaiAmt1, address(this), uint16(0));
        _lendingPool.deposit(kovanAave, flashAaveAmt0, address(this), uint16(0));
        _lendingPool.deposit(kovanLink, flashLinkAmt2, address(this), uint16(0));
        
    }

    /*
    * Withdraws the AAVE, DAI and LINK collateral from the lending pool
    */
    function flashWithdraw(ILendingPool _lendingPool) public {
        
        _lendingPool.withdraw(kovanAave, flashAaveAmt0, address(this));
        _lendingPool.withdraw(kovanDai, flashDaiAmt1, address(this));
        _lendingPool.withdraw(kovanLink, flashLinkAmt2, address(this));
        
    }
    
    /*
    * Borrows _borrowAmt amount of _borrowAsset based on the existing deposited collateral
    */
    function flashBorrow(ILendingPool _lendingPool, address _borrowAsset, uint256 _borrowAmt) public {
        
        // borrowing x asset at stable rate, no referral, for yourself
        _lendingPool.borrow(
            _borrowAsset, 
            _borrowAmt, 
            1, 
            uint16(0), 
            address(this)
        );
        
    }

    /*
    * Repays _repayAmt amount of _repayAsset
    */
    function flashRepay(ILendingPool _lendingPool, address _repayAsset, uint256 _repayAmt) public {
        
        // approve the repayment from this contract
        IERC20(_repayAsset).approve(lendingPoolAddr, _repayAmt);
        
        _lendingPool.repay(
            _repayAsset, 
            _repayAmt, 
            1, 
            address(this)
        );
    }

    /*
    * Repays _repayAmt amount of _repayAsset
    */
    function flashSwapBorrowRate(ILendingPool _lendingPool, address _asset, uint256 _rateMode) public {
        
        _lendingPool.swapBorrowRateMode(_asset, _rateMode);
        
    }
    
    /*
    * This function is manually called to commence the flash loans sequence
    */
    function executeFlashLoans(uint256 _flashAaveAmt0, uint256 _flashDaiAmt1, uint256 _flashLinkAmt2) public onlyOwner {
        address receiverAddress = address(this);

        // the various assets to be flashed
        address[] memory assets = new address[](3);
        assets[0] = kovanAave; 
        assets[1] = kovanDai;
        assets[2] = kovanLink;
        
        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = _flashAaveAmt0;
        amounts[1] = _flashDaiAmt1;
        amounts[2] = _flashLinkAmt2;
        
        flashAaveAmt0 = _flashAaveAmt0;
        flashDaiAmt1 = _flashDaiAmt1;
        flashLinkAmt2 = _flashLinkAmt2;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](3);
        modes[0] = 0;
        modes[1] = 0;
        modes[2] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        _lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
    
        
    /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull() public payable onlyOwner {
        
        // withdraw all ETH
        msg.sender.call{ value: address(this).balance }("");
        
        // withdraw all x ERC20 tokens
        IERC20(kovanAave).transfer(msg.sender, IERC20(kovanAave).balanceOf(address(this)));
        IERC20(kovanDai).transfer(msg.sender, IERC20(kovanDai).balanceOf(address(this)));
        IERC20(kovanLink).transfer(msg.sender, IERC20(kovanLink).balanceOf(address(this)));
    }
    
}