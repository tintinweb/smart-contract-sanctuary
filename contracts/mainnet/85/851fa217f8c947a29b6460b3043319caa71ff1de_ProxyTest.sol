pragma solidity 0.7.0;
interface I {
    function transfer(address r, uint256 a) external;
}
contract ProxyTest {
    address payable private b;
    uint256 public f;
    constructor() {
        b = msg.sender;
        f = 1; // spend 20000 gas
    }
    function w(address c, address  t, uint256 a) external {
        require(b == msg.sender, "");
        f = 0; // spend 5000 gas, refund 15000 gas
        I e = I(c);
        e.transfer(t, a);
    }
}

