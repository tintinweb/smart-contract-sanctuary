/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.4.23;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not beingzero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow
  * (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract ERC20 {
    using SafeMath for uint256; 

    string public name;
    string public url;
    string public imageURL;
    string public description;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 totalSupply_; 

    constructor(
        uint _totalSupply,
        string memory _name,
        string memory _url,
        string memory _imageURL,
        string memory _description
    ) public {
        totalSupply_ = _totalSupply;
        name = _name;
        url = _url;
        imageURL = _imageURL;
        description = _description;
        // Assigns all tokens to the owner
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) { 
        return totalSupply_; 
    }

    function balanceOf(address _owner) public view 
        returns (uint256) { 
        return balances[_owner]; 
    }

    function transfer(address _to, uint256 _value) public 
        returns (bool) { 
        require(_to != address(0)); 
        require(_value <= balances[msg.sender]); 

        balances[msg.sender] = balances[msg.sender].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        emit Transfer(msg.sender, _to, _value); 

        return true; 
    } 

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address Address which you want to send 
    * tokens from
    * @param _to address Address which you want to transfer to
    * @param _value uint256 Amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, 
        uint256 _value)
        public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = 
            allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the passed 
    * tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
   function approve(address _spender, uint256 _value) public 
        returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
   }

    /**
    * @dev Function to check the amount of tokens that an 
    * owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend 
    * the funds.
    * @return A uint256 specifying the amount of tokens still 
    * available for the spender.
    */
    function allowance(address _owner, address _spender)
        public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens allowed.
    * @param _spender Address which will spend the funds.
    * @param _addedValue Amount of tokens to increase.
    */
    function increaseApproval(address _spender, uint _addedValue)
        public returns (bool) {
        allowed[msg.sender][_spender] = 
            (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /** 
    * @dev Decrease the amount of tokens allowed.
    * @param _spender Address which will spend the funds. 
    * @param _subtractedValue Amount of tokens to decrease. 
    */ 
    function decreaseApproval(address _spender, uint _subtractedValue) 
        public returns (bool) { 
        uint oldValue = allowed[msg.sender][_spender]; 

        if (_subtractedValue > oldValue) { 
            allowed[msg.sender][_spender] = 0; 
        } else { 
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue); 
        } 

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true; 
    }


}