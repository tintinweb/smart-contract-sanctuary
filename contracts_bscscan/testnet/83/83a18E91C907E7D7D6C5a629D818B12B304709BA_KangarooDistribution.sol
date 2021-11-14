// SPDX-License-Identifier: MIT
/*
http://kangoo.group/
*/
pragma solidity 0.7.6;
import "./lib/IBEP20.sol";
import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/IPancakeRouter02.sol";
import "./lib/TransferHelper.sol";
import "./KangarooStake.sol";

contract KangarooDistribution is Ownable {
    
    using SafeMath for uint256;
    using TransferHelper for IBEP20; 

    address immutable public pancakeRouter;
    IBEP20 immutable public usdtToken;//0x55d398326f99059fF775485246999027B3197955  usdt
    IBEP20 immutable public kangarooToken;
    KangarooStake immutable public stakePool;
    address immutable public philanthropyAddress;
    uint256 immutable public minDistrBalance;
    bool public chargingPool=false;

    uint256 public philanthropyPercent;
    uint256 public burnPercent;
    uint256 public poolPercent;

    constructor (KangarooStake _stakePool,
                address _philanthropyAddress) {
        
        pancakeRouter=_stakePool.pancakeRouter();
        kangarooToken=_stakePool.rooToken(); 
        usdtToken=_stakePool.usdtToken(); 
        stakePool = _stakePool;
        philanthropyAddress=_philanthropyAddress;
        philanthropyPercent=10;
        burnPercent=40;
        poolPercent=50;
        minDistrBalance=10**18;
    }

    function setDistributionPercents(uint256 _philanthropyPercent,uint256 _burnPercent,uint256 _poolPercent) external onlyOwner {
        require(_philanthropyPercent.add(_burnPercent.add(_poolPercent))==100,"bad percent");
        philanthropyPercent =_philanthropyPercent;
        burnPercent =_burnPercent;
        poolPercent =_poolPercent;
    }

    function startChargingPool() external onlyOwner{
        chargingPool=true;
    }

    function distribute() external{
        
        uint256 usdtBalance=usdtToken.balanceOf(address(this));
        
        if(usdtBalance>=minDistrBalance){
            usdtToken.safeIncreaseAllowance(pancakeRouter, usdtBalance);
            address[] memory tokenPath = new address[](2);
            tokenPath[0] = address(usdtToken);
            tokenPath[1] = address(kangarooToken);

            IPancakeRouter02(pancakeRouter)
                .swapExactTokensForTokens(
                usdtBalance,
                0,
                tokenPath,
                address(this),
                block.timestamp + 60
            );
        }

        uint256 kangarooBalance = kangarooToken.balanceOf(address(this));

        if(kangarooBalance>minDistrBalance){
            
            if(chargingPool){
                
                uint256 toPoolAmount=kangarooBalance.mul(poolPercent).div(100);
                uint256 toBurnAmount=kangarooBalance.mul(burnPercent).div(100);
                uint256 toPhilanthropyAmount=kangarooBalance.mul(philanthropyPercent).div(100);

                if(toPoolAmount>0){
                    kangarooToken.safeIncreaseAllowance(address(stakePool), toPoolAmount);
                    require(stakePool.chargePool(toPoolAmount),"cant charge Pool");
                }

                if(toBurnAmount>0){
                    (bool success,) = address(kangarooToken).call(abi.encodeWithSignature("burn(uint256)",toBurnAmount));
                    require(success,"burn FAIL");
                }

                if(toPhilanthropyAmount>0){
                    kangarooToken.safeTransfer(philanthropyAddress, toPhilanthropyAmount);
                }
            }else{
                if(kangarooBalance>0){
                    (bool success,) = address(kangarooToken).call(abi.encodeWithSignature("burn(uint256)",kangarooBalance));
                    require(success,"burn FAIL");
                }
            }

        }

    }

}

// SPDX-License-Identifier: UNLICENSED
/*
http://kangoo.group/
*/
pragma solidity 0.7.6;

import "./lib/IBEP20.sol";
import "./lib/SafeMath.sol";
import "./lib/TransferHelper.sol";
import "./lib/Ownable.sol";
import "./lib/IPancakeRouter02.sol";
import './lib/IPancakeFactory.sol';

pragma experimental ABIEncoderV2;

