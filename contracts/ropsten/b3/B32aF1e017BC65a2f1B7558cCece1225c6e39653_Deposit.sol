pragma solidity 0.8.10;

import "./IERC20.sol";



contract Deposit {

    IERC20 public DAIToken;
    uint public DAIWallet;

    constructor() {
        DAIWallet = 0;
        DAIToken = IERC20(0x31F42841c2db5173425b5223809CF3A38FEde360);
    }

    function getAllowance() external view returns (uint) {
        return DAIToken.allowance(msg.sender, address(this));
    }

    function depositDAI(uint amount) external {
        DAIToken.transferFrom(msg.sender, address(this), amount);
        DAIWallet += amount;

    }

    function approve(address spender,uint amount) external {
        DAIToken.approve(spender, amount);
    }

    function withdraw(uint amount) external {
        require((DAIWallet-amount) > 0, "Empty wallet");
        DAIToken.transfer(msg.sender, amount);
        DAIWallet -= amount;
    }


}