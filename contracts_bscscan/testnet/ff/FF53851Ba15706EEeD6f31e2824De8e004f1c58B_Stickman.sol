/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: UNLICENSED

/*		     _\|/_
             (o o)
+---------oOO-{_}-OOo----------------------------------------------------------------------------------------------------------------------+
|                                                                                                                                          |
|    \        ███████╗████████╗██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ███╗   ██╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗        /   |
|     \0      ██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝████╗ ████║██╔══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║      0/    |
|      |\/    ███████╗   ██║   ██║██║     █████╔╝ ██╔████╔██║███████║██╔██╗ ██║       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║    \/|     |
|      |      ╚════██║   ██║   ██║██║     ██╔═██╗ ██║╚██╔╝██║██╔══██║██║╚██╗██║       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║      |     |
|     / \     ███████║   ██║   ██║╚██████╗██║  ██╗██║ ╚═╝ ██║██║  ██║██║ ╚████║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║     / \    |	
|____/___\__  ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ___/___\_  |
+-----------------------------------------------------------------------------------------------------------------------------------------*/

pragma solidity 0.8.9;

/*************************/
/*  I n t e r f a c e s  */
/*************************/

interface IBEP20 {
	function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint256);
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

interface IPancakeERC20 {
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	function nonces(address owner) external view returns (uint);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function decimals() external pure returns (uint8);
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function domainSeperator() external view returns (bytes32);
	function permitTypeHash() external pure returns (bytes32);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPancakeFactory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);
	function feeTo() external view returns (address);
	function feeToSetter() external view returns (address);
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function allPairs(uint) external view returns (address pair);
	function allPairsLength() external view returns (uint);
	function createPair(address tokenA, address tokenB) external returns (address pair);
	function setFeeTo(address) external;
	function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
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
	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETH(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountToken, uint amountETH);
	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETHWithPermit(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountToken, uint amountETH);
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
		external
		payable
		returns (uint[] memory amounts);
	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
		external
		returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
		external
		returns (uint[] memory amounts);
	function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
		external
		payable
		returns (uint[] memory amounts);
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
	function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
	function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountETH);
	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountETH);
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

/***********************/
/*  L i b r a r i e s  */
/***********************/

abstract contract Ownable {
	address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () {
		address msgSender = msg.sender;
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

    /****************
    * Current owner *
    *****************/

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == msg.sender, "Ownable: caller is not the owner");
		_;
	}

    /*********************
    * Renounce ownership *
    **********************/

	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}
	
	/*********************
    * Transfer ownership *
    **********************/
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

/****************************************************************
 * Enumerable Set - Library for managing set of primitive types *
 ****************************************************************/

library EnumerableSet {

    struct Set {
		bytes32[] _values;
		mapping (bytes32 => uint256) _indexes;
	}

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

	function _remove(Set storage set, bytes32 value) private returns (bool) {
		uint256 valueIndex = set._indexes[value];
            if (valueIndex != 0) {
                uint256 toDeleteIndex = valueIndex - 1;
		        uint256 lastIndex = set._values.length - 1;
                bytes32 lastvalue = set._values[lastIndex];
		        set._values[toDeleteIndex] = lastvalue;
		        set._indexes[lastvalue] = valueIndex;
		        set._values.pop();
		        delete set._indexes[value];
                return true;
            } else {
                return false;
		}
	}

	function _contains(Set storage set, bytes32 value) private view returns (bool) {
		return set._indexes[value] != 0;
	}

	function _length(Set storage set) private view returns (uint256) {
		return set._values.length;
	}

	function _at(Set storage set, uint256 index) private view returns (bytes32) {
		require(set._values.length > index, "EnumerableSet: index out of bounds");
		return set._values[index];
	}

    /***************
    * Bytes32 sets *
    ****************/

	struct Bytes32Set {
		Set _inner;
	}

	function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
		return _add(set._inner, value);
	}

	function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
		return _remove(set._inner, value);
	}

	function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
		return _contains(set._inner, value);
	}

	function length(Bytes32Set storage set) internal view returns (uint256) {
		return _length(set._inner);
	}

	function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
		return _at(set._inner, index);
	}

    /***************
    * Address sets *
    ****************/

	struct AddressSet {
		Set _inner;
	}

	function add(AddressSet storage set, address value) internal returns (bool) {
		return _add(set._inner, bytes32(uint256(uint160(value))));
	}

	function remove(AddressSet storage set, address value) internal returns (bool) {
		return _remove(set._inner, bytes32(uint256(uint160(value))));
	}

	function contains(AddressSet storage set, address value) internal view returns (bool) {
		return _contains(set._inner, bytes32(uint256(uint160(value))));
	}

	function length(AddressSet storage set) internal view returns (uint256) {
		return _length(set._inner);
	}

	function at(AddressSet storage set, uint256 index) internal view returns (address) {
		return address(uint160(uint256(_at(set._inner, index))));
	}

    /************
    * Uint sets *
    *************/

	struct UintSet {
        Set _inner;
	}
	
	function add(UintSet storage set, uint256 value) internal returns (bool) {
		return _add(set._inner, bytes32(value));
	}
	
	function remove(UintSet storage set, uint256 value) internal returns (bool) {
		return _remove(set._inner, bytes32(value));
	}
	
	function contains(UintSet storage set, uint256 value) internal view returns (bool) {
		return _contains(set._inner, bytes32(value));
	}

	function length(UintSet storage set) internal view returns (uint256) {
		return _length(set._inner);
	}

	function at(UintSet storage set, uint256 index) internal view returns (uint256) {
		return uint256(_at(set._inner, index));
	}
}

