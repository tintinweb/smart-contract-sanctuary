// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/utils/ReentrancyGuard.sol';

import "./openzeppelin/math/SafeMath.sol";
import "./openzeppelin/token/IERC20.sol";
import "./openzeppelin/token/SafeERC20.sol";
import "./openzeppelin/utils/ReentrancyGuard.sol";

contract IMO is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 amountLate;
        uint256 amountWrap; // How many tokens the user has provided.
        uint256 amountWrapLate;// How many tokens the user has provided Late.
        uint256 amountAll;
        uint256 fundLimit;
        //uint256 amountFund; 
        //map to imoNumber
        mapping(uint256 => uint256) amountFund;
        Tier currentTier; 
        uint256 currentIMO; 
    }
    
    struct ImoInfo {
        IERC20 offeringToken;
        IERC20 fundToken;
        uint256 startBlock;
        uint256 startLateBlock;
        // The block number when IFO ends
        uint256 endBlock;
        uint256 harvestBlock;
        uint256 withdrawStartBlock;
        uint256 withdrawStartLateBlock;
        uint256 raisingAmount;
         // total amount of offeringToken that will offer
        uint256 offeringAmount;
        uint256 totalFund;
    }

    //uint256 public AmountFund;

    // admin address
    address public adminAddress;
    address public vaultAddress;
    // The raising token
    IERC20 public lpToken;
    IERC20 public lpTokenWrap;
    // The offering token
    
    uint256 public totalAmount;
    
    uint256 public imoNumber;
    // address => amount
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => ImoInfo) public imoInfo;
    
    // participators
    address[] public addressList;
    address[] public addressWrapList;
    // participators
    address[] public addressListLate;
    address[] public addressWrapListLate;

    enum Tier {
        Zero,
        One,
        Two,
        Three,
        Four,
        Five
    }

    Tier public tier;

    //map to Tier
    mapping(uint256 => uint256) public requireTier;
    //map to Tier
    mapping(uint256 => uint256) public hardCap;
    // uint256 public RequireTier;
    // uint256 public HardCap;

    event Deposit(address indexed user, uint256 amount);
    event DepositLate(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 offeringAmount);

    constructor(
        IERC20 _lpToken,
        IERC20 _lpTokenWrap,
        IERC20 _fundToken,
        IERC20 _offeringToken,
        uint256 _startBlock,
        uint256 _startLateBlock,
        uint256 _endBlock,
        uint256 _harvestBlock,
        uint256 _withdrawStartBlock,
        uint256 _withdrawStartLateBlock,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        address _adminAddress,
        address _vaultAddress,
        uint256 _imoNumber
    ) public {
        lpToken = _lpToken;
        lpTokenWrap = _lpTokenWrap;
        imoInfo[_imoNumber].fundToken = _fundToken;
        imoInfo[_imoNumber].offeringToken = _offeringToken;
        imoInfo[_imoNumber].startBlock = _startBlock;
        imoInfo[_imoNumber].startLateBlock = _startLateBlock;
        imoInfo[_imoNumber].endBlock = _endBlock;
        imoInfo[_imoNumber].harvestBlock = _harvestBlock;
        imoInfo[_imoNumber].withdrawStartBlock = _withdrawStartBlock;
        imoInfo[_imoNumber].withdrawStartLateBlock = _withdrawStartLateBlock;
        imoInfo[_imoNumber].offeringAmount = _offeringAmount;
        imoInfo[_imoNumber].raisingAmount = _raisingAmount;
        totalAmount = 0;
        adminAddress = _adminAddress;
        vaultAddress = _vaultAddress;
        imoNumber = _imoNumber;
        requireTier[1] = 9 * 10**23;
        requireTier[2] = 45 * 10**22;
        requireTier[3] = 9 * 10**22;
        requireTier[4] = 9 * 10**21;
        requireTier[5] = 9 * 10**20;
        hardCap[1] = _raisingAmount * 20 /100;
        hardCap[2] = _raisingAmount * 5 /100;
        hardCap[3] = _raisingAmount * 5 /1000;
        hardCap[4] = _raisingAmount * 5 /10000;
        hardCap[5] = _raisingAmount * 5 /100000;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    function setIMO(
        IERC20 _fundToken,
        IERC20 _offeringToken,
        uint256 _startBlock,
        uint256 _startLateBlock,
        uint256 _endBlock,
        uint256 _harvestBlock,
        uint256 _withdrawStartBlock,
        uint256 _withdrawStartLateBlock,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _imoNumber
    ) public onlyAdmin {
        imoInfo[_imoNumber].fundToken = _fundToken;
        imoInfo[_imoNumber].offeringToken = _offeringToken;
        imoInfo[_imoNumber].startBlock = _startBlock;
        imoInfo[_imoNumber].startLateBlock = _startLateBlock;
        imoInfo[_imoNumber].endBlock = _endBlock;
        imoInfo[_imoNumber].harvestBlock = _harvestBlock;
        imoInfo[_imoNumber].withdrawStartBlock = _withdrawStartBlock;
        imoInfo[_imoNumber].withdrawStartLateBlock = _withdrawStartLateBlock;
        imoInfo[_imoNumber].offeringAmount = _offeringAmount;
        imoInfo[_imoNumber].raisingAmount = _raisingAmount;
        imoNumber = _imoNumber;
    }

    function setOfferingAmount(uint256 _offerAmount) public onlyAdmin {
        require(block.number < imoInfo[imoNumber].startBlock, "no");
        imoInfo[imoNumber].offeringAmount = _offerAmount;
    }

    function setRaisingAmount(uint256 _raisingAmount) public onlyAdmin {
        require(block.number < imoInfo[imoNumber].startBlock, "no");
        imoInfo[imoNumber].raisingAmount = _raisingAmount;
    }

    function deposit(uint256 _amount) public {
        require(
            block.number > imoInfo[imoNumber].harvestBlock || block.number < imoInfo[imoNumber].endBlock,
            "not ifo time"
        );
        require(_amount > 0, "need _amount > 0");
        uint256 amountAfterFee = _amount.mul(9).div(10);
        if (block.number < imoInfo[imoNumber].startLateBlock || block.number > imoInfo[imoNumber].harvestBlock) {
            lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (userInfo[msg.sender].amount == 0) {
                addressList.push(address(msg.sender));
            }
            userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(
                amountAfterFee
            );
            userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.add(
                amountAfterFee
            );
            totalAmount = totalAmount.add(amountAfterFee);
            updateTierAndLimitFund(msg.sender);
        } else if (block.number > imoInfo[imoNumber].startLateBlock) {
            lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (userInfo[msg.sender].amountLate == 0) {
                addressListLate.push(address(msg.sender));
            }
            userInfo[msg.sender].amountLate = userInfo[msg.sender]
            .amountLate
            .add(amountAfterFee);
            userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.add(
                amountAfterFee
            );
            totalAmount = totalAmount.add(amountAfterFee);
            updateTierAndLimitFund(msg.sender);
        }
        emit Deposit(msg.sender, amountAfterFee);
    }

    function depositWrap(uint256 _amount) public {
        require(
            block.number > imoInfo[imoNumber].harvestBlock || block.number < imoInfo[imoNumber].endBlock,
            "not ifo time"
        );
        require(_amount > 0, "need _amount > 0");
        if (block.number < imoInfo[imoNumber].startLateBlock || block.number > imoInfo[imoNumber].harvestBlock) {
            lpTokenWrap.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (userInfo[msg.sender].amountWrap == 0) {
                addressWrapList.push(address(msg.sender));
            }
            userInfo[msg.sender].amountWrap = userInfo[msg.sender]
            .amountWrap
            .add(_amount);
            userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.add(
                _amount
            );
            totalAmount = totalAmount.add(_amount);
            updateTierAndLimitFund(msg.sender);
        } else if (block.number > imoInfo[imoNumber].startLateBlock) {
            lpTokenWrap.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (userInfo[msg.sender].amountLate == 0) {
                addressWrapListLate.push(address(msg.sender));
            }
            userInfo[msg.sender].amountWrapLate = userInfo[msg.sender]
            .amountWrapLate
            .add(_amount);
            userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.add(
                _amount
            );
            totalAmount = totalAmount.add(_amount);
            updateTierAndLimitFund(msg.sender);
        }
        emit Deposit(msg.sender, _amount);
    }

    function depositFund(uint256 _amount) public nonReentrant {
        require(
            block.number > imoInfo[imoNumber].endBlock && block.number < imoInfo[imoNumber].harvestBlock,
            "not ifo time"
        );
        require(userInfo[msg.sender].amountAll > 0, "have you participated?");
        require(_amount > 0, "need _amount > 0");
        updateTierAndLimitFund(msg.sender);
        require(
            userInfo[msg.sender].amountFund[imoNumber] + _amount <=
                userInfo[msg.sender].fundLimit,
            "exceed fund limits"
        );
        imoInfo[imoNumber].fundToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        userInfo[msg.sender].amountFund[imoNumber] = userInfo[msg.sender].amountFund[imoNumber].add(
            _amount
        );
        imoInfo[imoNumber].totalFund = imoInfo[imoNumber].totalFund.add(_amount);
    }

    function harvest() public nonReentrant {
        require(block.number > imoInfo[imoNumber].harvestBlock, "not harvest time");
        require(userInfo[msg.sender].amountAll > 0, "have you participated?");
        require(
            userInfo[msg.sender].currentIMO < imoNumber,
            "nothing to harvest"
        );
        uint256 offeringTokenAmount = getOfferingAmount(msg.sender);
        uint256 refundingTokenAmount = getRefundingAmount(msg.sender);
        imoInfo[imoNumber].offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
        if (refundingTokenAmount > 0) {
            imoInfo[imoNumber].fundToken.safeTransfer(address(msg.sender), refundingTokenAmount);
        }
        userInfo[msg.sender].currentIMO = imoNumber;
        userInfo[msg.sender].amountFund[imoNumber] = 0;
        //totalFund = totalFund.sub(userInfo[msg.sender].amountFund);
        emit Harvest(msg.sender, offeringTokenAmount);
    }

    function currentIMO(address _user) external view returns (uint256) {
        return userInfo[_user].currentIMO;
    }

    function withdraw(uint256 _amount) public nonReentrant {
        require(
            block.number > imoInfo[imoNumber].withdrawStartBlock || block.number < imoInfo[imoNumber].endBlock,
            "not withdraw time"
        );
        require(userInfo[msg.sender].amount >= 0, "not enough to withdraw");

        lpToken.safeTransfer(address(msg.sender), _amount);
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.sub(_amount);
        userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.sub(
            _amount
        );
        totalAmount = totalAmount.sub(_amount);
        updateTierAndLimitFund(msg.sender);
    }

    function withdrawWrap(uint256 _amount) public nonReentrant {
        require(
            block.number > imoInfo[imoNumber].withdrawStartBlock || block.number < imoInfo[imoNumber].endBlock,
            "not harvest time"
        );
        require(userInfo[msg.sender].amountWrap >= 0, "not enough to withdraw");

        uint256 wrapAmount = _amount.mul(9).div(10);
        lpTokenWrap.safeTransfer(address(msg.sender), wrapAmount);
        userInfo[msg.sender].amountWrap = userInfo[msg.sender].amountWrap.sub(
            _amount
        );
        userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.sub(
            _amount
        );
        totalAmount = totalAmount.sub(_amount);
        updateTierAndLimitFund(msg.sender);
    }

    function withdrawLate(uint256 _amount) public nonReentrant {
        require(
            block.number > imoInfo[imoNumber].withdrawStartLateBlock || block.number < imoInfo[imoNumber].endBlock,
            "not harvest time"
        );
        require(userInfo[msg.sender].amountLate >= 0, "not enough to withdraw");

        lpToken.safeTransfer(address(msg.sender), _amount);
        userInfo[msg.sender].amountLate = userInfo[msg.sender].amountLate.sub(
            _amount
        );
        userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.sub(
            _amount
        );
        totalAmount = totalAmount.sub(_amount);
        updateTierAndLimitFund(msg.sender);
    }

    function withdrawWrapLate(uint256 _amount) public nonReentrant {
        require(
            block.number > imoInfo[imoNumber].withdrawStartLateBlock || block.number < imoInfo[imoNumber].endBlock,
            "not harvest time"
        );
        require(
            userInfo[msg.sender].amountWrapLate >= 0,
            "not enough to withdraw"
        );

        uint256 wrapAmount = _amount.mul(9).div(10);
        lpTokenWrap.safeTransfer(address(msg.sender), wrapAmount);
        userInfo[msg.sender].amountWrapLate = userInfo[msg.sender]
        .amountWrapLate
        .sub(_amount);
        userInfo[msg.sender].amountAll = userInfo[msg.sender].amountAll.sub(
            _amount
        );
        totalAmount = totalAmount.sub(_amount);
        updateTierAndLimitFund(msg.sender);
    }

    // allocation 100000 means 0.1(10%), 1 meanss 0.000001(0.0001%), 1000000 means 1(100%)
    function getUserAllocation(address _user) public view returns (uint256) {
        return userInfo[_user].amountFund[imoNumber].mul(1e12).div(imoInfo[imoNumber].totalFund).div(1e6);
    }

    // get the amount of IFO token you will get
    function getOfferingAmount(address _user) public view returns (uint256) {
        if (imoInfo[imoNumber].totalFund > imoInfo[imoNumber].raisingAmount) {
            uint256 allocation = getUserAllocation(_user);
            return imoInfo[imoNumber].offeringAmount.mul(allocation).div(1e6);
        } else {
            // userInfo[_user] / (raisingAmount / offeringAmount)
            return
                userInfo[_user].amountFund[imoNumber].mul(imoInfo[imoNumber].offeringAmount).div(
                    imoInfo[imoNumber].raisingAmount
                );
        }
    }

    //get the amount of lp token you will be refunded
    function getRefundingAmount(address _user) public view returns (uint256) {
        if (imoInfo[imoNumber].totalFund <= imoInfo[imoNumber].raisingAmount) {
            return 0;
        }
        uint256 allocation = getUserAllocation(_user);
        uint256 payAmount = imoInfo[imoNumber].raisingAmount.mul(allocation).div(1e6);
        return userInfo[_user].amountFund[imoNumber].sub(payAmount);
    }

    function getAddressListLength() external view returns (uint256) {
        return addressList.length;
    }

    function finalWithdraw(
        uint256 _lpAmount,
        uint256 _lpWrapAmount,
        uint256 _fundAmount,
        uint256 _offerAmount,
        uint256 _imoNumber
    ) public onlyAdmin {
        require(
            _lpAmount <= lpToken.balanceOf(address(this)),
            "not enough MMP token "
        );
        require(
            _lpWrapAmount <= lpTokenWrap.balanceOf(address(this)),
            "not enough wMMP token "
        );
        require(
            _fundAmount <= imoInfo[_imoNumber].fundToken.balanceOf(address(this)),
            "not enough fund token "
        );
        require(
            _offerAmount <= imoInfo[_imoNumber].offeringToken.balanceOf(address(this)),
            "not enough offerring token "
        );
        if (_lpAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), _lpAmount);
        }
        if (_lpWrapAmount > 0) {
            lpTokenWrap.safeTransfer(address(msg.sender), _lpWrapAmount);
        }
        if (_fundAmount > 0) {
            imoInfo[_imoNumber].fundToken.safeTransfer(address(msg.sender), _fundAmount);
            //totalFund = totalFund - _fundAmount;
        }
        if (_offerAmount > 0) {
            imoInfo[_imoNumber].offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }
    }

    function setStartBlock(uint256 _startBlock) public onlyAdmin {
        imoInfo[imoNumber].startBlock = _startBlock;
    }

    function setHarvestBlock(uint256 _harvestBlock) public onlyAdmin {
        imoInfo[imoNumber].harvestBlock = _harvestBlock;
    }

    function setStartLateBlock(uint256 _startLateBlock) public onlyAdmin {
        imoInfo[imoNumber].startLateBlock = _startLateBlock;
    }

    function setEndBlock(uint256 _endBlock) public onlyAdmin {
        imoInfo[imoNumber].endBlock = _endBlock;
    }

    function setwithdrawStartBlock(uint256 _withdrawStartBlock)
        public
        onlyAdmin
    {
        imoInfo[imoNumber].withdrawStartBlock = _withdrawStartBlock;
    }

    function setwithdrawStartLateBlock(uint256 _withdrawStartLateBlock)
        public
        onlyAdmin
    {
        imoInfo[imoNumber].withdrawStartLateBlock = _withdrawStartLateBlock;
    }

    function updateTierAndLimitFund(address _user) internal {
        require(userInfo[_user].amountAll >= 0, "have you participated?");
        if (userInfo[_user].amountAll >= requireTier[1]) {
            userInfo[_user].currentTier = Tier.One;
            userInfo[_user].fundLimit = hardCap[1];
        } else if (userInfo[_user].amountAll >= requireTier[2]) {
            userInfo[_user].currentTier = Tier.Two;
            userInfo[_user].fundLimit = hardCap[2];
        } else if (userInfo[_user].amountAll >= requireTier[3]) {
            userInfo[_user].currentTier = Tier.Three;
            userInfo[_user].fundLimit = hardCap[3];
        } else if (userInfo[_user].amountAll >= requireTier[4]) {
            userInfo[_user].currentTier = Tier.Four;
            userInfo[_user].fundLimit = hardCap[4];
        } else if (userInfo[_user].amountAll >= requireTier[5]) {
            userInfo[_user].currentTier = Tier.Five;
            userInfo[_user].fundLimit = hardCap[5];
        } else {
            userInfo[_user].currentTier = Tier.Zero;
            userInfo[_user].fundLimit = 0;
        }
    }

    function moveFromLatePoolToPool() public nonReentrant {
        require(
            block.number > imoInfo[imoNumber].withdrawStartLateBlock,
            "not wirtdraw latePool time"
        );
        require(
            userInfo[msg.sender].amountWrapLate > 0 ||
                userInfo[msg.sender].amountLate > 0,
            "have you participated in latePool?"
        );
        if (userInfo[msg.sender].amountLate > 0) {
            uint256 amountLate = userInfo[msg.sender].amountLate;
            userInfo[msg.sender].amount =
                userInfo[msg.sender].amount +
                amountLate;
            userInfo[msg.sender].amountLate = 0;
        }
        if (userInfo[msg.sender].amountWrapLate > 0) {
            uint256 amountWrapLate = userInfo[msg.sender].amountWrapLate;
            userInfo[msg.sender].amountWrap =
                userInfo[msg.sender].amountWrap +
                amountWrapLate;
            userInfo[msg.sender].amountWrapLate = 0;
        }
    }

    function setRequireTier(uint256 _tier, uint256 _require) public onlyAdmin {
        requireTier[_tier] = _require;
    }

    function setHardCap(uint256 _tier, uint256 _hardCap) public onlyAdmin {
        hardCap[_tier] = _hardCap;
    }

    function transferToVault(
    ) public onlyAdmin {
        if (imoInfo[imoNumber].fundToken.balanceOf(address(this)) > 0) {
            imoInfo[imoNumber].fundToken.safeTransfer(address(vaultAddress), imoInfo[imoNumber].totalFund);
            //totalFund = totalFund - _fundAmount;
        }
        if (imoInfo[imoNumber].offeringToken.balanceOf(address(this)) > 0) {
            imoInfo[imoNumber].offeringToken.safeTransfer(address(vaultAddress), imoInfo[imoNumber].offeringToken.balanceOf(address(this)));
        }
    }

    function getAmountFund(address _user ,uint256 _imoNumber) external view returns (uint256) {
        return userInfo[_user].amountFund[_imoNumber];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

