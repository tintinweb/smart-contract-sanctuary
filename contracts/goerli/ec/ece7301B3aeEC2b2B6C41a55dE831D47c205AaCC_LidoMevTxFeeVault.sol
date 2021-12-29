// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0


pragma solidity 0.8.9;

interface ILido {

    /**
    * @notice A payable function supposed to be funded only by LidoMevTxFeeVault contract
    * @dev We need a separate function because funds received by default payable function
    * will go through entire deposit algorithm
    */
    function mevTxFeeReceiver() external payable;
}


/**
* @title A vault for temporary storage of MEV and transaction fees
*
* This contract has no payable functions because it's balance is supposed to be
* increased directly by ethereum protocol when transaction priority fees and extracted MEV
* rewards are earned by a validator.
* These vault replenishments happen continuously throught a day, while withdrawals
* happen much less often, only on LidoOracle beacon balance reports
*/
contract LidoMevTxFeeVault {
    address public immutable LIDO;

    constructor(address _lidoAddress) {
        require(_lidoAddress != address(0x0), "LIDO_ZERO_ADDRESS");

        LIDO = _lidoAddress;
    }

    /**
    * @notice Withdraw all accumulated rewards to Lido contract
    * @return amount uint256 of funds received as MEV and transaction fees in wei
    */
    function withdrawRewards() external returns (uint256 amount) {
        require(msg.sender == LIDO, "Nobody except Lido contract can withdraw");

        amount = address(this).balance;
        if (amount > 0) {
            ILido(LIDO).mevTxFeeReceiver{value: amount}();
        }
        return amount;
    }
}