/*****************************************************************
 * Address - Collection of functions related to the address type *
 *****************************************************************/
 
 library Address {

   /***************************
   * Is an address a contract *
   ****************************/

	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(account) }
		return size > 0;
	}

    /********************************
    * Solidity transfer replacement *
    *********************************/

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		//solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

    /*******************************
    * Solidity safe function calls *
    ********************************/

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
	  return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		  // solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		  // solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

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

/***************************************/
/*  S t i c k m a n   C o n t r a c t  */
/***************************************/

contract Stickman is IBEP20, Ownable {
	using Address for address;
	using EnumerableSet for EnumerableSet.AddressSet;
	
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => uint256) private _sellLock;
	mapping (address => uint256) private _buyLock;
	EnumerableSet.AddressSet private _excluded;
	EnumerableSet.AddressSet private _excludedFromSellLock;
	EnumerableSet.AddressSet private _excludedFromBuyLock;
	EnumerableSet.AddressSet private _excludedFromDividends;
	
    /***********
    * Metadata *
    ************/
	
	string private constant _NAME = "Stickman Token";
	string private constant _SYMBOL = "STICK";
	uint8 private constant _DECIMALS = 9;
	uint256 public constant INITIAL_SUPPLY= 100000000* 10**_DECIMALS;
	
	//Divider for the MaxBalance based on circulating Supply (5%)
	uint8 private constant BALANCE_LIMIT_DIVIDER=20;
	//Divider for sellLimit based on circulating Supply (5%)
	uint16 private constant SELL_LIMIT_DIVIDER=100;
	//Sellers get locked for MaxSellLockTime (put in seconds, works better especially if changing later) so they can't dump repeatedly
	uint16 public constant MAX_SELL_LOCK_TIME= 300;
	//Buyers get locked for MaxBuyLockTime (put in seconds, works better especially if changing later) so they can't buy repeatedly
	uint16 public constant MAX_BUY_LOCK_TIME= 300;
	//The time Liquidity gets locked at start and prolonged once it gets released
	uint256 private constant DEFAULT_LIQUIDITY_LOCK_TIME= 1800;
	//Manual Claim addresses to best prevent chart manipulation.
	address public marketing=payable(0x8CB504069Ec1dBecDc940b43703307cEFf13f8d6);
	address private constantProvider=payable(0x8CB504069Ec1dBecDc940b43703307cEFf13f8d6);
	address private manualClaim=payable(0x8CB504069Ec1dBecDc940b43703307cEFf13f8d6);

	//TestNet
	//address private constant PANCAKE_ROUTER=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
	//MainNet
	//address private constant PANCAKE_ROUTER=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    address private _dividendToken=0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
    
	uint256 private _circulatingSupply = INITIAL_SUPPLY;
	uint256 public  balanceLimit = 5000000* 10**_DECIMALS;
	uint256 public  sellLimit = 1000000* 10**_DECIMALS;
	uint256 private maxBuyAmount = 1000000* 10**_DECIMALS;
	
	//Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
	uint8 private _buyTax;
	uint8 private _sellTax;
	uint8 private _transferTax;

	uint8 private _liquidityTax;
	uint8 private _dividendRate;

	address public _pancakePairAddress;
	IPancakeRouter02 public _pancakeRouter;
	
    /***********************
    * Contract Constructor *
    ************************/
	constructor () {
		uint256 deployerBalance=_circulatingSupply;
		_balances[msg.sender] = deployerBalance;
		emit Transfer(address(0), msg.sender, deployerBalance);
		_pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
		_pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
	}

	/***********************
	* Post Deployment *
	************************/

	function afterDeployment () external onlyOwner{
    	_excluded.add(marketing);
		_excluded.add(constantProvider);
		_excluded.add(manualClaim);
		_excluded.add(msg.sender);
		_excludedFromDividends.add(address(_pancakeRouter));
		_excludedFromDividends.add(_pancakePairAddress);
		_excludedFromDividends.add(address(this));
		_excludedFromDividends.add(0x000000000000000000000000000000000000dEaD);
	}

    /************
    * Transfers *
    *************/
	
	function _transfer(address sender, address recipient, uint256 amount) private{
		require(sender != address(0), "Transfer from zero");
		require(recipient != address(0), "Transfer to zero");
		
		//Manually excluded adresses are transferring tax and lock free
		bool excluded=(_excluded.contains(sender) || _excluded.contains(recipient));
		
		//Transactions from and to the contract are always tax and lock free
		bool isContractTransfer=(sender==address(this) || recipient==address(this));
		
		//transfers between PancakeRouter and PancakePair are tax and lock free
		address pancakeRouter=address(_pancakeRouter);
		bool isLiquidityTransfer=((sender==_pancakePairAddress && recipient==pancakeRouter) || (recipient==_pancakePairAddress && sender==pancakeRouter));
		//differentiate between buy/sell/transfer to apply different taxes/restrictions
		bool isBuy=sender==_pancakePairAddress|| sender==pancakeRouter;
		bool isSell=recipient==_pancakePairAddress|| recipient==pancakeRouter;
		//Pick transfer
		if(isContractTransfer || isLiquidityTransfer || excluded){
			_feelessTransfer(sender, recipient, amount);
		}
		else{ 
			require(tradingEnabled,"Trading not yet enabled");
			_taxedTransfer(sender,recipient,amount,isBuy,isSell);
		}
	}

	function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
		uint8 tax;
		uint8 liquidityTax;
		uint8 dividendRate;
		uint256 recipientBalance = _balances[recipient];
		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "Transfer exceeds balance");
		if(isSell){
            if(!_excludedFromSellLock.contains(sender)){
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                _sellLock[sender]=block.timestamp+sellLockTime;
            }
            //Sells can't exceed the sell limit
            require(amount<=sellLimit,"Dump protection");
            tax=_sellTax;
            liquidityTax=_liquidityTax;
            dividendRate=_dividendRate;
            } else if(isBuy){
                if(!_excludedFromBuyLock.contains(recipient)){
                require(_buyLock[recipient]<=block.timestamp||buyLockDisabled,"Buyer in buyLock");
                _buyLock[recipient]=block.timestamp+buyLockTime;
            }
            require(recipientBalance+amount<=balanceLimit,"MaxBuy protection");
            require(amount<=maxBuyAmount,"TX amount exceeding MaxBuy amount");
            tax=_buyTax;
            liquidityTax=_liquidityTax;
            dividendRate=_dividendRate;
            } else {//Transfer
                if(amount<=10**(_DECIMALS)) claimDividend(sender);
                require(recipientBalance+amount<=balanceLimit,"Max Wallet protection");
                if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
                tax=_transferTax;
                liquidityTax=_liquidityTax;
                dividendRate=_dividendRate;
            }
            //Swapping AutoLP and MarketingBNB is only possible if sender is not pancake pair, 
            //if its not manually disabled, if its not already swapping and if its a Sell to avoid
            // people from causing a large price impact from repeatedly transfering when theres a large backlog of Tokens
            if((sender!=_pancakePairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();
            //Dividend rate and liquidity tax get treated the same, only during conversion they get split
            uint256 contractToken=_calculateFee(amount, tax, dividendRate+liquidityTax);
            //Subtract the Taxed Tokens from the amount
            uint256 taxedAmount=amount-contractToken;
            //Removes token and handles dividends
            _removeToken(sender,amount);
            //Adds the taxed tokens to the contract wallet
            _balances[address(this)] += contractToken;
            //Adds token and handles dividends
            _addToken(recipient, taxedAmount);
            emit Transfer(sender,recipient,taxedAmount);
        }

    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        //Removes token and handles dividends
        _removeToken(sender,amount);
        //Adds token and handles dividends
        _addToken(recipient, amount);
        emit Transfer(sender,recipient,amount);
    }
    
    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
	//BNB Autostake//
	//Autostake uses the balances of each holder to redistribute auto generated BNB.
	//Each transaction _addToken and _removeToken gets called for the transaction amount
	//WithdrawBNB can be used for any holder to withdraw BNB at any time, like true Staking,
	//so unlike MRAT clones you can leave and forget your Token and claim after a while
	//lock for the withdraw
	bool private _isWithdrawing;
    //Dividend Share gets an extra 0.8% during launch/
	uint8 public dividendShare=80;
	//Multiplier to add some accuracy to profitPerShare
	uint256 private constant DISTRIBUTION_MULTIPLIER = 2**64;
	//profit for each share a holder holds, a share equals a token.
	uint256 public profitPerShare;
	//the total reward distributed through dividends, for tracking purposes
	uint256 public totalDividendReward;
	//the total payout through dividends, for tracking purposes
	uint256 public totalPayouts;
 	//balance that is claimable by the team
	uint256 public marketingBalance;
	//Mapping of the already paid out(or missed) shares of each holder
	mapping(address => uint256) private alreadyPaidDividends;
	//Mapping of shares that are reserved for payout
	mapping(address => uint256) private toBePaid;
	//Contract, pancake and burnAddress are excluded, other addresses like CEX
	//can be manually excluded, excluded list is limited to 30 entries to avoid a
	//out of gas exeption during sells
	function isExcludedFromDividends(address addr) public view returns (bool){
		return _excludedFromDividends.contains(addr);
	}
	function isExcluded(address addr) public view returns (bool){
		return _excluded.contains(addr);
	}
	//Total shares equals circulating supply minus excluded balances
	function _getTotalShares() public view returns (uint256){
		uint256 shares=_circulatingSupply;
		//substracts all excluded from shares, excluded list is limited to 30
		// to avoid creating a Honeypot through OutOfGas exeption
		for(uint i=0; i<_excludedFromDividends.length(); i++){
            shares-=_balances[_excludedFromDividends.at(i)];
		}
		return shares;
	}
    //adds Token to balances, adds new BNB to the toBePaid mapping and resets dividends
	function _addToken(address addr, uint256 amount) private {
		//the amount of token after transfer
		uint256 newAmount=_balances[addr]+amount;
		
		if(isExcludedFromDividends(addr)){
            _balances[addr]=newAmount;
            return;
        }
		
		//gets the payout before the change
		uint256 payment=_newDividendsOf(addr);
		//resets dividends to 0 for newAmount
		alreadyPaidDividends[addr] = profitPerShare* newAmount;
		//adds dividends to the toBePaid mapping
		toBePaid[addr]+=payment; 
		//sets newBalance
		_balances[addr]=newAmount;
	}
		
	//removes Token, adds BNB to the toBePaid mapping and resets staking
	function _removeToken(address addr, uint256 amount) private {
		//the amount of token after transfer
		uint256 newAmount=_balances[addr]-amount;
		
		if(isExcludedFromDividends(addr)){
            _balances[addr]=newAmount;
            return;
		}

		//gets the payout before the change
		uint256 payment=_newDividendsOf(addr);
		//sets newBalance
		_balances[addr]=newAmount;
		//resets dividends to 0 for newAmount
		alreadyPaidDividends[addr] = profitPerShare* newAmount;
		//adds dividends to the toBePaid mapping
		toBePaid[addr]+=payment; 
	}

	//gets the not dividends of a holder that aren't in the toBePaid mapping 
	//returns wrong value for excluded accounts
	function _newDividendsOf(address holder) private view returns (uint256) {
		uint256 fullPayout = profitPerShare* _balances[holder];
		// if theres an overflow for some unexpected reason, return 0, instead of 
		// an exeption to still make trades possible
		if(fullPayout<alreadyPaidDividends[holder]) return 0;
		return (fullPayout - alreadyPaidDividends[holder]) / DISTRIBUTION_MULTIPLIER;
	}
	//distributes bnb between marketing share and dividends 
	function _distributeDividends(uint256 bnbAmount) private {
		// Deduct marketing Tax
		uint256 marketingSplit = (bnbAmount* dividendShare) / 100;
		uint256 amount = bnbAmount - marketingSplit;
        marketingBalance+=marketingSplit;
		
		if (amount > 0) {
            totalDividendReward += amount;
            uint256 totalShares=_getTotalShares();
            //when there are 0 shares, add everything to marketing budget
            if (totalShares == 0) {
                marketingBalance += amount;
            }else{
                //Increases profit per share based on current total shares
                profitPerShare += ((amount* DISTRIBUTION_MULTIPLIER) / totalShares);
            }
        }
    }
	
	event OnWithdrawBNB(uint256 amount, address recipient);
	//withdraws all dividends of address
	function claimDividend(address addr) private{
		require(!_isWithdrawing, "Is not withdrawing");
		_isWithdrawing=true;
		uint256 amount;
		if(isExcludedFromDividends(addr)){
		    //if excluded just withdraw remaining toBePaid BNB
		    amount=toBePaid[addr];
		    toBePaid[addr]=0;
		}
		else{
		    uint256 newAmount=_newDividendsOf(addr);
		    //sets payout mapping to current amount
		    alreadyPaidDividends[addr] = profitPerShare* _balances[addr];
		    //the amount to be paid 
		    amount=toBePaid[addr]+newAmount;
		    toBePaid[addr]=0;
		}
		if(amount==0){//no withdraw if 0 amount
		    _isWithdrawing=false;
		    return;
		}
		totalPayouts+=amount;
		address[] memory path = new address[](2);
		path[0] = _pancakeRouter.WETH(); //BNB
		path[1] = _dividendToken;  // Testnet BUSD 
		//path[1] = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;  // SHIBA 
		_pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
		0,
		path,
		addr,
		block.timestamp);
		
		emit OnWithdrawBNB(amount, addr);
		_isWithdrawing=false;
	}
	//Swap Contract Tokens//
	//tracks auto generated BNB, useful for ticker etc
	uint256 public totalLPBNB;
	//Locks the swap if already swapping
	bool private _isSwappingContractModifier;
	modifier lockTheSwap {
		_isSwappingContractModifier = true;
		_;
		_isSwappingContractModifier = false;
	}
	//swaps the token on the contract for Marketing BNB and LP Token.
	//always swaps the sellLimit of token to avoid a large price impact
	function _swapContractToken() private lockTheSwap{
		uint8 liquidityTax;
		uint8 dividendRate;
		uint16 totalTax=liquidityTax+dividendRate;
		uint256 contractBalance=_balances[address(this)];
		uint256 tokenToSwap=sellLimit;
		//only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
		if(contractBalance<tokenToSwap||totalTax==0){
		    return;
		}
		//splits the token in TokenForLiquidity and tokenForMarketing
		uint256 tokenForLiquidity=(tokenToSwap*liquidityTax)/totalTax;
		uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;
        //splits tokenForLiquidity in 2 halves
		uint256 liqToken=tokenForLiquidity/2;
		uint256 liqBNBToken=tokenForLiquidity-liqToken;
        //swaps marktetingToken and the liquidity token half for BNB
		uint256 swapToken=liqBNBToken+tokenForMarketing;
		//Gets the initial BNB balance, so swap won't touch any staked BNB
		uint256 initialBNBBalance = address(this).balance;
		_swapTokenForBNB(swapToken);
		uint256 newBNB=(address(this).balance - initialBNBBalance);
		//calculates the amount of BNB belonging to the LP-Pair and converts them to LP
		uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
		_addLiquidity(liqToken, liqBNB);
		//Get the BNB balance after LP generation to get the
		//exact amount of token left for Staking
		uint256 distributeBNB=(address(this).balance - initialBNBBalance);
		//distributes remaining BNB between stakers and Marketing
		_distributeDividends(distributeBNB);
	}
	//swaps tokens on the contract for BNB
	function _swapTokenForBNB(uint256 amount) private {
		_approve(address(this), address(_pancakeRouter), amount);
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
	}
	//Adds Liquidity directly to the contract where LP are locked
	function _addLiquidity(uint256 tokenamount, uint256 bnbamount) private {
		totalLPBNB+=bnbamount;
		_approve(address(this), address(_pancakeRouter), tokenamount);
		_pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
		);
	}
	//public functions //
	function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
		if(block.timestamp<_liquidityUnlockTime){
		    return _liquidityUnlockTime-block.timestamp;
		}
		return 0;
	}

	function getLimits() public view returns(uint256 balance, uint256 maxBuy, uint256 sell){
		return(balanceLimit/10**_DECIMALS, maxBuyAmount/10**_DECIMALS, sellLimit/10**_DECIMALS);
	}

	function getTaxes() public view returns(uint256 buyTax, uint256 sellTax, uint256 transferTax, uint256 liquidityTax, uint256 dividendRate ){
            return (_buyTax, _sellTax, _transferTax, _liquidityTax, _dividendRate );
	    }

	//How long is a given address still locked from selling
	function getAddressSellLockTimeInSeconds(address addressToCheck) public view returns (uint256){
		uint256 lockTime=_sellLock[addressToCheck];
		if(lockTime<=block.timestamp)
		{
			return 0;
		}
		return lockTime-block.timestamp;
	}
	
	function getSellLockTimeInSeconds() public view returns(uint256){
		return sellLockTime;
	}

	//How long is a given address still locked from buying
	function getAddressBuyLockTimeInSeconds(address addressToCheck) public view returns (uint256){
		uint256 lockTime=_buyLock[addressToCheck];
		if(lockTime<=block.timestamp)
		{
			return 0;
		}
		return lockTime-block.timestamp;
	}
	
	function getBuyLockTimeInSeconds() public view returns(uint256){
		return buyLockTime;
	}
	
	/*******************
    * Public Functions *
    ********************/
	
	//Resets sell lock of caller to the default sellLockTime should something go very wrong
	function addressResetSellLock() public{
		_sellLock[msg.sender]=block.timestamp+sellLockTime;
	}
	//Resets buy lock of caller to the default buyLockTime should something go very wrong
	function addressResetBuyLock() public{
		_buyLock[msg.sender]=block.timestamp+buyLockTime;
	}
	//Withdraws dividends of sender
	function rewards() public {
		claimDividend(msg.sender);
	}
	function getDividends(address addr) public view returns (uint256){
		if(isExcludedFromDividends(addr)) return toBePaid[addr];
		return _newDividendsOf(addr)+toBePaid[addr];
	}

	/***********
    * Settings *
    ************/
	
	bool public sellLockDisabled;
	bool public buyLockDisabled;
	bool public manualConversion;
	uint256 public buyLockTime;
	uint256 public sellLockTime;
	function teamWithdrawALLMarketingBNB() public onlyOwner{
		uint256 amount=marketingBalance;
		marketingBalance=0;
		payable(marketing).transfer((amount*2)/5);
		payable(constantProvider).transfer((amount*1)/5);
		payable(manualClaim).transfer((amount*2)/5);
	} 

	function teamWithdrawXMarketingBNB(uint256 amount) public onlyOwner{
		require(amount<=marketingBalance, "Amount is less than Marketing Wallet Balance");
		marketingBalance-=amount;
		payable(marketing).transfer((amount*2)/5);
		payable(constantProvider).transfer((amount*1)/5);
		payable(manualClaim).transfer((amount*2)/5);
	} 

	//switches autoLiquidity and marketing BNB generation during transfers
	function teamSwitchManualBNBConversion(bool manual) public onlyOwner{
		manualConversion=manual;
	}

	function teamChangeMaxBuy(uint256 newMaxBuy) public onlyOwner{
		require(newMaxBuy<=balanceLimit, "MaxBuy cannot exceed Balance Limit");
		maxBuyAmount=newMaxBuy* 10**_DECIMALS;
	}
	
	function teamChangeMarketing(address newMarketing) public onlyOwner{
		marketing=payable(newMarketing);
	}
	
	function teamChangeConstantProvider(address newConstantProvider) public onlyOwner{
		constantProvider=payable(newConstantProvider);
	}
	
	function teamChangeManualClaim(address newManualClaim) public onlyOwner{
		manualClaim=payable(newManualClaim);
	}

	//Disables the timeLock after selling for everyone
	function teamDisableSellLock(bool disabled) public onlyOwner{
		sellLockDisabled=disabled;
	}

	//Disables the timeLock after buying for everyone
	function teamDisableBuyLock(bool disabled) public onlyOwner{
		buyLockDisabled=disabled;
	}

	//Sets SellLockTime, needs to be lower than MaxSellLockTime
	function teamSetSellLockTime(uint256 sellLockSeconds)external onlyOwner{
        require(sellLockSeconds<=MAX_SELL_LOCK_TIME,"Sell Lock time too high");
        sellLockTime=sellLockSeconds;
	} 

	//Sets BuyLockTime, needs to be lower than MaxBuyLockTime
	function teamSetBuyLockTime(uint256 buyLockSeconds) external onlyOwner{
        require(buyLockSeconds<=MAX_BUY_LOCK_TIME,"Buy Lock time too high");
        buyLockTime=buyLockSeconds;
	} 
	
	//Allows wallet exclusion to be added after launch
	function addWalletExclusion(address exclusionAdd) public onlyOwner{
		_excluded.add(exclusionAdd);
	}
	
	//Sets dividend token
	function teamChangeDividendToken(address newDividendToken) public onlyOwner{
		_dividendToken=(newDividendToken);
	}

	function teamSetTaxes(uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 liquidityTax, uint8 dividendRate) public onlyOwner{
		uint8 totalTax=liquidityTax+dividendRate;
		require(totalTax==100, "liq+marketing needs to equal 100%");
		_buyTax=buyTax;
	    _sellTax=sellTax;
        _transferTax=transferTax;
		_liquidityTax=liquidityTax;
		_dividendRate=dividendRate;
	}
	
	//How much of the dividend rate should be allocated for marketing
	function teamChangeDividendShare(uint8 newShare) public onlyOwner{
		require(newShare<=50, "New Shares are not less than 50%"); 
		dividendShare=newShare;
	}

	//manually converts contract token to LP and distributing BNB
	function teamCreateLPandBNB() public onlyOwner{
		_swapContractToken();
	}

	//Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
	function teamUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyOwner{
		//SellLimit needs to be below 1% to avoid a Large Price impact when generating auto LP
		require(newSellLimit<_circulatingSupply/100, "New sell limit is not less than circulating supply / 100");
		//Adds decimals to limits
		newBalanceLimit=newBalanceLimit*10**_DECIMALS;
		newSellLimit=newSellLimit*10**_DECIMALS;
		//Calculates the target Limits based on supply
		uint256 targetBalanceLimit=_circulatingSupply/BALANCE_LIMIT_DIVIDER;
		uint256 targetSellLimit=_circulatingSupply/SELL_LIMIT_DIVIDER;
		require((newBalanceLimit>=targetBalanceLimit), "newBalanceLimit needs to be at least target");
		require((newSellLimit>=targetSellLimit), "newSellLimit needs to be at least target");
		balanceLimit = newBalanceLimit;
		sellLimit = newSellLimit;     
	}

	bool public tradingEnabled;
	address private _liquidityTokenAddress;
	
	//Enables trading for everyone
	function setupEnableTrading() public onlyOwner{
		tradingEnabled=true;
	}
	
	//Sets up the LP-Token Address required for LP Release
	function setupLiquidityTokenAddress(address liquidityTokenAddress) public onlyOwner{
		_liquidityTokenAddress=liquidityTokenAddress;
	}
	
	//Liquidity Lock//////////////////////
	//the timestamp when Liquidity unlocks
	uint256 private _liquidityUnlockTime;
	
	function teamUnlockLiquidityInSeconds(uint256 secondsUntilUnlock) public onlyOwner{
		_prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
	}
	
	function _prolongLiquidityLock(uint256 newUnlockTime) private{
		// require new unlock time to be longer than old one
		require(newUnlockTime>_liquidityUnlockTime, "New unlock time must be longer than the old one");
		_liquidityUnlockTime=newUnlockTime;
	}
	
	//Release Liquidity Tokens once unlock time is over
	function teamReleaseLiquidity() public payable onlyOwner {
		//Only callable if liquidity Unlock time is over
		require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
		
		IPancakeERC20 liquidityToken = IPancakeERC20(_liquidityTokenAddress);
		uint256 amount = liquidityToken.balanceOf(address(this));
		//Liquidity release if something goes wrong at start
		liquidityToken.transfer(marketing, amount);
	}
	
	//Removes Liquidity once unlock Time is over, 
	function teamRemoveLiquidity(bool addToDividends) public onlyOwner{
		//Only callable if liquidity Unlock time is over
		require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
		_liquidityUnlockTime=block.timestamp+DEFAULT_LIQUIDITY_LOCK_TIME;
		IPancakeERC20 liquidityToken = IPancakeERC20(_liquidityTokenAddress);
		uint256 amount = liquidityToken.balanceOf(address(this));
		liquidityToken.approve(address(_pancakeRouter),amount);
		//Removes Liquidity and either distributes liquidity BNB to stakers, or 
		// adds them to marketing Balance
		//Token will be converted
		//to Liquidity and distrubuting BNB again
		uint256 initialBNBBalance = address(this).balance;
		_pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
		    address(this),
		    amount,
		    0,
		    0,
		    address(this),
		    block.timestamp
		    );
		uint256 newBNBBalance = address(this).balance-initialBNBBalance;
		if(addToDividends){
		    _distributeDividends(newBNBBalance);
		}
		else{
		    marketingBalance+=newBNBBalance;
		}
	  }
	
	//Releases all remaining BNB on the contract wallet, so BNB wont be burned
	function teamRemoveRemainingBNB() public onlyOwner{
		require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
		_liquidityUnlockTime=block.timestamp+DEFAULT_LIQUIDITY_LOCK_TIME;
		(bool sent,) =marketing.call{value: (address(this).balance)}("");
		require(sent, "Was not sent");
	}

    /***********
    * External *
    ************/
	
	receive() external payable {}
	fallback() external payable {}
	
	// IBEP20
	function getOwner() external view override returns (address) {
		return owner();
	}
	
	function name() external pure override returns (string memory) {
		return _NAME;
	}
	
	function symbol() external pure override returns (string memory) {
		return _SYMBOL;
	}
	
	function decimals() external pure override returns (uint8) {
		return _DECIMALS;
	}
	
	function totalSupply() external view override returns (uint256) {
		return _circulatingSupply;
	}
	
	function balanceOf(address account) external view override returns (uint256) {
		return _balances[account];
	}
	
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}
	
	function allowance(address _owner, address spender) external view override returns (uint256) {
		return _allowances[_owner][spender];
	}
	
	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}
	
	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "Approve from zero");
		require(spender != address(0), "Approve to zero");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	
	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		uint256 currentAllowance = _allowances[sender][msg.sender];
		require(currentAllowance >= amount, "Transfer > allowance");
		_approve(sender, msg.sender, currentAllowance - amount);
		return true;
	}
	
	// IBEP20 - Helpers
	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
		return true;
	}
	
	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 currentAllowance = _allowances[msg.sender][spender];
		require(currentAllowance >= subtractedValue, "<0 allowance");
		_approve(msg.sender, spender, currentAllowance - subtractedValue);
		return true;
	}
}