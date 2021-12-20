/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;


interface IFarmController {
    function notifyFarm(uint amount) external;
}
interface IEventBroadcaster {
    function broadcastEvent(bool isDeposit, bool isWithdrawl, bool isClaim, uint currentLiquidity, uint liquidity, address user, address pool) external;
}
interface IUP {

    function mint(address to, uint256 value) external payable returns(bool);

    function balanceOf(address owner) external view returns(uint256);

    function transfer(address _to, uint amount) external returns(bool);

    function transferFrom(address from, address to, uint value) external returns(bool);
}

interface IWETH {
    function approve(address to, uint value) external;

    function balanceOf(address owner) external view returns(uint256);

    function withdraw(uint amount) external;
}

interface IUnifiPair {
    function totalSupply() external view returns(uint256);

    function balanceOf(address owner) external view returns(uint256);

    function token0() external view returns(address);

    function token1() external view returns(address);
}

interface IUnifiFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external returns(address);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    
    function feeController() external view returns (address);
    function router() external view returns (address);
}

contract UnifiController {

    address public feeSetter;
    address public WBNB;
    address public UNIFIUPVault;
    address public nativeFeeTo;
    uint public defaultBuyBackAmount = 1000;
    IFarmController public ifc;
    IEventBroadcaster public ieb;
    IUP public uptoken;
    address payable uptokenAddress;
    uint public pendingUPPlatformClaimable = 0;

    address public defaultUPFeesTo;
    mapping(address => uint) public UPPoolFees;
    uint public maxFee = 1000; //100%
    uint public defaultMintRate = 9700; //55% -- max is 10000
    uint public defaultFee = 3; // max is 1000
    uint public defaultUPFee = 1500; // 10%  -- max is 10000
    uint public defaultMintFeeNumerator = 8;//0.32%
    uint public defaultMintFeeDenominator = 17;
    bool public defaultMintUPinClaim = false;
    uint public defaultNativeFee = 100;
    address public owner;

    mapping(address => bool) public admin;
    mapping(address => uint) public pairFees;
    mapping(address => uint) public nativeFees;
    mapping(address => bool) private isNotUPMintable;
    mapping(address => bool) public otherPairsUPMintable;
    mapping(address => bool) public flashLoan;
    mapping(address => bool) public poolPaused;
    mapping(address => uint) public UPMintrate;
    mapping(address => uint) public UPFee;
    mapping(address => uint) public mintFeeNumerator;
    mapping(address => uint) public mintFeeDenominator;




    address public defaultFarmPoolAddress;
    uint public totalUPTokenminted = 0;
    bool public broadcastEnabled = false;
    bool public farmEnabled = false;
    uint public currentNativeTokensHoldings = 0 ;
    mapping(address => uint) public lp_RewardPerToken;
    mapping(address => uint) public lp_FeeState;
    mapping(address => uint) public lp_LastTrade;
    mapping(address => uint) public lp_UPRemaining;//manually update it
    mapping(address => uint) public lp_TotalClaim;
    mapping(address =>bool) public mintUPinClaim;
    mapping(address =>bool) public lp_poolMigration;
    mapping(address =>uint) public lp_nativeTokensAccumulated;

    mapping(address => mapping(address => uint)) public lp_userState;
    mapping(address => mapping(address => uint)) public lp_userLastAction;
    mapping(address => mapping(address => uint)) public lp_userTotalClaim;

    mapping(address => address[]) private lp_pathToTrade;




    event SwapFeesUpminted(address indexed pool, uint amountUPMinted, address defaultPoolAddress, uint platforUPFees);
    event UpdatePoolRewards(address indexed pool, uint rewards);


    constructor(address _wbnb, address _up_address) {
        feeSetter = msg.sender;
        WBNB = _wbnb;
        owner = msg.sender;
        nativeFeeTo = msg.sender;
        admin[msg.sender] = true;
        defaultUPFeesTo = msg.sender;
        UNIFIUPVault = address(this);
        uptoken = IUP(payable(address(_up_address)));
      
        
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Unifi : Only Owner");
        _;
    }

    modifier onlyAdmin() {
        require(owner == msg.sender ||  admin[msg.sender] == true, "Unifi : Only Admins" );
        _;
    }
    function setFeeSetter(address _feeSetter) onlyOwner external {
        require(msg.sender == owner, 'Unifi: FORBIDDEN');
        feeSetter = _feeSetter;
    }
    
    function setUPToken(address _tokenAddr) onlyOwner external{//for UP v2 migration
        require(msg.sender == owner , 'Unifi: FORBIDDEN');
        uptoken = IUP(payable(address(_tokenAddr)));
    }


    function setPairFee(address _pair, uint _fee) external onlyAdmin{
        pairFees[_pair] = _fee > maxFee ? maxFee : _fee;
    }

    function setUPNotMintable(address _pair, bool _value, uint _mintRate) external  onlyAdmin {
        isNotUPMintable[_pair] = _value;
        UPMintrate[_pair] = _mintRate; //default is 1000
    }

    function setUPOtherPairsNotMintable(address _pair, bool _value, uint _mintRate) external onlyAdmin{
        require(msg.sender == feeSetter || admin[msg.sender] == true, 'Unifi: FORBIDDEN');
        otherPairsUPMintable[_pair] = _value;
        UPMintrate[_pair] = _mintRate; //default is 1000
    }

    function updateNotUPMintable(address _pair, bool _value) external onlyAdmin {
        isNotUPMintable[_pair] = _value;

    }

    function updateotherPairsUPMintable(address _pair, bool _value) external onlyAdmin {
        otherPairsUPMintable[_pair] = _value;

    }
    
    function updateMintUPinClaim(address _pair, bool _value) external onlyAdmin {
        mintUPinClaim[_pair] = _value;

    }

    function updateDefaultMintUPinClaim( bool _value) external onlyAdmin {
        defaultMintUPinClaim = _value;

    }
    function updateFlashLoan(address _pair, bool _value) external onlyAdmin {
        flashLoan[_pair] = _value;

    }

    function setMaxFee(uint _fee) external onlyAdmin {
        maxFee = _fee;
    }

    function setDefaultFee(uint _fee) external  onlyAdmin{
        defaultFee = _fee;
    }


    function setDefaultUPFee(uint _fee) external onlyAdmin {
        defaultUPFee = _fee;
    }

    function setUPPoolPlatformfee(uint _fee, address _pool) external onlyAdmin {
        UPPoolFees[_pool] = _fee;
    }


    function setDefaultUPFeeTo(address _wallet) external onlyAdmin {
        defaultUPFeesTo = _wallet;
    }


    function setNativeFeeTo(address _nativeFeeTo) external onlyAdmin{
        nativeFeeTo = _nativeFeeTo;
    }

    function setBNB(address _wrap) external onlyOwner{
        WBNB = _wrap;
    }

    function setUNIFIUPVault(address _UNIFIUPVault) external onlyOwner {
        UNIFIUPVault = _UNIFIUPVault;
    }

    function getPairFee(address _pair) external view returns(uint fees) {

        fees = pairFees[_pair] > 0 ? pairFees[_pair] : defaultFee;
    }

    function getPairUPFee(address _pair) external view returns(uint fees) {

        fees = UPPoolFees[_pair] > 0 ? UPPoolFees[_pair] : defaultUPFee;
    }

    function getNativeFee(address _pair) external view returns(uint fees) {
        fees = nativeFees[_pair] > 0 ? nativeFees[_pair] : defaultNativeFee;
    }

    function addAdmin(address _admin) external onlyOwner {
        admin[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admin[_admin] = false;
    }

    function isDisableFlashLoan(address pool) external view returns(bool) {
        return flashLoan[pool];

    }

    function getMintFeeConfig(address _pool) external view returns(uint numerator, uint denominator) {
        numerator = defaultMintFeeNumerator;
        denominator = defaultMintFeeDenominator;
        if (mintFeeNumerator[_pool] > 0) {
            numerator = mintFeeNumerator[_pool];
        }
        if (mintFeeDenominator[_pool] > 0) {
            denominator = mintFeeDenominator[_pool];
        }

    }

    function setDefaultMintFeeConf(uint _numerator, uint _denominator) external  onlyAdmin{
        defaultMintFeeNumerator = _numerator;
        defaultMintFeeDenominator = _denominator;
    }

    function setDefaultMintRate(uint _value) external  onlyAdmin{
        defaultMintRate = _value;
    }

    function getMintRate(address _pool) external view returns(uint) {
        return (UPMintrate[_pool] > 0 ? UPMintrate[_pool] : defaultMintRate);
    }

    function setMintFeeConf(uint _numerator, uint _denominator, address _pool) external onlyAdmin {
        mintFeeNumerator[_pool] = _numerator;
        mintFeeDenominator[_pool] = _denominator;
    }

    function setTradingStatusConf(address _pool, bool value) external onlyAdmin{
        poolPaused[_pool] = value;
    }

    function updateLPFeeState(address _lp, uint _value) external onlyOwner returns(bool)  {
        lp_FeeState[_lp] = _value;
        return true;
    }

    function updateLPLastTrade(address _lp, uint _value) external  onlyOwner returns(bool)  {
        require(msg.sender == owner);
        lp_LastTrade[_lp] = _value;
        return true;
    }


    function updateLPLUPRemaining(address _lp, uint _value) external onlyOwner returns(bool) {
        lp_UPRemaining[_lp] = _value;
        return true;
    }



    function _mintNativeUP(address _from, uint _ethAtm) internal returns(uint) {
        require(_ethAtm > 0, "Trying to mint with 0 value"); //<!! Important
        require(this.UPMintable(_from), "Error: ONLY whitelisted");
        uint beforeUpBalance = uptoken.balanceOf(address(this));
        _ethAtm = _ethAtm * this.getMintRate(_from) / 10000;
        uptoken.mint {
            value: _ethAtm
        }(address(this), _ethAtm);

        uint dust = getProxyNativeBalance();
        if (dust > 0) payable(address(uptoken)).transfer(dust);
        return (uptoken.balanceOf(address(this)) - beforeUpBalance);

    }

    function _mintUPinBulk(address _pool ) internal returns(uint) {
        if(lp_nativeTokensAccumulated[_pool] == 0 ){
            return 0;
        }
        if(this.UPMintable(_pool) == false){
            return 0 ;
        }
        uint beforeUpBalance = uptoken.balanceOf(address(this));
        uint _ethAtm = lp_nativeTokensAccumulated[_pool]  * this.getMintRate(_pool) / 10000;
        uptoken.mint {
            value: _ethAtm
        }(address(this), _ethAtm);
        if(lp_nativeTokensAccumulated[_pool] > _ethAtm ){
            uint dust =  lp_nativeTokensAccumulated[_pool] - _ethAtm;
            if (dust > 0) payable(address(uptoken)).transfer(dust);           
        }
        currentNativeTokensHoldings = currentNativeTokensHoldings- lp_nativeTokensAccumulated[_pool];
        lp_nativeTokensAccumulated[_pool] = 0 ;
        return (uptoken.balanceOf(address(this)) - beforeUpBalance);
        
        
    }

    //for future implementation
    function mintNativeUP(address _to) public payable returns(uint) {
        uint upMinted = _mintNativeUP(msg.sender, msg.value);
        uptoken.transfer(_to, upMinted);
        return upMinted;


    }

    function getProxyNativeBalance() view public returns(uint){
         return (address(this).balance - currentNativeTokensHoldings);
    }

    function mintPendingUP(address _pool) external returns(uint){
       uint upMintedForLiquidityPool = _mintUPinBulk(_pool);
       if(upMintedForLiquidityPool  > 0 ){
         uint upAddedToPool = 0;
         if (defaultFarmPoolAddress != address(0) && _pool != defaultFarmPoolAddress) {
            upAddedToPool = (upMintedForLiquidityPool * this.getPairUPFee(_pool)) / (10000);
            pendingUPPlatformClaimable = pendingUPPlatformClaimable + upAddedToPool;
            upMintedForLiquidityPool = upMintedForLiquidityPool - upAddedToPool;
         }
         uint rewardPerToken = upMintedForLiquidityPool * (1e18) / (IUnifiPair(_pool).totalSupply());
         _updatePoolStatus(_pool, upMintedForLiquidityPool,rewardPerToken) ;
         emit SwapFeesUpminted(_pool, upMintedForLiquidityPool, defaultFarmPoolAddress, upAddedToPool);         
       }
        return upMintedForLiquidityPool;
    }

    function mintUP(address _to) public payable returns(uint) {
        require(_to == msg.sender, "Unifi: Invalid params");
        if (!this.UPMintable(msg.sender)) {
            return 0;
        }
         lp_LastTrade[msg.sender] = block.timestamp;
        if(mintUPinClaim[msg.sender] == true || defaultMintUPinClaim == true){
           //getCurrentProxyAmount
            uint newBalance = getProxyNativeBalance() ;
            lp_nativeTokensAccumulated[msg.sender] =  lp_nativeTokensAccumulated[msg.sender]  + newBalance;
            currentNativeTokensHoldings = currentNativeTokensHoldings + newBalance;
            return 0;// no UP was minted
        }else{
         uint upMintedForLiquidityPool = _mintNativeUP(msg.sender, getProxyNativeBalance());
         uint upAddedToPool = 0;
         if (defaultFarmPoolAddress != address(0) && msg.sender != defaultFarmPoolAddress) {
            upAddedToPool = (upMintedForLiquidityPool * this.getPairUPFee(msg.sender)) / (10000);
            pendingUPPlatformClaimable = pendingUPPlatformClaimable + upAddedToPool;
            upMintedForLiquidityPool = upMintedForLiquidityPool - upAddedToPool;
         }
         uint rewardPerToken = upMintedForLiquidityPool * (1e18) / (IUnifiPair(msg.sender).totalSupply());
         _updatePoolStatus(_to, upMintedForLiquidityPool,rewardPerToken) ;
         emit SwapFeesUpminted(msg.sender, upMintedForLiquidityPool, defaultFarmPoolAddress, upAddedToPool);

         return upMintedForLiquidityPool;           
        }

    }

    function _notifyDefaultPoolRewards() internal returns(bool) {
        if (defaultFarmPoolAddress != address(0)) {
            uint rewardPerToken = pendingUPPlatformClaimable * (1e18) / (IUnifiPair(defaultFarmPoolAddress).totalSupply());
            _updatePoolStatus( defaultFarmPoolAddress,  pendingUPPlatformClaimable,rewardPerToken);           
            pendingUPPlatformClaimable = 0;
            emit UpdatePoolRewards(defaultFarmPoolAddress, pendingUPPlatformClaimable);
            return true;
        }
        return false;
    }

    function notifyOtherPoolRewards(address _pool, uint _upAmount) payable external returns(bool) {
        uptoken.transferFrom(msg.sender, address(this), _upAmount);
        uint rewardPerToken = _upAmount * (1e18) / (IUnifiPair(_pool).totalSupply());
        _updatePoolStatus( _pool,  _upAmount,rewardPerToken);
        emit UpdatePoolRewards(_pool, _upAmount);
        return true;
    }
    
    function _updatePoolStatus(address _pool, uint _upAmount,uint rewardPerToken) internal {
        lp_RewardPerToken[_pool] = lp_RewardPerToken[_pool] + (rewardPerToken);
        lp_FeeState[_pool] = lp_FeeState[_pool] + (_upAmount);
        lp_UPRemaining[_pool] = lp_UPRemaining[_pool] + (_upAmount);      
    }

    function updateDefaultPool(address _newPool) external onlyOwner returns(bool) {
        defaultFarmPoolAddress = _newPool;
        return true;
    }

    function updateMultipleUpdatePoolDetails(address[] memory _pools, uint[] memory _rewardPerTokens, uint[] memory _feeStates, uint[] memory _lastTrades, uint[] memory _upRemainings, uint[] memory _totalClaims,bool [] memory  _mintUPinClaim,uint[] memory _lp_nativeTokensAccumulated) onlyOwner  external {
        uint i = 0;
        while (i < _pools.length) {
            _updatePoolDetails(_pools[i], _rewardPerTokens[i], _feeStates[i], _lastTrades[i], _upRemainings[i], _totalClaims[i] ,  _mintUPinClaim[i],_lp_nativeTokensAccumulated[i]);
            i++;
        }

    }

    function _updatePoolDetails(address _pool, uint _rewardPerToken, uint _feeState, uint _lastTrade, uint _upRemaining, uint _totalClaim , bool _mintUPinClaim, uint _lp_nativeTokensAccumulated) internal returns(bool) {
        if(lp_RewardPerToken[_pool] != _rewardPerToken){
            lp_RewardPerToken[_pool] = _rewardPerToken;            
        }
        if(lp_FeeState[_pool] != _feeState){
            lp_FeeState[_pool] = _feeState;
        }
        if(lp_LastTrade[_pool] != _lastTrade){
            lp_LastTrade[_pool] = _lastTrade;
        }
        if(lp_UPRemaining[_pool] != _upRemaining){
            lp_UPRemaining[_pool] = _upRemaining;            
        }
        if(lp_TotalClaim[_pool] != _totalClaim){
            lp_TotalClaim[_pool] = _totalClaim;         
        }
        if(mintUPinClaim[_pool] != _mintUPinClaim){
            mintUPinClaim[_pool] = _mintUPinClaim;         
        }
        if(lp_nativeTokensAccumulated[_pool] != _lp_nativeTokensAccumulated){
            lp_nativeTokensAccumulated[_pool] = _lp_nativeTokensAccumulated;         
        }

        return true;
    }


    function updatePoolFeeDetails(address _pool, uint _pairFees, bool _otherPairsUPMintable, uint _UPMintrate) external  onlyOwner returns(bool) {
        if(pairFees[_pool] != _pairFees){
            pairFees[_pool] = _pairFees;            
        }
        if(otherPairsUPMintable[_pool] != _otherPairsUPMintable){
            otherPairsUPMintable[_pool] = _otherPairsUPMintable;            
        }
        if(UPMintrate[_pool] != _UPMintrate){
            UPMintrate[_pool] = _UPMintrate;            
        }

        return true;
    }

    function updateDefaultDetails(uint _maxFee, uint _defaultMintRate, uint _defaultFee , uint _defaultUPFee ,  uint _defaultMintFeeNumerator,uint _defaultMintFeeDenominator,uint _totalUPTokenminted ,uint _currentNativeTokensHoldings) external  onlyOwner returns(bool) {
        maxFee = _maxFee; //100%
         defaultMintRate = _defaultMintRate; 
         defaultFee = _defaultFee; // max is 1000
         defaultUPFee = _defaultUPFee; // 10%  -- max is 10000
         defaultMintFeeNumerator = _defaultMintFeeNumerator;//0.32%
         defaultMintFeeDenominator = _defaultMintFeeDenominator;
         totalUPTokenminted = _totalUPTokenminted;
         currentNativeTokensHoldings = _currentNativeTokensHoldings ;
        return true;
    }



    function updateMultipleUpdateUserPoolDetails(address[] memory _pools, address[] memory _users, uint[] memory _lp_userStates, uint[] memory _lp_userLastActions, uint[] memory _lp_userTotalClaims)onlyOwner external {
        uint i = 0;
        while (i < _pools.length) {
            this.updateUserPoolDetails(_pools[i], _users[i], _lp_userStates[i], _lp_userLastActions[i], _lp_userTotalClaims[i]);
            i++;
        }

    }

    function updateUserPoolDetails(address _pool, address _user, uint _lp_userState, uint _lp_userLastAction, uint _lp_userTotalClaim) external onlyOwner returns(bool) {
        lp_userState[_pool][_user] = _lp_userState;
        lp_userLastAction[_pool][_user] = _lp_userLastAction;
        lp_userTotalClaim[_pool][_user] = _lp_userTotalClaim;

        return true;
    }

    function pendingUpRewards(address _user, address _pool) external view returns(uint256) {
            if ( IUnifiPair(_pool).balanceOf(_user) == 0) {
                return 0;
            } else {
                return (lp_RewardPerToken[_pool] - (lp_userState[_pool][_user])) * (IUnifiPair(_pool).balanceOf(_user)) / (1e18); // up decimal places      
            }



    }



    function broadcastEvent(bool isDeposit, bool isWithdrawl, bool isClaim, uint currentLiquidity, uint liquidity, address user, address pool) internal returns(bool) {
        this.claimPlatformUPFees();
        if (broadcastEnabled) {
            ieb.broadcastEvent(isDeposit, isWithdrawl, isClaim, currentLiquidity, liquidity, user, pool); //
        }
        return true;
    }

    function claimPlatformUPFees() public {
        if (pendingUPPlatformClaimable > 0) {
            if (farmEnabled) {
                uptoken.transfer(this.defaultUPFeesTo(), pendingUPPlatformClaimable);
                ifc.notifyFarm(pendingUPPlatformClaimable); //
                pendingUPPlatformClaimable = 0;
            } else { //default
                _notifyDefaultPoolRewards();
            }

        }

    }

    function updateFarmEnabled(address farmAddress, bool value) onlyOwner external {
        ifc = IFarmController(farmAddress);
        farmEnabled = value;

    }

    function updateBroadCaseEnabled(address _broadcastAddress, bool _value) onlyOwner external {
        ieb = IEventBroadcaster(_broadcastAddress);
        broadcastEnabled = _value;

    }


    function transferOwnership(address _newOwner)onlyOwner  external {
        owner = _newOwner;

    }

    function emergencyWithdraw(address _tokens , uint _amount) onlyOwner external{
        IUP(_tokens).transfer(owner,_amount);
        
    }
    function claimUP(address _user, address _receipient, uint _liquidity, bool _isDeposit, bool _isWithdrawl, bool _isClaim) public returns(uint) {
        this.mintPendingUP( msg.sender);

        uint currentLiquidity = IUnifiPair(msg.sender).balanceOf(_user);
        uint upRewards = _claimUP(_user, msg.sender,_user);
        broadcastEvent(_isDeposit, _isWithdrawl, _isClaim, currentLiquidity, _liquidity, _user, msg.sender);
        return upRewards;
    }

    function claimUP(address _user, address _upRecipient, address _pool) public returns(uint) {
        require(msg.sender == _user, 'Unifi: FORBIDDEN');
        this.mintPendingUP( _pool);
        uint currentLiquidity = IUnifiPair(_pool).balanceOf(_user);
        uint upRewards = _claimUP(_user, _pool,_upRecipient);
        broadcastEvent(false, false, true, currentLiquidity, currentLiquidity, _user, _pool);
        return upRewards;
    }

    function _claimUP(address _user, address _pool, address _upRecipient) internal returns(uint) {
        uint upRewards = this.pendingUpRewards(_user, _pool);
        if (upRewards > 0) {
            uptoken.transfer(_upRecipient, upRewards);
        }
        _updateUserRewards(_pool, _user, upRewards);
        return upRewards;
    }

    function _updateUserRewards(address _pool, address _user, uint _upRewards) internal {
        if (_upRewards > 0) {
            lp_UPRemaining[_pool] = lp_UPRemaining[_pool] - (_upRewards);
            lp_userTotalClaim[_pool][_user] = lp_userTotalClaim[_pool][_user] + (_upRewards);
            lp_TotalClaim[_pool] = lp_TotalClaim[_pool] + (_upRewards);
        }
        if(lp_RewardPerToken[_pool]  == 0 && lp_userState[_pool][_user] == 0 ){//initialize state
            lp_RewardPerToken[_pool] = 1;
        }
        lp_userState[_pool][_user] = lp_RewardPerToken[_pool];
        lp_userLastAction[_pool][_user] = block.timestamp;
    }

    function updateFeeState(uint _fee) external returns(bool) {
        require(msg.sender == address(uptoken), 'updateFeetate : NOT_AUTHORIZED');
        if (_fee > 0) {
            totalUPTokenminted = totalUPTokenminted + (_fee);
        }
        return true;

    }

    function pathToTrade(address _pool) external view returns(address[] memory path) {
        path = lp_pathToTrade[_pool];

    }

    function updateLPPath(address _pair, address[] memory _path) external onlyOwner returns(bool) {
        require(_path[_path.length - 1] == this.WBNB(), ' require to be WBNB');
        lp_pathToTrade[_pair] = _path;
        return true;
    }

    function UPMintable(address _pool) public view returns(bool) {
        // check is it not up mintable    
        if (isNotUPMintable[_pool]) {
            return false;
        }

        if (otherPairsUPMintable[_pool] == true) {
            return true;
        } else if (IUnifiPair(_pool).token0() == WBNB || IUnifiPair(_pool).token1() == WBNB) { // contract address UPmintable does not have wbnb pair {
            return true;

        } else {
            return false;
        }


    }




    fallback() external payable {

    }

    receive() external payable {

    }
    
   
   
}