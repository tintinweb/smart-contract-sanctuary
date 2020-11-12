pragma solidity ^0.5.8;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event TransferBurn(address indexed src, address indexed dst, uint wad, uint remainAmount, uint receiveAmount, uint burnAmount, uint rewardAmount);
}
