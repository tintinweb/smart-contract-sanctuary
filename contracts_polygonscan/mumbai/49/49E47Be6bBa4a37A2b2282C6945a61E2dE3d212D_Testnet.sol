// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testnet {
    receive() external payable {}
    fallback() external payable {}

    event DepositTestnet(address account, uint256 amount);
    event WithdrawalTestnet(address account, uint256 amount);

    mapping (address => uint256) private _balanceOf;

    function contractBalanceTestnet() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOfTestnet(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function depositTestnet() public payable {
        _balanceOf[msg.sender] += msg.value;

        emit DepositTestnet(msg.sender, msg.value);
    }

    function withdrawTestnet(uint256 amount) public {
        require(amount <= _balanceOf[msg.sender], "Insufficient funds");

        _balanceOf[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");

        emit WithdrawalTestnet(msg.sender, amount);
    }
}