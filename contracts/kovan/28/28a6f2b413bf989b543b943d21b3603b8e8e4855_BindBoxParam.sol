/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// File: BindBox/MathX128.sol



pragma solidity ^0.8.7;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol



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

// File: BindBox/IBindBoxParam.sol



pragma solidity ^0.8.9;


interface IBindBoxParam {
    function reward(uint amount,uint probabilityX128) external view returns (uint);

    function newUserToken() external view returns (IERC20 token,uint amount);

    function newUserRewardToken(uint switchProbabilityX128,uint rewardProbabilityX128) external view returns (IERC20 token, uint amount);
}
// File: BindBox/param/BindBoxParam.sol


pragma solidity ^0.8.9;




contract BindBoxParam is IBindBoxParam {
    using MathX128 for uint;
    
    function reward(uint amount,uint probabilityX128) external pure returns (uint award) {
        uint twoX128=probabilityX128.mulX128(probabilityX128);
        uint fourX128=twoX128.mulX128(twoX128);
        uint eightX128=fourX128.mulX128(fourX128);
        uint finalX128=eightX128.mulX128(fourX128).mulX128(twoX128);
        
        uint half=amount/2;
        uint five=amount*5;
        award=finalX128.mulUint(five-half)+half;
    }

    function newUserToken() external pure returns (IERC20 token,uint amount) {
        token=IERC20(0x65be5459944B234386b98fd1BAAC97503d953874);
        amount=6*(10**6);
    }

    function newUserRewardToken(uint switchProbabilityX128,uint rewardProbabilityX128) external pure returns (IERC20 token, uint amount) {
        uint minn;
        uint maxx;
        if(switchProbabilityX128.mulUint(20)==0){
            token=IERC20(0x4809Efa3196954cA35445F0EE5e183d8940E8165);
            minn=10414;
            maxx=17356;
        }else{
            token=IERC20(0x65be5459944B234386b98fd1BAAC97503d953874);
            minn=6*(10**6);
            maxx=10*(10**6);
        }
        amount=rewardProbabilityX128.mulUint(maxx-minn)+minn;
    }
}