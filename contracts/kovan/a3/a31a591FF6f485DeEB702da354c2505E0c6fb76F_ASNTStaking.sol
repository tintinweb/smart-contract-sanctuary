// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol
// Code based on OlympusDAO development


/*

 TODO 
 - NEED TEST - epaoch in timestamp duration

*/

import './SafeMath.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import './IERC20.sol';
import './IsASNT.sol';
import './IWarmup.sol';
import './IDistributor.sol';


contract ASNTStaking is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable ASNT;
    address public immutable sASNT;

    struct Epoch {
        uint duration; // in seconds
        uint number;
        uint endTime; // unixtime
        uint distribute;
    }
    Epoch public epoch;

    address public distributor;
    
    address public locker;
    uint public totalBonus;
    
    address public warmupContract;
    uint public warmupPeriod;
    
    constructor ( 
        address _ASNT, 
        address _sASNT, 
        uint _epochDuration,
        uint _firstEpochNumber,
        uint _firstEpochTime
    ) {
        require( _ASNT != address(0) );
        ASNT = _ASNT;
        require( _sASNT != address(0) );
        sASNT = _sASNT;
        
        epoch = Epoch({
            duration: _epochDuration,
            number: _firstEpochNumber,
            endTime: _firstEpochTime,
            distribute: 0
        });
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }
    mapping( address => Claim ) public warmupInfo;

    /**
        @notice stake ASNT to enter warmup
        @param _amount uint
        @return bool
     */
    function stake( uint _amount, address _recipient ) external returns ( bool ) {
        rebase();
        
        IERC20( ASNT ).safeTransferFrom( msg.sender, address(this), _amount );

        Claim memory info = warmupInfo[ _recipient ];
        require( !info.lock, "Deposits for account are locked" );

        warmupInfo[ _recipient ] = Claim ({
            deposit: info.deposit.add( _amount ),
            gons: info.gons.add( IsASNT( sASNT ).gonsForBalance( _amount ) ),
            expiry: epoch.number.add( warmupPeriod ),
            lock: false
        });
        
        IERC20( sASNT ).safeTransfer( warmupContract, _amount );
        return true;
    }

    /**
        @notice retrieve sASNT from warmup
        @param _recipient address
     */
    function claim ( address _recipient ) public {
        Claim memory info = warmupInfo[ _recipient ];
        if ( epoch.number >= info.expiry && info.expiry != 0 ) {
            delete warmupInfo[ _recipient ];
            IWarmup( warmupContract ).retrieve( _recipient, IsASNT( sASNT ).balanceForGons( info.gons ) );
        }
    }

    /**
        @notice forfeit sASNT in warmup and retrieve ASNT
     */
    function forfeit() external {
        Claim memory info = warmupInfo[ msg.sender ];
        delete warmupInfo[ msg.sender ];

        IWarmup( warmupContract ).retrieve( address(this), IsASNT( sASNT ).balanceForGons( info.gons ) );
        IERC20( ASNT ).safeTransfer( msg.sender, info.deposit );
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
    }

    /**
        @notice redeem sASNT for ASNT
        @param _amount uint
        @param _trigger bool
     */
    function unstake( uint _amount, bool _trigger ) external {
        if ( _trigger ) {
            rebase();
        }
        IERC20( sASNT ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( ASNT ).safeTransfer( msg.sender, _amount );
    }

    /**
        @notice returns the sASNT index, which tracks rebase growth
        @return uint
     */
    function index() public view returns ( uint ) {
        return IsASNT( sASNT ).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if( epoch.endTime <= block.timestamp ) {

            IsASNT( sASNT ).rebase( epoch.distribute, epoch.number );

            epoch.endTime = epoch.endTime.add( epoch.duration );
            epoch.number++;
            
            if ( distributor != address(0) ) {
                IDistributor( distributor ).distribute();
            }

            uint balance = contractBalance();
            uint staked = IsASNT( sASNT ).circulatingSupply();

            if( balance <= staked ) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub( staked );
            }
        }
    }

    /**
        @notice returns contract ASNT holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns ( uint ) {
        return IERC20( ASNT ).balanceOf( address(this) ).add( totalBonus );
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus( uint _amount ) external {
        require( msg.sender == locker );
        totalBonus = totalBonus.add( _amount );
        IERC20( sASNT ).safeTransfer( locker, _amount );
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus( uint _amount ) external {
        require( msg.sender == locker );
        totalBonus = totalBonus.sub( _amount );
        IERC20( sASNT ).safeTransferFrom( locker, address(this), _amount );
    }

    enum DEPENDENCIES { DISTRIBUTOR, WARMUP, LOCKER }

    /**
        @notice sets the contract address for LP staking
        @param _dependency_ address
     */
    function setContract( DEPENDENCIES _dependency_, address _address ) external onlyManager() {
        if( _dependency_ == DEPENDENCIES.DISTRIBUTOR ) { // 0
            distributor = _address;
        } else if ( _dependency_ == DEPENDENCIES.WARMUP ) { // 1
            require( warmupContract == address( 0 ), "Warmup cannot be set more than once" );
            warmupContract = _address;
        } else if ( _dependency_ == DEPENDENCIES.LOCKER ) { // 2
            require( locker == address(0), "Locker cannot be set more than once" );
            locker = _address;
        }
    }
    
    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup( uint _warmupPeriod ) external onlyManager() {
        warmupPeriod = _warmupPeriod;
    }
}