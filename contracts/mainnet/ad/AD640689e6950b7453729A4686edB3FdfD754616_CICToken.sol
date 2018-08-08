pragma solidity ^0.4.18;

interface TransferRecipient {
	function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns(bool);
}

interface ApprovalRecipient {
	function approvalFallback(address _from, uint256 _value, bytes _extraData) public returns(bool);
}
contract ERCToken {
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	uint256 public  totalSupply;
	mapping (address => uint256) public balanceOf;

	function allowance(address _owner,address _spender) public view returns(uint256);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public  returns (bool success);


}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;





  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
  }

}
pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract CICToken is ERCToken,Ownable {

    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals=18;
    mapping (address => bool) public frozenAccount;
    mapping (address => mapping (address => uint256)) internal allowed;
    event FrozenFunds(address target, bool frozen);


  function CICToken(
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = 30e8 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                   // Give the creator all initial tokens
        name = tokenName;                                      // Set the name for display purposes
        symbol = tokenSymbol;
     }
    

   /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {

        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        // Save this for an assertion in the future
        uint previousbalanceOf = balanceOf[_from].add(balanceOf[_to]);

        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] =balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousbalanceOf);
    }


    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }



    function transferAndCall(address _to, uint256 _value, bytes _data)
        public
        returns (bool success) {
        _transfer(msg.sender,_to, _value);
        if(_isContract(_to))
        {
            TransferRecipient spender = TransferRecipient(_to);
            if(!spender.tokenFallback(msg.sender, _value, _data))
            {
                revert();
            }
        }
        return true;
    }


    function _isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender]= allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }


    function allowance(address _owner,address _spender) public view returns(uint256){
        return allowed[_owner][_spender];

    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public  returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {

        allowed[msg.sender][_spender] = _value;
        if(_isContract(_spender)){
            ApprovalRecipient spender = ApprovalRecipient(_spender);
            if(!spender.approvalFallback(msg.sender, _value, _extraData)){
                revert();
            }
        }
        Approval(msg.sender, _spender, _value);
        return true;

    }


    function freezeAccount(address target, bool freeze) onlyOwner public{
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }




}