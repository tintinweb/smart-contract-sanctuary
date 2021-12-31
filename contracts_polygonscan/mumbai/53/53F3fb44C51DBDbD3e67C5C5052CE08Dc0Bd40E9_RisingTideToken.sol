// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces.sol";


contract RisingTideToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private constant transferFee = 95;

    constructor() public ERC20("RisingTideToken", "RTT") {
        uint256 initialSupply = 1000000000 * 10**18;
        mint(initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        uint256 amountToTransfer = amount.mul(transferFee).div(100);
        uint256 amountToBurn = amount.sub(amountToTransfer);
        _transfer(msg.sender, recipient, amountToTransfer);
        burn(amountToBurn);
        return true;
    }
}