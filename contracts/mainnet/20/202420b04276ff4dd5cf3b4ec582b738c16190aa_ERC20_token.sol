pragma solidity ^0.4.19;      // 指定Compiler版本

contract ERC20_token {   // 使用 is 繼承 ERC20_interface
    uint256 public totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value, string _text); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint256 constant private MAX_UINT256 = 2**256 - 1; // 避免超過uint256最大可能的值，產生overflow
    mapping (address => uint256) public balances;   // 之後可使用 balances[地址] 查詢特定地址的餘額
    mapping (address => mapping (address => uint256)) public allowed;  // 可用 allowed[地址][地址]，查詢特定地址可以給另一個地址的轉帳配額

    string public name;             // 幫合約取名稱
    uint8  public decimals = 18;    // 小數點，官方建議為18
    string public symbol;           // e.g. ^_^
    address owner;
    uint256 public buyPrice;   // 一單位Ether可以換多少token
    uint private weiToEther = 10 ** 18; // 把單位從wei轉為Ether

    // 建構子，一開始即會執行，需要提供總量、價格、名稱、標誌
    constructor (
        uint256 _initialSupply,
        uint256 _buyPrice,
        string _tokenName,
        string _tokenSymbol
    ) public {
        totalSupply = _initialSupply * 10 ** uint256(decimals); // token總量
        balances[msg.sender] = totalSupply;                    // 將所有Token先全部分配給合約部屬者      

        name = _tokenName;                                   // token名稱
        symbol = _tokenSymbol;                               // token 標誌
        owner = msg.sender;                                  // 合約擁有人
        buyPrice = _buyPrice;                                // 每單位 ether 之價格
    }
    
    // 限定只有合約部屬人才能執行特定function
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // 查詢餘額
    function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
    }

    // 從合約擁有人地址轉帳
    function transfer(address _to, uint256 _value, string _text) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value, _text);
        return true;
    }

    // 從某一人地址轉給另一人地址，需要其轉帳配額有被同意，可想像為小明(msg.sender)用爸爸的副卡(_from)轉帳給別人(_to)
    function transferFrom(address _from, address _to, uint256 _value, string _text) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value, _text);
        return true;
    }

    // 給予特定帳號轉帳配額  類似小明的爸爸(msg.sender)給小明(_spender)一張信用卡副卡，額度為value
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 查詢特定帳號轉給另一帳號之轉帳配額
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   

    // 設定token購買價格，只有合約部屬者可以設定
    function setPrice(uint _price) public onlyOwner {
        buyPrice = _price;
    }

    // 購買token
    function buy() public payable {
        uint amount;
        amount = msg.value * buyPrice * 10 ** uint256(decimals) / weiToEther;    // 購買多少token
        require(balances[owner] >= amount);              // 檢查還有沒有足夠token可以賣
        balances[msg.sender] += amount;                  // 增加購買者token   
        balances[owner] -= amount;                        // 減少擁有者token
        emit Transfer(msg.sender, owner, amount, &#39;Buy token&#39;);               // 產生token轉帳log
    }

    // 從合約轉出Ether到部屬者帳戶
    function withdraw(uint amount) public onlyOwner {
        owner.transfer(amount * weiToEther);
    }
}