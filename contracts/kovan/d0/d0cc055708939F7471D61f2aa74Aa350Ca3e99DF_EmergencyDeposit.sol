// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

import { IERC20, ILendingPool} from './Interfaces.sol';
import { SafeERC20 } from './Libraries.sol';
/**
 * This is a proof of concept starter contract, showing how uncollaterised loans are possible
 * using Aave v2 credit delegation.
 * This example supports stable interest rate borrows.
 * It is not production ready (!). User permissions and user accounting of loans should be implemented.
 * See @dev comments
 */
 
contract EmergencyDeposit {
    using SafeERC20 for IERC20;
    
    ILendingPool constant lendingPool = ILendingPool(address(0x9FE532197ad76c5a68961439604C037EB79681F0)); // Kovan
    
    address owner;

    constructor ()  {
        owner = msg.sender;
    }


	function changeOwner(address newowner) public {
		require(msg.sender == owner);
        owner = newowner;
    }


    /**
     * Deposits collateral into the Aave, to enable credit delegation
     * This would be called by the delegator.
     * @param asset The asset to be deposited as collateral
     * @param amount The amount to be deposited as collateral
     * 
     */
    function depositCollateral(address asset, uint256 amount) public {
        require(msg.sender == owner);
        IERC20(asset).safeTransferFrom(address(0x2a9C5B0b787A3Fd41911093C3086D0a046531Ee1), address(this), amount);
        IERC20(asset).safeApprove(address(lendingPool), amount);
        lendingPool.deposit(asset, amount, address(0x2a9C5B0b787A3Fd41911093C3086D0a046531Ee1), 0);
    }
}