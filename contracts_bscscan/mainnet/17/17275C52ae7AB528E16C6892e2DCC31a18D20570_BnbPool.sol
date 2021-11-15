//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
}

contract TenguToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract CakeToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract BnbToken
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

contract PancakeSwapRouter
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
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public {}
}

contract BnbPool 
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x42\x4e\x42\x20\x50\x6f\x6f\x6c";
    uint256 private _swapWaitingBlocks = 3600;
    uint256 private _depositFee = 10; //Deposit fee: 10%
    uint256 private _autoCompoundFee = 33; //Auto-compound fee: 33%
    uint256 private _harvestCooldownBlocks = 28800;
    uint256 private _stakingBlockRange = 864000;
    uint256 private _decimalFixMultiplier = 1000000000000000000;
    uint256 private _updateCooldownBlocks = 1200;

    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
    
    address private _goTokenAddress = 0x1D296721f12af38d35F1663113373D98CCC96635;
    address private _tenguTokenAddress = 0x6f6350D5d347aA8F7E9731756b60b774a7aCf95B;
    address private _cakeTokenAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private _bnbTokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private _apeSwapRouterAddress = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    address private _pancakeSwapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private _masterChefAddress = 0x29e6b6ACB00ef1cDFeBDc5a2D3731F791b85B207;
    
    GoToken           private _goToken;
    TenguToken        private _tenguToken;
    CakeToken         private _cakeToken;
    BnbToken          private _bnbToken;
    PancakeSwapRouter private _pancakeSwapRouter;
    ApeSwapRouter     private _apeSwapRouter;
    MasterChef        private _masterChef;
    
    address[] private _goCakePair;
    address[] private _cakeTenguPair;
    address[] private _tenguBnbPair;
   
    constructor()
    {
        //Initialize contracts
        _goToken = GoToken(_goTokenAddress);
        _tenguToken = TenguToken(_tenguTokenAddress);
        _cakeToken = CakeToken(_cakeTokenAddress);
        _bnbToken = BnbToken(_bnbTokenAddress);
        _apeSwapRouter = ApeSwapRouter(_apeSwapRouterAddress);
        _pancakeSwapRouter = PancakeSwapRouter(_pancakeSwapRouterAddress);
        _masterChef = MasterChef(_masterChefAddress);
        
        //Initialize trading pairs
        _goCakePair = [_goTokenAddress, _bnbTokenAddress, _cakeTokenAddress];
        _cakeTenguPair = [_cakeTokenAddress, _bnbTokenAddress, _tenguTokenAddress];
        _tenguBnbPair = [_tenguTokenAddress, _bnbTokenAddress];
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _bnbToken.balanceOf(address(this));
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
            address[] memory _tenguBnbPairMemory = _tenguBnbPair;
                
            //Harvest pending Tengu
            _masterChef.deposit(0, 0, address(0));
            
            uint256 amount = _tenguToken.balanceOf(address(this));

            uint256 fee = amount * _autoCompoundFee / 100;
            uint256 netAmount = amount - fee;
            
            //Auto-compound
            if (fee > 0)
            {
                _tenguToken.approve(_masterChefAddress, fee);
                _masterChef.deposit(0, fee, address(0));
            }
            
            //Swap Tengu for BNB
            if (netAmount > 0)
            {
                _tenguToken.approve(_pancakeSwapRouterAddress, netAmount);
                _pancakeSwapRouter.swapExactTokensForTokens(netAmount, 0, _tenguBnbPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "BnbPool: minimum deposit amount: 100");
        
        _goToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update Pool data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap fee for Tengu
        address[] memory _goCakePairMemory = _goCakePair;
        address[] memory _cakeTenguPairMemory = _cakeTenguPair;
        
        _goToken.approve(_apeSwapRouterAddress, fee);
        _apeSwapRouter.swapExactTokensForTokens(fee, 0, _goCakePairMemory, address(this), block.timestamp + _swapWaitingBlocks);
        
        uint256 cakeAmount = _cakeToken.balanceOf(address(this));
        
        _cakeToken.approve(_pancakeSwapRouterAddress, cakeAmount);
        _pancakeSwapRouter.swapExactTokensForTokens(cakeAmount, 0, _cakeTenguPairMemory, address(this), block.timestamp + _swapWaitingBlocks);
        
        //Deposit Tengu on MasterChef
        uint256 tenguAmount = _tenguToken.balanceOf(address(this));

        _tenguToken.approve(_masterChefAddress, tenguAmount);
        _masterChef.deposit(0, tenguAmount, address(0));
        
        //Update rewards fund
        updateRewardsFund();
    }

    function withdraw() external
    {
        uint256 stakingDeposit = _userData[msg.sender].stakingDeposit;
        
        require(stakingDeposit > 0, "BnbPool: withdraw amount cannot be 0");
        
        uint256 blocksStaking = computeBlocksStaking();

        if (blocksStaking > _harvestCooldownBlocks)
            harvest();
        
        _userData[msg.sender].stakingDeposit = 0;
 
        _goToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "BnbPool: staking deposit is 0");
    
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
        require(_userData[msg.sender].stakingDeposit > 0, "BnbPool: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "BnbPool: harvest cooldown in progress");
    
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

