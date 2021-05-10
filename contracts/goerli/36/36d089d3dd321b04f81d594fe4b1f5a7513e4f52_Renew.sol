/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.6.2;

contract Owned{
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface ERC20{
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) ;
}

interface DepositContract{
    function deposit(bytes calldata pubkey,bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root) external payable;
}


contract Renew is Owned{
    uint public price= 600000000;
    uint public serviceFee = 0.16 ether;
    
    event renewFund(address user,uint period, uint amount);
    event depositLog(address user, bytes pubkey, uint amount);
    
    constructor () public {}
    
    function ERC20Renew(address from, ERC20 addr, uint amount, uint period) public returns (bool success) {
        require(amount == period * price);
        emit renewFund(msg.sender, period, amount);
        return addr.transferFrom(from, address(this), amount);
    }
    
    function receiveApproval(address from,uint amount, ERC20 addr, bytes calldata _extraData) external returns (bool success){
        require(amount % price == 0);
        uint period = amount/price;
        return ERC20Renew(from, addr, amount, period);
    }
    
    function deposit(DepositContract addr, bytes calldata pubkey,bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root) external payable{
        uint amount = msg.value - serviceFee;
        addr.deposit{value: amount}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        emit depositLog(msg.sender, pubkey, amount);
    }
    
    function setPrice(uint _price) public onlyOwner{
        price = _price;
    }
    
    function withdrawBalance(address cfoAddr) external onlyOwner{
        uint256 balance = address(this).balance;
        address payable _cfoAddr = address(uint160(cfoAddr));
        _cfoAddr.transfer(balance);
    }
}