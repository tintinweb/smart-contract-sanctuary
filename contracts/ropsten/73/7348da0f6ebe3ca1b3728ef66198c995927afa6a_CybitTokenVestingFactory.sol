pragma solidity 0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner , "Unauthorized Access");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ERC223Interface {
   
    function balanceOf(address who) constant external returns (uint);
    function transfer(address to, uint value) external returns (bool success);
    function transfer(address to, uint value, bytes data) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
 struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    function tokenFallback(address _from, uint _value, bytes _data) external;
}
contract ERC20BackedERC223 is ERC223Interface{
    
    

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function disApprove(address _spender)  public returns (bool success);
   function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
   function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);
     /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
     function name() public view returns (string _name);

    /* Get the contract constant _symbol */
    function symbol() public view returns (string _symbol);

    /* Get the contract constant _decimals */
    function decimals() public view returns (uint8 _decimals); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library SafeERC20BackedERC223 {

  function safeTransfer(ERC20BackedERC223 token, address to, uint256 value, bytes data) internal {
    assert(token.transfer(to, value, data));
  }    
    
  function safeTransfer(ERC20BackedERC223 token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20BackedERC223 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20BackedERC223 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
contract TokenVesting is ERC223ReceivingContract, owned {
    using SafeMath for uint256;
    using SafeERC20BackedERC223 for ERC20BackedERC223;
     event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
  string public benificiaryName;
  bytes private paramData;
  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;
    /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable,
    string _benficiaryName
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
    benificiaryName = _benficiaryName;
    paramData = bytes32ToBytes(stringToBytes32(_benficiaryName));
  }
  function tokenFallback(address _from, uint _value, bytes _data) external{
           /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
        TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      
     
     }
  function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

function bytes32ToBytes(bytes32 data) internal pure returns (bytes) {
    uint i = 0;
    while (i < 32 && uint(data[i]) != 0) {
        ++i;
    }
    bytes memory result = new bytes(i);
    i = 0;
    while (i < 32 && data[i] != 0) {
        result[i] = data[i];
        ++i;
    }
    return result;
}
  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC223 token which is being vested
   */
  function release(ERC20BackedERC223 token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased, paramData);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20BackedERC223 token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund, paramData);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20BackedERC223 token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20BackedERC223 token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}
contract CybitTokenVestingFactory is ERC223ReceivingContract, owned {

     using SafeMath for uint256;
     using SafeERC20BackedERC223 for ERC20BackedERC223;
    ERC20BackedERC223 CybitToken = ERC20BackedERC223(0x2a08c4B5CB8eC0b84beEC790741Ae92Bd1f921E3); //the deployed token address
    
    struct Trustee{
        string trusteeName;
        address benificiary;
        TokenVesting vestingForThisTrustee; 
        uint256 totalGrantedAmount;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        bool revokable;
    }

    // Grants holder.
    mapping (address => Trustee) public TrusteeBoard;
    address[] public trusteeAccts;
    event Created(TokenVesting vesting);
      function tokenFallback(address _from, uint _value, bytes _data) external{
           /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
        TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      
     
     }
    function create(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable, string _benficiaryName) internal returns (TokenVesting) {

        TokenVesting vesting = new TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable, _benficiaryName );

        emit Created(vesting);

        return vesting;
    }
    function VestTokens(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable, string _benficiaryName, uint256 _grantedAmount) onlyOwner public
    {
        require(CybitToken.balanceOf(address(this)) >= _grantedAmount);
        uint256 tokendecimals = CybitToken.decimals();
        uint256 fullgrantedAmount  = _grantedAmount.mul(10 ** uint256(tokendecimals));
        TokenVesting vest = create(_beneficiary, _start, _cliff, _duration, _revocable, _benficiaryName);
        TrusteeBoard[_beneficiary] = Trustee({
                                                trusteeName: _benficiaryName,
                                                benificiary: _beneficiary,
                                                vestingForThisTrustee: vest,
                                                totalGrantedAmount: fullgrantedAmount,
                                                start: _start,
                                                cliff: _cliff,
                                                duration: _duration,
                                                revokable: _revocable
                                                
                                            });
        trusteeAccts.push(_beneficiary) -1;
        CybitToken.safeTransfer(vest,fullgrantedAmount);
    }
    
    function callRealeseVestedAmount(address _beneficiary,TokenVesting _vested) public {
        require((TrusteeBoard[_beneficiary].benificiary == _beneficiary && TrusteeBoard[_beneficiary].vestingForThisTrustee == _vested),"Member Not Found");
        _vested.release(CybitToken);
    }

   function optionalRevoke(address _beneficiary,TokenVesting _vested) public onlyOwner{
       require((TrusteeBoard[_beneficiary].benificiary == _beneficiary && TrusteeBoard[_beneficiary].vestingForThisTrustee == _vested),"Member Not Found");
       require(TrusteeBoard[_beneficiary].revokable ,"Revoke not allowed");
      _vested.revoke(CybitToken);
       
   }
   
   function readReleasableAmountOf(address _beneficiary,TokenVesting _vested) public view returns(uint256 _ramount)
   {
       assert(TrusteeBoard[_beneficiary].benificiary == _beneficiary && TrusteeBoard[_beneficiary].vestingForThisTrustee == _vested);
        return _vested.releasableAmount(CybitToken);
       
   }
   function readVestedAmountOf(address _beneficiary,TokenVesting _vested) public view returns(uint256 _ramount)
   {
       assert(TrusteeBoard[_beneficiary].benificiary == _beneficiary && TrusteeBoard[_beneficiary].vestingForThisTrustee == _vested);
        return _vested.vestedAmount(CybitToken);
       
   }
   //function for withdrawal of extra tokens
    function withdrawTokenFromcontract(ERC20BackedERC223 _token, uint256 _tamount) public onlyOwner{
        require(_token.balanceOf(address(this)) > _tamount);
        _token.safeTransfer(owner, _tamount);
     
    }

}