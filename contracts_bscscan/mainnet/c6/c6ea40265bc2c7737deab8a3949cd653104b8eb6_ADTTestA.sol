/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
	ADTTest-A: An Olhympus Fork Testing ADTSlowMode and Buyback fron any BSC address.
	(C) 2021, AxionSempra / DefiAuditGroup(DAG)
	
	This is a beta Solidity Program. Use at your own risk. Caveat Emptor!
 */

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
	function setNextPayoutContract(address tokenizationAddress) external;
	function setPayoutAsContractAddressOrBUSD(bool busdEnabled) external;
	function checkBusdPayoutEnabled() external returns(bool);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
	
	//default it to BUSD but we can set it later
	IBEP20 ddCurentPayoutContract = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
	bool public ddSwitchToBUSDPayout = false;

    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }
	
	//set the new tokeniation address
	function setNextPayoutContract(address tokenizationAddress) external override onlyToken
	{
		ddCurentPayoutContract = IBEP20(tokenizationAddress);
	}
	
	//disable custom tokenization and switch to BUSD payout, like olymnpus
	function setPayoutAsContractAddressOrBUSD(bool busdEnabled) external override onlyToken
	{
		ddSwitchToBUSDPayout = busdEnabled;
	}
	
	function checkBusdPayoutEnabled() external override view returns(bool)
	{
	    return ddSwitchToBUSDPayout;
	}

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        if(ddSwitchToBUSDPayout == false)
		{
			uint256 balanceBefore = ddCurentPayoutContract.balanceOf(address(this));

			address[] memory path = new address[](2);
			path[0] = WBNB;
			path[1] = address(ddCurentPayoutContract);

			router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
				0,
				path,
				address(this),
				block.timestamp
			);

			uint256 amount = ddCurentPayoutContract.balanceOf(address(this)).sub(balanceBefore);

			totalDividends = totalDividends.add(amount);
			dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
		}
		else
		{
			uint256 balanceBefore = BUSD.balanceOf(address(this));

			address[] memory path = new address[](2);
			path[0] = WBNB;
			path[1] = address(BUSD);

			router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
				0,
				path,
				address(this),
				block.timestamp
			);

			uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

			totalDividends = totalDividends.add(amount);
			dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
		}
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

