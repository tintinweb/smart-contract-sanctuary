// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Partnerable.sol";
import "./ERC20Burnable.sol";

contract Coin is ERC20Burnable, Partnerable {
    address public tokenAddress;
    event mintCoined(address _partner, address _to, uint256 _amount);
    event burnCoined(address _partner, address _to, uint256 _amount);

    constructor(uint256 _supply) ERC20("GameCoin", "Coin") {
        owner = msg.sender;
        tokenAddress = address(this);
        _mint(owner, _supply * (10**decimals()));
        _approve(tokenAddress, owner, totalSupply());
        addPartner(owner);
    }

    function mintCoin(uint256 _supply, address _address) public onlyPartner {
        _mint(_address, _supply * (10**decimals()));
        emit mintCoined(msg.sender, _address, _supply);
    }

    function burnCoin(uint256 _supply, address _address) public onlyPartner {
        _burn(_address, _supply);
        emit burnCoined(msg.sender, _address, _supply);
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }
}