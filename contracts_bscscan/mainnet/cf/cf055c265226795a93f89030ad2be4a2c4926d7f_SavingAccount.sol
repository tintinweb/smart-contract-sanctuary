pragma solidity >= 0.5.0 < 0.6.0;

import "./TokenInfoLib.sol";
import "./SymbolsLib.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./Ownable.sol";
import "./SavingAccountParameters.sol";
import "./IERC20.sol";
import "./ABDK.sol";
import "./tokenbasic.sol";


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface RateInternal {
	function getCurrentBorrowRate(int256 totalLoans,int256 totalDeposits) external returns (uint);
	function getCurrentSupplyRate(int256 totalLoans,int256 totalDeposits) external returns (uint);
}

interface takenInfoInternal {
	function getTotalAmount(address accountAddr, address tokenAddress) view external returns(int256);
	function getCurrentTotalAmount(address accountAddr, address tokenAddress) view external returns(int256);
	function getTokenNumbers(address tokenAddress,address account) view external returns (int256 amount);
	function addAmount(address tokenAddress,address account,  uint256 amount, uint256 rate, uint256 currentTimestamp)external returns(int256);
	function minusAmount(address account,address tokenAddress,  uint256 amount, uint256 rate, uint256 currentTimestamp)external;
	function getActive(address accountAddr) view external returns(bool);
    function setActive(address accountAddr, bool act)external;
    function setActiveAccountse(address accountAddr) external;
    function getActiveAccountse() view external returns(address[] memory);
}

interface stakeInternal {
    function checkHalve()external;
    function updateReward(address account,address tokenID,int256 totalDeposits,int256 totalLoans) external;
    function _startTime()external view returns(uint256);
    function getReward(address account) external;
}


interface getPrice_{
    function update_() external;
    function getPrice()  external view returns(uint256[] memory );
}

interface IPlayerBook {
    function settleReward( address from,uint256 amount ) external returns (uint256);
}

