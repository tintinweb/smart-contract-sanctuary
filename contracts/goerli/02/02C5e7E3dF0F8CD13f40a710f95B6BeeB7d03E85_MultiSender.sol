/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract MultiSender {
    event Send(address indexed from, address indexed to, uint256 amount);

    function send(uint256[] memory amounts, address payable[] memory recipients)
        public
        payable
    {
        require(
            amounts.length == recipients.length,
            "amounts length must equal recipients length"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
            emit Send(msg.sender, recipients[i], amounts[i]);
        }
    }
}