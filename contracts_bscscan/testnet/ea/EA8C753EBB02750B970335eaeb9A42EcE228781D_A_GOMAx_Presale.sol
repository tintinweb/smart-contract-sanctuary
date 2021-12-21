/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

/** 
                                                         
    (                       (                (        
    )\   (         (  (     )\ )          )  )\   (   
  (((_)  )(    (   )\))(   (()/(   (   ( /( ((_) ))\  
  )\___ (()\   )\ ((_)()\   ((_))  )\  )(_)) _  /((_) 
 ((/ __| ((_) ((_)_(()((_)  _| |  ((_)((_)_ | |(_))   
  | (__ | '_|/ _ \\ V  V // _` |  (_-</ _` || |/ -_)  
   \___||_|  \___/ \_/\_/ \__,_|  /__/\__,_||_|\___|  



            *******************************
                  GOMAx Crowdsale v2                        
     
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// ------------------------------------- Address -------------------------------------------
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner; 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        //_setOwner(_msgSender());
        _setOwner(0x1d3354FB678086Aa367FBb2BD30c05FADf558c9c); // set on deploy
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
	//function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(uint256 amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ------------------------------------- SafeERC20 -------------------------------------------
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

contract A_GOMAx_Presale is Ownable {
	using SafeERC20 for IERC20;
    IERC20 public immutable token;
	IERC20 public immutable gomaToken;
    address payable public wallet;  

    struct Round {
        uint256 amount; // Round amount of WEI of TOKEN    
        uint256 rate; // WEI of TOKEN per 1 WEI of BNB
    }
    uint256 public rateMultiplier;
    Round[] public rounds;
    uint256 public currentRound;

    struct UserInfo {
        uint256 bnbSpent; 
        uint256 tokensPurchased; 
    }
    mapping (address => UserInfo) public users;

    bool public whiteListSell = false;
	mapping (address => bool) public whiteList;
	
	uint256 public startTime;
    uint256 public minBuyValue;
    uint256 public maxBuyValue;
    uint256 public totalTokensPurchased;
    uint256 public totalBNBCollected;

    bool public paused = false;

	uint256 public minGOMAHold;
        
    event Buy(address indexed user, uint256 amount, uint256 value);    
	
    constructor() {
        token = IERC20(0x66795834A08f69EB455A332A4DF48c13e5F509F2); // GOMAx
		gomaToken = IERC20(0x7Dd8c66FB5b301F34f948188Cce0a9b8cDF29b0B); // GOMA
        wallet = payable(0xf7a6799E164685Ef752e7121eC6CBf47D6B67dD5);
        minBuyValue = 100000000000000000; // 0,1 BNB
        maxBuyValue = 5000000000000000000; // 5 BNB        
        rateMultiplier = 1; 
		// price 0,001 bnb per one GOMAx token  
		// 1000000000000000000 / 10 * 10000     
		rounds.push(Round({
			amount: 200000 * 1e18,
			rate: 1000
		}));
		rounds.push(Round({
			amount: 333333 * 1e18,
			rate: 1200
		}));
		rounds.push(Round({
			amount: 460000 * 1e18,
			rate: 1300
		}));
		rounds.push(Round({
			amount: 715000 * 1e18,
			rate: 1400
		}));
		startTime = blockTimestamp();
		// owner already set in Owanble constructor !

		minGOMAHold = 2200000000 * 1e9; // 2,2 BN GOMA (9 decimals)
        // 10000000000000000000
        // 2200000000000000000

    }

    // 
    function reset() external onlyOwner {			
		currentRound = 0;
        totalTokensPurchased = 0;
        totalBNBCollected = 0;
        startTime = 0;
        whiteListSell = false;
        paused = false;
        delete rounds;
    }
    
    // 
    function buyCalculate(uint256 _value) public view returns (uint256 purchaseAmount, uint256 roundResult) {
		roundResult = currentRound;
		for (uint256 i = currentRound; i < rounds.length; i ++) {
            if (_value != 0) {
                Round memory round = rounds[i]; 
                uint256 curentRoundBuyAmount = _value * round.rate / rateMultiplier;
                if (totalTokensPurchased + purchaseAmount + curentRoundBuyAmount > round.amount) {
                    if (i < rounds.length - 1) {                        
                        uint256 leftInRoundAmount = round.amount - totalTokensPurchased - purchaseAmount;
                        purchaseAmount = purchaseAmount + leftInRoundAmount;
                        if (leftInRoundAmount * rateMultiplier <= round.rate) {
                            _value = _value - 1;
                        } else {                            
                            _value = _value - (leftInRoundAmount * rateMultiplier / round.rate);
                        }                        
                        roundResult = i + 1;
                    } else {
                        purchaseAmount = purchaseAmount + curentRoundBuyAmount;
                        _value = 0;
                    }
                } else if (totalTokensPurchased + purchaseAmount + curentRoundBuyAmount == round.amount) {
                    purchaseAmount = purchaseAmount + curentRoundBuyAmount;
                    if (i < rounds.length - 1) {
                        roundResult = i + 1;
                    }
                    _value = 0;
                } else {
                    purchaseAmount = purchaseAmount + curentRoundBuyAmount;
                    _value = 0;
                }
            } else {
                break;
            }						
		}
		return (purchaseAmount, roundResult);
    }
	
	// 
    function buyTokens() public payable {
        require(!paused, "GOMAx-Presale buyTokens: sale paused!");	
        require(isStarted(), "GOMAx-Presale buyTokens: sale not started!");
                
        if (whiteListSell) {
			require(whiteList[msg.sender], "GOMAx-Presale buyTokens: buy allowed only for whitelisted addresses!");
		} 

		uint256 gomaUserBalance = gomaToken.balanceOf(msg.sender);
		require(gomaUserBalance >= minGOMAHold, "GOMAx-Presale buyTokens: you must hold minimum GOMA tokens to participate in presale!");
		
        require(msg.value >= minBuyValue, "GOMAx-Presale buyTokens: you can't buy for less than min buy value!");
                
        UserInfo storage user = users[msg.sender];

        require(user.bnbSpent + msg.value <= maxBuyValue, "GOMAx-Presale buyTokens: you can't buy for more than max buy value!");

		(uint256 purchaseAmount, uint256 roundResult) = buyCalculate(msg.value);
				
		try token.mint(purchaseAmount) {} catch {
            require(false, "GOMAx-Presale token.mint!");
        }
		// transfer TOKENS to recipient
        
		try token.transfer(msg.sender, purchaseAmount) {} catch {
            require(false, "GOMAx-Presale token.transfer!");
        }
		totalTokensPurchased = totalTokensPurchased + purchaseAmount;
		
        // update current round
		currentRound = roundResult;
         
        user.bnbSpent = user.bnbSpent + msg.value;
        user.tokensPurchased = user.tokensPurchased + purchaseAmount;
        
		// transfer BNB to wallet
		wallet.transfer(msg.value);
        totalBNBCollected = totalBNBCollected + msg.value;
		// emit event
		emit Buy(msg.sender, purchaseAmount, msg.value);
    }

    // 
    function togglePause() external onlyOwner {			
		paused = !paused;
    }

	// 
    function toggleWhiteListSell() external onlyOwner {			
		whiteListSell = !whiteListSell;
    }

	// 
    function setMinGomaHold(uint256 _minGOMAHold) external onlyOwner {
		minGOMAHold = _minGOMAHold;
    }
    
    // 
    function setRateMultiplier(uint256 _rateMultiplier) external onlyOwner {
		rateMultiplier = _rateMultiplier;
    }

	// 
    function setRound(uint256 _index, uint256 _amount, uint256 _rate) external onlyOwner {
        require(rounds.length > 0 && _index < rounds.length - 1, "GOMAx-Presale setRound: no round with such index!");
        
        if (isStarted()) {
            require(_index > currentRound, "GOMAx-Presale setRound: you can't change started rounds!");
        }
		
		require(_amount > totalTokensPurchased, "GOMAx-Presale setRound: amount must be grater than total purchased amount!");
		require(_amount != 0, "GOMAx-Presale setRound: amount can't be 0!");
		
		if (rounds.length - 1 > _index) {
			require(_amount < rounds[_index + 1].amount, "GOMAx-Presale setRound: amount must be lower than next round amount!");
		}

        if (_index > 0) {
            Round storage prevRound = rounds[_index - 1];            
            require((_amount * rateMultiplier) > ((prevRound.amount * rateMultiplier) + prevRound.rate), "GOMAx-Presale setRound: amount must be grater than previous round amount + previous round rate!");
        }		
		
		require(_rate > 0, "GOMAx-Presale setRound: rate can't be 0!");
		
		Round storage round = rounds[_index]; 
		round.amount = _amount;
		round.rate = _rate;	     
    }
	
	// 
    function addRound(uint256 _amount, uint256 _rate) external onlyOwner {
		require(_amount > totalTokensPurchased, "GOMAx-Presale addRound: amount must be grater than total purchased amount!");
		require(_rate > 0, "GOMAx-Presale addRound: rate can't be 0!");
        
        if (rounds.length > 0) {
            Round storage lastRound = rounds[rounds.length - 1];            
            require((_amount * rateMultiplier) > ((lastRound.amount * rateMultiplier) + lastRound.rate), "GOMAx-Presale addRound: amount must be grater than last round amount + last round rate!");
            
            if (totalTokensPurchased > lastRound.amount) {
                currentRound = currentRound + 1;
            }
        }
        		
		rounds.push(Round({
			amount: _amount,
			rate: _rate 
		}));       
    }
    
    // 
    function getRound()  public view returns (uint256 index, uint256 amount, uint256 rate, uint256 previousRoundAmount, bool isLastRound, uint256 roundRateMultiplier) {
        require(rounds.length > 0, "GOMAx-Presale getRound: no rounds added!");
        
		index = currentRound;
		Round storage round = rounds[index]; 
		amount = round.amount;
		rate = round.rate;
		roundRateMultiplier = rateMultiplier;
		
		if (currentRound != 0) previousRoundAmount = rounds[currentRound - 1].amount;
		isLastRound = false;
		if (currentRound == rounds.length - 1) isLastRound = true;
		
		return (index, amount, rate, previousRoundAmount, isLastRound, roundRateMultiplier);   
    }

    // 
    function addWhiteListUsers(address[] memory _addresses) external onlyOwner {
		for (uint256 i = 0; i < _addresses.length; i ++) {
			whiteList[_addresses[i]] = true;		
        }       
    }

    // 
    function removeWhiteListUsers(address[] memory _addresses) external onlyOwner {
		for (uint256 i = 0; i < _addresses.length; i ++) {
			whiteList[_addresses[i]] = false;		
        }       
    }

	// 
    function setMinBuyValue(uint256 _minBuyValue) external onlyOwner {
		require(_minBuyValue > 0, "GOMAx-Presale setMinBuyValue: you can't set 0!");
        require(_minBuyValue <= maxBuyValue, "GOMAx-Presale setMinBuyValue: you can't set more than max buy value!");
		minBuyValue = _minBuyValue;		     
    }

    // 
    function setMaxBuyValue(uint256 _maxBuyValue) external onlyOwner {
		require(_maxBuyValue > 0, "GOMAx-Presale setMaxBuyValue: you can't set 0!");
        require(_maxBuyValue >= minBuyValue, "GOMAx-Presale setMaxBuyValue: you can't less than min buy value!");
		maxBuyValue = _maxBuyValue;		     
    }

	// 
    function setStartTime(uint256 _startTimestamp) external onlyOwner {
		require(totalTokensPurchased == 0, "GOMAx-Presale setStartTime: you can start only at 0 purchsed, or reset it first!");
        require(_startTimestamp >= blockTimestamp(), "GOMAx-Presale setStartTime: start time can't be in past!");
        require(rounds.length > 0, "GOMAx-Presale setStartTime: at least one round should be added!");
		startTime = _startTimestamp;		      
    }

    // 
    function startNow() external onlyOwner {
		require(totalTokensPurchased == 0, "GOMAx-Presale startNow: you can start only at 0 purchsed, or reset it first!");
        require(rounds.length > 0, "GOMAx-Presale startNow: at least one round should be added!");
        startTime = blockTimestamp();		      
    }
    
    // 
    function isStarted() public view returns (bool) {
		return startTime != 0 && startTime <= blockTimestamp();
    }

	// 
    function setWallet(address payable _wallet) external onlyOwner {
        require(_wallet != address(0), "GOMAx-Presale setWallet: wrong wallet address!");
		wallet = _wallet;		     
    }
            
    // 
    function withdrawAllTokens(address _recipient) external onlyOwner {
        require(balanceOfToken() != 0, "GOMAsterChef withdrawAllTokens: nothing to withdraw");
        token.transfer(_recipient, balanceOfToken());        
    }
    
    // 
    function balanceOfToken() public view returns (uint256) {
		return token.balanceOf(address(this));
    }
        
    //
    function blockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
     
}