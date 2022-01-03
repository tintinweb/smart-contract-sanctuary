/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     * 
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * 
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * 
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     *  
     * 
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
     * Emits an {Approval} event.
     * 
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
     * 
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface ICOIN {
    // model1
    function calcLast(address) external ;

    function viewCalc(address) external returns(uint256) ;

    // model2
    function bankerModelCalcLast(address) external ;

    // router
    function addReward(address,uint256) external ; 

    function minusBet(address,uint256) external ; 

    function updataReward(address) external ; 

    function totalAmount(address) external returns(uint256); 

}


contract BankerMode {
    using SafeMath for uint;

    IERC20 public TSB;

    ICOIN public router;
    
    string constant fixedSalt = '23426%$$%#*-1234LNJKnln`~~';

    struct gameMsg {
        uint256 number;
        uint256 time;
        uint256 frontMoney;
        uint256 frontRatio;
        uint256 frontCounting;
        uint256 contraryMoney;
        uint256 contraryRatio;
        uint256 contraryCounting;
        mapping (address => bool) use;
        uint256 random;
        address bankerAddress;
        uint256 bankerMoney;
        bool end;
    }

    struct userMsg {
        bool start;
        uint256 random;
        uint256 amount;
        uint256 userIndex;
    }

    struct bankerMsg {
        address bankerAddress;
        uint256 bankerMoney;
        uint256 frontRatio; 
        uint256 contraryRatio;
        uint256 time;
    }
    
    struct history {
        uint256 number; 
        bool state; 
        uint256 buy; 
        uint256 amount;
    }

    mapping (address => history[]) public myHistory;

    uint256 public frontNum;
    uint256 public contraryNum;

    uint256 public lockTime = 150;

    mapping(address => userMsg) public user;

    bankerMsg public nowBanker;

    mapping(uint256 => gameMsg) public game;

    uint256 public heightPeriods;

    address public owner;
    address public feeFive;
    address public feeFour;
    address public feeOne;
    
    event lotteryDone(uint256 Periods,uint256 result);

    constructor (IERC20 _TSB ,address _feeOne,ICOIN _router) public {
        TSB = _TSB;
        owner = 0x43f1Ee2c8aCa00D736187d3aAb89e9e67C63e5ce;
        feeFive = 0xc0DfebF96dADfaf63d174D53C5b90f03c6D9B7a4;
        feeFour = 0x170c048FFC4897F4fc6871009CD2f3BB928EBD6F;
        feeOne = _feeOne;
        router = _router;
    }

    modifier ownerOnly() {
        require(msg.sender == owner,'who are you');
        _;
    }

    modifier isContract(address account){
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        require(!(size > 0),"contract can not be called");
        _;
    }
    

    function changeFeeAddress(address _feeFive,address _feeFour) public ownerOnly {
        feeFive = _feeFive;
        feeFour = _feeFour;
    }

    
    function viewMyHistoryLength() public view returns(uint256){
        return myHistory[msg.sender].length;
    }
 
    function rand (uint256 _maxNumber) internal view returns (uint256) {
        uint256 randomNumber = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number-1), block.difficulty, msg.sender, fixedSalt))) % _maxNumber);
        return randomNumber;
    }

    function bankerModelCalcLast(address _user) public {
        userMsg storage um = user[_user];
        gameMsg storage gm = game[um.userIndex];
        if(um.userIndex == heightPeriods && !gm.end) {
            return;
        }

        if (um.amount == 0) {
            return;
        }
        
        uint256 myRatio = um.random == 0? gm.frontRatio: gm.contraryRatio;
 
        if(um.random == gm.random) {
            uint256 reward = um.amount.mul(myRatio).div(10).mul(95).div(100);
            uint256 fee = um.amount.mul(myRatio).div(10).mul(5).div(100);
            
            router.addReward(_user,reward.add(um.amount)); 
            
            TSB.transferFrom(address(router),feeFive,fee.mul(5).div(10));
            TSB.transferFrom(address(router),feeFour,fee.mul(4).div(10));
            TSB.transferFrom(address(router),feeOne,fee.mul(1).div(10));
            
            myHistory[_user].push(history({
               number : gm.number,
               state : um.random == gm.random,
               buy : um.random,
               amount : reward
            }));
        }else {
            myHistory[_user].push(history({
               number : gm.number,
               state : um.random == gm.random,
               buy : um.random,
               amount : um.amount
            }));
        }
        um.amount = 0;
    }

    function changeRatio(uint256 _frontRatio,uint256 _contrartRatio) public {
        require(nowBanker.bankerAddress == msg.sender,"who are you");
        require(_frontRatio >= 10 && _contrartRatio>=10,"Cannot be zero");

        require(nowBanker.time.add(30) > now, " time out ");
        
        nowBanker.frontRatio = _frontRatio;
        nowBanker.contraryRatio = _contrartRatio;
    }


    function quit() public {
        require(nowBanker.bankerAddress == msg.sender,"who are you");
        
        require(nowBanker.time.add(30) > now, " time out ");
        quitBanker();
        delete nowBanker;
    }

    function rob(uint256 _amount,uint256 _frontRatio,uint256 _contrartRatio) public {
        require(_amount >= 2000000 * (10**18) && _amount >= nowBanker.bankerMoney.add(200000 * (10**18)),"to mini");
        require(_frontRatio >= 10 && _contrartRatio>=10,"Cannot be zero");

        if(nowBanker.time == 0) {
           nowBanker.time = uint256(now);
        }

        require(nowBanker.time.add(30) > now, " time out ");

        uint256 reward = router.totalAmount(msg.sender);

        if(reward >= _amount) {
            router.minusBet(msg.sender,_amount);
        }else { 
            router.minusBet(msg.sender,reward);
            TSB.transferFrom(msg.sender,address(router),_amount.sub(reward));
        } 

        if(nowBanker.bankerAddress != address(0)){
            quitBanker();
        }
        nowBanker.bankerAddress = msg.sender;
        nowBanker.bankerMoney = _amount;
        nowBanker.frontRatio = _frontRatio;
        nowBanker.contraryRatio = _contrartRatio;
    }

    function quitBanker() private {
        router.addReward(nowBanker.bankerAddress,nowBanker.bankerMoney);
        
    }

    function viewCalc(address _user) public view returns(uint256) {
        userMsg storage um = user[_user];
        gameMsg storage gm = game[um.userIndex];
        if(um.userIndex == heightPeriods && !gm.end) {
            return 0;
        }

        uint256 myRatio = um.random == 0? gm.frontRatio: gm.contraryRatio;
 
        if(um.random == gm.random) {
            uint256 reward = um.amount.mul(myRatio).div(10).mul(95).div(100);
            return reward.add(um.amount);
        }
        return 0;
    }

    function play(bool _front,uint256 _amount) public {
        require(nowBanker.bankerAddress != address(0),"none banker");
        require(_amount >= 50000 *( 10 **18),"minimum is 1000");

        require(nowBanker.time.add(30) < now, " time out ");

        require( viewMiniDeposit(_front,_amount) ,"To mini");
        gameMsg storage gm = game[heightPeriods];
        userMsg storage um = user[msg.sender];
        
        router.updataReward(msg.sender);

        if(um.userIndex == heightPeriods && um.start) {
            uint256 _option = _front ? 0 : 1 ;
            require( _option == um.random ,"Select the back");
        }else {
            um.random = _front ? 0 : 1 ;
            um.start = true;
        }
        um.userIndex = heightPeriods;

        if(gm.time == 0) {
            gm.time = now;
            gm.number = heightPeriods;
            gm.bankerAddress = nowBanker.bankerAddress;
            gm.bankerMoney = nowBanker.bankerMoney;
            gm.frontRatio = nowBanker.frontRatio;
            gm.contraryRatio = nowBanker.contraryRatio;
        }
        require( gm.time.add(lockTime) > now , "time out");

        uint256 reward = router.totalAmount(msg.sender);

        if(reward >= _amount) {
            router.minusBet(msg.sender,_amount);
        }else { 
            router.minusBet(msg.sender,reward);
            TSB.transferFrom(msg.sender,address(router),_amount.sub(reward));
        }

        um.amount = um.amount.add(_amount);

        if(!gm.use[msg.sender]){ 
            if(_front){
                gm.frontCounting = gm.frontCounting.add(1);
            }else {
                gm.contraryCounting = gm.contraryCounting.add(1);
            }
            gm.use[msg.sender] = true;
        }
        if(_front){
            gm.frontMoney = gm.frontMoney.add(_amount);
            require( gm.frontMoney <= viewMaxDeposit(_front) ,"overflow money");
        }else {
            gm.contraryMoney = gm.contraryMoney.add(_amount);
            require( gm.contraryMoney <= viewMaxDeposit(_front) ,"overflow money");
        }
    } 

    function viewMaxDeposit (bool _front) view public returns(uint256) {
        gameMsg storage gm = game[heightPeriods]; 
        uint256 frontRatio = gm.frontRatio == 0 ? nowBanker.frontRatio : gm.frontRatio;
        uint256 contraryRatio = gm.contraryRatio == 0 ? nowBanker.contraryRatio : gm.contraryRatio;
        uint256 bankerMoney = gm.bankerMoney == 0 ? nowBanker.bankerMoney : gm.bankerMoney;
        
        if(_front) {
            if(gm.contraryMoney != 0){
                if(frontRatio < 10){
                    return gm.contraryMoney.add(bankerMoney).mul(frontRatio).div(10);
                }else {
                    return gm.contraryMoney.add(bankerMoney).mul(10).div(frontRatio);
                }
            }else {
                if(frontRatio < 10){
                    return bankerMoney.mul(frontRatio).div(10);
                }else {
                    return bankerMoney.mul(10).div(frontRatio);
                } 
            }
        }else {
            if(gm.frontMoney != 0) { 
                if(contraryRatio < 10){
                    return gm.frontMoney.add(bankerMoney).mul(contraryRatio).div(10);
                }else {
                    return gm.frontMoney.add(bankerMoney).mul(10).div(contraryRatio);
                }
            }else{
                if(contraryRatio < 10){
                    return bankerMoney.mul(contraryRatio).div(10);
                }else {
                    return bankerMoney.mul(10).div(contraryRatio);
                } 
            }
        }
    }

    function viewMiniDeposit (bool _front ,uint256 amount) view public returns(bool) {
        gameMsg storage gm = game[heightPeriods];
        uint256 contraryRatio = gm.contraryRatio == 0 ? nowBanker.contraryRatio : gm.contraryRatio; 
        uint256 frontRatio = gm.frontRatio == 0 ? nowBanker.frontRatio : gm.frontRatio;
        if(_front) {
            if(amount.mul(contraryRatio) >= 10){
                return true;
            }else {
                return false;
            }
        }else {
            if(amount.mul(frontRatio) >= 10) {
                return true;
            }else{
                return false;
            }
        }
    }

    function viewTime() public view returns(uint256) {
        return now;
    }

    function lottery() public {
        gameMsg storage gm = game[heightPeriods];
        require( gm.time.add(lockTime) < now , "time out");
        require( !gm.end , "end");
        require( gm.frontMoney != 0 || gm.contraryMoney != 0,"amount is zero");

        uint256 random = rand(2);
        if(random == 0){
            frontNum = frontNum.add(1);
        }else if(random == 1){
            contraryNum = contraryNum.add(1);
        }
        gm.random = random;
        gm.end = true;
        heightPeriods = heightPeriods.add(1);
 
        uint256 winMoney = random == 0? gm.frontMoney: gm.contraryMoney;
        uint256 loserMoney = random == 0? gm.contraryMoney : gm.frontMoney;
        uint256 winRatio = random == 0? gm.frontRatio: gm.contraryRatio;

        uint256 win = winMoney.mul(winRatio).div(10);
        uint256 loser = loserMoney;
        if(loser > win) { 
            loser = loserMoney.sub(loserMoney.sub(win).mul(5).div(100)); 
            uint256 fee = loserMoney.sub(win).mul(5).div(100);  
            
            TSB.transferFrom(address(router),feeFive,fee.mul(5).div(10));
            TSB.transferFrom(address(router),feeFour,fee.mul(4).div(10));
            TSB.transferFrom(address(router),feeOne,fee.mul(1).div(10));
        }

        uint256 nowBankerMoney = gm.bankerMoney.add(loser).sub(win);
        if( nowBankerMoney < 2000000 * (10**18)){ 
            router.addReward(gm.bankerAddress,nowBankerMoney);
            delete nowBanker; 
        }else {
            nowBanker.bankerMoney = nowBankerMoney;
            nowBanker.time = uint256(now);
        }
        
        myHistory[gm.bankerAddress].push(history({
            number : gm.number,
            state : win < loser,
            buy : 3,
            amount : win < loser?loser.sub(win):win.sub(loser)
        }));
        
        emit lotteryDone( heightPeriods.sub(1), random);
    }

}