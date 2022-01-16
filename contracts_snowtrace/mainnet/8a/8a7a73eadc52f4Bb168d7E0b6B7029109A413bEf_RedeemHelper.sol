/**
 *Submitted for verification at snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IBarter {
    function redeem( address _recipient, bool _stake ) external returns ( uint );
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ );
}

contract RedeemHelper is Ownable {

    address[] public barters;

    function redeemAll( address _recipient, bool _stake ) external {
        for( uint i = 0; i < barters.length; i++ ) {
            if ( barters[i] != address(0) ) {
                if ( IBarter( barters[i] ).pendingPayoutFor( _recipient ) > 0 ) {
                    IBarter( barters[i] ).redeem( _recipient, _stake );
                }
            }
        }
    }

    function addBarterContract( address _barter ) external onlyPolicy() {
        require( _barter != address(0) );
        barters.push( _barter );
    }

    function removeBarterContract( uint _index ) external onlyPolicy() {
        barters[ _index ] = address(0);
    }
}