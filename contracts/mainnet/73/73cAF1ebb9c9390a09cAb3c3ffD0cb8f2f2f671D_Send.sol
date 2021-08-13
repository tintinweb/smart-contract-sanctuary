/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.5.16;




// Math operations with safety checks that throw on error
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
}


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    
    function balanceOf(address _address) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}




// Token contract
contract Send {
    // 交易
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    // 授权交易
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );
    // 管理员
    address public owner;
    
    // 构造函数;
    constructor() public {
        owner = msg.sender;
    }
    
    // 管理员修饰符
    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }
    
    // 设置新的管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "zero address");
        owner = _owner;
        success = true;
    }
    
    // 提取合约里面的币
    // 参数1: Token地址
    function fetch(ERC20 _erc20Address) public onlyOwner returns (bool success2) {
        uint256 _value = _erc20Address.balanceOf(address(this));
        (bool success, ) = address(_erc20Address).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success) {
            revert("transfer fail");
        }
        success2 = true;
    }
    
    // 批量转代币, 从合约里面扣币, 一样的数量
    // 参数1: Token地址
    // 参数2: 接收者地址数组
    // 参数3: 数量
    function batchTranferEqually(address _tokenAddress, address[] memory _addresss, uint256 _value) public onlyOwner returns (bool success2) {
        for(uint256 i = 0; i < _addresss.length; i++) {
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFER, _addresss[i], _value)
            );
            if(!success) {
                revert("transfer fail");
                
            }
        }
        success2 = true;
    }
    
    // 批量转代币, 从发送者地址扣币, 一样的数量
    // 参数1: Token地址
    // 参数2: 接收者地址数组
    // 参数3: 数量
    function batchTranferFromEqually(address _tokenAddress, address[] memory _addresss, uint256 _value) public onlyOwner returns (bool success2) {
        for(uint256 i = 0; i < _addresss.length; i++) {
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, _addresss[i], _value)
            );
            if(!success) {
                revert("transfer fail");
                
            }
        }
        success2 = true;
    }
    
    // 批量转代币, 从合约里面扣币, 不一样的数量
    // 参数1: Token地址
    // 参数2: 接收者地址数组
    // 参数3: 数量
    function batchTranferUnlike(address _tokenAddress, address[] memory _addresss, uint256[] memory _value) public onlyOwner returns (bool success2) {
        require(_addresss.length == _value.length, "length Unlike");
        for(uint256 i = 0; i < _addresss.length; i++) {
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFER, _addresss[i], _value[i])
            );
            if(!success) {
                revert("transfer fail");
                
            }
        }
        success2 = true;
    }
    
    // 批量转代币, 从发送者地址扣币, 不一样的数量
    // 参数1: Token地址
    // 参数2: 接收者地址数组
    // 参数3: 数量
    function batchTranferFromUnlike(address _tokenAddress, address[] memory _addresss, uint256[] memory _value) public onlyOwner returns (bool success2) {
        require(_addresss.length == _value.length, "length Unlike");
        for(uint256 i = 0; i < _addresss.length; i++) {
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, _addresss[i], _value[i])
            );
            if(!success) {
                revert("transfer fail");
                
            }
        }
        success2 = true;
    }
    
    
    
}