pragma solidity ^0.4.18;

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transferInternal(address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/SafeMath.sol

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/BasicToken.sol

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
    function transferInternal(address _to, uint256 _value) internal returns (bool) {
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

// File: contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowanceInternal(address owner, address spender) internal view returns (uint256);
    function transferFromInternal(address from, address to, uint256 value) internal returns (bool);
    function approveInternal(address spender, uint256 value) internal returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/StandardToken.sol

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
    function transferFromInternal(address _from, address _to, uint256 _value) internal returns (bool) {
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
    function approveInternal(address _spender, uint256 _value) internal returns (bool) {
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
    function allowanceInternal(address _owner, address _spender) internal view returns (uint256) {
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
    function increaseApprovalInternal(address _spender, uint _addedValue) internal returns (bool) {
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
    function decreaseApprovalInternal(address _spender, uint _subtractedValue) internal returns (bool) {
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

// File: contracts/MintableToken.sol

//import "./StandardToken.sol";
//import "../../ownership/Ownable.sol";



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    address public icoContractAddress;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Throws if called by any account other than the icoContract.
    */
    modifier onlyIcoContract() {
        require(msg.sender == icoContractAddress);
        _;
    }


    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyIcoContract canMint external returns (bool) {
        //return true;
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
    function finishMinting() onlyOwner canMint external returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}

// File: contracts/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
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
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}

// File: contracts/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

    function transferInternal(address _to, uint256 _value) internal whenNotPaused returns (bool) {
        return super.transferInternal(_to, _value);
    }

    function transferFromInternal(address _from, address _to, uint256 _value) internal whenNotPaused returns (bool) {
        return super.transferFromInternal(_from, _to, _value);
    }

    function approveInternal(address _spender, uint256 _value) internal whenNotPaused returns (bool) {
        return super.approveInternal(_spender, _value);
    }

    function increaseApprovalInternal(address _spender, uint _addedValue) internal whenNotPaused returns (bool success) {
        return super.increaseApprovalInternal(_spender, _addedValue);
    }

    function decreaseApprovalInternal(address _spender, uint _subtractedValue) internal whenNotPaused returns (bool success) {
        return super.decreaseApprovalInternal(_spender, _subtractedValue);
    }
}

// File: contracts/ReentrancyGuard.sol

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="89fbece4eae6c9bb">[email&#160;protected]</span>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

// File: contracts/IiinoCoin.sol

contract IiinoCoin is MintableToken, PausableToken, ReentrancyGuard {
    event RewardMint(address indexed to, uint256 amount);
    event RewardMintingAmt(uint256 _amountOfTokensMintedPreCycle);
    event ResetReward();
    event RedeemReward(address indexed to, uint256 value);

    event CreatedEscrow(bytes32 _tradeHash);
    event ReleasedEscrow(bytes32 _tradeHash);
    event Dispute(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event BuyerArbitratorSet(bytes32 _tradeHash);
    event SellerArbitratorSet(bytes32 _tradeHash);
    event DisputeResolved (bytes32 _tradeHash);
    event IcoContractAddressSet (address _icoContractAddress);

    using SafeMath for uint256;

    // Mapping of rewards to beneficiaries of the reward
    mapping(address => uint256) public reward;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public amountMintPerDuration; // amount to mint during one minting cycle
    uint256 public durationBetweenRewardMints; // reward miniting cycle duration
    uint256 public previousDistribution; //EPOCH time of the previous distribution
    uint256 public totalRewardsDistributed; //Total amount of the rewards distributed
    uint256 public totalRewardsRedeemed; //Total amount of the rewards redeemed
    uint256 public minimumRewardWithdrawalLimit; //The minimum limit of rewards that can be withdrawn
    uint256 public rewardAvailableCurrentDistribution; //The amount of rewards available for the current Distribution.

    function IiinoCoin(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _amountMintPerDuration,
        uint256 _durationBetweenRewardMints
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        amountMintPerDuration = _amountMintPerDuration;
        durationBetweenRewardMints = _durationBetweenRewardMints;
        previousDistribution = now; // To initialize the previous distribution to the time of the creation of the contract
        totalRewardsDistributed = 0;
        totalRewardsRedeemed = 0;
        minimumRewardWithdrawalLimit = 10 ether; //Defaulted to 10 iiinos represented in iii
        rewardAvailableCurrentDistribution = amountMintPerDuration;
        icoContractAddress = msg.sender;
    }

    /**
    * @dev set the icoContractAddress in the token so that the ico Contract can mint the token
    * @param _icoContractAddress array of address. The address to which the reward needs to be distributed
    */
    function setIcoContractAddress(
        address _icoContractAddress
    ) external nonReentrant onlyOwner whenNotPaused {
        require (_icoContractAddress != address(0));
        emit IcoContractAddressSet(_icoContractAddress);
        icoContractAddress = _icoContractAddress;
    }

    /**
    * @dev distribute reward tokens to the list of addresses based on their proportion
    * @param _rewardAdresses array of address. The address to which the reward needs to be distributed
    */
    function batchDistributeReward(
        address[] _rewardAdresses,
        uint256[] _amountOfReward,
        uint256 _timestampOfDistribution
    ) external nonReentrant onlyOwner whenNotPaused {
        require(_timestampOfDistribution > previousDistribution.add(durationBetweenRewardMints)); //To only allow a distribution to happen 30 days (2592000 seconds) after the previous distribution
        require(_timestampOfDistribution < now); // To only allow a distribution time in the past
        require(_rewardAdresses.length == _amountOfReward.length); // To verify the length of the arrays are the same.

        uint256 rewardDistributed = 0;

        for (uint j = 0; j < _rewardAdresses.length; j++) {
            rewardMint(_rewardAdresses[j], _amountOfReward[j]);
            rewardDistributed = rewardDistributed.add(_amountOfReward[j]);
        }
        require(rewardAvailableCurrentDistribution >= rewardDistributed);
        totalRewardsDistributed = totalRewardsDistributed.add(rewardDistributed);
        rewardAvailableCurrentDistribution = rewardAvailableCurrentDistribution.sub(rewardDistributed);
    }

    /**
    * @dev distribute reward tokens to a addresse based on the proportion
    * @param _rewardAddress The address to which the reward needs to be distributed
    */
    function distributeReward(
        address _rewardAddress,
        uint256 _amountOfReward,
        uint256 _timestampOfDistribution
    ) external nonReentrant onlyOwner whenNotPaused {

        require(_timestampOfDistribution > previousDistribution);
        require(_timestampOfDistribution < previousDistribution.add(durationBetweenRewardMints)); //To only allow a distribution to happen 30 days (2592000 seconds) after the previous distribution
        require(_timestampOfDistribution < now); // To only allow a distribution time in the past
        //reward[_rewardAddress] = reward[_rewardAddress].add(_amountOfReward);
        rewardMint(_rewardAddress, _amountOfReward);

    }

    /**
    * @dev reset reward tokensfor the new duration
    */
    function resetReward() external nonReentrant onlyOwner whenNotPaused {
        require(now > previousDistribution.add(durationBetweenRewardMints)); //To only allow a distribution to happen 30 days (2592000 seconds) after the previous distribution
        previousDistribution = previousDistribution.add(durationBetweenRewardMints); // To set the new distribution period as the previous distribution timestamp
        rewardAvailableCurrentDistribution = amountMintPerDuration;
        emit ResetReward();
    }

    /**
   * @dev Redeem Reward tokens from one rewards array to balances array
   * @param _beneficiary address The address which contains the reward as well as the address to which the balance will be transferred
   * @param _value uint256 the amount of tokens to be redeemed
   */
    function redeemReward(
        address _beneficiary,
        uint256 _value
    ) external nonReentrant whenNotPaused{
        //Need to consider what happens to rewards after the stopping of minting process
        require(msg.sender == _beneficiary);
        require(_value >= minimumRewardWithdrawalLimit);
        require(reward[_beneficiary] >= _value);
        reward[_beneficiary] = reward[_beneficiary].sub(_value);
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        totalRewardsRedeemed = totalRewardsRedeemed.add(_value);
        emit RedeemReward(_beneficiary, _value);
    }

    function rewardMint(
        address _to,
        uint256 _amount
    ) onlyOwner canMint whenNotPaused internal returns (bool) {
        require(_amount > 0);
        require(_to != address(0));
        require(rewardAvailableCurrentDistribution >= _amount);
        totalSupply_ = totalSupply_.add(_amount);
        reward[_to] = reward[_to].add(_amount);
        totalRewardsDistributed = totalRewardsDistributed.add(_amount);
        rewardAvailableCurrentDistribution = rewardAvailableCurrentDistribution.sub(_amount);
        emit RewardMint(_to, _amount);
        //Transfer(address(0), _to, _amount); //balance of the user will only be updated on claiming the coin
        return true;
    }
    function userRewardAccountBalance(
        address _address
    ) whenNotPaused external view returns (uint256) {
        require(_address != address(0));
        return reward[_address];
    }
    function changeRewardMintingAmount(
        uint256 _newRewardMintAmt
    ) whenNotPaused nonReentrant onlyOwner external {
        require(_newRewardMintAmt < amountMintPerDuration);
        amountMintPerDuration = _newRewardMintAmt;
        emit RewardMintingAmt(_newRewardMintAmt);
    }

    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        return transferFromInternal(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) external nonReentrant returns (bool) {
        return approveInternal(_spender, _value);
    }
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowanceInternal(_owner, _spender);
    }
    function increaseApproval(address _spender, uint _addedValue) external nonReentrant returns (bool) {
        return increaseApprovalInternal(_spender, _addedValue);
    }
    function decreaseApproval(address _spender, uint _subtractedValue) external nonReentrant returns (bool) {
        return decreaseApprovalInternal(_spender, _subtractedValue);
    }
    function transfer(address _to, uint256 _value) external nonReentrant returns (bool) {
        return transferInternal(_to, _value);
    }
}