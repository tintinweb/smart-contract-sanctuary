// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
contract FlashSwapWithParaSwap is FlashLoanReceiverBase {
    using SafeMath for uint256;
    address augustusAddr = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address tokenTransferProxyAddr = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;
    address usdcAddr = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address daiAddr = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    // https://docs.aave.com/developers/deployed-contracts/matic-polygon-market
    // 0xd05e3E715d945B59290df0ae8eF85c1BdB684744
    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}

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
        uint usdcBalance;
        (bytes memory swapCalldata1, bytes memory swapCalldata2) = abi.decode(params, (bytes, bytes));

        IERC20(assets[0]).approve(tokenTransferProxyAddr, amounts[0]);
        (bool success,) = augustusAddr.call(swapCalldata1);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        usdcBalance = IERC20(usdcAddr).balanceOf(address(this));
        IERC20(usdcAddr).approve(tokenTransferProxyAddr, usdcBalance);
        (success,) = augustusAddr.call(swapCalldata2);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        usdcBalance = IERC20(usdcAddr).balanceOf(address(this));
        if (usdcBalance > 0) IERC20(usdcAddr).transfer(tx.origin, usdcBalance);

        return true;
    }

    function executeFlashSwap(uint256 _flashDaiAmount, uint256 _usdcAmount, bytes calldata swapCalldata1, bytes calldata swapCalldata2) public {
        if (_usdcAmount > 0){
            IERC20(usdcAddr).transferFrom(msg.sender, address(this), _usdcAmount);
        }

        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = daiAddr;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashDaiAmount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = abi.encode(swapCalldata1, swapCalldata2);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}