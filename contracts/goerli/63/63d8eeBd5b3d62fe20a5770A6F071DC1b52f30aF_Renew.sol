/**
 *Submitted for verification at Etherscan.io on 2021-05-28
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

interface IUniswapRouterV2{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface DepositContract{
    function deposit(bytes calldata pubkey,bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root) external payable;
}


contract Renew is Owned{
    uint public price;
    bool public isSend;
    uint public fee=90000000;
    address public uniswapAddress=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETHAddress=0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public USDAddress=0xda5C6931Cc4e44fDd22C6Aa86b4f1fDA7e20eC04;
    
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
    
    receive() external payable {
    }
    
    function generateMessageToSign(bytes memory pubkey, uint value) public view returns (bytes32) {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, pubkey, value));
        return message;
    }
    
    function deposit(DepositContract addr, bytes memory pubkey, bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root, uint _fee) external payable{
        require(_fee == msg.value - 32 ether, "fee is not match!");
        uint ethFee = getAmountsOut(fee*90/100, USDAddress, WETHAddress);
        require(_fee > ethFee, "fee is error!");

        if(isSend=true){
            addr.deposit{value: 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        }
        emit depositLog(msg.sender, pubkey, msg.value);
    }
    
    function getAmountsOut(uint _tokenNum, address _symbolAddress, address _returnSymbolAddress) public view returns (uint) {
        address[] memory addr = new address[](2);
        addr[0] = _symbolAddress;
        addr[1] = _returnSymbolAddress;
        uint[] memory amounts = IUniswapRouterV2(uniswapAddress).getAmountsOut(_tokenNum, addr);
        return amounts[1];
    }
    
    function setFeeConfigAddress(address _uniswapAddress,address _WETHAddress,address _USDAddress) public onlyOwner{
        uniswapAddress = _uniswapAddress;
        WETHAddress = _WETHAddress;
        USDAddress = _USDAddress;
    }
    function setFee(uint _fee) public onlyOwner{
        fee = _fee;
    }
    
    function setOpen(bool b) public onlyOwner{
        isSend = b;
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