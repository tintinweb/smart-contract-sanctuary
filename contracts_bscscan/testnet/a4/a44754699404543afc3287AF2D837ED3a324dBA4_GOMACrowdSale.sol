/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/** 

        /$$$$$$   /$$$$$$  /$$      /$$  /$$$$$$      
       /$$__  $$ /$$__  $$| $$$    /$$$ /$$__  $$     
      | $$  \__/| $$  \ $$| $$$$  /$$$$| $$  \ $$     
      | $$ /$$$$| $$  | $$| $$ $$/$$ $$| $$$$$$$$     
      | $$|_  $$| $$  | $$| $$  $$$| $$| $$__  $$     
      | $$  \ $$| $$  | $$| $$\  $ | $$| $$  | $$     
      |  $$$$$$/|  $$$$$$/| $$ \/  | $$| $$  | $$     
       \______/  \______/ |__/     |__/|__/  |__/     
                                                      
                                                      
                                                      
  /$$$$$$                                          /$$
 /$$__  $$                                        | $$
| $$  \__/  /$$$$$$   /$$$$$$  /$$  /$$  /$$  /$$$$$$$
| $$       /$$__  $$ /$$__  $$| $$ | $$ | $$ /$$__  $$
| $$      | $$  \__/| $$  \ $$| $$ | $$ | $$| $$  | $$
| $$    $$| $$      | $$  | $$| $$ | $$ | $$| $$  | $$
|  $$$$$$/| $$      |  $$$$$$/|  $$$$$/$$$$/|  $$$$$$$
 \______/ |__/       \______/  \_____/\___/  \_______/
                                                      
                                                      
                                                      
            /$$$$$$            /$$                  
           /$$__  $$          | $$                  
          | $$  \__/  /$$$$$$ | $$  /$$$$$$         
          |  $$$$$$  |____  $$| $$ /$$__  $$        
           \____  $$  /$$$$$$$| $$| $$$$$$$$        
           /$$  \ $$ /$$__  $$| $$| $$_____/        
          |  $$$$$$/|  $$$$$$$| $$|  $$$$$$$        
           \______/  \_______/|__/ \_______/ 



            *******************************

           
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

contract GOMACrowdSale is Ownable {
    IBEP20 public immutable token;
    address payable public wallet;  

    struct Tier {
        uint256 amount; // Tier amount of WEI of TOKEN    
        uint256 rate; // WEI of TOKEN per 1 WEI of BNB
    }
    Tier[] public tiers;
    uint256 public currentTier = 0;

    bool public whiteListSell = false;
	mapping (address => bool) public whiteList;
	
	uint256 public startTime;
    uint256 public minBuyValue;
    uint256 public totalBuyAmount;
        
    event Buy(address indexed purchaser, address indexed user, uint256 amount, uint256 value);    
	
    constructor() {
        token = IBEP20(0x246BbEC0Fd4c32DA3dC0B0483Ec94104c48B625e); // TORII
        wallet = payable(0xf7a6799E164685Ef752e7121eC6CBf47D6B67dD5);
        minBuyValue = 10000000000000; // 10000000000000 = 0,001 BNB
        
        // 0 -> 100 -> 200 -> 300
		tiers.push(Tier({
			amount: 100 * 10**18, 
			rate: 10
		}));   
		tiers.push(Tier({
			amount: 200 * 10**18,
			rate: 20
		})); 
		tiers.push(Tier({
			amount: 300 * 10**18,
			rate: 30 
		}));    
    }
	
	// 
    function buyTokens(address _recipient) public payable {			
		require(startTime != 0 && startTime <= blockTimestamp(), "GOMACrowdSale buyTokens: sale not started!");
		require(_recipient != address(0), "GOMACrowdSale buyTokens: wrong recipient address!");
		if (whiteListSell) {
			require(whiteList[_recipient], "GOMACrowdSale buyTokens: buy allowed only for whitelisted addresses!");
		} 
		require(msg.value >= minBuyValue, "GOMACrowdSale buyTokens: you can't buy for less than min buy value!");
		
		// 150
		uint256 msgValue = msg.value;
		// 0
		uint256 buyAmount;

		for (uint256 i = currentTier; i < tiers.length; i ++) {
            if (msgValue != 0) {
                Tier storage tier = tiers[i]; 
                // 0 : 150 * 10 = 1500
                // 1 : 50 * 20 = 1000
                uint256 cuurentTierBuyAmount = msgValue * tier.rate;
                // 0 : 0 + 1500 > 1000 = true
                // 1 : 1000 + 1000 > 2000 = false
                if (totalBuyAmount + cuurentTierBuyAmount > tier.amount) {
                    // 0 : 1000 - 0 = 1000
                    uint256 leftInTierAmount = tier.amount - totalBuyAmount;
                    // 0 : 0 + 1000 = 1000
                    buyAmount = buyAmount + leftInTierAmount * tier.rate;
                    // 0 : 150 - (1000 / 10) = 50
                    msgValue = msgValue - (buyAmount / tier.rate);
                    // update current tier index
                    currentTier = i;
                } else {
                    // 1 : 1000 + 1000 = 2000
                    buyAmount = cuurentTierBuyAmount;
                    msgValue = 0;
                }
                totalBuyAmount = totalBuyAmount + buyAmount;
            }						
		}

		require(buyAmount <= balanceOfToken(), "GOMAsterChef buyTokens: not enough tokens in contract for sell");		
		// transfer TOKENS to recipient
		token.transfer(_recipient, buyAmount);
		// transfer BNB to wallet
		wallet.transfer(msg.value);
		// emit event
		emit Buy(msg.sender, _recipient, buyAmount, msg.value);
    }

	// 
    function toggleWhiteListSell() external onlyOwner {			
		whiteListSell = !whiteListSell;
    }

	// 
    function setTier(uint256 _index, uint256 _amount, uint256 _rate) external onlyOwner {
		require(tiers.length > 0 && _index < tiers.length - 1, "GOMACrowdSale setTier: no tier with such index!");
		require(_amount >= totalBuyAmount, "GOMACrowdSale setTier: amount must be grater than total purchased amount!");
		require(_amount != 0, "GOMACrowdSale setTier: amount can't be 0!");
		
		if (tiers.length - 1 > _index) {
			require(_amount < tiers[_index + 1].amount, "GOMACrowdSale setTier: amount must be lower than next tier amount!");
		} 		
		
		require(_rate > 0, "GOMACrowdSale setTier: rate can't be 0!");
		
		Tier storage tier = tiers[_index]; 
		tier.amount = _amount;
		tier.rate = _rate;	     
    }
	// 
    function addTier(uint256 _amount, uint256 _rate) external onlyOwner {
		require(_amount >= totalBuyAmount, "GOMACrowdSale addTier: amount must be grater than total purchased amount!");
		require(_rate > 0, "GOMACrowdSale addTier: rate can't be 0!");
		
		tiers.push(Tier({
			amount: _amount,
			rate: _rate 
		}));       
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
		require(_minBuyValue > 0, "GOMACrowdSale setMinBuyValue: you can't set 0!");
		minBuyValue = _minBuyValue;		     
    }

	// 
    function setStartTime(uint256 _startTimestamp) external onlyOwner {
		require(startTime == 0, "GOMACrowdSale setStartTime: start time already set!");
        require(_startTimestamp >= blockTimestamp(), "GOMACrowdSale setStartTime: start time can't be in past!");
		startTime = _startTimestamp;		      
    }

    // 
    function startNow() external onlyOwner {
		require(startTime == 0, "GOMACrowdSale startNow: start time already set!");
        startTime = blockTimestamp();		      
    }

	// 
    function setWallet(address payable _wallet) external onlyOwner {
        require(_wallet != address(0), "GOMACrowdSale buyTokens: wrong wallet address!");
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