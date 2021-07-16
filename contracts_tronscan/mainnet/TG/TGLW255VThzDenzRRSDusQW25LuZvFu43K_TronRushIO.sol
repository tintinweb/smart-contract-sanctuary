//SourceUnit: TronRushIO.sol

pragma solidity 0.5.10;

/**
 *  _______ _____   ____  _   _ _____  _    _  _____ _    _   _____ ____      
 * |__   __|  __ \ / __ \| \ | |  __ \| |  | |/ ____| |  | | |_   _/ __ \     
 *    | |  | |__) | |  | |  \| | |__) | |  | | (___ | |__| |   | || |  | |    
 *    | |  |  _  /| |  | | . ` |  _  /| |  | |\___ \|  __  |   | || |  | |    
 *    | |  | | \ \| |__| | |\  | | \ \| |__| |____) | |  | |_ _| || |__| |    
 *    |_|  |_|  \_\\____/|_| \_|_|  \_\\____/|_____/|_|  |_(_)_____\____/     
 *
 * https://app.tronrush.io/
 */

contract TronRushIO {

    struct User {
        uint256 id;
        mapping(address => Rush1Matrix) rushWorkingPool;
        mapping(address => Rush2Matrix) rushAutoPool;
    }
    struct Rush1Matrix {
        address referrer;
        uint8 currentSlot;
        address[] referrals;
        uint256 earning;
    }
    struct Rush2Matrix {
        address referrer;
        uint8 currentSlot;
        address[] referrals; 
        uint256 earning; 
    }
    struct Slot {
        uint256 price;
        uint256 limit;
    }

    bool public preLaunchActive;
    bool public contractEnabled;
    address public owner;
    address public creator;
    uint256 public lastId;

    mapping(uint8 => uint8) public levelCommission;
    mapping(uint8 => Slot) public slots;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;

    event Registration(address indexed user, address referrer, uint256 userId, bool preLaunch);
    event Purchase(address indexed user, uint8 slot, uint8 matrix);
    event EarnedProfit(address indexed user, address referral, uint8 matrix, uint8 slot, uint8 level, uint256 amount);
    event LostProfit(address indexed user, address referral, uint8 matrix, uint8 slot, uint8 level, uint256 amount);
    event ReferralCommission(address indexed user, address referral, uint256 amount);
   
    modifier isOwner(address _account) {
        require(creator == _account, "Restricted Access!");
        _;
    }
  
    constructor(address _owner) public {
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
        _createAccount(owner, address(0), 20, false);
    }

    function() external payable {
        revert();
    }

    function registration(address _addr, address _referrer, bool temp) external payable {
        require(contractEnabled == true, "Closed");
        require(!isUserExists(_addr), "User registered");
        require(isUserExists(_referrer), "Invalid referrer");
        if (preLaunchActive == true || temp == true) {
             require(msg.value == 20000000, "Invalid amount");
            if (temp == true) {
                require(preLaunchActive == false, "Prelaunch active");
                _createAccount(_addr, _referrer, 1, true);
            }
            else {
                _createAccount(_addr, _referrer, 1, false);
            }
        }
        else {
            require(msg.value == 500000000, "Invalid amount");
            _createAccount(_addr, _referrer, 1, false);
        }
    }

    function purchase(uint8 _matrix, uint8 _slotId, bool _activation) external payable {
        require(contractEnabled == true, "Closed");
        require(preLaunchActive == false, "Prelaunch active!");
        require(isUserExists(msg.sender), "User not registered!");
        require((_matrix == 1 || _matrix == 2), "Invalid matrix");
        if (_activation == false) {
            uint8 currentSlot;
            require(msg.value == slots[_slotId].price, "Invalid amount!");
            require(_slotId > 1 && _slotId <= 20, "Invalid Slot");
            if (_matrix == 1) {
                currentSlot = users[msg.sender].rushWorkingPool[msg.sender].currentSlot;
                require(_slotId == currentSlot+1, "Invalid Slot");
            }
            else {
                currentSlot = users[msg.sender].rushAutoPool[msg.sender].currentSlot;
                require(_slotId == currentSlot+1, "Invalid Slot");
            }
            _activateSlots(msg.sender, _slotId, _matrix, false, false);
        }
        else {
            require(msg.value == 500000000, "Invalid amount!");
            require(_slotId == 1, "Invalid Slot");
            _activateSlots(msg.sender, _slotId, _matrix, true, false);
        }
        emit Purchase(msg.sender, _slotId, _matrix);
    }

    function updatePreLaunchStatus(bool _status) external isOwner(msg.sender) {
        preLaunchActive = _status;
    }

    function changeContractStatus() external isOwner(msg.sender) {
        contractEnabled = !contractEnabled;
    }

    function systemAccount(address _addr, address _referrer, uint8 _slotId) external isOwner(msg.sender) {
        require(!isUserExists(_addr), "User registered");
        require(isUserExists(_referrer), "Invalid Referrer");
        require(_slotId >= 1 && _slotId <= 20, "Invalid Slot");
        _createAccount(_addr, _referrer, 1, true);
        _activateSlots(_addr, _slotId, 1, true, true);
    }

    function failSafe(address payable _addr, uint _amount) external isOwner(msg.sender) {
        require(_addr != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_addr).transfer(_amount);
    }

    function isUserExists(address _addr) public view returns (bool) {
        return (users[_addr].id != 0);
    }

    function getUserDetails(address _addr) public view returns (uint256, uint8, uint8, uint256, uint256, address, address, address[] memory, address[] memory) {
        Rush1Matrix storage rone = users[_addr].rushWorkingPool[_addr];
        Rush2Matrix storage rtwo = users[_addr].rushAutoPool[_addr];
        return(
            users[_addr].id,
            rone.currentSlot,
            rtwo.currentSlot,
            rone.earning,
            rtwo.earning,
            rone.referrer,
            rtwo.referrer,
            rone.referrals,
            rtwo.referrals
        );
    }

	function getReferrrers(uint8 height, address _addr, uint8 _matrix) public view returns (address) {
		if (height <= 0 || _addr == address(0)) {
			return _addr;
		}
		if (_matrix == 1) {
		    return getReferrrers(height - 1, users[_addr].rushWorkingPool[_addr].referrer, _matrix);    
		}
		else {
		    return getReferrrers(height - 1, users[_addr].rushAutoPool[_addr].referrer, _matrix);
		}
	}

    function _createAccount(address _addr, address _referrer, uint8 _slotId, bool tempPlacement) internal {
        lastId++;
        User memory account = User({
            id: lastId
        });
        users[_addr] = account;
        idToAddress[lastId] = _addr;
        if (_addr != owner) {
            users[_addr].rushWorkingPool[_addr].referrer = _referrer;
            users[_referrer].rushWorkingPool[_referrer].referrals.push(_addr);
            address _referrerR2 = _findR2Referrer(_referrer, true);
            users[_addr].rushAutoPool[_addr].referrer = _referrerR2;
            users[_referrerR2].rushAutoPool[_referrerR2].referrals.push(_addr);
        }
        if (tempPlacement == false && preLaunchActive == false) {
            _activateSlots(_addr, _slotId, 1, true, false);
        }
        emit Registration(_addr, _referrer, lastId, preLaunchActive);
    }

   function _activateSlots(address _addr, uint8 _slotId, uint8 _matrix, bool _isRegistration, bool _ext) internal {
        require(!preLaunchActive, "Prelaunch is active!");
        uint256 _flushs;
        uint256 _fees;
        if (_isRegistration == true || _matrix == 1) {
            users[_addr].rushWorkingPool[_addr].currentSlot = _slotId;
            if (_ext == false) {
                (_flushs, _fees) = _sendDividends(_addr, _slotId, 1);
                if (0x2A5bb2bAc3ae381065C550Dfc9561Bbc10112537.send(_fees)) {
                    if (_flushs > 0) {
                        0xEA1DF6f051ea1eE7Fb0f2a1a9AF49CB5FF3Dba41.transfer(_flushs);
                    }
                }
            }
        }
        if (_isRegistration == true || _matrix == 2) {
            users[_addr].rushAutoPool[_addr].currentSlot = _slotId;
            if (_ext == false) {
                (_flushs, _fees) = _sendDividends(_addr, _slotId, 2);
                if (0x2A5bb2bAc3ae381065C550Dfc9561Bbc10112537.send(_fees)) {
                    if (_flushs > 0) {
                        0xEA1DF6f051ea1eE7Fb0f2a1a9AF49CB5FF3Dba41.transfer(_flushs);
                    }
                }
            }
        }
    }
    
    function _sendLevelCommission(address _addr, uint8 _slotId) internal returns (uint256) {
        uint256 profit;
        (, uint _earning, uint _maxLimit,) = _getLevelDistribution(_addr, _slotId, 2, 1);
        address _referrer = getReferrrers(1, _addr, 1);
        if (_referrer != address(0)) {
            uint256 commission = (((slots[_slotId].price * 85) / 100) * 10 / 100);
            if ((commission + _earning) < _maxLimit) {
                _processPayout(_referrer, commission);
                profit = commission;
                users[_referrer].rushAutoPool[_referrer].earning += profit; 
                emit ReferralCommission(_referrer, _addr, profit);
            }
            else {
                if (((commission + _earning) - _maxLimit) > 0 && _earning < _maxLimit) {
                    profit = _maxLimit - _earning;
                    users[_referrer].rushAutoPool[_referrer].earning += profit;
                    _processPayout(_referrer, profit);
                    emit ReferralCommission(_referrer, _addr, profit);
                    emit LostProfit(_referrer, _addr, 2, _slotId, 1, (commission - profit));
                }
                else {
                    emit LostProfit(_referrer, _addr, 2, _slotId, 1, commission);
                }
            }
        }
        return profit;
    }

    function _sendDividends(address _addr, uint8 _slotId, uint8 _matrix) internal returns (uint, uint) {
        uint256 _slotLimit = slots[_slotId].price * 85 / 100;
        uint256 _fee = slots[_slotId].price * 15 / 100;

        if (_matrix == 2) {
           _slotLimit = _slotLimit - _sendLevelCommission(_addr, _slotId);
        }
        for (uint8 _level = 1; _level <= 10; _level++) {
            (address _referrer, uint _earning, uint _maxLimit, uint _bonus) = _getLevelDistribution(_addr, _slotId, _matrix, _level);
            if (_referrer == address(0)) {
                break;
            }
            if ((_earning + _bonus) < _maxLimit) {
                if (_matrix == 1) {
                    users[_referrer].rushWorkingPool[_referrer].earning += _bonus;    
                }
                else {
                    users[_referrer].rushAutoPool[_referrer].earning += _bonus; 
                }
                _processPayout(_referrer, _bonus);
                _slotLimit = _slotLimit -  _bonus;
                emit EarnedProfit(_referrer, _addr, _matrix, _slotId, _level, _bonus);
            }
            else {
                if (((_earning + _bonus) - _maxLimit) > 0 && _earning < _maxLimit) {
                    if (_matrix == 1) {
                        users[_referrer].rushWorkingPool[_referrer].earning += (_maxLimit - _earning);    
                    }
                    else {
                        users[_referrer].rushAutoPool[_referrer].earning += (_maxLimit - _earning); 
                    }
                    _processPayout(_referrer, (_maxLimit - _earning));
                    _slotLimit = _slotLimit - (_maxLimit - _earning);
                    emit EarnedProfit(_referrer, _addr, _matrix, _slotId, _level, (_maxLimit - _earning));
                    emit LostProfit(_referrer, _addr, _matrix, _slotId, _level, _bonus - (_maxLimit - _earning));
                }
                else {
                    emit LostProfit(_referrer, _addr, _matrix, _slotId, _level, _bonus);
                }
            }
        }
        return(_slotLimit, _fee);
    }

    function _findR2Referrer(address _addr, bool deep) internal returns(address) {
		if (users[_addr].rushAutoPool[_addr].referrals.length < 2) {
			return _addr;
		}
		uint size = 2 * ((2 ** 11) - 1);
		uint previous = 2 * ((2 ** (11 - 1)) - 1);
		address referrer;
		address[] memory referrals = new address[](size);
		referrals[0] = users[_addr].rushAutoPool[_addr].referrals[0];
		referrals[1] = users[_addr].rushAutoPool[_addr].referrals[1];
		for (uint i = 0; i < size; i++) {
			if (users[referrals[i]].rushAutoPool[referrals[i]].referrals.length < 2) {
				referrer = referrals[i];
				break;
			}
			if (i < previous) {
				referrals[(i + 1) * 2] = users[referrals[i]].rushAutoPool[referrals[i]].referrals[0];
				referrals[(i + 1) * 2 + 1] = users[referrals[i]].rushAutoPool[referrals[i]].referrals[1];
			}
		}
		if (deep == true && referrer == address(0)) {
    		if (referrer == address(0)) {
    			for (uint j = previous; j < size; j++) {
    				address descendant = _findR2Referrer(referrals[j], false);
    				if (descendant != address(0)) {
    					referrer = descendant;
    					break;
    				}
    			}
    		}
		}
		return referrer;
    }

   function _getLevelDistribution(address _addr, uint8 _slotId, uint8 _matrix, uint8 _level) internal view returns(address, uint, uint, uint) {
        address referrer = getReferrrers(_level, _addr, _matrix);
        if (referrer != address(0)) {
            uint8 currentSlot;
            uint256 actualSlotPricing = (slots[_slotId].price * 85) / 100;
            uint256 bonus;
            uint256 maxLimit;
            uint256 earning;
            if (_matrix == 1) {
                bonus = actualSlotPricing * levelCommission[_level] / 100;
                earning = users[referrer].rushWorkingPool[referrer].earning;
                currentSlot = users[referrer].rushWorkingPool[referrer].currentSlot;
                for (uint8 i = 1; i <= currentSlot; i++) {
                    maxLimit += slots[i].limit;
                }
            }
            else {
                bonus = actualSlotPricing * 9 / 100;
                earning = users[referrer].rushAutoPool[referrer].earning;
                currentSlot = users[referrer].rushAutoPool[referrer].currentSlot;
                for (uint8 i = 1; i <= currentSlot; i++) {
                    maxLimit += slots[i].limit;
                }
            }
            return(
                referrer,   
                earning,
                maxLimit,
                bonus
            );
        }
    }

    function _processPayout(address _addr, uint _amount) private {
        if (!address(uint160(_addr)).send(_amount)) {
            address(uint160(owner)).transfer(_amount);
            return;
        }
    }
}