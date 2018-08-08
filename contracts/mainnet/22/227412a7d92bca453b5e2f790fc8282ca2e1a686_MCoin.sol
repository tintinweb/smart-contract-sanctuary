pragma solidity ^0.4.24;


/** ----------------------MonetaryCoin V1.0.0 ------------------------*/

/**
 * Homepage: https://MonetaryCoin.org  Distribution: https://MonetaryCoin.io
 *
 * Full source code: https://github.com/Monetary-Foundation/MonetaryCoin
 * 
 * Licenced MIT - The Monetary Foundation 2018
 *
 */

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
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
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}



/**
 * @title MineableToken
 * @dev ERC20 Token with Pos mining.
 * The blockReward_ is controlled by a GDP oracle tied to the national identity or currency union identity of the subject MonetaryCoin.
 * This type of mining will be used during both the initial distribution period and when GDP growth is positive.
 * For mining during negative growth period please refer to MineableM5Token.sol. 
 * Unlike standard erc20 token, the totalSupply is sum(all user balances) + totalStake instead of sum(all user balances).
*/
contract MineableToken is MintableToken { 
  event Commit(address indexed from, uint value,uint atStake, int onBlockReward);
  event Withdraw(address indexed from, uint reward, uint commitment);

  uint256 totalStake_ = 0;
  int256 blockReward_;         //could be positive or negative according to GDP

  struct Commitment {
    uint256 value;             // value commited to mining
    uint256 onBlockNumber;     // commitment done on block
    uint256 atStake;           // stake during commitment
    int256 onBlockReward;
  }

  mapping( address => Commitment ) miners;

  /**
  * @dev commit _value for minning
  * @notice the _value will be substructed from user balance and added to the stake.
  * if user previously commited, add to an existing commitment. 
  * this is done by calling withdraw() then commit back previous commit + reward + new commit 
  * @param _value The amount to be commited.
  * @return the commit value: _value OR prevCommit + reward + _value
  */
  function commit(uint256 _value) public returns (uint256 commitmentValue) {
    require(0 < _value);
    require(_value <= balances[msg.sender]);
    
    commitmentValue = _value;
    uint256 prevCommit = miners[msg.sender].value;
    //In case user already commited, withdraw and recommit 
    // new commitment value: prevCommit + reward + _value
    if (0 < prevCommit) {
      // withdraw Will revert if reward is negative
      uint256 prevReward;
      (prevReward, prevCommit) = withdraw();
      commitmentValue = prevReward.add(prevCommit).add(_value);
    }

    // sub will revert if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(commitmentValue);
    emit Transfer(msg.sender, address(0), commitmentValue);

    totalStake_ = totalStake_.add(commitmentValue);

    miners[msg.sender] = Commitment(
      commitmentValue, // Commitment.value
      block.number, // onBlockNumber
      totalStake_, // atStake = current stake + commitments value
      blockReward_ // onBlockReward
      );
    
    emit Commit(msg.sender, commitmentValue, totalStake_, blockReward_); // solium-disable-line

    return commitmentValue;
  }

  /**
  * @dev withdraw reward
  * @return {
    "uint256 reward": the new supply
    "uint256 commitmentValue": the commitment to be returned
    }
  */
  function withdraw() public returns (uint256 reward, uint256 commitmentValue) {
    require(miners[msg.sender].value > 0); 

    //will revert if reward is negative:
    reward = getReward(msg.sender);

    Commitment storage commitment = miners[msg.sender];
    commitmentValue = commitment.value;

    uint256 withdrawnSum = commitmentValue.add(reward);
    
    totalStake_ = totalStake_.sub(commitmentValue);
    totalSupply_ = totalSupply_.add(reward);
    
    balances[msg.sender] = balances[msg.sender].add(withdrawnSum);
    emit Transfer(address(0), msg.sender, commitmentValue.add(reward));
    
    delete miners[msg.sender];
    
    emit Withdraw(msg.sender, reward, commitmentValue);  // solium-disable-line
    return (reward, commitmentValue);
  }

  /**
  * @dev Calculate the reward if withdraw() happans on this block
  * @notice The reward is calculated by the formula:
  * (numberOfBlocks) * (effectiveBlockReward) * (commitment.value) / (effectiveStake) 
  * effectiveBlockReward is the average between the block reward during commit and the block reward during the call
  * effectiveStake is the average between the stake during the commit and the stake during call (liniar aproximation)
  * @return An uint256 representing the reward amount
  */ 
  function getReward(address _miner) public view returns (uint256) {
    if (miners[_miner].value == 0) {
      return 0;
    }

    Commitment storage commitment = miners[_miner];

    int256 averageBlockReward = signedAverage(commitment.onBlockReward, blockReward_);
    
    require(0 <= averageBlockReward);
    
    uint256 effectiveBlockReward = uint256(averageBlockReward);
    
    uint256 effectiveStake = average(commitment.atStake, totalStake_);
    
    uint256 numberOfBlocks = block.number.sub(commitment.onBlockNumber);

    uint256 miningReward = numberOfBlocks.mul(effectiveBlockReward).mul(commitment.value).div(effectiveStake);
       
    return miningReward;
  }

  /**
  * @dev Calculate the average of two integer numbers 
  * @notice 1.5 will be rounded toward zero
  * @return An uint256 representing integer average
  */
  function average(uint256 a, uint256 b) public pure returns (uint256) {
    return a.add(b).div(2);
  }

  /**
  * @dev Calculate the average of two signed integers numbers 
  * @notice 1.5 will be toward zero
  * @return An int256 representing integer average
  */
  function signedAverage(int256 a, int256 b) public pure returns (int256) {
    int256 ans = a + b;

    if (a > 0 && b > 0 && ans <= 0) {
      require(false);
    }
    if (a < 0 && b < 0 && ans >= 0) {
      require(false);
    }

    return ans / 2;
  }

  /**
  * @dev Gets the commitment of the specified address.
  * @param _miner The address to query the the commitment Of
  * @return the amount commited.
  */
  function commitmentOf(address _miner) public view returns (uint256) {
    return miners[_miner].value;
  }

  /**
  * @dev Gets the all fields for the commitment of the specified address.
  * @param _miner The address to query the the commitment Of
  * @return {
    "uint256 value": the amount commited.
    "uint256 onBlockNumber": block number of commitment.
    "uint256 atStake": stake when commited.
    "int256 onBlockReward": block reward when commited.
    }
  */
  function getCommitment(address _miner) public view 
  returns (
    uint256 value,             // value commited to mining
    uint256 onBlockNumber,     // commited on block
    uint256 atStake,           // stake during commit
    int256 onBlockReward       // block reward during commit
    ) 
  {
    value = miners[_miner].value;
    onBlockNumber = miners[_miner].onBlockNumber;
    atStake = miners[_miner].atStake;
    onBlockReward = miners[_miner].onBlockReward;
  }

  /**
  * @dev the total stake
  * @return the total stake
  */
  function totalStake() public view returns (uint256) {
    return totalStake_;
  }

  /**
  * @dev the block reward
  * @return the current block reward
  */
  function blockReward() public view returns (int256) {
    return blockReward_;
  }
}


