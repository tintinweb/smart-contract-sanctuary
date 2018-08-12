pragma solidity 0.4.12;

/**

 * ╔═════╗ ╦═╦ ╦═╦     ╔═╗    ╔═╗    ╦═══════╦ ╔═════╗ ╦═╦ ╔═╦ ╔══════╗ ╔══╗  ╦═╦
 * ║ ╔═══╩ ║ ║ ║ ║     ║ ╚╗  ╔╝ ║    ╚══╗ ╔══╝ ║ ╔═╗ ║ ║ ║╔╝ ║ ║ ╔════╝ ║  ╚╗ ║ ║
 * ║ ╚═╦   ║ ║ ║ ║     ║  ╚╗╔╝  ║       ║ ║    ║ ║ ║ ║ ║ ╚╝ ╔╝ ║ ╚═══╗  ║ ╔╗╚╗║ ║
 * ║ ╔═╝   ║ ║ ║ ║     ║   ╚╝   ║       ║ ║    ║ ║ ║ ║ ║ ╔╗ ╚╗ ║ ╔═══╝  ║ ║╚╗╚╝ ║
 * ║ ║     ║ ║ ║ ╚═══╣ ║ ╔╗  ╔╗ ║       ║ ║    ║ ╚═╝ ║ ║ ║╚╗ ║ ║ ╚════╗ ║ ║ ╚╗  ║
 * ╩═╩     ╩═╩ ╩═════╝ ╩═╝╚══╝╚═╩       ╩═╩    ╚═════╝ ╩═╩ ╚═╩ ╚══════╝ ╩═╩  ╚══╝
 * 
 * ╔═╗╦ ╦  ╔╦╗  ╔═╗ ╔═╗╔═╗╔═╗  ┌─┐┬─┐┌─┐┌─┐┌─┐┌┐┌┌┬┐┌─┐
 * ╠╣ ║ ║  ║║║  ╠═╩╗╠═╣╚═╗╠╣   ├─┘├┬┘├┤ └─┐├┤ │││ │ └─┐
 * ╩  ╩ ╚═╝╩ ╩  ╩══╝╩ ╩╚═╝╚═╝  ┴  ┴└─└─┘└─┘└─┘┘└┘ ┴ └─┘ 
 */
 
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    event Burn(address indexed from, uint256 value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
    }

    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (_value > allowance[_from][msg.sender]) throw;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function () {
        throw;
    }
}

contract FILMToken is owned, token {

    mapping (address => bool) public frozenAccount;
    bool frozen = false; 
    event FrozenFunds(address target, bool frozen);

    function FILMToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (frozenAccount[msg.sender]) throw;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;
        if (balanceOf[_from] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (_value > allowance[_from][msg.sender]) throw;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    function unfreezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = !freeze;
        FrozenFunds(target, !freeze);
    }
  function freezeTransfers () {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;
      Freeze ();
    }
  }

  function unfreezeTransfers () {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;
      Unfreeze ();
    }
  }


  event Freeze ();

  event Unfreeze ();

    function burn(uint256 _value) public returns (bool success) {        
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);        
        return true;
    }
    
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