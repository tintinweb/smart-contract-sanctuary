pragma solidity ^0.4.24;

pragma solidity ^0.4.24;


pragma solidity ^0.4.24;


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

pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
contract ERC20Interface {

    // ERC Token Standard #223 Interface
    // https://github.com/ethereum/EIPs/issues/223

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

    // approveAndCall
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

    // ERC Token Standard #20 Interface
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md


    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // bulk operations
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}

pragma solidity ^0.4.24;

/// @author https://BlockChainArchitect.iocontract Bank is CutiePluginBase
contract PluginInterface
{
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

    /// @dev Begins new feature.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    /// @param _seller - Old owner, if not the message sender
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    ) 
    public
    payable;

    /// @dev Begins new feature, approved and signed by COO.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    )
    external
    payable;

    function withdraw() public;
}


contract CuteCoinInterface is ERC20Interface
{
    function mint(address target, uint256 mintedAmount) public;
    function mintBulk(address[] target, uint256[] mintedAmount) external;
    function burn(uint256 amount) external;
}


/// @dev Receives payments for payd features from players for Blockchain Cuties
/// @author https://BlockChainArchitect.io
contract CuteCoinShop is Pausable
{
    CuteCoinInterface token;

    event CuteCoinShopBuy(address sender, uint value, bytes extraData);

    function setToken(CuteCoinInterface _token)
        external
        onlyOwner
    {
        token = _token;
    }

    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData)
        external
        whenNotPaused
    {
        require(_tokenContract == address(token));
        require(token.transferFrom(_sender, address(this), _value));
        token.burn(_value);

        emit CuteCoinShopBuy(_sender, _value, _extraData);
    }

    // @dev Transfers to _withdrawToAddress all tokens controlled by
    // contract _tokenContract.
    function withdrawTokenFromBalance(ERC20Interface _tokenContract, address _withdrawToAddress)
        external
        onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }
}