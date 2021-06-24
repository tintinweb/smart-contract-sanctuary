/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

abstract contract Ownable {
    address public owner;

    /**
     * @dev IMPR manager feature
     */

    mapping(address => bool) public managers;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * @dev IMPR refactored contract definition to comply with 0.8.5
     * account.
     */

    constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ownerOrManager(){
        require(managers[msg.sender] == true || msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    /**
   * @dev IMPR Allows the current owner to toggle manager status of an address
   * @param target The address to transfer ownership to.
   * @param status toggling manager status
   */

    function toggleManager(address target, bool status) public onlyOwner{
        managers[target] = status;
    }

    /**
   * @dev IMPR Check if user is manager
   * @param target The address to check if they are the manager.
   * @return status Manager status of the user in question
   */
    function isManager(address target) public view returns(bool status){
        return managers[target];
    }

    /**
    * @dev IMPR allows a manager to resign
    */

    function resignAsManager() public {
        managers[msg.sender] = false;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev IMPR refactored contract definition to comply with 0.8.5
 */
abstract contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address who) public virtual view returns (uint);
    function transfer(address to, uint value) public virtual returns(bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev IMPR refactored contract definition to comply with 0.8.5
 */
abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual view returns (uint);
    function transferFrom(address from, address to, uint value) public virtual returns(bool success);
    function approve(address spender, uint value) public virtual returns(bool success);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * @dev IMPR refactored contract definition to comply with 0.8.5
 */
abstract contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @dev IMPR changed return to comply with newer ERC20
    * @return success 
    */
    function transfer(address _to, uint _value) public virtual override onlyPayloadSize(2 * 32) returns(bool success){
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);

        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return balance An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public virtual override view returns (uint balance) {
        return balances[_owner];
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 * @dev IMPR refactored contract definition to comply with 0.8.5
 */
abstract contract StandardToken is BasicToken, ERC20 {

    /* @dev IMPR imported SafeMath to be used in implementation */
    using SafeMath for uint;

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    * @return success added for newer ERC20 compliance
    */
    function transferFrom(address _from, address _to, uint _value) public virtual override onlyPayloadSize(3 * 32) returns(bool success){
        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit  Transfer(_from, _to, sendAmount);

        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    * @return success added for newer ERC20 compliance.
    */
    function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) returns(bool success){

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return remaining A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public override view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev IMPR refactored contract definition to comply with 0.8.5
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

abstract contract BlackList is Ownable, BasicToken {
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;

    /**
   * @dev IMPR amend to check if the blacklisted user is a manager or the owner.
   * @dev IMPR changed onlyOwner modifier to ownerOrManager.
   */
    function addBlackList (address _evilUser) public ownerOrManager {
        require(_evilUser != owner);
        require(isManager(_evilUser) == false);
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    /**
   * @dev IMPR changed modifier to ownerOrManager from onlyOwner
   */
    function removeBlackList (address _clearedUser) public ownerOrManager {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    /**
   * @dev IMPR changed modifier to ownerOrManager from onlyOwner
   */
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}



/**
 * @dev IMPR refactored contract definition to comply with 0.8.5
 */
abstract contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint value) public virtual returns(bool success);
    function transferFromByLegacy(address sender, address from, address spender, uint value) public virtual returns(bool success);
    function approveByLegacy(address from, address spender, uint value) public virtual returns(bool success);
}

contract ImperiumToken is Pausable, StandardToken, BlackList
{
    //ERC20 standard requirements
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    //Deprecation attributes
    address public upgradedAddress;
    bool public deprecated;


    /* constructor */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_)
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = initialSupply_;
        balances[owner] = initialSupply_;
    }

    /* Core Attributes Getters */
    function name() public view returns(string memory)
    {
        return _name;
    }

    function symbol() public view returns(string memory)
    {
        return _symbol;
    }

    function decimals() public view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256)
    {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    /* Core Attributes Getters - Remote Accounts */
    function balanceOf(address _owner) public override view returns (uint256)
    {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(_owner);
        } else {
            return super.balanceOf(_owner);
        }
    }

    /* Transfer Methods */
    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool)
    {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused returns (bool)
    {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function approve(address _spender, uint256 _value) public override onlyPayloadSize(2 * 32) returns (bool)
    {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function mint(uint256 _value) public onlyOwner returns(bool)
    {
        balances[owner] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), owner, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns(bool)
    {
        require(balances[owner] >= _value);
        balances[owner] -= _value;
        emit Transfer(owner, address(0), _value);
        return true;
    }

    function mintFor(address _for, uint256 _value) public onlyOwner returns(bool)
    {
        balances[_for] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _for, _value);
        return true;
    }

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);
    event Deprecate(address newAddress);
}