pragma solidity ^0.4.16;
contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract FCTOKEN is Token {

    string public name;                   //名稱，例如"My test token"
    uint8 public decimals;               //返回token使用的小數點後幾位。比如如果設定為3，就是支援0.001表示.
    string public symbol;               //token簡稱,like MTT
  
  // string public constant name = "fc_token"; // 合约名称
  // string public constant symbol = "FCO"; // 代币名称
  // uint8 public constant decimals = 18; // 代币精确度

  // uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

    function FCTOKEN(){
        _FCTOKEN(10000 , "fc_tokenS" , 18 , "FCCS");
    }
    // 10000 , "fc_token" , 18 , "fcoin"
    // 貨幣數量10000 ，合約名稱 ， 貨幣精度18 ， 貨幣簡稱
    function _FCTOKEN(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {

        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);         // 設定初始總量
        balances[msg.sender] = totalSupply; // 初始token數量給予訊息傳送者，因為是建構函式，所以這裡也是合約的建立者

        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //預設totalSupply 不會超過最大值 (2^256 - 1).
        //如果隨著時間的推移將會有新的token生成，則可以用下面這句避免溢位的異常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;//從訊息傳送者賬戶中減去token數量_value
        balances[_to] += _value;//往接收賬戶增加token數量_value
        Transfer(msg.sender, _to, _value);//觸發轉幣交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收賬戶增加token數量_value
        balances[_from] -= _value; //支出賬戶_from減去token數量_value
        allowed[_from][msg.sender] -= _value;//訊息傳送者可以從賬戶_from中轉出的數量減少_value
        Transfer(_from, _to, _value);//觸發轉幣交易事件
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//允許_spender從_owner中轉出的token數
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}