//SourceUnit: Common.sol

pragma solidity ^0.5.13;

import './TRC20.sol';

contract Common {

    // 管理员地址
    mapping(address => bool) internal managerAddressList;

    // Hero合约地址
    address constant hero_contract = address(0x410A98E9C4347184D635E0F875A29A3D59B89E2713);

    // Hero one合约地址
    address constant hero_one_contract = address(0x4102A5D5DA6B02B4EED301244D2594F207081997AF);

    // Hero提币地址
    address internal hero_draw_address = address(0x4187EBF8C0801772A9B92350A0725D585AA2C683E4);

    address internal hero_receive_address = address(0x416989F16289E0EEB4A4894C82893664FB639D7A33);

    address internal minter;

    // 返回代码常量：成功（0）
    uint constant SUCCESS = 0;

    // 返回代码常量：没权限（2）
    uint constant NOAUTH = 2002;

    // 数据不存在
    uint constant NODATA = 2003;

    // 数据已存在
    uint constant DATA_EXIST = 2004;

    modifier onlyAdmin() {
        require(
            msg.sender == minter || managerAddressList[msg.sender],
            "Only admin can call this."
        );
        _;
    }

    // 设置管理员地址
    function setManager(address userAddress) onlyAdmin public returns(uint){
        managerAddressList[userAddress] = true;
        return SUCCESS;
    }

    // 提取trx
    function drawTrx(address drawAddress, uint amount) onlyAdmin public returns(uint) {
        address(uint160(drawAddress)).transfer(amount * 10 ** 6);
        return SUCCESS;
    }

    // 提取其他代币
    function drawCoin(address contractAddress, address drawAddress, uint amount) onlyAdmin public returns(uint) {
        TRC20 token = TRC20(contractAddress);
        uint256 decimal = 10 ** uint256(token.decimals());
        token.transfer(drawAddress, amount * decimal);
        return SUCCESS;
    }

    constructor() public {
        minter = msg.sender;
    }
}


//SourceUnit: HeroMemberShareWeek.sol

pragma solidity ^0.5.13;

import "./Common.sol";
import './TRC20.sol';

contract HeroMemberShareWeek is Common {

    // 池子分红
    struct PoolShare {
        uint amount;    // 数量
        uint status;    // 状态  1 未领取  2 已领取
    }

    // 领取时间
    mapping(uint => mapping(address => PoolShare)) internal poolShareList;

    // 当前期数时间
    uint internal currentTime;

    // 设置当前期数
    function setCurrentTime(uint time) onlyAdmin public returns (uint) {
        currentTime = time;
        return SUCCESS;
    }

    // 获取当前期数
    function getCurrentTime() public view returns (uint) {
        return currentTime;
    }

    // 设置奖金池
    function setSharePool(address[] memory addressList, uint[] memory amountList) onlyAdmin public returns (uint) {
        require(addressList.length == amountList.length, "data error!");
        for (uint i = 0; i < addressList.length; i ++) {
            poolShareList[currentTime][addressList[i]] = PoolShare(amountList[i], 1);
        }
        return SUCCESS;
    }

    // 获取对应期数地址的分红数量
    function getSharePool(uint time, address userAddress) public view returns (uint, uint) {
        PoolShare memory poolShare = poolShareList[time][userAddress];
        return (poolShare.amount, poolShare.status);
    }

    // 获取用户签到状态
    function getUserStatus() public view returns (uint, uint) {
        PoolShare memory poolShare = poolShareList[currentTime][msg.sender];
        return (poolShare.amount, poolShare.status);
    }

    // 用户签到
    function userGetShare() public payable returns (uint) {
        require(msg.value >= 20 * 10 ** 6, "trx is not enough!");
        PoolShare storage poolShare = poolShareList[currentTime][msg.sender];
        require(poolShare.status == 1, "you cant get share!");
        require((currentTime + 288000) / (24 * 60 * 60 * 7) == (now + 288000) / (24 * 60 * 60 * 7), "you cant get share!");
        TRC20 token = TRC20(hero_contract);
        assert(token.transferFrom(hero_draw_address, msg.sender, poolShare.amount) == true);
        poolShare.status = 2;
        return SUCCESS;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.13;

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


//SourceUnit: TRC20.sol

pragma solidity ^0.5.13;

contract TRC20 {

  function transferFrom(address from, address to, uint value) external returns (bool ok);

  function decimals() public view returns (uint8);

  function transfer(address _to, uint256 _value) public;

  function balanceOf(address account) external view returns (uint256);
}