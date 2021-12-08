// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IGateV2{
    function getEffectiveCollateralRatio() external view  returns(uint256 ecr);
}
interface ICoffinOracle{
    function PERIOD() external view returns (uint32);
    function getCOFFINUSD() external view returns (uint256, uint8);
    function updateTwap(address token0, address token1) external ;
    function getCOUSDUSD() external view returns (uint256, uint8);
    function getTwapCOUSDUSD() external view returns (uint256, uint8);
    function getTwapCOFFINUSD() external view returns (uint256, uint8);
    function getTwapXCOFFINUSD() external view returns (uint256, uint8);
    function updateTwapDollar() external ;
    function updateTwapCoffin() external ;
    function updateTwapXCoffin() external ;
    function getXCOFFINUSD() external view returns (uint256, uint8);
    function getCOUSDFTM() external view returns (uint256, uint8);
    function getXCOFFINFTM() external view returns (uint256, uint8);
    function getCOFFINFTM() external view returns (uint256, uint8);
    function getFTMUSD() external view returns (uint256, uint8);
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    // https://github.com/lunamcsv/
    // defi2/blob/b3ff9b8622c16cc18bd0401881e60d3cfb8d2228/periphery/libraries/FullMath.sol
    // https://github.com/TepNik/exilon-contracts/
    // blob/c352f71d7acb1c3dfa3e5fe14a564cc18cfecfca/contracts/pancake-swap/libraries/FullMath.sol
    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (~d + 1);
        d /= pow2;
        l /= pow2;
        l += h * ((~pow2 + 1) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

interface ICollateralReserveV2{
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
    function deposit( uint _amount, address _token, uint _profit ) external ;

}

contract BondDepositoryDAI is Ownable{
    using FixedPoint for *;

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SafeMath for uint32;


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint minimumPrice; // vs principle value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
    }

    // Info for bond holder
    struct Bond {
        uint payout; // CoUSD remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
        uint32 lastTime; // Last interaction
        uint32 vesting; // Seconds left to vest
    }

    // // Info for incremental adjustments to control variable 
    // struct Adjust {
    //     bool add; // addition or subtraction
    //     uint rate; // increment
    //     uint target; // BCV when adjustment finished
    //     uint32 buffer; // minimum length (in seconds) between adjustments
    //     uint32 lastTime; // time when last adjustment made
    // }

    /* ======== STATE VARIABLES ======== */

    address public collateralReserveV2; // mints CoUSD when receives principle
    // address public immutable DAO; // receives profit share from bond
    // address public immutable cousd = 0x0DeF844ED26409C5C46dda124ec28fb064D90D27; // dollar 
    address public immutable cousd = 0xA51a63261A7dfdc7eD1E480223C2f705b9CbEE6F; // test 
    // address public immutable bondCalculator; // calculates value of LP tokens
    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    address public daiAddress = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address public principle = daiAddress; // token used to create bond

    address public oracle = address(0x605ce7209B6811c1892Ae18Cfa6595bA1462C403); // oracle 
    uint256 private constant PRICE_PRECISION6 = 1e6;
    uint256 private constant PRICE_PRECISION18 = 1e18;



    /// 
    // address public staking; // to auto-stake payout
    // address public stakingHelper; // to stake and claim if no staking warmup
    // bool public useHelper;


    Terms public terms; // stores terms for new bonds
    // Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference time for debt decay

    address public gatev2;
    
    constructor(address _gatev2 ){
        
        gatev2 = _gatev2;

        address _bondCalculator = address(0);
        isLiquidityBond = ( _bondCalculator != address(0) );
        
        // uint _controlVariable = 500000;
        uint _minPrice = 500000;
        uint _maxPayout = 100; // 100 / 100000 => 0.1%
        uint _fee = 50; // 50 / 10000 => 0.5%. 
        uint _maxDebt = 500000 * 1e18;
        uint32 _vestingTerm = 1 days ;
        uint _initialDebt = 0;
        
        terms = Terms ({
            minimumPrice: _minPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt,
            vestingTerm: _vestingTerm
        });
        totalDebt = _initialDebt;
        // lastDecay = uint32(block.timestamp);
    }

    function setVestingTerm(uint _input) external onlyOwner{
        require( _input >= 129600, "Vesting must be longer than 36 hours" );
        terms.vestingTerm = uint32(_input);
    }
    function setMaxPayout(uint _input) external onlyOwner{
        require( _input <= 10000, "should be less than 10%" ); 
        // _input / 100000 
        // 10000 / 100000 => 10%
        // 1000 / 100000 => 1%
        // 500 / 100000 => 0.5%
        // 50 / 100000 => 0.05%
        terms.maxPayout = _input;
    }
    
    function setFee(uint _input) external onlyOwner{
        require( _input <= 10000, "DAO fee cannot exceed payout" );
        terms.fee = _input;
    }
    
    function setDebt(uint _input) external onlyOwner{
        terms.maxDebt = _input;
    }
    
    // function setMinPrice(uint _input) external onlyOwner{
    //     require( _input <= 1000, "Payout cannot be above 1 percent" );
    //     terms.minimumPrice = _input;
    // }

    function setCollateralReserve(address _collateralReserveV2) public onlyOwner {
        require(_collateralReserveV2 != address(0), "invalidAddress");
        collateralReserveV2 = _collateralReserveV2;
    }

    // /**
    //  *  @notice set control variable adjustment
    //  *  @param _addition bool
    //  *  @param _increment uint
    //  *  @param _target uint
    //  *  @param _buffer uint
    //  */
    // function setAdjustment ( 
    //     bool _addition,
    //     uint _increment, 
    //     uint _target,
    //     uint32 _buffer 
    // ) external onlyOwner() {
    //     require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

    //     adjustment = Adjust({
    //         add: _addition,
    //         rate: _increment,
    //         target: _target,
    //         buffer: _buffer,
    //         lastTime: uint32(block.timestamp)
    //     });
    // }

    // /**
    //  *  @notice set contract for auto stake
    //  *  @param _staking address
    //  *  @param _helper bool
    //  */
    // function setStaking( address _staking, bool _helper ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     if ( _helper ) {
    //         useHelper = true;
    //         stakingHelper = _staking;
    //     } else {
    //         useHelper = false;
    //         staking = _staking;
    //     }
    // }





    /* ======== USER FUNCTIONS ======== */



    function getDollarPrice6() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getCOUSDUSD();
        return __price.mul(PRICE_PRECISION6).div(10**__d);
    }
    function getEffectiveCollateralRatio() public view  returns (uint256) {
        return IGateV2(gatev2).getEffectiveCollateralRatio();
    }




