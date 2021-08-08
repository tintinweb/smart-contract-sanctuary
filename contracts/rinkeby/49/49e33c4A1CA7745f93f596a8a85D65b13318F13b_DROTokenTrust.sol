/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity ^0.8.0;

contract DROTokenTrust {
    mapping(address => uint256) private _balances;

    constructor() {

    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function deposit() public payable {
        uint256 amount = msg.value;
        require(amount > 0, "Amount should be greater than 0");

        _balances[msg.sender] += amount;
    }

    receive() external payable {}

    function withdraw(uint256 amount) public {
        uint256 senderBalance = _balances[msg.sender];
        require(senderBalance > 0, "Nothing to withdraw");
        require(senderBalance >= amount, "Not enough tokens to withdraw");

        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}