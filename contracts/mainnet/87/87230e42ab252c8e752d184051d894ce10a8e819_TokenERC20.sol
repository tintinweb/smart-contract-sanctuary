/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity ^0.4.24;


interface tokenRecipient{function receiveApproval (address _from, uint256 _value, address _token, bytes _extradata) external;}

contract owner {
    address public _owner;
    
    constructor() public {
        _owner = msg.sender;
    }
    
    modifier onlyOwer {
        require(msg.sender == _owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwer {
        _owner = newOwner;
    }
}


contract TokenERC20 is owner {
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address=>uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 _value);
    event FrozenFunds(address indexed target, bool frozen);
    
    
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
        ) public {
        
        totalSupply = initialSupply* (10**uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    /////////////////////////// TRANSFER //////////////////////////////////
    function _transfer(address _from,address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(_value >= 0);
        require(!frozenAccount[msg.sender]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        
        _transfer(msg.sender, _to, _value);
        return true;
    }
    /////////////////////////// TRANSFER END //////////////////////////////////
    
    
    
    /////////////////////////// ALLOWANCE //////////////////////////////////
    
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value<=allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    
    function approve (address _spender, uint256 _value) onlyOwer public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }
    
    
    function approveAndCall(address _spender, uint256 _value, bytes _extradata) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        
        if(approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extradata);
            return true;
        }
    }
    
    /////////////////////////// ALLOWANCE END //////////////////////////////////
    
    
    /////////////////////////// BURN //////////////////////////////////
    
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        
        return true;
    }
    
    function burnAccount0(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        balanceOf[account] -= amount;
        totalSupply -= amount;
        _transfer(account, address(0), amount);
    }
    /////////////////////////// BURN END//////////////////////////////////
    
    /////////////////////////// MINT TOKEN//////////////////////////////////
    function mintToken(address target, uint256 mintedAmount) public onlyOwer {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        
    }
    ////////////////////////// MINT TOKEN END //////////////////////////////////
    
    
    ////////////////////////// FREEZING ASSET ////////////////////////////////// 
    function freezeAccount (address target, bool freeze) public onlyOwer {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    ////////////////////////// FREEZING ASSET END////////////////////////////////// 
    
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
        // trả về số token đang có trong ví của owner
    }
    
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

}