    function deposit2( 
        uint _amount, 
        uint _maxPrice
        // uint _value,
        // address _depositor
    ) external view returns (
        uint _bondprice,
        uint _value ,
        uint payout ,
        uint maxpayout,
        uint fee, 
        // uint profit,
        uint out,
        uint termsfee
    ) {
        // require( _depositor != address(0), "Invalid address" );
        


        // getDollarPrice18

        // decayDebt();
        // require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
        // uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        _bondprice = bondPrice();

        require( _maxPrice >= _bondprice, "Slippage limit: more than max price" ); // slippage protection

        _value = ICollateralReserveV2( collateralReserveV2 ).valueOf( principle, _amount );
        // _value = 999880000000000000 
        // bondPrice = 513658000000000000
        payout = _value.mul(1e18).div(_bondprice);
        // payout = 1.94 => 1940000000000000000
        // maxpayout =    815328017817717989005
        // fee 9700
        // termsfee 500000

        // 1 DAI を入れると、
        // 支払いは、194CoUSD ??? 
        // 1 - 194

        // uint payout = payoutFor( value ); // payout to bonder is computed
  
        // return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );

        maxpayout = maxPayout();
        // require( payout >= 10000000000000000, "Bond too small" ); // must be > 0.01 COUSD ( underflow protection )
        // require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
        
        termsfee = terms.fee;

        // profits are calculated
        
        fee = payout.mul( terms.fee ).div( 10000 );
        out = payout.add(fee);


        // profit = value.sub( payout ).sub( fee );

        // /**
        //     principle is transferred in
        //     approved and
        //     deposited into the treasury, returning (_amount - profit) COUSD
        //  */
        // IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        // IERC20( principle ).approve( address( collateralReserveV2 ), _amount );
        // ICollateralReserveV2( collateralReserveV2 ).deposit( _amount, principle, profit );
        
        // payout

        // _value.sub(profit)

        // // if ( fee != 0 ) { // fee is transferred to dao 
        // //     IERC20( dollar ).safeTransfer( DAO, fee ); 
        // // }
        
        // // total debt is increased
        // totalDebt = totalDebt.add( _value ); 
                
        // // depositor info is stored
        // bondInfo[ _depositor ] = Bond({ 
        //     payout: bondInfo[ _depositor ].payout.add( payout ),
        //     vesting: terms.vestingTerm,
        //     lastTime: uint32(block.timestamp),
        //     pricePaid: priceInUSD
        // });

        // // indexed events are emitted
        // emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        // emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        // adjust(); // control variable is adjusted
        // return payout; 
    }

