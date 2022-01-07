pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./SafeMath.sol";
import "./LendingWhiteList.sol";
import "./TokenPriceOracle.sol";
import "./DateTimeLibrary.sol";

contract FinanceProduct is LendingWhiteList{

    using SafeMath for uint256;
    using DateTimeLibrary for uint256;

    /// @notice invest event
    event TokenInvest(address account, address tokenAddress, uint amount);

    /// @notice divest event
    event TokenDivest(address account, address tokenAddress, uint amount);

    /// @notice supply ESG event
    event EsgSupply(address account, uint amount);

    /// @notice withdraw ESG event
    event EsgWithdraw(address account, uint amount);

    /// @notice borrow event
    event TokenBorrow(address account, address tokenAddress, uint amount);

    /// @notice reapy event
    event TokenRepay(address account, address tokenAddress, uint amount);

    /// @notice change ESG mortgage rate event
    event ChangeMortgageRate(address account, address tokenAddress, uint amount);

    /// @notice change liquidation rate event
    event ChangeLiquidationRate(address account, address tokenAddress, uint amount);

    /// @notice change ESG speed event
    event ChangeEsgSpeed(address tokenAddress, uint rate);

    /// @notice liquidation event
    event liquidationToken(address liquidator, address account, address tokenAddress, uint token_amount, uint esg_amount);

    /// @notice ESG token
    EIP20Interface public esg;

    /// @notice TokenPriceOracle
    TokenPriceOracle public oracle;

    bool is_stop = false;

    // @notice incentive rate
    uint256 incentiveRate = 1.1e18;
    // @notice last repay time
    uint40 last_regular_repay_time;

    struct Token {
        // @notice symbol of token, such as USDT, USDC, DAI, .etc
        string token_symbol;   
        // @notice address of token
        address token_addr;    
    }
    Token[] public tokens;

    struct Checkpoint {
	// @notice UNIX timestamp
	uint40 last_check_time; 
	// @notice total supply of account
	uint256 total_supply;   
	// @notice interest of supply
	uint256 bonus; 		
	// @notice interest of ESG
	uint256 esg_bonus; 	
    }
    mapping (address => mapping (address => Checkpoint)) checkpoints;

    struct InvestCheckpoint {
	// @notice UNIX timestamp
	uint40 last_check_time; 
	uint256 total_supply;
	uint256 after_endtime_invest;
	uint claim_issue;
	// @notice interest of ESG
	uint256 esg_bonus; 	
    }
    mapping (address => mapping (address => InvestCheckpoint)) invest_checkpoints;

    // @notice checkpoint struct for borrowing
    struct BorrowCheckpoint {
	// @notice UNIX timestamp
	uint40 last_check_time; 
	// @notice total borrow of account
	uint256 total_borrow;  
	// @notice total borrow afte endtime
	uint256 after_endtime_borrow;
	// @notice interest of borrow
	uint256 interest;      
	// @notice how many issues had been repaid
	uint repay_issue;      
    }
    mapping (address => mapping (address => BorrowCheckpoint)) borrow_checkpoints;

    uint public online_year = 2021;
    uint public online_month = 12;
    uint public online_day = 25;
    uint public issueDay = 10; 
    // @notice 1:Equal repayment of principal；2：Matching the repayment of principal and interest; 3:before interest after principal payment 
    uint repayType = 1;
    // @notice how many months to repay 
    uint public period = 12; 

    // @notice How much is the target investment
    uint256 public targetSupply = 1000000 * 1e18; 
    // @notice true:To raise success; false:Not to raise success
    mapping (address => bool) isSuccessed;

    uint40 public online_time; 
    uint40 public end_time;
    // @notice The rate every year. 
	uint256 public yearRatio = 12e16; //12%
    // @notice The rate every day. 
    uint256 public dayRatio = yearRatio.div(365); 
    // @notice ESG collateral rate
    uint256 public mortgageRate = 4e17;//40%
    // @notice Liquidition rate
    uint256 public liquidationRate = 8e17;//80%
    
    // @notice ESG bonus speed per block
    uint256 public esg_bonus_per_block = 1e16;

    uint256 total_esg;

    // @notice total supply amount for each token
    mapping (address => uint256) total_deposited;

    // @notice total borrow amount for each token
    mapping (address => uint256) total_borrowed;

    // @notice claimed issue amount for each token
    mapping (address => mapping (address => uint)) issue_number;
    
    constructor (address _esgAddress, address _usdtAddress, address _oracleAddress) public {
		require(_esgAddress != address(0) && _usdtAddress != address(0) && _oracleAddress != address(0), "FinanceProduct: address should not be 0x0.");
		esg = EIP20Interface(_esgAddress);
		oracle = TokenPriceOracle(_oracleAddress);
		tokens.push(Token({token_symbol:"USDT", token_addr:_usdtAddress}));
		online_time = 1640448000; 
    	end_time = 1640696400;
    }

	function isListed(address tokenAddress) public view returns(bool){
		for(uint i = 0; i<tokens.length; i++){
			Token memory tk = tokens[i];
			if(tk.token_addr == tokenAddress){
				return true;
			}
		}
		return false;
	}

	// @notice add new token to supported token list
	function _addToken(string calldata symbol, address tokenAddress) external onlyOwner{
		require(is_stop == false,"The system is shut downn");
		require(!isListed(tokenAddress),"token already listed");
		tokens.push(Token({token_symbol:symbol, token_addr:tokenAddress}));
	}

	function invest(address tokenAddress, uint256 amount) external returns (bool){
		require(is_stop == false,"The system is shut downn");
		require(isSuccessed[tokenAddress] != true,"Has been successfully raised.");
		require(tokenAddress != address(0),"address should not be 0x0.");
		require(amount>0,"amount should not be 0.");
		require(amount <= EIP20Interface(tokenAddress).balanceOf(msg.sender), "Insufficient token.");
		require(uint40(block.timestamp) <= end_time,"false");

		EIP20Interface(tokenAddress).transferFrom(msg.sender, address(this), amount);

		InvestCheckpoint storage cp = invest_checkpoints[msg.sender][tokenAddress];
		if(cp.last_check_time == 0)
		{
			cp.total_supply = amount;
			cp.after_endtime_invest = amount;
			cp.last_check_time = uint40(block.timestamp);
			total_deposited[tokenAddress] = amount;
			if(total_deposited[tokenAddress] >= targetSupply){
				isSuccessed[tokenAddress] = true;
			}
			emit TokenInvest(msg.sender, tokenAddress, amount);
			return true;
		}
		else
		{
			uint256 left_amount = targetSupply.sub(total_deposited[tokenAddress]);
			if(left_amount >= amount){
				cp.total_supply = cp.total_supply.add(amount);
				cp.after_endtime_invest = cp.after_endtime_invest.add(amount);
				cp.last_check_time = uint40(block.timestamp);
				total_deposited[tokenAddress] = total_deposited[tokenAddress].add(amount);
				if(total_deposited[tokenAddress] >= targetSupply){
					isSuccessed[tokenAddress] = true;
				}
				emit TokenInvest(msg.sender, tokenAddress, amount);
				return true;
			}
			else if(left_amount>0)
			{
				
				cp.total_supply = cp.total_supply.add(left_amount);
				cp.after_endtime_invest = cp.after_endtime_invest.add(left_amount);
				cp.last_check_time = uint40(block.timestamp);
				EIP20Interface(tokenAddress).transfer(msg.sender, amount.sub(left_amount));
				total_deposited[tokenAddress] = total_deposited[tokenAddress].add(left_amount);
				if(total_deposited[tokenAddress] >= targetSupply){
					isSuccessed[tokenAddress] = true;
				}
				emit TokenInvest(msg.sender, tokenAddress, left_amount);
				return true;
			}
			else
			{
				return false;
			}
		}
		
	}

	function divest(address tokenAddress) external returns (bool) {
		require(is_stop == false,"The system is shut downn");
		require(tokenAddress != address(0),"not 0x0");
		require(uint40(block.timestamp) > end_time,"false");

		InvestCheckpoint storage cp = invest_checkpoints[msg.sender][tokenAddress];
		uint256 ratio = cp.total_supply.div(targetSupply).mul(1e18);
		uint256 total_interest = total_deposited[tokenAddress].mul(yearRatio).div(1e18);
		uint256 each_bonus =  total_interest.mul(ratio).div(period).div(1e18);
		uint256 each_principal = cp.total_supply.div(period);
		issuesNumber(msg.sender, tokenAddress);
		uint unclaim_issues_number = issue_number[msg.sender][tokenAddress].sub(cp.claim_issue);

		uint esg_num = block.timestamp.sub(cp.last_check_time).div(3).mul(esg_bonus_per_block);
		cp.esg_bonus = cp.esg_bonus.add(esg_num.mul(cp.total_supply).div(targetSupply).div(1e18));
		esg.transfer(msg.sender, cp.esg_bonus);
		cp.esg_bonus = 0;

		cp.last_check_time = uint40(block.timestamp);
		EIP20Interface(tokenAddress).transfer(msg.sender, each_bonus.add(each_principal).mul(unclaim_issues_number));
		cp.total_supply = cp.total_supply.sub(each_bonus.add(each_principal).mul(unclaim_issues_number));
		cp.claim_issue = cp.claim_issue.add(unclaim_issues_number);
			
		emit TokenDivest(msg.sender, tokenAddress, each_bonus.add(each_principal).mul(unclaim_issues_number));
		return true;
		
	}


    // @notice supply ESG（whitelist user required）
	function esgSupply(uint256 amount) onlyWhitelisted external returns (bool){
		require(is_stop == false,"The system is shut downn");
		require(amount>0,"greater than 0");
		require(amount <= esg.balanceOf(msg.sender), "Insufficient ESG token.");

		esg.transferFrom(msg.sender, address(this), amount);

		Checkpoint storage cp = checkpoints[msg.sender][address(esg)];
		cp.total_supply = cp.total_supply.add(amount);
		total_esg = total_esg.add(amount);
		cp.last_check_time = uint40(block.timestamp);
		emit EsgSupply(msg.sender, amount);
		return true;
	}

	// @notice withdraw ESG（whitelist user required）
	function esgWithdraw(uint256 amount) onlyWhitelisted external returns (bool) {
		require(is_stop == false,"The system is shut downn");
		require(amount>0,"greater than 0");
		
		Checkpoint storage cp = checkpoints[msg.sender][address(esg)];
		uint tokenBorrowedValue = getTotalTokensBorrowValue(msg.sender);
		if(tokenBorrowedValue == 0)
		{
			require(amount <= esg.balanceOf(address(this)), "Insufficient ESG token in product pool.");
		}
		else
		{
			uint left_esg_usd_value = cp.total_supply.sub(amount).mul(oracle.getEsgPrice());
			require(tokenBorrowedValue <= left_esg_usd_value.mul(mortgageRate).div(1e18), "amount exceeds max ESG quantity required.");
		}		

		cp.total_supply = cp.total_supply.sub(amount);
		total_esg = total_esg.sub(amount);
		cp.last_check_time = uint40(block.timestamp);
		esg.transfer(msg.sender, amount);
		
		emit EsgWithdraw(msg.sender, amount);
		return true;
	}

	// @notice borrow token (only whitelist users)
	function borrow(address tokenAddress, uint256 amount) onlyWhitelisted external returns (bool){
		require(is_stop == false,"The system is shut downn");
		require(tokenAddress != address(0),"not 0x0");
		require(amount>0,"greater than 0");
		require(uint40(block.timestamp) <= end_time,"false");

		Checkpoint memory esg_cp = checkpoints[msg.sender][address(esg)];
		uint tokenBorrowedValue = getTotalTokensBorrowValue(msg.sender);

		uint left_esg_usd_value = esg_cp.total_supply.mul(oracle.getEsgPrice()).mul(mortgageRate).div(1e18).sub(tokenBorrowedValue);
		require(amount.mul(oracle.getPrice(tokenAddress)).div(1e18) <= left_esg_usd_value, "Insufficient ESG token for collateral.");

		BorrowCheckpoint storage cp = borrow_checkpoints[msg.sender][tokenAddress];
		
		if(cp.last_check_time == 0)
		{
			cp.total_borrow = amount;
			cp.after_endtime_borrow = amount;
			cp.last_check_time = uint40(block.timestamp);
		}
		else
		{
			cp.total_borrow = cp.total_borrow.add(amount);
			cp.after_endtime_borrow = cp.after_endtime_borrow.add(amount);
			cp.last_check_time = uint40(block.timestamp);
		}
		
		total_borrowed[tokenAddress] = total_borrowed[tokenAddress].add(amount);
		EIP20Interface(tokenAddress).transfer(msg.sender, amount);
		emit TokenBorrow(msg.sender, tokenAddress, amount);
		return true;
	}


	// @notice repay function(whitelist user required)
	function repay(address tokenAddress) onlyWhitelisted external returns (bool) {
		require(is_stop == false,"The system is shut downn");
		require(tokenAddress != address(0),"not 0x0");
		require(uint40(block.timestamp) > end_time,"false");
		
		BorrowCheckpoint storage cp = borrow_checkpoints[msg.sender][tokenAddress];
		uint256 loan = cp.after_endtime_borrow;
		uint every_month_repay;
		if(repayType == 1){
			every_month_repay = repayType1(loan, cp.repay_issue);
		}
		else if(repayType == 2){
			every_month_repay = repayType2(loan);
		}
		else{
			every_month_repay = repayType3(loan, cp.repay_issue);
		}
		issuesNumber(msg.sender, tokenAddress);
		uint unrepay_issues_number = issue_number[msg.sender][tokenAddress].sub(cp.repay_issue);

		if(unrepay_issues_number == 0){
			return false;
		}else{
			EIP20Interface(tokenAddress).transferFrom(msg.sender, address(this), every_month_repay.mul(unrepay_issues_number));
			cp.total_borrow = cp.total_borrow.sub(every_month_repay.mul(unrepay_issues_number));
			cp.last_check_time = uint40(block.timestamp);
			last_regular_repay_time = uint40(block.timestamp);
			cp.repay_issue = cp.repay_issue.add(unrepay_issues_number);

			emit TokenRepay(msg.sender, tokenAddress, every_month_repay);
			return true;
		}
		
	}

	//@notice 1:Equal repayment of principal；
	function repayType1(uint256 loan, uint issue) public view returns (uint256){
		uint every_month_repay_principal = loan.div(period);
		uint every_month_repay_interest = loan.sub(every_month_repay_principal.mul(issue)).mul(yearRatio.div(12).div(1e18));
		uint256 every_month_repay = every_month_repay_principal.add(every_month_repay_interest);
		return every_month_repay;
	}
	//@notice 2：Matching the repayment of principal and interest;  
	function repayType2(uint256 loan) public view returns (uint256){
		uint ratio1 = yearRatio.div(12).add(1).pwr(period);
		uint ratio2 = ratio1.sub(1e18);
		uint every_month_repay = loan.mul(yearRatio.div(12)).mul(ratio1).div(ratio2).div(1e18);
		return every_month_repay;
	}
	//@notice 3:before interest after principal payment
	function repayType3(uint256 loan, uint issue) public view returns (uint256){
		uint every_month_repay;
		if(issue<period.sub(1)){
			every_month_repay = loan.mul(yearRatio.div(12)).div(1e18);
		}
		else{
			every_month_repay = loan.mul(yearRatio.div(12)).add(loan).div(1e18);
		}
		return every_month_repay;
	}
	function getDivestIssue(address tokenAddress, address account) external view returns(uint){
		InvestCheckpoint memory cp = invest_checkpoints[account][tokenAddress];
		return cp.claim_issue;
	}

	function getDivestBalance(address tokenAddress, address account) external view returns(uint256){
		InvestCheckpoint storage cp = invest_checkpoints[account][tokenAddress];
		uint256 ratio = cp.total_supply.div(targetSupply).mul(1e18);
		uint256 total_interest = total_deposited[tokenAddress].mul(yearRatio).div(1e18);
		uint256 each_bonus =  total_interest.mul(ratio).div(period).div(1e18);
		uint256 each_principal = cp.total_supply.div(period);
		return each_bonus.add(each_principal);
	}

	function getRepayIssue(address tokenAddress, address account) external view returns(uint){
		BorrowCheckpoint memory cp = borrow_checkpoints[account][tokenAddress];
		return cp.repay_issue;
	}

	function getTotalBorrowByAccount(address tokenAddress, address account) external view returns(uint){
		BorrowCheckpoint memory cp = borrow_checkpoints[account][tokenAddress];
		return cp.after_endtime_borrow;
	}

	function getTotalInvestByAccount(address tokenAddress, address account) external view returns(uint){
		InvestCheckpoint memory cp = invest_checkpoints[account][tokenAddress];
		return cp.after_endtime_invest;
	}

	function getTotalInvestment(address tokenAddress) external view returns(uint256){
		uint256 total_deposit = total_deposited[tokenAddress];
		return total_deposit;
	}

	function getInvestment(address tokenAddress, address account) external view returns(uint){
		InvestCheckpoint memory cp = invest_checkpoints[account][tokenAddress];
		return cp.total_supply;
	}

	function getTotalBorrowing(address tokenAddress) external view returns(uint256){
		uint256 total_borrow = total_borrowed[tokenAddress];
		return total_borrow;
	}

	function getBorrowing(address tokenAddress, address account) external view returns(uint){
		BorrowCheckpoint memory cp = borrow_checkpoints[account][tokenAddress];
		return cp.total_borrow;
	}

	function getEsgSupplying(address tokenAddress, address account) external view returns(uint){
		Checkpoint memory cp = checkpoints[account][tokenAddress];
		return cp.total_supply;
	}

	function getIssueNumber(address account, address tokenAddress) external returns(uint){
		issuesNumber(account, tokenAddress);
		uint issue_numb = issue_number[account][tokenAddress];
		return issue_numb;
	}

	function getSupportedTokens() external view returns (Token[] memory){
		return 	tokens;
	}

	//@notice The fund has been raised ？
	function getIsSuccessed(address tokenAddress) public view returns (bool){
		bool isSuccess = isSuccessed[tokenAddress];
		return 	isSuccess;
	}

	function getTotalEsg() public view returns (uint256){
		return 	total_esg;
	}

	// @notice get unclaimed token bonus
	function getUnclaimedBouns(address account) public view returns (uint)
	{
		require(is_stop == false,"The system is shut downn");
		uint bonus = 0;
	    	for(uint i=0; i<tokens.length; i++)
	   	{
			address tokenAddress = tokens[i].token_addr;
	    		Checkpoint memory cp = checkpoints[account][tokenAddress];
			bonus = bonus.add(cp.bonus);
	    	}
		return bonus;
	}

	// @notice get unclaimed ESG bonus
	function getUnclaimedEsg(address account) public view returns (uint) 
	{
		require(is_stop == false,"The system is shut downn");
		uint bonus = 0;
	    	for(uint i=0; i<tokens.length; i++)
	   	{
			address tokenAddress = tokens[i].token_addr;
	    		Checkpoint memory cp = checkpoints[account][tokenAddress];
			bonus = bonus.add(cp.esg_bonus);
	    	}
		return bonus;
    	}

    // @notice get all tokens borrowed value in USD
    function getTotalTokensBorrowValue(address account) public view returns (uint) {
	    require(is_stop == false,"The system is shut downn");
	    uint borrowedValue = 0;
	    for(uint i=0; i<tokens.length; i++)
	    {
			address tokenAddress = tokens[i].token_addr;
	    	uint token_price = oracle.getPrice(tokenAddress);
	    	BorrowCheckpoint memory cp = borrow_checkpoints[account][tokenAddress];
	    	borrowedValue = borrowedValue.add(token_price.mul(cp.total_borrow).div(1e18));
	    }
	    return borrowedValue;
    }

	// @notice admin rights
	function _changeMortgageRate(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
	    require(is_stop == false,"The system is shut downn");
	    mortgageRate = amount;
	    emit ChangeMortgageRate(msg.sender,tokenAddress, amount);
	    return true;
	}

	// @notice admin rights
	function _changeLiquidationRate(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
	    require(is_stop == false,"The system is shut downn");
	    liquidationRate = amount;
	    emit ChangeLiquidationRate(msg.sender,tokenAddress, amount);
	    return true;
	}
	// @notice admin rights
	function _changeEsgBonusRate(address tokenAddress, uint256 rate) public onlyOwner returns (bool) {
	    require(is_stop == false,"The system is shut downn");
	    esg_bonus_per_block = rate;
	    emit ChangeEsgSpeed(tokenAddress, rate);
	    return true;
	}

	//@notice shut down the system
	function close() public onlyOwner returns (bool){
		is_stop = true;
		return 	is_stop;
	}

	//@notice open the system
	function open() public onlyOwner returns (bool){
		is_stop = false;
		return 	is_stop;
	}

	//@notice set endtime
	function setEndtime(uint40 endtime) public onlyOwner returns (bool){
		end_time = endtime;
		return 	true;
	}

	//@notice set issueday
	function setIssueDay(uint issue_day) public onlyOwner returns (bool){
		issueDay = issue_day;
		return 	true;
	}

    // @notice how many issues since online date
    function issuesNumber(address account, address tokenAddress) public {
    	uint issues_num = 0;
    	(uint year, uint month, uint day) = DateTimeLibrary._daysToDate(block.timestamp.div(86400));
    	if(issueDay > online_day){
    		issues_num++;
    		if(day > issueDay){
    			issues_num++;
    			if(month >= online_month){
    				issues_num = issues_num.add(month.sub(online_month)).add(year.sub(online_year).mul(12));
    			}else{
    				issues_num = issues_num.add(month.add(12).sub(online_month)).add(year.sub(1).sub(online_year).mul(12));
    			}
    		}else{
    			if(month >= online_month){
    				issues_num = issues_num.add(month.sub(online_month)).add(year.sub(online_year).mul(12));
    			}else{
    				issues_num = issues_num.add(month.add(12).sub(online_month)).add(year.sub(1).sub(online_year).mul(12));
    			}
    		}
    	}else{
    		if(day > issueDay){
    			issues_num++;
    			if(month >= online_month){
    				issues_num = issues_num.add(month.sub(online_month)).add(year.sub(online_year).mul(12));
    			}else{
    				issues_num = issues_num.add(month.add(12).sub(online_month)).add(year.sub(1).sub(online_year).mul(12));
    			}
    		}else{
    			if(month >= online_month){
    				issues_num = issues_num.add(month.sub(online_month)).add(year.sub(online_year).mul(12));
    			}else{
    				issues_num = issues_num.add(month.add(12).sub(online_month)).add(year.sub(1).sub(online_year).mul(12));
    			}
    		}
    	}
    	issue_number[account][tokenAddress] = issues_num;
    } 

	// @notice Liquidition function
	function liquidation(address account, address borrowTokenAddress, uint256 amount) public onlyOwner returns (bool) 
	{
        require(is_stop == false,"The system is shut downn");

        Checkpoint storage cp1 = checkpoints[account][address(esg)];
        uint esg_amount = cp1.total_supply;
        BorrowCheckpoint storage cp2 = borrow_checkpoints[account][borrowTokenAddress];
        uint borrow_amount = cp2.total_borrow;
		require(amount >= borrow_amount, "should be great than borrow quantity.");

		uint total_borrow_value = getTotalTokensBorrowValue(account);
		uint token_price = oracle.getPrice(borrowTokenAddress);
		uint esg_price = oracle.getEsgPrice();
        if(esg_amount.mul(esg_price).mul(liquidationRate) <= total_borrow_value){
        	EIP20Interface(borrowTokenAddress).transferFrom(msg.sender, address(this), borrow_amount);
			uint liquidite_esg_amount = borrow_amount.mul(token_price).mul(incentiveRate).div(esg_price);
	        esg.transfer(msg.sender, liquidite_esg_amount);
			cp1.total_supply = cp1.total_supply.sub(liquidite_esg_amount);
			cp1.last_check_time = uint40(block.timestamp);
			cp2.total_borrow = 0;
			cp2.last_check_time = uint40(block.timestamp);
	        emit liquidationToken(msg.sender, account, borrowTokenAddress, borrow_amount, liquidite_esg_amount);
	        return true;
        }
		return false;
    }

	// @notice overdue payment---liquidition function
    function currentLiquidation(address account, address borrowTokenAddress, uint256 amount) public returns (bool) 
	{
			require(is_stop == false,"The system is shut downn");
	        EIP20Interface(borrowTokenAddress).transferFrom(msg.sender, address(this), amount);
	        uint token_price = oracle.getPrice(borrowTokenAddress);
		    uint esg_price = oracle.getEsgPrice();
			uint liquidite_esg_amount = amount.mul(token_price).mul(incentiveRate).div(esg_price);
		    esg.transfer(msg.sender, liquidite_esg_amount);
			Checkpoint storage cp1 = checkpoints[account][address(esg)];
			cp1.total_supply = cp1.total_supply.sub(liquidite_esg_amount);
			cp1.last_check_time = uint40(block.timestamp);
			BorrowCheckpoint storage cp2 = borrow_checkpoints[account][borrowTokenAddress];
			cp2.total_borrow = cp2.total_borrow.sub(amount);
			cp2.last_check_time = uint40(block.timestamp);
			cp2.repay_issue = cp2.repay_issue.add(1);
	        return true;
    }
}

