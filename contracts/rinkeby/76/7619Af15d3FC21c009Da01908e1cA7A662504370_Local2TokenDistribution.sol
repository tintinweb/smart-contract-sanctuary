pragma solidity 0.5.4;

import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";

/**
 * @title Contract for Rewards Token
 * Copyright 2021
 */

contract Local2Token is Ownable {
    using SafeMath for uint;

    string public constant symbol = 'Local2';
    string public constant name = 'Local2';
    uint8 public constant decimals = 18;

    uint256 public constant hardCap = 5 * (10 ** (18 + 8)) ; //500M tokens. Max amount of tokens which can be minted
    uint256 public totalSupply;

    bool public mintingFinished = false;
    bool public frozen = true;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event NewToken(address indexed _token);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _burner, uint _burnedAmount);
    event Revoke(address indexed _from, uint256 _value);
    event MintFinished();
    event MintStarted();
    event Freeze();
    event Unfreeze();

    modifier canMint() {
        require(!mintingFinished, "Minting was already finished");
        _;
    }

    modifier canTransfer() {
        require(msg.sender == owner || !frozen, "Tokens could not be transferred");
        _;
    }

    constructor () public {
        emit NewToken(address(this));
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(totalSupply.add(_amount) <= hardCap);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev Function to start minging new tokens.
     * @return True if the operation was successful
     */
    function startMinting() public onlyOwner returns (bool) {
        require(mintingFinished);
        mintingFinished = false;
        emit MintStarted();
        return true;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(_value <= balances[msg.sender], "Insufficient balance");

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(_value <= balances[_from], "Insufficient Balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient Allowance");

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

    /** 
     * @dev Burn tokens from an address
     * @param _burnAmount The amount of tokens to burn
     */
    function burn(uint _burnAmount) public {
        require(_burnAmount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_burnAmount);
        totalSupply = totalSupply.sub(_burnAmount);
        emit Burned(msg.sender, _burnAmount);
    }

    /**
     * @dev Revokes minted tokens
     * @param _from The address whose tokens are revoked
     * @param _value The amount of token to revoke
     */
    function revoke(address _from, uint256 _value) public onlyOwner returns (bool) {
        require(_value <= balances[_from]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Revoke(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }

    /**
     * @dev Freeze tokens
     */
    function freeze() public onlyOwner {
        require(!frozen);
        frozen = true;
        emit Freeze();
    }

    /**
     * @dev Unfreeze tokens 
     */
    function unfreeze() public onlyOwner {
        require(frozen);
        frozen = false;
        emit Unfreeze();
    }
}

pragma solidity 0.5.4;

import "./Local2Token.sol";
import "./VestingVault.sol";
import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";

/**
 * @title Contract for distribution of tokens
 * Copyright 2021
 */
contract Local2TokenDistribution is Ownable {
    using SafeMath for uint256;

    Local2Token public token;
    VestingVault public vestingVault;

    bool public finished;

    event TokenMinted(address indexed _to, uint _value, string _id);
    event RevokeTokens(address indexed _from, uint _value);
    event MintingFinished();

    modifier isAllowed() {
        require(finished == false, "Minting was already finished");
        _;
    }

    /**
     * @dev Constructor
     * @param _token Contract address of Local2Token
     * @param _vestingVault Contract address of VestingVault
     */
    constructor (
        Local2Token _token,
        VestingVault _vestingVault
    ) public {
        require(address(_token) != address(0), "Address should not be zero");
        require(address(_vestingVault) != address(0), "Address should not be zero");

        token = _token;
        vestingVault = _vestingVault;
        finished = false;
    }

    /**
     * @dev Function to allocate tokens for normal contributor
     * @param _to Address of a contributor
     * @param _value Value that represents tokens amount allocated for a contributor
     */
    function allocNormalUser(address _to, uint _value) public onlyOwner isAllowed {
        token.mint(_to, _value);
        emit TokenMinted(_to, _value, "Allocated Tokens To User");
    }

    /**
     * @dev Function to allocate tokens for vested contributor
     * @param _to Withdraw address that tokens will be sent
     * @param _value Amount to hold during vesting period
     * @param _start Unix epoch time that vesting starts from
     * @param _duration Seconds amount of vesting duration
     * @param _cliff Seconds amount of vesting cliff
     * @param _scheduleTimes Array of Unix epoch times for vesting schedules
     * @param _scheduleValues Array of Amount for vesting schedules
     * @param _level Indicator that will represent types of vesting
     */
    function allocVestedUser(
        address _to, uint _value, uint _start, uint _duration, uint _cliff, uint[] memory _scheduleTimes,
        uint[] memory _scheduleValues, uint _level) public onlyOwner isAllowed {
        _value = vestingVault.grant(_to, _value, _start, _duration, _cliff, _scheduleTimes, _scheduleValues, _level);
        token.mint(address(vestingVault), _value);
        emit TokenMinted(_to, _value, "Allocated Vested Tokens To User");
    }

    /**
     * @dev Function to allocate tokens for normal contributors
     * @param _holders Address of a contributor
     * @param _amounts Value that represents tokens amount allocated for a contributor
     */
    function allocNormalUsers(address[] memory _holders, uint[] memory _amounts) public onlyOwner isAllowed {
        require(_holders.length > 0, "Empty holder addresses");
        require(_holders.length == _amounts.length, "Invalid arguments");
        for (uint i = 0; i < _holders.length; i++) {
            token.mint(_holders[i], _amounts[i]);
            emit TokenMinted(_holders[i], _amounts[i], "Allocated Tokens To Users");
        }
    }

    /**
     * @dev Function to revoke tokens from an address
     */
    function revokeTokensFromVestedUser(address _from, uint _amount) public onlyOwner {
        vestingVault.revokeTokens(_from, _amount);
        emit RevokeTokens(_from, _amount);
    }

    /**
     * @dev Function to get back Ownership of Token Contract after minting finished
     */
    function transferBackTokenOwnership() public onlyOwner {
        token.transferOwnership(owner);
    }

    /**
     * @dev Function to get back Ownership of VestingVault Contract after minting finished
     */
    function transferBackVestingVaultOwnership() public onlyOwner {
        vestingVault.transferOwnership(owner);
    }

    /**
     * @dev Function to finish token distribution
     */
    function finalize() public onlyOwner {
        token.finishMinting();
        finished = true;
        emit MintingFinished();
    }
}

pragma solidity 0.5.4;

import './Local2Token.sol';
/**
 * @title Contract that will hold vested tokens;
 * @notice Tokens for vested contributors will be hold in this contract and token holders
 * will claim their tokens according to their own vesting timelines.
 * Copyright 2021
 */
contract VestingVault is Ownable {
    using SafeMath for uint256;

    struct Grant {
        uint value;
        uint vestingStart;
        uint vestingCliff;
        uint vestingDuration;
        uint[] scheduleTimes;
        uint[] scheduleValues;
        uint level;              // 1: frequency, 2: schedules
        uint transferred;
    }

    Local2Token public token;

    mapping(address => Grant) public grants;

    uint public totalVestedTokens;
    // array of vested users addresses
    address[] public vestedAddresses;
    bool public locked;

    event NewGrant (address _to, uint _amount, uint _start, uint _duration, uint _cliff, uint[] _scheduleTimes,
        uint[] _scheduleAmounts, uint _level);
    event NewRelease(address _holder, uint _amount);
    event WithdrawAll(uint _amount);
    event BurnTokens(uint _amount);
    event LockedVault();

    modifier isOpen() {
        require(locked == false, "Vault is already locked");
        _;
    }

    constructor (Local2Token _token) public {
        require(address(_token) != address(0), "Token address should not be zero");

        token = _token;
        locked = false;
    }

    /**
     * @return address[] that represents vested addresses;
     */
    function returnVestedAddresses() public view returns (address[] memory) {
        return vestedAddresses;
    }

    /**
     * @return grant that represents vested info for specific user;
     */
    function returnGrantInfo(address _user)
    public view returns (uint, uint, uint, uint, uint[] memory, uint[] memory, uint, uint) {
        require(_user != address(0), "Address should not be zero");
        Grant storage grant = grants[_user];

        return (grant.value, grant.vestingStart, grant.vestingCliff, grant.vestingDuration, grant.scheduleTimes,
        grant.scheduleValues, grant.level, grant.transferred);
    }

    /**
     * @dev Add vested contributor information
     * @param _to Withdraw address that tokens will be sent
     * @param _value Amount to hold during vesting period
     * @param _start Unix epoch time that vesting starts from
     * @param _duration Seconds amount of vesting duration
     * @param _cliff Seconds amount of vesting cliffHi
     * @param _scheduleTimes Array of Unix epoch times for vesting schedules
     * @param _scheduleValues Array of Amount for vesting schedules
     * @param _level Indicator that will represent types of vesting
     * @return Int value that represents granted token amount
     */
    function grant(
        address _to, uint _value, uint _start, uint _duration, uint _cliff, uint[] memory _scheduleTimes,
        uint[] memory _scheduleValues, uint _level) public onlyOwner isOpen returns (uint256) {
        require(_to != address(0), "Address should not be zero");
        require(_level == 1 || _level == 2, "Invalid vesting level");
        // make sure a single address can be granted tokens only once.
        require(grants[_to].value == 0, "Already added to vesting vault");

        if (_level == 2) {
            require(_scheduleTimes.length == _scheduleValues.length, "Schedule Times and Values should be matched");
            _value = 0;
            for (uint i = 0; i < _scheduleTimes.length; i++) {
                require(_scheduleTimes[i] > 0, "Seconds Amount of ScheduleTime should be greater than zero");
                require(_scheduleValues[i] > 0, "Amount of ScheduleValue should be greater than zero");
                if (i > 0) {
                    require(_scheduleTimes[i] > _scheduleTimes[i - 1], "ScheduleTimes should be sorted by ASC");
                }
                _value = _value.add(_scheduleValues[i]);
            }
        }

        require(_value > 0, "Vested amount should be greater than zero");

        grants[_to] = Grant({
            value : _value,
            vestingStart : _start,
            vestingDuration : _duration,
            vestingCliff : _cliff,
            scheduleTimes : _scheduleTimes,
            scheduleValues : _scheduleValues,
            level : _level,
            transferred : 0
            });

        vestedAddresses.push(_to);
        totalVestedTokens = totalVestedTokens.add(_value);

        emit NewGrant(_to, _value, _start, _duration, _cliff, _scheduleTimes, _scheduleValues, _level);
        return _value;
    }

    /**
     * @dev Get token amount for a token holder available to transfer at specific time
     * @param _holder Address that represents holder's withdraw address
     * @param _time Unix epoch time at the moment
     * @return Int value that represents token amount that is available to release at the moment
     */
    function transferableTokens(address _holder, uint256 _time) public view returns (uint256) {
        Grant storage grantInfo = grants[_holder];

        if (grantInfo.value == 0) {
            return 0;
        }
        return calculateTransferableTokens(grantInfo, _time);
    }

    /**
     * @dev Internal function to calculate available amount at specific time
     * @param _grant Grant that represents holder's vesting info
     * @param _time Unix epoch time at the moment
     * @return Int value that represents available vested token amount
     */
    function calculateTransferableTokens(Grant memory _grant, uint256 _time) private pure returns (uint256) {
        uint totalVestedAmount = _grant.value;
        uint totalAvailableVestedAmount = 0;

        if (_grant.level == 1) {
            if (_time < _grant.vestingCliff.add(_grant.vestingStart)) {
                return 0;
            } else if (_time >= _grant.vestingStart.add(_grant.vestingDuration)) {
                return _grant.value;
            } else {
                totalAvailableVestedAmount =
                totalVestedAmount.mul(_time.sub(_grant.vestingStart)).div(_grant.vestingDuration);
            }
        } else {
            if (_time < _grant.scheduleTimes[0]) {
                return 0;
            } else if (_time >= _grant.scheduleTimes[_grant.scheduleTimes.length - 1]) {
                return _grant.value;
            } else {
                for (uint i = 0; i < _grant.scheduleTimes.length; i++) {
                    if (_grant.scheduleTimes[i] <= _time) {
                        totalAvailableVestedAmount = totalAvailableVestedAmount.add(_grant.scheduleValues[i]);
                    } else {
                        break;
                    }
                }
            }
        }

        return totalAvailableVestedAmount;
    }

    /**
     * @dev Claim vested token
     * @notice this will be eligible after vesting start + cliff or schedule times
     */
    function claim() public {
        address beneficiary = msg.sender;
        Grant storage grantInfo = grants[beneficiary];
        require(grantInfo.value > 0, "Grant does not exist");

        uint256 vested = calculateTransferableTokens(grantInfo, now);
        require(vested > 0, "There is no vested tokens");

        uint256 transferable = vested.sub(grantInfo.transferred);
        require(transferable > 0, "There is no remaining balance for this address");
        require(token.balanceOf(address(this)) >= transferable, "Contract Balance is insufficient");

        grantInfo.transferred = grantInfo.transferred.add(transferable);
        totalVestedTokens = totalVestedTokens.sub(transferable);

        token.transfer(beneficiary, transferable);
        emit NewRelease(beneficiary, transferable);
    }

    /**
     * @dev Function to revoke tokens from each Accounts
     */
    function revokeTokens(address _from, uint amount) public onlyOwner {
        // finally transfer all remaining tokens to owner
        Grant storage grantInfo = grants[_from];
        require(grantInfo.value > 0, "Grant does not exist");

        uint256 revocable = grantInfo.value.sub(grantInfo.transferred);
        require(revocable > 0, "There is no remaining balance for this address");
        require(revocable >= amount, "Revocable balance is insufficient");
        require(token.balanceOf(address(this)) >= amount, "Contract Balance is insufficient");

        grantInfo.value = grantInfo.value.sub(amount);
        totalVestedTokens = totalVestedTokens.sub(amount);

        token.burn(amount);
        emit BurnTokens(amount);
    }

    /**
     * @dev Function to burn remaining tokens
     */
    function burnRemainingTokens() public onlyOwner {
        // finally transfer all remaining tokens to owner
        uint amount = token.balanceOf(address(this));

        token.burn(amount);
        emit BurnTokens(amount);
    }

    /**
     * @dev Function to withdraw remaining tokens;
     */
    function withdraw() public onlyOwner {
        // finally withdraw all remaining tokens to owner
        uint amount = token.balanceOf(address(this));
        token.transfer(owner, amount);

        emit WithdrawAll(amount);
    }

    /**
     * @dev Function to lock vault not to be able to alloc more
     */
    function lockVault() public onlyOwner {
        // finally lock vault
        require(!locked);
        locked = true;
        emit LockedVault();
    }
}

pragma solidity 0.5.4;

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
    constructor () public {
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

}

pragma solidity 0.5.4;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}