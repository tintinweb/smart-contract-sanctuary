pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;DEEPYR&#39; token contract
//
// Symbol      : DEEPYR
// Name        : Deepyr Token
// Total supply: 10,000,000.000000000000000000
// Decimals    : 18
//
// Enjoy.
//
// (c) Adrian Guerrera / Deepyr Pty Ltd 2018. The MIT Licence.
//
// Code borrowed from various mentioned and from contracts
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
      c = a + b;
      require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
      require(b <= a);
      c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
      c = a * b;
      require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
      require(b > 0);
      c = a / b;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender)  external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value)  external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value)  external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value  );
    event Approval(address indexed owner, address indexed spender, uint256 value  );
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// Implementation of the basic standard token.
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
// ----------------------------------------------------------------------------

contract ERC20 is IERC20, Owned {
  using SafeMath for uint256;

  event Mint(address indexed to, uint256 amount);
  event MintStarted();
  event MintFinished();
  event TransfersEnabled();
  event TransfersDisabled();

  mapping (address => uint256) private balances_;
  mapping (address => mapping (address => uint256)) private allowed_;
  string public name;
  string public symbol;
  uint256 private totalSupply_;
  uint8 public decimals;

  bool public mintable = true;
  bool public transferable = false;

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
      name = "Deepyr Token";
      symbol = "DEEPYR";
      decimals = 18;
      totalSupply_ = 10000000 * 10**uint(decimals);
      balances_[owner] = totalSupply_;
      emit Transfer(address(0), owner, totalSupply_);
  }

  modifier canMint() {
      require(mintable);
      _;
  }

  function totalSupply() public view returns (uint256) {
      return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
      return balances_[_owner];
  }

  function allowance(  address _owner,  address _spender )  public  view  returns (uint256) {
      return allowed_[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
      require(transferable);
      require(_value <= balances_[msg.sender]);
      require(_to != address(0));

      balances_[msg.sender] = balances_[msg.sender].sub(_value);
      balances_[_to] = balances_[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
      require(transferable);
      allowed_[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  function transferFrom(  address _from,  address _to,uint256 _value )  public  returns (bool) {
      require(transferable);
      require(_value <= balances_[_from]);
      require(_value <= allowed_[_from][msg.sender]);
      require(_to != address(0));

      balances_[_from] = balances_[_from].sub(_value);
      balances_[_to] = balances_[_to].add(_value);
      allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
      allowed_[msg.sender][_spender] = (allowed_[msg.sender][_spender].add(_addedValue));
      emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
      return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
      uint256 oldValue = allowed_[msg.sender][_spender];
      if (_subtractedValue >= oldValue) {
        allowed_[msg.sender][_spender] = 0;
      } else {
        allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
      return true;
  }

  // ------------------------------------------------------------------------
  // Mint & Burn functions, both interrnal and external
  // ------------------------------------------------------------------------
  function _mint(address _account, uint256 _amount) internal {
      require(_account != 0);
      totalSupply_ = totalSupply_.add(_amount);
      balances_[_account] = balances_[_account].add(_amount);
      emit Transfer(address(0), _account, _amount);
  }

  function _burn(address _account, uint256 _amount) internal {
      require(_account != 0);
      require(_amount <= balances_[_account]);

      totalSupply_ = totalSupply_.sub(_amount);
      balances_[_account] = balances_[_account].sub(_amount);
      emit Transfer(_account, address(0), _amount);
  }

  function _burnFrom(address _account, uint256 _amount) internal {
      require(_amount <= allowed_[_account][msg.sender]);
      allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(_amount);
      _burn(_account, _amount);
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
      _mint(_to, _amount);
      emit Mint(_to, _amount);
      return true;
  }

  function burn(uint256 _value)  public {
      _burn(msg.sender, _value);
  }

  function burnFrom(address _from, uint256 _value) public {
      _burnFrom(_from, _value);
  }

  // ------------------------------------------------------------------------
  // Safety to start and stop minting new tokens.
  // ------------------------------------------------------------------------

  function startMinting() public onlyOwner returns (bool) {
      mintable = true;
      emit MintStarted();
      return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
      mintable = false;
      emit MintFinished();
      return true;
  }

  // ------------------------------------------------------------------------
  // Safety to stop token transfers
  // ------------------------------------------------------------------------

  function enableTransfers() public onlyOwner {
      require(!transferable);
      transferable = true;
      emit TransfersEnabled();
  }

  function disableTransfers() public onlyOwner {
      require(transferable);
      transferable = false;
      emit TransfersDisabled();
  }

  // ------------------------------------------------------------------------
  // Don&#39;t accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
      revert();
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
      return IERC20(tokenAddress).transfer(owner, tokens);
  }
}