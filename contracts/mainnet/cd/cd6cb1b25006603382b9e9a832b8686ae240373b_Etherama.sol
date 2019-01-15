pragma solidity ^0.4.25;

contract IStdToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
}

contract EtheramaCommon {
    
    //main adrministrators of the Etherama network
    mapping(address => bool) private _administrators;

    //main managers of the Etherama network
    mapping(address => bool) private _managers;

    
    modifier onlyAdministrator() {
        require(_administrators[msg.sender]);
        _;
    }

    modifier onlyAdministratorOrManager() {
        require(_administrators[msg.sender] || _managers[msg.sender]);
        _;
    }
    
    constructor() public {
        _administrators[msg.sender] = true;
    }
    
    
    function addAdministator(address addr) onlyAdministrator public {
        _administrators[addr] = true;
    }

    function removeAdministator(address addr) onlyAdministrator public {
        _administrators[addr] = false;
    }

    function isAdministrator(address addr) public view returns (bool) {
        return _administrators[addr];
    }

    function addManager(address addr) onlyAdministrator public {
        _managers[addr] = true;
    }

    function removeManager(address addr) onlyAdministrator public {
        _managers[addr] = false;
    }
    
    function isManager(address addr) public view returns (bool) {
        return _managers[addr];
    }
}


contract EtheramaGasPriceLimit is EtheramaCommon {
    
    uint256 public MAX_GAS_PRICE = 0 wei;
    
    event onSetMaxGasPrice(uint256 val);    
    
    //max gas price modifier for buy/sell transactions in order to avoid a "front runner" vulnerability.
    //It is applied to all network contracts
    modifier validGasPrice(uint256 val) {
        require(val > 0);
        _;
    }
    
    constructor(uint256 maxGasPrice) public validGasPrice(maxGasPrice) {
        setMaxGasPrice(maxGasPrice);
    } 
    
    
    //only main administators or managers can set max gas price
    function setMaxGasPrice(uint256 val) public validGasPrice(val) onlyAdministratorOrManager {
        MAX_GAS_PRICE = val;
        
        emit onSetMaxGasPrice(val);
    }
}

