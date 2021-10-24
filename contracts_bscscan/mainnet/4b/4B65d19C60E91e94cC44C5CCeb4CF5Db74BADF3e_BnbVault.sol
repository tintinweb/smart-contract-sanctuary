//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract WingsToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract EthereumToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract BnbToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
}

contract ApeSwapRouter
{
    function swapExactTokensForTokens(
                 uint,
                 uint,
                 address[] calldata,
                 address,
                 uint
             ) external virtual returns (uint[] memory) {}
}

contract JetSwapRouter
{
    function swapExactTokensForTokens(
                 uint,
                 uint,
                 address[] calldata,
                 address,
                 uint
             ) external virtual returns (uint[] memory) {}
}

contract GoFarm
{
    function donate(uint256) external {}
}

contract MasterChef
{
    function enterStaking(uint256) public {}
    function leaveStaking(uint256) public {}
}

contract BnbVault 
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x42\x4e\x42\x20\x56\x61\x75\x6c\x74";
    uint256 private _swapWaitingSeconds = 3600;
    uint256 private _depositFee = 10; //Deposit fee: 10%
    uint256 private _performanceFee = 1; //Performance fee: 1%
    uint256 private _autoCompoundFee = 33; //Auto-compound fee: 33%
    uint256 private _harvestCooldownBlocks = 28800;
    uint256 private _stakingBlockRange = 864000;
    uint256 private _decimalFixMultiplier = 1000000000000000000;
    uint256 private _updateCooldownBlocks = 1200;

    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
    
    address private _goTokenAddress = 0x1D296721f12af38d35F1663113373D98CCC96635;
    address private _wingsTokenAddress = 0x0487b824c8261462F88940f97053E65bDb498446;
    address private _ethereumTokenAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Cake
    address private _bnbTokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private _apeSwapRouterAddress = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    address private _jetSwapRouterAddress = 0xBe65b8f75B9F20f4C522e0067a3887FADa714800;
    address private _goFarmAddress = 0xaaAa30ebf45fA0996fdbe000824A919B57a4cBF4;
    address private _masterChefAddress = 0x63d6EC1cDef04464287e2af710FFef9780B6f9F5;
        
    GoToken       private _goToken;
    WingsToken    private _wingsToken;
    EthereumToken private _ethereumToken;
    BnbToken      private _bnbToken;
    ApeSwapRouter private _apeSwapRouter;
    JetSwapRouter private _jetSwapRouter;
    GoFarm        private _goFarm;
    MasterChef    private _masterChef;
    
    address[] private _bnbWingsPair;
    address[] private _wingsBnbPair;
    address[] private _wingsEthPair;
    address[] private _ethGoPair;
   
    constructor()
    {
        //Initialize contracts
        _goToken = GoToken(_goTokenAddress);
        _wingsToken = WingsToken(_wingsTokenAddress);
        _ethereumToken = EthereumToken(_ethereumTokenAddress);
        _bnbToken = BnbToken(_bnbTokenAddress);
        _apeSwapRouter = ApeSwapRouter(_apeSwapRouterAddress);
        _jetSwapRouter = JetSwapRouter(_jetSwapRouterAddress);
        _goFarm = GoFarm(_goFarmAddress);
        _masterChef = MasterChef(_masterChefAddress);
        
        //Initialize trading pairs
        _bnbWingsPair = [_bnbTokenAddress,      _wingsTokenAddress];
        _wingsBnbPair = [_wingsTokenAddress,    _bnbTokenAddress];
        _wingsEthPair = [_wingsTokenAddress,    _bnbTokenAddress, _ethereumTokenAddress];
        _ethGoPair    = [_ethereumTokenAddress, _bnbTokenAddress, _goTokenAddress];
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _bnbToken.balanceOf(address(this)) - _totalStakingDeposits;
    }
    
    function getTotalStakingDeposits() external view returns (uint256)
    {
        return _totalStakingDeposits;
    }
    
    function getDepositFee() external view returns (uint256)
    {
        return _depositFee;
    }
    
    function getHarvestCooldownBlocks() external view returns (uint256)
    {
        return _harvestCooldownBlocks;
    }
    
    function getStakingBlockRange() external view returns (uint256)
    {
        return _stakingBlockRange;
    } 
    
    function buyGoToken(uint256 wingsAmount) private
    {
        require(wingsAmount > 0, "BnbVault: Wings amount cannot be 0");
    
        address[] memory wingsEthPairMemory = _wingsEthPair;
        address[] memory ethGoPairMemory = _ethGoPair;
        
        //Swap Wings for Ethereum
        _wingsToken.approve(_jetSwapRouterAddress, wingsAmount);
        _jetSwapRouter.swapExactTokensForTokens(wingsAmount, 0, wingsEthPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        uint256 ethAmount = _ethereumToken.balanceOf(address(this));
        
        //Swap Ethereum for Gō
        _ethereumToken.approve(_apeSwapRouterAddress, ethAmount);
        _apeSwapRouter.swapExactTokensForTokens(ethAmount, 0, ethGoPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Donate to Gō farm
        uint256 goAmount = _goToken.balanceOf(address(this));
        
        if (goAmount > 0)
        {
            _goToken.approve(_goFarmAddress, goAmount);
            _goFarm.donate(goAmount);
        }
    }
    
    function updateRewardsFund() private
    {
        uint256 elapsedBlocks = block.number - _lastUpdate;
    
        if (elapsedBlocks > _updateCooldownBlocks)
        {
            address[] memory wingsBnbPairMemory = _wingsBnbPair;
                
            //Harvest pending Wings
            _masterChef.leaveStaking(0);
            
            uint256 wingsAmount = _wingsToken.balanceOf(address(this));
            
            uint256 performanceFeeAmount = wingsAmount * _performanceFee / 100;
            uint256 autoCompoundFeeAmount = wingsAmount * _autoCompoundFee / 100;
            
            //Buy Gō and donate it to Gō farm
            if (performanceFeeAmount > 0)
                buyGoToken(performanceFeeAmount);
                
            //Auto-compound
            if (autoCompoundFeeAmount > 0)
            {
                _wingsToken.approve(_masterChefAddress, autoCompoundFeeAmount);
                _masterChef.enterStaking(autoCompoundFeeAmount);
            }
            
            //Swap Wings for Bnb
            wingsAmount = _wingsToken.balanceOf(address(this));
            
            if (wingsAmount > 0)
            {
                _wingsToken.approve(_jetSwapRouterAddress, wingsAmount);
                _jetSwapRouter.swapExactTokensForTokens(wingsAmount, 0, wingsBnbPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "BnbVault: minimum deposit amount: 100");
        
        _bnbToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update Vault data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap deposit fee for Wings
        address[] memory bnbWingsPairMemory = _bnbWingsPair;
        
        _bnbToken.approve(_jetSwapRouterAddress, fee);
        _jetSwapRouter.swapExactTokensForTokens(fee, 0, bnbWingsPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Deposit Wings on JetSwap Pool
        uint256 wingsAmount = _wingsToken.balanceOf(address(this));
            
        if (wingsAmount > 0)
        {
            _wingsToken.approve(_masterChefAddress, wingsAmount);
            _masterChef.enterStaking(wingsAmount);
        }
        
        //Update rewards fund
        updateRewardsFund();
    }

    function withdraw() external
    {
        uint256 blocksStaking = computeBlocksStaking();

        if (blocksStaking > _harvestCooldownBlocks)
            harvest();
        
        emergencyWithdraw();
    }
    
    function emergencyWithdraw() public
    {
        uint256 stakingDeposit = _userData[msg.sender].stakingDeposit;
        
        require(stakingDeposit > 0, "BnbVault: withdraw amount cannot be 0");
        
        _userData[msg.sender].stakingDeposit = 0;
 
        _bnbToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "BnbVault: staking deposit is 0");
    
        uint256 rewardsFund = getRewardsFund();
        
        uint256 userReward = 0;
    
        uint256 blocksStaking = computeBlocksStaking();
        
        if (blocksStaking > 0)
	    {
	        uint256 userBlockRatio = _decimalFixMultiplier;
	    
	        if (blocksStaking < _stakingBlockRange)
	            userBlockRatio = blocksStaking * _decimalFixMultiplier / _stakingBlockRange; 
		    
		    uint256 userDepositRatio = _decimalFixMultiplier;
		    
		    if (_userData[msg.sender].stakingDeposit < _totalStakingDeposits)
		        userDepositRatio = _userData[msg.sender].stakingDeposit * _decimalFixMultiplier / _totalStakingDeposits;
		    
		    uint256 totalRatio = userBlockRatio * userDepositRatio / _decimalFixMultiplier;
		    
		    userReward = totalRatio * rewardsFund / _decimalFixMultiplier;
		}
		
		return userReward;
    }

    function harvest() public 
    {
        require(_userData[msg.sender].stakingDeposit > 0, "BnbVault: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "BnbVault: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        _bnbToken.transfer(msg.sender, userReward);
    }
    
    function getStakingDeposit() external view returns (uint256)
    {
        UserData memory userData = _userData[msg.sender];
    
        return (userData.stakingDeposit);
    }
    
    function getStakingBlock() external view returns (uint256)
    {
        UserData memory userData = _userData[msg.sender];
    
        return (userData.stakingBlock);
    }
    
    function computeBlocksStaking() public view returns (uint256)
    {
        uint256 blocksStaking = 0;
        
        if (_userData[msg.sender].stakingDeposit > 0)
            blocksStaking = block.number - _userData[msg.sender].stakingBlock;
        
        return blocksStaking;
    }
}