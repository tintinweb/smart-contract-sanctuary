pragma solidity ^0.4.24;


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(msg.sender != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
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
   * https://github.com/OpenZeppelin
   * openzeppelin-solidity/contracts/ownership/Ownable.sol
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


contract HiGold is StandardToken, Ownable {

    /*** SAFEMATH ***/
    using SafeMath for uint256;

    /*** EVENTS ***/
    event Deposit(address indexed manager, address indexed user, uint value);
    event Withdrawl(address indexed manager, address indexed user, uint value);

    /*** CONSTANTS ***/
    // ERC20
    string public name = "HiGold Community Token";
    string public symbol = "HIG";
    uint256 public decimals = 18;

    /*** STORAGE ***/
    // HiGold Standard
    uint256 public inVaults;
    address public miner;
    mapping (address => mapping (address => uint256)) inVault;

    /*** MODIFIERS  ***/
    modifier onlyMiner() {
        require(msg.sender == miner);
        _;
    }

    /*** FUNCTIONS ***/
    // Constructor function
    constructor() public {
        totalSupply = 105 * (10 ** 26);
        balances[msg.sender] = totalSupply;
    }

    // Public functions
    function totalInVaults() public constant returns (uint256 amount) {
        return inVaults;
    }

    function balanceOfOwnerInVault
    (
        address _vault,
        address _owner
    )
        public
        constant
        returns (uint256 balance)
    {
        return inVault[_vault][_owner];
    }

    function deposit
    (
        address _vault,
        uint256 _value
    )
        public
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        inVaults = inVaults.add(_value);
        inVault[_vault][msg.sender] = inVault[_vault][msg.sender].add(_value);
        emit Deposit(_vault, msg.sender, _value);
        return true;
    }

    function withdraw
    (
        address _vault,
        uint256 _value
    )
        public
        returns (bool)
    {
        inVault[_vault][msg.sender] = inVault[_vault][msg.sender].sub(_value);
        inVaults = inVaults.sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        emit Withdrawl(_vault, msg.sender, _value);
        return true;
    }

    function accounting
    (
        address _credit, // -
        address _debit, // +
        uint256 _value
    )
        public
        returns (bool)
    {
        inVault[msg.sender][_credit] = inVault[msg.sender][_credit].sub(_value);
        inVault[msg.sender][_debit] = inVault[msg.sender][_debit].add(_value);
        return true;
    }

    /// For Mining
    function startMining(address _minerContract) public  onlyOwner {
        require(miner == address(0));
        miner = _minerContract;
        inVault[miner][miner] = 105 * (10 ** 26);
    }
    //// Update contract overview infomations when new token mined.
    function update(uint _value) public onlyMiner returns(bool) {
        totalSupply = totalSupply.add(_value);
        inVaults = inVaults.add(_value);
        return true;
    }

}