pragma solidity ^0.4.20;

contract OptionToken {

    address public owner;
// 以下是基于ERC20生成代币逻辑
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Burn(address indexed from, uint value);
    
    constructor (
        uint initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 tokenDecimals
    ) public {
        totalSupply = initialSupply * 10 ** uint(tokenDecimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
        decimals = tokenDecimals;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(add(balanceOf[_to],_value) >= balanceOf[_to]);
        uint previousBalances = add(balanceOf[_from],balanceOf[_to]);
        balanceOf[_from] = sub(balanceOf[_from],_value);
        balanceOf[_to] = add(balanceOf[_to],_value);
        emit Transfer(_from, _to, _value);
        assert(add(balanceOf[_from],balanceOf[_to]) == previousBalances);
        return true;
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender],_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function burn(uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = sub(balanceOf[msg.sender],_value);
        totalSupply = sub(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = sub(balanceOf[_from],_value);
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender],_value);
        totalSupply = sub(totalSupply,_value);
        emit Burn(_from, _value);
        return true;
    }

// 以上是基于ERC20生成代币逻辑


// 以下是公共判断及基本方法
    // 判断是否为owner地址
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // 更改owner地址
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0))
            owner = newOwner;
    }
    // 摧毁该智能合约
    function selfdestruct() external onlyOwner {
        selfdestruct(owner);
    }

    bool public status = true;// 判断该合约状态

    modifier checkStatus() {
        require(status == true);
        _;
    }

    function unlockContract() external onlyOwner {
        require(!status);
        status = true;
    }

    function lockContract() external onlyOwner {
        require(status);
        status = false;
    }

    mapping (address => uint) whitelist;// 白名单列表

    function addWhiteList (address _user, uint _amount) public onlyOwner checkStatus {
        whitelist[_user] = _amount;
    }

    function removeWhiteList (address _user) public onlyOwner checkStatus {
        delete whitelist[_user];
    }

    function isAllowTransfer(address _user) public view returns (bool) {
        return whitelist[_user] == 0 ? false : true;
    }

    function getAllowAmount(address _user) public view returns (uint) {
        return whitelist[_user];
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

// 以上是公共判断及基本方法

// 以下是授予公共模块

    event issueEvent(bytes32 issueKey);

    struct IssueStruct {
        // 授予数量
        uint issueAmount;
        // 授予日期
        uint32 issueDate;
        // 成熟起算日
        uint32 vestingStartDate;
    }
    
    mapping (address => mapping (bytes32 => IssueStruct)) public issueList;


    // 授予
    function issue ( 
        address _issueAddress, uint _issueAmount,
        uint32 _issueDate,uint32 _vestingStartDate 
    ) 
        external 
        checkStatus 
        onlyOwner 
        returns (bool)
    {
        require(_issueAddress != 0x0);
        require(_issueDate != 0);
        require(_vestingStartDate != 0);
        
        uint nowTime = block.timestamp;
        bytes32 issueKey = sha256(_issueAddress, _issueAmount, _issueDate, _vestingStartDate, nowTime);
        // 授予
        issueList[_issueAddress][issueKey] = IssueStruct({
            issueAmount: _issueAmount,
            issueDate: _issueDate,
            vestingStartDate: _vestingStartDate
        });

        emit issueEvent(issueKey);
        return true;
    }

    // 根据address、key 查看授予详情
    function showIssueDetail ( address _issueAddress, bytes32 _issueKey ) 
        public 
        view 
        returns ( uint, uint32, uint32 ) 
    {
        require(hasIssue(_issueAddress, _issueKey));
        IssueStruct storage issueDetail = issueList[_issueAddress][_issueKey];
        return ( 
            issueDetail.issueAmount, issueDetail.issueDate, 
            issueDetail.vestingStartDate
        );
    }

    // 通过address 和 key 判断是否有该授予纪录
    function hasIssue ( address _issueAddress, bytes32 _issueKey )
        internal 
        view 
        returns (bool)
    {
        if (issueList[_issueAddress][_issueKey].issueAmount != 0) {
            return true;
        } else {
            return false;
        }
    }

// 以上是授予模块

// 以下是成熟列表展示模块
    function reveiveToken ( address _issueAddress, uint amount ) 
        external
        onlyOwner
        checkStatus
    {
        _transfer(owner, _issueAddress, amount);
    }
// 以上是成熟列表展示模块
}