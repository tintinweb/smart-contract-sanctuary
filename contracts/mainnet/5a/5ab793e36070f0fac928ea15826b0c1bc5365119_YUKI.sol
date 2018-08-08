pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address & authority addresses, and provides basic
 * authorization control functions, this simplifies the implementation of user permissions.
 */
contract Ownable {
  address public owner;
  bool public canRenounce = false;
  mapping (address => bool) public authorities;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AuthorityAdded(address indexed authority);
  event AuthorityRemoved(address indexed authority);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
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
   * @dev Throws if called by any account other than the authority or owner.
   */
  modifier onlyAuthority() {
      require(msg.sender == owner || authorities[msg.sender]);
      _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function enableRenounceOwnership() onlyOwner public {
    canRenounce = true;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) onlyOwner public {
    if(!canRenounce){
      require(_newOwner != address(0));
    }
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  /**
   * @dev Adds authority to execute several functions to subOwner.
   * @param _authority The address to add authority to.
   */

  function addAuthority(address _authority) onlyOwner public {
    authorities[_authority] = true;
    emit AuthorityAdded(_authority);
  }


  /**
   * @dev Removes authority to execute several functions from subOwner.
   * @param _authority The address to remove authority from.
   */

  function removeAuthority(address _authority) onlyOwner public {
    authorities[_authority] = false;
    emit AuthorityRemoved(_authority);
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
 * @title ERC223
 * @dev ERC223 contract interface with ERC20 functions and events
 *      Fully backward compatible with ERC20
 *      Recommended implementation used at https://github.com/Dexaran/ERC223-token-standard/tree/Recommended
 */
contract ERC223 {
    uint public totalSupply;

    // ERC223 and ERC20 functions and events
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



/**
 * @title ContractReceiver
 * @dev Contract that is working with ERC223 tokens
 */
 contract ContractReceiver {
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) external;
}




/**
 * @title YUKI
 * @author YUKI_Hayate and NANJ_Shimokawa
 * @dev YUKI is an ERC223 Token with ERC20 functions and events
 *      Fully backward compatible with ERC20
 */
contract YUKI is ERC223, Ownable, Pausable {
    using SafeMath for uint256;

    string public name = "YUKI";
    string public symbol = "YUKI";
    uint8 public decimals = 8;
    uint256 public totalSupply = 20e9 * 1e8;
    uint256 public codeSize = 0;
    bool public mintingFinished = false;

    address public initialMarketSales = 0x1b879912446d844Fb5915bf4f773F0Db9Cd16ADb;
    address public incentiveForHolder = 0x0908e3Df5Ed1E67D2AaF38401d4826B2879e8f4b;
    address public developmentFunds = 0x52F018dc3dd621c8b2D649AC0e22E271a0dE049e;
    address public marketingFunds = 0x6771a091C97c79a52c8DD5d98A59c5d3B27F99aA;
    address public organization = 0xD90E1f987252b8EA71ac1cF14465FE9A3803267F;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public cannotSend;
    mapping (address => bool) public cannotReceive;
    mapping (address => uint256) public cannotSendUntil;
    mapping (address => uint256) public cannotReceiveUntil;

    event FrozenFunds(address indexed target, bool cannotSend, bool cannotReceive);
    event LockedFunds(address indexed target, uint256 cannotSendUntil, uint256 cannotReceiveUntil);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * @dev Constructor is called only once and can not be called again
     */
    constructor() public {
        owner = msg.sender;

        balanceOf[initialMarketSales] = totalSupply.mul(45).div(100);
        balanceOf[incentiveForHolder] = totalSupply.mul(5).div(100);
        balanceOf[developmentFunds] = totalSupply.mul(20).div(100);
        balanceOf[marketingFunds] = totalSupply.mul(175).div(1000);
        balanceOf[organization] = totalSupply.mul(125).div(1000);
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
    /**
     * @dev Prevent targets from sending or receiving tokens
     * @param targets Addresses to be frozen
     * @param _cannotSend Whether to prevent targets from sending tokens or not
     * @param _cannotReceive Whether to prevent targets from receiving tokens or not
     */
    function freezeAccounts(address[] targets, bool _cannotSend, bool _cannotReceive) onlyOwner public {
        require(targets.length > 0);

        for (uint i = 0; i < targets.length; i++) {
            cannotSend[targets[i]] = _cannotSend;
            cannotReceive[targets[i]] = _cannotReceive;
            emit FrozenFunds(targets[i], _cannotSend, _cannotReceive);
        }
    }

    /**
     * @dev Prevent targets from sending or receiving tokens by setting Unix time
     * @param targets Addresses to be locked funds
     * @param _cannotSendUntil Unix time when locking up sending function will be finished
     * @param _cannotReceiveUntil Unix time when locking up receiving function will be finished
     */
    function lockupAccounts(address[] targets, uint256 _cannotSendUntil, uint256 _cannotReceiveUntil) onlyOwner public {
        require(targets.length > 0);

        for(uint i = 0; i < targets.length; i++){
            require(cannotSendUntil[targets[i]] <= _cannotSendUntil
                    && cannotReceiveUntil[targets[i]] <= _cannotReceiveUntil);

            cannotSendUntil[targets[i]] = _cannotSendUntil;
            cannotReceiveUntil[targets[i]] = _cannotReceiveUntil;
            emit LockedFunds(targets[i], _cannotSendUntil, _cannotReceiveUntil);
        }
    }

    /**
     * @dev Function that is called when a user or another contract wants to transfer funds
     */
    function transfer(address _to, uint _value, bytes _data) whenNotPaused public returns (bool success) {
        require(_value > 0
                && cannotSend[msg.sender] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[msg.sender]
                && now > cannotReceiveUntil[_to]);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /**
     * @dev Standard function transfer similar to ERC20 transfer with no _data
     *      Added due to backwards compatibility reasons
     */
    function transfer(address _to, uint _value) whenNotPaused public returns (bool success) {
        require(_value > 0
                && cannotSend[msg.sender] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[msg.sender]
                && now > cannotReceiveUntil[_to]);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

 /**
   * @dev Returns whether the target address is a contract
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > codeSize ;
  }

    function setCodeSize(uint256 _codeSize) onlyOwner public {
        codeSize = _codeSize;
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     *      Added due to backwards compatibility with ERC20
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && cannotSend[msg.sender] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[msg.sender]
                && now > cannotReceiveUntil[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Allows _spender to spend no more than _value tokens in your behalf
     *      Added due to backwards compatibility with ERC20
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     *      Added due to backwards compatibility with ERC20
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _from The address that will burn the tokens.
     * @param _unitAmount The amount of token to be burned.
     */
    function burn(address _from, uint256 _unitAmount) onlyOwner public {
        require(_unitAmount > 0
                && balanceOf[_from] >= _unitAmount);

        balanceOf[_from] = balanceOf[_from].sub(_unitAmount);
        totalSupply = totalSupply.sub(_unitAmount);
        emit Burn(_from, _unitAmount);
        emit Transfer(_from, address(0), _unitAmount);

    }
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _unitAmount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
        require(_unitAmount > 0);

        totalSupply = totalSupply.add(_unitAmount);
        balanceOf[_to] = balanceOf[_to].add(_unitAmount);
        emit Mint(_to, _unitAmount);
        emit Transfer(address(0), _to, _unitAmount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev Function to distribute tokens to the list of addresses by the provided amount
     */
    function batchTransfer(address[] addresses, uint256 amount) whenNotPaused public returns (bool) {
        require(amount > 0
                && addresses.length > 0
                && cannotSend[msg.sender] == false
                && now > cannotSendUntil[msg.sender]);

        amount = amount.mul(1e8);
        uint256 totalAmount = amount.mul(addresses.length);
        require(balanceOf[msg.sender] >= totalAmount);

        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0)
                    && cannotReceive[addresses[i]] == false
                    && now > cannotReceiveUntil[addresses[i]]);

            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amount);
            emit Transfer(msg.sender, addresses[i], amount);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    function batchTransfer(address[] addresses, uint[] amounts) whenNotPaused public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && cannotSend[msg.sender] == false
                && now > cannotSendUntil[msg.sender]);

        uint256 totalAmount = 0;

        for(uint i = 0; i < addresses.length; i++){
            require(amounts[i] > 0
                    && addresses[i] != address(0)
                    && cannotReceive[addresses[i]] == false
                    && now > cannotReceiveUntil[addresses[i]]);

            amounts[i] = amounts[i].mul(1e8);
            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amounts[i]);
            totalAmount = totalAmount.add(amounts[i]);
            emit Transfer(msg.sender, addresses[i], amounts[i]);
        }

        require(balanceOf[msg.sender] >= totalAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }


    /**
     * @dev Function to transfer tokens between addresses, only for Owner & subOwner
     */

    function transferFromTo(address _from, address _to, uint256 _value, bytes _data) onlyAuthority public returns (bool) {
        require(_value > 0
                && balanceOf[_from] >= _value
                && cannotSend[_from] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[_from]
                && now > cannotReceiveUntil[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        if(isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(_from, _value, _data);
        }
        emit Transfer(_from, _to, _value, _data);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFromTo(address _from, address _to, uint256 _value) onlyAuthority public returns (bool) {
        bytes memory empty;
        return transferFromTo(_from, _to, _value, empty);
    }

    /**
     * @dev fallback function
     */
    function() payable public {
        revert();
    }

    /**
     * @dev Reject all ERC223 compatible tokens
     * @param from_ address The address that is transferring the tokens
     * @param value_ uint256 the amount of the specified token
     * @param data_ Bytes The data passed from the caller.
     */
    function tokenFallback(address from_, uint256 value_, bytes data_) external pure {
        from_;
        value_;
        data_;
        revert();
    }
}