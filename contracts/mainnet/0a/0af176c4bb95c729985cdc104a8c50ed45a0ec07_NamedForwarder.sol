// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

contract NamedForwarder {

    mapping(bytes32 => uint256) public _userBalances;
    mapping(bytes32 => address) public _usersByAddress;
    mapping(address => bool) public _oracles;
    address internal owner;

    event DepositEvent(address from, bytes32 to, uint256 value);
    event WithdrawEvent(bytes32 from, address to, uint256 value);

    modifier onlyOwner {
        require(owner == msg.sender, "Only the owner of this contract can perform this action");
        _;
    }

    modifier onlyOracles {
        require(_oracles[msg.sender], "Only oracles can confirm operations.");
        _;
    }

    constructor() public {
        owner = msg.sender;
        _oracles[owner] = true;
    }

    function enableOracle(address oracle) external onlyOwner {
        _oracles[oracle] = true;
    }

    function disableOracle(address oracle) external onlyOwner {
        require(_oracles[oracle], "Oracle does not exists.");
        require(oracle != owner, "Owner oracle can not be removed.");
        _oracles[oracle] = false;
    }

    function deposit(bytes32 account) external payable {
        require(msg.value > 0, "No ether sent.");
        _userBalances[account] += msg.value;
        emit DepositEvent(msg.sender, account, msg.value);
    }

    function withdraw(bytes32 account) external {
        require(_usersByAddress[account] == msg.sender, "You can not withdraw for this account");
        require(_userBalances[account] > 0, "There is nothing to withdraw");
        payable(_usersByAddress[account]).transfer(_userBalances[account]);
        emit WithdrawEvent(account, _usersByAddress[account], _userBalances[account]);
        _userBalances[account] = 0;
    }

    function approveAddress(address wallet, bytes32 account) external onlyOracles {
        _usersByAddress[account] = wallet;
    }

}