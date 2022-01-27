// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './FixedPoint.sol';
import './ITreasury.sol';
import './IBondCalculator.sol';
import './IStaking.sol';
import './IStakingHelper.sol';
import "./ReEntrance.sol";

contract StandardBond is Ownable, ReEntrance 
{
    using FixedPoint for uint;
    using FixedPoint for FixedPoint.uq112x112;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    address public immutable OHM; // token given as payment for bond
    address public immutable treasury; // mints OHM when receives principle
    address public immutable DAO; // receives profit share from bond
    address public immutable bondCalculator; // calculates value of LP tokens
    address public staking; // to auto-stake payout
    address public stakingHelper; // to stake and claim if no staking warmup
    bool public useHelper;

   struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint minimumPrice; // vs principle value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint totalDebt;
        uint lastDecay;
        bool isLiquidityBond;
    }

    // Info for bond holder
    struct Bond {
        uint payout; // OHM remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
    }
    // struct Info{
    //     uint totalDebt;
    //     uint lastDecay;
    //     bool isLiquidityBond;
    // }
    mapping(address => bool)public isBond;
    mapping(address => Terms)public BondTerms; // principle address => Terms Struct (generic for all users).
    // mapping(address => Info)public BondInfo; //  bond info (generic for all users).
    mapping(address => mapping(address => Bond))public DepositorInfo; // principal(user => bondPersonalInfo) user based information of bond..

    constructor(address _OHM,
        address _treasury, 
        address _DAO,
        address _calculator)
    {
        require( _OHM != address(0) );
        OHM = _OHM;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require(_calculator != address(0));
        bondCalculator = _calculator;
    }

    /**
    @param _principle is the Token address of which Bond is Created...
    @param _calculator is address(0) if it is not LPToken Bond..
    @notice Other parameters are Terms for that created Bond..
    @notice Principle address is registered as Bond Contract so that no other address is used as paarameter in deposit and redeem..
     */
    function createBond(
    address _principle,
    address _calculator,
    uint _controlVariable, 
    uint _vestingTerm,
    uint _minimumPrice,
    uint _maxPayout,
    uint _fee,
    uint _maxDebt,
    uint _initialDebt)public onlyOwner
    {
        // creating bond and initializing Terms ...
        require( BondTerms[_principle].controlVariable == 0, "Bonds must be initialized from 0" );
        bool _isliquiditybond;
        if (_calculator != address(0))
        {
            _isliquiditybond = true;
        }
        else
        {
            _isliquiditybond = false;
        }
        Terms memory terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt,
            totalDebt: _initialDebt,
            lastDecay: block.number,
            isLiquidityBond: _isliquiditybond
        });

        BondTerms[_principle] = terms;

    }

    enum PARAMETER { VESTING, PAYOUT, FEE, DEBT, MINIMUM_PRICE, BCV }
    function setBondTerms(address _principle, PARAMETER _parameter, uint _input)public onlyOwner
    {
        require(isBond[_principle], "Given principle is not Bond Token");
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 0, "Vesting must be longer than given time" );
            BondTerms[_principle].vestingTerm = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            BondTerms[_principle].maxPayout = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            BondTerms[_principle].fee = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 3
            BondTerms[_principle].maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINIMUM_PRICE ) { // 4
            BondTerms[_principle].minimumPrice = _input;
        } else if ( _parameter == PARAMETER.BCV ) { // 5
            BondTerms[_principle].controlVariable = _input;
        }
    }

    function deposit(address _principle, uint _amount, uint _maxPrice, address _depositor)public reEntrance returns(uint)
    {
        require( _depositor != address(0), "Invalid address" );
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        decayDebt(_principle);
        require( BondTerms[_principle].totalDebt <= BondTerms[_principle].maxDebt, "Max capacity reached" );
        
        uint priceInUSD = bondPriceInUSD(_principle); // Stored in bond info
        uint nativePrice = _bondPrice(_principle);

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOf( _principle, _amount );
        uint payout = payoutFor(_principle, value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 OHM ( underflow protection )
        require( payout <= maxPayout(_principle), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul( BondTerms[_principle].fee ).div( 10000 );
        uint profit = value.sub( payout ).sub( fee );

        /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) OHM
         */
        IERC20( _principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( _principle ).approve( address( treasury ), _amount );
        ITreasury( treasury ).deposit( _amount, _principle, profit );
        
        if ( fee != 0 ) { // fee is transferred to dao 
            IERC20( OHM ).safeTransfer( DAO, fee ); 
        }
        
        // total debt is increased
        BondTerms[_principle].totalDebt = BondTerms[_principle].totalDebt.add( value ); 
        uint __payout = DepositorInfo[_principle][ _depositor ].payout;
        // depositor info is stored
        DepositorInfo[_principle][ _depositor ] = Bond({ 
            payout: __payout.add( payout ),
            vesting: BondTerms[_principle].vestingTerm,
            lastBlock: block.number,
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.number.add( BondTerms[_principle].vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(_principle), _bondPrice(_principle), debtRatio(_principle) );

        // adjust(); // control variable is adjusted
        return payout; 
    }

    function decayDebt(address _principle) internal {
        BondTerms[_principle].totalDebt = BondTerms[_principle].totalDebt.sub( debtDecay(_principle) );
        BondTerms[_principle].lastDecay = block.number;
    }

    function debtDecay(address _principle) public view returns ( uint decay_ ) {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        uint blocksSinceLast = block.number.sub( BondTerms[_principle].lastDecay );
        decay_ = BondTerms[_principle].totalDebt.mul( blocksSinceLast ).div( BondTerms[_principle].vestingTerm);
        if ( decay_ > BondTerms[_principle].totalDebt ) {
            decay_ = BondTerms[_principle].totalDebt;
        }
    }

    function _bondPrice(address _principle) internal returns ( uint price_ ) {
        price_ = BondTerms[_principle].controlVariable.mul( debtRatio(_principle) ).add( 1000000000 ).div( 1e7 );
        if ( price_ < BondTerms[_principle].minimumPrice ) {
            price_ = BondTerms[_principle].minimumPrice;        
        } else if ( BondTerms[_principle].minimumPrice != 0 ) {
            BondTerms[_principle].minimumPrice = 0;
        }
    }

    function debtRatio(address _principle) public view returns ( uint debtRatio_ ) {  
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!"); 
        uint supply = IERC20( OHM ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt(_principle).mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    function currentDebt(address _principle) public view returns ( uint ) {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        return BondTerms[_principle].totalDebt.sub( debtDecay(_principle) );
    }

     function bondPriceInUSD(address _principle) public view returns ( uint price_ )
    {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        if( BondTerms[_principle].isLiquidityBond ) {
            price_ = bondPrice(_principle).mul( IBondCalculator( bondCalculator ).markdown( _principle ) ).div( 100 );
        } else {
            price_ = bondPrice(_principle).mul( 10 ** IERC20( _principle ).decimals() ).div( 100 );
        }
    }

    function bondPrice(address _principle) public view returns ( uint price_ ) {        
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        price_ = BondTerms[_principle].controlVariable.mul( debtRatio(_principle) ).add( 1000000000 ).div( 1e7 );
        if ( price_ < BondTerms[_principle].minimumPrice ) {
            price_ = BondTerms[_principle].minimumPrice;
        }
    }


    function payoutFor(address _principle, uint _value ) public view returns ( uint ) {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        return FixedPoint.fraction( _value, bondPrice(_principle) ).decode112with18().div( 1e16 );
    }


    function maxPayout(address _principle) public view returns ( uint ) {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        return IERC20( OHM ).totalSupply().mul( BondTerms[_principle].maxPayout ).div( 100000 );
    }

    function setStaking( address _staking, bool _helper ) external onlyOwner() {
        require( _staking != address(0) );
        if ( _helper ) {
            useHelper = true;
            stakingHelper = _staking;
        } else {
            useHelper = false;
            staking = _staking;
        }
    }


    function redeem( address _principle, address _recipient, bool _stake ) external reEntrance returns ( uint ) {   
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");     
        Bond memory info = DepositorInfo[_principle][ _recipient ];
        uint percentVested = percentVestedFor(_principle, _recipient ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            // delete bondInfo[ _recipient ]; // delete user info
            DepositorInfo[_principle][_recipient].payout = 0;
            DepositorInfo[_principle][_recipient].vesting = 0;
            DepositorInfo[_principle][_recipient].lastBlock = 0;
            DepositorInfo[_principle][_recipient].pricePaid = 0;
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return stakeOrSend(_recipient, _stake, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            DepositorInfo[_principle][ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub( block.number.sub( info.lastBlock ) ),
                lastBlock: block.number,
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, DepositorInfo[_principle][ _recipient ].payout );
            return stakeOrSend(_recipient, _stake, payout );
        }
    }


      function percentVestedFor(address _principle, address _depositor ) public view returns ( uint percentVested_ ) {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        Bond memory bond = DepositorInfo[_principle][ _depositor ];
        uint blocksSinceLast = block.number.sub( bond.lastBlock );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }


    function stakeOrSend(address _recipient, bool _stake, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( OHM ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            if ( useHelper ) { // use if staking warmup is 0
                IERC20( OHM ).approve( stakingHelper, _amount );
                IStakingHelper( stakingHelper ).stake( _amount, _recipient );
            } else {
                IERC20( OHM ).approve( staking, _amount );
                IStaking( staking ).stake( _amount, _recipient );
            }
        }
        return _amount;
    }

    function pendingPayoutFor(address _principle, address _depositor ) external view returns ( uint pendingPayout_ ) {
        require(isBond[_principle], "Given Principle is not registered as Bond Token!!");
        uint percentVested = percentVestedFor( _principle, _depositor );
        uint payout = DepositorInfo[_principle][ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }

    function Bondinfo(address _user, address _principle)public view returns(uint _payout, uint _vesting, uint _lastBlock, uint _pricePaid)
    {
        return(DepositorInfo[_principle][_user].payout,
        DepositorInfo[_principle][_user].vesting,
        DepositorInfo[_principle][_user].lastBlock,
        DepositorInfo[_principle][_user].pricePaid);
    }

    function lastDecay(address _principle)public view returns(uint _lastDeacy)
    {
        return(BondTerms[_principle].lastDecay);
    }
    function totalDebt(address _principle)public view returns(uint _totalDebt)
    {
        return(BondTerms[_principle].totalDebt);
    }
    function isLiquidityBond(address _principle)public view returns(bool _liquidity)
    {
        return(BondTerms[_principle].isLiquidityBond);
    }
    function _Terms(address _principle)public view returns(uint _controlVariable,
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint _fee,
        uint _maxDebt)
    {
        return(
            BondTerms[_principle].controlVariable,
            BondTerms[_principle].vestingTerm,
            BondTerms[_principle].minimumPrice,
            BondTerms[_principle].maxPayout,
            BondTerms[_principle].fee,
            BondTerms[_principle].maxDebt);
    }

}