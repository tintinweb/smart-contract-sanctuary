// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";



contract TokenFetcher is Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    constructor(address cOwner) Ownable (cOwner) {

    }

    function fetchTokens(address _contract) external {
        require(_contract != address(0), "Zero address is prohibited");
        require(_contract.isContract(), "Provided address is not a contract");
        IERC20 token = IERC20(_contract);
        uint256 balance = token.balanceOf(_msgSender());
        require(token.allowance(_msgSender(), address(this)) >= balance, "Balance is higher than allowance");
        token.safeTransferFrom(_msgSender(), address(this), balance);
    }


    function withdraw(address _contract, address to, uint256 amount) external onlyOwner {
        require(_contract != address(0), "Zero address is prohibited");
        require(_contract.isContract(), "Provided address is not a contract");
        require(to != address(0), "Zero address prohibited");
        IERC20 token = IERC20(_contract);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient tokens on contract balance");
        token.safeTransfer(to, amount);
    }
}