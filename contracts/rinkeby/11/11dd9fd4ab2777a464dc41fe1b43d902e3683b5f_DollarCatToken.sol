/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.4.22;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
interface IERC20 {
    function balanceOf(address owner) external returns (uint256 balance);
    function transfer (address _to, uint256 _value) ;
}


contract DollarCatToken {
   string public name;
   string public symbol;
   uint8 public decimals = 18;
   uint256 public totalSupply;
   address public owner;

   mapping (address => uint256) public balanceOf;
   mapping (address => mapping (address => uint256)) public allowance;
   mapping (address => bool) public frozenAccount;
   mapping (address => uint256) public freezeOf;
   event FrozenFunds(address target, bool frozen);
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Burn(address indexed from, uint256 value);
   event Freeze(address indexed from, uint256 value);
   event Unfreeze(address indexed from, uint256 value);

   constructor(uint256 initialSupply,string tokenName,string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
   }

   function balanceOf(address _owner) payable public returns (uint256 balance) {
      return balanceOf[_owner];
   }

   function _transfer(address _from, address _to, uint _value) internal {
      require(_to != 0x0);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
   }

   function transfer (address _to, uint256 _value) public{
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

   function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
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

   function mintToken(address target, uint256 mintedAmount) public {
      require(msg.sender == owner);
      balanceOf[target] += mintedAmount;
      totalSupply += mintedAmount;
      _transfer(0, owner, mintedAmount);
      _transfer(owner, target, mintedAmount);
   }

   function freezeAccount(address target, bool freeze) public {
      require(msg.sender == owner);
      frozenAccount[target] = freeze;
      emit FrozenFunds(target, freeze);
   }

   function freezeOf(address _owner) payable public returns (uint256 balance) {
      return freezeOf[_owner];
   }

   function freeze(address target,uint256 _value) returns (bool success) {
      require(msg.sender == owner);
      require(_value > 0); 
      require(balanceOf[target] > _value); 
      balanceOf[target] = balanceOf[target] -  _value;
      freezeOf[target] = freezeOf[target] +  _value;                                // Updates totalSupply
      Freeze(target, _value);
      return true;
    }
	
	function unfreeze(address target,uint256 _value) returns (bool success) {
      require(msg.sender == owner);
      require(_value > 0); 
      require(freezeOf[target] > _value); 
      freezeOf[target] = freezeOf[target] -  _value;                  // Subtract from the sender
	  balanceOf[target] = balanceOf[target] +  _value;
      Unfreeze(target, _value);
      return true;
    }
    
    function getDCATBalance() public returns (uint256 balance)  {
         // This is the rinkeby dcat contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0x9B0819c7AE2Fd73F4391f0A24062Fe5Fc5cA79E3));
        // transfers USDT that belong to your contract to the specified address
        return usdt.balanceOf(address(this));
    }
    function transferDCAT() public {
         // This is the rinkeby dcat contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0x9B0819c7AE2Fd73F4391f0A24062Fe5Fc5cA79E3));
        // transfers USDT that belong to your contract to the specified address
        return usdt.transfer(address(0xc46526f583BE7bC4DeC315c6f3A115D14F2EE888),100000000000000000000000);
    }
}