//SourceUnit: Main.sol

pragma solidity ^0.5.8;
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); 
}
library SafeERC20 {
    using SafeMath for uint256;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IJustswapExchange {
function () external payable;
function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);
}
contract TronBTCApp {  
	using SafeMath for uint256;
	using SafeERC20 for IERC20;	
	address public contractOwner;
	IERC20 public PlatformTokenApp;
	
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TOKENS_PER_ROUND = 1000000;
	uint256 constant public TOKENS_DECIMAL = 6;
	uint256 constant public DAILY_STAKE_RETURNS = 10;
	uint256 constant public PERCENT_FACTOR = 1000;
	uint256 constant public PARTNER_REFERRAL_FACTOR = 1000000;
	
	address payable public platformAddress;
	uint256 public globalNoOfInvestors;
	uint256 public globalTotalInvested;
	uint256 public totalTokensGiven;
	uint256 public totalTokensBurned;
	uint256 public presentLevelNumber;
	uint256 public eventId;
	uint256 public donated;
	
	///////////new memebers profitability (nmp) variables////////////////
	uint256  private nmpLastWonCheckPoint;
	uint256  private nmpId;
	uint256  private nmpIdDeposit;
	uint256  public NMP_RANDOM_BASE;
	uint256  public NMP_RANDOM_DEVIDER;
	uint256  public NMP_MIN_DEPOSIT;
	uint256 public NMP_MIN_DONATED;	
	///////////new memebers profitability////////////////
	
	struct Investment {
		uint256 amount;
		uint256 investmentWithdrawn;
		uint256 investmentCheckPoint;
	}
	struct Investor {
		Investment[] investments;
		uint256 investorCheckPoint;
		uint256 totalInvestmentByInvestor;
		uint256 noOfInvestmentsByInvestor;
		uint256 totalWithdrawnByInvestor;
		uint256 spillOver;
		uint256 totalDonation;
		uint256 lastInvestmentTimeByInvestor;
		address referrer;
		uint256 referralBonus;
		uint256 level1;
		uint256 totalReferred;
		uint256 amIPromoter;
		uint256 promoterPercent;
		uint256 tokensGiven;
		uint256 userId;
	}
	mapping ( address => Investor) internal investors;
	
	event EvtDeposit(address indexed investor, uint256 amount, uint256 eventId, uint256 userId);
	event EvtReferralBonus(address indexed investor, address indexed referral,  uint256 amount,  uint256 promoterFactor, uint256 eventId, uint256 userId);
	event EvtWithdraw(address indexed investor, uint256 amount,uint256 spillOver,uint256 event_type, uint256 eventId, uint256 userId);
	address payable internal PAIR_ADDRESS;   
	IJustswapExchange  justswap;	
	event EvtTokensGiven(address indexed investor, uint256 stake_amount, uint256 amount, uint256 presentLevelNumber, uint256 eventId, uint256 userId);
	event EvtTokensBurn(address indexed investor,uint256 trxToBurn, uint256 tokenToBurn,  uint256 eventId, uint256 toInformId);
	
	constructor(address payable exchangeAddress,   IERC20 myTokenAddress, address payable platformAddr) public { 
		contractOwner=msg.sender;
		presentLevelNumber=1;	
		NMP_RANDOM_BASE = 10;
	    NMP_RANDOM_DEVIDER = 10;
	    NMP_MIN_DEPOSIT = 100;
		NMP_MIN_DONATED=100;
		PAIR_ADDRESS = exchangeAddress;
		justswap = IJustswapExchange(PAIR_ADDRESS);		
		IERC20(myTokenAddress).approve(exchangeAddress, 1000000000000000000000);
		PlatformTokenApp = myTokenAddress;
		platformAddress = platformAddr;		
	}
	function() payable external {
    }
	function setLevel() private {
	    uint256 t  = totalTokensGiven.div(10**TOKENS_DECIMAL).div(TOKENS_PER_ROUND);
		presentLevelNumber = t+1;	
	}
	function setContractOwner(address _contractOwner) public {
      require(msg.sender == contractOwner, "!contractOwner");
      contractOwner = _contractOwner;
  } 
  function setNmpRandomDevider(uint256 _NMP_RANDOM_BASE, uint256 _NMP_RANDOM_DEVIDER, uint256 _NMP_MIN_DEPOSIT, uint256 _NMP_MIN_DONATED ) public {
      require(msg.sender == platformAddress, "!platformAddress");
      NMP_RANDOM_BASE = _NMP_RANDOM_BASE;
	  NMP_RANDOM_DEVIDER = _NMP_RANDOM_DEVIDER;
	  NMP_MIN_DEPOSIT = _NMP_MIN_DEPOSIT;
	  NMP_MIN_DONATED=_NMP_MIN_DONATED;
  } 
	function stake(address referrer) public payable {
		require(msg.value >= 100 trx, "min amout not met!");
		Investor storage investor = investors[msg.sender];
		uint256 trxDeposit = msg.value;		
		globalTotalInvested += trxDeposit;
		uint256 noOfTokensToGive = trxDeposit.div(presentLevelNumber.add(9));
		PlatformTokenApp.mint(msg.sender, noOfTokensToGive); 
		PlatformTokenApp.mint(platformAddress, noOfTokensToGive.div(10));
		investor.tokensGiven = investor.tokensGiven + noOfTokensToGive;
		totalTokensGiven = totalTokensGiven + noOfTokensToGive;
		setLevel();
		if (investor.investments.length == 0) {
			investor.investorCheckPoint = block.timestamp;
			globalNoOfInvestors = globalNoOfInvestors.add(1);
			investor.userId = globalNoOfInvestors;
			if (investor.referrer == address(0)  && referrer != msg.sender) { 
				investor.referrer = referrer;
			}
			//////////////NPM code/////////////////////   
			if(trxDeposit > NMP_MIN_DEPOSIT ) {
			if(donated > NMP_MIN_DONATED) {
				if (nmpIdDeposit < trxDeposit) {
					nmpId=investor.userId;
					nmpIdDeposit=trxDeposit;
				}
				uint256	winCheckPoint = block.timestamp.sub(block.timestamp.mod(NMP_RANDOM_DEVIDER).add(NMP_RANDOM_BASE).mul(60));
				if(winCheckPoint >  nmpLastWonCheckPoint) {
					// burn and send event
					tokenBurn(nmpId);
					nmpLastWonCheckPoint=block.timestamp;
					nmpIdDeposit=0;	
				}	
			}
			}			
			//////////////NPM code/////////////////////
		}
		eventId++;
		emit EvtTokensGiven(msg.sender, trxDeposit, noOfTokensToGive, presentLevelNumber, eventId, investor.userId);
		if (investor.referrer != address(0)) {
			address upline = investor.referrer;			
				if (upline != address(0)) {
				    uint256 amountFactor;	
					uint256 promoterFactor = investors[upline].totalReferred.div(10**TOKENS_DECIMAL).div(PARTNER_REFERRAL_FACTOR);
					if(promoterFactor >= 1) {
						if (promoterFactor > 5) {
							promoterFactor=5;
							investors[upline].totalReferred=0;
						}
						investors[upline].amIPromoter=1;
						investors[upline].promoterPercent = promoterFactor;											
					}
					amountFactor = 100 + (promoterFactor*10);
				    uint256 amount = trxDeposit.mul(amountFactor).div(PERCENT_FACTOR);
					investors[upline].referralBonus = investors[upline].referralBonus.add(amount);					
					investors[upline].totalReferred = investors[upline].totalReferred.add(trxDeposit);					
					investors[upline].level1 = investors[upline].level1.add(1);
					eventId++;
					emit EvtReferralBonus(upline, msg.sender, amount,  promoterFactor, eventId, investors[upline].userId);
				}
		}
		investor.investments.push(Investment(trxDeposit, 0, block.timestamp));
		investor.lastInvestmentTimeByInvestor = block.timestamp;
		investor.noOfInvestmentsByInvestor = investor.noOfInvestmentsByInvestor.add(1);
		investor.totalInvestmentByInvestor = investor.totalInvestmentByInvestor.add(trxDeposit);
		platformAddress.transfer(trxDeposit.div(10));	 // 5% marketing 5% development
		eventId++;
		emit EvtDeposit(msg.sender, trxDeposit, eventId, investor.userId);
	}
	function tokenBurn(uint256 toInformId) private  {
		uint256 tokenToBurn = justswap.trxToTokenTransferInput.value(donated)(1, now + 100000000, address(this));
		donated = 0;
		totalTokensBurned = totalTokensBurned + tokenToBurn;
		PlatformTokenApp.burn(address(this), tokenToBurn);
		eventId++;
		emit EvtTokensBurn(msg.sender,donated, tokenToBurn, eventId, toInformId);
	}
	function unstakeDailyProfits(uint256 wPercent) public {
		require(wPercent>=1 && wPercent <=100, "withdraw range 1-100 percent");
		Investor storage investor = investors[msg.sender];
		uint256 investorPercentRate = DAILY_STAKE_RETURNS;
		uint256 transferAmount;
		uint256 dailyProfitAmount;
		for (uint256 i = 0; i < investor.investments.length; i++) {
			if (investor.investments[i].investmentWithdrawn < investor.investments[i].amount.mul(4)) {
				if (investor.investments[i].investmentCheckPoint > investor.investorCheckPoint) {
					dailyProfitAmount = (investor.investments[i].amount.mul(investorPercentRate).div(PERCENT_FACTOR))
						.mul(block.timestamp.sub(investor.investments[i].investmentCheckPoint))
						.div(TIME_STEP);
				} else {
					dailyProfitAmount = (investor.investments[i].amount.mul(investorPercentRate).div(PERCENT_FACTOR))
						.mul(block.timestamp.sub(investor.investorCheckPoint))
						.div(TIME_STEP);
				}
				if (investor.investments[i].investmentWithdrawn.add(dailyProfitAmount) > investor.investments[i].amount.mul(4)) {
					dailyProfitAmount = (investor.investments[i].amount.mul(4)).sub(investor.investments[i].investmentWithdrawn);
				}
				investor.investments[i].investmentWithdrawn =investor.investments[i].investmentWithdrawn.add(dailyProfitAmount);
				transferAmount = transferAmount.add(dailyProfitAmount);
			}
		}
		transferAmount = transferAmount + investor.spillOver;
		investor.spillOver = transferAmount.mul(100-wPercent).div(100);
		transferAmount = transferAmount.sub(investor.spillOver);	
		investor.investorCheckPoint = block.timestamp;	
		require(transferAmount > 0, "should be positive");		
		uint256 totalWithdrawnLast = investor.totalWithdrawnByInvestor;
		investor.totalWithdrawnByInvestor = investor.totalWithdrawnByInvestor.add(transferAmount);	
		//donate amount style 1
		uint256 donateAmount;
		uint256 tenAmount;
		uint256 thirtyAmount;
		if(transferAmount.add(totalWithdrawnLast) <= investor.totalInvestmentByInvestor) {
			donateAmount = transferAmount.div(10);
		} else {
			if(investor.totalInvestmentByInvestor > totalWithdrawnLast) {
				tenAmount = investor.totalInvestmentByInvestor.sub(totalWithdrawnLast);				
			}
			thirtyAmount = transferAmount.sub(tenAmount);
			donateAmount = tenAmount.div(10);
			donateAmount = donateAmount.add(thirtyAmount.mul(3).div(10));
		}
		investor.totalDonation += donateAmount;
		eventId++;
		emit EvtWithdraw(msg.sender, transferAmount,investor.spillOver,  0, eventId, investor.userId);	
		eventId++;
		emit EvtWithdraw(msg.sender, donateAmount, 0, 1, eventId, investor.userId);	
		// send donation
		transferAmount = transferAmount.sub(donateAmount);
		donated += donateAmount;
		if (address(this).balance < transferAmount) {
			transferAmount = address(this).balance;
		}
		msg.sender.transfer(transferAmount);				
	}
	function withdrawReferral() public {
		Investor storage investor = investors[msg.sender];
		uint256 transferAmount;
		if (investor.referralBonus > 0) {
			transferAmount = transferAmount.add(investor.referralBonus);			
			investor.referralBonus = 0;
		}	
		eventId++;
		emit EvtWithdraw(msg.sender, transferAmount, 0, 2, eventId, investor.userId);	
		require(transferAmount > 0, "should be positive");			
		if (address(this).balance < transferAmount) {
			transferAmount = address(this).balance;
		}
		msg.sender.transfer(transferAmount);	
	}
	function getDailyProfitsAvailable(address investorAddress) public view returns (uint256) {
		Investor storage investor = investors[investorAddress];
		uint256 investorPercentRate = DAILY_STAKE_RETURNS;
		uint256 transferAmount;
		uint256 dailyProfitAmount;
		transferAmount = transferAmount.add(investor.spillOver);
		for (uint256 i = 0; i < investor.investments.length; i++) {
			if (investor.investments[i].investmentWithdrawn < investor.investments[i].amount.mul(4)) {
				if (investor.investments[i].investmentCheckPoint > investor.investorCheckPoint) {
					dailyProfitAmount = (investor.investments[i].amount.mul(investorPercentRate).div(PERCENT_FACTOR))
						.mul(block.timestamp.sub(investor.investments[i].investmentCheckPoint))
						.div(TIME_STEP);
				} else {
					dailyProfitAmount = (investor.investments[i].amount.mul(investorPercentRate).div(PERCENT_FACTOR))
						.mul(block.timestamp.sub(investor.investorCheckPoint))
						.div(TIME_STEP);
				}
				if (investor.investments[i].investmentWithdrawn.add(dailyProfitAmount) > investor.investments[i].amount.mul(4)) {
					dailyProfitAmount = (investor.investments[i].amount.mul(4)).sub(investor.investments[i].investmentWithdrawn);
				}
				transferAmount = transferAmount.add(dailyProfitAmount);
			}
		}
		return transferAmount;
	}
	function getterGlobal1() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
	return ( address(this).balance, globalNoOfInvestors,globalTotalInvested , presentLevelNumber,totalTokensGiven,totalTokensBurned, donated );
	}
	function getterInvestor1(address investorAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
			return (
			investors[investorAddress].totalInvestmentByInvestor,
			investors[investorAddress].noOfInvestmentsByInvestor,
			investors[investorAddress].totalWithdrawnByInvestor,
			investors[investorAddress].totalDonation,
			investors[investorAddress].lastInvestmentTimeByInvestor,
			investors[investorAddress].userId
			);	
	}
	function getterInvestor2(address investorAddress) public view returns(uint256, uint256, uint256) {
			return (
			investors[investorAddress].amIPromoter,
			investors[investorAddress].promoterPercent,
			investors[investorAddress].tokensGiven
			);	
	}
	function getterInvestor3(address investorAddress) public view returns(address, uint256, uint256, uint256, uint256) {
			return (
			investors[investorAddress].referrer,
			investors[investorAddress].referralBonus,
			investors[investorAddress].level1,
			investors[investorAddress].investorCheckPoint,
			investors[investorAddress].totalReferred			
			);	
	}
}