// Core contract for Etherama network
contract EtheramaCore is EtheramaGasPriceLimit {
    
    uint256 constant public MAGNITUDE = 2**64;

    // Max and min amount of tokens which can be bought or sold. There are such limits because of math precision
    uint256 constant public MIN_TOKEN_DEAL_VAL = 0.1 ether;
    uint256 constant public MAX_TOKEN_DEAL_VAL = 1000000 ether;

    // same same for ETH
    uint256 constant public MIN_ETH_DEAL_VAL = 0.001 ether;
    uint256 constant public MAX_ETH_DEAL_VAL = 200000 ether;
    
    // percent of a transaction commission which is taken for Big Promo bonus
    uint256 public _bigPromoPercent = 5 ether;

    // percent of a transaction commission which is taken for Quick Promo bonus
    uint256 public _quickPromoPercent = 5 ether;

    // percent of a transaction commission which is taken for Etherama DEV team
    uint256 public _devRewardPercent = 15 ether;
    
    // percent of a transaction commission which is taken for Token Owner. 
    uint256 public _tokenOwnerRewardPercent = 30 ether;

    // percent of a transaction commission which is taken for share reward. Each token holder receives a small reward from each buy or sell transaction proportionally his holding. 
    uint256 public _shareRewardPercent = 25 ether;

    // percent of a transaction commission which is taken for a feraral link owner. If there is no any referal then this part of commission goes to share reward.
    uint256 public _refBonusPercent = 20 ether;

    // interval of blocks for Big Promo bonus. It means that a user which buy a bunch of tokens for X ETH in that particular block will receive a special bonus 
    uint128 public _bigPromoBlockInterval = 9999;

    // same same for Quick Promo
    uint128 public _quickPromoBlockInterval = 100;
    
    // minimum eth amount of a purchase which is required to participate in promo.
    uint256 public _promoMinPurchaseEth = 1 ether;
    
    // minimum eth purchase which is required to get a referal link.
    uint256 public _minRefEthPurchase = 0.5 ether;

    // percent of fee which is supposed to distribute.
    uint256 public _totalIncomeFeePercent = 100 ether;

    // current collected big promo bonus
    uint256 public _currentBigPromoBonus;
    // current collected quick promo bonus
    uint256 public _currentQuickPromoBonus;
    
    uint256 public _devReward;

    
    uint256 public _initBlockNum;

    mapping(address => bool) private _controllerContracts;
    mapping(uint256 => address) private _controllerIndexer;
    uint256 private _controllerContractCount;
    
    //user token balances per data contracts
    mapping(address => mapping(address => uint256)) private _userTokenLocalBalances;
    //user reward payouts per data contracts
    mapping(address => mapping(address => uint256)) private _rewardPayouts;
    //user ref rewards per data contracts
    mapping(address => mapping(address => uint256)) private _refBalances;
    //user won quick promo bonuses per data contracts
    mapping(address => mapping(address => uint256)) private _promoQuickBonuses;
    //user won big promo bonuses per data contracts
    mapping(address => mapping(address => uint256)) private _promoBigBonuses;  
    //user saldo between buys and sels in eth per data contracts
    mapping(address => mapping(address => uint256)) private _userEthVolumeSaldos;  

    //bonuses per share per data contracts
    mapping(address => uint256) private _bonusesPerShare;
    //buy counts per data contracts
    mapping(address => uint256) private _buyCounts;
    //sell counts per data contracts
    mapping(address => uint256) private _sellCounts;
    //total volume eth per data contracts
    mapping(address => uint256) private _totalVolumeEth;
    //total volume tokens per data contracts
    mapping(address => uint256) private _totalVolumeToken;

    
    event onWithdrawUserBonus(address indexed userAddress, uint256 ethWithdrawn); 


    modifier onlyController() {
        require(_controllerContracts[msg.sender]);
        _;
    }
    
    constructor(uint256 maxGasPrice) EtheramaGasPriceLimit(maxGasPrice) public { 
         _initBlockNum = block.number;
    }
    
    function getInitBlockNum() public view returns (uint256) {
        return _initBlockNum;
    }
    
    function addControllerContract(address addr) onlyAdministrator public {
        _controllerContracts[addr] = true;
        _controllerIndexer[_controllerContractCount] = addr;
        _controllerContractCount = SafeMath.add(_controllerContractCount, 1);
    }

    function removeControllerContract(address addr) onlyAdministrator public {
        _controllerContracts[addr] = false;
    }
    
    function changeControllerContract(address oldAddr, address newAddress) onlyAdministrator public {
         _controllerContracts[oldAddr] = false;
         _controllerContracts[newAddress] = true;
    }
    
    function setBigPromoInterval(uint128 val) onlyAdministrator public {
        _bigPromoBlockInterval = val;
    }

    function setQuickPromoInterval(uint128 val) onlyAdministrator public {
        _quickPromoBlockInterval = val;
    }
    
    function addBigPromoBonus() onlyController payable public {
        _currentBigPromoBonus = SafeMath.add(_currentBigPromoBonus, msg.value);
    }
    
    function addQuickPromoBonus() onlyController payable public {
        _currentQuickPromoBonus = SafeMath.add(_currentQuickPromoBonus, msg.value);
    }
    
    
    function setPromoMinPurchaseEth(uint256 val) onlyAdministrator public {
        _promoMinPurchaseEth = val;
    }
    
    function setMinRefEthPurchase(uint256 val) onlyAdministrator public {
        _minRefEthPurchase = val;
    }
    
    function setTotalIncomeFeePercent(uint256 val) onlyController public {
        require(val > 0 && val <= 100 ether);

        _totalIncomeFeePercent = val;
    }
        
    
    // set reward persentages of buy/sell fee. Token owner cannot take more than 40%.
    function setRewardPercentages(uint256 tokenOwnerRewardPercent, uint256 shareRewardPercent, uint256 refBonusPercent, uint256 bigPromoPercent, uint256 quickPromoPercent) onlyAdministrator public {
        require(tokenOwnerRewardPercent <= 40 ether);
        require(shareRewardPercent <= 100 ether);
        require(refBonusPercent <= 100 ether);
        require(bigPromoPercent <= 100 ether);
        require(quickPromoPercent <= 100 ether);

        require(tokenOwnerRewardPercent + shareRewardPercent + refBonusPercent + _devRewardPercent + _bigPromoPercent + _quickPromoPercent == 100 ether);

        _tokenOwnerRewardPercent = tokenOwnerRewardPercent;
        _shareRewardPercent = shareRewardPercent;
        _refBonusPercent = refBonusPercent;
        _bigPromoPercent = bigPromoPercent;
        _quickPromoPercent = quickPromoPercent;
    }    
    
    
    function payoutQuickBonus(address userAddress) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _promoQuickBonuses[dataContractAddress][userAddress] = SafeMath.add(_promoQuickBonuses[dataContractAddress][userAddress], _currentQuickPromoBonus);
        _currentQuickPromoBonus = 0;
    }
    
    function payoutBigBonus(address userAddress) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _promoBigBonuses[dataContractAddress][userAddress] = SafeMath.add(_promoBigBonuses[dataContractAddress][userAddress], _currentBigPromoBonus);
        _currentBigPromoBonus = 0;
    }

    function addDevReward() onlyController payable public {
        _devReward = SafeMath.add(_devReward, msg.value);
    }    
    
    function withdrawDevReward() onlyAdministrator public {
        uint256 reward = _devReward;
        _devReward = 0;

        msg.sender.transfer(reward);
    }
    
    function getBlockNumSinceInit() public view returns(uint256) {
        return block.number - getInitBlockNum();
    }

    function getQuickPromoRemainingBlocks() public view returns(uint256) {
        uint256 d = getBlockNumSinceInit() % _quickPromoBlockInterval;
        d = d == 0 ? _quickPromoBlockInterval : d;

        return _quickPromoBlockInterval - d;
    }

    function getBigPromoRemainingBlocks() public view returns(uint256) {
        uint256 d = getBlockNumSinceInit() % _bigPromoBlockInterval;
        d = d == 0 ? _bigPromoBlockInterval : d;

        return _bigPromoBlockInterval - d;
    } 
    
    
    function getBonusPerShare(address dataContractAddress) public view returns(uint256) {
        return _bonusesPerShare[dataContractAddress];
    }
    
    function getTotalBonusPerShare() public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _bonusesPerShare[Etherama(_controllerIndexer[i]).getDataContractAddress()]);
        }          
    }
    
    
    function addBonusPerShare() onlyController payable public {
        EtheramaData data = Etherama(msg.sender)._data();
        uint256 shareBonus = (msg.value * MAGNITUDE) / data.getTotalTokenSold();
        
        _bonusesPerShare[address(data)] = SafeMath.add(_bonusesPerShare[address(data)], shareBonus);
    }        
 
    function getUserRefBalance(address dataContractAddress, address userAddress) public view returns(uint256) {
        return _refBalances[dataContractAddress][userAddress];
    }
    
    function getUserRewardPayouts(address dataContractAddress, address userAddress) public view returns(uint256) {
        return _rewardPayouts[dataContractAddress][userAddress];
    }    

    function resetUserRefBalance(address userAddress) onlyController public {
        resetUserRefBalance(Etherama(msg.sender).getDataContractAddress(), userAddress);
    }
    
    function resetUserRefBalance(address dataContractAddress, address userAddress) internal {
        _refBalances[dataContractAddress][userAddress] = 0;
    }
    
    function addUserRefBalance(address userAddress) onlyController payable public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _refBalances[dataContractAddress][userAddress] = SafeMath.add(_refBalances[dataContractAddress][userAddress], msg.value);
    }

    function addUserRewardPayouts(address userAddress, uint256 val) onlyController public {
        addUserRewardPayouts(Etherama(msg.sender).getDataContractAddress(), userAddress, val);
    }    

    function addUserRewardPayouts(address dataContractAddress, address userAddress, uint256 val) internal {
        _rewardPayouts[dataContractAddress][userAddress] = SafeMath.add(_rewardPayouts[dataContractAddress][userAddress], val);
    }

    function resetUserPromoBonus(address userAddress) onlyController public {
        resetUserPromoBonus(Etherama(msg.sender).getDataContractAddress(), userAddress);
    }
    
    function resetUserPromoBonus(address dataContractAddress, address userAddress) internal {
        _promoQuickBonuses[dataContractAddress][userAddress] = 0;
        _promoBigBonuses[dataContractAddress][userAddress] = 0;
    }
    
    
    function trackBuy(address userAddress, uint256 volEth, uint256 volToken) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _buyCounts[dataContractAddress] = SafeMath.add(_buyCounts[dataContractAddress], 1);
        _userEthVolumeSaldos[dataContractAddress][userAddress] = SafeMath.add(_userEthVolumeSaldos[dataContractAddress][userAddress], volEth);
        
        trackTotalVolume(dataContractAddress, volEth, volToken);
    }

    function trackSell(address userAddress, uint256 volEth, uint256 volToken) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _sellCounts[dataContractAddress] = SafeMath.add(_sellCounts[dataContractAddress], 1);
        _userEthVolumeSaldos[dataContractAddress][userAddress] = SafeMath.sub(_userEthVolumeSaldos[dataContractAddress][userAddress], volEth);
        
        trackTotalVolume(dataContractAddress, volEth, volToken);
    }
    
    function trackTotalVolume(address dataContractAddress, uint256 volEth, uint256 volToken) internal {
        _totalVolumeEth[dataContractAddress] = SafeMath.add(_totalVolumeEth[dataContractAddress], volEth);
        _totalVolumeToken[dataContractAddress] = SafeMath.add(_totalVolumeToken[dataContractAddress], volToken);
    }
    
    function getBuyCount(address dataContractAddress) public view returns (uint256) {
        return _buyCounts[dataContractAddress];
    }
    
    function getTotalBuyCount() public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _buyCounts[Etherama(_controllerIndexer[i]).getDataContractAddress()]);
        }         
    }
    
    function getSellCount(address dataContractAddress) public view returns (uint256) {
        return _sellCounts[dataContractAddress];
    }
    
    function getTotalSellCount() public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _sellCounts[Etherama(_controllerIndexer[i]).getDataContractAddress()]);
        }         
    }

    function getTotalVolumeEth(address dataContractAddress) public view returns (uint256) {
        return _totalVolumeEth[dataContractAddress];
    }
    
    function getTotalVolumeToken(address dataContractAddress) public view returns (uint256) {
        return _totalVolumeToken[dataContractAddress];
    }

    function getUserEthVolumeSaldo(address dataContractAddress, address userAddress) public view returns (uint256) {
        return _userEthVolumeSaldos[dataContractAddress][userAddress];
    }
    
    function getUserTotalEthVolumeSaldo(address userAddress) public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _userEthVolumeSaldos[Etherama(_controllerIndexer[i]).getDataContractAddress()][userAddress]);
        } 
    }
    
    function getTotalCollectedPromoBonus() public view returns (uint256) {
        return SafeMath.add(_currentBigPromoBonus, _currentQuickPromoBonus);
    }

    function getUserTotalPromoBonus(address dataContractAddress, address userAddress) public view returns (uint256) {
        return SafeMath.add(_promoQuickBonuses[dataContractAddress][userAddress], _promoBigBonuses[dataContractAddress][userAddress]);
    }
    
    function getUserQuickPromoBonus(address dataContractAddress, address userAddress) public view returns (uint256) {
        return _promoQuickBonuses[dataContractAddress][userAddress];
    }
    
    function getUserBigPromoBonus(address dataContractAddress, address userAddress) public view returns (uint256) {
        return _promoBigBonuses[dataContractAddress][userAddress];
    }

    
    function getUserTokenLocalBalance(address dataContractAddress, address userAddress) public view returns(uint256) {
        return _userTokenLocalBalances[dataContractAddress][userAddress];
    }
  
    
    function addUserTokenLocalBalance(address userAddress, uint256 val) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _userTokenLocalBalances[dataContractAddress][userAddress] = SafeMath.add(_userTokenLocalBalances[dataContractAddress][userAddress], val);
    }
    
    function subUserTokenLocalBalance(address userAddress, uint256 val) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _userTokenLocalBalances[dataContractAddress][userAddress] = SafeMath.sub(_userTokenLocalBalances[dataContractAddress][userAddress], val);
    }

  
    function getUserReward(address dataContractAddress, address userAddress, bool incShareBonus, bool incRefBonus, bool incPromoBonus) public view returns(uint256 reward) {
        EtheramaData data = EtheramaData(dataContractAddress);
        
        if (incShareBonus) {
            reward = data.getBonusPerShare() * data.getActualUserTokenBalance(userAddress);
            reward = ((reward < data.getUserRewardPayouts(userAddress)) ? 0 : SafeMath.sub(reward, data.getUserRewardPayouts(userAddress))) / MAGNITUDE;
        }
        
        if (incRefBonus) reward = SafeMath.add(reward, data.getUserRefBalance(userAddress));
        if (incPromoBonus) reward = SafeMath.add(reward, data.getUserTotalPromoBonus(userAddress));
        
        return reward;
    }
    
    //user&#39;s total reward from all the tokens on the table. includes share reward + referal bonus + promo bonus
    function getUserTotalReward(address userAddress, bool incShareBonus, bool incRefBonus, bool incPromoBonus) public view returns(uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            address dataContractAddress = Etherama(_controllerIndexer[i]).getDataContractAddress();
            
            res = SafeMath.add(res, getUserReward(dataContractAddress, userAddress, incShareBonus, incRefBonus, incPromoBonus));
        }
    }
    
    //current user&#39;s reward
    function getCurrentUserReward(bool incRefBonus, bool incPromoBonus) public view returns(uint256) {
        return getUserTotalReward(msg.sender, true, incRefBonus, incPromoBonus);
    }
 
    //current user&#39;s total reward from all the tokens on the table
    function getCurrentUserTotalReward() public view returns(uint256) {
        return getUserTotalReward(msg.sender, true, true, true);
    }
    
    //user&#39;s share bonus from all the tokens on the table
    function getCurrentUserShareBonus() public view returns(uint256) {
        return getUserTotalReward(msg.sender, true, false, false);
    }
    
    //current user&#39;s ref bonus from all the tokens on the table
    function getCurrentUserRefBonus() public view returns(uint256) {
        return getUserTotalReward(msg.sender, false, true, false);
    }
    
    //current user&#39;s promo bonus from all the tokens on the table
    function getCurrentUserPromoBonus() public view returns(uint256) {
        return getUserTotalReward(msg.sender, false, false, true);
    }
    
    //is ref link available for the user
    function isRefAvailable(address refAddress) public view returns(bool) {
        return getUserTotalEthVolumeSaldo(refAddress) >= _minRefEthPurchase;
    }
    
    //is ref link available for the current user
    function isRefAvailable() public view returns(bool) {
        return isRefAvailable(msg.sender);
    }
    
     //Withdraws all of the user earnings.
    function withdrawUserReward() public {
        uint256 reward = getRewardAndPrepareWithdraw();
        
        require(reward > 0);
        
        msg.sender.transfer(reward);
        
        emit onWithdrawUserBonus(msg.sender, reward);
    }

    //gather all the user&#39;s reward and prepare it to withdaw
    function getRewardAndPrepareWithdraw() internal returns(uint256 reward) {
        
        for (uint256 i = 0; i < _controllerContractCount; i++) {

            address dataContractAddress = Etherama(_controllerIndexer[i]).getDataContractAddress();
            
            reward = SafeMath.add(reward, getUserReward(dataContractAddress, msg.sender, true, false, false));

            // add share reward to payouts
            addUserRewardPayouts(dataContractAddress, msg.sender, reward * MAGNITUDE);

            // add ref bonus
            reward = SafeMath.add(reward, getUserRefBalance(dataContractAddress, msg.sender));
            resetUserRefBalance(dataContractAddress, msg.sender);
            
            // add promo bonus
            reward = SafeMath.add(reward, getUserTotalPromoBonus(dataContractAddress, msg.sender));
            resetUserPromoBonus(dataContractAddress, msg.sender);
        }
        
        return reward;
    }
    
    //withdaw all the remamining ETH if there is no one active contract. We don&#39;t want to leave them here forever
    function withdrawRemainingEthAfterAll() onlyAdministrator public {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            if (Etherama(_controllerIndexer[i]).isActive()) revert();
        }
        
        msg.sender.transfer(address(this).balance);
    }

    
    
    function calcPercent(uint256 amount, uint256 percent) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(SafeMath.div(amount, 100), percent), 1 ether);
    }

    //Converts real num to uint256. Works only with positive numbers.
    function convertRealTo256(int128 realVal) public pure returns(uint256) {
        int128 roundedVal = RealMath.fromReal(RealMath.mul(realVal, RealMath.toReal(1e12)));

        return SafeMath.mul(uint256(roundedVal), uint256(1e6));
    }

    //Converts uint256 to real num. Possible a little loose of precision
    function convert256ToReal(uint256 val) public pure returns(int128) {
        uint256 intVal = SafeMath.div(val, 1e6);
        require(RealMath.isUInt256ValidIn64(intVal));
        
        return RealMath.fraction(int64(intVal), 1e12);
    }    
}

