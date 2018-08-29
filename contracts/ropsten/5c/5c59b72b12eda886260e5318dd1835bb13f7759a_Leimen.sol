pragma solidity ^0.4.24;

//設定管理者//

contract owned {
    address public owner;
    address public owner2;

    function owned() {
        owner = msg.sender;
    }
    function change_owned(address new_owner2) onlyOwner {
        owner2 =  new_owner2;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == owner2);
        _;
    }
}    

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
    function tokenFallback(address _sender, uint256 _value, bytes _extraData) returns (bool);
}

contract Leimen is owned{
    
//設定初始值//

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals = 2;
    uint256 public totalSupply;
    
//初始化//

    function Leimen() public {
	    totalSupply = 1000000000 * 100 ;
    	balanceOf[msg.sender] = totalSupply ;
        name = "Leimen coin";
        symbol = "XLEM";         
    }
    
//管理權限//

    mapping (address => bool) public frozenAccount;
    uint256 public eth_amount ;
    bool public stoptransfer ;
    bool public stopsell ;
    

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function set_prices(uint256 _eth_amount) onlyOwner {
        eth_amount  = _eth_amount  ;
    }

    function withdraw_Leim(uint256 amount)  onlyOwner {
        require(balanceOf[this] >= amount) ;
        balanceOf[this] -= amount ;
        balanceOf[msg.sender] += amount ;
    }
    
    function withdraw_Eth(uint amount_wei) onlyOwner {
        msg.sender.transfer(amount_wei) ;
    }
    
    function set_Name(string _name) onlyOwner {
        name = _name;
    }
    
    function set_symbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }
    
    function set_stopsell(bool _stopsell) onlyOwner {
        stopsell = _stopsell;
    }
    
    function set_stoptransfer(bool _stoptransfer) onlyOwner {
        stoptransfer = _stoptransfer;
    }
    
    function burn(uint256 _value) onlyOwner {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
    }    

//交易//

    function _transfer(address _from, address _to, uint _value) 
        internal returns(bool success){
	    require(!frozenAccount[_from]);
	    require(!stoptransfer);
        require(_to != 0x0);
        
        require(_value >= 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        if(compare(_to) == true){
            transferAndCall(_to, _value , "");
        }
        else{
            require(_transfer(msg.sender, _to, _value));
        }
        return true;
	}

// 服務合約

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        require(_transfer(_from, _to, _value));
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
    function transferAndCall(address _recipient, uint256 _value, bytes _extraData) {
        require(_transfer(msg.sender, _recipient, _value));
        require(tokenRecipient(_recipient).tokenFallback(msg.sender, _value, _extraData));
    }

    address[]  public contract_address;
    
    function add_address(address _address){
        contract_address.push(_address);
    }

    function change_address(uint256 _index, address _address){
        contract_address[_index] = _address;
    }

    function compare(address _address) view public returns(bool){
        uint i = 0;
        for (i;i<contract_address.length;i++){
            if (contract_address[i] == _address){
                return true;
            }
        }
    }

//幣販售

    function () payable {
        buy();
    }

    function buy() payable returns (uint amount){
	    require(!stopsell);
        amount = msg.value * eth_amount  / (10**16) ;
        assert(amount*(10**16)/eth_amount == msg.value);
        require(balanceOf[this] >= amount);           
        balanceOf[msg.sender] += amount;           
        balanceOf[this] -= amount; 
        Transfer(this, msg.sender, amount);         
        return amount;    
    }
}