pragma solidity >=0.6.2;

contract owned {
    address public owner;
 
    constructor() public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

pragma solidity ^0.6.2;

import "./EIP20Interface.sol";
import "./SafeMath.sol";
import "./AggregatorV2V3Interface.sol";

contract TokenPriceOracle{

    using SafeMath for uint;
    address public admin;

    EIP20Interface esg;
    EIP20Interface wbnb; // wrapper of BNB
    address lpTokenAddress; // LP token address of pancackeswap

    mapping(address => uint) internal prices;
    mapping(bytes32 => AggregatorV2V3Interface) internal feeds;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);
    event NewAdmin(address oldAdmin, address newAdmin);
    event FeedSet(address feed, string symbol);

    constructor(address esgAddress, address wbnbAddress, address lpTokenAddr) public {
        esg = EIP20Interface(esgAddress);
        wbnb = EIP20Interface(wbnbAddress);
        lpTokenAddress = lpTokenAddr;
        admin = msg.sender;
    }

    //get usd price of BIP20 token at tokenAddress
    function getPrice(address tokenAddress) public  view returns (uint price) {
        if (prices[address(tokenAddress)] != 0) {
            price = prices[address(tokenAddress)];
        } else {
            price = getChainlinkPrice(getFeed(EIP20Interface(tokenAddress).symbol()));
        }
        return price;
    }

    //get usd price of ESG token
    function getEsgPrice() external view returns (uint price){
        uint bnb_usd_price = getPrice(address(wbnb));
        uint256 bnb_amount = wbnb.balanceOf(lpTokenAddress);
        uint256 esg_amount = esg.balanceOf(lpTokenAddress);

        uint256 ten = 10;   
        uint esg_usd_price = bnb_amount.mul(ten.pwr(esg.decimals())).mul(bnb_usd_price).div(esg_amount.mul(ten.pwr(wbnb.decimals())));
        return esg_usd_price;
    }

    function getChainlinkPrice(AggregatorV2V3Interface feed) internal view returns (uint) {
        // Chainlink USD-denominated feeds store answers at 8 decimals
        uint decimalDelta = uint(18).sub(feed.decimals());
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return uint(feed.latestAnswer()).mul(10**decimalDelta);
        } else {
            return uint(feed.latestAnswer());
        }
    }

    function setDirectPrice(address asset, uint price) external onlyAdmin {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function setFeed(string calldata symbol, address feed) external onlyAdmin {
        require(feed != address(0) && feed != address(this), "invalid feed address");
        emit FeedSet(feed, symbol);
        feeds[keccak256(abi.encodePacked(symbol))] = AggregatorV2V3Interface(feed);
    }

    function getFeed(string memory symbol) public view returns (AggregatorV2V3Interface) {
        return feeds[keccak256(abi.encodePacked(symbol))];
    }

    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "only admin may call");
      _;
    }
}