contract SavingAccount is Ownable{
	using SymbolsLib for SymbolsLib.Symbols;
	using SafeMath for uint256;
	using SignedSafeMath for int256;
	using SafeERC20 for IERC20;


    event borrowed(address onwer,uint256 amount,address tokenaddress);
	event depositTokened(address onwer,uint256 amount,address tokenaddress);
	event repayed(address onwer,uint256 amount,address tokenaddress);
	event withdrawed(address onwer,uint256 amount,address tokenaddress);
	event liquidated(address onwer);
	
	event changeFeeAddr(address _eaddr);
	event changeSkyfAddr(address _eaddr);
	event changeTokenInfoAddr(address _eaddr);
	event changeStakeInternalAddr(address _eaddr);
	event changeRateInternalAddr(address _eaddr);
	event changeFee(uint _feeRepay,uint _feeLiquidate);
    
    
    mapping(address => int256) public totalDeposits;
	mapping(address => int256) public totalLoans;
    
    uint256 SUPPLY_APR_PER_SECOND = 4755;	                               
	uint256 BORROW_APR_PER_SECOND = 6340;                                 
    
	
	address public _skyfAdress = 0x9E570F7c7068B4aCcC519DDA3A92544Cd5947692;             //todo
	address public price_address = 0xC6263fd7fE167Df6a4959D15445F757Fc45D03a3;         //todo----------------------------------------------------------
	address public rate_address = 0xbC998503C83f0591aadCC6BC9Bfa8312aC28425C;         //todo---------------------------------------
	
	address public takenInfo_address = 0x2c60e3b6CDc9cC7E90e6961F6B2B7b4bFd2f0F6D;     //todo---------------------------------------
	address public stakeInternal_add;
	
	address public feeAddr;
	
//   address _teamWallet = 0x19b9712FA52eedfe4EBCd18E9b31EaCcd79fD61C;
// 	address Playbook = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
	
    mapping(address => bool) loansAccount;
    mapping(address => uint256)_initTokenReward;
    uint256 constant REWARD_FEE_BASE = 10000;
    
    
    uint public feeRepay = 80;
    uint public feeLiquidate = 80;
    
    
    // uint256  _teamRewardRate = 0;
    uint256  _baseRate = 10000;
	SymbolsLib.Symbols symbols;
	int256 constant BASE = 10**6;                                                          //usd base-------------
	mapping(address => uint256) public BORROW_LTV;                                                              
	int LIQUIDATE_THREADHOLD = 110;                                                          //LIQUIDATE rate

	constructor(address _feeAddr) public {
		SavingAccountParameters params = new SavingAccountParameters();
		address[] memory tokenAddresses = params.getTokenAddresses();
		symbols.initialize(params.ratesURL(), params.tokenNames(), tokenAddresses);
		
		//init
		uint coinsLen = getCoinLength();
		for (uint i = 0; i < coinsLen; i++) {
			address token_Address = symbols.addressFromIndex(i);
			BORROW_LTV[token_Address] = 66;
		}
		
		feeAddr = _feeAddr;
	}
    
    function setFeeAddr(address _feeAddr) external onlyOwner{
	    feeAddr = _feeAddr;
	    emit changeFeeAddr(feeAddr);
	} 
	

	function setSkyfToken(address token) external onlyOwner{
	    _skyfAdress = token;
	    emit changeSkyfAddr(_skyfAdress);
	} 
	
	function setTokenInfoAddress(address _takenInfoAddress) external onlyOwner{
	    takenInfo_address = _takenInfoAddress;
	    emit changeTokenInfoAddr(takenInfo_address);
	} 
	
	function setStakeInternalAdd(address _stakeInternalAdd) external onlyOwner{
	    stakeInternal_add = _stakeInternalAdd;
	    emit changeStakeInternalAddr(stakeInternal_add);
	} 
	
	function setRateInternal(address _rateInternal) external onlyOwner{
	    rate_address = _rateInternal;
	    emit changeRateInternalAddr(rate_address);
	} 
	
	function setRateAllFee(uint _feeRepay,uint _feeLiquidate) external onlyOwner{
	    feeRepay = _feeRepay;
	    feeLiquidate = _feeLiquidate;
	    emit changeFee(feeRepay,feeLiquidate);
	}
	
	 
// 	function setTeamToken(address tokenaddress,uint256 teamRewardRate,address Playbook_) external onlyOwner{
// 	    _teamWallet = tokenaddress;
// 	    _teamRewardRate = teamRewardRate;
// 	    Playbook = Playbook_;
// 	}
	 
	 
	function() external payable {}
	
	
    function setPrice(uint256[] memory list) private {
        symbols.setPriceByList(list);
    }
    
    function getAddressFromIndex(uint _index) public view returns(address){
	    return symbols.addressFromIndex(_index);
	}
    
	function getAccountTotalUsdValue(address accountAddr, bool isPositive) public view returns (int256 usdValue){
		int256 totalUsdValue = 0;
		for(uint i = 0; i < getCoinLength(); i++) {
			if (isPositive && takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i)) >= 0) {
				totalUsdValue = totalUsdValue.add(
					takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i))
					.mul(int256(symbols.priceFromIndex(i)))
					.div(BASE)
				);
			}
			if (!isPositive && takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i)) < 0) {
				totalUsdValue = totalUsdValue.add(
					takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i))
					.mul(int256(symbols.priceFromIndex(i)))
					.div(BASE)
				);
			}
		}
		return totalUsdValue;
	}
	
    modifier checkHalve() {
        stakeInternal(stakeInternal_add).checkHalve();
        _;
    }
    
    modifier checkStart() {
        require(block.timestamp > stakeInternal(stakeInternal_add)._startTime(), "not start");
        getPrice_(price_address).update_();                                                             
        setPrice(getPrice_(price_address).getPrice());
        _;
    }
    
	modifier updateReward(address account,address tokenID) {
        stakeInternal(stakeInternal_add).updateReward(account, tokenID,totalDeposits[tokenID],totalLoans[tokenID]);
        _;
    } 
	
	modifier updateRewardAll(address account) {
        uint coinsLen = getCoinLength();
        for (uint i = 0; i < coinsLen; i++) {
			address tokenID = symbols.addressFromIndex(i);
            stakeInternal(stakeInternal_add).updateReward( account, tokenID,totalDeposits[tokenID],totalLoans[tokenID]);
        }
    _;
	}

	
