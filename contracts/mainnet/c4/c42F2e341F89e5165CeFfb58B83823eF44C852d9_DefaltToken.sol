pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/* Some of ERC20 methods is implemented as public states. */
contract ERC20Interface {
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DefaltToken is ERC20Interface {

    /* States */
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address beneficiary = 0x5404764f19b5163ef5450707cc2615bb5b522c36;
    bool isSale;    
    address creator;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Sale(address indexed from, uint256 value);
    event Burn(address indexed from, uint256 value);
        
    /* Modifiers */
    modifier onlyCreator{
        require( msg.sender == creator, "Unauthorized.");
        _;
    }


    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;                               
        creator = msg.sender;
        isSale = true;
    }

    function saleis(bool _salestate) public onlyCreator{
        isSale = _salestate;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


    function transfer(address _to, uint256 _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
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
        emit Approval(msg.sender, _spender, _value);
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


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }
    
    function sell(uint _amount, address _recipient) public onlyCreator returns(bool){
        require(isSale);
        _transfer(msg.sender,_recipient,_amount);
        return true;
    }
    
    function buy() public payable {
        beneficiary.transfer(msg.value);
        emit Sale(msg.sender,msg.value);
    }
    
    //Deprecated
    function() public payable {
        beneficiary.transfer(msg.value);
        emit Sale(msg.sender,msg.value);
    }
    
}