/**
 * @title GDPOraclizedToken
 * @dev This is an interface for the GDP Oracle to control the mining rate.
 * For security reasons, two distinct functions were created: 
 * setPositiveGrowth() and setNegativeGrowth()
 */
contract GDPOraclizedToken is MineableToken {

  event GDPOracleTransferred(address indexed previousOracle, address indexed newOracle);
  event BlockRewardChanged(int oldBlockReward, int newBlockReward);

  address GDPOracle_;
  address pendingGDPOracle_;

  /**
   * @dev Modifier Throws if called by any account other than the GDPOracle.
   */
  modifier onlyGDPOracle() {
    require(msg.sender == GDPOracle_);
    _;
  }
  
  /**
   * @dev Modifier throws if called by any account other than the pendingGDPOracle.
   */
  modifier onlyPendingGDPOracle() {
    require(msg.sender == pendingGDPOracle_);
    _;
  }

  /**
   * @dev Allows the current GDPOracle to transfer control to a newOracle.
   * The new GDPOracle need to call claimOracle() to finalize
   * @param newOracle The address to transfer ownership to.
   */
  function transferGDPOracle(address newOracle) public onlyGDPOracle {
    pendingGDPOracle_ = newOracle;
  }

  /**
   * @dev Allows the pendingGDPOracle_ address to finalize the transfer.
   */
  function claimOracle() onlyPendingGDPOracle public {
    emit GDPOracleTransferred(GDPOracle_, pendingGDPOracle_);
    GDPOracle_ = pendingGDPOracle_;
    pendingGDPOracle_ = address(0);
  }

  /**
   * @dev Chnage block reward according to GDP 
   * @param newBlockReward the new block reward in case of possible growth
   */
  function setPositiveGrowth(int256 newBlockReward) public onlyGDPOracle returns(bool) {
    // protect against error / overflow
    require(0 <= newBlockReward);
    
    emit BlockRewardChanged(blockReward_, newBlockReward);
    blockReward_ = newBlockReward;
  }

  /**
   * @dev Chnage block reward according to GDP 
   * @param newBlockReward the new block reward in case of negative growth
   */
  function setNegativeGrowth(int256 newBlockReward) public onlyGDPOracle returns(bool) {
    require(newBlockReward < 0);

    emit BlockRewardChanged(blockReward_, newBlockReward);
    blockReward_ = newBlockReward;
  }

  /**
  * @dev get GDPOracle
  * @return the address of the GDPOracle
  */
  function GDPOracle() public view returns (address) { // solium-disable-line mixedcase
    return GDPOracle_;
  }

  /**
  * @dev get GDPOracle
  * @return the address of the GDPOracle
  */
  function pendingGDPOracle() public view returns (address) { // solium-disable-line mixedcase
    return pendingGDPOracle_;
  }
}



