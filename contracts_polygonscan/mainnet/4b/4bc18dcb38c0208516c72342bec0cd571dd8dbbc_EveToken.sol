/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is IERC20, Context {

  mapping(address => uint256) internal balances; // must be internal

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view virtual override returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public virtual override returns (bool) {
    require(_value <= balances[_msgSender()]);
    require(_to != address(0));

    balances[_msgSender()] = balances[_msgSender()] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(_msgSender(), _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view virtual override returns (uint256) {
    return balances[_owner];
  }

}

abstract contract ERC20 is IERC20 {
  function allowance(address _owner, address _spender)
    public view virtual returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public virtual returns (bool);

  function approve(address _spender, uint256 _value) public virtual returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping(address => mapping(address => uint256)) internal allowed; // must be internal


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
    virtual 
    override
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][_msgSender()]);
    require(_to != address(0));

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    allowed[_from][_msgSender()] = allowed[_from][_msgSender()] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    allowed[_msgSender()][_spender] = _value;
    emit Approval(_msgSender(), _spender, _value);
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
    override
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[_msgSender()][_spender] = (
      allowed[_msgSender()][_spender] + _addedValue);
    emit Approval(_msgSender(), _spender, allowed[_msgSender()][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[_msgSender()][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[_msgSender()][_spender] = 0;
    } else {
      allowed[_msgSender()][_spender] = oldValue - _subtractedValue;
    }
    emit Approval(_msgSender(), _spender, allowed[_msgSender()][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(_msgSender() == owner());
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
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_ + _amount;
    balances[_to] = balances[_to] + _amount;
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

abstract contract ReleasableToken is MintableToken {

    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release it into the wild if the sale is a success. If false we are still in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
    mapping(address => bool) public transferAgents;

    /**
     * Limit token transfer until the crowdsale is over.
     *
     */
    modifier canTransfer(address _sender) {
        require(released || transferAgents[_sender], "For the token to be able to transfer: it's required that the crowdsale is in released state; or the sender is a transfer agent.");
        _;
    }

    /**
     * Set the contract that can call release and make the token transferable.
     *
     * Design choice. Allow reset the release agent to fix fat finger mistakes.
     */
    function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {

        // We don't do interface check here as we might want to a normal wallet address to act as a release agent
        releaseAgent = addr;
    }

    /**
     * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
     */
    function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
        transferAgents[addr] = state;
    }

    /**
     * One way function to release the tokens to the wild.
     *
     * Can be called only from the release agent that is the final sale contract. It is only called if the crowdsale has been success (first milestone reached).
     */
    function releaseTokenTransfer() public virtual onlyReleaseAgent {
        released = true;
    }

    /** The function can be called only before or after the tokens have been released */
    modifier inReleaseState(bool releaseState) {
        require(releaseState == released, "It's required that the state aligns with the released flag.");
        _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
        require(_msgSender() == releaseAgent, "Message sender is required to be a release agent.");
        _;
    }

    function transfer(address _to, uint _value) public override canTransfer(_msgSender()) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public override canTransfer(_from) returns (bool success) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

}

contract UpgradeableToken is ReleasableToken {


    /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
    address public upgradeMaster;

    /** The next contract where the tokens will be migrated. */
    UpgradeAgent public upgradeAgent;

    /** How many tokens we have upgraded by now. */
    uint256 public totalUpgraded;

    /**
     * Upgrade states.
     *
     * - NotAllowed: The child contract has not reached a condition where the upgrade can begin
     * - WaitingForAgent: Token allows upgrade, but we don't have a new agent yet
     * - ReadyToUpgrade: The agent is set and the balance holders can upgrade their tokens
     *
     */
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade}

    /**
     * Somebody has upgraded some of his tokens.
     */
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    /**
     * New upgrade agent available.
     */
    event UpgradeAgentSet(address agent);

    /**
     * Do not allow construction without upgrade master set.
     */
    constructor(address _upgradeMaster) {
        upgradeMaster = _upgradeMaster;
    }

    /**
     * Allow the token holder to upgrade some of their tokens to a new contract.
     */
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();

        require(state == UpgradeState.ReadyToUpgrade, "It's required that the upgrade state is ready.");

        // Validate input value.
        require(value > 0, "The upgrade value is required to be above 0.");

        balances[_msgSender()] = balances[_msgSender()] - value;

        // Take tokens out from circulation
        totalSupply_ = totalSupply_ - value;
        totalUpgraded = totalUpgraded + value;

        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(_msgSender(), value);
        emit Upgrade(_msgSender(), address(upgradeAgent), value);
    }

    /**
     * Set an upgrade agent that handles
     */
    function setUpgradeAgent(address agent) external {

        require(canUpgrade(), "It's required to be in canUpgrade() condition when setting upgrade agent.");

        require(agent != address(0), "Agent is required to be an non-empty address when setting upgrade agent.");

        // Only a master can designate the next agent
        require(_msgSender() == upgradeMaster, "Message sender is required to be the upgradeMaster when setting upgrade agent.");

        // Upgrade has already begun for an agent
        require(getUpgradeState() != UpgradeState.ReadyToUpgrade, "Upgrade state is required to not be upgrading when setting upgrade agent.");

        require(address(upgradeAgent) == address(0), "upgradeAgent once set, cannot be reset");

        upgradeAgent = UpgradeAgent(agent);

        // Bad interface
        require(upgradeAgent.isUpgradeAgent(), "The provided updateAgent contract is required to be compliant to the UpgradeAgent interface method when setting upgrade agent.");

        // Make sure that token supplies match in source and target
        require(upgradeAgent.originalSupply() == totalSupply_, "The provided upgradeAgent contract's originalSupply is required to be equivalent to existing contract's totalSupply_ when setting upgrade agent.");

        emit UpgradeAgentSet(address(upgradeAgent));
    }

    /**
     * Get the state of the token upgrade.
     */
    function getUpgradeState() public view returns (UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(upgradeAgent) == address(0)) return UpgradeState.WaitingForAgent;
        else return UpgradeState.ReadyToUpgrade;
    }

    /**
     * Change the upgrade master.
     *
     * This allows us to set a new owner for the upgrade mechanism.
     */
    function setUpgradeMaster(address master) public {
        require(master != address(0), "The provided upgradeMaster is required to be a non-empty address when setting upgrade master.");

        require(_msgSender() == upgradeMaster, "Message sender is required to be the original upgradeMaster when setting (new) upgrade master.");

        upgradeMaster = master;
    }

    bool canUpgrade_ = true;

    /**
     * Child contract can enable to provide the condition when the upgrade can begin.
     */
    function canUpgrade() public view virtual returns (bool) {
        return canUpgrade_;
    }

}

contract EveToken is UpgradeableToken {

    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;

    string public symbol;

    uint8 public decimals;

    address public secondarySaleReserveWallet;
    address public mainNetLaunchIncentiveReserveWallet;
    address public capitalReserveWallet;
    address public ecosystemGrantsReserveWallet;
    address public airdropReserveWallet;

    /**
     * Construct the token.
     *
     * This token must be created through a team multisig wallet, so that it is owned by that wallet.
     *
     * @param _name Token name
     * @param _symbol Token symbol - should be all caps
     * @param _initialSupply How many tokens we start with
     * @param _decimals Number of decimal places
     * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
     */
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, uint8 _decimals, bool _mintable,
        address _secondarySaleReserveWallet,
        address _mainNetLaunchIncentiveReserveWallet,
        address _capitalReserveWallet,
        address _ecosystemGrantsReserveWallet,
        address _airdropReserveWallet)
    UpgradeableToken(_msgSender()) {

        // Create any address, can be transferred
        // to team multisig via changeOwner(),
        // also remember to call setUpgradeMaster()
        // owner() = _msgSender();
        releaseAgent = owner();

        name = _name;
        symbol = _symbol;

        decimals = _decimals;

        secondarySaleReserveWallet = _secondarySaleReserveWallet;
        mainNetLaunchIncentiveReserveWallet = _mainNetLaunchIncentiveReserveWallet;
        capitalReserveWallet = _capitalReserveWallet;
        ecosystemGrantsReserveWallet = _ecosystemGrantsReserveWallet;
        airdropReserveWallet = _airdropReserveWallet;

        if (_initialSupply > 0) {
            require((_initialSupply % 10) == 0, "_initialSupply has to be a mulitple of 10");
            uint256 thirtyPerCent = (_initialSupply * 3) / 10;
            uint256 twentyPerCent = (_initialSupply * 2) / 10;
            uint256 tenPerCent = _initialSupply / 10;

            mint(secondarySaleReserveWallet, thirtyPerCent);

            mint(mainNetLaunchIncentiveReserveWallet, twentyPerCent);

            mint(capitalReserveWallet, twentyPerCent);

            mint(ecosystemGrantsReserveWallet, twentyPerCent);

            mint(airdropReserveWallet, tenPerCent);

        }

        // No more new supply allowed after the token creation
        if (!_mintable) {
            finishMinting();
            require(totalSupply_ > 0, "Total supply is required to be above 0 if the token is not mintable.");
        }

    }

    /**
     * When token is released to be transferable, enforce no new tokens can be created.
     */
    function releaseTokenTransfer() public override onlyReleaseAgent {
        mintingFinished = true;
        super.releaseTokenTransfer();
    }

    /**
     * Allow upgrade agent functionality kick in only if the crowdsale was success.
     */
    function canUpgrade() public view override returns (bool) {
        return released && super.canUpgrade();
    }

    // Total supply
    function totalSupply() public view override returns (uint) {
        return totalSupply_ - balances[address(0)];
    }

}

abstract contract UpgradeAgent {

    uint public originalSupply;

    /** Interface marker */
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) virtual public;

}