interface _ADTSlowMode
{
	function ADTEnableSlowMode(bool enabled) external;
	function ADTSetMinimumForSlowMode(uint256 minimum) external;
	function ADTAddAddressToList(address transactor, uint256 lastTransactionTime, uint256 totalTranactionAmount, uint256 timeLeft, uint256 numberExactMinimumBuys, bool isWhiteListed, uint256 lastMinimumProvided) external;
	function ADTCheckRemainingTime(address transactor) external returns(uint256);
	function ADTCheckAddressIsWhiteListed(address transactor) external returns(bool);
	function ADTCheckMinimumNeededForSlowMode() external returns(uint256);
	function ADTCheckNumberExactMinimumBuys(address transactor) external returns(uint256);
	function ADTEnableMultiplexForExactMinimumBuys(bool multpilexerEnabled) external;
	function ADTCheckIfMultiplexIsEnabled() external returns(bool);
	function ADTValidatePotentialTransaction(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ADTSlowMode is _ADTSlowMode
{
	struct _ADTTransactedAddress
	{
		uint256 _lastTransactionTime;
		uint256 _totalTransactionAmount;
		uint256 _timeLeft;
		uint256 _numberExactMinimumBuys;
		bool _isWhiteListed;
		uint256 _lastMinimumProvided;
	}
	
	address _PCSV2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	address _PCSLEGACY = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
						 
	
	uint256 _ADTMinAmountNeededForSlowMode;
	bool _ADTSlowModeIsEnabled;
	bool _ADTMultiplexEnabled;
	
	mapping(address => _ADTTransactedAddress) ADTTransactedAddresses;
	
	constructor()
	{
		_ADTMinAmountNeededForSlowMode = 20000 * 10**6 * 10**9;
		_ADTSlowModeIsEnabled = true;
		_ADTMultiplexEnabled = true;
	}
	
	function ADTEnableSlowMode(bool enabled) external override
	{
		_ADTSlowModeIsEnabled = enabled;
	}
	
	function ADTSetMinimumForSlowMode(uint256 minimum) external override
	{
		_ADTMinAmountNeededForSlowMode = minimum;
	}
	
	function ADTAddAddressToList(address transactor, uint256 lastTransactionTime, uint256 totalTranactionAmount, uint256 timeLeft, uint256 numberExactMinimumBuys, bool isWhiteListed, uint256 lastMinimumProvided) external override
	{
		ADTTransactedAddresses[transactor]._lastTransactionTime = lastTransactionTime;
		ADTTransactedAddresses[transactor]._totalTransactionAmount = totalTranactionAmount;
		ADTTransactedAddresses[transactor]._timeLeft = timeLeft;
		ADTTransactedAddresses[transactor]._numberExactMinimumBuys = numberExactMinimumBuys;
		ADTTransactedAddresses[transactor]._isWhiteListed = isWhiteListed;
		ADTTransactedAddresses[transactor]._lastMinimumProvided = lastMinimumProvided;
	}
	
	function ADTCheckRemainingTime(address transactor) external override view returns(uint256)
	{
		if(block.timestamp < (ADTTransactedAddresses[transactor]._lastTransactionTime + ADTTransactedAddresses[transactor]._timeLeft))
		{
		    return ((ADTTransactedAddresses[transactor]._lastTransactionTime + ADTTransactedAddresses[transactor]._timeLeft) - block.timestamp) / (1 * 10**8);
		}
		else return 0;
	}
	
	function ADTCheckAddressIsWhiteListed(address transactor) external override view returns(bool)
	{
		return ADTTransactedAddresses[transactor]._isWhiteListed;
	}
	
	function ADTCheckMinimumNeededForSlowMode() external override view returns(uint256)
	{
		return _ADTMinAmountNeededForSlowMode;
	}
	
	function ADTCheckNumberExactMinimumBuys(address transactor) external override view returns(uint256)
	{
		return ADTTransactedAddresses[transactor]._numberExactMinimumBuys;
	}
	
	function ADTEnableMultiplexForExactMinimumBuys(bool enabled) external override
	{
		_ADTMultiplexEnabled = enabled;
	}
	
	function ADTCheckIfMultiplexIsEnabled() external override view returns(bool)
	{
		return _ADTMultiplexEnabled;
	}
	
	function ADTValidatePotentialTransaction(address sender, address recipient, uint256 amount) external override returns(bool)
	{
		//check the from address to see if it is PancakeSwap V2 Router or PancakSwap Legacy Router.
		//if this is true, assume that the person is buying.
		//we want to check for legacy to enable backwards compatibility, but most contracts now will not be using it.
		
		if(sender == _PCSV2 || sender == _PCSLEGACY)
		{
			//check here if the recipient is whitelisted.
			//whitelisted addresses do not have slow mode enabled.
			//this is to preserve compatibility between CEX/DEX and presale addresses
			if(ADTTransactedAddresses[recipient]._isWhiteListed == true)
				return true;
			else
			{
				//we assume that the address is not whitelisted.
				//next we check to see if the total totalTranactionAmount is greater than the minimum needed to trigger slow mode
				//if yes we assume that the adress is in slow mode or has it enabled
				if(ADTTransactedAddresses[recipient]._totalTransactionAmount <= _ADTMinAmountNeededForSlowMode)
				{
					//check if the wallet has a listing in  ADTTransactedAddresses. There is no easy way to do this in Solidity.
					//Best way is to check if the lastMinimumProvided is Zero. It will only be zero if it has not been set yet.
					//This is convoluted, but it's how solidity works.
					if(ADTTransactedAddresses[recipient]._lastMinimumProvided == 0)
					{
						//assume that the address is new and has not been added so we need to set defaults
						ADTTransactedAddresses[recipient]._lastTransactionTime = block.timestamp;
						ADTTransactedAddresses[recipient]._lastMinimumProvided = _ADTMinAmountNeededForSlowMode;
						ADTTransactedAddresses[recipient]._isWhiteListed = false;
						
						//we need to check and see if the transaction is a minimum buy.
						//first we check for exact minimum, since this is a common tactic by buy-bots and whales trying to cause artificial gains
						//if true, we keep track of it and use it for the multiplexer.
						//if multiplexer is not enabled, we use a regulaar amount.
						//First exact minimum buy will be the exact same as if the multiplexer is disabled.
						if(amount == _ADTMinAmountNeededForSlowMode)
						{
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._numberExactMinimumBuys += 1;
							
							ADTTransactedAddresses[recipient]._timeLeft = (_ADTMultiplexEnabled == true) ? (100000000000 * ADTTransactedAddresses[recipient]._numberExactMinimumBuys) : 100000000000;	
						}
						else if(amount > _ADTMinAmountNeededForSlowMode)
						{
							//the amount being transfered is higher than the minimum, so we need to calculate the total wait time.
							
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._numberExactMinimumBuys = 0;
							
							ADTTransactedAddresses[recipient]._timeLeft = ((amount - _ADTMinAmountNeededForSlowMode)/2);
						}
						else
						{
							//we assume here that the amount is less than the minimum. So no time limit is imposed.
							//but we store the transaction value so we can add successive amounts to it.
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._numberExactMinimumBuys = 0;
							ADTTransactedAddresses[recipient]._timeLeft = 0;
						}
					}
					else
					{
						//we assume here that the transactor is in the list. and act accordingly
						ADTTransactedAddresses[recipient]._lastTransactionTime = block.timestamp;
						ADTTransactedAddresses[recipient]._lastMinimumProvided = _ADTMinAmountNeededForSlowMode;
						
						//we need to check and see if the transaction is a minimum buy.
						//first we check for exact minimum, since this is a common tactic by buy-bots and whales trying to cause artificial gains
						//if true, we keep track of it and use it for the multiplexer.
						//if multiplexer is not enabled, we use a regular amount.
						//First exact minimum buy will be the exact same as if the multiplexer is disabled.
						if(amount == _ADTMinAmountNeededForSlowMode)
						{
							ADTTransactedAddresses[recipient]._totalTransactionAmount += amount;
							ADTTransactedAddresses[recipient]._numberExactMinimumBuys += 1;
						
							ADTTransactedAddresses[recipient]._timeLeft = (_ADTMultiplexEnabled == true) ? ((ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode)  * ADTTransactedAddresses[recipient]._numberExactMinimumBuys) : (ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode);	
						}
						else if(amount > _ADTMinAmountNeededForSlowMode)
						{
							//the amount being transfered is higher than the minimum, so we need to calculate the total wait time.
						
							ADTTransactedAddresses[recipient]._totalTransactionAmount += amount;
							ADTTransactedAddresses[recipient]._timeLeft = ((ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode)/2);
						}
						else
						{
							//we assume here that the amount is less than the minimum. So no time limit is imposed.
							//but we store the transaction value so we can add successive amounts to it.
							ADTTransactedAddresses[recipient]._totalTransactionAmount += amount;
							ADTTransactedAddresses[recipient]._timeLeft = 0;
						}
					}
				}
				else
				{
					//we assume here that the transactor is in slowmode currently
					//we don't need to check if transactor exists as it should exist here.
					if(block.timestamp < ( ADTTransactedAddresses[recipient]._lastTransactionTime + ADTTransactedAddresses[recipient]._timeLeft))
					{
						//we need to return false since we cannot conduct the transaction
						return false;
					}
					else
					{
						//at this point we know that the time has to be up, and we can procede with thransaction
						ADTTransactedAddresses[recipient]._lastTransactionTime = block.timestamp;
						ADTTransactedAddresses[recipient]._lastMinimumProvided = _ADTMinAmountNeededForSlowMode;
						
						//we need to check and see if the transaction is a minimum buy.
						//first we check for exact minimum, since this is a common tactic by buy-bots and whales trying to cause artificial gains
						//if true, we keep track of it and use it for the multiplexer.
						//if multiplexer is not enabled, we use a regular amount.
						//First exact minimum buy will be the exact same as if the multiplexer is disabled.
						if(amount == _ADTMinAmountNeededForSlowMode)
						{
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._numberExactMinimumBuys += 1;
						
							ADTTransactedAddresses[recipient]._timeLeft = (_ADTMultiplexEnabled == true) ? ((ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode)  * ADTTransactedAddresses[recipient]._numberExactMinimumBuys) : (ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode);	
						}
						else if(amount > _ADTMinAmountNeededForSlowMode)
						{
							//the amount being transfered is higher than the minimum, so we need to calculate the total wait time.
						
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._timeLeft = ((ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode)/2);
						}
						else
						{
							//we assume here that the amount is less than the minimum. So no time limit is imposed.
							//but we store the transaction value so we can add successive amounts to it.
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._timeLeft = 0;
						}
					}
				}
			}
		}
		else
		{
			//we assume here that this is a sell or a wallet-to-wallet transfer.
			//sells and transfers have a higher  wait period than buys. we want people to buy into the token, but slow their sales.
			//this is not about being a honeypot, it's about controlling whales from dumping the token to buy back in low, while inhibiting bots.
			
			//first we need to check if the Sender is whitelisted, and return true if yes
			if(ADTTransactedAddresses[sender]._isWhiteListed == true)
				return true;
			else
			{
				//sender isn't whitelisted so we need to check it's values.
				//we still need to check if they exist, as not doing so would break airdrops and transfers to new wallets.
				//we will use the same check as for buys.
				//we're doing this inverse from buys though, because with sells, we don't need to check the transfer amount first to see if the account is sending the minimum.
				//they will only be transfering if they have token to send and they are not currently in slow mode.
				if(ADTTransactedAddresses[sender]._lastMinimumProvided == 0)
				{
					//The wallet here has token but has never transacted (got airdropped or had token transfered from a base address, other than PCS, to it)
					//since this is a first sell, we assume that the sell will go through.
					//assume that the address is new and has not been added so we need to set defaults
					ADTTransactedAddresses[sender]._lastTransactionTime = block.timestamp;
					ADTTransactedAddresses[sender]._lastMinimumProvided = _ADTMinAmountNeededForSlowMode;
					ADTTransactedAddresses[sender]._isWhiteListed = false;
						
					//we need to check and see if the transaction is a minimum buy.
					//first we check for exact minimum, since this is a common tactic by buy-bots and whales trying to cause artificial gains
					//if true, we keep track of it and use it for the multiplexer.
					//if multiplexer is not enabled, we use a regulaar amount.
					//First exact minimum buy will be the exact same as if the multiplexer is disabled.
					if(amount == _ADTMinAmountNeededForSlowMode)
					{
						ADTTransactedAddresses[sender]._totalTransactionAmount = amount;
						ADTTransactedAddresses[sender]._numberExactMinimumBuys += 1;
						
						ADTTransactedAddresses[sender]._timeLeft = (_ADTMultiplexEnabled == true) ? (100000000000 * ADTTransactedAddresses[recipient]._numberExactMinimumBuys) : 100000000000;	
					}
					else if(amount > _ADTMinAmountNeededForSlowMode)
					{
						//the amount being transfered is higher than the minimum, so we need to calculate the total wait time.
						
						ADTTransactedAddresses[sender]._totalTransactionAmount = amount;
						ADTTransactedAddresses[sender]._numberExactMinimumBuys = 0;
						
						ADTTransactedAddresses[sender]._timeLeft = (amount - _ADTMinAmountNeededForSlowMode);
					}
					else
					{
						//we assume here that the amount is less than the minimum. So no time limit is imposed.
						//but we store the transaction value so we can add successive amounts to it.
						ADTTransactedAddresses[sender]._totalTransactionAmount += amount;
						ADTTransactedAddresses[sender]._numberExactMinimumBuys = 0;
						ADTTransactedAddresses[sender]._timeLeft = 0;
					}
				}
				else
				{
					//assume the transactor is in slow mode.we need to check and see if the time is up
					if(block.timestamp < (ADTTransactedAddresses[sender]._lastTransactionTime + ADTTransactedAddresses[sender]._timeLeft))
					{
						//return false since we cannot conduct the transaction
						return false;
					}
					else
					{
						//we can assume that the time is up and conduct the transaction.
						//at this point we know that the time has to be up, and we can procede with thransaction
						ADTTransactedAddresses[recipient]._lastTransactionTime = block.timestamp;
						ADTTransactedAddresses[recipient]._lastMinimumProvided = _ADTMinAmountNeededForSlowMode;
						
						//we need to check and see if the transaction is a minimum buy.
						//first we check for exact minimum, since this is a common tactic by buy-bots and whales trying to cause artificial gains
						//if true, we keep track of it and use it for the multiplexer.
						//if multiplexer is not enabled, we use a regular amount.
						//First exact minimum buy will be the exact same as if the multiplexer is disabled.
						if(amount == _ADTMinAmountNeededForSlowMode)
						{
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._numberExactMinimumBuys += 1;
						
							ADTTransactedAddresses[recipient]._timeLeft = (_ADTMultiplexEnabled == true) ? ((ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode)  * ADTTransactedAddresses[recipient]._numberExactMinimumBuys) : (ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode);	
						}
						else if(amount > _ADTMinAmountNeededForSlowMode)
						{
							//the amount being transfered is higher than the minimum, so we need to calculate the total wait time.
						
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._timeLeft = (ADTTransactedAddresses[recipient]._totalTransactionAmount - _ADTMinAmountNeededForSlowMode);
						}
						else
						{
							//we assume here that the amount is less than the minimum. So no time limit is imposed.
							//but we store the transaction value so we can add successive amounts to it.
							ADTTransactedAddresses[recipient]._totalTransactionAmount = amount;
							ADTTransactedAddresses[recipient]._timeLeft = 0;
						}
					}
				}
			}
		}
		return true;
	}
}
				
			
		
	
	
contract ADTTestA is IBEP20, Auth {
    using SafeMath for uint256;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "ADTTestA";
    string constant _symbol = "ADTTA";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 2917000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    uint256 liquidityFee = 400;
    uint256 buybackFee = 400;
    uint256 reflectionFee = 400;
    uint256 marketingFee = 200;
    uint256 totalFee = 1400;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
	
	//ADT and new code
	
	ADTSlowMode public adtSlowMode;
	

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _presaler,
        address _presaleContract
    ) Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[_presaler] = true;
        isTxLimitExempt[_presaler] = true;
        isFeeExempt[_presaleContract] = true;
        isTxLimitExempt[_presaleContract] = true;
        isDividendExempt[_presaleContract] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
	
	//set the tokenization contract
	function ddSetTokenizationContract(address contractAddress) external authorized
	{
		distributor.setNextPayoutContract(contractAddress);
	}
	
	//get the tokenization contract
	function ddReturnCurrentTokenizationContract() external view returns (address)
	{
		//return address(distributor.ddCurentPayoutContract);
	}
	
	//enable or disable BUSD payout instead of custom tokenization.
	function ddSetPayoutToBUSDEnabled(bool enabled) external authorized
	{
		distributor.setPayoutAsContractAddressOrBUSD(enabled);
	}
	
	function ddReturnWhetherBUSDIsEnabled() public view returns (bool)
	{
		return distributor.checkBusdPayoutEnabled();
	}
	
	function setMinimumNeededForSlowMode(uint256 _value) public authorized
	{
		adtSlowMode.ADTSetMinimumForSlowMode(_value);
	}
	
	function enableSlowModeOnContract(bool _enabled) public authorized
	{
		adtSlowMode.ADTEnableSlowMode(_enabled);
	}
	
	function enableMultiplexerOnSlowMode(bool _enabled) public authorized
	{
		adtSlowMode.ADTEnableMultiplexForExactMinimumBuys(_enabled);
	}
	
	function addAddressToADTTransactionList(address _transactor, uint256 _lastTransactionTime, uint256 _totalTranactionAmount, uint256 _timeLeft, uint256 _numberExactMinimumBuys, bool _isWhiteListed, uint256 _lastMinimumProvided) public authorized
	{
		adtSlowMode.ADTAddAddressToList(_transactor, _lastTransactionTime, _totalTranactionAmount, _timeLeft, _numberExactMinimumBuys, _isWhiteListed, _lastMinimumProvided);
	}
	
	function validatePotentialTransaction(address _sender, address _recipient, uint256 _amount) public returns(bool)
	{
		return adtSlowMode.ADTValidatePotentialTransaction(_sender, _recipient, _amount);
	}
	
	function checkAddressRemaningTimeInSlowMode(address _transactor) public view returns(uint256)
	{
		return adtSlowMode.ADTCheckRemainingTime(_transactor);
	}
	
	function checkAddressIsWhiteListed(address _transactor) public view returns(bool)
	{
		return adtSlowMode.ADTCheckAddressIsWhiteListed(_transactor);
	}
	
	function checkMinimumNeededForSlowMode() public view returns(uint256)
	{
		return adtSlowMode.ADTCheckMinimumNeededForSlowMode();
	}
	
	function checkAddressExactMinimumBuys(address _transactor) public view returns(uint256)
	{
		return adtSlowMode.ADTCheckNumberExactMinimumBuys(_transactor);
	}
	
	function checkIfMultiplexIsEnabledOnSlowMode() public view returns(bool)
	{
		return adtSlowMode.ADTCheckIfMultiplexIsEnabled();
	}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(validatePotentialTransaction(msg.sender, recipient, amount) != false, "Your wallet is limited due to SlowMode. Please Try Again Later.");
		return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerZeusBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}