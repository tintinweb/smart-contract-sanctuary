pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface TakerInterface {
    function take(address, uint) external;
}

contract Migrator {
    TakerInterface public immutable t;
    constructor(address taker) {
        t = TakerInterface(taker);
    }

    function deposit(address token, uint amount) external {
        TokenInterface(token).transferFrom(msg.sender, address(this), amount);
    }

    function give(address token, uint amount) external {
        TokenInterface(token).approve(address(t), amount);
        t.take(token, amount);
    }
}

