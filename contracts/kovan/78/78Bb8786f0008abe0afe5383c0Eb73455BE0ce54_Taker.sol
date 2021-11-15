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

contract Taker {
    function withdraw(address token, address to) external {
        TokenInterface t = TokenInterface(token);
        TokenInterface(t).transfer(to, t.balanceOf(address(this)));
    }

    function take(address token, uint amt) external {
        TokenInterface t = TokenInterface(token);
        t.transferFrom(msg.sender, address(this), amt);
    }
}

