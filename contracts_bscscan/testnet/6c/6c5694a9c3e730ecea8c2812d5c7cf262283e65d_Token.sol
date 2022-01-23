// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract Token is ERC20 {
    address public nftContract;

    constructor() ERC20("Robotic", "RBT") {
        _mint(address(this), 5000000 * (10**uint256(decimals())));
        _approve(address(this), msg.sender, totalSupply());
        _transfer(address(this), msg.sender, totalSupply());
    }

    function setNftContract(address _nftContract) public {
        nftContract = _nftContract;
    }

    function mintReward(address rewarded, uint256 amount) public {
        require(msg.sender == nftContract);
        _mint(rewarded, amount);
    }
}