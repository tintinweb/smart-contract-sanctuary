/**
 *Submitted for verification at FtmScan.com on 2021-12-06
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

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

contract DAOLocator is Ownable {
    address public DAO;
    address public RedeemHelper;
    address public Staking;
    address public StakingDistributor;
    address public StakingHelper;
    address public StakingWarmup;
    address public BondingCalculator;
    address public sTOKEN;
    address public TOKEN;
    address public Treasury;
    address public wsTOKEN;

    enum MANAGING {
        DAO,
        REDEEM_HELPER,
        STAKING,
        STAKING_DISTRIBUTOR,
        STAKING_HELPER,
        STAKING_WARMUP,
        BONDING_CALCULATOR,
        STAKED_TOKEN,
        TOKEN,
        TREASURY,
        WRAPPED_STAKED_TOKEN
    }

    event ChangedAddress( MANAGING indexed managing, address _oldAddress, address _newAddress );

    constructor( address _DAO ) {
        emit OwnershipPushed( _owner, _DAO );
        emit ChangedAddress( MANAGING.DAO, _owner, _DAO );
        _owner = _DAO;
        DAO = _DAO;
    }

    function setAddress( MANAGING _managing, address _address ) external onlyPolicy() returns ( bool ) {
        require( _address != address(0) );

        address _old;

        if ( _managing == MANAGING.DAO ) {
            _old = DAO;
            DAO = _address;
        } else if ( _managing == MANAGING.REDEEM_HELPER ) {
            _old = RedeemHelper;
            RedeemHelper = _address;
        } else if ( _managing == MANAGING.STAKING ) {
            _old = Staking;
            Staking = _address;
        } else if ( _managing == MANAGING.STAKING_DISTRIBUTOR ) {
            _old = StakingDistributor;
            StakingDistributor = _address;
        } else if ( _managing == MANAGING.STAKING_HELPER ) {
            _old = StakingHelper;
            StakingHelper = _address;
        } else if ( _managing == MANAGING.STAKING_WARMUP ) {
            _old = StakingWarmup;
            StakingWarmup = _address;
        } else if ( _managing == MANAGING.BONDING_CALCULATOR ) {
            _old = BondingCalculator;
            BondingCalculator = _address;
        } else if ( _managing == MANAGING.STAKED_TOKEN ) {
            _old = sTOKEN;
            sTOKEN = _address;
        } else if ( _managing == MANAGING.TOKEN ) {
            _old = TOKEN;
            TOKEN = _address;
        } else if ( _managing == MANAGING.TREASURY ) {
            _old = Treasury;
            Treasury = _address;
        } else if ( _managing == MANAGING.WRAPPED_STAKED_TOKEN ) {
            _old = wsTOKEN;
            wsTOKEN = _address;
        } else return false;

        emit ChangedAddress( _managing, _old, _address );
        return true;
    }
}