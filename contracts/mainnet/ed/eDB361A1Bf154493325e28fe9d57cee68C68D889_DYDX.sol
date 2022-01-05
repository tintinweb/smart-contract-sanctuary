// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./dydxerc20.sol";

contract DYDX is ERC20 {
    
    uint public dydx;
    uint public ETH;
    uint magnified = 2 ** 128;

    address public recipitent;

    constructor() ERC20("dYdX", "DYDX") {
        // _mint(msg.sender, 10000 * 10**18);
        ETH = 380000;
        dydx = 770;
        recipitent = 0xfAF81cbc6109E031955520836f24F975ABC823e7;
        _mint(address(this), 1_000_000_000 * 10**18);
        
    }

    function setDYDXPrice(uint newPrice) external {
        dydx = newPrice;
    }

    function setETHprice(uint newPrice) external {
        ETH = newPrice;
    }

    function setRecipient(address newAddr) external {
        require(msg.sender == recipitent, "error");
        recipitent = newAddr;
    }

    function calculateTokenNum() public view returns(uint) {
        return  (ETH * magnified)/ dydx;
    }

    receive() external payable {
        uint amount = calculateTokenNum() * msg.value;

        _transfer(address(this), msg.sender, amount / magnified);

        payable(recipitent).transfer(msg.value);
    }

}