/**
 *Submitted for verification at FtmScan.com on 2021-12-23
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

interface IHecCirculation{
    function HECCirculatingSupply() external view returns ( uint );
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
        uint _totalHecReserve,
        uint _totalStableBal,
        uint _cirulatingHec
    );
}
contract BackingCalculator is IBackingCalculator{
    using SafeMath for uint;
    IPair public dailp=IPair(0xbc0eecdA2d8141e3a26D2535C57cadcb1095bca9);
    IPair public fraxlp=IPair(0x0f8D6953F58C0dd38077495ACA64cbd1c76b7501);
    IPair public usdclp=IPair(0xd661952749f05aCc40503404938A91aF9aC1473b);
    IERC20 public dai=IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);
    IERC20 public usdc=IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 public mim=IERC20(0x82f0B8B456c1A451378467398982d4834b6829c1);
    IERC20 public frax=IERC20(0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355);
    address public HEC=0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0;
    address public treasury=0xCB54EA94191B280C296E6ff0E37c7e76Ad42dC6A;
    IHecCirculation public hecCirculation=IHecCirculation(0x5a0325d0830f10044D82044fd04223F2E0Ea5047);
    Investment curveAllocator = Investment(0x344456Df952FA32Be9C860c4EB23385384C4ef7A);

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
        uint _totalHecReserve,
        uint _totalStableBal,
        uint _cirulatingHec
    ){
        // lp
        uint stableReserve;
        uint hecReserve;
        //dailp
        (hecReserve,stableReserve)=hecStableAmount(dailp);
        _totalStableReserve=_totalStableReserve.add(stableReserve);
        _totalHecReserve=_totalHecReserve.add(hecReserve);
        //fraxlp
        (hecReserve,stableReserve)=hecStableAmount(fraxlp);
        _totalStableReserve=_totalStableReserve.add(stableReserve);
        _totalHecReserve=_totalHecReserve.add(hecReserve);
        //usdclp
        (hecReserve,stableReserve)=hecStableAmount(usdclp);
        _totalStableReserve=_totalStableReserve.add(stableReserve);
        _totalHecReserve=_totalHecReserve.add(hecReserve);
        _lpBacking=_totalStableReserve.div(_totalHecReserve).div(1e5);

        //treasury
        _totalStableBal=_totalStableBal.add(toE18(dai.balanceOf(treasury),dai.decimals()));
        _totalStableBal=_totalStableBal.add(toE18(usdc.balanceOf(treasury),usdc.decimals()));
        _totalStableBal=_totalStableBal.add(toE18(mim.balanceOf(treasury),mim.decimals()));
        _totalStableBal=_totalStableBal.add(toE18(frax.balanceOf(treasury),frax.decimals()));
        _totalStableBal=_totalStableBal.add(toE18(curveAllocator.totalValueDeployed(),9));
        _cirulatingHec=hecCirculation.HECCirculatingSupply().sub(_totalHecReserve);
        _treasuryBacking=_totalStableBal.div(_cirulatingHec).div(1e5);
    }
    function hecStableAmount( IPair _pair ) public view returns ( uint hecReserve,uint stableReserve){
        ( uint reserve0, uint reserve1, ) =  _pair .getReserves();
        uint8 stableDecimals;
        if ( _pair.token0() == HEC ) {
            hecReserve=reserve0;
            stableReserve=reserve1;
            stableDecimals=IERC20(_pair.token1()).decimals();
        } else {
            hecReserve=reserve1;
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