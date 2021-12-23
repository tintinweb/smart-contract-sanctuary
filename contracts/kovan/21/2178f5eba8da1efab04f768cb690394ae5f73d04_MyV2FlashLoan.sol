// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "Interfaces.sol";
import { SafeMath } from "Libraries.sol";

import "IUniswap.sol";

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
contract MyV2FlashLoan is FlashLoanReceiverBase {
    address public constant DAI_ADDRESS = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
    address public constant BAT_ADDRESS = 0x2d12186Fbb9f9a8C28B3FfdD4c42920f8539D738;
    address public constant UNISWAP_FACTORY_A = 0xECc6C0542710a0EF07966D7d1B10fA38bbb86523;
    address public constant UNISWAP_FACTORY_B = 0x54Ac34e5cE84C501165674782582ADce2FDdc8F4;

    IUniswapExchange public exchangeA;
    IUniswapExchange public exchangeB;
    IUniswapFactory public uniswapFactoryA;
    IUniswapFactory public uniswapFactoryB;

    uint i;

    using SafeMath for uint256;

    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
        // Instantiate Uniswap Factory A
        uniswapFactoryA = IUniswapFactory(UNISWAP_FACTORY_A);
        // get Exchange A Address
        address exchangeA_address = uniswapFactoryA.getExchange(DAI_ADDRESS);
        // Instantiate Exchange A
        exchangeA = IUniswapExchange(exchangeA_address);

        //Instantiate Uniswap Factory B
        uniswapFactoryB = IUniswapFactory(UNISWAP_FACTORY_B);
        // get Exchange B Address
        address exchangeB_address = uniswapFactoryB.getExchange(BAT_ADDRESS);
        //Instantiate Exchange B
        exchangeB = IUniswapExchange(exchangeB_address);
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

        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // If transactions are not mined until deadline the transaction is reverted
        uint256 deadline = getDeadline();

        IERC20 dai = IERC20(DAI_ADDRESS);
        IERC20 bat = IERC20(BAT_ADDRESS);

        // Buying ETH at Exchange A
        require(
            dai.approve(address(exchangeA), amounts[1]),
            "Could not approve DAI sell"
        );

        uint256 tokenBought = exchangeA.tokenToTokenSwapInput(
            amounts[1],
            1,
            1,
            deadline,
            BAT_ADDRESS
        );

        require(
            bat.approve(address(exchangeB), tokenBought),
            "Could not approve DAI sell"
        );

        // Selling ETH at Exchange B
        uint256 daiBought = exchangeB.tokenToTokenSwapInput(
            tokenBought,
            1,
            1,
            deadline,
            DAI_ADDRESS
        );

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }



        // Any left amount of DAI is considered profit
        uint256 profit = dai.balanceOf(address(this));
        // Sending back the profits
        require(
            dai.transfer(msg.sender, profit),
            "Could not transfer back the profit"
        );

        return true;
    }

    function myFlashLoanCall() public {
        address receiverAddress = address(this);

        address[] memory assets = new address[](2);
        // assets[0] = address(0xB597cd8D3217ea6477232F9217fa70837ff667Af); // Kovan AAVE
        assets[0] = address(BAT_ADDRESS); // Kovan BAT
        assets[1] = address(DAI_ADDRESS); // Kovan DAI
        // assets[0] = address(0x2d12186Fbb9f9a8C28B3FfdD4c42920f8539D738); // Kovan BAT
        // assets[1] = address(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD); // Kovan DAI
        // assets[3] = address(0x075A36BA8846C6B6F53644fDd3bf17E5151789DC); // Kovan UNI
        // assets[4] = address(0xb7c325266ec274fEb1354021D27FA3E3379D840d); // Kovan YFI
        // assets[5] = address(0xAD5ce863aE3E4E9394Ab43d4ba0D80f419F61789); // Kovan LINK
        // assets[6] = address(0x7FDb81B0b8a010dd4FFc57C3fecbf145BA8Bd947); // Kovan SNX

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        // amounts[2] = 1 ether;
        // amounts[3] = 1 ether;
        // amounts[4] = 1 ether;
        // amounts[5] = 1 ether;
        // amounts[6] = 1 ether;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;
        modes[1] = 0;
        // modes[2] = 0;
        // modes[3] = 0;
        // modes[4] = 0;
        // modes[5] = 0;
        // modes[6] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
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

    function getDeadline() internal view returns (uint256) {
        return now + 3000;
    }
}