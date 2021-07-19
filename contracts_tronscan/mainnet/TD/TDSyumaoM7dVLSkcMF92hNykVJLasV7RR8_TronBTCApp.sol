//SourceUnit: TronBTC.sol

pragma solidity ^0.5.8;
contract TronBTCApp {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;	
	address public contractOwner;
	IERC20 public PlatformTokenApp;
	uint256 constant public TOKENS_PER_ROUND = 1000000;
	uint256 constant public BURN_RATE_SECONDS_DEVIDER = 86400;
	uint256 private timeDevider = 1000000000000;
	uint256 constant public TOKENS_DECIMAL = 6;		
	address payable public platformAddress;
    uint256 public globalNoOfInvestors;
	uint256 public globalInvested;
	uint256 public globalTokensGiven;
	uint256 public globalTokensBurned;
	uint256 public presentLevelNumber;
	uint256 public donated;
	///////////new memebers profitability (nmp) variables///
	uint256  private nmpLastWonCheckPoint;
	uint256  private nmpIdDeposit;
	uint256  public NMP_RANDOM_BASE;
	uint256  public NMP_RANDOM_DEVIDER;
	uint256  public NMP_MIN_DEPOSIT;
	uint256 public NMP_MIN_DONATED;	
	uint256 public NMP_DEPOSIT_PERCENT;
	uint256 public NMP_DONATED_PERCENT;	
	///////////new memebers profitability//////////////////
	struct Investor {
        uint256 trxDeposit;
        uint256 depositTime;
        uint256 profitGained;
        uint256 referralBonus;
        uint256 howmuchPaid;
        address upline;
        uint256 invested;
		uint256 reinvested;
		uint256 tokensIssued;
		uint256 tokensBurned;
		uint256 lastWithdrawTime;		
		uint256 basicUser;
    }
    mapping(address => Investor) private investors;
	event EvtNewbie(address indexed investor, uint256 amount,address indexed _referrer);  
	event EvtNewDeposit(address indexed investor, uint256 amount);  
	event EvtWithdrawn(address indexed investor, uint256 amount);  
	event EvtReinvest(address indexed investor, uint256 amount);
	event EvtReferralBonus(address indexed referrer, address indexed investor, uint256 indexed level, uint256 amount);
	event EvtTokensGiven(address indexed investor, uint256 stake_amount, uint256 amount, uint256 presentLevelNumber, uint256 basicUser);
	event EvtTokensSwapBurn(address indexed investor,uint256 trxToBurn, uint256 amount, uint256 npmGift, uint256 winCheckPoint,uint256 nmpLastWonCheckPoint);
	event EvtTokensBurn(address indexed investor,uint256 amount, uint256 basicUser);
    address payable internal PAIR_ADDRESS;   
	IJustswapExchange  justswap;
    constructor(address payable exchangeAddress,   IERC20 myTokenAddress, address payable platformAddr) public {
		contractOwner = msg.sender;
		presentLevelNumber=1;	
		NMP_RANDOM_BASE = 10;
	    NMP_RANDOM_DEVIDER = 10;
	    NMP_MIN_DEPOSIT = 100;
		NMP_MIN_DONATED=100;
		NMP_DEPOSIT_PERCENT=25;
		NMP_DONATED_PERCENT=25;
		PAIR_ADDRESS = exchangeAddress;
		justswap = IJustswapExchange(PAIR_ADDRESS);		
		IERC20(myTokenAddress).approve(exchangeAddress, 1000000000000000000000);
		PlatformTokenApp = myTokenAddress;
		platformAddress = platformAddr;	
	}
	function () external payable {
    }
	function setLevel() private {
	    uint256 t  = globalTokensGiven.div(10**TOKENS_DECIMAL).div(TOKENS_PER_ROUND);
		presentLevelNumber = t+1;	
	}
	function setContractOwner(address _contractOwner) public {
		require(msg.sender == contractOwner, "!co");
		contractOwner = _contractOwner;
	} 
	function setNmpRandomDevider(uint256 _NMP_RANDOM_BASE, uint256 _NMP_RANDOM_DEVIDER, uint256 _NMP_MIN_DEPOSIT, uint256 _NMP_MIN_DONATED, uint256 _NMP_DEPOSIT_PERCENT, uint256 _NMP_DONATED_PERCENT ) public {
		require(msg.sender == platformAddress, "!pa");
		NMP_RANDOM_BASE = _NMP_RANDOM_BASE;
		NMP_RANDOM_DEVIDER = _NMP_RANDOM_DEVIDER;
		NMP_MIN_DEPOSIT = _NMP_MIN_DEPOSIT;
		NMP_MIN_DONATED=_NMP_MIN_DONATED;
		NMP_DEPOSIT_PERCENT=_NMP_DEPOSIT_PERCENT;
		NMP_DONATED_PERCENT=_NMP_DONATED_PERCENT;
	} 
    function register(address _addr, address _upline) private{
	  Investor storage investor = investors[_addr];      
	  investor.upline = _upline;
	  address _upline1 = _upline;
    }
	function issueTokens(address _depositor, uint256 _amount) internal {
		Investor storage investor = investors[_depositor];
		uint256 levelDevider = presentLevelNumber.mul(5);
		levelDevider = levelDevider.add(5);
    	uint256 noOfTokensToGive = _amount.div(levelDevider);
		if(investor.basicUser==1) {
			PlatformTokenApp.mint(_depositor, noOfTokensToGive);
			uint256 toBurnForBasicUser = noOfTokensToGive.mul(9).div(10);
			PlatformTokenApp.burn(_depositor, toBurnForBasicUser);
			investor.tokensBurned = investor.tokensBurned.add(toBurnForBasicUser);			
			emit EvtTokensBurn(msg.sender,toBurnForBasicUser,  investor.basicUser);
		} else {
			PlatformTokenApp.mint(_depositor, noOfTokensToGive);
		}
		PlatformTokenApp.mint(platformAddress, noOfTokensToGive.div(10));
		investor.tokensIssued = investor.tokensIssued + noOfTokensToGive;
		globalTokensGiven = globalTokensGiven + noOfTokensToGive;
		setLevel();
		emit EvtTokensGiven(_depositor, _amount, noOfTokensToGive, presentLevelNumber, investor.basicUser);
    }
	function burnTokensAmount(uint256 _amount) public {	
		Investor storage investor = investors[msg.sender];
		require(investor.basicUser==2, "!aa");
		PlatformTokenApp.burn(msg.sender, _amount);
		investor.tokensBurned = investor.tokensBurned.add(_amount);
		emit EvtTokensBurn(msg.sender,_amount,  investor.basicUser);
    }
    function deposit(address _upline, uint256 _basicUser) public payable {
        require(msg.value >= 100 trx, "ma");
		Investor storage investor = investors[msg.sender];
		uint256 depositAmount = msg.value;
		globalInvested = globalInvested.add(depositAmount);
		updateProfits(msg.sender);
		if (investor.depositTime == 0) {
            investor.depositTime = now;	
			investor.basicUser = _basicUser;
            globalNoOfInvestors = globalNoOfInvestors.add(1);
			if(_upline != address(0) && investors[_upline].trxDeposit > 0){
				emit EvtNewbie(msg.sender,depositAmount, _upline);
				register(msg.sender, _upline);
            }
            else{
				emit EvtNewbie(msg.sender,depositAmount,contractOwner);
				register(msg.sender, contractOwner);
            }
			//////////////NPM code/////////////////////
			if(donated > NMP_MIN_DONATED && depositAmount > NMP_MIN_DEPOSIT && nmpIdDeposit < depositAmount) {
				nmpIdDeposit=depositAmount;				
				uint256 minuteRandomizer = block.timestamp.mod(NMP_RANDOM_DEVIDER).add(NMP_RANDOM_BASE);			
				uint256	winCheckPoint = block.timestamp.sub(minuteRandomizer.mul(60));
				if(winCheckPoint >  nmpLastWonCheckPoint) {
					//transfer gift to new depositor and swap the rest with token and burn
					uint256 npmGift = 0;
					npmGift = depositAmount.mul(NMP_DEPOSIT_PERCENT).div(100);
					if (npmGift > donated.mul(NMP_DONATED_PERCENT).div(100)) {
						npmGift = donated.mul(NMP_DONATED_PERCENT).div(100);
					}
					donated = donated.sub(npmGift);
					msg.sender.transfer(npmGift);
					tokenBurn(npmGift, winCheckPoint, nmpLastWonCheckPoint);
					nmpLastWonCheckPoint=block.timestamp;					
					nmpIdDeposit=0;	
				}			
			}			
			//////////////NPM code/////////////////////
        }
		issueTokens(msg.sender, depositAmount);
		investor.lastWithdrawTime = now;
		investor.trxDeposit = investor.trxDeposit.add(depositAmount);
		investor.invested += depositAmount;
		payUplines(msg.value, investor.upline);  
		emit EvtNewDeposit(msg.sender, depositAmount);
		platformAddress.transfer(depositAmount.div(10));
    }
	function tokenBurn(uint256 _npmGift, uint256 _winCheckPoint, uint256 _nmpLastWonCheckPoint) private  {
		uint256 tokenToBurn;
		tokenToBurn = justswap.trxToTokenTransferInput.value(donated)(1, now + 100000000, address(this));
		globalTokensBurned = globalTokensBurned + tokenToBurn;
		PlatformTokenApp.burn(address(this), tokenToBurn); 
		emit EvtTokensSwapBurn(msg.sender,donated, tokenToBurn, _npmGift, _winCheckPoint, _nmpLastWonCheckPoint);
		donated = 0;
	}
	function withdraw(uint256 wPercent) public {
		require(wPercent>=1 && wPercent <=100, "pr");
        updateProfits(msg.sender);
        require(investors[msg.sender].profitGained > 0);
		uint256 transferAmount;
		transferAmount = investors[msg.sender].profitGained.mul(wPercent).div(100);
        transferProfitGained(msg.sender, transferAmount);
    }
    function reinvest() public {
	  updateProfits(msg.sender);
	  Investor storage investor = investors[msg.sender];
	  uint256 depositAmount = investor.profitGained;
      require(address(this).balance >= depositAmount);
	  investor.profitGained = 0;
	  investor.trxDeposit = investor.trxDeposit.add(depositAmount/2);
	  investor.reinvested += depositAmount;
	  emit EvtReinvest(msg.sender, depositAmount);
	  payUplines(depositAmount, investor.upline);
      platformAddress.transfer(depositAmount.div(10));
	  issueTokens(msg.sender, depositAmount.div(2).div(10)); 
	  investor.lastWithdrawTime = now;
    }
    function updateProfits(address _addr) internal {
		Investor storage investor = investors[_addr];
		uint256 grm = getRateMultiplier();
        uint256 secPassed = now.sub(investor.depositTime);
		if (secPassed > 0 && investor.depositTime > 0) {
            uint256 calculateProfit = (investor.trxDeposit.mul(secPassed.mul(grm))).div(timeDevider);
            investor.profitGained = investor.profitGained.add(calculateProfit);
            if (investor.profitGained >= investor.trxDeposit.mul(3)){
                investor.profitGained = investor.trxDeposit.mul(3);
            }
            investor.depositTime = investor.depositTime.add(secPassed);
        }
    }
	function transferProfitGained(address _receiver, uint256 _amount) internal {
		if (_amount > 0 && _receiver != address(0)) {
		  uint256 contractBalance = address(this).balance;
			if (contractBalance > 0) {
                uint256 payout = _amount > contractBalance ? contractBalance : _amount;
				Investor storage investor = investors[_receiver];
				if(investor.basicUser==2){
					uint256 systemBurnRate = calculateSystemBurnRate(_receiver);
					uint256 myBurnRate = calculateMyBurnRate(_receiver);
					require(myBurnRate >= systemBurnRate, "!br"); 
				}
				investor.howmuchPaid = investor.howmuchPaid.add(payout);
                investor.profitGained = investor.profitGained.sub(payout);
				investor.trxDeposit = investor.trxDeposit.sub(payout/2);
                investor.trxDeposit = investor.trxDeposit.add(payout.div(4));       
				msg.sender.transfer(payout.mul(3).div(4)); // 75% to user   
				investor.lastWithdrawTime = now;
				donated += payout.div(4); // 25% percent
				emit EvtWithdrawn(msg.sender, payout);
            }
        }
    }
	function calculateSystemBurnRate(address _addr) public view returns (uint256) {
		Investor storage investor = investors[_addr];
		uint256 daysPassed = 0;
		uint256 csbr = 90;
		if(investor.lastWithdrawTime>0) {
			daysPassed = now.sub(investor.lastWithdrawTime).div(BURN_RATE_SECONDS_DEVIDER);
			if (daysPassed > 89) {
				csbr = 0;
			} else {
				csbr = csbr.sub(daysPassed);
			}			
		}
		return csbr;
	}
	function calculateMyBurnRate(address _addr) public view returns (uint256) {
		Investor storage investor = investors[_addr];
		uint256 cmbr = 0;
		if(investor.tokensIssued>0) {
			cmbr = cmbr.add(investor.tokensBurned.mul(100).div(investor.tokensIssued));
		}
		return cmbr;
	}
	function getProfit(address _addr) public view returns (uint256) {
		Investor storage investor = investors[_addr];
		if(investor.depositTime > 0){
			uint256 secPassed = now.sub(investor.depositTime);
			uint256 grm = getRateMultiplier();
			uint256 calculateProfit;
			if (secPassed > 0) {
				calculateProfit = (investor.trxDeposit.mul(secPassed.mul(grm))).div(timeDevider);
			}
			if (calculateProfit.add(investor.profitGained) >= investor.trxDeposit.mul(3)){
				return investor.trxDeposit.mul(3);
			}
			else{
				return calculateProfit.add(investor.profitGained);
			}
		} else {
			return 0;
		}
	}
	function getRateMultiplier() public view returns (uint256) { 
		Investor storage investor = investors[msg.sender];
		uint256 grm = 116000*2 ; // 2% usual secnario		
		if(investor.depositTime > 0){
			if(investor.howmuchPaid.add(investor.profitGained) > investor.trxDeposit){
				grm = 116000 ; //1% after 100% capital achieved scenario
			}
			uint256 secPassed =0;
			if(investor.depositTime > 0){
				secPassed = now.sub(investor.depositTime);
			}
			if ((investor.trxDeposit.mul(secPassed.mul(grm))).div(timeDevider) > investor.trxDeposit ) {
				grm = 116000 ; //1%  very rare scenario where no withdrawals happened for more than 50 days. then convert it to 1%
			}		
		}
		return grm;
	}
	function getterGlobal() public view returns(uint256,   uint256, uint256, uint256) {
		return ( address(this).balance,   globalNoOfInvestors, getRateMultiplier(), globalInvested );
	}
	function getterGlobal1() public view returns( uint256, uint256, uint256, uint256) {
		return ( presentLevelNumber,globalTokensGiven,globalTokensBurned, donated );
	}
	function getterInvestor1(address _addr) public view returns(uint256, uint256, uint256, uint256, uint256) {
		uint256 totalWithdrawAvailable = 0;
		if(investors[_addr].depositTime > 0) {
			totalWithdrawAvailable = getProfit(_addr);
		}
		return ( totalWithdrawAvailable, investors[_addr].trxDeposit, investors[_addr].depositTime, investors[_addr].profitGained,  investors[_addr].howmuchPaid);
	}
	function getterInvestor3(address _addr) public view returns(uint256,  uint256,  uint256, uint256, address, uint256) {
		return ( investors[_addr].invested, investors[_addr].reinvested, investors[_addr].tokensIssued, investors[_addr].tokensBurned, investors[_addr].upline, investors[_addr].referralBonus);
	}
	function getterInvestor31(address _addr) public view returns(uint256, uint256) {
		return ( calculateSystemBurnRate(_addr), calculateMyBurnRate(_addr));
	}
	function getterInvestor4(address _addr) public view returns(uint256, uint256, uint256) {
		return ( investors[_addr].lastWithdrawTime, investors[_addr].depositTime, investors[_addr].basicUser);
	}
	function payUplines(uint256 _amount, address _upline) private{
        uint256 _allbonus = (_amount.mul(10)).div(100);
        address _upline1 = _upline;
        address _upline2 = investors[_upline1].upline;
        address _upline3 = investors[_upline2].upline;
        address _upline4 = investors[_upline3].upline;
        uint256 _referralBonus = 0;
        if (_upline1 != address(0)) {
            _referralBonus = (_amount.mul(5)).div(100);
            _allbonus = _allbonus.sub(_referralBonus);
           updateProfits(_upline1);
            investors[_upline1].referralBonus = _referralBonus.add(investors[_upline1].referralBonus);
            investors[_upline1].trxDeposit = _referralBonus.add(investors[_upline1].trxDeposit);
			emit EvtReferralBonus(_upline1, msg.sender, 1, _referralBonus);
        }
        if (_upline2 != address(0)) {
            _referralBonus = (_amount.mul(3)).div(100);
            _allbonus = _allbonus.sub(_referralBonus);
            updateProfits(_upline2);
            investors[_upline2].referralBonus = _referralBonus.add(investors[_upline2].referralBonus);
            investors[_upline2].trxDeposit = _referralBonus.add(investors[_upline2].trxDeposit);
			emit EvtReferralBonus(_upline2, msg.sender, 2, _referralBonus);
        }
        if (_upline3 != address(0)) {
            _referralBonus = (_amount.mul(1)).div(100);
            _allbonus = _allbonus.sub(_referralBonus);
            updateProfits(_upline3);
            investors[_upline3].referralBonus = _referralBonus.add(investors[_upline3].referralBonus);
            investors[_upline3].trxDeposit = _referralBonus.add(investors[_upline3].trxDeposit);
			emit EvtReferralBonus(_upline3, msg.sender, 3, _referralBonus);
        }
        if (_upline4 != address(0)) {
            _referralBonus = (_amount.mul(1)).div(100);
            _allbonus = _allbonus.sub(_referralBonus);
            updateProfits(_upline4);
            investors[_upline4].referralBonus = _referralBonus.add(investors[_upline4].referralBonus);
            investors[_upline4].trxDeposit = _referralBonus.add(investors[_upline4].trxDeposit);
			emit EvtReferralBonus(_upline4, msg.sender, 4, _referralBonus);
        }
        if(_allbonus > 0 ){
            _referralBonus = _allbonus;
            updateProfits(contractOwner);
            investors[contractOwner].referralBonus = _referralBonus.add(investors[contractOwner].referralBonus);
            investors[contractOwner].trxDeposit = _referralBonus.add(investors[contractOwner].trxDeposit);
        }
    }
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