pragma solidity  >=0.6.2 <0.7.0;
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

  /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x)
  internal
  pure
  returns(uint256 y) {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y) {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x)
  internal
  pure
  returns(uint256) {
    return (mul(x, x));
  }

  /**
   * @dev x to the power of y
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}

pragma solidity >=0.6.2;

import "./EnumerableSet.sol";
import "./owned.sol";

contract LendingWhiteList is owned {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor() public {
    }

    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender), "LendingWhiteList: caller is not in whitelist");
        _;
    }

    //往白名单中增加地址
    function add(address _address) public onlyOwner returns(bool) {
        require(_address != address(0), "LendingWhiteList: _address is the zero address");
        EnumerableSet.add(_whitelist, _address);
        emit AddedToWhitelist(_address);
        return true;
    }

    //从白名单中移除地址
    function remove(address _address) public onlyOwner returns(bool) {
        require(_address != address(0), "LendingWhiteList: _address is the zero address");
        EnumerableSet.remove(_whitelist, _address);
        emit RemovedFromWhitelist(_address);
        return true;
    }

    //判断此地址是否在白名单中
    function isWhitelisted(address _address) public view returns(bool) {
        return EnumerableSet.contains(_whitelist, _address);
    }
}

pragma solidity >=0.6.2;
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity >=0.6.2 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

pragma solidity >=0.6.2;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
  //
  // V2 Interface:
  //
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  //
  // V3 Interface:
  //
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}