// Data contract for Etherama contract controller. Data contract cannot be changed so no data can be lost. On the other hand Etherama controller can be replaced if some error is found.
contract EtheramaData {

    // tranding token address
    address constant public TOKEN_CONTRACT_ADDRESS = 0x83cee9e086A77e492eE0bB93C2B0437aD6fdECCc;
    
    // token price in the begining
    uint256 constant public TOKEN_PRICE_INITIAL = 0.0023 ether;
    // a percent of the token price which adds/subs each _priceSpeedInterval tokens
    uint64 constant public PRICE_SPEED_PERCENT = 5;
    // Token price speed interval. For instance, if PRICE_SPEED_PERCENT = 5 and PRICE_SPEED_INTERVAL = 10000 it means that after 10000 tokens are bought/sold  token price will increase/decrease for 5%.
    uint64 constant public PRICE_SPEED_INTERVAL = 10000;
    // lock-up period in days. Until this period is expeired nobody can close the contract or withdraw users&#39; funds
    uint64 constant public EXP_PERIOD_DAYS = 365;

    
    mapping(address => bool) private _administrators;
    uint256 private  _administratorCount;

    uint64 public _initTime;
    uint64 public _expirationTime;
    uint256 public _tokenOwnerReward;
    
    uint256 public _totalSupply;
    int128 public _realTokenPrice;

    address public _controllerAddress = address(0x0);

    EtheramaCore public _core;

    uint256 public _initBlockNum;
    
    bool public _hasMaxPurchaseLimit = false;
    
    IStdToken public _token;

    //only main contract
    modifier onlyController() {
        require(msg.sender == _controllerAddress);
        _;
    }

    constructor(address coreAddress) public {
        require(coreAddress != address(0x0));

        _core = EtheramaCore(coreAddress);
        _initBlockNum = block.number;
    }
    
    function init() public {
        require(_controllerAddress == address(0x0));
        require(TOKEN_CONTRACT_ADDRESS != address(0x0));
        require(RealMath.isUInt64ValidIn64(PRICE_SPEED_PERCENT) && PRICE_SPEED_PERCENT > 0);
        require(RealMath.isUInt64ValidIn64(PRICE_SPEED_INTERVAL) && PRICE_SPEED_INTERVAL > 0);
        
        
        _controllerAddress = msg.sender;

        _token = IStdToken(TOKEN_CONTRACT_ADDRESS);
        _initTime = uint64(now);
        _expirationTime = _initTime + EXP_PERIOD_DAYS * 1 days;
        _realTokenPrice = _core.convert256ToReal(TOKEN_PRICE_INITIAL);
    }
    
    function isInited()  public view returns(bool) {
        return (_controllerAddress != address(0x0));
    }
    
    function getCoreAddress()  public view returns(address) {
        return address(_core);
    }
    

    function setNewControllerAddress(address newAddress) onlyController public {
        _controllerAddress = newAddress;
    }


    
    function getPromoMinPurchaseEth() public view returns(uint256) {
        return _core._promoMinPurchaseEth();
    }

    function addAdministator(address addr) onlyController public {
        _administrators[addr] = true;
        _administratorCount = SafeMath.add(_administratorCount, 1);
    }

    function removeAdministator(address addr) onlyController public {
        _administrators[addr] = false;
        _administratorCount = SafeMath.sub(_administratorCount, 1);
    }

    function getAdministratorCount() public view returns(uint256) {
        return _administratorCount;
    }
    
    function isAdministrator(address addr) public view returns(bool) {
        return _administrators[addr];
    }

    
    function getCommonInitBlockNum() public view returns (uint256) {
        return _core.getInitBlockNum();
    }
    
    
    function resetTokenOwnerReward() onlyController public {
        _tokenOwnerReward = 0;
    }
    
    function addTokenOwnerReward(uint256 val) onlyController public {
        _tokenOwnerReward = SafeMath.add(_tokenOwnerReward, val);
    }
    
    function getCurrentBigPromoBonus() public view returns (uint256) {
        return _core._currentBigPromoBonus();
    }        
    

    function getCurrentQuickPromoBonus() public view returns (uint256) {
        return _core._currentQuickPromoBonus();
    }    

    function getTotalCollectedPromoBonus() public view returns (uint256) {
        return _core.getTotalCollectedPromoBonus();
    }    

    function setTotalSupply(uint256 val) onlyController public {
        _totalSupply = val;
    }
    
    function setRealTokenPrice(int128 val) onlyController public {
        _realTokenPrice = val;
    }    
    
    
    function setHasMaxPurchaseLimit(bool val) onlyController public {
        _hasMaxPurchaseLimit = val;
    }
    
    function getUserTokenLocalBalance(address userAddress) public view returns(uint256) {
        return _core.getUserTokenLocalBalance(address(this), userAddress);
    }
    
    function getActualUserTokenBalance(address userAddress) public view returns(uint256) {
        return SafeMath.min(getUserTokenLocalBalance(userAddress), _token.balanceOf(userAddress));
    }  
    
    function getBonusPerShare() public view returns(uint256) {
        return _core.getBonusPerShare(address(this));
    }
    
    function getUserRewardPayouts(address userAddress) public view returns(uint256) {
        return _core.getUserRewardPayouts(address(this), userAddress);
    }
    
    function getUserRefBalance(address userAddress) public view returns(uint256) {
        return _core.getUserRefBalance(address(this), userAddress);
    }
    
    function getUserReward(address userAddress, bool incRefBonus, bool incPromoBonus) public view returns(uint256) {
        return _core.getUserReward(address(this), userAddress, true, incRefBonus, incPromoBonus);
    }
    
    function getUserTotalPromoBonus(address userAddress) public view returns(uint256) {
        return _core.getUserTotalPromoBonus(address(this), userAddress);
    }
    
    function getUserBigPromoBonus(address userAddress) public view returns(uint256) {
        return _core.getUserBigPromoBonus(address(this), userAddress);
    }

    function getUserQuickPromoBonus(address userAddress) public view returns(uint256) {
        return _core.getUserQuickPromoBonus(address(this), userAddress);
    }

    function getRemainingTokenAmount() public view returns(uint256) {
        return _token.balanceOf(_controllerAddress);
    }

    function getTotalTokenSold() public view returns(uint256) {
        return _totalSupply - getRemainingTokenAmount();
    }   
    
    function getUserEthVolumeSaldo(address userAddress) public view returns(uint256) {
        return _core.getUserEthVolumeSaldo(address(this), userAddress);
    }

}


