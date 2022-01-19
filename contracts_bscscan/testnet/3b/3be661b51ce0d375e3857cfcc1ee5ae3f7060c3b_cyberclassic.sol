// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract cyberclassic is ERC20, Ownable {
    using SafeERC20 for IERC20;

    constructor(
        string memory _name, 
        string memory _symbol,
        uint256 _initialSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply * (10 ** 18) );
    } 

    function clearTokens(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(this), "Cannot clear same tokens as Cyberclassic");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}