pragma solidity ^0.4.23;

import './SafeMath.sol';



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable 
{
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  
  
   /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return owner;
    }
  

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
  
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable 
{
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpauseunpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic 
{
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic 
{
  // function allowance(address owner, address spender) public view returns (uint256);

  // function transferFrom(address from, address to, uint256 value) public returns (bool);

  // function approve(address spender, uint256 value) public returns (bool);
  
  // event Approval(
  //   address indexed owner,
  //   address indexed spender,
  //   uint256 value
  // );

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic 
{
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken 
{

  // mapping (address => mapping (address => uint256)) internal allowed;

  // /**
  //  * @dev Transfer tokens from one address to another
  //  * @param _from address The address which you want to send tokens from
  //  * @param _to address The address which you want to transfer to
  //  * @param _value uint256 the amount of tokens to be transferred
  //  */
  // function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
  //   require(_to != address(0));
  //   require(_value <= balances[_from]);
  //   require(_value <= allowed[_from][msg.sender]);

  //   balances[_from] = balances[_from].sub(_value);
  //   balances[_to] = balances[_to].add(_value);
  //   allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
  //   emit Transfer(_from, _to, _value);
  //   return true;
  // }

  // /**
  //  * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
  //  *
  //  * Beware that changing an allowance with this method brings the risk that someone may use both the old
  //  * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
  //  * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
  //  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  //  * @param _spender The address which will spend the funds.
  //  * @param _value The amount of tokens to be spent.
  //  */
  // function approve(address _spender, uint256 _value) public returns (bool) {
  //   require((_value == 0) || (allowed[msg.sender][_spender] == 0));
  //   allowed[msg.sender][_spender] = _value;
  //   emit Approval(msg.sender, _spender, _value);
  //   return true;
  // }

  // /**
  //  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  //  * @param _owner address The address which owns the funds.
  //  * @param _spender address The address which will spend the funds.
  //  * @return A uint256 specifying the amount of tokens still available for the spender.
  //  */
  // function allowance(address _owner, address _spender) public view returns (uint256) {
  //   return allowed[_owner][_spender];
  // }

  // /**
  //  * @dev Increase the amount of tokens that an owner allowed to a spender.
  //  *
  //  * approve should be called when allowed[_spender] == 0. To increment
  //  * allowed value is better to use this function to avoid 2 calls (and wait until
  //  * the first transaction is mined)
  //  * From MonolithDAO Token.sol
  //  * @param _spender The address which will spend the funds.
  //  * @param _addedValue The amount of tokens to increase the allowance by.
  //  */
  // function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
  //   allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
  //   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
  //   return true;
  // }

  // /**
  //  * @dev Decrease the amount of tokens that an owner allowed to a spender.
  //  *
  //  * approve should be called when allowed[_spender] == 0. To decrement
  //  * allowed value is better to use this function to avoid 2 calls (and wait until
  //  * the first transaction is mined)
  //  * From MonolithDAO Token.sol
  //  * @param _spender The address which will spend the funds.
  //  * @param _subtractedValue The amount of tokens to decrease the allowance by.
  //  */
  // function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
  //   uint256 oldValue = allowed[msg.sender][_spender];
  //   if (_subtractedValue > oldValue) {
  //     allowed[msg.sender][_spender] = 0;
  //   } else {
  //     allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
  //   }
  //   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
  //   return true;
  // }
  
}


/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable 
{

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  // function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
  //   return super.transferFrom(_from, _to, _value);
  // }

  // function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
  //   return super.approve(_spender, _value);
  // }

  // function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool success) {
  //   return super.increaseApproval(_spender, _addedValue);
  // }

  // function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool success) {
  //   return super.decreaseApproval(_spender, _subtractedValue);
  // }

}


/**
 * @title Frozenable Token
 * @dev Illegal address that can be frozened.
 */
contract FrozenableToken is Ownable 
{
    mapping (address => bool) public Approvers; 

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address indexed to, bool frozen);

    modifier whenNotFrozen(address _who) {
      require(!frozenAccount[msg.sender] && !frozenAccount[_who]);
      _;
    }

    function setApprover(address _wallet, bool _approve) public {
        require(msg.sender == owner);

        Approvers[_wallet] = _approve;

        if (!_approve)
          delete Approvers[_wallet];
    }

    function freezeAccount(address _to, bool _freeze) public {
        require(true == Approvers[msg.sender]);
        require(_to != address(0));

        frozenAccount[_to] = _freeze;
        emit FrozenFunds(_to, _freeze);
    }

}


/**
*------------------可增发token----------------------------
*/
contract MintableToken is StandardToken, Ownable {
    
      event Mint(address indexed to, uint256 amount);

      /**
      * @dev 增发token方法
      * @param _to 获取增发token的地址_to.
      * @param _amount 增发的token数量.
      * @return A boolean that indicates if the operation was successful.
      */
      function _mint(address _to, uint256 _amount) internal returns (bool){
          
           // 总发行量增加_amount数量的token
            totalSupply_ = totalSupply_.add(_amount);
            // 获取增发的地址增加_amount数量的token
            balances[_to] = balances[_to].add(_amount);
            // 触发增发事件
            emit Mint(_to, _amount);
            // 触发Transfer事件
            emit Transfer(address(0), _to, _amount);
            return true;
       
      }

}



/**
 * @title HiToken Token
 * @dev Global digital painting asset platform token.
 * @author HiToken 
 */
contract HiToken is PausableToken, FrozenableToken, MintableToken
{
    using SafeMath for uint256;

    string public name = "hi Dollars";
    string public symbol = "HI";
    uint256 public decimals = 18;
    // uint256 INITIAL_SUPPLY = 10 *(10 ** 5) * (10 ** uint256(decimals));
    uint256 INITIAL_SUPPLY = 0;
    uint totalHolders_ = 6;  // total number is fixed, wont change in future
                             // but holders address can be updated thru setMintSplitHolder method

    mapping (uint => address) public holders;
    mapping (uint => uint256) public MintSplitHolderRatios; //index -> ratio boosted by 10000
    mapping (address => bool) public Proposers; 
    mapping (address => uint256) public Proposals; //address -> mintAmount

    /**
     * @dev Initializes the total release
     */
    constructor() public {
        holders[0] = 0xb660539dd01A78ACB3c7CF77BfcCE735081ec004; //HI_LID
        holders[1] = 0x8376EEF57D86A8c1DFEE8E91E75912e361A940e0; //HI_EG
        holders[2] = 0x572aB5eC71354Eb80e6D18e394b3e71BA8e282F5; //HI_NLTI
        holders[3] = 0x93aeC0ADc392C09666B4d56654F39a375AEbD4C1; //HI_CR
        holders[4] = 0xFb3BEb5B1258e438982956c9f023d4F7bD683E4E; //HI_FT
        holders[5] = 0xBF990D24F7167b97b836457d380ACCdCb1782201; //HI_FR

        MintSplitHolderRatios[0] = 2720; //27.2%
        MintSplitHolderRatios[1] = 1820; //18.2%
        MintSplitHolderRatios[2] = 1820; //18.2%
        MintSplitHolderRatios[3] = 1360; //13.6%
        MintSplitHolderRatios[4] = 1360; //13.6%
        MintSplitHolderRatios[5] = 920;  //9.2%, remaining
        
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    /**
     * if ether is sent to this address, send it back.
     */
    function() public payable {
        revert();
    }
 
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public whenNotFrozen(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    // /**
    //  * @dev Transfer tokens from one address to another
    //  * @param _from address The address which you want to send tokens from
    //  * @param _to address The address which you want to transfer to
    //  * @param _value uint256 the amount of tokens to be transferred
    //  */
    // function transferFrom(address _from, address _to, uint256 _value) public whenNotFrozen(_from) returns (bool) {
    //     return super.transferFrom(_from, _to, _value);
    // }        
    
   
    function setProposer(address _wallet, bool _on) public{
        require(msg.sender == owner);

        Proposers[_wallet] = _on;

        if (!_on)
          delete Proposers[_wallet];
    }

    /**
     *  to update an split holder ratio at the index
     *  index ranges from 0..totalHolders -1
     */
    function setMintSplitHolder(uint index, address _wallet, uint64 _ratio) public returns (bool) {
        require(msg.sender == owner);

        if (index > totalHolders_ - 1)
          return false;

        holders[ index ] = _wallet;
        MintSplitHolderRatios[ index ] = _ratio;

        return true;
    }

    /**
    * @dev propose to mint
    * @param _amount amount to mint
    * @return mint propose ID
    */
    function proposeMint(uint256 _amount) public returns(bool) {
        require(true == Proposers[msg.sender]);

        Proposals[msg.sender] = _amount; //mint once for a propoer at a time otherwise would be overwritten
        return true;
    }

    function approveMint(address _proposer, uint256 _amount, bool _approve) public returns(bool) {
      require(true == Approvers[msg.sender]);

      if (!_approve) {
          delete Proposals[_proposer];
          return true;
      }

      if (totalHolders_ == 0)
        return false;

      if (Proposals[_proposer] < _amount)
        return false;

      uint256 unsplitted = _amount;
      for (uint8 i = 0; i < totalHolders_ - 1; i++) {
        address _to = holders[i];
        uint256 _amt = _amount.mul(MintSplitHolderRatios[i]).div(10000);
        unsplitted -= _amt;
        _mint(_to, _amt);
      }

      _to = holders[totalHolders_ - 1];
      _mint(_to, unsplitted); //for the last holder in the list

      Proposals[_proposer] -= _amount;
      if (Proposals[_proposer] == 0)
        delete Proposals[_proposer];

      return true;

    }
}