/**
 * @title MineableM5Token
 * @notice This contract adds the ability to mine for M5 tokens when growth is negative.
 * The M5 token is a distinct ERC20 token that may be obtained only following a period of negative GDP growth.
 * The logic for M5 mining will be finalized in advance of the close of the initial distribution period – see the White Paper for additional details.
 * After upgrading this contract with the final M5 logic, finishUpgrade() will be called to permanently seal the upgradeability of the contract.
*/
contract MineableM5Token is GDPOraclizedToken { 
  
  event M5TokenUpgrade(address indexed oldM5Token, address indexed newM5Token);
  event M5LogicUpgrade(address indexed oldM5Logic, address indexed newM5Logic);
  event FinishUpgrade();

  // The M5 token contract
  address M5Token_;
  // The contract to manage M5 mining logic.
  address M5Logic_;
  // The address which controls the upgrade process
  address upgradeManager_;
  // When isUpgradeFinished_ is true, no more upgrades is allowed
  bool isUpgradeFinished_ = false;

  /**
  * @dev get the M5 token address
  * @return M5 token address
  */
  function M5Token() public view returns (address) {
    return M5Token_;
  }

  /**
  * @dev get the M5 logic contract address
  * @return M5 logic contract address
  */
  function M5Logic() public view returns (address) {
    return M5Logic_;
  }

  /**
  * @dev get the upgrade manager address
  * @return the upgrade manager address
  */
  function upgradeManager() public view returns (address) {
    return upgradeManager_;
  }

  /**
  * @dev get the upgrade status
  * @return the upgrade status. if true, no more upgrades are possible.
  */
  function isUpgradeFinished() public view returns (bool) {
    return isUpgradeFinished_;
  }

  /**
  * @dev Throws if called by any account other than the GDPOracle.
  */
  modifier onlyUpgradeManager() {
    require(msg.sender == upgradeManager_);
    require(!isUpgradeFinished_);
    _;
  }

  /**
   * @dev Allows to set the M5 token contract 
   * @param newM5Token The address of the new contract
   */
  function upgradeM5Token(address newM5Token) public onlyUpgradeManager { // solium-disable-line
    require(newM5Token != address(0));
    emit M5TokenUpgrade(M5Token_, newM5Token);
    M5Token_ = newM5Token;
  }

  /**
   * @dev Allows the upgrade the M5 logic contract 
   * @param newM5Logic The address of the new contract
   */
  function upgradeM5Logic(address newM5Logic) public onlyUpgradeManager { // solium-disable-line
    require(newM5Logic != address(0));
    emit M5LogicUpgrade(M5Logic_, newM5Logic);
    M5Logic_ = newM5Logic;
  }

  /**
   * @dev Allows the upgrade the M5 logic contract and token at the same transaction
   * @param newM5Token The address of a new M5 token
   * @param newM5Logic The address of the new contract
   */
  function upgradeM5(address newM5Token, address newM5Logic) public onlyUpgradeManager { // solium-disable-line
    require(newM5Token != address(0));
    require(newM5Logic != address(0));
    emit M5TokenUpgrade(M5Token_, newM5Token);
    emit M5LogicUpgrade(M5Logic_, newM5Logic);
    M5Token_ = newM5Token;
    M5Logic_ = newM5Logic;
  }

  /**
  * @dev Function to dismiss the upgrade capability
  * @return True if the operation was successful.
  */
  function finishUpgrade() onlyUpgradeManager public returns (bool) {
    isUpgradeFinished_ = true;
    emit FinishUpgrade();
    return true;
  }

  /**
  * @dev Calculate the reward if withdrawM5() happans on this block
  * @notice This is a wrapper, which calls and return result from M5Logic
  * the actual logic is found in the M5Logic contract
  * @param _miner The address of the _miner
  * @return An uint256 representing the reward amount
  */
  function getM5Reward(address _miner) public view returns (uint256) {
    require(M5Logic_ != address(0));
    if (miners[_miner].value == 0) {
      return 0;
    }
    // check that effective block reward is indeed negative
    require(signedAverage(miners[_miner].onBlockReward, blockReward_) < 0);

    // return length (bytes)
    uint32 returnSize = 32;
    // target contract
    address target = M5Logic_;
    // method signeture for target contract
    bytes32 signature = keccak256("getM5Reward(address)");
    // size of calldata for getM5Reward function: 4 for signeture and 32 for one variable (address)
    uint32 inputSize = 4 + 32;
    // variable to check delegatecall result (success or failure)
    uint8 callResult;
    // result from target.getM5Reward()
    uint256 result;
    
    assembly { // solium-disable-line
        // return _dest.delegatecall(msg.data)
        mstore(0x0, signature) // 4 bytes of method signature
        mstore(0x4, _miner)    // 20 bytes of address
        // delegatecall(g, a, in, insize, out, outsize)	- call contract at address a with input mem[in..(in+insize))
        // providing g gas and v wei and output area mem[out..(out+outsize)) returning 0 on error (eg. out of gas) and 1 on success
        // keep caller and callvalue
        callResult := delegatecall(sub(gas, 10000), target, 0x0, inputSize, 0x0, returnSize)
        switch callResult 
        case 0 
          { revert(0,0) } 
        default 
          { result := mload(0x0) }
    }
    return result;
  }

  event WithdrawM5(address indexed from,uint commitment, uint M5Reward);

  /**
  * @dev withdraw M5 reward, only appied to mining when GDP is negative
  * @return {
    "uint256 reward": the new M5 supply
    "uint256 commitmentValue": the commitment to be returned
    }
  */
  function withdrawM5() public returns (uint256 reward, uint256 commitmentValue) {
    require(M5Logic_ != address(0));
    require(M5Token_ != address(0));
    require(miners[msg.sender].value > 0); 
    
    // will revert if reward is positive
    reward = getM5Reward(msg.sender);
    commitmentValue = miners[msg.sender].value;
    
    require(M5Logic_.delegatecall(bytes4(keccak256("withdrawM5()")))); // solium-disable-line
    
    return (reward,commitmentValue);
  }

  //triggered when user swaps m5Value of M5 tokens for value of regular tokens.
  event Swap(address indexed from, uint256 M5Value, uint256 value);

  /**
  * @dev swap M5 tokens back to regular tokens when GDP is back to positive 
  * @param _value The amount of M5 tokens to swap for regular tokens
  * @return true
  */
  function swap(uint256 _value) public returns (bool) {
    require(M5Logic_ != address(0));
    require(M5Token_ != address(0));

    require(M5Logic_.delegatecall(bytes4(keccak256("swap(uint256)")),_value)); // solium-disable-line
    
    return true;
  }
}


