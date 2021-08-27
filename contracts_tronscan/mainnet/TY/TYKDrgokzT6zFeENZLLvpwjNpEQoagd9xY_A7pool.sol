//SourceUnit: A7Pool.sol


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


pragma solidity ^0.5.0;


    contract A7pool {
        using SafeMath for uint256;
        uint256 private _suanliprice;
        address private _owner;
        uint256 public _release;
        uint256 private _lastTime;
        uint256 private _beginTime;
        uint256 private _days;
        uint256 private _turn;
        uint256 constant public INVEST_MIN_AMOUNT = 1;
        uint256[] public REFERRAL_PERCENTS = [200,100,50,200];
        uint256 constant public PERCENTS_DIVIDER = 1000;
        uint256 constant public TIME_STEP = 1 days;
        uint256 public totalUsers;
        uint256 public totalInvested;
        uint256 public totalWithdrawn;
 	    uint256 public totalDeposits;
        bool private _iscaninvest;
        
        struct Deposit {
            uint256 amount;
            uint256 withdrawn;
            uint256 start;
            uint256 desposittype;
        }

        struct User {
            Deposit[] deposits;
            uint256 checkpoint;
            address referrer;
            uint256 isteamleader;
            uint256[] teamamount;
        }

        struct TodayDeposit {
            uint256 amount;
            uint256 timestamp;
        }
        TodayDeposit[]  todayDeposits;

        address private _A7Addr;
        FMToken A7Token;
        mapping (address => User) internal users;
        event Newbie(address user);
        event NewDeposit(address indexed user, uint256 amount);
        event Withdrawn(address indexed user, uint256 amount);
        
        constructor(address a7Addr)  public {
            _owner = msg.sender;
            _A7Addr=a7Addr;
            A7Token = FMToken(_A7Addr);
            _suanliprice=100* (10 ** 6);
            _release=16666 *9 * (10 ** 5);
            _lastTime = 1629907199;
            _beginTime = 1629907199;
            _turn = 0;
            _days =0;
            _iscaninvest=true;
            

        }

        function issue() public returns (bool){
            if(block.timestamp.sub(_lastTime) < 86400){
                return true;
            }
            uint256 nowturn = _days/360;
            if(nowturn > _turn){
                _turn = nowturn;
                _release = _release*9/10;
            }
            _lastTime = _lastTime.add(86400);
            _days = _days.add(1);
            return true;
        }
        
        

     function invest(address referrer,uint256 suanli) public returns (bool){
        uint256 a7Amount=suanli.mul(_suanliprice).div(1000000);
        require(suanli >= 1000000);
        require(_iscaninvest == true, "It's not invest");
        
        uint a7balances = A7Token.balanceOf(msg.sender);
        require(a7balances>a7Amount, "It's not enough A7 Token");
        require( A7Token.burnFrom(msg.sender, a7Amount),"token transfer failed");
        uint256 dayindex=block.timestamp.sub(_beginTime).div(TIME_STEP);

        if (todayDeposits.length > 0) {
			if (todayDeposits[todayDeposits.length-1].timestamp != dayindex) {
				todayDeposits.push(TodayDeposit(0, dayindex));
			}
		}
        else{
            todayDeposits.push(TodayDeposit(0, dayindex));
        }
        User storage user = users[msg.sender];
        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
 		}
        if (user.referrer != address(0)) {
			address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 suanli1 = suanli.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].deposits.push(Deposit(suanli1, 0, block.timestamp,i+1));
                    totalInvested = totalInvested.add(suanli1);
                    todayDeposits[todayDeposits.length-1].amount=todayDeposits[todayDeposits.length-1].amount.add(suanli1);
                    emit NewDeposit(upline, suanli1);
				    users[upline].teamamount[i]=users[upline].teamamount[i]+suanli;
					upline = users[upline].referrer;
               } else break;
			}
			upline = user.referrer;
			while(upline != address(0)){
                if(users[upline].isteamleader==1){
                    uint256 suanli1 = suanli.mul(REFERRAL_PERCENTS[3]).div(PERCENTS_DIVIDER);
					users[upline].deposits.push(Deposit(suanli1, 0, block.timestamp,4));
                    totalInvested = totalInvested.add(suanli1);
                    todayDeposits[todayDeposits.length-1].amount=todayDeposits[todayDeposits.length-1].amount.add(suanli1);
                    users[upline].teamamount[3]=users[upline].teamamount[3]+suanli;
				
                    emit NewDeposit(upline, suanli1);
                    break;
                }
                upline = users[upline].referrer;
			}
		}
        if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
            for (uint256 i = 0; i < 4; i++) {
                user.teamamount.push(0);
            }
            totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
        user.deposits.push(Deposit(suanli, 0, block.timestamp,0));
        totalInvested = totalInvested.add(suanli);
        todayDeposits[todayDeposits.length-1].amount=todayDeposits[todayDeposits.length-1].amount.add(suanli);
		totalDeposits = totalDeposits.add(1);
        emit NewDeposit(msg.sender, suanli);
        return true;
        
    }

        function withdraw() public {
            User storage user = users[msg.sender];
            uint256 totalAmount;
            uint256 dividends;
            for (uint256 i = 0; i < user.deposits.length; i++) {
                    if (user.deposits[i].start > user.checkpoint) {
                        dividends = (user.deposits[i].amount
                            .mul(_release).div(totalInvested))
                            .mul(block.timestamp.sub(user.deposits[i].start))
                            .div(TIME_STEP);
                    } else {
                        dividends = (user.deposits[i].amount
                            .mul(_release).div(totalInvested))
                            .mul(block.timestamp.sub(user.checkpoint))
                            .div(TIME_STEP);

                    }
                    user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); 
                    totalAmount = totalAmount.add(dividends);
            }

            require(totalAmount > 0, "User has no dividends");
            
            uint256 amount = A7Token.balanceOf(address(this));
            require(amount >= totalAmount, "It's not enough A7 Token");
            
            A7Token.transfer(msg.sender, totalAmount);
        
            user.checkpoint = block.timestamp;
            
            totalWithdrawn = totalWithdrawn.add(totalAmount);

            emit Withdrawn(msg.sender, totalAmount);
            
        }


	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalDividends;
		uint256 dividends;

            for (uint256 i = 0; i < user.deposits.length; i++) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (user.deposits[i].amount
                        .mul(_release).div(totalInvested))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.deposits[i].amount
                        .mul(_release).div(totalInvested))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }
                 totalDividends = totalDividends.add(dividends);
            }


		return totalDividends;
	}

    function getTodayDeposit() public view returns (uint256){
        uint256 dayindex=block.timestamp.sub(_beginTime).div(TIME_STEP);
        if(todayDeposits.length>0 && todayDeposits[todayDeposits.length-1].timestamp==dayindex){
            return todayDeposits[todayDeposits.length-1].amount;
        }
        else{
            return 0;
        }
     }

        function getsuanliprice() public view returns (uint256){
                return _suanliprice;
        }
            
        function setsuanliprice(uint256 suanliprice) public returns (bool){
            if(msg.sender == _owner){
                _suanliprice=suanliprice;
            }
            return true;
        }
        function setcaninvest(bool flag) public returns (bool){
            if(msg.sender == _owner){
                _iscaninvest=flag;
            }
            return true;
        }

        
        function getcaninvest(bool flag) public view returns (bool){
                return _iscaninvest;
         }
            
        function bindA7address(address A7address) public returns (bool){
            if(msg.sender == _owner){
                _A7Addr=A7address;
                A7Token = FMToken(_A7Addr);
            }
            return true;
        }
        function bindOwner(address addressOwner) public returns (bool){
            if(msg.sender == _owner){
                _owner = addressOwner;
            }
            return true;
        }

        function setteamleader(address useraddress,uint flage) public returns (bool){
            if(msg.sender == _owner){
                users[useraddress].isteamleader = flage;
            }
            return true;
        }

        function getteamleader(address useraddress) public view returns (uint256){
             if(msg.sender == _owner){
                return  users[useraddress].isteamleader ;
             }else{
                 return users[msg.sender].isteamleader ;
             }
        }


        function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}


	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
				return true;
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];
		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start, user.deposits[index].desposittype);
	}


	function getUserTeamsAmount(address userAddress,uint256 index) public view returns(uint256) {
	    return users[userAddress].teamamount[index];
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}

    } 
       



    contract FMToken {
       function burnFrom(address addr, uint value) public   returns (bool);
       function transfer(address to, uint value) public;
       function transferFrom(address from, address to, uint value) public returns (bool);
       function balanceOf(address who) external view returns (uint);
    }