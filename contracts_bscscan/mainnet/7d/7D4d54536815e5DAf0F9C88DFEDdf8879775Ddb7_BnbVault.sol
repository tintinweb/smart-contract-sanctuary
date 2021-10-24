//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract BnbToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
}

contract BananaToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
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

contract MasterApe
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
    uint256 private _autoCompoundFee = 33; //Auto-compound fee: 33%
    uint256 private _harvestCooldownBlocks = 28800;
    uint256 private _stakingBlockRange = 864000;
    uint256 private _decimalFixMultiplier = 1000000000000000000;
    uint256 private _updateCooldownBlocks = 1200;

    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
    
    address private _bananaTokenAddress = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    address private _bnbTokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private _apeSwapRouterAddress = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    address private _masterApeAddress = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;
    
    BnbToken      private _bnbToken;
    BananaToken   private _bananaToken;
    ApeSwapRouter private _apeSwapRouter;
    MasterApe     private _masterApe;
    
    address[] private _bnbBananaPair;
    address[] private _bananaBnbPair;
   
    constructor()
    {
        //Initialize contracts
        _bnbToken = BnbToken(_bnbTokenAddress);
        _bananaToken = BananaToken(_bananaTokenAddress);
        _apeSwapRouter = ApeSwapRouter(_apeSwapRouterAddress);
        _masterApe = MasterApe(_masterApeAddress);
        
        //Initialize trading pairs
        _bnbBananaPair = [_bnbTokenAddress, _bananaTokenAddress];
        _bananaBnbPair = [_bananaTokenAddress, _bnbTokenAddress];
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
    
    function updateRewardsFund() private
    {
        uint256 elapsedBlocks = block.number - _lastUpdate;
    
        if (elapsedBlocks > _updateCooldownBlocks)
        {
            address[] memory bananaBnbPairMemory = _bananaBnbPair;
                
            //Harvest pending Banana
            _masterApe.leaveStaking(0);
            
            uint256 amount = _bananaToken.balanceOf(address(this));
            
            uint256 fee = amount * _autoCompoundFee / 100;
                        
            //Auto-compound
            if (fee > 0)
            {
                _bananaToken.approve(_masterApeAddress, fee);
                _masterApe.enterStaking(fee);
            }
            
            amount = _bananaToken.balanceOf(address(this));

            //Swap Banana for WBNB
            if (amount > 0)
            {
                _bananaToken.approve(_apeSwapRouterAddress, amount);
                _apeSwapRouter.swapExactTokensForTokens(amount, 0, bananaBnbPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
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
        
        //Swap fee for Banana
        address[] memory bnbBananaPairMemory = _bnbBananaPair;
        
        _bnbToken.approve(_apeSwapRouterAddress, fee);
        _apeSwapRouter.swapExactTokensForTokens(fee, 0, bnbBananaPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Deposit Banana on MasterApe
        uint256 bananaAmount = _bananaToken.balanceOf(address(this));

        _bananaToken.approve(_masterApeAddress, bananaAmount);
        _masterApe.enterStaking(bananaAmount);
        
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