/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

// Current Version of solidity
pragma solidity ^0.8.2;

// Main coin information
interface SpooderToken {
    //mapping(address => uint) public balances;
    //mapping(address => mapping(address => uint)) public allowance;
    function allowance() external view returns (uint);
    function totalSupply() external view returns (uint);
    // function name() public pure returns (string);
    // function symbol() public pure returns (string);
    function decimals() external view returns (uint);
    function devWallet1() external view returns (address);
    function devWallet2() external view returns (address);
    function lpWallet() external view returns (address);
    function taxWallet() external view returns (address);
    //event Transfer(address indexed from, address indexed to, uint value);
    // event Approval(address indexed owner, address indexed spender, uint value);
    function balanceOf(address) external returns(uint);
    function transfer(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function approve(address, uint) external returns (bool);
}

contract SpooderSilk {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Spooder Silk Dev";
    string public symbol = "SILK-DEV";
    uint public decimals = 18;
    // Dev wallets
    address public devWallet1 = 0xB33662186c4FCFAFc2E4Ca9A8F08a4840200ad5d;
    address public devWallet2 = 0x37B997DD48932E6B6186189e419e58ff4f02FB9d;
    // Staking Wallet
    address public stakeWallet = 0xa586D78971Aa896E24239ccebA84477B598cE198;
    // SPOOD Contract address
    address public contractSPOOD = 0x3E6f8f859efCe9bc509a0c03497e0548e5BF3950;
    address public contractSILK;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        // Dev wallets
        balances[devWallet1] = 100000000*0.1 * 10 ** 18;
        balances[devWallet2] = 100000000*0.1 * 10 ** 18;
        // Staking Wallet
        balances[stakeWallet] = 100000000*0.8 * 10 ** 18;
        contractSILK = address(this);
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // Only allow transfers between Staking Wallet and user, no user to user transfers.
        if (msg.sender != stakeWallet) {
            require(to == stakeWallet,'You can only send SILK to the SPOOD Staking Wallet');
        }
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function stake(uint value) public returns(bool) {
        require(SpooderToken(contractSPOOD).balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // approve contract address on SPOOD wallet first
        SpooderToken(contractSPOOD).transferFrom(msg.sender, stakeWallet, value);
        balances[msg.sender] += value;
        balances[stakeWallet] -= value;
        emit Transfer(stakeWallet, msg.sender, value);
        return true;
    }
    
    function unstake(uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // approve contract address on SPOOD stake wallet after deployment
        SpooderToken(contractSPOOD).transferFrom(stakeWallet, msg.sender, value);
        balances[stakeWallet] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, stakeWallet, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        // Only allow transfers between Staking Wallet and user, no user to user transfers.
        if (from != stakeWallet) {
            require(to == stakeWallet,'You can only send SILK to the SPOOD Staking Wallet');
        }
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}