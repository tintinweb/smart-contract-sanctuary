//SourceUnit: IEOContract.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ITRC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";

contract IEOContract is Ownable
{
    address _fcnaddress=0x7dD3835ffCc194356f5Ea5Cf12e45658972BAC6a;
    address _trxtrade=0xA2726afbeCbD8e936000ED684cEf5E2F5cf43008;
    address _trustaddress=0xd77Aef4B7752304d31Ee6Be4C068bD9Ba6d46c01;
    address _fcntrade=0x163EAb303c63ad767EC9bE7FcC84296AE05B0Ad4;
    address _usdtaddress=0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    mapping(address=>uint256) _totalbuy;
    mapping(address=>uint256) _totalgeted;

    mapping(address=>mapping(uint256=>uint256)) _oneroundlimit;

    using SafeMath for uint256;
    using TransferHelper for address;

    mapping(uint256=>uint256) _roundprice;

    uint256 _totalLunched;
    uint256 _totalcanlanched;

    uint256 _nowround;

    uint256 _startreleasetime=1643904000;

    address _feeowner;
    

    constructor()
    {
        _nowround=2;
        _totalcanlanched= 5000 * 1e18;
        _feeowner=msg.sender;

        _roundprice[1]=0;
        _roundprice[2]= 14 * 1e6;
        _roundprice[3]= 20 * 1e6;
    }

    function BuyIdo(uint256 amount) public
    {
        require(amount > 0 ,"error amount");
        require(getRemain() >=amount,"over than remain");
        address user=msg.sender;
        require(_oneroundlimit[user][_nowround].add(amount)<=50 * 1e18,"max50");
        uint256[2] memory price = getIdoPrice();
        _fcnaddress.safeTransferFrom(user, _feeowner, price[0].mul(amount).div(1e18));
        _usdtaddress.safeTransferFrom(user, _feeowner, price[1].mul(amount).div(1e18));
        _oneroundlimit[user][_nowround]=_oneroundlimit[user][_nowround].add(amount);
        _totalbuy[user] =_totalbuy[user].add(amount);
        _totalLunched=_totalLunched.add(amount);
    }

    function setFeeOwner(address user) public onlyOwner 
    {
        _feeowner = user;
    }

    function setStartRelease(uint256 stime) public onlyOwner 
    {
        _startreleasetime=stime;
    }

    function takeOutErrorTransfer(address tokenaddress,address target,uint256 amount) public onlyOwner
    {
        ITRC20(tokenaddress).transfer(target,amount);
    }

    function getUsdtToFcn(uint256 usdtamount) public view returns(uint256)
    {
        uint256 trxprice = _trxtrade.balance.mul(1e10).div( ITRC20(_usdtaddress).balanceOf(_trxtrade));
        uint256 fcntrx= ITRC20(_fcnaddress).balanceOf(_fcntrade).mul(1e10).div(_fcntrade.balance);
        return usdtamount.mul(fcntrx).mul(trxprice).div(1e20);
    }

    function getThisRoundBuied(address user,uint256 roundid) public view returns(uint256)
    { 
        return _oneroundlimit[user][roundid];
    }

    function buyOffline(address user,uint256 amount) public onlyOwner
    {
        _totalbuy[user] = amount;
        _totalLunched += amount;
    }

    function settotalLunched(uint256 amount) public onlyOwner
    {
        _totalLunched=amount;
    }

    function getRemain() public view returns (uint256)
    {
        return _totalcanlanched - _totalLunched;
    }

    function setRoundId(uint256 rounrid,uint256 totalamount) public  onlyOwner
    {
        _nowround=rounrid;
        _totalcanlanched= totalamount;
    }

    function getRoundid() public view returns(uint256)
    {
         return _nowround;
    }

    function getIdoPrice() public  view returns(uint256[2] memory ret)
    {
        ret[0] = getUsdtToFcn(_roundprice[_nowround].mul(3).div(10));
        ret[1] = _roundprice[_nowround].mul(7).div(10);
        return ret;
    }

    function setRoundPrice(uint256 idx,uint256 amount) public onlyOwner
    {
        _roundprice[idx]=amount;
    }

    function getedTrustCount(address user) public view returns(uint256)
    {
        return _totalgeted[user];
    }


    function WithDrawCredit() public
    {
        address user=msg.sender;
        uint256 k= getPendingcoin(user);
        _totalgeted[user] +=k;
        _trustaddress.safeTransfer(user, k);
    }

    function getTotalRelease(address user) public view returns (uint256)
    {
        if(block.timestamp < _startreleasetime +86400 )
            return 0;
        
        uint256 daysdiff = (block.timestamp  - _startreleasetime) / 86400 ;
        daysdiff = daysdiff * 10;
        if(daysdiff >1800)
            daysdiff =1800;


        if(daysdiff <=200)
        {
            return _totalbuy[user].mul(daysdiff).div(1000);
        }
        else 
        {
            return _totalbuy[user].mul( 200 + ((daysdiff - 200) * 5 / 10)).div(1000);
        }
    }

    function getMyIdoCount(address user) public view returns (uint256)
    {
        return _totalbuy[user];
    }

    function getPendingcoin(address user) public view returns(uint256)
    {
        return getTotalRelease(user).sub( _totalgeted[user]);
   
    }


}

//SourceUnit: ITRC20.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
 */
interface ITRC20 {
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


//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

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
    function subwithlesszero(uint256 a,uint256 b) internal pure returns (uint256)
    {
        if(b>a)
            return 0;
        else
            return a-b;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


//SourceUnit: TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}