contract Etherama {

    IStdToken public _token;
    EtheramaData public _data;
    EtheramaCore public _core;


    bool public isActive = false;
    bool public isMigrationToNewControllerInProgress = false;
    bool public isActualContractVer = true;
    address public migrationContractAddress = address(0x0);
    bool public isMigrationApproved = false;

    address private _creator = address(0x0);
    

    event onTokenPurchase(address indexed userAddress, uint256 incomingEth, uint256 tokensMinted, address indexed referredBy);
    
    event onTokenSell(address indexed userAddress, uint256 tokensBurned, uint256 ethEarned);
    
    event onReinvestment(address indexed userAddress, uint256 ethReinvested, uint256 tokensMinted);
    
    event onWithdrawTokenOwnerReward(address indexed toAddress, uint256 ethWithdrawn); 

    event onWinQuickPromo(address indexed userAddress, uint256 ethWon);    
   
    event onWinBigPromo(address indexed userAddress, uint256 ethWon);    


    // only people with tokens
    modifier onlyContractUsers() {
        require(getUserLocalTokenBalance(msg.sender) > 0);
        _;
    }
    

    // administrators can:
    // -> change minimal amout of tokens to get a ref link.
    // administrators CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    // -> suspend the contract
    modifier onlyAdministrator() {
        require(isCurrentUserAdministrator());
        _;
    }
    
    //core administrator can only approve contract migration after its code review
    modifier onlyCoreAdministrator() {
        require(_core.isAdministrator(msg.sender));
        _;
    }

    // only active state of the contract. Administator can activate it, but canncon deactive untill lock-up period is expired.
    modifier onlyActive() {
        require(isActive);
        _;
    }

    // maximum gas price for buy/sell transactions to avoid "front runner" vulnerability.   
    modifier validGasPrice() {
        require(tx.gasprice <= _core.MAX_GAS_PRICE());
        _;
    }
    
    // eth value must be greater than 0 for purchase transactions
    modifier validPayableValue() {
        require(msg.value > 0);
        _;
    }
    
    modifier onlyCoreContract() {
        require(msg.sender == _data.getCoreAddress());
        _;
    }

    // dataContractAddress - data contract address where all the data is collected and separated from the controller
    constructor(address dataContractAddress) public {
        
        require(dataContractAddress != address(0x0));
        _data = EtheramaData(dataContractAddress);
        
        if (!_data.isInited()) {
            _data.init();
            _data.addAdministator(msg.sender);
            _creator = msg.sender;
        }
        
        _token = _data._token();
        _core = _data._core();
    }



    function addAdministator(address addr) onlyAdministrator public {
        _data.addAdministator(addr);
    }

    function removeAdministator(address addr) onlyAdministrator public {
        _data.removeAdministator(addr);
    }

    // transfer ownership request of the contract to token owner from contract creator. The new administator has to accept ownership to finish the transferring.
    function transferOwnershipRequest(address addr) onlyAdministrator public {
        addAdministator(addr);
    }

    // accept transfer ownership.
    function acceptOwnership() onlyAdministrator public {
        require(_creator != address(0x0));

        removeAdministator(_creator);

        require(_data.getAdministratorCount() == 1);
    }
    
    // if there is a maximim purchase limit then a user can buy only amount of tokens which he had before, not more.
    function setHasMaxPurchaseLimit(bool val) onlyAdministrator public {
        _data.setHasMaxPurchaseLimit(val);
    }
        
    // activate the controller contract. After calling this function anybody can start trading the contrant&#39;s tokens
    function activate() onlyAdministrator public {
        require(!isActive);
        
        if (getTotalTokenSupply() == 0) setTotalSupply();
        require(getTotalTokenSupply() > 0);
        
        isActive = true;
        isMigrationToNewControllerInProgress = false;
    }

    // Close the contract and withdraw all the funds. The contract cannot be closed before lock up period is expired.
    function finish() onlyActive onlyAdministrator public {
        require(uint64(now) >= _data._expirationTime());
        
        _token.transfer(msg.sender, getRemainingTokenAmount());   
        msg.sender.transfer(getTotalEthBalance());
        
        isActive = false;
    }
    
    //Converts incoming eth to tokens
    function buy(address refAddress, uint256 minReturn) onlyActive validGasPrice validPayableValue public payable returns(uint256) {
        return purchaseTokens(msg.value, refAddress, minReturn);
    }

    //sell tokens for eth. before call this func you have to call "approve" in the ERC20 token contract
    function sell(uint256 tokenAmount, uint256 minReturn) onlyActive onlyContractUsers validGasPrice public returns(uint256) {
        if (tokenAmount > getCurrentUserLocalTokenBalance() || tokenAmount == 0) return 0;

        uint256 ethAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (ethAmount, totalFeeEth, tokenPrice) = estimateSellOrder(tokenAmount, true);
        require(ethAmount >= minReturn);

        subUserTokens(msg.sender, tokenAmount);

        msg.sender.transfer(ethAmount);

        updateTokenPrice(-_core.convert256ToReal(tokenAmount));

        distributeFee(totalFeeEth, address(0x0));
        
        uint256 userEthVol = _data.getUserEthVolumeSaldo(msg.sender);
        _core.trackSell(msg.sender, ethAmount > userEthVol ? userEthVol : ethAmount, tokenAmount);
       
        emit onTokenSell(msg.sender, tokenAmount, ethAmount);

        return ethAmount;
    }   


    //Fallback function to handle eth that was sent straight to the contract
    function() onlyActive validGasPrice validPayableValue payable external {
        purchaseTokens(msg.value, address(0x0), 1);
    }

    // withdraw token owner&#39;s reward
    function withdrawTokenOwnerReward() onlyAdministrator public {
        uint256 reward = getTokenOwnerReward();
        
        require(reward > 0);
        
        _data.resetTokenOwnerReward();

        msg.sender.transfer(reward);

        emit onWithdrawTokenOwnerReward(msg.sender, reward);
    }

    // prepare the contract for migration to another one in case of some errors or refining
    function prepareForMigration() onlyAdministrator public {
        require(!isMigrationToNewControllerInProgress);
        isMigrationToNewControllerInProgress = true;
    }

    // accept funds transfer to a new controller during a migration.
    function migrateFunds() payable public {
        require(isMigrationToNewControllerInProgress);
    }
    

    //HELPERS

    // max gas price for buy/sell transactions  
    function getMaxGasPrice() public view returns(uint256) {
        return _core.MAX_GAS_PRICE();
    }

    // max gas price for buy/sell transactions
    function getExpirationTime() public view returns (uint256) {
        return _data._expirationTime();
    }
            
    // time till lock-up period is expired 
    function getRemainingTimeTillExpiration() public view returns (uint256) {
        if (_data._expirationTime() <= uint64(now)) return 0;
        
        return _data._expirationTime() - uint64(now);
    }

    
    function isCurrentUserAdministrator() public view returns(bool) {
        return _data.isAdministrator(msg.sender);
    }

    //data contract address where all the data is holded
    function getDataContractAddress() public view returns(address) {
        return address(_data);
    }

    // get trading token contract address
    function getTokenAddress() public view returns(address) {
        return address(_token);
    }

    // request migration to new contract. After request Etherama dev team should review its code and approve it if it is OK
    function requestControllerContractMigration(address newControllerAddr) onlyAdministrator public {
        require(!isMigrationApproved);
        
        migrationContractAddress = newControllerAddr;
    }
    
    // Dev team gives a pervission to updagrade the contract after code review, transfer all the funds, activate new abilities or fix some errors.
    function approveControllerContractMigration() onlyCoreAdministrator public {
        isMigrationApproved = true;
    }
    
    //migrate to new controller contract in case of some mistake in the contract and transfer there all the tokens and eth. It can be done only after code review by Etherama developers.
    function migrateToNewNewControllerContract() onlyAdministrator public {
        require(isMigrationApproved && migrationContractAddress != address(0x0) && isActualContractVer);
        
        isActive = false;

        Etherama newController = Etherama(address(migrationContractAddress));
        _data.setNewControllerAddress(migrationContractAddress);

        uint256 remainingTokenAmount = getRemainingTokenAmount();
        uint256 ethBalance = getTotalEthBalance();

        if (remainingTokenAmount > 0) _token.transfer(migrationContractAddress, remainingTokenAmount); 
        if (ethBalance > 0) newController.migrateFunds.value(ethBalance)();
        
        isActualContractVer = false;
    }

    //total buy count
    function getBuyCount() public view returns(uint256) {
        return _core.getBuyCount(getDataContractAddress());
    }
    //total sell count
    function getSellCount() public view returns(uint256) {
        return _core.getSellCount(getDataContractAddress());
    }
    //total eth volume
    function getTotalVolumeEth() public view returns(uint256) {
        return _core.getTotalVolumeEth(getDataContractAddress());
    }   
    //total token volume
    function getTotalVolumeToken() public view returns(uint256) {
        return _core.getTotalVolumeToken(getDataContractAddress());
    } 
    //current bonus per 1 token in ETH
    function getBonusPerShare() public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(_data.getBonusPerShare(), 1 ether), _core.MAGNITUDE());
    }    
    //token initial price in ETH
    function getTokenInitialPrice() public view returns(uint256) {
        return _data.TOKEN_PRICE_INITIAL();
    }

    function getDevRewardPercent() public view returns(uint256) {
        return _core._devRewardPercent();
    }

    function getTokenOwnerRewardPercent() public view returns(uint256) {
        return _core._tokenOwnerRewardPercent();
    }
    
    function getShareRewardPercent() public view returns(uint256) {
        return _core._shareRewardPercent();
    }
    
    function getRefBonusPercent() public view returns(uint256) {
        return _core._refBonusPercent();
    }
    
    function getBigPromoPercent() public view returns(uint256) {
        return _core._bigPromoPercent();
    }
    
    function getQuickPromoPercent() public view returns(uint256) {
        return _core._quickPromoPercent();
    }

    function getBigPromoBlockInterval() public view returns(uint256) {
        return _core._bigPromoBlockInterval();
    }

    function getQuickPromoBlockInterval() public view returns(uint256) {
        return _core._quickPromoBlockInterval();
    }

    function getPromoMinPurchaseEth() public view returns(uint256) {
        return _core._promoMinPurchaseEth();
    }


    function getPriceSpeedPercent() public view returns(uint64) {
        return _data.PRICE_SPEED_PERCENT();
    }

    function getPriceSpeedTokenBlock() public view returns(uint64) {
        return _data.PRICE_SPEED_INTERVAL();
    }

    function getMinRefEthPurchase() public view returns (uint256) {
        return _core._minRefEthPurchase();
    }    

    function getTotalCollectedPromoBonus() public view returns (uint256) {
        return _data.getTotalCollectedPromoBonus();
    }   

    function getCurrentBigPromoBonus() public view returns (uint256) {
        return _data.getCurrentBigPromoBonus();
    }  

    function getCurrentQuickPromoBonus() public view returns (uint256) {
        return _data.getCurrentQuickPromoBonus();
    }    

    //current token price
    function getCurrentTokenPrice() public view returns(uint256) {
        return _core.convertRealTo256(_data._realTokenPrice());
    }

    //contract&#39;s eth balance
    function getTotalEthBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    //amount of tokens which were funded to the contract initially
    function getTotalTokenSupply() public view returns(uint256) {
        return _data._totalSupply();
    }

    //amount of tokens which are still available for selling on the contract
    function getRemainingTokenAmount() public view returns(uint256) {
        return _token.balanceOf(address(this));
    }
    
    //amount of tokens which where sold by the contract
    function getTotalTokenSold() public view returns(uint256) {
        return getTotalTokenSupply() - getRemainingTokenAmount();
    }
    
    //user&#39;s token amount which were bought from the contract
    function getUserLocalTokenBalance(address userAddress) public view returns(uint256) {
        return _data.getUserTokenLocalBalance(userAddress);
    }
    
    //current user&#39;s token amount which were bought from the contract
    function getCurrentUserLocalTokenBalance() public view returns(uint256) {
        return getUserLocalTokenBalance(msg.sender);
    }    

    //is referal link available for the current user
    function isCurrentUserRefAvailable() public view returns(bool) {
        return _core.isRefAvailable();
    }


    function getCurrentUserRefBonus() public view returns(uint256) {
        return _data.getUserRefBalance(msg.sender);
    }
    
    function getCurrentUserPromoBonus() public view returns(uint256) {
        return _data.getUserTotalPromoBonus(msg.sender);
    }
    
    //max and min values of a deal in tokens
    function getTokenDealRange() public view returns(uint256, uint256) {
        return (_core.MIN_TOKEN_DEAL_VAL(), _core.MAX_TOKEN_DEAL_VAL());
    }
    
    //max and min values of a deal in ETH
    function getEthDealRange() public view returns(uint256, uint256) {
        uint256 minTokenVal; uint256 maxTokenVal;
        (minTokenVal, maxTokenVal) = getTokenDealRange();
        
        return ( SafeMath.max(_core.MIN_ETH_DEAL_VAL(), tokensToEth(minTokenVal, true)), SafeMath.min(_core.MAX_ETH_DEAL_VAL(), tokensToEth(maxTokenVal, true)) );
    }
    
    //user&#39;s total reward from all the tokens on the table. includes share reward + referal bonus + promo bonus
    function getUserReward(address userAddress, bool isTotal) public view returns(uint256) {
        return isTotal ? 
            _core.getUserTotalReward(userAddress, true, true, true) :
            _data.getUserReward(userAddress, true, true);
    }
    
    //price for selling 1 token. mostly useful only for frontend
    function get1TokenSellPrice() public view returns(uint256) {
        uint256 tokenAmount = 1 ether;

        uint256 ethAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (ethAmount, totalFeeEth, tokenPrice) = estimateSellOrder(tokenAmount, true);

        return ethAmount;
    }
    
    //price for buying 1 token. mostly useful only for frontend
    function get1TokenBuyPrice() public view returns(uint256) {
        uint256 ethAmount = 1 ether;

        uint256 tokenAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (tokenAmount, totalFeeEth, tokenPrice) = estimateBuyOrder(ethAmount, true);  

        return SafeMath.div(ethAmount * 1 ether, tokenAmount);
    }

    //calc current reward for holding @tokenAmount tokens
    function calcReward(uint256 tokenAmount) public view returns(uint256) {
        return (uint256) ((int256)(_data.getBonusPerShare() * tokenAmount)) / _core.MAGNITUDE();
    }  

    //esimate buy order by amount of ETH/tokens. returns tokens/eth amount after the deal, total fee in ETH and average token price
    function estimateBuyOrder(uint256 amount, bool fromEth) public view returns(uint256, uint256, uint256) {
        uint256 minAmount; uint256 maxAmount;
        (minAmount, maxAmount) = fromEth ? getEthDealRange() : getTokenDealRange();
        //require(amount >= minAmount && amount <= maxAmount);

        uint256 ethAmount = fromEth ? amount : tokensToEth(amount, true);
        require(ethAmount > 0);

        uint256 tokenAmount = fromEth ? ethToTokens(amount, true) : amount;
        uint256 totalFeeEth = calcTotalFee(tokenAmount, true);
        require(ethAmount > totalFeeEth);

        uint256 tokenPrice = SafeMath.div(ethAmount * 1 ether, tokenAmount);

        return (fromEth ? tokenAmount : SafeMath.add(ethAmount, totalFeeEth), totalFeeEth, tokenPrice);
    }
    
    //esimate sell order by amount of tokens/ETH. returns eth/tokens amount after the deal, total fee in ETH and average token price
    function estimateSellOrder(uint256 amount, bool fromToken) public view returns(uint256, uint256, uint256) {
        uint256 minAmount; uint256 maxAmount;
        (minAmount, maxAmount) = fromToken ? getTokenDealRange() : getEthDealRange();
        //require(amount >= minAmount && amount <= maxAmount);

        uint256 tokenAmount = fromToken ? amount : ethToTokens(amount, false);
        require(tokenAmount > 0);
        
        uint256 ethAmount = fromToken ? tokensToEth(tokenAmount, false) : amount;
        uint256 totalFeeEth = calcTotalFee(tokenAmount, false);
        require(ethAmount > totalFeeEth);

        uint256 tokenPrice = SafeMath.div(ethAmount * 1 ether, tokenAmount);
        
        return (fromToken ? ethAmount : tokenAmount, totalFeeEth, tokenPrice);
    }

    //returns max user&#39;s purchase limit in tokens if _hasMaxPurchaseLimit pamam is set true. If it is a user cannot by more tokens that hs already bought on some other exchange
    function getUserMaxPurchase(address userAddress) public view returns(uint256) {
        return _token.balanceOf(userAddress) - SafeMath.mul(getUserLocalTokenBalance(userAddress), 2);
    }
    //current urser&#39;s max purchase limit in tokens
    function getCurrentUserMaxPurchase() public view returns(uint256) {
        return getUserMaxPurchase(msg.sender);
    }

    //token owener collected reward
    function getTokenOwnerReward() public view returns(uint256) {
        return _data._tokenOwnerReward();
    }

    //current user&#39;s won promo bonuses
    function getCurrentUserTotalPromoBonus() public view returns(uint256) {
        return _data.getUserTotalPromoBonus(msg.sender);
    }

    //current user&#39;s won big promo bonuses
    function getCurrentUserBigPromoBonus() public view returns(uint256) {
        return _data.getUserBigPromoBonus(msg.sender);
    }
    //current user&#39;s won quick promo bonuses
    function getCurrentUserQuickPromoBonus() public view returns(uint256) {
        return _data.getUserQuickPromoBonus(msg.sender);
    }
   
    //amount of block since core contract is deployed
    function getBlockNumSinceInit() public view returns(uint256) {
        return _core.getBlockNumSinceInit();
    }

    //remaing amount of blocks to win a quick promo bonus
    function getQuickPromoRemainingBlocks() public view returns(uint256) {
        return _core.getQuickPromoRemainingBlocks();
    }
    //remaing amount of blocks to win a big promo bonus
    function getBigPromoRemainingBlocks() public view returns(uint256) {
        return _core.getBigPromoRemainingBlocks();
    } 
    
    
    // INTERNAL FUNCTIONS
    
    function purchaseTokens(uint256 ethAmount, address refAddress, uint256 minReturn) internal returns(uint256) {
        uint256 tokenAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (tokenAmount, totalFeeEth, tokenPrice) = estimateBuyOrder(ethAmount, true);
        require(tokenAmount >= minReturn);

        if (_data._hasMaxPurchaseLimit()) {
            //user has to have at least equal amount of tokens which he&#39;s willing to buy 
            require(getCurrentUserMaxPurchase() >= tokenAmount);
        }

        require(tokenAmount > 0 && (SafeMath.add(tokenAmount, getTotalTokenSold()) > getTotalTokenSold()));

        if (refAddress == msg.sender || !_core.isRefAvailable(refAddress)) refAddress = address(0x0);

        distributeFee(totalFeeEth, refAddress);

        addUserTokens(msg.sender, tokenAmount);

        // the user is not going to receive any reward for the current purchase
        _core.addUserRewardPayouts(msg.sender, _data.getBonusPerShare() * tokenAmount);

        checkAndSendPromoBonus(ethAmount);
        
        updateTokenPrice(_core.convert256ToReal(tokenAmount));
        
        _core.trackBuy(msg.sender, ethAmount, tokenAmount);

        emit onTokenPurchase(msg.sender, ethAmount, tokenAmount, refAddress);
        
        return tokenAmount;
    }

    function setTotalSupply() internal {
        require(_data._totalSupply() == 0);

        uint256 tokenAmount = _token.balanceOf(address(this));

        _data.setTotalSupply(tokenAmount);
    }


    function checkAndSendPromoBonus(uint256 purchaseAmountEth) internal {
        if (purchaseAmountEth < _data.getPromoMinPurchaseEth()) return;

        if (getQuickPromoRemainingBlocks() == 0) sendQuickPromoBonus();
        if (getBigPromoRemainingBlocks() == 0) sendBigPromoBonus();
    }

    function sendQuickPromoBonus() internal {
        _core.payoutQuickBonus(msg.sender);

        emit onWinQuickPromo(msg.sender, _data.getCurrentQuickPromoBonus());
    }

    function sendBigPromoBonus() internal {
        _core.payoutBigBonus(msg.sender);

        emit onWinBigPromo(msg.sender, _data.getCurrentBigPromoBonus());
    }

    function distributeFee(uint256 totalFeeEth, address refAddress) internal {
        addProfitPerShare(totalFeeEth, refAddress);
        addDevReward(totalFeeEth);
        addTokenOwnerReward(totalFeeEth);
        addBigPromoBonus(totalFeeEth);
        addQuickPromoBonus(totalFeeEth);
    }

    function addProfitPerShare(uint256 totalFeeEth, address refAddress) internal {
        uint256 refBonus = calcRefBonus(totalFeeEth);
        uint256 totalShareReward = calcTotalShareRewardFee(totalFeeEth);

        if (refAddress != address(0x0)) {
            _core.addUserRefBalance.value(refBonus)(refAddress);
        } else {
            totalShareReward = SafeMath.add(totalShareReward, refBonus);
        }

        if (getTotalTokenSold() == 0) {
            _data.addTokenOwnerReward(totalShareReward);
        } else {
            _core.addBonusPerShare.value(totalShareReward)();
        }
    }

    function addDevReward(uint256 totalFeeEth) internal {
        _core.addDevReward.value(calcDevReward(totalFeeEth))();
    }    
    
    function addTokenOwnerReward(uint256 totalFeeEth) internal {
        _data.addTokenOwnerReward(calcTokenOwnerReward(totalFeeEth));
    }  

    function addBigPromoBonus(uint256 totalFeeEth) internal {
        _core.addBigPromoBonus.value(calcBigPromoBonus(totalFeeEth))();
    }

    function addQuickPromoBonus(uint256 totalFeeEth) internal {
        _core.addQuickPromoBonus.value(calcQuickPromoBonus(totalFeeEth))();
    }   


    function addUserTokens(address user, uint256 tokenAmount) internal {
        _core.addUserTokenLocalBalance(user, tokenAmount);
        _token.transfer(msg.sender, tokenAmount);   
    }

    function subUserTokens(address user, uint256 tokenAmount) internal {
        _core.subUserTokenLocalBalance(user, tokenAmount);
        _token.transferFrom(user, address(this), tokenAmount);    
    }

    function updateTokenPrice(int128 realTokenAmount) public {
        _data.setRealTokenPrice(calc1RealTokenRateFromRealTokens(realTokenAmount));
    }

    function ethToTokens(uint256 ethAmount, bool isBuy) internal view returns(uint256) {
        int128 realEthAmount = _core.convert256ToReal(ethAmount);
        int128 t0 = RealMath.div(realEthAmount, _data._realTokenPrice());
        int128 s = getRealPriceSpeed();

        int128 tn =  RealMath.div(t0, RealMath.toReal(100));

        for (uint i = 0; i < 100; i++) {

            int128 tns = RealMath.mul(tn, s);
            int128 exptns = RealMath.exp( RealMath.mul(tns, RealMath.toReal(isBuy ? int64(1) : int64(-1))) );

            int128 tn1 = RealMath.div(
                RealMath.mul( RealMath.mul(tns, tn), exptns ) + t0,
                RealMath.mul( exptns, RealMath.toReal(1) + tns )
            );

            if (RealMath.abs(tn-tn1) < RealMath.fraction(1, 1e18)) break;

            tn = tn1;
        }

        return _core.convertRealTo256(tn);
    }

    function tokensToEth(uint256 tokenAmount, bool isBuy) internal view returns(uint256) {
        int128 realTokenAmount = _core.convert256ToReal(tokenAmount);
        int128 s = getRealPriceSpeed();
        int128 expArg = RealMath.mul(RealMath.mul(realTokenAmount, s), RealMath.toReal(isBuy ? int64(1) : int64(-1)));
        
        int128 realEthAmountFor1Token = RealMath.mul(_data._realTokenPrice(), RealMath.exp(expArg));
        int128 realEthAmount = RealMath.mul(realTokenAmount, realEthAmountFor1Token);

        return _core.convertRealTo256(realEthAmount);
    }

    function calcTotalFee(uint256 tokenAmount, bool isBuy) internal view returns(uint256) {
        int128 realTokenAmount = _core.convert256ToReal(tokenAmount);
        int128 factor = RealMath.toReal(isBuy ? int64(1) : int64(-1));
        int128 rateAfterDeal = calc1RealTokenRateFromRealTokens(RealMath.mul(realTokenAmount, factor));
        int128 delta = RealMath.div(rateAfterDeal - _data._realTokenPrice(), RealMath.toReal(2));
        int128 fee = RealMath.mul(realTokenAmount, delta);
        
        //commission for sells is a bit lower due to rounding error
        if (!isBuy) fee = RealMath.mul(fee, RealMath.fraction(95, 100));

        return _core.calcPercent(_core.convertRealTo256(RealMath.mul(fee, factor)), _core._totalIncomeFeePercent());
    }



    function calc1RealTokenRateFromRealTokens(int128 realTokenAmount) internal view returns(int128) {
        int128 expArg = RealMath.mul(realTokenAmount, getRealPriceSpeed());

        return RealMath.mul(_data._realTokenPrice(), RealMath.exp(expArg));
    }
    
    function getRealPriceSpeed() internal view returns(int128) {
        require(RealMath.isUInt64ValidIn64(_data.PRICE_SPEED_PERCENT()));
        require(RealMath.isUInt64ValidIn64(_data.PRICE_SPEED_INTERVAL()));
        
        return RealMath.div(RealMath.fraction(int64(_data.PRICE_SPEED_PERCENT()), 100), RealMath.toReal(int64(_data.PRICE_SPEED_INTERVAL())));
    }


    function calcTotalShareRewardFee(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._shareRewardPercent());
    }
    
    function calcRefBonus(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._refBonusPercent());
    }
    
    function calcTokenOwnerReward(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._tokenOwnerRewardPercent());
    }

    function calcDevReward(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._devRewardPercent());
    }

    function calcQuickPromoBonus(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._quickPromoPercent());
    }    

    function calcBigPromoBonus(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._bigPromoPercent());
    }        


}


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    } 

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }   

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }   
}

