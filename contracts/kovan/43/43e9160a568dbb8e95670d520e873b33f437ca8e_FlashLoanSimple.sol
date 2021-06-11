// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

// import 'https://github.com/aave/protocol-v2/blob/master/contracts/flashloan/base/FlashLoanReceiverBase.sol';
import './FlashLoanReceiverBase.sol';

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
contract FlashLoanSimple is FlashLoanReceiverBase {

    // bool public paused = true;
    // address public owner;

    constructor(ILendingPoolAddressesProvider _provider) FlashLoanReceiverBase(_provider) public {
        // owner = msg.sender;
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

        // while (paused) {
            
        // }

        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //
        
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.
        
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(_lendingPool), amountOwing);
        }
        
        return true;
    }
    
    function aaveFlashLoan() public {
        myFlashLoanCall(address(0xB597cd8D3217ea6477232F9217fa70837ff667Af), 1 ether);
    }
    
    function myFlashLoanCall(address addressOneAsset, uint ammount) public {
        address receiverAddress = address(this);

        address[] memory assets = new address[](2);
        assets[0] = address(addressOneAsset);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = ammount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;

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
    
    // function setPause(bool _paused) public {
    //     require(msg.sender == owner, "You are not the owner");
    //     paused = _paused;
    // }
}