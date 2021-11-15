//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract GoToken
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

contract SafeMarsToken
{
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
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

contract GoPool 
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x47\xc5\x8d\x20\x50\x6f\x6f\x6c";
    uint256 private _swapWaitingBlocks = 3600;
    uint256 private _depositFee = 10; //Deposit fee: 10%
    uint256 private _harvestCooldownBlocks = 28800;
    uint256 private _stakingBlockRange = 864000;
    uint256 private _decimalFixMultiplier = 1000000000000000000;
    uint256 private _updateCooldownBlocks = 1200;

    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
    
    address private _goTokenAddress = 0x1D296721f12af38d35F1663113373D98CCC96635;
    address private _bananaTokenAddress = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    address private _safeMarsTokenAddress = 0x3aD9594151886Ce8538C1ff615EFa2385a8C3A88;
    address private _wbnbTokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private _apeSwapRouterAddress = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    address private _masterApeAddress = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;
    
    GoToken       private _goToken;
    BananaToken   private _bananaToken;
    SafeMarsToken private _safeMarsToken;
    ApeSwapRouter private _apeSwapRouter;
    MasterApe     private _masterApe;
    
    address[] private _goBananaPair;
    address[] private _bananaSafeMarsPair;
   
    constructor()
    {
        //Initialize contracts
        _goToken = GoToken(_goTokenAddress);
        _bananaToken = BananaToken(_bananaTokenAddress);
        _safeMarsToken = SafeMarsToken(_safeMarsTokenAddress);
        _apeSwapRouter = ApeSwapRouter(_apeSwapRouterAddress);
        _masterApe = MasterApe(_masterApeAddress);
        
        //Initialize trading pairs
        _goBananaPair = [_goTokenAddress, _wbnbTokenAddress, _bananaTokenAddress];
        _bananaSafeMarsPair = [_bananaTokenAddress, _wbnbTokenAddress, _safeMarsTokenAddress];
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _safeMarsToken.balanceOf(address(this));
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
            address[] memory _bananaSafeMarsPairMemory = _bananaSafeMarsPair;
                
            //Harvest pending Banana
            _masterApe.leaveStaking(0);
            
            uint256 amount = _bananaToken.balanceOf(address(this));

            //Swap Banana for SafeMars
            if (amount > 0)
            {
                _bananaToken.approve(_apeSwapRouterAddress, amount);
                _apeSwapRouter.swapExactTokensForTokens(amount, 0, _bananaSafeMarsPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "GoPool: minimum deposit amount: 100");
        
        _goToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update Pool data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap fee for Banana
        address[] memory _goBananaPairMemory = _goBananaPair;
        
        _goToken.approve(_apeSwapRouterAddress, fee);
        _apeSwapRouter.swapExactTokensForTokens(fee, 0, _goBananaPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
        
        //Deposit Banana on MasterApe
        uint256 bananaAmount = _bananaToken.balanceOf(address(this));

        _bananaToken.approve(_masterApeAddress, bananaAmount);
        _masterApe.enterStaking(bananaAmount);
        
        //Update rewards fund
        updateRewardsFund();
    }

    function withdraw() external
    {
        uint256 stakingDeposit = _userData[msg.sender].stakingDeposit;
        
        require(stakingDeposit > 0, "GoPool: withdraw amount cannot be 0");
        
        uint256 blocksStaking = computeBlocksStaking();

        if (blocksStaking > _harvestCooldownBlocks)
            harvest();
        
        _userData[msg.sender].stakingDeposit = 0;
 
        _goToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "GoPool: staking deposit is 0");
    
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
        require(_userData[msg.sender].stakingDeposit > 0, "GoPool: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "GoPool: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        _safeMarsToken.transfer(msg.sender, userReward);
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

