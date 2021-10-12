// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";


contract PayromaToken is BEP20('Payroma Wallet', 'PYA') {
    uint256 public inflationPercent;
    uint256 public inflationDurationEnd;
    
    uint256 private _inflationDuration;
    uint256 private _availableToMint;

    constructor() public {
        inflationPercent = 5;
        _inflationDuration = 365 days;

        uint256 _initialSupply = 20000000e18;
        _mint(owner(), _initialSupply);
    }

    function availableToMintCurrentYear() public view returns (uint256) {
        if (block.timestamp > inflationDurationEnd) {
            return totalSupply().mul(inflationPercent).div(100);
        }

        return _availableToMint;
    }

    function transferMultiple(address[] calldata addresses, uint256[] calldata amounts) public returns (bool) {
        require(addresses.length <= 100, 'BEP20: addresses exceeds 100 address');
        require(addresses.length == amounts.length, 'BEP20: mismatch between addresses and amounts count');

        uint256 totalAmount = 0;
        for (uint i=0; i < addresses.length; i++) {
            totalAmount = totalAmount + amounts[i];
        }

        require(balanceOf(_msgSender()) >= totalAmount, 'BEP20: balance is not enough');

        for (uint i=0; i < addresses.length; i++) {
            transfer(addresses[i], amounts[i]);
        }

        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address spender, uint256 amount) public returns (bool) {
        _burnFrom(spender, amount);
        return true;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, 'Cannot mint 0');

        _availableToMint = availableToMintCurrentYear().sub(amount, 'BEP20: not enough tokens available to mint');

        if (block.timestamp > inflationDurationEnd) {
            inflationDurationEnd = block.timestamp + _inflationDuration;
        }

        _mint(_msgSender(), amount);
        return true;
    }

    function recoverBEP20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
        return IBEP20(tokenAddress).transfer(_msgSender(), amount);
    }
}