//taken from https://github.com/NovakDistributed/macroverse/blob/master/contracts/RealMath.sol and a bit modified
library RealMath {
    
    int64 constant MIN_INT64 = int64((uint64(1) << 63));
    int64 constant MAX_INT64 = int64(~((uint64(1) << 63)));
    
    /**
     * How many total bits are there?
     */
    int256 constant REAL_BITS = 128;
    
    /**
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 64;
    
    /**
     * How many integer bits are there?
     */
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;
    
    /**
     * What&#39;s the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << REAL_FBITS;
    
    /**
     * What&#39;s the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> 1;
    
    /**
     * What&#39;s two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << 1;
    
    /**
     * And our logarithms are based on ln(2).
     */
    int128 constant REAL_LN_TWO = 762123384786;
    
    /**
     * It is also useful to have Pi around.
     */
    int128 constant REAL_PI = 3454217652358;
    
    /**
     * And half Pi, to save on divides.
     * TODO: That might not be how the compiler handles constants.
     */
    int128 constant REAL_HALF_PI = 1727108826179;
    
    /**
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int128 constant REAL_TWO_PI = 6908435304715;
    
    /**
     * What&#39;s the sign bit?
     */
    int128 constant SIGN_MASK = int128(1) << 127;
    

    function getMinInt64() internal pure returns (int64) {
        return MIN_INT64;
    }
    
    function getMaxInt64() internal pure returns (int64) {
        return MAX_INT64;
    }
    
    function isUInt256ValidIn64(uint256 val) internal pure returns (bool) {
        return val >= 0 && val <= uint256(getMaxInt64());
    }
    
    function isInt256ValidIn64(int256 val) internal pure returns (bool) {
        return val >= int256(getMinInt64()) && val <= int256(getMaxInt64());
    }
    
    function isUInt64ValidIn64(uint64 val) internal pure returns (bool) {
        return val >= 0 && val <= uint64(getMaxInt64());
    }
    
    function isInt128ValidIn64(int128 val) internal pure returns (bool) {
        return val >= int128(getMinInt64()) && val <= int128(getMaxInt64());
    }

    /**
     * Convert an integer to a real. Preserves sign.
     */
    function toReal(int64 ipart) internal pure returns (int128) {
        return int128(ipart) * REAL_ONE;
    }
    
    /**
     * Convert a real to an integer. Preserves sign.
     */
    function fromReal(int128 real_value) internal pure returns (int64) {
        int128 intVal = real_value / REAL_ONE;
        require(isInt128ValidIn64(intVal));
        
        return int64(intVal);
    }
    
    
    /**
     * Get the absolute value of a real. Just the same as abs on a normal int128.
     */
    function abs(int128 real_value) internal pure returns (int128) {
        if (real_value > 0) {
            return real_value;
        } else {
            return -real_value;
        }
    }
    
    
    /**
     * Get the fractional part of a real, as a real. Ignores sign (so fpart(-0.5) is 0.5).
     */
    function fpart(int128 real_value) internal pure returns (int128) {
        // This gets the fractional part but strips the sign
        return abs(real_value) % REAL_ONE;
    }

    /**
     * Get the fractional part of a real, as a real. Respects sign (so fpartSigned(-0.5) is -0.5).
     */
    function fpartSigned(int128 real_value) internal pure returns (int128) {
        // This gets the fractional part but strips the sign
        int128 fractional = fpart(real_value);
        return real_value < 0 ? -fractional : fractional;
    }
    
    /**
     * Get the integer part of a fixed point value.
     */
    function ipart(int128 real_value) internal pure returns (int128) {
        // Subtract out the fractional part to get the real part.
        return real_value - fpartSigned(real_value);
    }
    
    /**
     * Multiply one real by another. Truncates overflows.
     */
    function mul(int128 real_a, int128 real_b) internal pure returns (int128) {
        // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
        // So we just have to clip off the extra REAL_FBITS fractional bits.
        return int128((int256(real_a) * int256(real_b)) >> REAL_FBITS);
    }
    
    /**
     * Divide one real by another real. Truncates overflows.
     */
    function div(int128 real_numerator, int128 real_denominator) internal pure returns (int128) {
        // We use the reverse of the multiplication trick: convert numerator from
        // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
        return int128((int256(real_numerator) * REAL_ONE) / int256(real_denominator));
    }
    
    /**
     * Create a real from a rational fraction.
     */
    function fraction(int64 numerator, int64 denominator) internal pure returns (int128) {
        return div(toReal(numerator), toReal(denominator));
    }
    
    // Now we have some fancy math things (like pow and trig stuff). This isn&#39;t
    // in the RealMath that was deployed with the original Macroverse
    // deployment, so it needs to be linked into your contract statically.
    
    /**
     * Raise a number to a positive integer power in O(log power) time.
     * See <https://stackoverflow.com/a/101613>
     */
    function ipow(int128 real_base, int64 exponent) internal pure returns (int128) {
        if (exponent < 0) {
            // Negative powers are not allowed here.
            revert();
        }
        
        // Start with the 0th power
        int128 real_result = REAL_ONE;
        while (exponent != 0) {
            // While there are still bits set
            if ((exponent & 0x1) == 0x1) {
                // If the low bit is set, multiply in the (many-times-squared) base
                real_result = mul(real_result, real_base);
            }
            // Shift off the low bit
            exponent = exponent >> 1;
            // Do the squaring
            real_base = mul(real_base, real_base);
        }
        
        // Return the final result.
        return real_result;
    }
    
    /**
     * Zero all but the highest set bit of a number.
     * See <https://stackoverflow.com/a/53184>
     */
    function hibit(uint256 val) internal pure returns (uint256) {
        // Set all the bits below the highest set bit
        val |= (val >>  1);
        val |= (val >>  2);
        val |= (val >>  4);
        val |= (val >>  8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }
    
    /**
     * Given a number with one bit set, finds the index of that bit.
     */
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
        // We and the value with alternating bit patters of various pitches to find it.
        
        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
            // Picth 1
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
            // Pitch 2
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
            // Pitch 4
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
            // Pitch 8
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
            // Pitch 16
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
            // Pitch 32
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
            // Pitch 64
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
            // Pitch 128
            index |= 128;
        }
    }
    
    /**
     * Shift real_arg left or right until it is between 1 and 2. Return the
     * rescaled value, and the number of bits of right shift applied. Shift may be negative.
     *
     * Expresses real_arg as real_scaled * 2^shift, setting shift to put real_arg between [1 and 2).
     *
     * Rejects 0 or negative arguments.
     */
    function rescale(int128 real_arg) internal pure returns (int128 real_scaled, int64 shift) {
        if (real_arg <= 0) {
            // Not in domain!
            revert();
        }
        
        require(isInt256ValidIn64(REAL_FBITS));
        
        // Find the high bit
        int64 high_bit = findbit(hibit(uint256(real_arg)));
        
        // We&#39;ll shift so the high bit is the lowest non-fractional bit.
        shift = high_bit - int64(REAL_FBITS);
        
        if (shift < 0) {
            // Shift left
            real_scaled = real_arg << -shift;
        } else if (shift >= 0) {
            // Shift right
            real_scaled = real_arg >> shift;
        }
    }
    
    /**
     * Calculate the natural log of a number. Rescales the input value and uses
     * the algorithm outlined at <https://math.stackexchange.com/a/977836> and
     * the ipow implementation.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function lnLimited(int128 real_arg, int max_iterations) internal pure returns (int128) {
        if (real_arg <= 0) {
            // Outside of acceptable domain
            revert();
        }
        
        if (real_arg == REAL_ONE) {
            // Handle this case specially because people will want exactly 0 and
            // not ~2^-39 ish.
            return 0;
        }
        
        // We know it&#39;s positive, so rescale it to be between [1 and 2)
        int128 real_rescaled;
        int64 shift;
        (real_rescaled, shift) = rescale(real_arg);
        
        // Compute the argument to iterate on
        int128 real_series_arg = div(real_rescaled - REAL_ONE, real_rescaled + REAL_ONE);
        
        // We will accumulate the result here
        int128 real_series_result = 0;
        
        for (int64 n = 0; n < max_iterations; n++) {
            // Compute term n of the series
            int128 real_term = div(ipow(real_series_arg, 2 * n + 1), toReal(2 * n + 1));
            // And add it in
            real_series_result += real_term;
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }
        
        // Double it to account for the factor of 2 outside the sum
        real_series_result = mul(real_series_result, REAL_TWO);
        
        // Now compute and return the overall result
        return mul(toReal(shift), REAL_LN_TWO) + real_series_result;
        
    }
    
    /**
     * Calculate a natural logarithm with a sensible maximum iteration count to
     * wait until convergence. Note that it is potentially possible to get an
     * un-converged value; lack of convergence does not throw.
     */
    function ln(int128 real_arg) internal pure returns (int128) {
        return lnLimited(real_arg, 100);
    }
    

     /**
     * Calculate e^x. Uses the series given at
     * <http://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap04/exp.html>.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function expLimited(int128 real_arg, int max_iterations) internal pure returns (int128) {
        // We will accumulate the result here
        int128 real_result = 0;
        
        // We use this to save work computing terms
        int128 real_term = REAL_ONE;
        
        for (int64 n = 0; n < max_iterations; n++) {
            // Add in the term
            real_result += real_term;
            
            // Compute the next term
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));
            
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }
        
        // Return the result
        return real_result;
        
    }

    function expLimited(int128 real_arg, int max_iterations, int k) internal pure returns (int128) {
        // We will accumulate the result here
        int128 real_result = 0;
        
        // We use this to save work computing terms
        int128 real_term = REAL_ONE;
        
        for (int64 n = 0; n < max_iterations; n++) {
            // Add in the term
            real_result += real_term;
            
            // Compute the next term
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));
            
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }

            if (n == k) return real_term;

            // If we somehow never converge I guess we will run out of gas
        }
        
        // Return the result
        return real_result;
        
    }

    /**
     * Calculate e^x with a sensible maximum iteration count to wait until
     * convergence. Note that it is potentially possible to get an un-converged
     * value; lack of convergence does not throw.
     */
    function exp(int128 real_arg) internal pure returns (int128) {
        return expLimited(real_arg, 100);
    }
    
    /**
     * Raise any number to any power, except for negative bases to fractional powers.
     */
    function pow(int128 real_base, int128 real_exponent) internal pure returns (int128) {
        if (real_exponent == 0) {
            // Anything to the 0 is 1
            return REAL_ONE;
        }
        
        if (real_base == 0) {
            if (real_exponent < 0) {
                // Outside of domain!
                revert();
            }
            // Otherwise it&#39;s 0
            return 0;
        }
        
        if (fpart(real_exponent) == 0) {
            // Anything (even a negative base) is super easy to do to an integer power.
            
            if (real_exponent > 0) {
                // Positive integer power is easy
                return ipow(real_base, fromReal(real_exponent));
            } else {
                // Negative integer power is harder
                return div(REAL_ONE, ipow(real_base, fromReal(-real_exponent)));
            }
        }
        
        if (real_base < 0) {
            // It&#39;s a negative base to a non-integer power.
            // In general pow(-x^y) is undefined, unless y is an int or some
            // weird rational-number-based relationship holds.
            revert();
        }
        
        // If it&#39;s not a special case, actually do it.
        return exp(mul(real_exponent, ln(real_base)));
    }
}