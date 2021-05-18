/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.4.17;

contract TokenERC20 {
    string public name;  //發行Token名稱
    string public symbol; //發行Token符號
    uint8 public decimals = 1; //設定Token最多能達到小數點多少位數
    uint256 public totalSupply; //總發行量

   //錢包地址的餘額
    mapping (address => uint256) public balanceOf;  
    mapping (address => mapping (address => uint256)) public allowance;

    //觸發Token交易事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    //觸發Token消耗事件，Token用了就必須刪掉
    event Burn(address indexed from, uint256 value);
    
    //建構子
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals); //確定總發行量
        balanceOf[msg.sender] = totalSupply; //把Token全部指定給合約的建立者
        name = tokenName;
        symbol = tokenSymbol;
    }

    //Token發送：_from 給 _to共 _value 的Token發送
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); //錢包地址不能是0
        require(balanceOf[_from] >= _value); //餘額要足夠
        require(balanceOf[_to] + _value > balanceOf[_to]);//不能發送_value 小於0的負値
        uint previousBalances = balanceOf[_from] + balanceOf[_to];  //目前 _from 與 _to 的總金額，轉帳後應該要一致
        balanceOf[_from] -= _value;  //_from 減少 Token
        balanceOf[_to] += _value; //_to 增加 Token 
        Transfer(_from, _to, _value);  //轉帳，觸發Token交易事件
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); //判斷總金額是否還是一致
    }
	
    //這個函式只能被合約建立者呼叫
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;  //這是可花費的總量
        return true;
    }

    //用於把建立者的 Token 消耗掉
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    //用於把用戶的 Token 消耗掉
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);   
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}