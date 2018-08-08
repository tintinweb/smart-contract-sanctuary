pragma solidity ^0.4.24;

//設定管理者//

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}    

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract x32323 is owned{
    
//設定初始值//

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    string public name;
    string public symbol;
    uint8 public decimals = 2;
    uint256 public totalSupply;
    
//初始化//

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
	totalSupply = 1000000000 * 100 ;
    	balanceOf[msg.sender] = totalSupply ;
        name = "Leimen coin";
        symbol = "Lem";         
    }
    
//管理權限//

    uint256 minBalance ;
    uint256 price ;
    bool stopped ;
    bool selling;


    function set_prices(uint256 price_wei) onlyOwner {
        price = price_wei  ;
    }

    function withdrawal_Lem(uint256 amount)  onlyOwner {
        require(balanceOf[this] >= amount) ;
        balanceOf[this] -= amount ;
        balanceOf[msg.sender] += amount ;
    }
    
    function withdrawal_Eth(uint amount_wei) onlyOwner {
        msg.sender.transfer(amount_wei) ;
    }
    
    function set_Name(string _name) onlyOwner {
        name = _name;
    }
    
    function set_symbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }
    
    function set_sell(bool _selling) onlyOwner {
        selling = _selling;
    }
    
    function stop() onlyOwner {
        stopped = true;
    }

    function start() onlyOwner {
        stopped = false;
    }

//交易//

    function _transfer(address _from, address _to, uint _value) internal {
	    require(!frozenAccount[_from]);
	    require(!stopped);
        require(_to != 0x0);
        
        require(_value >= 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
	    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

//販售

    function () payable {
        buy();
    }

    function buy() payable returns (uint amount){
        require(price != 0);
	    require(selling);
        amount = msg.value / price * 100 ;
        require(balanceOf[this] > amount);           
        balanceOf[msg.sender] += amount;           
        balanceOf[this] -= amount; 
        Transfer(this, msg.sender, amount);         
        return amount;    
    }
}