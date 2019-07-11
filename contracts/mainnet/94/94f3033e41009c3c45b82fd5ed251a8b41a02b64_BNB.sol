/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity >=0.4.22 <0.6.0;

/**
  interface :
 */
interface tokenRecipient{
  function receiveApproval(address _from, uint256 _value,  address _token,   bytes calldata _extraData) external;
}


contract owned{
  //the token owner
  address public owner;
  
  constructor() public{
      owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

//   function transferOwnerShip(address newOwner) onlyOwner public  {
//     owner = newOwner;
//   }
}


contract BNB is owned {
    string public name;  //token name
    string public symbol; //token symbol
    uint8 public decimals = 18; //Tokens to support the number of decimal digits
    uint256 public totalSupply; //token total nums

    mapping (address => uint256) public balanceOf;//mapping address balance
    mapping (address => mapping(address => uint256)) public allowance;//
    mapping (address => bool) public frozenAccount;//

    event Transfer(address indexed from, address indexed to, uint256 value); //transfer event
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);

   
    constructor(uint256 initialSupply,string memory tokenName,string memory tokenSymbol) public {
       totalSupply = initialSupply * 10 ** uint256(decimals);
       balanceOf[msg.sender] = totalSupply;
       name = tokenName;
       symbol = tokenSymbol; 
    }

    /**
      freeze or unfreeze account
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
      frozenAccount[target] = freeze;
      emit FrozenFunds(target,freeze);
    }

    /**
       Internal transfer,only can be called by this contract 
     */
    function _transfer(address _from,address _to, uint _value) internal{
      require(_to != address(0x0));
      require(_from != address(0x0));
      require(balanceOf[_from] >= _value); //check if the sender has enough
      require(balanceOf[_to] + _value >= balanceOf[_to]);//check for overflows
      require(!frozenAccount[_from]);
      require(!frozenAccount[_to]);

      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value); //send transfer event
      // the  num mast equals after transfer
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
      send &#39;_value&#39; tokens to &#39;_to&#39; from your account
     */
    function transfer(address _to , uint256 _value) public  returns(bool success){
      _transfer(msg.sender, _to, _value);
      return true;
    }
    
    /**
        send &#39;_value&#39; tokens to &#39;_to&#39; on behalf to &#39;_from&#39;
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
      require(_value <= allowance[_from][msg.sender]);
      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value); 
      return true;
    }

    /**
     * 
      set allowance for other address
      allows &#39;_spender&#39; to spend no more than &#39;_value&#39; tokens on you behalf
     */
    function approve(address _spender, uint256 _value)  public returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);     
      return true;
    }

    /**
     set allowance for other address and nofity

     allows &#39;_spender&#39; to spend no more than &#39;_value&#39; tokens on you behalf,and then ping the contract about it
     */
    function approveAndCall(address _spender,uint256 _value, bytes memory _extraData) public returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if(approve(_spender,_value)){
        spender.receiveApproval(msg.sender, _value, address(this),_extraData);
        return true;
      }
    }
    
    /**
      Destroy tokens
      remove &#39;_value&#39; tokens from the system irreversibly
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
      require(balanceOf[msg.sender] >= _value);
      balanceOf[msg.sender] -= _value;
      totalSupply -= _value;
      emit Burn(msg.sender, _value);
      return true;
    }
    
    /**
     destroy tokens from other account
     remove &#39;_value&#39; tokens from the system irreversibly or &#39;_from&#39; 
    */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns(bool success){
      require(balanceOf[_from] >= _value);
      require(_value <= allowance[_from][msg.sender]);
      balanceOf[_from] -= _value;
      allowance[_from][msg.sender] -= _value;
      totalSupply -= _value;
      emit Burn(_from, _value);
      return true;
    }
    
    /**
      Increase the total tokens
    */
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
      uint256 number = mintedAmount * 10 * uint256(decimals);    
      balanceOf[target] += number;
      totalSupply += number;
      emit Transfer(address(0x0),owner,mintedAmount);
      emit Transfer(owner,target,mintedAmount);
    }
}