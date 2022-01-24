/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-23
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IERC20 {
    function decimals() external view returns(uint8);
    function balanceOf(address owner) external view returns(uint);
}

interface IPair is IERC20{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IAOMCirculation{
    function AOMCirculatingSupply() external view returns ( uint );
}
interface Investment{
    function totalValueDeployed() external view returns (uint);
}
interface IBackingCalculator{
    //decimals for backing is 4
    function backing() external view returns (uint _lpBacking, uint _treasuryBacking);

    //decimals for backing is 4
    function lpBacking() external view returns(uint _lpBacking);

    //decimals for backing is 4
    function treasuryBacking() external view returns(uint _treasuryBacking);

    //decimals for backing is 4
    function backing_full() external view returns (
        uint _lpBacking, 
        uint _treasuryBacking,
        uint _totalStableReserve,
        uint _totalAOMReserve,
        uint _totalStableBal,
        uint _cirulatingAOM
    );
}
contract BackingCalculator is IBackingCalculator{
    using SafeMath for uint;
    // IPair public dailp=IPair(0xbc0eecdA2d8141e3a26D2535C57cadcb1095bca9);
    // IPair public usdclp=IPair(0xd661952749f05aCc40503404938A91aF9aC1473b);
    // IERC20 public dai=IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);
    // IERC20 public usdc=IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    // IERC20 public mim=IERC20(0x82f0B8B456c1A451378467398982d4834b6829c1);
    // address public treasury=0xCB54EA94191B280C296E6ff0E37c7e76Ad42dC6A;
    // IAOMCirculation public AOMCirculation=IAOMCirculation(0x5a0325d0830f10044D82044fd04223F2E0Ea5047);

    //===on FUJI test.
    IPair public dailp=IPair(0xB24F5AB557d99D58E4437d225BF71F2C890c790D);
    IPair public usdclp=IPair(0x81CC2Fe481226a1594a603eBc24F65Adf1a0F37F);  //MIM-AOM LP
    IERC20 public dai=IERC20(0x6341f5C463017E98a3FB9a5d59CC898a5443e65B);
    IERC20 public usdc=IERC20(0x9BF72e2A50f203662a0eDE314C68818708d371eD);
    IERC20 public mim=IERC20(0xa6d68596564079D1f91c108c40bB72E6b03f152a);
    address public AOM=0x3b5bafBE789900a80dDb078b214d5636476E94F5;
    address public treasury=0x9492E401e8aAe94db0880992e0675a46fA85b6e4;
    IAOMCirculation public AOMCirculation=IAOMCirculation(0xEFb3499466Acb872dbe71760C3d392A122a18497);

    function backing() external view override returns (uint _lpBacking, uint _treasuryBacking){
        (_lpBacking,_treasuryBacking,,,,)=backing_full();
    }

    function lpBacking() external view override returns(uint _lpBacking){
        (_lpBacking,,,,,)=backing_full();
    }

    function treasuryBacking() external view override returns(uint _treasuryBacking){
        (,_treasuryBacking,,,,)=backing_full();
    }

    //decimals for backing is 4
    function backing_full() public view override returns (
        uint _lpBacking, 
        uint _treasuryBacking,
        uint _totalStableReserve,
        uint _totalAOMReserve,
        uint _totalStableBal,
        uint _cirulatingAOM
    ){
        // lp
        uint stableReserve;
        uint AOMReserve;
        //dailp
        (AOMReserve,stableReserve)=AOMStableAmount(dailp);
        _totalStableReserve=_totalStableReserve.add(stableReserve);
        _totalAOMReserve=_totalAOMReserve.add(AOMReserve);
        //usdclp
        (AOMReserve,stableReserve)=AOMStableAmount(usdclp);
        _totalStableReserve=_totalStableReserve.add(stableReserve);
        _totalAOMReserve=_totalAOMReserve.add(AOMReserve);
        _lpBacking=_totalStableReserve.div(_totalAOMReserve).div(1e5);

        //treasury
        _totalStableBal=_totalStableBal.add(toE18(dai.balanceOf(treasury),dai.decimals()));
        _totalStableBal=_totalStableBal.add(toE18(usdc.balanceOf(treasury),usdc.decimals()));
        _totalStableBal=_totalStableBal.add(toE18(mim.balanceOf(treasury),mim.decimals()));
        _cirulatingAOM=AOMCirculation.AOMCirculatingSupply().sub(_totalAOMReserve);
        _treasuryBacking=_totalStableBal.div(_cirulatingAOM).div(1e5);
    }
    function AOMStableAmount( IPair _pair ) public view returns ( uint AOMReserve,uint stableReserve){
        ( uint reserve0, uint reserve1, ) =  _pair .getReserves();
        uint8 stableDecimals;
        if ( _pair.token0() == AOM ) {
            AOMReserve=reserve0;
            stableReserve=reserve1;
            stableDecimals=IERC20(_pair.token1()).decimals();
        } else {
            AOMReserve=reserve1;
            stableReserve=reserve0;
            stableDecimals=IERC20(_pair.token0()).decimals();
        }
        stableReserve=toE18(stableReserve,stableDecimals);
    }
    
    function toE18(uint amount, uint8 decimals) public pure returns (uint){
        if(decimals==18)return amount;
        else if(decimals>18) return amount.div(10**(decimals-18));
        else return amount.mul(10**(18-decimals));
    }
}