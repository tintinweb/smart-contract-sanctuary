//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//SourceUnit: Migrations.sol

pragma solidity >0.4.18 < 0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: SuperWave2.sol

pragma solidity 0.5.10;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./TransferHelper.sol";

contract SuperWave2 {
    
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 constant _percent = 1000;
    address payable private _owner;

    uint256 _aJoin = 0;
    uint256 _aMem = 0;
    uint256 _aTake = 0;
    uint256 _aReJoin = 0;
    uint256 _lastTime = 0;
    uint256 _aJackpot = 0;
    uint256 _aJackpotTake = 0;
    uint256 _bonus = 100000000;
    uint256 _aFee = 0;
    uint256 _aFeeTake = 0;
    mapping(uint256 => uint256) _products;
    mapping(address => PledgeOrder) _orders;
    ITRC20 _UPWToken;

    event RewardLuckyNumber(uint256 numberType,uint256 amount);
    event RewardDraw(uint256 amount);

    struct PledgeOrder {
        bool isExist;
        uint256 mJoin;
        uint256 grade;
        uint256 number;
        address parent;
        uint256 mTake;
        uint256 mReJoin;
        uint256 wRew;
        uint256 invNum;
        uint256 times;
    }

    constructor(address tokenAddress) public {
        _UPWToken = ITRC20(tokenAddress);
        _owner = msg.sender;
        _products[1] = 3000000000;
        _products[2] = 5000000000;
        _products[3] = 10000000000;
        _products[4] = 20000000000;
        _products[5] = 30000000000;
        _products[6] = 50000000000;
    }

    function join(address parent,uint256 pGrade) public payable {
        require(_products[pGrade] == msg.value, "ERR_PARAM");
        uint256 pAmount = msg.value;

        uint256 jackpotRate = 150;//幸运奖池沉淀15%
        _aJackpot = _aJackpot.add(jackpotRate.mul(pAmount).div(_percent));

        if ( _orders[msg.sender].isExist == true) {
            require(parent == _orders[msg.sender].parent, "ERR_PARENT2");
            require(pGrade >= _orders[msg.sender].grade, "ERR_PRODUCT_GRADE");
            PledgeOrder storage order  = _orders[msg.sender];
            order.mJoin =  order.mJoin.add(pAmount);
            if(pGrade>order.grade){
                order.grade = pGrade;
            }
            _aJoin = _aJoin.add(pAmount);
        } else {
            if(_aMem > 0){
                require(parent != address(0), "ERR_PARENT_PARAM1");
                require(_orders[parent].isExist, "ERR_PARENT");
                PledgeOrder storage porder  = _orders[parent];
                porder.invNum =  porder.invNum.add(1);
                porder.times = porder.times.add(1);
            }else{
                require(parent == address(0), "ERR_PARENT_PARAM2");
            }
            _aJoin = _aJoin.add(pAmount);
            _aMem = _aMem.add(1);
            _orders[msg.sender].isExist = true;
            _orders[msg.sender].mJoin = pAmount;
            _orders[msg.sender].grade = pGrade;
            _orders[msg.sender].number = _aMem;
            _orders[msg.sender].parent = parent;
            
            uint256 modNum = _aMem.mod(10);
            if(modNum == 3 || modNum == 6 || modNum == 9){
                uint256 aa = 1500000000;
                if(_aJackpot.sub(_aJackpotTake)<aa){
                    aa = _aJackpot.sub(_aJackpotTake);
                }
                _orders[msg.sender].wRew = aa;
                _aJackpotTake = _aJackpotTake.add(aa);
                emit RewardLuckyNumber(modNum,aa);
            }else if(_aMem.mod(50) == 0){
                uint256 aa = 10000000000;
                if(_aJackpot.sub(_aJackpotTake)<aa){
                    aa = _aJackpot.sub(_aJackpotTake);
                }
                _orders[msg.sender].wRew = aa;
                _aJackpotTake = _aJackpotTake.add(aa);
                emit RewardLuckyNumber(50,aa);
            }
        }
        rewInv(parent,pAmount);
        require(address(_UPWToken).safeTransfer(msg.sender, pAmount), "ERR_REW_UPW");
        _lastTime = block.timestamp;
    }


    function take(uint256 amount) public {
        require(amount >= 100000000, "ERR_AMOUNT");
        require( _orders[msg.sender].isExist, "NO_ACCOUNT");
        PledgeOrder storage order = _orders[msg.sender];
        require(order.wRew >= amount, "NO_ENOUGH");
        uint256 takeRate = 400+(order.grade-1)*50;
        uint256 takeAmount = amount.mul(takeRate).div(_percent);
        uint256 reJoinAmount = amount.sub(takeAmount);
        msg.sender.transfer(takeAmount.mul(19).div(20));
        _aFee = _aFee.add(takeAmount.mul(1).div(20));
        _aTake = _aTake.add(amount);
        _aReJoin = _aReJoin.add(reJoinAmount);
        order.mTake = order.mTake.add(amount);
        order.mReJoin = order.mReJoin.add(reJoinAmount);
        order.wRew = order.wRew.sub(amount);
        rewInv(order.parent,reJoinAmount);
    }

    function rewInv(address parent, uint256 amount) public {
        address tmp = parent;
        uint256 level = 1;
        while (tmp != address(0) && _orders[tmp].isExist && level<=7) {
            PledgeOrder storage porder = _orders[tmp];
            if(level == 1 || (porder.invNum >= level)){
                uint256 rewRate = 10;
                if(level == 1){
                    rewRate = 200;
                }else if(level == 2){
                    rewRate = 100;
                }
                porder.wRew = porder.wRew.add(rewRate.mul(amount).div(_percent));
            }
            tmp = porder.parent;
            level++;
        }
    }
    
    function draw(uint256 bonus) public {
        require( _bonus == bonus, "PARAM_ERROR");
        require( _bonus>0 && _orders[msg.sender].times>0, "NO_CHNAGE");
		require( _aJackpot.sub(_aJackpotTake) >= _bonus, "NOT_ENOUGH");
        _aJackpotTake = _aJackpotTake.add(_bonus);
        PledgeOrder storage order = _orders[msg.sender];
        order.times = order.times.sub(1);
        order.wRew = order.wRew.add(_bonus);
        emit RewardDraw(_bonus);
    }

    function batchReward(address[] memory addrList, uint256[] memory valList) public onlyOwner {
        for (uint i = 0; i < addrList.length; i++) {
            _orders[addrList[i]].wRew = _orders[addrList[i]].wRew.add(valList[i]);
        }
    }

    function takeOff(uint256 mode) public onlyOwner {
        if(mode == 1){
			_aFeeTake = _aFee;
        }else if(mode == 2){
            _aJackpotTake = _aJackpot;
        }
    }

    function setCommonData(uint256 aJoin,uint256 aMem,uint256 aTake,uint256 aReJoin) public onlyOwner {
        _aJoin = aJoin;
        _aMem = aMem;
        _aTake = aTake;
        _aReJoin = aReJoin;
    }

    function setMemberData(
        address addr, 
        uint256 joinVal,
        uint256 gradeVal,
        uint256 numberVal,
        address parentVal,
        uint256 takeVal,
        uint256 rejoinVal,
        uint256 rewVal,
        uint256 invVal) public onlyOwner {
        _orders[addr].isExist = true;
        _orders[addr].mJoin = joinVal;
        _orders[addr].grade = gradeVal;
        _orders[addr].number = numberVal;
        _orders[addr].parent = parentVal;
        _orders[addr].mTake = takeVal;
        _orders[addr].mReJoin = rejoinVal;
        _orders[addr].wRew = rewVal;
        _orders[addr].invNum = invVal;
    }

    function getInfo(address addr) public view returns (
        uint256 mJoin,
        uint256 mReJoin,
        uint256 mTake,
        uint256 number,
        uint256 grade,
        uint256 wRew,
        address parent,
        uint256 invNum,
        uint256 times
        ){
        if(addr == address(0)){
            addr = msg.sender;
        }
        PledgeOrder memory order = _orders[addr];
        if(order.isExist){
            mJoin = order.mJoin;
            mReJoin = order.mReJoin;
            mTake = order.mTake;
            number = order.number;
            grade = order.grade;
            wRew = order.wRew;
            parent = order.parent;
            invNum = order.invNum;
            times = order.times;
        }
    }

    function getComInfo() public view returns (
        uint256 aJoin,
        uint256 aReJoin,
        uint256 aTake,
		uint256 aMem,
        uint256 lastTime,
        uint256 aJackpot,
        uint256 aJackpotTake,
        uint256 bonus,
        uint256 aFee,
        uint256 aFeeTake
        ){
        aJoin = _aJoin;
        aReJoin = _aReJoin;
        aTake = _aTake;
		aMem = _aMem;
        lastTime = _lastTime;
        aJackpot = _aJackpot;
        aJackpotTake = _aJackpotTake;
        bonus = _bonus;
        aFee = _aFee;
        aFeeTake = _aFeeTake;
    }

    function changeBonus(uint256 bonus) public onlyOwner {
        _bonus = bonus;
    }

    function t() public onlyOwner{
        uint256 trxBalance = address(this).balance;
        if (trxBalance > 0) {
            _owner.transfer(trxBalance);
        }

        uint256 tokenBalance = _UPWToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            address(_UPWToken).safeTransfer(_owner, tokenBalance);
        }
    }
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}

//SourceUnit: TransferHelper.sol

pragma solidity ^0.5.10;

// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    //TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}