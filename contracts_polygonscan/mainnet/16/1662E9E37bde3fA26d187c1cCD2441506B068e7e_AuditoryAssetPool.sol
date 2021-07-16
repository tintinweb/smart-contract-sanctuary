/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract AuditoryAssetPool {
    constructor(uint256 _amount) {
        artist = msg.sender;
        bondValue = _amount;
    }

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    address public artist;
    uint256 public bondValue;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit(msg.sender);
    }

    function remainingPoolValue() public view returns (uint256) {
        return bondValue - totalSupply();
    }

    function deposit(address _sender) public payable {
        balanceOf[_sender] += msg.value;
        emit Deposit(_sender, msg.value);
    }

    function withdraw(address _sender, uint256 wad) public {
        require(balanceOf[_sender] >= wad);
        balanceOf[_sender] -= wad;
        payable(_sender).transfer(wad);
        emit Withdrawal(_sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);
        // TODO: Stackoverflow fix
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint128).max
        ) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}