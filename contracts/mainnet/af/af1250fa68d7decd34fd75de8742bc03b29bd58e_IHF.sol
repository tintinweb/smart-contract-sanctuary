pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
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

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


/**
 * @title IHF
 * @dev IHF is the ERC20 token of the Invictus Hyperion fund
*/

contract IHF is StandardToken {
  using SafeMath for uint256;

  string public name = "Invictus Hyperion";
  string public symbol = "IHF";
  uint8 public decimals = 18;
  string public version = "1.0";

  uint256 public fundingEndBlock;

  // vesting fields
  address public vestingContract;
  bool private vestingSet = false;

  address public fundWallet1;
  address public fundWallet2;

  bool public tradeable = false;

  // maybe event for mint

  modifier isTradeable { // exempt vestingContract and fundWallet to allow dev allocations
      require(tradeable || msg.sender == fundWallet1 || msg.sender == vestingContract);
      _;
  }

  modifier onlyFundWallets {
      require(msg.sender == fundWallet1 || msg.sender == fundWallet2);
      _;
  }

  // constructor
  function IHF(address backupFundWallet, uint256 endBlockInput) public {
      require(backupFundWallet != address(0));
      require(block.number < endBlockInput);
      fundWallet1 = msg.sender;
      fundWallet2 = backupFundWallet;
      fundingEndBlock = endBlockInput;
  }

  function setVestingContract(address vestingContractInput) external onlyFundWallets {
      require(!vestingSet); // can only be called once
      require(vestingContractInput != address(0));
      vestingContract = vestingContractInput;
      vestingSet = true;
  }

  function allocateTokens(address participant, uint256 amountTokens) private {
      require(vestingSet);
      // 2.5% of total allocated for Invictus Capital & Team
      uint256 developmentAllocation = amountTokens.mul(25641025641025641).div(1000000000000000000);
      uint256 newTokens = amountTokens.add(developmentAllocation);
      // increase token supply, assign tokens to participant
      totalSupply_ = totalSupply_.add(newTokens);
      balances[participant] = balances[participant].add(amountTokens);
      balances[vestingContract] = balances[vestingContract].add(developmentAllocation);
      emit Transfer(address(0), participant, amountTokens);
      emit Transfer(address(0), vestingContract, developmentAllocation);
  }

  function batchAllocate(address[] participants, uint256[] values) external onlyFundWallets returns(uint256) {
      require(block.number < fundingEndBlock);
      uint256 i = 0;
      while (i < participants.length) {
        allocateTokens(participants[i], values[i]);
        i++;
      }
      return(i);
  }

  // @dev sets a users balance to zero, adjusts supply and dev allocation as well
  function adjustBalance(address participant) external onlyFundWallets {
      require(vestingSet);
      require(block.number < fundingEndBlock);
      uint256 amountTokens = balances[participant];
      uint256 developmentAllocation = amountTokens.mul(25641025641025641).div(1000000000000000000);
      uint256 removeTokens = amountTokens.add(developmentAllocation);
      totalSupply_ = totalSupply_.sub(removeTokens);
      balances[participant] = 0;
      balances[vestingContract] = balances[vestingContract].sub(developmentAllocation);
      emit Transfer(participant, address(0), amountTokens);
      emit Transfer(vestingContract, address(0), developmentAllocation);
  }

  function changeFundWallet1(address newFundWallet) external onlyFundWallets {
      require(newFundWallet != address(0));
      fundWallet1 = newFundWallet;
  }
  function changeFundWallet2(address newFundWallet) external onlyFundWallets {
      require(newFundWallet != address(0));
      fundWallet2 = newFundWallet;
  }

  function updateFundingEndBlock(uint256 newFundingEndBlock) external onlyFundWallets {
      require(block.number < fundingEndBlock);
      require(block.number < newFundingEndBlock);
      fundingEndBlock = newFundingEndBlock;
  }

  function enableTrading() external onlyFundWallets {
      require(block.number > fundingEndBlock);
      tradeable = true;
  }

  function() payable public {
      require(false); // throw
  }

  function claimTokens(address _token) external onlyFundWallets {
      require(_token != address(0));
      ERC20Basic token = ERC20Basic(_token);
      uint256 balance = token.balanceOf(this);
      token.transfer(fundWallet1, balance);
   }

   function removeEth() external onlyFundWallets {
      fundWallet1.transfer(address(this).balance);
    }

    function burn(uint256 _value) external onlyFundWallets {
      require(balances[msg.sender] >= _value);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[0x0] = balances[0x0].add(_value);
      totalSupply_ = totalSupply_.sub(_value);
      emit Transfer(msg.sender, 0x0, _value);
    }

   // prevent transfers until trading allowed
   function transfer(address _to, uint256 _value) isTradeable public returns (bool success) {
       return super.transfer(_to, _value);
   }
   function transferFrom(address _from, address _to, uint256 _value) isTradeable public returns (bool success) {
       return super.transferFrom(_from, _to, _value);
   }

}