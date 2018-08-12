pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public minter;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping(address => bool) public accessAllowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        uint8 tokendecimals,
        string tokenName,
        string tokenSymbol
    ) public {
        decimals = tokendecimals;
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;                                   
        symbol = tokenSymbol;
        minter = msg.sender;
        accessAllowed[msg.sender]=true;
    }
    
    modifier platform(){
        require(accessAllowed[msg.sender]==true);
        _;
    }
    
    function setBlance(address _address,uint256 v)platform public{
        //if(msg.sender == minter) {
        //if(accessAllowed[_address]){
        balanceOf[_address]=v;
        //}
        //}
    }
    
    function setSupply(uint256 v2)platform public{
        //if(msg.sender == minter) {
        totalSupply = v2;
        //}
    }
    
    function setDecimals(uint8 v4)platform public{
        //if(msg.sender == minter) {
        decimals = v4;
        //}
    } 
    
    function allowAccess(address _addr)platform public{
        if(msg.sender == minter) {
        accessAllowed[_addr] = true;
         }
    }
    
    function denyAccess(address _addr)platform public{
        if(msg.sender == minter) {
        accessAllowed[_addr] = false;
        }
    }
    
    function setAllowance(address _address , uint256 v3)public{
        allowance[msg.sender][_address]=v3;
    }
//1
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
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
//2
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
//3
}

contract control{
    
    event Burn(address indexed from, uint256 value);
    
    TokenERC20 tokenerc20;
    
    function control(address _tokenerc20Addr) public {
        tokenerc20 = TokenERC20(_tokenerc20Addr);
    }
    
    function _burn(address _burner,uint256 _value) internal {
        if(tokenerc20.accessAllowed(_burner)){
        uint val = tokenerc20.balanceOf(_burner);
//        uint valtotal = tokenerc20.Supply;
        require(val >= _value);
        val -= _value;
//        valtotal -= _value;
        tokenerc20.setBlance(_burner,val);
//        tokenerc20.setSupply(valtotal);
        Burn(_burner,_value);
        }
    }
    function burn(uint256 _value) public {
        _burn(msg.sender,_value);
    }
    
    
    
    
    
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        tokenerc20.setAllowance(_spender,_value);
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
    
    
    
    
}
    
    
    

/*
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
//4
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
//5
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
//6
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    */
    
    /*
    if(dateContract.accessAllowed(_from))
    */