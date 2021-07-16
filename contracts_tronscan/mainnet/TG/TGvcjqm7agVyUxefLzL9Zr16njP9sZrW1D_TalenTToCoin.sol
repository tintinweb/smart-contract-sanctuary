//SourceUnit: contract TTC_2V.sol

/*
    TalenTToCoin - TTC
    Version: 1
    last contract version 0: none
    
    A new economic and financial era!
    A free cryptocurrency without any kind of limits!
    www.talenttocoin.com - www.talenttocointtc.com
    August 20th, 2020 - 11:11:11 - born to be free!
*/

pragma solidity ^0.5.10;

interface TTC_SubTokens {
    function mineTTC(address _from) external;
    function exchange(address _from, string calldata _symbolSubTokenOrigen, uint256 _amount, string calldata _symbolSubTokenDestino) external returns(bool success);
    function buyTTC(address _from, uint256 _value) external payable returns (bool success);
}

interface TTC_OldTTC {
    function userMigrationSystem(address _from, uint16 _idSubToken) external returns(uint256);
    function ownerMigrationReturnBalance(uint16 _idSubToken) view external returns(uint256);
    function getSubTokenTTC(string calldata _symbolSubToken, uint16 _idSubToken) external view returns (
        uint64 _dateTime, uint16 _id, string memory _symbol, string memory _alias, string memory _name, 
        uint8 _status, uint256 _usdValue, uint256 _usdValueSell, uint256 _totalCirculante);
}

contract ERC20Interface {
    uint8 systemON;
    uint16 public version = 1;
    string public name;
    string public symbol;
    uint8 public decimals;


    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
        /**
        Allows _spender to withdraw from your account multiple times, up to the _value amount. 
        If this function is called again it overwrites the current allowance with _value.
        */
    function approve(address _spender, uint256 _value) public returns (bool success);
        /**
        Returns the amount which _spender is still allowed to withdraw from _owner.
        */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);


    event Transfer(address indexed _from, address indexed _to, string _symbolSubToken, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, string _symbolSubToken, uint256 _value);
    event PayTo(address _from, address _to, string _symbolSubToken, uint _value, string _concept);

    uint256 public totalInitialSupply;
    uint256 public totalCirculante;

    uint16 public idControl;
    uint8 idControlCtr;
    uint256 oneTTC = 1000000000000000000; 
    address address0 = address(0);

    
	struct SubTokenTTC {
	    uint64 dateTime;
	    uint16 id; 
	    string symbol; 
	    string aliaS; 
	    string name; 
	    uint8 status; 
	    uint256 usdValue; 
	    uint256 usdValueSell; 
	    uint256 totalCirculante; 
	}
	mapping(uint16 => SubTokenTTC) public subTokenTTC; 
	mapping(string => uint16) public subTokenSymbol; 

	mapping(address => mapping(uint16 => uint256)) public userSubTokens; 
	mapping(address => mapping (address => uint256)) public userSubTokensAllowed;

    uint32 public msgNumber;
    struct Msg {
        uint64 dateTime;
        string title;
        string msg;
    }
    mapping(uint32 => Msg) messagges;

    string msg_nys = "No yet support!";
    string msg_sne = "subToken no exist!";
    string msg_sae = "subToken exist!";
    string msg_snr = "subToken no ready!";
    string msg_ns = "No system!";
    
    
    modifier SystemON {
        require(systemON == 1, msg_ns);
        _;
    }
}




contract Owned {
    address owner;
    address addressThisContract;
    string msg_an = "No allowed!";
    
    constructor () public {
        owner = msg.sender;
        addressThisContract = address(this);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, msg_an);
        _;
    }
}






//Function to receive approval and execute function in one call.
contract TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
    function TTC_receiveApproval(address _from, uint256 _value, address _token, string memory _symbolSubToken, bytes memory _extraData) public; 
}




