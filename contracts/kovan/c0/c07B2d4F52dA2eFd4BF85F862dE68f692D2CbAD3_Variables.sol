// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./OwnableStorage.sol";

contract Ownable{

    OwnableStorage _storage;

    function initialize( address storage_ ) public {
        _storage = OwnableStorage(storage_);
    }

    modifier OnlyAdmin(){
        require( _storage.isAdmin(msg.sender) );
        _;
    }

    modifier OnlyGovernance(){
        require( _storage.isGovernance( msg.sender ) );
        _;
    }

    modifier OnlyAdminOrGovernance(){
        require( _storage.isAdmin(msg.sender) || _storage.isGovernance( msg.sender ) );
        _;
    }

    function updateAdmin( address admin_ ) public OnlyAdmin {
        _storage.setAdmin(admin_);
    }

    function updateGovenance( address gov_ ) public OnlyAdminOrGovernance {
        _storage.setGovernance(gov_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract OwnableStorage {

    address public _admin;
    address public _governance;

    constructor() payable {
        _admin = msg.sender;
        _governance = msg.sender;
    }

    function setAdmin( address account ) public {
        require( isAdmin( msg.sender ), "OWNABLESTORAGE : Not a admin" );
        _admin = account;
    }

    function setGovernance( address account ) public {
        require( isAdmin( msg.sender ) || isGovernance( msg.sender ), "OWNABLESTORAGE : Not a admin or governance" );
        _admin = account;
    }

    function isAdmin( address account ) public view returns( bool ) {
        return account == _admin;
    }

    function isGovernance( address account ) public view returns( bool ) {
        return account == _admin;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

struct Saver{
    uint256 createTimestamp;
    uint256 startTimestamp;
    uint count;
    uint interval;
    uint256 mint;
    uint256 released;
    uint256 accAmount;
    uint256 relAmount;
    uint score;
    uint status;
    uint updatedTimestamp;
}

struct Transaction{
    bool pos;
    uint timestamp;
    uint amount;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./Ownable.sol";
import "./Saver.sol";

contract Variables is Ownable{

    uint256 private _earlyTerminateFee;
    uint256 private _buybackRate;
    address private _treasury;
    mapping( address => bool ) _emergency;

    constructor( address storage_ ) payable {
        Ownable.initialize(storage_);
        _earlyTerminateFee = 2;
        _buybackRate = 20;
    }

    function earlyTerminateFee() public view returns( uint256 ){ return _earlyTerminateFee; }

    function setEarlyTerminateFee( uint256 earlyTerminateFee_ ) public OnlyGovernance {
        require(  1 <= earlyTerminateFee_ && earlyTerminateFee_ < 11, "VARIABLES : Fees range from 1 to 10." );
        _earlyTerminateFee = earlyTerminateFee_;
    }

    function buybackRate() public view returns( uint256 ){ return _buybackRate; }

    function setBuybackRate( uint256 buybackRate_ ) public OnlyGovernance {
        require(  1 <= buybackRate_ && buybackRate_ < 30, "VARIABLES : BuybackRate range from 1 to 30." );
        _buybackRate = buybackRate_;
    }

    function setEmergency( address forge, bool emergency ) public OnlyAdmin {
        _emergency[ forge ] = emergency;
    }

    function isEmergency( address forge ) public view returns( bool ){
        return _emergency[ forge ];
    }

    function setTreasury( address treasury_ ) public OnlyAdmin {
        _treasury = treasury_;
    }

    function treasury() public view returns( address ){
        return _treasury;
    }

}