contract KangarooStake is Ownable{
    using SafeMath for uint256;
    using TransferHelper for IBEP20;

    
    IBEP20 immutable public lpKangarooToken;
    IBEP20 immutable public rooToken;
    IBEP20 immutable public usdtToken;
    address immutable public poolInitiator;
    address immutable public pancakeRouter;// 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public PancakePairAddress;
    address[] public tokenPath;
    bool public openSale=false;

    struct UserInfo {
        uint256 depositTimestamp;
        uint256 sharesAmount;
        uint256 initialDepositAmount;
    }

    struct PoolInfo {
        uint256 freezingPeriod;
        uint256 currentRewardPerShare;
        uint256 sharesTotal;
        mapping(address => UserInfo) usersInfo;
    }


    PoolInfo[3] private pool;
    mapping(address => bool) public isUserExists;
    
    modifier notForPoolInitiator() {
        require(msg.sender!=poolInitiator,"not for pool initiator");
        _;
    }

    modifier poolExist(uint256 _id) {
        require(_id >= 0 && _id<3, "bad pool id");
        _;
    }

    event Stake(uint256 poolId, address user, uint256 amount);
    event PoolCharged(uint256 amount);
    event UnStake(uint256 poolId, address user, uint256 amount);
    event Dividends(uint256 poolId, address user, uint256 amount);

    constructor(address _pancakeRouter,
        address _rooToken,
        address _usdtToken,
        address _poolInitiator,
        uint256[] memory _freezingPeriod
    ) {
        tokenPath=[_usdtToken,_rooToken];
        rooToken=IBEP20(_rooToken);
        usdtToken=IBEP20(_usdtToken);
        poolInitiator=_poolInitiator;
        pancakeRouter=_pancakeRouter;
        PancakePairAddress=IPancakeFactory(IPancakeRouter02(_pancakeRouter).factory()).getPair(_usdtToken,_rooToken);
        require(PancakePairAddress != address(0), "create Pancake pair first");
        lpKangarooToken=IBEP20(PancakePairAddress);
         
        for(uint256 i=0;i<3;i++){
            pool[i].freezingPeriod=_freezingPeriod[i];
            pool[i].usersInfo[_poolInitiator].depositTimestamp = block.timestamp;
            pool[i].usersInfo[_poolInitiator].sharesAmount = 1e12;
            pool[i].usersInfo[_poolInitiator].initialDepositAmount = 0;
        }
        pool[2].sharesTotal = 1e12;
        pool[1].sharesTotal = 2e12;
        pool[0].sharesTotal = 3e12;

    }

    function firstStaking(address _user,uint256 _amount) external {
        require(msg.sender==poolInitiator,"can only be called by the pool initiator");
        require(
            isUserExists[_user],
            "user is not exists. Register first."
        );
        require(
            usdtToken.allowance(_user, address(this)) >=_amount,
            "Increase the allowance first,call the usdt-approve method "
        );

        usdtToken.safeTransferFrom(
            _user,
            address(this),
            _amount
        );

        uint256 token0amount=usdtToken.balanceOf(address(this)).div(2);

        usdtToken.safeIncreaseAllowance(pancakeRouter, token0amount);

        uint256[] memory amounts=IPancakeRouter02(pancakeRouter)
            .swapExactTokensForTokens(
            token0amount,
            0,
            tokenPath,
            address(this),
            block.timestamp + 60
        );

        uint256 token0Amt = usdtToken.balanceOf(address(this));
        uint256 token1Amt = amounts[amounts.length - 1];//rooToken.balanceOf(address(this));

        usdtToken.safeIncreaseAllowance(
            pancakeRouter,
            token0Amt
        );
        rooToken.safeIncreaseAllowance(
            pancakeRouter,
            token1Amt
        );


        (,, uint256 liquidity)=IPancakeRouter02(pancakeRouter).addLiquidity(
            tokenPath[0],
            tokenPath[1],
            token0Amt,
            token1Amt,
            0,
            0,
            address(this),
            block.timestamp + 60
        );

        UserInfo storage user = pool[2].usersInfo[_user];
        

        user.depositTimestamp = block.timestamp;
        user.sharesAmount = user.sharesAmount.add(liquidity);
        user.initialDepositAmount = user.sharesAmount.mul(pool[2].currentRewardPerShare).div(1e12);

        for(uint256 i=0;i<3;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.add(liquidity);
        }

        emit Stake(2, _user, liquidity);

    }


    function createUser(address userAddress) external onlyOwner returns (bool){
        isUserExists[userAddress]=true;
        return(true);
    }

    function startOpenSale() external onlyOwner returns(bool) {
        openSale=true;
        return(openSale);
    }

    function chargePool(uint256 amount) external returns (bool){
        
        require(amount>100,"charged amount is too small");

        rooToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );
        
        uint256 chargedAmount50=amount.div(2);
        uint256 chargedAmount20=amount.div(5);
        uint256 chargedAmount30=amount.sub(chargedAmount50.add(chargedAmount20));
            
        pool[2].currentRewardPerShare=pool[2].currentRewardPerShare
        .add(chargedAmount20.mul(1e12).div(pool[2].sharesTotal))
        .add(chargedAmount30.mul(1e12).div(pool[1].sharesTotal))
        .add(chargedAmount50.mul(1e12).div(pool[0].sharesTotal));

        pool[1].currentRewardPerShare=pool[1].currentRewardPerShare
        .add(chargedAmount30.mul(1e12).div(pool[1].sharesTotal))
        .add(chargedAmount50.mul(1e12).div(pool[0].sharesTotal));

        pool[0].currentRewardPerShare=pool[0].currentRewardPerShare
        .add(chargedAmount50.mul(1e12).div(pool[0].sharesTotal));

        emit PoolCharged(amount);
        return(true);
    }

    function dividendsTransfer(uint256 _id, address _to, uint256 _amount) internal {
        
        require(openSale,"not available before the OpenSale started");

        uint256 max=rooToken.balanceOf(address(this));
        if (_amount > max) {
            _amount=max;
        }

        pool[_id].usersInfo[_to].initialDepositAmount = pool[_id].usersInfo[_to].sharesAmount
        .mul(pool[_id].currentRewardPerShare)
        .div(1e12);

        rooToken.safeTransfer(_to, _amount);
        emit Dividends(_id, _to, _amount);
    }

    

    function stake(uint256 _id, uint256 _amount) external notForPoolInitiator poolExist(_id){
        require(
            isUserExists[msg.sender],
            "user is not exists. Register first."
        );
        require(_amount > 0, "amount must be greater than 0");
        
        
        require(
            lpKangarooToken.allowance(address(msg.sender), address(this)) >=
                _amount,
            "Increase the allowance first,call the approve method"
        );

        UserInfo storage user = pool[_id].usersInfo[msg.sender];

        if (user.sharesAmount > 0) {
            uint256 dividends = calculateDividends(_id,msg.sender);
            if (dividends > 0) {
                dividendsTransfer(_id, msg.sender, dividends);
            }
        }
        
        lpKangarooToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.depositTimestamp = block.timestamp;
        user.sharesAmount = user.sharesAmount.add(_amount);
        user.initialDepositAmount = user.sharesAmount.mul(pool[_id].currentRewardPerShare).div(1e12);
        for(uint256 i=0;i<=_id;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.add(_amount);
        }
        emit Stake(_id, msg.sender, _amount);
      
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _id) external notForPoolInitiator poolExist(_id){
        
        UserInfo storage user = pool[_id].usersInfo[msg.sender];
        uint256 unstaked_shares = user.sharesAmount;
        require(
            unstaked_shares > 0,
            "you do not have staked tokens, stake first"
        );
        require(isTokensFrozen(_id, msg.sender) == false, "tokens are frozen");
        user.sharesAmount = 0;
        user.initialDepositAmount = 0;

        for(uint256 i=0;i<=_id;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.sub(unstaked_shares);
        }
        lpKangarooToken.safeTransfer(msg.sender, unstaked_shares);
        emit UnStake(_id, msg.sender, unstaked_shares);
    }

    function unstake(uint256 _id, uint256 _amount) external notForPoolInitiator poolExist(_id){
        
        UserInfo storage user = pool[_id].usersInfo[msg.sender];

        require(
            _amount > 0 && _amount<=user.sharesAmount,"bad _amount"
        );
        require(isTokensFrozen(_id, msg.sender) == false, "tokens are frozen");

        uint256 dividends = calculateDividends(_id, msg.sender);
        if (dividends > 0) {
            dividendsTransfer(_id, msg.sender, dividends);
        }
        user.sharesAmount=user.sharesAmount.sub(_amount);
        user.initialDepositAmount = user.sharesAmount.mul(pool[_id].currentRewardPerShare).div(1e12);
        for(uint256 i=0;i<=_id;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.sub(_amount);
        }
        
        lpKangarooToken.safeTransfer(msg.sender, _amount);

        emit UnStake(_id, msg.sender, _amount);
    }

    function getDividends(uint256 _id) external poolExist(_id){
        require(
            pool[_id].usersInfo[msg.sender].sharesAmount > 0,
            "you do not have staked tokens, stake first"
        );
        uint256 dividends = calculateDividends(_id, msg.sender);
        if (dividends > 0) {
            dividendsTransfer(_id, msg.sender, dividends);
        }
    }

    function calculateDividends(uint256 _id, address userAddress)
        public
        view
        returns (uint256)
    {
        return pool[_id].usersInfo[userAddress].sharesAmount
        .mul(pool[_id].currentRewardPerShare)
        .div(1e12)
        .sub(pool[_id].usersInfo[userAddress].initialDepositAmount);
    }

    function isTokensFrozen(uint256 _id, address userAddress) public view returns (bool) {
        return (pool[_id].freezingPeriod >(block.timestamp.sub(pool[_id].usersInfo[userAddress].depositTimestamp)));
    }

    function getPoolSharesTotal(uint256 _id)
        external
        view
        returns (uint256)
    {
        return pool[_id].sharesTotal;
    }

    function getUser(uint256 _id,address userAddress)
        external
        view
        returns (UserInfo memory)
    {
        return pool[_id].usersInfo[userAddress];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.4 <0.8.0;
// "SPDX-License-Identifier: Apache License 2.0"

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.8.0;

/**
 * Copyright (c) 2016-2019 zOS Global Limited
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.8.0;
import "./IBEP20.sol";
import "./SafeMath.sol";

library TransferHelper {
    using SafeMath for uint256;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(token.transfer.selector, to, value)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);

        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(token.approve.selector,spender,newAllowance)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "INCREASE_ALLOWANCE_FAILED"
        );     
    }
}