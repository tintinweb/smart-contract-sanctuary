/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.4.26;

contract Token {
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    /// 获取账户_owner拥有token的数量
    function balanceOf(address _owner) constant returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) returns (bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) returns
    (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) returns (bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) constant returns
    (uint256 remaining);

    //发生转账时必须要触发的事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        //从消息发送者账户中减去token数量_value
        balances[_to] += _value;
        //往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);
        //触发转币交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >=
        // _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        //接收账户增加token数量_value
        balances[_from] -= _value;
        //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;
        //消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);
        //触发转币交易事件
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
        //允许_spender从_owner中转出的token数
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}

interface carTokenIERC20 {
    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    external
    returns (bool);
}

contract HumanStandardToken is StandardToken {

    /* Public variables of the token */
    string public name;                   //名称: eg Simon Bucks
    uint8 public decimals;               //最多的小数位数，How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;               //token简称: eg SBX
    string public version = 'H0.1';    //版本
    uint8 public coinPrice = 3;
    uint public lastUserId = 2;

    address public owner;

    carTokenIERC20 carToken;

    struct User {
        uint userId;
        address userAddress;
        uint turnover;
        address inviteAddress;
    }

    mapping(address => User) public users;

    mapping(uint => address) public userId;

    event Create(address ownerAddress);

    event Exchange(address userAddress, uint256 exchangeNum);

    function HumanStandardToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) {
        balances[address(this)] = _initialAmount;
        // 初始token数量给予消息发送者
        totalSupply = _initialAmount;
        // 设置初始总量
        name = _tokenName;
        // token名称
        decimals = _decimalUnits;
        // 小数位数
        symbol = _tokenSymbol;
        // token简称
        owner = msg.sender;

        User memory ownerInfo = User({
        userId : 1,
        userAddress : msg.sender,
        turnover : 0,
        inviteAddress : address(0)
        });
        users[msg.sender] = ownerInfo;
        userId[1] = msg.sender;

        emit Create(msg.sender);
    }

    /* Approves and then calls the receiving contract */

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    function exchangeToHum(address _user, address _inviteAddress, uint256 exchangeNum) public returns (bool success){

        require(isUserExists(_inviteAddress), "invite not exists");

        uint256 setNum = exchangeNum * coinPrice * 1 ether;
        uint256 toHumNum = exchangeNum * 10 ** decimals;

        // carTokenIERC20 carToken = carTokenIERC20(0x337610d27c682e347c9cd60bd4b3b107c9d34ddd);
        // carToken.transferFrom(_user, address(this), setNum);

        carTokenIERC20 carToken1 = carTokenIERC20(address(this));
        carToken1.transfer(_user, exchangeNum * 1 ether);
        
        if (isUserExists(_user)) {
            users[_user].turnover += toHumNum;
        } else {
            User memory userInfo = User({
            userId : lastUserId,
            userAddress : _user,
            turnover : toHumNum,
            inviteAddress : _inviteAddress
            });
            users[_user] = userInfo;
            userId[lastUserId] = _user;
            lastUserId++;
        }

        emit Exchange(_user, toHumNum);

        return true;
    }

    function extractToOwner(uint256 setAmount) public returns (bool){
        require(msg.sender == owner, "address error");
        carTokenIERC20 carToken = carTokenIERC20(0x337610d27c682e347c9cd60bd4b3b107c9d34ddd);
        carToken.transfer(owner, setAmount * 1 ether);
        return true;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].userId != 0);
    }


}