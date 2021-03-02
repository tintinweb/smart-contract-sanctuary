pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./SafeMath.sol";
import "./TimeLockedWallet.sol";
import "./ERC20.sol";

contract MyTestToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => TimeLockedWallet[]) private wallets;
    address owner;

    constructor() public ERC20("PKTesting", "PKT") {
        owner = msg.sender;
        super._mint(_msgSender(), 800000000 * 10 ** 18);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can make this request");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
          owner = newOwner;
        }
    }

    function multisend(address[] memory dests, uint256 amount) public onlyOwner
        returns (uint256) {
            require(dests.length > 0, "Require at least 1 address");
            uint256 value = amount / dests.length;
            uint256 i = 0;
            while (i < dests.length) {
                transfer(dests[i], value);
                i += 1;
            }
            return(i);
    }
    
    function requestWallet(address _owner, uint256 _amount, uint256 _unlockDate) public onlyOwner {
        TimeLockedWallet wallet = new TimeLockedWallet(_msgSender(), _owner, _unlockDate);
        wallets[_owner].push(wallet);
        transfer(address(wallet), _amount);
        emit RequestWallet(address(wallet), _msgSender(), _owner, block.timestamp, _unlockDate, _amount);
    }
    
    function walletCount() public view returns (uint256) {
        return wallets[_msgSender()].length;
    }
    
    function walletBalanceAt(uint index) public view returns (uint256) {
        require(index < wallets[_msgSender()].length);
        return balanceOf(address(wallets[_msgSender()][index]));
    }
    
    function walletUnlockAt(uint index) public view returns (uint256) {
        require(index < wallets[_msgSender()].length);
        return wallets[_msgSender()][index].unlockDate();
    }
    
    function withdrawWallet(uint index) public {
        require(index < wallets[_msgSender()].length);
        wallets[_msgSender()][index].withdrawTokens(address(this));
    }
    
    event RequestWallet(address wallet, address from, address to, uint createdAt, uint unlockDate, uint amount);
}