// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DEX {
    using SafeMath for uint256;

    uint256 constant public START_TIME = 1614704400; // start
    uint256 constant public PRESALE_DAYS = 3;//
    uint256 constant public LOCK_DAYS = 1;
    uint256 constant public RATE = 1000;
    uint256 constant public minBNB = 1;//0.1 BNB
    uint256 constant public maxBNB = 10;//1 BNB
    uint256 constant public DIVIDER = 10;

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    ERC20 constant public token = ERC20(0x390626db689C1b3B5ED100d4A20E7ad8865016EE);

    function buy() public payable{
        require(block.timestamp >= START_TIME,"Start Tue Mar 02 2021 17:00:00 GMT+0000");
        require(msg.value >= minBNB.div(DIVIDER),"Min amount 0.1 BNB");
        uint tokens = msg.value.mul(RATE);
        require(token.balanceOf(address(this)) >= tokens);
        //uint commission = msg.value/100; // 1% of wei tx
        //require(address(this).send(commission));
        token.transfer(msg.sender, tokens);
        emit Bought(tokens);
    }

    function sell(uint256 amount) public {
        require(block.timestamp >= START_TIME,"Start Tue Mar 02 2021 17:00:00 GMT+0000");
        require(amount > 0, "You need to sell at least some tokens");
        uint256 bnb = amount.div(RATE);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= bnb, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(bnb);
        emit Sold(amount);
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

