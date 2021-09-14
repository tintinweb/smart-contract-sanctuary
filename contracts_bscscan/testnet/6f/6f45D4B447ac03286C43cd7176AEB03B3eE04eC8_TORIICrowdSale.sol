/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/** 
        ___________________ __________.___.___ 
        \__    ___/\_____  \\______   \   |   |
        |    |    /   |   \|       _/   |   |
        |    |   /    |    \    |   \   |   |
        |____|   \_______  /____|_  /___|___|
                        \/       \/         

                                                     
    (                       (                (        
    )\   (         (  (     )\ )          )  )\   (   
  (((_)  )(    (   )\))(   (()/(   (   ( /( ((_) ))\  
  )\___ (()\   )\ ((_)()\   ((_))  )\  )(_)) _  /((_) 
 ((/ __| ((_) ((_)_(()((_)  _| |  ((_)((_)_ | |(_))   
  | (__ | '_|/ _ \\ V  V // _` |  (_-</ _` || |/ -_)  
   \___||_|  \___/ \_/\_/ \__,_|  /__/\__,_||_|\___|  



            *******************************
                   TORII Crowdsale
           
              Written by:  Chvankov Roman
               Telegram: @Chvankov_Roman 
               
               Use it at your own risk !   
     
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
        _setOwner(_msgSender());
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

contract TORIICrowdSale is Ownable {
    IBEP20 public immutable token;
    address payable public wallet;  

    struct Round {
        uint256 amount; // Round amount of WEI of TOKEN    
        uint256 rate; // WEI of TOKEN per 1 WEI of BNB
    }
    Round[] public rounds;
    uint256 public currentRound = 0;

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
        
    event Buy(address indexed user, uint256 amount, uint256 value);    
	
    constructor() {
        token = IBEP20(0x5e330cEBB06F0cAfA91cdF506Cd6A5ae6E4A420E); // TORII
        wallet = payable(0xf7a6799E164685Ef752e7121eC6CBf47D6B67dD5);
        minBuyValue = 10000000000000; // 10000000000000 = 0,001 BNB
        maxBuyValue = 5000000000000000000; // 5000000000000000000 = 5 BNB
        
        // 0 -> 100 -> 200 -> 300
		rounds.push(Round({
			amount: 600 * 10**18, // 6000000000000000000000 
			rate: 3000
		}));   
		rounds.push(Round({
			amount: 1200 * 10**18,
			rate: 2000
		})); 
		rounds.push(Round({
			amount: 3000 * 10**18,
			rate: 1000
		}));   
		
		startTime = blockTimestamp();
    }
    
    // 
    function buyCalculate(uint256 _value) public view returns (uint256 purchaseAmount, uint256 roundResult) {
		uint256 _totalTokensPurchased = totalTokensPurchased;
		roundResult = currentRound;
		for (uint256 i = currentRound; i < rounds.length; i ++) {
            if (_value != 0) {
                Round storage round = rounds[i]; 
                uint256 curentRoundBuyAmount = _value * round.rate;
                if (_totalTokensPurchased + curentRoundBuyAmount > round.amount) {
                    if (i < rounds.length - 1) {
                        uint256 leftInRoundAmount = round.amount - _totalTokensPurchased;
                        purchaseAmount = purchaseAmount + leftInRoundAmount;
                        if (leftInRoundAmount <= round.rate) {
                            _value = _value - 1;
                        } else {
                            _value = _value - (leftInRoundAmount / round.rate);
                        }
                        roundResult = i + 1;
                    } else {
                        purchaseAmount = purchaseAmount + curentRoundBuyAmount;
                        _value = 0;
                    }
                } else if (_totalTokensPurchased + curentRoundBuyAmount == round.amount) {
                    purchaseAmount = purchaseAmount + curentRoundBuyAmount;
                    if (i < rounds.length - 1) {
                        roundResult = i + 1;
                    }
                    _value = 0;
                } else {
                    purchaseAmount = purchaseAmount + curentRoundBuyAmount;
                    _value = 0;
                }
                _totalTokensPurchased = _totalTokensPurchased + purchaseAmount;
            } else {
                break;
            }						
		}
		return (purchaseAmount, roundResult);
    }
	
	// 
    function buyTokens() public payable {
        require(!paused, "TORII-CrowdSale buyTokens: sale paused!");	
        require(isStarted(), "TORII-CrowdSale buyTokens: sale not started!");
                
        if (whiteListSell) {
			require(whiteList[msg.sender], "TORII-CrowdSale buyCalculate: buy allowed only for whitelisted addresses!");
		} 
		
        require(msg.value >= minBuyValue, "TORII-CrowdSale buyCalculate: you can't buy for less than min buy value!");
                
        UserInfo storage user = users[msg.sender];

        require(user.bnbSpent + msg.value <= maxBuyValue, "TORII-CrowdSale buyCalculate: you can't buy for more than max buy value!");

		(uint256 purchaseAmount, uint256 roundResult) = buyCalculate(msg.value);
		
		require(purchaseAmount <= balanceOfToken(), "TORII-CrowdSale buyTokens: not enough tokens in contract for sell");		
		// transfer TOKENS to recipient
		token.transfer(msg.sender, purchaseAmount);
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
    function setRound(uint256 _index, uint256 _amount, uint256 _rate) external onlyOwner {
        require(_index > currentRound, "TORII-CrowdSale setRound: you can't change started rounds!");
		require(rounds.length > 0 && _index < rounds.length - 1, "TORII-CrowdSale setRound: no round with such index!");
		require(_amount >= totalTokensPurchased, "TORII-CrowdSale setRound: amount must be grater than total purchased amount!");
		require(_amount != 0, "TORII-CrowdSale setRound: amount can't be 0!");
		
		if (rounds.length - 1 > _index) {
			require(_amount < rounds[_index + 1].amount, "TORII-CrowdSale setRound: amount must be lower than next round amount!");
		} 		
		
		require(_rate > 0, "TORII-CrowdSale setRound: rate can't be 0!");
		
		Round storage round = rounds[_index]; 
		round.amount = _amount;
		round.rate = _rate;	     
    }
	
	// 
    function addRound(uint256 _amount, uint256 _rate) external onlyOwner {
		require(_amount >= totalTokensPurchased, "TORII-CrowdSale addRound: amount must be grater than total purchased amount!");
		require(_rate > 0, "TORII-CrowdSale addRound: rate can't be 0!");
		
		rounds.push(Round({
			amount: _amount,
			rate: _rate 
		}));       
    }
    
    // 
    function getRound()  public view returns (uint256 index, uint256 amount, uint256 rate, uint256 previousRoundAmount, bool isLastRound) {
		index = currentRound;
		Round storage round = rounds[index]; 
		amount = round.amount;
		rate = round.rate;
		if (currentRound != 0) previousRoundAmount = rounds[currentRound - 1].amount;
		isLastRound = false;
		if (currentRound == rounds.length - 1) isLastRound = true;
		
		return (index, amount, rate, previousRoundAmount, isLastRound);   
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
		require(_minBuyValue > 0, "TORII-CrowdSale setMinBuyValue: you can't set 0!");
        require(_minBuyValue <= maxBuyValue, "TORII-CrowdSale setMinBuyValue: you can't set more than max buy value!");
		minBuyValue = _minBuyValue;		     
    }

    // 
    function setMaxBuyValue(uint256 _maxBuyValue) external onlyOwner {
		require(_maxBuyValue > 0, "TORII-CrowdSale setMaxBuyValue: you can't set 0!");
        require(_maxBuyValue >= minBuyValue, "TORII-CrowdSale setMaxBuyValue: you can't less than min buy value!");
		maxBuyValue = _maxBuyValue;		     
    }

	// 
    function setStartTime(uint256 _startTimestamp) external onlyOwner {
		require(startTime == 0, "TORII-CrowdSale setStartTime: start time already set!");
        require(_startTimestamp >= blockTimestamp(), "TORII-CrowdSale setStartTime: start time can't be in past!");
		startTime = _startTimestamp;		      
    }

    // 
    function startNow() external onlyOwner {
		require(startTime == 0, "TORII-CrowdSale startNow: start time already set!");
        startTime = blockTimestamp();		      
    }
    
    // 
    function isStarted() public view returns (bool) {
		return startTime != 0 && startTime <= blockTimestamp();
    }

	// 
    function setWallet(address payable _wallet) external onlyOwner {
        require(_wallet != address(0), "TORII-CrowdSale buyTokens: wrong wallet address!");
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