// 	function getBalances() public returns (address[] memory addresses, int256[] memory balances)
// 	{
// 		uint coinsLen = getCoinLength();

// 		addresses = new address[](coinsLen);
// 		balances = new int256[](coinsLen);

// 		for (uint i = 0; i < coinsLen; i++) {
// 			address tokenAddress = symbols.addressFromIndex(i);
// 			addresses[i] = tokenAddress;
// 			balances[i] = tokenBalanceOf(tokenAddress);
// 		}

// 		return (addresses, balances);
// 	}
    
    //  without interest    -----------------------------
    function tokenNumbers(address tokenAddress,address account)public view returns (int256 amount) {
		return takenInfoInternal(takenInfo_address).getTokenNumbers(tokenAddress, account);
	}
    
	function getCoinLength() public view returns (uint256 length){
		return symbols.getCoinLength();
	}

	function tokenBalanceOf(address tokenAddress,address account) public view returns (int256 amount) {
		return takenInfoInternal(takenInfo_address).getTotalAmount(account, tokenAddress);
	}
	
	
	function setBorrowLTV(address tokenaddress,uint256 ltv) public onlyOwner{
	    require(ltv <= 100 , "ltv cant");
		BORROW_LTV[tokenaddress] = ltv;
	}
    
    /** 
	 * funcs of rate
	 */
	
	function getAvailableForLoan(address accountAddr) public view returns (int256) {
		int256 totalUsdValue = 0;
		for(uint i = 0; i < getCoinLength(); i++) {
			if (takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i)) >= 0) {
				totalUsdValue = totalUsdValue.add(
					takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i))
					.mul(int256(symbols.priceFromIndex(i)))
					.mul(int256(BORROW_LTV[symbols.addressFromIndex(i)])).div(100)
					.div(BASE)
				);
			}
		}
		return totalUsdValue;
	}
	
	function updateAccountRate(address accountAddr) public {
		for(uint i = 0; i < getCoinLength(); i++) {
		    if(totalLoans[symbols.addressFromIndex(i)] > 0 )
		    {
		        if (takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i)) >= 0) {
				SUPPLY_APR_PER_SECOND = totalDeposits[symbols.addressFromIndex(i)]>0? RateInternal(rate_address).getCurrentSupplyRate(totalLoans[symbols.addressFromIndex(i)], totalDeposits[symbols.addressFromIndex(i)]) : 0;
				takenInfoInternal(takenInfo_address).addAmount(accountAddr, symbols.addressFromIndex(i),0, SUPPLY_APR_PER_SECOND, block.timestamp);
    			}
    			if (takenInfoInternal(takenInfo_address).getTotalAmount(accountAddr, symbols.addressFromIndex(i)) < 0) {
    				BORROW_APR_PER_SECOND = totalDeposits[symbols.addressFromIndex(i)]>0?RateInternal(rate_address).getCurrentBorrowRate(totalLoans[symbols.addressFromIndex(i)], totalDeposits[symbols.addressFromIndex(i)]):0;
    				takenInfoInternal(takenInfo_address).minusAmount(accountAddr, symbols.addressFromIndex(i),0, BORROW_APR_PER_SECOND, block.timestamp);
    			}
		    }
		}
	}
    
    
	/** 
	 * Deposit the amount of tokenAddress to the saving pool. 
	 */
	
