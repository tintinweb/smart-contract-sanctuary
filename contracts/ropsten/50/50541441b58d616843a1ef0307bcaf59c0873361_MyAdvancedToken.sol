pragma solidity ^0.4.2;

contract owned{
    address public owner;
    function owned(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        if(msg.sender != owner) throw;
        _;
    }
    function transferOwnership (address newOwner) onlyOwner{
        owner = newOwner;
    }
}

contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, byte _extraData);}

// &quot;21000000&quot;,&quot;JSCoin&quot;,&quot;18&quot;,&quot;JSC&quot;
contract token{
    //虛擬幣 公共變數
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    //對所有帳戶建立一個數組
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address=> uint256)) public allowance;

    //在區塊鏈上產生一個公共事件提示用戶
    event Transfer (address indexed from, address indexed to,uint256 value);

    //為合約建立者設定&quot;虛擬幣&quot;初始值
    function token (uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol ){
        //為合約建立者設定&quot;虛擬幣&quot;初始值
        balanceOf[msg.sender]=initialSupply;

        //更新&quot;虛擬幣&quot;總量
        totalSupply=initialSupply;

        //為&quot;虛擬幣&quot;命名
        name = tokenName;

        //為&quot;虛擬幣&quot;設定符號
        symbol = tokenSymbol;

        //為&quot;虛擬幣&quot;設定小數位
        decimals = decimalUnits;
    }

    //發送&quot;虛擬幣&quot;
    function transfer(address _to, uint256 _value){
        // 檢查發送者的餘額是否足夠
        if(balanceOf[msg.sender]<_value) throw;

        //檢查益出
        if(balanceOf[_to] + _value < balanceOf[_to]) throw;

        //從發送者帳戶中減去發送金額
        balanceOf[msg.sender] -= _value;

        //把相對應的金額加到接收者帳戶
        balanceOf[_to]+= _value;

        //提示發送操作已發生
        Transfer (msg.sender,_to,_value);
    }

    //允許其他合約以你的名義發送&quot;虛擬幣&quot;
    function approve(address _spender, uint256 _value) returns (bool success){
        allowance[msg.sender][_spender]=_value;
        return true;
    }

    //批準，並在一個交易中與已批準的合約進行交互
    function approveAndCall(address _spender, uint256 _value, byte _extraData) returns (bool success){
        tokenRecipient spender = tokenRecipient(_spender);
        if(approve(_spender,_value)){
            spender.receiveApproval(msg.sender,_value,this,_extraData);
            return true;
        }
    }

    //一個試圖獲得&quot;虛擬幣&quot;的合約
    function transferFrom(address _from, address _to,uint256 _value) returns (bool success){
        // 檢查發送者的餘額是否足夠
        if(balanceOf[_from]<_value) throw;

        //檢查益出
        if(balanceOf[_to] + _value < balanceOf[_to]) throw;

        //檢查是否許可
        if(_value > allowance[_from][msg.sender]) throw;

        //從發送者帳戶中減去發送金額
        balanceOf[_from] -= _value;

        //把相對應的金額加到接收者帳戶
        balanceOf[_to]+= _value;

        //提示發送操作已發生
        Transfer (_from,_to,_value);
    }

    function(){
        // 防止被錯誤發送&quot;虛擬幣&quot;
        throw;
    }
}

contract MyAdvancedToken is owned,token {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;

    //產生一個提示用戶的共用事件
    event FrozenFunds(address target,bool frozen);

    //為合約建立者設定&quot;虛擬幣&quot;初始值
    function MyAdvancedToken(uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply,tokenName,decimalUnits,tokenSymbol){}

    //發送&quot;虛擬幣&quot;
    function transfer(address _to, uint256 _value){
        // 檢查發送者的餘額是否足夠
        if(balanceOf[msg.sender]<_value) throw;

        //檢查益出
        if(balanceOf[_to] + _value < balanceOf[_to]) throw;

        //檢查帳戶是否凍結
        if(frozenAccount[msg.sender]) throw;

        //從發送者帳戶中減去發送金額
        balanceOf[msg.sender] -= _value;

        //把相對應的金額加到接收者帳戶
        balanceOf[_to]+= _value;

        //提示發送操作已發生
        Transfer (msg.sender,_to,_value);
    }


    //一個試圖獲得&quot;虛擬幣&quot;的合約
    function transferFrom(address _from, address _to,uint256 _value) returns (bool success){
        //檢查帳戶是否凍結
        if(frozenAccount[_from]) throw;

        // 檢查發送者的餘額是否足夠
        if(balanceOf[_from]<_value) throw;

        //檢查益出
        if(balanceOf[_to] + _value < balanceOf[_to]) throw;

        //檢查是否許可
        if(_value > allowance[_from][msg.sender]) throw;

        //從發送者帳戶中減去發送金額
        balanceOf[_from] -= _value;

        //把相對應的金額加到接收者帳戶
        balanceOf[_to]+= _value;

        //提示發送操作已發生
        Transfer (_from,_to,_value);
    }

    function mintToken(address target,uint256 mintedAmount) onlyOwner{
        balanceOf[target]+=mintedAmount;
        totalSupply+=mintedAmount;
        Transfer(0,this,mintedAmount);
        Transfer(this,target,mintedAmount);
    }

    function frozenAccount(address target,bool freeze) onlyOwner{
        frozenAccount[target]=freeze;
        FrozenFunds(target,freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner{
        sellPrice=newSellPrice;
        buyPrice=newBuyPrice;
    }

    function buy() payable{
        // 計算數量
        uint amount = msg.value/buyPrice;

        //檢查是否有足夠餘額賣出
        if(balanceOf[this]<amount) throw;

        //在買方帳戶中加入所買的數額
        balanceOf[msg.sender] += amount;

        //在賣方帳戶扣掉所銷售的數額
        balanceOf[this]-=amount;

        //執行交易
        Transfer(this,msg.sender,amount);
    }

    function sell(uint256 amount) payable{
        //檢查是否有足夠餘額賣出
        if(balanceOf[msg.sender] < amount) throw;

        //在買方帳戶中加入所買的數額
        balanceOf[this] += amount;

        //在賣方帳戶扣掉所銷售的數額
        balanceOf[msg.sender]-=amount;

        //向賣方發送虛擬幣
        if(!msg.sender.send(amount * sellPrice)){
            throw;
        }else{
            Transfer(msg.sender,this,amount);
        }
    }
}