    function depositTest0( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {

        require( _depositor != address(0), "Invalid address" );

        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
        // uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint priceInUSD = bondPrice(); // Stored in bond info
        uint nativePrice = bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ICollateralReserveV2( collateralReserveV2 ).valueOf( principle, _amount );
        // uint payout = payoutFor( value ); // payout to bonder is computed
        uint payout = value.mul(1e18).div(nativePrice);
        // return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );

        require( payout >= 10000000000000000, "Bond too small" ); // must be > 0.01 COUSD ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
        
    }

    function depositTest1( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external {


        require( _depositor != address(0), "Invalid address" );

        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
        // uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint priceInUSD = bondPrice(); // Stored in bond info
        uint nativePrice = bondPrice();

        // require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        // uint value = ICollateralReserveV2( collateralReserveV2 ).valueOf( principle, _amount );
        // // uint payout = payoutFor( value ); // payout to bonder is computed
        // uint payout = value.mul(1e18).div(nativePrice);
        // return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );

        // require( payout >= 10000000000000000, "Bond too small" ); // must be > 0.01 COUSD ( underflow protection )
        // require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
        
        // // profits are calculated
        // uint fee = payout.mul( terms.fee ).div( 10000 );
        // // uint profit = value.sub( payout ).sub( fee );


    }
    function depositTest2( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {

        require( _depositor != address(0), "Invalid address" );

        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
        // uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint priceInUSD = bondPrice(); // Stored in bond info
        uint nativePrice = bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ICollateralReserveV2( collateralReserveV2 ).valueOf( principle, _amount );
        // uint payout = payoutFor( value ); // payout to bonder is computed
        uint payout = value.mul(1e18).div(nativePrice);
        // return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );

        // require( payout >= 10000000000000000, "Bond too small" ); // must be > 0.01 COUSD ( underflow protection )
        // require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
        
        // // profits are calculated
        // uint fee = payout.mul( terms.fee ).div( 10000 );
        // // uint profit = value.sub( payout ).sub( fee );

        // uint out = payout.add(fee);
        // return out;
    }

    function depositTest3( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external  {
        IERC20( principle ).approve( address( collateralReserveV2 ), _amount );

    }

    function depositTest4( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {
        uint out = 1e17;
        IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( collateralReserveV2 ), _amount );
        ICollateralReserveV2( collateralReserveV2 ).deposit( _amount, principle, out );
        return out;
    }
    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {
        //
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
        // uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint priceInUSD = bondPrice(); // Stored in bond info
        uint nativePrice = bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection
        //


        uint value = ICollateralReserveV2( collateralReserveV2 ).valueOf( principle, _amount );
        // uint payout = payoutFor( value ); // payout to bonder is computed
        uint payout = value.mul(1e18).div(nativePrice);
        // return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );

        require( payout >= 10000000000000000, "Bond too small" ); // must be > 0.01 COUSD ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
        
        // profits are calculated
        uint fee = payout.mul( terms.fee ).div( 10000 );
        // uint profit = value.sub( payout ).sub( fee );

        uint out = payout.add(fee);
        // payout => 0.8 
        // profit = 1 - 0.8 - 0.08 = 0.12
        // 0.88 COUSD => 

        /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) COUSD
         */
        IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( collateralReserveV2 ), _amount );
        ICollateralReserveV2( collateralReserveV2 ).deposit( _amount, principle, out );
        
        if ( fee != 0 ) { // fee is transferred to dao 
            IERC20( cousd ).safeTransfer( collateralReserveV2, fee ); 
        }
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), bondPrice(), debtRatio() );

        // adjust(); // control variable is adjusted
        return payout; 
    }



    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _rebond bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _rebond ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        // (seconds since last interaction / vesting term remaining)
        uint percentVested = percentVestedFor( _recipient );

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return rebondOrSend( _recipient, _rebond, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );
            uint32 t = uint32 (block.timestamp) - (info.lastTime);
            uint32 newvesting = info.vesting - t; 
            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                // vesting: info.vesting.sub32( uint32( block.timestamp ).sub32( info.lastTime ) ),
                vesting: newvesting,
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return rebondOrSend( _recipient, _rebond, payout );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _rebond bool
     *  @param _amount uint
     *  @return uint
     */
    function rebondOrSend( address _recipient, bool _rebond, uint _amount ) internal returns ( uint ) {
        if ( !_rebond ) { // if user does not want to stake
            IERC20( cousd ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake

            //TODO  implement REBONDING mechanism. 

            // if ( useHelper ) { // use if staking warmup is 0
            //     IERC20( cousd ).approve( stakingHelper, _amount );
            //     IStakingHelper( stakingHelper ).stake( _amount, _recipient );
            // } else {
            //     IERC20( cousd ).approve( staking, _amount );
            //     IStaking( staking ).stake( _amount, _recipient );
            // }
        }
        return _amount;
    }







    // /**
    //  *  @notice makes incremental adjustment to control variable
    //  */
    // function adjust() internal {
    //     uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
    //     if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
    //         uint initial = terms.controlVariable;
    //         if ( adjustment.add ) {
    //             terms.controlVariable = terms.controlVariable.add( adjustment.rate );
    //             if ( terms.controlVariable >= adjustment.target ) {
    //                 adjustment.rate = 0;
    //             }
    //         } else {
    //             terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
    //             if ( terms.controlVariable <= adjustment.target ) {
    //                 adjustment.rate = 0;
    //             }
    //         }
    //         adjustment.lastTime = uint32(block.timestamp);
    //         emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
    //     }
    // }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( cousd ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    // /**
    //  *  @notice calculate interest due for new bond
    //  *  @param _value uint
    //  *  @return uint
    //  */
    // function payoutFor( uint _value ) public view returns ( uint ) {
    //     return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );
    // }

    
    
    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {
        uint _ecr = getEffectiveCollateralRatio();
        uint _cousd_price = getDollarPrice6();
        uint _discountRate = 5; 
        uint bondprice = _cousd_price.mul(uint(100).sub(_discountRate)).div(100);
        if (_ecr > bondprice) {
            bondprice = _ecr;
        }
        if ( bondprice < terms.minimumPrice ) {
            bondprice = terms.minimumPrice;
        }        
        return bondprice.mul(1e12);
    }



    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        price_ = bondPrice();
        // price_ = bondPrice().mul( 10 ** ERC20( principle ).decimals() ).div( 100 );
        // if( isLiquidityBond ) {
        //     price_ = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 100 );
        // } else {
        //     price_ = bondPrice().mul( 10 ** IERC20( principle ).decimals() ).div( 100 );
        // }
    }


    /**
     *  @notice calculate current ratio of debt to COUSD supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( cousd ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        return debtRatio();
        // if ( isLiquidityBond ) {
        //     return debtRatio().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 1e9 );
        // } else {
        //     return debtRatio();
        // }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns ( uint ) {
        return totalDebt.sub( debtDecay() );
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns ( uint decay_ ) {
        uint32 timeSinceLast = uint32(block.timestamp) - ( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
        if ( decay_ > totalDebt ) {
            decay_ = totalDebt;
        }
    }


    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ];
        uint secondsSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = secondsSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of COUSD available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );


//     /* ======= AUXILLIARY ======= */

//     /**
//      *  @notice allow anyone to send lost tokens (excluding principle or COUSD) to the DAO
//      *  @return bool
//      */
//     function recoverLostToken( address _token ) external returns ( bool ) {
//         require( _token != Time );
//         require( _token != principle );
//         IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
//         return true;
//     }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}