/**
 * @title MCoin
 * @dev The MonetaryCoin contract
 * The MonetaryCoin contract allows for the creation of a new monetary coin.
 * The supply of a minable coin in a period is defined by an oracle that reports GDP data from the country related to that coin.
 * Example: If the GDP of a given country grows by 3%, then 3% more coins will be available for forging (i.e. mining) in the next period.
 * Coins will be distributed by the proof of stake forging mechanism both during and after the initial distribution period.
 * The Proof of stake forging is defined by the MineableToken.sol contract. 
 */
contract MCoin is MineableM5Token {

  string public name; // solium-disable-line uppercase
  string public symbol; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  constructor(
    string tokenName,
    string tokenSymbol,
    uint256 blockReward, // will be transformed using toDecimals()
    address GDPOracle,
    address upgradeManager
    ) public 
    {
    require(GDPOracle != address(0));
    require(upgradeManager != address(0));
    
    name = tokenName;
    symbol = tokenSymbol;

    blockReward_ = toDecimals(blockReward);
    emit BlockRewardChanged(0, blockReward_);

    GDPOracle_ = GDPOracle;
    emit GDPOracleTransferred(0x0, GDPOracle_);

    M5Token_ = address(0);
    M5Logic_ = address(0);
    upgradeManager_ = upgradeManager;
  }

  function toDecimals(uint256 _value) pure internal returns (int256 value) {
    value = int256 (
      _value.mul(10 ** uint256(decimals))
    );
    assert(0 < value);
    return value;
  }

}