/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SafeMoonSwapAirdrop {
    IERC20 public token;
    address payable public owner;
    mapping (address => uint256) public rewards;

    event OwnershipTransferred(address indexed _old, address indexed _new);
    event Claim(address indexed _user, uint256 indexed _amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    constructor(IERC20 _token) public {
        token = _token;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function transferOwnership(address payable _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
    struct RewardInfo {address user; uint256 amount;}
    function setRewards(RewardInfo[] memory _infos) public onlyOwner {
        for (uint256 i = 0; i < _infos.length; i++) {
            require(_infos[i].amount != 1, "invalid amount");
            require(rewards[_infos[i].user] == 0, "already set");
            rewards[_infos[i].user] = _infos[i].amount;
        }
    }
    function clearUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            rewards[_users[i]] = 0;
        }
    }
    function claim() public returns (bool) {
        uint256 amount = rewards[msg.sender];
        require(amount > 1, "invalid amount");
        uint256 balance = token.balanceOf(address(owner));
        require(balance >= amount, "not enough balance");
        assert(token.transferFrom(owner, msg.sender, amount));
        rewards[msg.sender] = 1;
        emit Claim(msg.sender, amount);
        return true;
    }
}