//Token implement
contract Token is ERC20Interface, Owned {
    mapping (address => uint256) public _balances; //Balances del token TTC
    mapping (address => mapping (address => uint256)) public _allowed;

    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    function TTC_balanceOf(address _address, string memory _symbolSubToken) public view returns(uint256) {
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken !=0 , msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        if(_idSubToken == 0) { //TTC
            return _balances[_address];
        } else {
            return userSubTokens[_address][_idSubToken];
        }
    }
    
    function transfer(address _to, uint256 _value) public SystemON returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function TTC_transfer(address _from, address _to, string memory _symbolSubToken, uint256 _value) public SystemON returns (bool success) {
        if(!contractAllowed[msg.sender]) { 
	        require(_from == msg.sender,msg_an); 
	        _from = msg.sender;
	    }
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken != 0, msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        _TTC_transfer(_from, _to, _idSubToken, _value);
        return true;
    }
    
    
    function transferFrom(address _from, address _to, uint256 _value) public SystemON returns (bool success) {
        require(_value <= _allowed[_from][msg.sender]); 
        _allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function TTC_transferFrom(address _from, address _to, string memory _symbolSubToken, uint256 _value) public SystemON returns (bool success) {
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken != 0 , msg_sne);
        if(_idSubToken== 0xffff) _idSubToken = 0; //token TTC

        if(_idSubToken==0) { //TTC
            require(subTokenTTC[_idSubToken].status == 1, msg_snr);
            require(_value <= _allowed[_from][msg.sender]); 
            _allowed[_from][msg.sender] -= _value;
            _transfer(_from, _to, _value);
        } else {
            require(_value <= userSubTokensAllowed[_from][msg.sender]); 
            userSubTokensAllowed[_from][msg.sender] -= _value;
            _TTC_transfer(_from, _to, _idSubToken, _value);
        }
        return true;
    }
    
    
    function approve(address _spender, uint256 _value) public SystemON returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, "TTC:TTC", _value);
        return true;
    }
    function TTC_approve(address _spender, string memory _symbolSubToken, uint256 _value) public  SystemON returns (bool success) {
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken != 0, msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
        
        if(_idSubToken == 0) { //TTC
            _allowed[msg.sender][_spender] = _value;
        } else {
            userSubTokensAllowed[msg.sender][_spender] = _value;
        }
        emit Approval(msg.sender, _spender, subTokenTTC[_idSubToken].symbol, _value);
        return true;
    }
    
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }
    function TTC_allowance(address _owner, address _spender, string memory _symbolSubToken) public view returns (uint256 remaining) {
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken !=0 , msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
        
        if(_idSubToken == 0) { //TTC
            return _allowed[_owner][_spender];
        } else {
            return userSubTokensAllowed[_owner][_spender];
        }
    }

    /**
    Approves and then calls the receiving contract
    */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public SystemON returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        approve(_spender, _value);
        spender.receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }
    function TTC_approveAndCall(address _spender, uint256 _value, string memory _symbolSubToken, bytes memory _extraData) public SystemON returns (bool success) {
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken != 0, msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
        
        if(_idSubToken == 0) { //TTC
            TokenRecipient spender = TokenRecipient(_spender);
            approve(_spender, _value);
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
        } else {
            TokenRecipient spender = TokenRecipient(_spender);
            TTC_approve(_spender, _symbolSubToken, _value);
            spender.TTC_receiveApproval(msg.sender, _value, address(this), _symbolSubToken, _extraData);
        }
        return true;
    }


    //Internal transfer, only can be called by this contract
    function _transfer(address _from, address _to, uint _value) internal {
        require(subTokenTTC[0].status == 1, msg_snr);
        require(_to != address0);
        require(_balances[_from] >= _value);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, "TTC:TTC" ,_value);
    }
    function _TTC_transfer(address _from, address _to, uint16 _idSubToken, uint _value) internal {
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
        require(_to != address0);
        if(_idSubToken == 0) { //TTC
            require(_balances[_from] >= _value);
            _balances[_from] -= _value;
            _balances[_to] += _value;
        } else {
            require(userSubTokens[_from][_idSubToken] >= _value);
            userSubTokens[_from][_idSubToken] -= _value;
            userSubTokens[_to][_idSubToken] += _value;
        }
        emit Transfer(_from, _to, subTokenTTC[_idSubToken].symbol ,_value);
    }
    
    function _TTC_payTo(address _from, address _to, uint16 _idSubToken, uint _value, string memory _concept) public SystemON returns(bool success){
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
        if(!contractAllowed[msg.sender]) {
	        require(_from == msg.sender,"No allowed!");
	        _from = msg.sender;
	    }
        require(_to != address0);
        if(_idSubToken == 0) { //TTC
            require(_balances[_from] >= _value);
            _balances[_from] -= _value;
            _balances[_to] += _value;
        } else {
            require(userSubTokens[_from][_idSubToken] >= _value);
            userSubTokens[_from][_idSubToken] -= _value;
            userSubTokens[_to][_idSubToken] += _value;
        }
        emit PayTo(_from, _to, subTokenTTC[_idSubToken].symbol, _value, _concept);
        return true;
    }

    //interfaces 
    TTC_SubTokens               TTC_subTokens;
    TTC_OldTTC                  TTC_oldTTC;
    address aTTC_SubTokens;
    address aTTC_OldTTC;
    mapping(address => bool) contractAllowed;
    
    function getSubTokenTTC(string memory _symbolSubToken, uint16 _idSubToken) public view returns (
            uint64 _dateTime, uint16 _iid, string memory _symbol, string memory _alias, string memory _name, 
            uint8 _status, uint256 _usdValue, uint256 _usdValueSell, uint256 _totalCirculante) {
        uint16 _id = _idSubToken;
        if(_idSubToken == 0 ) {
            _id = subTokenSymbol[_symbolSubToken];
        }
        require(_id != 0, msg_sne);
        if(_id == 0xffff) _id = 0; //token TTC
        _dateTime = subTokenTTC[_id].dateTime;
        _iid = subTokenTTC[_id].id;
        _symbol =  string(subTokenTTC[_id].symbol);
        _alias = string(subTokenTTC[_id].aliaS);
        _name = subTokenTTC[_id].name;
        _status = subTokenTTC[_id].status;
        _usdValue = subTokenTTC[_id].usdValue;
        _usdValueSell = subTokenTTC[_id].usdValueSell;
        if(_id == 0) {
            _totalCirculante = totalCirculante;
        } else {
            _totalCirculante = subTokenTTC[_id].totalCirculante;
        }
    }


	function mineTTC() public SystemON returns(bool success){
        require(contractAllowed[aTTC_SubTokens],msg_nys);
        require(subTokenTTC[0].status == 1, msg_snr);
        TTC_subTokens.mineTTC(msg.sender);
        return true;
	}
	function exchange(string memory _symbolSubTokenOrigen, uint256 _amount, string memory _symbolSubTokenDestino) public SystemON returns(bool success) {
	    require(contractAllowed[aTTC_SubTokens],msg_nys);
	    uint16 _idSubToken = subTokenSymbol[_symbolSubTokenOrigen];
	    require(_idSubToken != 0, msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
        _idSubToken = subTokenSymbol[_symbolSubTokenDestino];
        require(_idSubToken != 0, msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        require(subTokenTTC[_idSubToken].status == 1, msg_snr);
	    return(TTC_subTokens.exchange(msg.sender, _symbolSubTokenOrigen, _amount, _symbolSubTokenDestino));
	}
	function buyTTC() payable public SystemON returns(bool success) {
	    //require(aTTC_SubTokens != address0,msg_nys);
	    require(contractAllowed[aTTC_SubTokens],msg_nys);
	    require(subTokenTTC[0].status == 1, msg_snr);
	    return(TTC_subTokens.buyTTC(msg.sender, msg.value));
	}
	function getSellTTC_TRXfounds() public onlyOwner returns(bool success) { //retirar fondos del contrato, en moneda principal TRX TRoniX a mi cuenta
	    msg.sender.transfer(addressThisContract.balance);
	    return true;
	}
	
	
	function add_totalCirculante(uint16 _idSubToken, uint256 _amount, uint8 _mode) public SystemON returns(bool success) {
	    require(contractAllowed[msg.sender],msg_an);
	    require(subTokenTTC[_idSubToken].status == 1, msg_snr);
	    if(_idSubToken == 0) { //Token TTC
	        if(_mode == 1) {
    	        totalCirculante += _amount;
    	    } else {
    	        if(_amount >= totalCirculante) {
    	            totalCirculante = 0;
    	        } else {
    	            totalCirculante -= _amount;
    	        }
    	    }
	    } else {
	        if(_mode == 1) {
    	        subTokenTTC[_idSubToken].totalCirculante += _amount;
    	    } else {
    	        if(_amount >= subTokenTTC[_idSubToken].totalCirculante) {
    	            subTokenTTC[_idSubToken].totalCirculante = 0;
    	        } else {
    	            subTokenTTC[_idSubToken].totalCirculante -= _amount;
    	        }
    	    }
	    }
	    return true;
	}
	function afectBalances(address _to, uint16 _idSubToken, uint256 _amount, uint8 _modo) public SystemON returns(bool success) {
	    require(contractAllowed[msg.sender],msg_an);
	    require(subTokenTTC[_idSubToken].status == 1, msg_snr);
	    if(_idSubToken == 0) { //Token TTC
	        if(_modo == 1) { //suma
	            _balances[_to] += _amount;
	        } else {
	            _balances[_to] -= _amount;
	        }
	    } else { //subtoken
	        if(_modo == 1) {
	            userSubTokens[_to][_idSubToken] += _amount;
	        } else {
	            userSubTokens[_to][_idSubToken] -= _amount;
	        }
	    }
	    return true;
	}
	function getSubTokenTTC_usdValue(uint16 _idSubToken) public view returns (uint256) {
        return(subTokenTTC[_idSubToken].usdValue); //to buy
    }
    function getSubTokenTTC_usdValueShell(uint16 _idSubToken) public view returns (uint256) {
        return(subTokenTTC[_idSubToken].usdValueSell); //to sell
    }
    


	function writeMessagge(string memory _title, string memory _msg) public onlyOwner {
	    msgNumber++;
	    messagges[msgNumber].dateTime = uint64(now);
	    messagges[msgNumber].title = _title;
	    messagges[msgNumber].msg = _msg;
	}
	function getMessagge(uint32 _msgNumber) public view returns (uint64 _dateTime, string memory _title, string memory _msg) {
	    //if(_msgNumber==0) _msgNumber = msgNumber;
	    _dateTime = messagges[_msgNumber].dateTime;
	    _title = messagges[_msgNumber].title;
	    _msg = messagges[_msgNumber].msg;
	}
	function getActualMessagge() public view returns (uint32 _msgNumer, uint64 _dateTime, string memory _title, string memory _msg) {
	    _msgNumer = msgNumber;
	    _dateTime = messagges[msgNumber].dateTime;
	    _title = messagges[msgNumber].title;
	    _msg = messagges[msgNumber].msg;
	}


	
	// =========================================================================
	//FUNCTIONS OWNER!
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    function setSystemON(uint8 _state) public onlyOwner returns(bool success) {
        systemON = _state;
        return true;
    }

	function addSubTokenTTC(string memory _symbol, string memory _name, uint256 _usdValue, string memory _alias) public onlyOwner returns(bool success) {
        require(subTokenSymbol[_symbol] == 0,msg_sae);
        require(subTokenSymbol[_alias] == 0,msg_sae);
        
	    idControl++;
	    subTokenTTC[idControl].dateTime = uint64(now);
	    subTokenTTC[idControl].id = idControl;
        subTokenTTC[idControl].symbol = _symbol;
        subTokenTTC[idControl].aliaS = _alias;
        subTokenTTC[idControl].name = _name;
        subTokenTTC[idControl].status = 1; // 1
        subTokenTTC[idControl].usdValue = _usdValue;
        subTokenTTC[idControl].usdValueSell = _usdValue;
        subTokenTTC[idControl].totalCirculante = 0;
        
        subTokenSymbol[_symbol] = idControl;
        subTokenSymbol[_alias] = idControl;
        return true;
	}
	function changeUSDvalue(uint16 _idSubToken, uint256 _newUSDvalue, uint256 _newUSDvalueSell) public SystemON {
	    //for trade
	    require(contractAllowed[msg.sender],msg_an);
	    subTokenTTC[_idSubToken].usdValue = _newUSDvalue;
	    subTokenTTC[_idSubToken].usdValueSell = _newUSDvalueSell;
	}
	function changeUSDvalueLocal(uint16 _idSubToken, uint256 _newUSDvalue, uint256 _newUSDvalueSell, uint8 _status) public onlyOwner {
	    subTokenTTC[_idSubToken].usdValue = _newUSDvalue;
	    subTokenTTC[_idSubToken].usdValueSell = _newUSDvalueSell;
	    subTokenTTC[_idSubToken].status = _status;
	}
	

	function contract_SubTokens(address _addressContract) public onlyOwner returns(bool success){
        TTC_subTokens = TTC_SubTokens(_addressContract);
        aTTC_SubTokens = _addressContract; 
        contractAllowed[_addressContract] = true;
        return true;
    }
    function contract_OldTTC(address _addressContract) public onlyOwner returns(bool success){
        TTC_oldTTC = TTC_OldTTC(_addressContract);
        aTTC_OldTTC = _addressContract; 
        contractAllowed[_addressContract] = true;
        return true;
    }
    function setContracAllowed(address _addressContract, bool _active) public onlyOwner {
        contractAllowed[_addressContract] = _active;
    }
    function userMigrationSystem(address _from, uint16 _idSubToken) public returns(uint256) {
        require(contractAllowed[msg.sender],msg_an);
        uint256 tmp;
        if(_idSubToken==0) {
            tmp = _balances[_from];
            _balances[_from] = 0;
        } else {
            tmp = userSubTokens[_from][_idSubToken];
            userSubTokens[_from][_idSubToken]=0;
        }
        return tmp;
    }
    function userMigration(string memory _symbolSubToken) public returns(uint256) {
        uint16 _idSubToken = subTokenSymbol[_symbolSubToken];
        require(_idSubToken !=0 , msg_sne);
        if(_idSubToken == 0xffff) _idSubToken = 0; //token TTC
        uint256 tmp = TTC_oldTTC.userMigrationSystem(msg.sender, _idSubToken);
        if(_idSubToken==0) {
            _balances[msg.sender] += tmp;
        } else {
            userSubTokens[msg.sender][_idSubToken]+=tmp;
        }
        return tmp;
    }
    function ownerMigration() public onlyOwner returns(bool success) {
        //stop or restart all transfer operations for several minutes
        uint16 tmp = 0;
        if(idControlCtr==1) { //stop
            while(tmp<idControl) {
                subTokenTTC[tmp].status++;
                tmp++;
            }
            idControlCtr=2;
        } else {
            while(tmp<idControl) { //restart
                subTokenTTC[tmp].status--;
                tmp++;
            }
            idControlCtr=1;
        }
        return true;
    }
    function ownerMigrationGetAllBalances() public onlyOwner returns(bool success) {
        uint16 _id = 0;
        SubTokenTTC storage subTokenTTCtmp = subTokenTTC[_id];
        while(_id<65535) {
            _id++;
            subTokenTTCtmp  = subTokenTTC[_id];
            (uint64 dateTime, 
                uint16 id, 
                string memory symbol, 
                string memory aliaS, 
                string memory name, 
                uint8 status, 
                uint256 usdValue, 
                uint256 usdValueSell,
                uint256 totalCirculante
            ) = TTC_oldTTC.getSubTokenTTC('',_id);
            if(id==0) break;

            subTokenTTCtmp.dateTime = dateTime;
            subTokenTTCtmp.id = id;
            subTokenTTCtmp.symbol = symbol;
            subTokenTTCtmp.aliaS = aliaS;
            subTokenTTCtmp.name = name;
            subTokenTTCtmp.status = status;
            subTokenTTCtmp.usdValue = usdValue;
            subTokenTTCtmp.usdValueSell = usdValueSell;
            subTokenTTCtmp.totalCirculante = totalCirculante;

            subTokenSymbol[subTokenTTCtmp.symbol] = _id;
            subTokenSymbol[subTokenTTCtmp.aliaS] =_id; //alias
        }
        return true;
    }

    function totalSupply() view public returns(uint256){
        return totalCirculante;
    }
  
}




contract CommonToken is Token {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply, uint256 _balanceOldTTC) public {
        systemON = 1;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalInitialSupply = _initialSupply * 10 ** uint256(decimals);
        _balances[msg.sender] = totalInitialSupply;
        totalCirculante = _balanceOldTTC;

        idControl = 0;
        idControlCtr = 1; //started
		
		subTokenTTC[idControl].dateTime = uint64(now);
		subTokenTTC[idControl].id = 0xffff; //id=65535
        subTokenTTC[idControl].symbol = "TTC:TTC";
        subTokenTTC[idControl].aliaS = "TTC";
        subTokenTTC[idControl].name = "TalenTToCoin";//"TalenToCoin";
        subTokenTTC[idControl].status = 1;
        subTokenTTC[idControl].usdValue = 10000000000000000000; // init: 1 TTC = 10 TTC:USD (id=1)
        subTokenTTC[idControl].usdValueSell = 10000000000000000000;
        
        subTokenSymbol["TTC:TTC"] = 0xffff;
        subTokenSymbol["TTC"] = 0xffff; //alias
        
    }


    function () external payable {
        revert();
    }

}


contract TalenTToCoin is CommonToken {
    constructor() CommonToken("TalenTToCoin", "TTC", 18, 33033033, 33033033000000000000000000) public {}
}