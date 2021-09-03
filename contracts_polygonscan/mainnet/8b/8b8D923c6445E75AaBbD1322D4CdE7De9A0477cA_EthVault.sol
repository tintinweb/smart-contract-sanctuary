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
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
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

contract EthVault 
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x45\x74\x68\x65\x72\x65\x75\x6d\x20\x56\x61\x75\x6c\x74";
    uint256 private _swapWaitingBlocks = 3600;
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
    
    address private _goTokenAddress = 0x98D23ADA1Da268Bc10E2e0d1585C47971C4B89DD;
    address private _wingsTokenAddress = 0x845E76A8691423fbc4ECb8Dd77556Cb61c09eE25;
    address private _ethereumTokenAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private _maticTokenAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private _jetSwapRouterAddress = 0x5C6EC38fb0e2609672BDf628B1fD605A523E5923;
    address private _goFarmAddress = 0x05C1EC18455dB5edcf1389B8fC215d56B42A15C0;
    address private _masterChefAddress = 0x4e22399070aD5aD7f7BEb7d3A7b543e8EcBf1d85;
        
    GoToken       private _goToken;
    WingsToken    private _wingsToken;
    EthereumToken private _ethereumToken;
    JetSwapRouter private _jetSwapRouter;
    GoFarm        private _goFarm;
    MasterChef    private _masterChef;
    
    address[] private _ethereumWingsPair;
    address[] private _wingsGoPair;
    address[] private _wingsEthereumPair;
   
    constructor()
    {
        //Initialize contracts
        _goToken = GoToken(_goTokenAddress);
        _wingsToken = WingsToken(_wingsTokenAddress);
        _ethereumToken = EthereumToken(_ethereumTokenAddress);
        _jetSwapRouter = JetSwapRouter(_jetSwapRouterAddress);
        _goFarm = GoFarm(_goFarmAddress);
        _masterChef = MasterChef(_masterChefAddress);
        
        //Initialize trading pairs
        _ethereumWingsPair = [_ethereumTokenAddress, _maticTokenAddress, _wingsTokenAddress];
        _wingsGoPair       = [_wingsTokenAddress, _maticTokenAddress, _goTokenAddress];
        _wingsEthereumPair = [_wingsTokenAddress, _maticTokenAddress, _ethereumTokenAddress];
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _ethereumToken.balanceOf(address(this)) - _totalStakingDeposits;
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
        require(wingsAmount > 0, "EthVault: Wings amount cannot be 0");
    
        address[] memory wingsGoPairMemory = _wingsGoPair;
        
        //Swap Wings for Gō
        _wingsToken.approve(_jetSwapRouterAddress, wingsAmount);
        _jetSwapRouter.swapExactTokensForTokens(wingsAmount, 0, wingsGoPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
        
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
            address[] memory wingsEthereumPairMemory = _wingsEthereumPair;
                
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
            
            //Swap Wings for Ethereum
            wingsAmount = _wingsToken.balanceOf(address(this));
            
            if (wingsAmount > 0)
            {
                _wingsToken.approve(_jetSwapRouterAddress, wingsAmount);
                _jetSwapRouter.swapExactTokensForTokens(wingsAmount, 0, wingsEthereumPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "EthVault: minimum deposit amount: 100");
        
        _ethereumToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update Vault data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap deposit fee for Wings
        address[] memory ethereumWingsPairMemory = _ethereumWingsPair;
        
        _ethereumToken.approve(_jetSwapRouterAddress, fee);
        _jetSwapRouter.swapExactTokensForTokens(fee, 0, ethereumWingsPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
        
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
        uint256 stakingDeposit = _userData[msg.sender].stakingDeposit;
        
        require(stakingDeposit > 0, "EthVault: withdraw amount cannot be 0");
        
        uint256 blocksStaking = computeBlocksStaking();

        if (blocksStaking > _harvestCooldownBlocks)
            harvest();
        
        _userData[msg.sender].stakingDeposit = 0;
        
        _ethereumToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "EthVault: staking deposit is 0");
    
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
        require(_userData[msg.sender].stakingDeposit > 0, "EthVault: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "EthVault: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        _ethereumToken.transfer(msg.sender, userReward);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}