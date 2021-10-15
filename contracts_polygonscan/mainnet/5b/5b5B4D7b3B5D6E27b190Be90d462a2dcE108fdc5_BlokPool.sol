//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
}

contract WingsToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract MaticToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract BlokToken
{
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
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

contract QuickSwapRouter
{
    function swapExactTokensForTokens(
                 uint,
                 uint,
                 address[] calldata,
                 address,
                 uint
             ) external virtual returns (uint[] memory) {}
}

contract MasterChef
{
    function enterStaking(uint256) public {}
    function leaveStaking(uint256) public {}
}

contract BlokPool 
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x42\x4c\x4f\x4b\x20\x50\x6f\x6f\x6c";
    uint256 private _swapWaitingSeconds = 3600;
    uint256 private _depositFee = 10; //Deposit fee: 10%
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
    address private _maticTokenAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private _blokTokenAddress = 0x229b1b6C23ff8953D663C4cBB519717e323a0a84;
    address private _jetSwapRouterAddress = 0x5C6EC38fb0e2609672BDf628B1fD605A523E5923;
    address private _quickSwapRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private _masterChefAddress = 0x4e22399070aD5aD7f7BEb7d3A7b543e8EcBf1d85;
    
    GoToken         private _goToken;
    WingsToken      private _wingsToken;
    MaticToken      private _maticToken;
    BlokToken       private _blokToken;
    JetSwapRouter   private _jetSwapRouter;
    QuickSwapRouter private _quickSwapRouter;
    MasterChef      private _masterChef;
    
    address[] private _goWingsPair;
    address[] private _wingsMaticPair;
    address[] private _maticBlokPair;
   
    constructor()
    {
        //Initialize contracts
        _goToken         = GoToken(_goTokenAddress);
        _wingsToken      = WingsToken(_wingsTokenAddress);
        _maticToken      = MaticToken(_maticTokenAddress);
        _blokToken       = BlokToken(_blokTokenAddress);
        _jetSwapRouter   = JetSwapRouter(_jetSwapRouterAddress);
        _quickSwapRouter = QuickSwapRouter(_quickSwapRouterAddress);
        _masterChef      = MasterChef(_masterChefAddress);
        
        //Initialize trading pairs
        _goWingsPair    = [_goTokenAddress,    _maticTokenAddress, _wingsTokenAddress];
        _wingsMaticPair = [_wingsTokenAddress, _maticTokenAddress];
        _maticBlokPair  = [_maticTokenAddress, _blokTokenAddress];
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _blokToken.balanceOf(address(this));
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
    
    function updateRewardsFund() private
    {
        uint256 elapsedBlocks = block.number - _lastUpdate;
    
        if (elapsedBlocks > _updateCooldownBlocks)
        {
            address[] memory wingsMaticPairMemory = _wingsMaticPair;
            address[] memory maticBlokPairMemory = _maticBlokPair;
        
            //Harvest pending Wings
            _masterChef.leaveStaking(0);
            
            uint256 amount = _wingsToken.balanceOf(address(this));

            uint256 fee = amount * _autoCompoundFee / 100;
                        
            //Auto-compound
            if (fee > 0)
            {
                _wingsToken.approve(_masterChefAddress, fee);
                _masterChef.enterStaking(fee);
            }
            
            amount = _wingsToken.balanceOf(address(this));
            
            if (amount > 0)
            {
                //Swap Wings for Matic
                _wingsToken.approve(_jetSwapRouterAddress, amount);
                _jetSwapRouter.swapExactTokensForTokens(amount, 0, wingsMaticPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
 
                //Swap Matic for Blok
                amount = _maticToken.balanceOf(address(this));
                
                _maticToken.approve(_quickSwapRouterAddress, amount);
                _quickSwapRouter.swapExactTokensForTokens(amount, 0, maticBlokPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "BlokPool: minimum deposit amount: 100");
        
        _goToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update Pool data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap fee for Wings
        address[] memory goWingsPairMemory = _goWingsPair;
                
        _goToken.approve(_jetSwapRouterAddress, fee);
        _jetSwapRouter.swapExactTokensForTokens(fee, 0, goWingsPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Deposit Wings on MasterChef
        uint256 wingsAmount = _wingsToken.balanceOf(address(this));

        _wingsToken.approve(_masterChefAddress, wingsAmount);
        _masterChef.enterStaking(wingsAmount);
        
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
        
        require(stakingDeposit > 0, "BlokPool: withdraw amount cannot be 0");
        
        _userData[msg.sender].stakingDeposit = 0;
 
        _goToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "BlokPool: staking deposit is 0");
    
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
        require(_userData[msg.sender].stakingDeposit > 0, "BlokPool: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "BlokPool: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        _blokToken.transfer(msg.sender, userReward);
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