pragma solidity ^0.8.0;

interface I_ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PausedReserve {

    event Withdraw(address to, uint256 amount);

    bool public canWithdraw;
    address public owner;
    address public gov = 0xade20A93179003300529AfeF3853F9679234D929;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(address to, uint256 amount, bool max) external {
        require(canWithdraw, "!canWithdraw");
        require(msg.sender == gov, "PausedReserve: not gov");
        if (max) {amount = I_ERC20(dai).balanceOf(address(this));}
        require(
            I_ERC20(dai).transfer(to, amount),
            "withdraw: transfer failed"
        );
        emit Withdraw(to, amount);
    }

    function approveWithdrawal() external returns (bool) {
        require(msg.sender == owner, "!owner");
        canWithdraw = true;
    }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}