// 	function getCoinToUsdRate() public view returns(uint256[] memory) {
// 		//return symbols.priceFromIndex(coinIndex);
// 		uint length = getCoinLength();
// 		uint256[] memory  listOfPrice = new uint256[](length);
// 		for(uint i=0;i<length;i++){
// 			listOfPrice[i] = symbols.priceFromIndex(i);
// 		}
// 		return listOfPrice;
// 	}

    function getCoinToUsdRate(address tokenAddress) public view returns(uint) {
		return symbols.priceFromAddress(tokenAddress);
	}



	function borrow(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkStart checkHalve public payable {
	    require(tokenAddress!=_skyfAdress,"can't borrow TLS");
		require(takenInfoInternal(takenInfo_address).getActive(msg.sender), "Account not active, please deposit first.");
		if (!loansAccount[msg.sender]) {
			loansAccount[msg.sender] = true;
		}
		require(takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress) <= int256(amount), "Borrow amount less than available balance, please use withdraw instead.");
		require(
			(
				int256(getAccountTotalUsdValue(msg.sender, false).mul(-1))
				.add(int256(amount.mul(symbols.priceFromAddress(tokenAddress))).div(BASE))
			)
			<=
			getAvailableForLoan(msg.sender),
			 "Insufficient collateral.");

        emit borrowed(msg.sender,amount,tokenAddress);
        int256 trueValue = 0;
        trueValue = takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress)<=0?int256(amount):int256(amount)-takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress);
		
        if(trueValue!=int256(amount)){
            totalDeposits[tokenAddress] = totalDeposits[tokenAddress].sub(int256(takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress)));
            
        }
        
        takenInfoInternal(takenInfo_address).minusAmount(msg.sender, tokenAddress,amount, 0, block.timestamp);
        
		totalLoans[tokenAddress] = totalLoans[tokenAddress].add(int256(trueValue));
		
		updateAccountRate(msg.sender);
		
		
        send(msg.sender, amount, tokenAddress);

	}

	function repay(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkStart checkHalve public payable returns(int256,int256){
		require(takenInfoInternal(takenInfo_address).getActive(msg.sender), "Account not active, please deposit first.");
		int256 amountOwedWithInterest = takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress);
		require(amountOwedWithInterest <= 0, "Balance of the token must be negative. To deposit balance, please use deposit button.");
		int256 amountBorrowed = takenInfoInternal(takenInfo_address).getCurrentTotalAmount(msg.sender, tokenAddress).mul(-1);// get the actual amount that was borrowed (abs)
		int256 amountToRepay = int256(amount);
		//require(amountToRepay <= amountBorrowed, "repay more than borrowed");
		
		repqyFeeTranfer( amountToRepay , tokenAddress);
		
		//BORROW_APR_PER_SECOND = totalDeposits[tokenAddress]>0 && totalLoans[tokenAddress] > 0?RateInternal(rate_address).getCurrentBorrowRate(totalLoans[tokenAddress], totalDeposits[tokenAddress]):0;
		takenInfoInternal(takenInfo_address).addAmount(msg.sender, tokenAddress,amount, 0, block.timestamp);
		
		if (amountToRepay > amountBorrowed) {
			totalDeposits[tokenAddress] = totalDeposits[tokenAddress].add(amountToRepay.sub(amountBorrowed));
			totalLoans[tokenAddress] = totalLoans[tokenAddress].sub(amountBorrowed);
		}
		else {
			totalLoans[tokenAddress] = totalLoans[tokenAddress].sub(amountToRepay);
		}
		
		if(totalLoans[tokenAddress] < 0)
		{
		    totalLoans[tokenAddress] = 0;
		}
		
		updateAccountRate(msg.sender);
		
		emit repayed(msg.sender,amount,tokenAddress);
		receive(msg.sender, uint256(amount), amount,tokenAddress);
		return(amountBorrowed,amountToRepay);
	}
	
	function repqyFeeTranfer(int amountToRepay ,address tokenAddress)internal{
	    uint feeToPay = uint(amountToRepay).mul(feeRepay).mul(symbols.priceFromAddress(tokenAddress)).div(REWARD_FEE_BASE).div(symbols.priceFromAddress(_skyfAdress));
		allFeeTranfer(msg.sender, feeToPay,_skyfAdress);
	}
	


	function Liquidate(address targetAddress) public payable updateRewardAll(targetAddress) checkHalve checkStart{
		require(
			int256(getAccountTotalUsdValue(targetAddress, false).mul(-1))
			.mul(100)
			>
			getAvailableForLoan(targetAddress).mul(LIQUIDATE_THREADHOLD),
			"The ratio of borrowed money and collateral must be larger than 85% in order to be liquidated.");
        emit liquidated(targetAddress);
		uint coinsLen = getCoinLength();
		for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			int256 totalAmount = takenInfoInternal(takenInfo_address).getTotalAmount(targetAddress, tokenAddress);
			if (totalAmount > 0) {
				send(msg.sender, uint256(totalAmount), tokenAddress);
				takenInfoInternal(takenInfo_address).minusAmount(targetAddress ,tokenAddress, uint256(totalAmount), 0, block.timestamp);
				totalDeposits[tokenAddress] = totalDeposits[tokenAddress].sub(totalAmount);
			} else if (totalAmount < 0) {
				//TODO uint256(-totalAmount) this will underflow - Critical Security Issue
				//TODO what is the reason for doing this???
				
				
				uint skyToPay = uint(-totalAmount).mul(feeLiquidate).mul(symbols.priceFromAddress(tokenAddress)).div(REWARD_FEE_BASE).div(symbols.priceFromAddress(_skyfAdress));
		      //  receive(msg.sender, skyToPay, skyToPay, _skyfAdress);
		        allFeeTranfer(msg.sender, skyToPay,_skyfAdress);
				receive(msg.sender, uint256(-totalAmount),uint256(-totalAmount), tokenAddress); 
				
				
				takenInfoInternal(takenInfo_address).addAmount(targetAddress, tokenAddress,uint256(-totalAmount), 0, block.timestamp);
				totalLoans[tokenAddress] = totalLoans[tokenAddress].sub(-totalAmount);
				
				if(totalLoans[tokenAddress] < 0)
        		{
        		    totalLoans[tokenAddress] = 0;
        		}
			}
		}
	}
	
	function allFeeTranfer(address from, uint256 amount,address tokenAddress)internal{
	    require(IERC20(tokenAddress).transferFrom(from, feeAddr, amount));
	}
	
	
	function getLiquidatableAccounts() public view returns (address[] memory) {
	    address[] memory totalAccounts = takenInfoInternal(takenInfo_address).getActiveAccountse();
		address[] memory liquidatableAccounts = new address[](totalAccounts.length);
		uint returnIdx;
		//TODO `activeAccounts` not getting removed from array.
		//TODO its always increasing. Call to this function needing
		//TODO more gas, however, it will not be charged in ETH.
		//TODO What could be the impact? 
		for (uint i = 0; i < totalAccounts.length; i++) {
			address targetAddress = totalAccounts[i];
			if (
				int256(getAccountTotalUsdValue(targetAddress, false).mul(-1))
			.mul(100)
			>
			getAvailableForLoan(targetAddress).mul(LIQUIDATE_THREADHOLD)
			) {
				liquidatableAccounts[returnIdx++] = targetAddress;
			}
		}
		return liquidatableAccounts;
	}
	

	function depositToken(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkHalve checkStart public payable {
 		if (!takenInfoInternal(takenInfo_address).getActive(msg.sender)) {
 		    takenInfoInternal(takenInfo_address).setActive(msg.sender, true);
 		    takenInfoInternal(takenInfo_address).setActiveAccountse(msg.sender);
 		}

		int256 currentBalance = takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress);

		require(currentBalance >= 0,
			"Balance of the token must be zero or positive. To pay negative balance, please use repay button.");
		
 		int256 depositedAmount = takenInfoInternal(takenInfo_address).addAmount(msg.sender, tokenAddress,amount, 0, block.timestamp) - currentBalance;
        
		totalDeposits[tokenAddress] = totalDeposits[tokenAddress].add(depositedAmount);
		
		updateAccountRate(msg.sender);
		
        emit depositTokened(msg.sender,amount,tokenAddress);
		receive(msg.sender, amount, amount,tokenAddress);
	}
	
	 
	function withdrawToken(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkStart checkHalve public payable {
		require(takenInfoInternal(takenInfo_address).getActive(msg.sender), "Account not active, please deposit first.");

		require(takenInfoInternal(takenInfo_address).getTotalAmount(msg.sender, tokenAddress) >= int256(amount), "Insufficient balance.");
  		// require(int256(getAccountTotalUsdValue(msg.sender, false).mul(-1)).mul(100) <= (getAccountTotalUsdValue(msg.sender, true) - int256(amount.mul(symbols.priceFromAddress(tokenAddress)).div(uint256(BASE)))).mul(int(BORROW_LTV[tokenAddress])));
        
        emit withdrawed(msg.sender,amount,tokenAddress);
        takenInfoInternal(takenInfo_address).minusAmount(msg.sender ,tokenAddress, amount, 0, block.timestamp);
		
		totalDeposits[tokenAddress] = totalDeposits[tokenAddress].sub(int256(amount));
		
		updateAccountRate(msg.sender);
		
		require(getAvailableForLoan(msg.sender).sub(int256(getAccountTotalUsdValue(msg.sender, false).mul(-1))) >= 0,"Insufficient collateral.");

		send(msg.sender, amount, tokenAddress);		
	}



	function receive(address from, uint256 amount, uint256 amounttwo,address tokenAddress) private {
		if (symbols.isEth(tokenAddress)) {
            require(msg.value >= amounttwo, "The amount is not sent from address.");
            msg.sender.transfer(msg.value-amounttwo);                                                   
		} else {
			require(msg.value >= 0, "msg.value must > 0 when receiving tokens");
			//if(tokenAddress!=0x32578Ca09Da276AfDff7943455eAa3f270dEDAb7){                               
			    require(IERC20(tokenAddress).transferFrom(from, address(this), amount));
// 			}else{
// 			    basic(tokenAddress).transferFrom(from,address(this),amount);
// 			}
		}
	}
	

// function receivemyself(address from, uint256 amount, address tokenAddress) private {



	function send(address to, uint256 amount, address tokenAddress) private {
		if (symbols.isEth(tokenAddress)) {
			msg.sender.transfer(amount);
		} else {
		    //if(tokenAddress!=0x32578Ca09Da276AfDff7943455eAa3f270dEDAb7){                       
			    require(IERC20(tokenAddress).transfer(to, amount));
            // 	}else{
            // 	 basic(tokenAddress).transfer(to, amount);
            // 	}
		}
	}
    
    
    function getReward() public updateRewardAll(msg.sender) checkHalve checkStart {
        stakeInternal(stakeInternal_add).getReward(msg.sender);
        updateAccountRate(msg.sender);
    }
    
    
    function Informations(address tokenAddress,address account) public view returns(uint256 _index,int256 _tokenbalance,int256 _totaldeposits,int256 _totalloans,uint _usdrate) {
		_index = BORROW_LTV[tokenAddress];
		_tokenbalance = tokenBalanceOf(tokenAddress, account);
		_totaldeposits = totalDeposits[tokenAddress];
		_totalloans = totalLoans[tokenAddress];
		_usdrate = getCoinToUsdRate(tokenAddress);
	}
    
}