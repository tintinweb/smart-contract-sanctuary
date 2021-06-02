/**
 *Submitted for verification at Etherscan.io on 2021-06-02
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
pragma experimental ABIEncoderV2;

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
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IUniswapRouterV2{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface DepositContract{
    function deposit(bytes calldata pubkey,bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root) external payable;
}


contract ARenew is Owned{
    uint public price=600000000;
    uint public fee=90000000;
    address public uniswapAddress=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETHAddress=0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public USDAddress=0xda5C6931Cc4e44fDd22C6Aa86b4f1fDA7e20eC04;
    address public DepositContractAddress=0x6BaF62E8b0Dde0Fd038f74b21dba1F6f7a76F154;
    
    event renewFund(address user,uint period, uint amount, bytes _extraData);
    event depositLog(address user, bytes pubkey, uint amount);
    
    constructor () public {}
    
    function ERC20Renew(address from, ERC20 addr, uint amount, uint period, bytes calldata _extraData) public returns (bool success) {
        require(amount == period * price);
        emit renewFund(msg.sender, period, amount, _extraData);
        return addr.transferFrom(from, address(this), amount);
    }
    
    function receiveApproval(address from,uint amount, ERC20 addr, bytes calldata _extraData) external returns (bool success){
        require(amount % price == 0);
        uint period = amount/price;
        return ERC20Renew(from, addr, amount, period, _extraData);
    }
    
    receive() external payable {
    }
    
    function generateMessageToSign(bytes memory pubkey, uint value) public view returns (bytes32) {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, pubkey, value));
        return message;
    }
    
    function deposit(DepositContract addr, bytes[] calldata pubkeys, bytes[] calldata withdrawal_credentials,bytes[] calldata signatures,bytes32[] calldata deposit_data_roots, uint _fee) external payable{
        uint len = pubkeys.length;
        require(len <= 16, "Stack too deep, try removing local variables.");
        require(_fee == msg.value - len*32 ether, "fee is not match!");
        uint ethFee = getAmountsOut(fee*90/100, USDAddress, WETHAddress);
        require(_fee >= ethFee*len, "fee is error!");
        require(DepositContract(DepositContractAddress) == addr, "DepositContractAddress is not match!");
        
        for(uint i=0;i<len;++i){
            addr.deposit{value: 32 ether}(pubkeys[i], withdrawal_credentials[i], signatures[i], deposit_data_roots[i]);
            emit depositLog(msg.sender, pubkeys[i], msg.value);
        }
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
    
    function setDepositContractAddr(address _addr) public onlyOwner{
        DepositContractAddress = _addr;
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