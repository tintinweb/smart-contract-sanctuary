/**
 *Submitted for verification at snowtrace.io on 2021-12-14
*/

// File: contracts/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/SafeMath.sol

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {

    function decimals() external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts/CurveLpTvl.sol

pragma solidity ^0.5.16;






interface IFarm {
    function poolLength() external view returns (uint256);
    function getPoolInfo(uint256 _pid) external view returns (
        address lpToken,         // Address of LP token contract.
        uint256 currentSupply,    //
        uint256 bonusStartBlock,  //
        uint256 newStartBlock,    //
        uint256 bonusEndBlock,    // Block number when bonus defrost period ends.
        uint256 lastRewardBlock,  // Last block number that defrost distribution occurs.
        uint256 accRewardPerShare,// Accumulated defrost per share, times 1e12. See below.
        uint256 rewardPerBlock,   // defrost tokens created per block.
        uint256 totalDebtReward);
}

interface IOracle {
    function getPrice(address asset) external view returns (uint256);
}


//  supply and borrow (using borrowRatePerTimestamp) APYs using this formula:
// (qiToken.supplyRatePerTimestamp() * 10 ^ -18 * 60 * 60 * 24 + 1) ^ 365 - 1

// Distribution APYs can be calculated with this formula, where rewardTokenType = 0 for QI, 1 for AVAX:

// (Comptroller.rewardSpeeds[rewardTokenType][qiToken] * 10 ^ -18 * 60 * 60 * 24 * rewardTokenPrice / tokenPrice / totalSupply + 1) ^ 365 - 1

interface IQiToken {    
    function supplyRatePerTimestamp() external view returns (uint);
    function borrowRatePerTimestamp() external view returns (uint);
    function totalSupply() external view returns (uint256);
}

interface IComptroller {  
    function rewardSpeeds(uint8,address) external view returns (uint);
}


contract qiApyCal {
    using SafeMath for uint256;
    address public oracleAddress = 0x3eb50Ac62BFe63d76c2Fa8597E5D7a10F9F7f6B8;
    address public ComptrollerAddress = 0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4;
    address public qiAddress = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;  

    address[] public qiTokens = [0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c,//qiavax
                                0xe194c4c5aC32a3C9ffDb358d9Bfd523a0B6d1568,//qiBtc
                                0x334AD834Cd4481BB02d09615E7c11a00579A7909,//qiEth
                                0xc9e5999b8e75C3fEB117F6f73E664b9f3C8ca65C,//qiUsdt
                                0x4e9f683A27a6BdAD3FC2764003759277e93696e6,//qilink
                                0xBEb5d47A3f720Ec0a390d04b4d41ED7d9688bC7F,//qiUsdc
                                0x835866d37AFB8CB8F8334dCCdaf66cf01832Ff5D,//qidai，decimal
                                0x35Bd6aedA81a7E5FC7A7832490e71F757b0cD9Ce //qiQi    
                                ];

    address[] public qiTokenUnderlyings = [ address(0), //AVAX
                                            0x50b7545627a5162F82A992c33b87aDc75187B218,//WBTC,decimal 8
                                            0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB,//WETH,decimal 18
                                            0xc7198437980c041c805A1EDcbA50c1Ce5db95118,//USDT,decimal 6
                                            0x5947BB275c521040051D82396192181b413227A3,//LINK,decimal 18
                                            0xc7198437980c041c805A1EDcbA50c1Ce5db95118,//0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E,//UDSC,decimal 6
                                            0xd586E7F844cEa2F87f50152665BCbc2C279D8d70,//DAI,decimal 18
                                            0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5//QI，decimal 18;
                                           ];

    uint256[] public underlyingDecimal = [ 10**18, //AVAX
                                            10**8, //WBTC
                                            10**18, //WETH
                                            10**6, //USDT
                                            10**18,//LINK
                                            10**6, //USDC
                                            10**18, //dai
                                            10**18 //qi
                                          ]; 

    uint256 constant DIVIDOR = 10**4;
    uint256 constant internal rayDecimals = 1e18;

    function getPriceTokenDecimal(address token) internal view returns(uint256){
        return (10**IERC20(token).decimals());
    }

 //(qiToken.supplyRatePerTimestamp() * 10 ^ -18 * 60 * 60 * 24 + 1) ^ 365 - 1
    function getSupplyApy()
        public
        view
        returns (uint256,uint256)
    {
        uint256 minApy = DIVIDOR.mul(rayDecimals);
        uint256 maxApy = 0;

        for(uint256 i=0;i<qiTokens.length;i++) {
            uint256 supplyRate = IQiToken(qiTokens[i]).supplyRatePerTimestamp();
            supplyRate = supplyRate.mul(3600*24).mul(rayDecimals).div(10**18).add(rayDecimals);
            uint256 apy = rpower(supplyRate,365,rayDecimals).sub(rayDecimals);
            if(apy>maxApy) {
                maxApy = apy;
            }

            if(apy<minApy) {
                minApy = apy;
            }
        }

        return (minApy.mul(DIVIDOR).div(rayDecimals),maxApy.mul(DIVIDOR).div(rayDecimals));
    }

    function getBorrowApy()
        public
        view
        returns (uint256,uint256)
    {
        uint256 minApy = DIVIDOR.mul(rayDecimals);
        uint256 maxApy = 0;

        for(uint256 i=0;i<qiTokens.length;i++) {
            uint256 supplyRate = IQiToken(qiTokens[i]).borrowRatePerTimestamp();
            supplyRate = supplyRate.mul(3600*24).mul(rayDecimals).div(10**18).add(rayDecimals);
            uint256 apy = rpower(supplyRate,365,rayDecimals).sub(rayDecimals);
            if(apy>maxApy) {
                maxApy = apy;
            }

            if(apy<minApy) {
                minApy = apy;
            }
        }

        return (minApy.mul(DIVIDOR).div(rayDecimals),maxApy.mul(DIVIDOR).div(rayDecimals));
    }


// (Comptroller.rewardSpeeds[rewardTokenType][qiToken] * 10 ^ -18 * 60 * 60 * 24 * (rewardTokenPrice / tokenPrice) / totalSupply + 1) ^ 365 - 1
// rewardTokenType = 0 for QI, 1 for AVAX:   
function getDistributionApy()
        public
        view
        returns (uint256,uint256)
    {
        uint256 minApy = DIVIDOR.mul(rayDecimals);
        uint256 maxApy = 0;
        
        uint256 qiPrice = IOracle(oracleAddress).getPrice(qiAddress).mul(1e18);
        uint256 avaxPrice = IOracle(oracleAddress).getPrice(address(0)).mul(1e18);

        for(uint256 i=0;i<qiTokens.length;i++) {
            uint256 qiTokenUnderLyingPrice =  IOracle(oracleAddress).getPrice(qiTokenUnderlyings[i]).mul(underlyingDecimal[i]);
            uint256 total =  IQiToken(qiTokens[i]).totalSupply();
            uint256 qiRewardSpeed = IComptroller(ComptrollerAddress).rewardSpeeds(uint8(0),qiTokens[i]);

            qiRewardSpeed = qiRewardSpeed.mul(3600*24).mul(rayDecimals).mul(qiPrice);
            qiRewardSpeed = (qiRewardSpeed.div(qiTokenUnderLyingPrice).div(total).div(1e18)).add(rayDecimals);
            uint256 qiApy = rpower(qiRewardSpeed,365,rayDecimals).sub(rayDecimals);


            uint256 avaxRewardSpeed = IComptroller(ComptrollerAddress).rewardSpeeds(uint8(1),qiTokens[i]);
            avaxRewardSpeed = avaxRewardSpeed.mul(3600*24).mul(rayDecimals).mul(avaxPrice);
            avaxRewardSpeed = (avaxRewardSpeed.div(qiTokenUnderLyingPrice).div(total).div(1e18)).add(rayDecimals);
            uint256 avaxApy = rpower(qiRewardSpeed,365,rayDecimals).sub(rayDecimals);            

            if((qiApy.add(avaxApy))>maxApy) {
                maxApy = (qiApy.add(avaxApy));
            }

            if((qiApy.add(avaxApy))<minApy) {
                minApy = (qiApy.add(avaxApy));
            }
        } 
        
        return (minApy.mul(DIVIDOR).div(rayDecimals),maxApy.mul(DIVIDOR).div(rayDecimals));

    }  

    function rpower(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }

}