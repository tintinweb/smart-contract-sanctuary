/*
Implements DET token standard ERC20
POWER BY DET
.*/

pragma solidity ^0.4.21;

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ERC2.0 代币
contract DET is EIP20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    //创始者
    address public god;
    // 点卡余额
    mapping (address => uint256) public balances;
    // 点卡授权维护
    mapping (address => mapping (address => uint256)) public allowed;

    //服务节点
    struct ServiceStat {
        address user;
        uint64 serviceId;
        string serviceName;
        uint256 timestamp; 
    }

    //每个用户状态状态
    mapping (address => mapping (uint64 => ServiceStat)) public serviceStatMap;

    //服务价格
    struct ServiceConfig{
        uint64 serviceId;
        string serviceName;
        uint256 price;
        uint256 discount;
        address fitAddr;
        string detail;
    }
    //服务价格配置
    mapping (uint64 => ServiceConfig) public serviceConfgMap;
    mapping (uint64 => uint256) public serviceWin;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    //兑换比例
    uint256 public tokenPrice;
    
    //以下为ERC20的规范
    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        god = msg.sender;
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //以下为服务相关
    function getMsgSender() public view returns(address sender){
        return msg.sender;
    }

    //设置服务价格配置
    function setConfig(uint64 _serviceId, string _serviceName, uint256 _price, uint256 _discount, address _fitAddr, string _desc) public returns (bool success){
        require(msg.sender==god);
        serviceConfgMap[_serviceId].serviceId = _serviceId;
        serviceConfgMap[_serviceId].serviceName = _serviceName;
        serviceConfgMap[_serviceId].price = _price;
        serviceConfgMap[_serviceId].discount = _discount;
        serviceConfgMap[_serviceId].fitAddr = _fitAddr;
        serviceConfgMap[_serviceId].detail = _desc;
        return true;
    }

    //获取服务价格
    function configOf(uint64 _serviceId) public view returns (string serviceName, uint256 price, uint256 discount, address addr, string desc){
        serviceName = serviceConfgMap[_serviceId].serviceName;
        price = serviceConfgMap[_serviceId].price;
        discount = serviceConfgMap[_serviceId].discount;
        addr = serviceConfgMap[_serviceId].fitAddr;
        desc = serviceConfgMap[_serviceId].detail;
    }

    //购买服务
    function buyService(uint64 _serviceId,uint64 _count) public returns (uint256 cost, uint256 timestamp){
        require(_count >= 1);
        //计算多少点卡
        //ServiceConfig storage config = serviceConfgMap[_serviceId];
        cost = serviceConfgMap[_serviceId].price * serviceConfgMap[_serviceId].discount * _count / 100;
        address fitAddr = serviceConfgMap[_serviceId].fitAddr;
        //require(balances[msg.sender]>need);
        if( transfer(fitAddr,cost ) == true ){
            uint256 timeEx = serviceStatMap[msg.sender][_serviceId].timestamp;
            if(timeEx == 0){
                serviceStatMap[msg.sender][_serviceId].serviceId = _serviceId;
                serviceStatMap[msg.sender][_serviceId].serviceName = serviceConfgMap[_serviceId].serviceName;
                serviceStatMap[msg.sender][_serviceId].user = msg.sender;
                serviceStatMap[msg.sender][_serviceId].timestamp = now + (_count * 86400);
                serviceWin[_serviceId] += cost;
                timestamp = serviceStatMap[msg.sender][_serviceId].timestamp;
            }else{
                if(timeEx < now){
                    timeEx = now;
                }
                timeEx += (_count * 86400);
                serviceStatMap[msg.sender][_serviceId].timestamp = timeEx;
                timestamp = timeEx;
            }
        }else{
            timestamp = 0;
        }
        
    }

    //购买服务
    function buyServiceByAdmin(uint64 _serviceId,uint64 _count,address addr) public returns (uint256 cost, uint256 timestamp){
        require(msg.sender==god);
        require(_count >= 1);
        //计算多少点卡
        //ServiceConfig storage config = serviceConfgMap[_serviceId];
        cost = serviceConfgMap[_serviceId].price * serviceConfgMap[_serviceId].discount * _count / 100;
        address fitAddr = serviceConfgMap[_serviceId].fitAddr;
        timestamp = 0;
        require(balances[addr] >= cost);
        balances[fitAddr] += cost;
        balances[addr] -= cost;
        emit Transfer(addr, fitAddr, cost); 

        uint256 timeEx = serviceStatMap[addr][_serviceId].timestamp;
        if(timeEx == 0){
            serviceStatMap[addr][_serviceId].serviceId = _serviceId;
            serviceStatMap[addr][_serviceId].serviceName = serviceConfgMap[_serviceId].serviceName;
            serviceStatMap[addr][_serviceId].user = addr;
            serviceStatMap[addr][_serviceId].timestamp = now + (_count * 86400); 
            serviceWin[_serviceId] += cost;
            timestamp = serviceStatMap[addr][_serviceId].timestamp;
        }else{
            if(timeEx < now){
                timeEx = now;
            }
            timeEx += (_count * 86400);
            serviceStatMap[addr][_serviceId].timestamp = timeEx;
            timestamp = timeEx;
        }    
    }

    //获取服务时长
    function getServiceStat(uint64 _serviceId) public view returns (uint256 timestamp){
        timestamp = serviceStatMap[msg.sender][_serviceId].timestamp;
    }
    
    //获取服务时长
    function getServiceStatByAddr(uint64 _serviceId,address addr) public view returns (uint256 timestamp){
        require(msg.sender==god);
        timestamp = serviceStatMap[addr][_serviceId].timestamp;
    }

    //admin
    function getWin(uint64 _serviceId) public view returns (uint256 win){
        require(msg.sender==god);
        win = serviceWin[_serviceId];
        return win;
    }
    //设置token price
    function setPrice(uint256 _price) public returns (bool success){
        require(msg.sender==god);
        tokenPrice = _price;
        return true;
    }

    //get token price
    function getPrice() public view returns (uint256 _price){
        require(msg.sender==god);
        _price = tokenPrice;
        return tokenPrice;
    }
}