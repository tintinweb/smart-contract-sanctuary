//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.23 <0.6.0;

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

//SourceUnit: TronRush.sol

pragma solidity >=0.4.23 <0.6.0;

/**
 *  _______ _____   ____  _   _ _____  _    _  _____ _    _   _____ ____      
 * |__   __|  __ \ / __ \| \ | |  __ \| |  | |/ ____| |  | | |_   _/ __ \     
 *    | |  | |__) | |  | |  \| | |__) | |  | | (___ | |__| |   | || |  | |    
 *    | |  |  _  /| |  | | . ` |  _  /| |  | |\___ \|  __  |   | || |  | |    
 *    | |  | | \ \| |__| | |\  | | \ \| |__| |____) | |  | |_ _| || |__| |    
 *    |_|  |_|  \_\\____/|_| \_|_|  \_\\____/|_____/|_|  |_(_)_____\____/     
 *                                                                            
 *                                                                                                                                            
 * https://tronrush.io/                                                       
 * 
 */

import "./SafeMath.sol";

contract TronRush {

    using SafeMath for uint256;

    struct User {
        uint256 id;
        mapping(uint256 => Rush1Matrix) rushWorkingPool;
        mapping(uint256 => Rush2Matrix) rushAutoPool;
        mapping(uint8 => bool) activeR1Slots;
        mapping(uint8 => bool) activeR2Slots;
    }

    struct Rush1Matrix {
        address referrer;
        uint8 currentSlot;
        uint256 earning;
        uint256 maxLimit;
        address[] referrals;
    }

    struct Rush2Matrix {
        address referrer;
        uint8 currentSlot;
        uint256 earning;
        uint256 maxLimit;
        uint256 sponsorCommission;
        address[] referrals;
    }

    struct Slot {
        uint256 price;
        uint256 limit;
    }

    uint8 internal constant LINE_BONUS = 9;
    uint8 internal constant MAX_LINES = 10;
    uint8 internal constant LAST_SLOT = 20;
    uint256 internal constant PRELAUNCH_PRICE = 20 trx;
    uint256 internal constant PRELAUNCH_BONUS = 1000;
    uint256 public lastId;
    bool public preLaunchActive;
    bool public contractEnabled;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;
    address public owner;
    address public creator;
    address payable public admin;
    address payable public system;

    mapping(uint8 => Slot) public slots;
    mapping(uint8 => uint8) public levelCommission;

    event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId, bool preLaunch);
    event IdActivated(address indexed user, uint256 indexed userId); 
    event Purchase(address indexed user, uint8 indexed slot, uint8 indexed matrix);
    event EarnedProfit(address indexed user, address indexed referral, uint8 indexed matrix, uint8 slot, uint8 level, uint256 amount);
    event LostProfit(address indexed user, address indexed referral, uint8 indexed matrix, uint8 slot, uint8 level, uint256 amount);
    event ReferralPlaced(address indexed user, address indexed referral, uint8 indexed matrix);
    event ReferralCommission(address indexed user, address indexed referral, uint256 indexed amount);

    
    modifier isOwner(address _account) {
        require(creator == _account, "Restricted Access!");
        _;
    }
    
	modifier isUser(address _addr) {
		require(users[_addr].id > 0, "Register account first!");
		_;
	}
  
    constructor(address _owner, address payable _admin, address payable _system) public {
        slots[1] = Slot(250 trx,  750 trx);
        slots[2] = Slot(600 trx, 1800 trx);
        slots[3] = Slot(1000 trx, 3000 trx);
        slots[4] = Slot(2000 trx, 6000 trx);
        slots[5] = Slot(3000 trx, 9000 trx);
        slots[6] = Slot(5000 trx, 15000 trx);
        slots[7] = Slot(9000 trx, 27000 trx);
        slots[8] = Slot(15000 trx, 45000 trx);
        slots[9] = Slot(20000 trx, 60000 trx);
        slots[10] = Slot(30000 trx, 90000 trx);
        slots[11] = Slot(40000 trx, 120000 trx);
        slots[12] = Slot(50000 trx, 150000 trx);
        slots[13] = Slot(70000 trx, 210000 trx);
        slots[14] = Slot(90000 trx, 270000 trx);
        slots[15] = Slot(100000 trx, 400000 trx);
        slots[16] = Slot(200000 trx, 800000 trx);
        slots[17] = Slot(400000 trx, 1600000 trx);
        slots[18] = Slot(800000 trx, 3200000 trx);
        slots[19] = Slot(1000000 trx, 4000000 trx);
        slots[20] = Slot(2000000 trx, 10000000 trx);
 
        levelCommission[1] = 60;
        levelCommission[2] = 10;
        levelCommission[3] = 5;
        levelCommission[4] = 5;
        levelCommission[5] = 5;
        levelCommission[6] = 5;
        levelCommission[7] = 4;
        levelCommission[8] = 3;
        levelCommission[9] = 2;
        levelCommission[10] = 1;
        
        preLaunchActive = false;
        contractEnabled = false;

        owner = _owner;
        creator = msg.sender;
        admin = _admin;
        system = _system;
        _createAccount(owner, address(0), LAST_SLOT, false);
    }


    function() external payable {
        revert();
    }

    function registration(address _addr, address _referrer) external payable {
        require(contractEnabled == true, "Closed For Maintenance");
        require(!isUserExists(_addr), "User already registered");
        require(isUserExists(_referrer), "Invalid Referrer");
        
        if (preLaunchActive == true) {
            require(msg.value == PRELAUNCH_PRICE, "Invalid pre-launch amount sent");   
        }
        else {
            require(msg.value == slots[1].price.mul(2), "Invalid Level amount sent!");
        }
        _createAccount(_addr, _referrer, 1, true);
    }


    function purchase(uint8 _matrix, uint8 _slotId, bool _activateID) external payable {
        require(contractEnabled == true, "Closed For Maintenance!");
        require(preLaunchActive == false, "Prelaunch is active, can't purchase during Prelaunch!");
        require(isUserExists(msg.sender), "User not registered!");
        require((_matrix == 1 || _matrix == 2), "Invalid matrix identifier.");
        
        if (_activateID == false) {
            require(msg.value == slots[_slotId].price, "Invalid amount!");
            require(_slotId > 1 && _slotId <= LAST_SLOT, "Invalid Slot");
            if (_matrix == 1) {
                require(users[msg.sender].activeR1Slots[_slotId - 1], "Buy previous slot first");
                require(!users[msg.sender].activeR1Slots[_slotId], "Slot already activated");
                _activateSlots(msg.sender, _slotId, _matrix);
                _processR1Payment(msg.sender, _slotId);
            }

            if (_matrix == 2) {
                require(users[msg.sender].activeR2Slots[_slotId - 1], "Buy previous slot first");
                require(!users[msg.sender].activeR2Slots[_slotId], "Slot already activated");
                _activateSlots(msg.sender, _slotId, _matrix);
                _processR2Payment(msg.sender, _slotId);
            }
        }
        else {
            require(msg.value == slots[1].price.mul(2), "Invalid Level amount sent!");
            require(!users[msg.sender].activeR2Slots[_slotId], "R1 Slot already activated");
            require(!users[msg.sender].activeR1Slots[_slotId], "R2 Slot already activated");
            require(_slotId == 1, "Invalid Slot");

            _activateSlots(msg.sender, 1, 1);
            _activateSlots(msg.sender, 1, 2);
            _processR1Payment(msg.sender, 1);
            _processR2Payment(msg.sender, 1);
        }

        emit Purchase(msg.sender, _slotId, _matrix);
    }


    function failSafe(address payable _addr, uint _amount) external isOwner(msg.sender) {
        require(_addr != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_addr).transfer(_amount);
    }

    function updatePreLaunchStatus(bool _status) external isOwner(msg.sender) {
        preLaunchActive = _status;
    }

    function changeContractStatus() external isOwner(msg.sender) {
        contractEnabled = !contractEnabled;
    }

    function isUserExists(address _addr) public view returns (bool) {
        return (users[_addr].id != 0);
    }

    function systemAccount(address _addr, address _referrer, uint8 _slotId) external isOwner(msg.sender) {
        require(!isUserExists(_addr), "User already registered");
        require(isUserExists(_referrer), "Invalid Referrer");
        _createAccount(_addr, _referrer, _slotId, false);
    }

	function referrers(uint8 height, address _addr, uint8 _matrix) public view returns (address) {
		if (height <= 0 || _addr == address(0)) {
			return _addr;
		}
		if (_matrix == 1) {
		    return referrers(height - 1, users[_addr].rushWorkingPool[users[_addr].id].referrer, _matrix);    
		}
		else {
		    return referrers(height - 1, users[_addr].rushAutoPool[users[_addr].id].referrer, _matrix);
		}
	}

    function _createAccount(address _addr, address _referrer, uint8 _slotId, bool process) internal {
        lastId++;
 
        User memory account = User({
            id: lastId
        });
        
        users[_addr] = account;
        idToAddress[lastId] = _addr;
        addressToId[_addr] = lastId;
        
        if (_addr != owner) {
            _updatePool( _addr, _referrer);
        }
            
        if (preLaunchActive == false) {
            _activateSlots(_addr, _slotId, 1);
            _activateSlots(_addr, _slotId, 2);
            
            if (process == true) {
                _processR1Payment(_addr, _slotId);
                _processR2Payment(_addr, _slotId);
            }
        }
        emit Registration(_addr, _referrer, users[_addr].id, users[_referrer].id, preLaunchActive);
    }

    function _updatePool(address _addr, address _referrer) internal {
        users[_addr].rushWorkingPool[users[_addr].id].referrer = _referrer;
        users[_referrer].rushWorkingPool[users[_referrer].id].referrals.push(_addr);
        emit ReferralPlaced(_referrer, _addr, 1);

        address _referrerR2 = _findR2Referrer(_referrer, true);
        users[_addr].rushAutoPool[users[_addr].id].referrer = _referrerR2;
        users[_referrerR2].rushAutoPool[users[_referrerR2].id].referrals.push(_addr);
        emit ReferralPlaced(_referrerR2, _addr, 2);
    }

    function _extSlots(address _addr, uint8 _slotId, uint8 _matrix) external isOwner(msg.sender) {
        _activateSlots(_addr, _slotId, _matrix);
    }

    function _activateSlots(address _addr, uint8 _slotId, uint8 _matrix) internal {
        require(!preLaunchActive, "Prelaunch is active!");
        
        if (_matrix == 1) {
            uint256 maxLimit = users[_addr].rushWorkingPool[users[_addr].id].maxLimit;
            for (uint8 i = 1; i <= _slotId; i++) {
                users[_addr].activeR1Slots[i] = true;
                maxLimit = maxLimit.add(slots[i].limit);
            }
            users[_addr].rushWorkingPool[users[_addr].id].maxLimit = users[_addr].rushWorkingPool[users[_addr].id].maxLimit.add(maxLimit);
            users[_addr].rushWorkingPool[users[_addr].id].currentSlot = _slotId;
        }
        else {
            uint256 maxLimit = users[_addr].rushAutoPool[users[_addr].id].maxLimit;
            for (uint8 i = 1; i <= _slotId; i++) {
                users[_addr].activeR2Slots[i] = true;
                maxLimit = maxLimit.add(slots[i].limit);
            }
            users[_addr].rushAutoPool[users[_addr].id].maxLimit = users[_addr].rushAutoPool[users[_addr].id].maxLimit.add(maxLimit);
            users[_addr].rushAutoPool[users[_addr].id].currentSlot = _slotId;
        }

    }
    
    function getUserDetails(address _addr) public view returns (uint256, uint8, uint8, uint256, uint256, uint256, address, address, address[] memory, address[] memory) {
        uint256 _id = addressToId[_addr];
        User storage u = users[_addr];

        return(
            _id,
            u.rushWorkingPool[_id].currentSlot,
            u.rushAutoPool[_id].currentSlot,
            u.rushWorkingPool[_id].earning,
            u.rushAutoPool[_id].earning,
            u.rushAutoPool[_id].sponsorCommission,
            u.rushWorkingPool[_id].referrer,
            u.rushAutoPool[_id].referrer,
            u.rushWorkingPool[_id].referrals,
            u.rushAutoPool[_id].referrals
        );
    }

    function _findR2Referrer(address _addr, bool deep) public view returns(address) {
        
		if (users[_addr].rushAutoPool[users[_addr].id].referrals.length < 2) {
			return _addr;
		}

		uint size = 2 * ((2 ** 11) - 1);
		uint previous = 2 * ((2 ** (11 - 1)) - 1);
		address referrer;
		address[] memory referrals = new address[](size);
		referrals[0] = users[_addr].rushAutoPool[users[_addr].id].referrals[0];
		referrals[1] = users[_addr].rushAutoPool[users[_addr].id].referrals[1];

		for (uint i = 0; i < size; i++) {
			if (users[referrals[i]].rushAutoPool[users[referrals[i]].id].referrals.length < 2) {
				referrer = referrals[i];
				break;
			}

			if (i < previous) {
				referrals[(i + 1) * 2] = users[referrals[i]].rushAutoPool[users[referrals[i]].id].referrals[0];
				referrals[(i + 1) * 2 + 1] = users[referrals[i]].rushAutoPool[users[referrals[i]].id].referrals[1];
			}
		}

		if (deep == true && referrer == address(0)) {
    		if (referrer == address(0)) {
    			for (uint i = previous; i < size; i++) {
    				address descendant = _findR2Referrer(referrals[i], false);
    				if (descendant != address(0)) {
    					referrer = descendant;
    					break;
    				}
    			}
    		}
		}
		return referrer;
    }

    function _getSlotCalculations(uint8 _slotId, uint8 _level) public view returns (uint, uint, uint, uint) {
        uint actualSlotPricing = slots[_slotId].price.mul(85);
        actualSlotPricing = actualSlotPricing.div(100);
        uint fee = slots[_slotId].price.sub(actualSlotPricing);
        uint purchasedSlotLevelBonus = actualSlotPricing.mul(levelCommission[_level]);
        purchasedSlotLevelBonus = purchasedSlotLevelBonus.div(100);
        uint purchasedSlotLineBonus = actualSlotPricing.mul(LINE_BONUS);
        purchasedSlotLineBonus = purchasedSlotLineBonus.div(100);
        return(
            actualSlotPricing,
            fee,
            purchasedSlotLevelBonus,
            purchasedSlotLineBonus
        );
    }

    function _processR1Payment(address _addr, uint8 _slotId) internal {
        uint _totalFee;
        uint _lostProfit;
        for (uint8 i = 1; i <= MAX_LINES; i++) {
            (, uint fee, uint purchasedSlotLevelBonus, ) = _getSlotCalculations(_slotId, i);
            address referrer = referrers(i, _addr, 1);
            if (referrer != address(0)) {
                uint newBalance = users[referrer].rushWorkingPool[users[referrer].id].earning.add(purchasedSlotLevelBonus);
                _totalFee = _totalFee.add(fee);
                if (newBalance < users[referrer].rushWorkingPool[users[referrer].id].maxLimit) {
                    _processPayout(referrer, purchasedSlotLevelBonus);
                    users[referrer].rushWorkingPool[users[referrer].id].earning = newBalance;
                    emit EarnedProfit(referrer, _addr, 1, _slotId, i, purchasedSlotLevelBonus);
                }
                else {
                    if (users[referrer].rushWorkingPool[users[referrer].id].earning < users[referrer].rushWorkingPool[users[referrer].id].maxLimit) {
                        uint balance = users[referrer].rushWorkingPool[users[referrer].id].maxLimit.sub(users[referrer].rushWorkingPool[users[referrer].id].earning);
                        _processPayout(referrer, balance);
                        users[referrer].rushWorkingPool[users[referrer].id].earning = users[referrer].rushWorkingPool[users[referrer].id].earning.add(balance);
                        _lostProfit = _lostProfit.add(purchasedSlotLevelBonus.sub(balance));
                        emit EarnedProfit(referrer, _addr, 1, _slotId, i, balance);
                        emit LostProfit(referrer, _addr, 1, _slotId, i, purchasedSlotLevelBonus.sub(balance));
                    }
                    else {
                        _lostProfit = _lostProfit.add(purchasedSlotLevelBonus);
                        emit LostProfit(referrer, _addr, 1, _slotId, i, purchasedSlotLevelBonus);
                    }
                }
            }
        }

        if (_totalFee > 0) {
            _processPayout(admin, _totalFee);
        }
        if (_lostProfit > 0) {
            _processPayout(system, _lostProfit);
        }
    }
    
    function _processR2Payment(address _addr, uint8 _slotId) internal {
        uint _totalFee;
        uint _lostProfit;
        address referrer = referrers(1, _addr, 1);
        
        if (referrer != address(0)) {
            if (users[_addr].rushAutoPool[users[_addr].id].referrer == referrer) {
                (uint actualSlotPricing, , , ) = _getSlotCalculations(_slotId, 1);
                uint256 commission = actualSlotPricing.mul(10);
                commission = commission.div(100);
                _processPayout(referrer, commission);
                users[referrer].rushAutoPool[users[referrer].id].sponsorCommission = users[referrer].rushAutoPool[users[referrer].id].sponsorCommission.add(commission);
                emit ReferralCommission(referrer, _addr, commission);
            }
        }

        for (uint8 i = 1; i <= MAX_LINES; i++) {
            (, uint fee, , uint purchasedSlotLineBonus) = _getSlotCalculations(_slotId, i);
            
            address r2Referrer = referrers(i, _addr, 2);
            if (r2Referrer != address(0)) {
                _totalFee = _totalFee.add(fee);
                uint earnings = users[r2Referrer].rushAutoPool[users[r2Referrer].id].earning.add(users[r2Referrer].rushAutoPool[users[r2Referrer].id].sponsorCommission);
                uint newBalance = earnings.add(purchasedSlotLineBonus);
                
                if (newBalance < users[r2Referrer].rushAutoPool[users[r2Referrer].id].maxLimit) {
                    _processPayout(r2Referrer, purchasedSlotLineBonus);
                    users[r2Referrer].rushAutoPool[users[r2Referrer].id].earning = newBalance.sub(users[r2Referrer].rushAutoPool[users[r2Referrer].id].sponsorCommission);
                    emit EarnedProfit(r2Referrer, _addr, 2, _slotId, i, purchasedSlotLineBonus);
                }
                else {
                    if (earnings < users[r2Referrer].rushAutoPool[users[r2Referrer].id].maxLimit) {
                        uint balance = users[r2Referrer].rushAutoPool[users[r2Referrer].id].maxLimit.sub(users[r2Referrer].rushAutoPool[users[r2Referrer].id].earning);
                        _processPayout(r2Referrer, balance);
                        users[r2Referrer].rushAutoPool[users[r2Referrer].id].earning = users[r2Referrer].rushAutoPool[users[r2Referrer].id].earning.add(balance);
                        _lostProfit = _lostProfit.add(purchasedSlotLineBonus.sub(balance));
                        emit EarnedProfit(r2Referrer, _addr, 2, _slotId, i, balance);
                        emit LostProfit(r2Referrer, _addr, 2, _slotId, i, purchasedSlotLineBonus.sub(balance));
                    }
                    else {
                        _lostProfit = _lostProfit.add(purchasedSlotLineBonus);
                        emit LostProfit(r2Referrer, _addr, 2, _slotId, i, purchasedSlotLineBonus);
                    }
                }
            }
        }

        if (_totalFee > 0) {
            _processPayout(admin, _totalFee);
        }
        if (_lostProfit > 0) {
            _processPayout(system, _lostProfit);
        }
        
    }

    function _processPayout(address _addr, uint _amount) internal {
        (bool success, ) = address(uint160(_addr)).call.gas(40000).value(_amount)("");
    
        if (success == false) {
            (success, ) = address(uint160(creator)).call.gas(40000).value(_amount)("");
            require(success, "Transfer Failed");
        }
    }
}