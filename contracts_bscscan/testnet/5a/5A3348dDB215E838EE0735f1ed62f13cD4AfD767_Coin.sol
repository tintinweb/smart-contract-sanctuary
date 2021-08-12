// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Partnerable.sol";
import "./ERC20.sol";

contract Coin is ERC20, Partnerable {
    event mintCoined(address _partner, address _to, uint256 _amount);
    event burnCoined(address _partner, address _to, uint256 _amount);
    event tipCoin(address _from, uint256 _amount);
    event isPauseCoin(bool _pause);

    address public tokenAddress;
    bool public pause = true;

    constructor(uint256 _supply) ERC20("GameCoin", "Coin") {
        owner = _msgSender();
        tokenAddress = address(this);
        _mint(owner, _supply * (10**decimals()));
        _approve(tokenAddress, owner, totalSupply());
        addPartner(owner);
        pause = false;
    }

    function pauseCoin() public onlyOwner {
        pause = true;
        emit isPauseCoin(pause);
    }

    function runCoin() public onlyOwner {
        pause = false;
        emit isPauseCoin(pause);
    }

    modifier isNotPause() {
        require(!pause);
        _;
    }

    function mintCoin(uint256 _supply, address _address)
        public
        onlyPartner
        isNotPause
    {
        _mint(_address, _supply * (10**decimals()));
        emit mintCoined(_msgSender(), _address, _supply);
    }

    function burnCoin(uint256 _supply, address _address)
        public
        onlyPartner
        isNotPause
    {
        _burn(_address, _supply * (10**decimals()));
        emit burnCoined(_msgSender(), _address, _supply);
    }

    function tipDeveloper(uint256 _amount, address payable _from)
        public
        isNotPause
    {
        _transfer(_from, owner, _amount);
        emit tipCoin(_from, _amount);
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }
}