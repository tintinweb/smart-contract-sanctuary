/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity 0.4.24;

contract IFMTokenContract {
    
	//狀態變數
    string public constant name = "IFM Token";					//代幣全名，宣告為public，編譯器會自動產生getter函數，也就是function name() constant returns(string)
    string public constant symbol = "IFT";						//代幣縮寫，宣告為public，編譯器會自動產生getter函數，也就是function symbol() constant returns(string)
	uint8 public constant decimals = 0;							//代幣的最小單位，表示代幣最多到小數點後幾位，宣告為public，編譯器會自動產生getter函數，也就是function decimals() constant returns(uint8)
    uint256 public totalSupply = 100000000;						//代幣的總量，設定為1億個
    address public owner;										//合約建立者帳號   
    mapping( address => uint256) balances;						//餘額表：每個帳號目前持有的IFT代幣數量
    mapping( address => mapping( address => uint256)) allowed;	//授權表：授權轉出帳號，記錄授權轉出帳號及允許轉出的IFT代幣數量	
    
    event Transfer( address indexed _form, address indexed _to, uint256 _value);			//轉出事件
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);		//授權事件
    
	//函數修飾子
	//合約建立者檢查
    modifier onlyOwner() {
        if( msg.sender != owner) {	//若執行合約帳號不是合約建立者帳號，則放棄執行，還原狀態
            revert();
        }
        _;
    }
    
	//建構式
    constructor() public{
        owner = msg.sender;		//記錄合約建立者帳號
    }
    
	//fallback函數，搭配payable可實作傳輸乙太幣智能合約的功能，支付1個ETH來購買10000個IFT		
    function () public payable{
        if(totalSupply > 0 						//合約必須還有剩餘的IFT代幣
			&& balances[msg.sender] == 0	 	//購買人必須沒有買過
			&& msg.value == 1 ether) {		    //購買人必須支付1個ETH來購買10000個IFT			
            totalSupply -= 10000;				//代幣總量-10000
            balances[msg.sender] = 100000;		//購買人的帳號的IFT代幣設定為100000
        } else {
            revert();						//錯誤處理函數，放棄執行，還原狀態
        }
    }
    
	//查詢指定帳號的IFT代幣餘額，_owner：指定的帳號
    function balanceOf( address _owner) public view returns ( uint256) {	//view，函數不會變更狀態
        return balances[_owner];	//傳回balances mapping，address映射的uint256，也就address對應的IFT代幣餘額
    }

	//執行合約的帳號自行將IFT代幣轉出到指定的帳號，_to：指定轉入的帳號，_amount：指定轉出的IFT代幣數量，回傳布林值（true成功/false失敗）
    function transfer( address _to, uint _amount) public returns( bool) {
        if( _amount > 0  								//指定轉出的IFT代幣數量必須大於0
			&& balances[msg.sender] >= _amount  			//執行合約帳號的IFT代幣餘額必須足夠
			&& balances[_to] + _amount > balances[_to]) {	//轉入帳號的IFT代幣餘額必須增加
            balances[msg.sender] -= _amount;			//執行合約的帳號（也就是轉出的帳號）IFT餘額扣除_amount
            balances[_to] += _amount;					//轉入帳號IFT餘額增加_amount
            emit Transfer( msg.sender, _to, _amount);	//發出轉出事件
            return true;								//回傳成功
        } else {
            return false;								//回傳失敗
        }
    }
    
	//執行代理的帳號將IFT代幣轉出到指定的帳號，_form：指定轉出的帳號，_to：指定轉入的帳號，_amount：指定轉入的IFT代幣數量，回傳布林值（true成功/false失敗）
    function transferFrom( address _from, address _to, uint256 _amount) public returns( bool) {
        if( _amount > 0  								//指定轉出的IFT代幣數量必須大於0
			&& balances[_from] >= _amount 				//轉出帳號的IFT代幣餘額必須足夠
			&& allowed[_from][msg.sender] >= _amount  	//授權轉出帳號的授權數量足夠			
			&& balances[_to] + _amount > balances[_to]) { 	//轉入帳號的IFT代幣餘額必須增加
            balances[_from] -= _amount;					//轉出帳號IFT代幣餘額扣除_amount
            allowed[_from][msg.sender] -= _amount;		//授權轉出帳號的授權數量扣除_amount
            balances[_to] += _amount;					//轉入帳號IFT餘額增加_amount
            emit Transfer( _from, _to, _amount);		//發出轉出事件
            return true;								//回傳成功
        } else {
            return false;								//回傳失敗
        }
    }
    
	//執行合約的帳號指定授權帳號及可轉出的金額，_spender：設定授權轉出的帳號，_amount：設定授權轉出的IFT代幣數量
    function approve( address _spender, uint256 _amount) public returns(bool) {
        allowed[msg.sender][_spender] = _amount;			//指定數量之轉出帳號授權
        emit Approval( msg.sender, _spender, _amount);		//發出授權事件，
        return true;
    }
    
	//查詢授權額度
    function allowance( address _owner, address _spender) public view returns( uint256) {
        return allowed[_owner][_spender];
    }
    
	//查詢智能合約的ETH餘額
    function contractETH() public view returns(uint256){
        return address(this).balance;
    }
    
	//ico結束，將智能合約的ETH轉到合約建立者帳號
    function icoEnding() public onlyOwner{
        owner.transfer(address(this).balance);
    }
}