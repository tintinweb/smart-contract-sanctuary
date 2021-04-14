/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.5.16;

// Math operations with safety checks that throw on error
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
            
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
            
        }
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
contract BHX is ERC20 {
    
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    // 管理员 
    address public owner;
    // 管理员2; 用于双重签名验证
    address public owner2;
    // 二次签名的验证; 只能使用一次
    mapping (bytes32 => bool) public signMsg;
    // usdt合约地址
    address public usdt;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    
    
    // "BHDEX Token","BHX","18000000","18"
    // owner2: 0xEd90A957557941C61Ad8c730d7f958bB6f7C668c
    // usdt: 0x70cCc035A942F58D5c532cFf22d7e3D2C1db17Df
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals, address _owner2, address _usdt) public {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * 10**uint256(_decimals);
        decimals = _decimals;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        owner2 = _owner2;
        usdt = _usdt;
    }
    
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Zero address error");
        require(balances[msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0) && _to != address(0), "Zero address error");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    // 管理员修饰符
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not owner");
        _;
        
    }
    
    // 设置新的管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "Zero address error");
        owner = _owner;
        success = true;
    }
    
    // 设置新的管理员2
    function setOwner2(address _owner2) public onlyOwner returns (bool success) {
        require(_owner2 != address(0), "Zero address error");
        owner2 = _owner2;
        success = true;
    }
    
    // 管理员取出合约里面全部的bhx
    function takeBhx(address _to) public onlyOwner returns (bool success) {
        require(_to != address(0), "Zero address error");
        // 获取合约地址全部的余额
        uint256 balanceBhx = balances[address(this)];
        // 从合约地址转出bhx到to地址
        balances[address(this)] = SafeMath.sub(balances[address(this)], balanceBhx);
        balances[_to] = SafeMath.add(balances[_to], balanceBhx);
        // 触发交易事件
        emit Transfer(address(this), _to, balanceBhx);
        success = true;
    }
    
    // 管理员取出合约里面全部的usdt, 也可取出其它代币
    function takeUsdt(address _usdtAddress, address _to) public onlyOwner returns (bool success2) {
        require(_usdtAddress != address(0) && _to != address(0), "Zero address error");
        // 创建usdt的合约对象
        ERC20 erc20 = ERC20(_usdtAddress);
        // 获取合约地址的余额
        uint256 balanceUsdt = erc20.balanceOf(address(this));
        // 从合约地址转出usdt到to地址
        (bool success, ) = address(_usdtAddress).call(
            abi.encodeWithSelector(TRANSFER, _to, balanceUsdt)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        success2 = true;
    } 
    
    
    // 后台交易bhx; 使用二次签名进行验证, 从合约地址扣除bhx
    function backendTransferBhx(address _to, uint256 _value, bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) public returns (bool success) {
        require(_to != address(0), "Zero address error");
        require(balances[address(this)] >= _value && _value > 0, "Insufficient balance or zero amount");
        // 必须是没有使用过的
        require(signMsg[_messageHash] == false, "MessageHash is used");
        // 验证得到的地址是不是owner2
        address signer = ecrecover(_messageHash, _v, _r, _s);
        require(signer == owner2, "Signer is not owner2");
        // 该messageHash设置为已使用
        signMsg[_messageHash] = true;
        // 从合约地址转出bhx到to地址
        balances[address(this)] = SafeMath.sub(balances[address(this)], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        // 触发交易事件
        emit Transfer(address(this), _to, _value);
        success = true;
    }
    
    // 抵押bhx借贷usdt; 使用二次签名进行验证, 从合约地址扣除usdt
    function backendTransferUsdt(address _to, uint256 _value, bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) public returns (bool success2) {
        require(_to != address(0), "Zero address error");
        // 创建usdt的合约对象
        ERC20 erc20 = ERC20(usdt);
        uint256 balanceUsdt = erc20.balanceOf(address(this));
        // 判断合约地址的usdt余额是否足够
        require(balanceUsdt >= _value && _value > 0, "Insufficient balance or zero amount");
        // 必须是没有使用过的
        require(signMsg[_messageHash] == false, "MessageHash is used");
        // 验证得到的地址是不是owner2
        address signer = ecrecover(_messageHash, _v, _r, _s);
        require(signer == owner2, "Signer is not owner2");
        // 该messageHash设置为已使用
        signMsg[_messageHash] = true;
        // 从合约地址转出usdt到to地址
        (bool success, ) = address(usdt).call(
            abi.encodeWithSelector(TRANSFER, _to, _value)
        );
        if(!success) {
            revert("Transfer is fail");
        }
        success2 = true;
    }
    
    
    
    
}