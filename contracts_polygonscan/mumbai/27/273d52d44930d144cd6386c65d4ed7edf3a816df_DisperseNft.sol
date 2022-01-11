/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC720 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

contract DisperseNft {
    function disperse(IERC720 token, address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external {
        require(token.isApprovedForAll(msg.sender, address(this)), "Sender has not approved disperse contract");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 preBalance = token.balanceOf(msg.sender, ids[i]);
            uint256 reqBalance = recipients.length * values[i];

            require(reqBalance <= preBalance, "Insufficient balance");
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeBatchTransferFrom(msg.sender, recipients[i], ids, values, data);
        }
    }
}