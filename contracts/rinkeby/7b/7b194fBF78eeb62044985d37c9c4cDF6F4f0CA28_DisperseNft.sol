/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

contract DisperseNft {
    function disperse(IERC1155 token, address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) public {
        bool approval = token.isApprovedForAll(msg.sender, address(this));
        if (!approval) {
            revert("Sender has not approved disperse contract");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 preBalance = token.balanceOf(msg.sender, ids[i]);
            uint256 reqBalance = recipients.length * values[i];

            if (reqBalance > preBalance) {
                revert("Insufficient balance");
            }
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeBatchTransferFrom(msg.sender, recipients[i], ids, values, data);
        }
    }
}