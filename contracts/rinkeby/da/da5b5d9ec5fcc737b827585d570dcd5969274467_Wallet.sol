/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Wallet {

    function deposit() public payable {}

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function multisendEther(
        address payable[] calldata _recipients,
        uint256[] calldata _amounts
    ) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _recipients.length; i++) {
            require(total >= _amounts[i], "Insufficient total amount provided.");
            total = total - _amounts[i];
            _recipients[i].transfer(_amounts[i]);
        }
    }
}