// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract PersonalSubgraphAnchor {
    event AddERC20(address user, address token);
    event AddERC20Sender(address user, address token);
    event AddERC721(address user, address token, uint256 tokenID);
    event AddERC721Sender(address user, address token, uint256 tokenID);

    function addERC20Sender(address _token) external {
        emit AddERC20Sender(msg.sender, _token);
    }
    function addERC20(address _user, address _token) external {
        emit AddERC20(_user, _token);
    }

}