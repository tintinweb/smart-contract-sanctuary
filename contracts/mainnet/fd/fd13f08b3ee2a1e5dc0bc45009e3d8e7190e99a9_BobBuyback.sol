pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}
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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="05776068666a4537">[email&#160;protected]</span>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param _contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20;

  /**
   * @dev Reclaim all ERC20 compatible tokens
   * @param _token ERC20 The address of the token contract
   */
  function reclaimToken(ERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

/**
 * Automated buy back BOB tokens
 */
contract BobBuyback is Claimable, HasNoContracts, CanReclaimToken, Destructible {
    using SafeMath for uint256;    

    ERC20 public token;                 //Address of BOB token contract
    uint256 public maxGasPrice;         //Highest gas price allowed for buyback transaction
    uint256 public maxTxValue;          //Highest amount of BOB sent in one transaction
    uint256 public roundStartTime;      //Timestamp when buyback starts (timestamp of the first block where buyback allowed)
    uint256 public rate;                //1 ETH = rate BOB

    event Buyback(address indexed from, uint256 amountBob, uint256 amountEther);

    constructor(ERC20 _token, uint256 _maxGasPrice, uint256 _maxTxValue) public {
        token = _token;
        maxGasPrice = _maxGasPrice;
        maxTxValue = _maxTxValue;
        roundStartTime = 0;
        rate = 0;
    }

    /**
     * @notice Somebody may call this to sell his tokens
     * @param _amount How much tokens to sell
     * Call to token.approve() required before calling this function
     */
    function buyback(uint256 _amount) external {
        require(tx.gasprice <= maxGasPrice);
        require(_amount <= maxTxValue);
        require(isRunning());

        uint256 amount = _amount;
        uint256 reward = calcReward(amount);

        if(address(this).balance < reward) {
            //If not enough money to fill request, handle it partially
            reward = address(this).balance;
            amount = reward.mul(rate);
        }

        require(token.transferFrom(msg.sender, address(this), amount));
        msg.sender.transfer(reward);
        emit Buyback(msg.sender, amount, reward);
    }

    /**
     * @notice Calculates how much ETH somebody can receive for selling amount BOB
     * @param amount How much tokens to sell
     */
    function calcReward(uint256 amount) view public returns(uint256) {
        if(rate == 0) return 0;     //Handle situation when no Buyback is planned
        return amount.div(rate);    //This operation may result in rounding. Which is fine here (rounded  amount < rate / 10**18)
    }

    /**
     * @notice Calculates how much BOB tokens this contract can buy (during current buyback round)
     */
    function calcTokensAvailableToBuyback() view public returns(uint256) {
        return address(this).balance.mul(rate);
    }

    /**
     * @notice Checks if Buyback round is running
     */
    function isRunning() view public returns(bool) {
        return (rate > 0) && (now >= roundStartTime) && (address(this).balance > 0);
    }

    /**
     * @notice Changes buyback parameters
     * @param _maxGasPrice Max gas price one ca use to sell is tokens. 
     * @param _maxTxValue Max amount of tokens to sell in one transaction
     */
    function setup(uint256 _maxGasPrice, uint256 _maxTxValue) onlyOwner external {
        maxGasPrice = _maxGasPrice;
        maxTxValue = _maxTxValue;
    }

    /**
     * @notice Starts buyback at specified time, with specified rate
     * @param _roundStartTime Time when Buyback round starts
     * @param _rate Rate of current Buyback round (1 ETH = rate BOB). Zero means no buyback is planned.
     */
    function startBuyback(uint256 _roundStartTime, uint256 _rate) onlyOwner external payable {
        require(_roundStartTime > now);
        roundStartTime = _roundStartTime;
        rate = _rate;   //Rate is not required to be > 0
    }

    /**
     * @notice Claim all BOB tokens stored on the contract and send them to owner
     */
    function claimTokens() onlyOwner external {
        require(token.transfer(owner, token.balanceOf(address(this))));
    }
    /**
     * @notice Claim some of tokens stored on the contract
     * @param amount How much tokens to claim
     * @param beneficiary Who to send this tokens
     */
    function claimTokens(uint256 amount, address beneficiary) onlyOwner external {
        require(token.transfer(beneficiary, amount));
    }

    /**
    * @notice Transfer all Ether held by the contract to the owner.
    */
    function reclaimEther()  onlyOwner external {
        owner.transfer(address(this).balance);
    }

}