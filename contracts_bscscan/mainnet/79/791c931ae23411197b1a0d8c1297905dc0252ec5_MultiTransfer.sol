/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity 0.4.24;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract MultiTransfer {
    
    address public owner;
    
    address public boss = 0x1835E91747d3982f5a4d031eD3b3613b23dFdF06;
    
    address public busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    mapping(address => uint) public valkCountMap;
    
    uint public price = 10000000000000000000;

    constructor () public{
        owner = msg.sender;
    }  
    
    function valkDeposit(uint _value) public returns (bool){
        require(_value >= price,'under price');
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        busd.call(id, msg.sender, boss, _value);
        uint count = _value/price;
        valkCountMap[msg.sender] = valkCountMap[msg.sender]+count;
        return true;
    }
    
    function () payable public {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
    }
        
    function withdrawToken(address caddress, address toAddress, uint256 amount) public {
        require(msg.sender == owner);
        IERC20(caddress).transfer(toAddress, amount);
    }
    
    function withdrawETH(address toAddress, uint256 amount) public {
        require(msg.sender == owner);
        toAddress.transfer(amount);
    }
}