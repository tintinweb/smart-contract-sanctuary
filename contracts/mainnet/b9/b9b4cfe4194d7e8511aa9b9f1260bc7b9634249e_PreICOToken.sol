pragma solidity ^0.4.10;

contract IERC20Token {
    function totalSupply() public constant returns ( uint256 supply ) { supply; }
    function balanceOf( address _owner ) public constant returns ( uint256 balance ) { _owner; balance; }
    function allowance( address _owner, address _spender ) public constant returns ( uint256 remaining ) { _owner; _spender; remaining; }

  function transfer( address _to, uint256 _value ) public returns ( bool success );
  function transferFrom( address _from, address _to, uint256 _value ) public returns ( bool success );
  function approve( address _spender, uint256 _value ) public returns ( bool success );
}

contract RegaUtils {
  modifier validAddress( address _address ) {
    require( _address != 0x0 );
    _;
  }

  // Overflow checked math
  function safeAdd( uint256 x, uint256 y ) internal returns( uint256 ) {
    uint256 z = x + y;
    assert( z >= x );
    return z;
  }

  function safeSub( uint256 x, uint256 y ) internal returns( uint256 ) {
    assert( x >= y);
    return x - y;
  }
}

contract ERC20Token is IERC20Token, RegaUtils {
  uint256 public totalSupply = 0;
  mapping( address => uint256 ) public balanceOf;
  mapping( address => mapping( address => uint256 ) ) public allowance;

  event Transfer( address indexed _from, address indexed _to, uint256 _value );
  event Approval( address indexed _owner, address indexed _spender, uint256 _value );

  function transfer( address _to, uint256 _value ) validAddress( _to )
    returns( bool success )
  {
    balanceOf[ msg.sender ] = safeSub( balanceOf[ msg.sender ], _value );
    balanceOf[ _to ] = safeAdd( balanceOf[ _to ], _value );
    Transfer( msg.sender, _to, _value );
    return true;
  }

  function transferFrom( address _from, address _to, uint256 _value ) validAddress( _from ) validAddress( _to )
    returns( bool success )
  {
    allowance[ _from ][ msg.sender ] = safeSub( allowance[ _from ][ msg.sender ], _value );
    balanceOf[ _from] = safeSub( balanceOf[_from], _value );
    balanceOf[ _to] = safeAdd( balanceOf[_to], _value );
    Transfer( _from, _to, _value );
    return true;
  }

  function approve( address _spender, uint256 _value ) validAddress( _spender )
    returns( bool success)
  {
    require( _value == 0 || allowance[ msg.sender ][ _spender ] == 0 );

    allowance[ msg.sender ][ _spender ] = _value;
    Approval( msg.sender, _spender, _value );
    return true;
  }

}

contract IApplyPreICO {
  function applyTokens( address owner, uint tokens );
}

contract PreICOToken is ERC20Token {

  string public constant name = "REGA Risk Sharing preICO Token";
  string public constant symbol = "RST-P";
  uint8 public constant decimals = 10;

  address public board;
  address public owner;
  uint public weiForToken;
  uint public notMoreThan;
  uint public notLessThan;
  uint public tokensLimit;
  uint public totalEther = 0;
  address[] public holders;
  bool public closed;
  IApplyPreICO public rst;

  event Issuance( address _to, uint _tokens, uint _amount, uint _sentBack );

  modifier ownerOnly() {
    require( msg.sender == owner );
    _;
  }

  modifier boardOnly() {
    require( msg.sender == board );
    _;
  }

  modifier opened() {
    require(!closed && weiForToken > 0 && totalSupply < tokensLimit);
    _;
  }

  function PreICOToken( address _board ) {
    board = _board;
    owner = msg.sender;
    weiForToken = 5 * uint(10)**(18-2-decimals); // 0.05 Ether
    notMoreThan = 700 * uint(10)**decimals;
    notLessThan = 100 * uint(10)**decimals;
    tokensLimit = 30000 * uint(10)**decimals;
    closed = true;
  }

  function() payable opened {
      issueInternal( msg.sender, msg.value, true );
  }

  function setNotMoreThan( uint _notMoreThan ) public boardOnly {
    notMoreThan = _notMoreThan * uint(10)**decimals;
  }

  function setNotLessThan( uint _notLessThan ) public boardOnly {
    notLessThan = _notLessThan * uint(10)**decimals;
  }

  function setTokensLimit( uint _limit ) public boardOnly {
    tokensLimit = _limit * uint(10)**decimals;
  }

  function setOpen( bool _open ) public boardOnly {
    closed = !_open;
  }

  function setRST( IApplyPreICO _rst ) public boardOnly {
    closed = true;
    rst = _rst;
  }

  function getHoldersCount() public constant returns (uint count) {
    count = holders.length;
  }

  function issue(address to, uint256 amount) public boardOnly validAddress(to) {
    issueInternal( to, amount, false );
  }

  function buy() public payable opened {
    issueInternal( msg.sender, msg.value, true );
  }

  function withdraw( uint amount ) public boardOnly {
    board.transfer( amount );
  }

  function issueInternal(address to, uint256 amount, bool returnExcess) internal {
    uint tokens = amount / weiForToken;
    require( weiForToken > 0 && safeAdd(totalSupply, tokens) < tokensLimit && (balanceOf[to] < notMoreThan || notMoreThan == 0) && safeAdd(balanceOf[to], tokens) >= notLessThan );
    uint sendBack = 0;
    if( notMoreThan > 0 && safeAdd(balanceOf[to], tokens) > notMoreThan ) {
      tokens = notMoreThan - balanceOf[to];
      sendBack = amount - tokens * weiForToken;
    }

    totalEther = safeAdd(totalEther, amount - sendBack);
    balanceOf[to] = safeAdd(balanceOf[to], tokens);
    totalSupply = safeAdd(totalSupply, tokens);
    holders.push(to);
    if( returnExcess && sendBack > 0 && sendBack < amount )
      to.transfer( sendBack );
    Issuance(to, tokens, amount, returnExcess ? sendBack : 0);
    Transfer( this, to, tokens );
  }

  function moveToRST() validAddress(rst) {
    sendToRstForAddress( msg.sender );
  }

  function sendToRST( address from ) validAddress(rst) {
    sendToRstForAddress( from );
  }

  function sendToRstForAddress( address from ) internal {
    require( closed );
    uint amount = balanceOf[from];
    if( amount > 0 ) {
      balanceOf[from] = 0;
      rst.applyTokens( from, amount );
      Transfer( from, rst, amount );
    }
  }
}