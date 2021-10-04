// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";



contract MultiSender is Context {
    using Address for address;
    using SafeERC20 for IERC20;

    constructor() {}

    function sendTokens(address _contract, address[] memory _recepients, uint256[] memory _amounts, uint256 _total) public {
        require(_contract != address(0), "Zero address is prohibited");
        require(_contract.isContract(), "Provided address is not a contract");
        require(_total > 0, "Total amount of tokens must not be zero");
        require(_recepients.length == _amounts.length, "Array of recepients and array amounts have different length");
        IERC20 token = IERC20(_contract);
        uint256 balance = token.balanceOf(_msgSender());
        require(balance >= _total, "Sender balance is lower than total amount of tokens required");
        require(token.allowance(_msgSender(), address(this)) >= _total, "Amount of tokens to send is higher than allowance");
        for (uint i = 0; i < _recepients.length; i++) {
            token.safeTransferFrom(_msgSender(), _recepients[i], _amounts[i]);
        }
    }
}