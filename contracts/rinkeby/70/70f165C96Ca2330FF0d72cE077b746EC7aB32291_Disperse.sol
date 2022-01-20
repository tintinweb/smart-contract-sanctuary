/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Disperse{

    address owner;
    //address[] payees;
    address[] public _payees;
    mapping ( address => string ) _payeeIDs;
    uint8 public TOTAL_PAYEES;
    uint256 public totalDispersment;

    event PayoutInitiated( uint256 totalPayout, uint8 totalPayees );
    event PayeeAdded( address Payee, string Name );
    event PayeeRemoved( address Payee, string Name );
    event FundsRecieved( uint256 Amount );

    constructor( address _owner ){
        owner = _owner;
        TOTAL_PAYEES = 0;
        totalDispersment = 0;
    }

    modifier _isOwner(){
        require( msg.sender == owner );
        _;
    }
    modifier _hasPayees(){
        require( TOTAL_PAYEES > 0 );
        _;
    }
    modifier _hasPool(){
        require( totalDispersment > 0 );
        _;
    }

    function strComp( string memory a, string memory b ) private pure returns( bool ){ 
        return ( keccak256(bytes(a)) == keccak256(bytes(b)) );
    } 

    function getPayeeID( address _addr ) public view returns ( string memory ){
        return _payeeIDs[ _addr ];
    }

    //Add a new payee to the dispersment pool
    function addPayee( string memory _name, address _addr ) public _isOwner() {
        _payees.push( _addr );
        _payeeIDs[_payees[TOTAL_PAYEES]] = _name;
        TOTAL_PAYEES++;
        emit PayeeAdded( _addr, _name );
    }

    //Remove a payee from the disperment pool
    //  REQUIREMENTS:
    //      addr: Address to remove from the pool
    //          * sender must equal address if not owner
    function removePayee( string memory _name ) public {
        if( msg.sender != owner ){
            require( strComp( _payeeIDs[ msg.sender ], _name ) );
            for( uint8 i = 0; i < TOTAL_PAYEES; i++ ){
                if( strComp( _payeeIDs[ _payees[i] ], _name ) ){
                    address _foundAddr = _payees[i];
                    delete( _payeeIDs[ _payees[i] ] );
                    delete( _payees[i] );
                    TOTAL_PAYEES--;
                    emit PayeeRemoved( _foundAddr, _name );
                }
            }  
        } 
    }

    function fund() public payable {
        totalDispersment += msg.value;
        emit FundsRecieved( msg.value );
    }

    function payOut() public _isOwner() _hasPayees() _hasPool() {
        uint256 evenCut = totalDispersment / TOTAL_PAYEES;
        emit PayoutInitiated( totalDispersment, TOTAL_PAYEES );
        for( uint8 i = 0; i < TOTAL_PAYEES; i++ ){
            payable(_payees[i]).transfer( evenCut );
            totalDispersment -= evenCut;
        }
    }

}