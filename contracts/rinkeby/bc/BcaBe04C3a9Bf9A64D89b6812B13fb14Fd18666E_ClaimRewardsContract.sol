pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT


import './CarbonCoin.sol';


contract ClaimRewardsContract is Ownable,ReentrancyGuard {
    using SafeMath for uint256;

    CarbonCoin public cbc;
    //MigrateContract public m;

    address private _usdt = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;

    uint256 private _tTotal = 1000 * 10**6 * 10**6 * 10**18;
    uint256 private rewardCycleBlock = 7 days;

    mapping (address => uint256) private nextAvailableClaimDate;
    mapping (address => uint256) private previousNextAvailableClaimDate;
    mapping (address => bool) private isExcludedFromReward;
    bool private _autoTransfer = true;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address private  uniswapV2Pair;
    IERC20 usdt = IERC20(_usdt);
    //IERC20  cbc2 = CarbonCoin(_cbc) ;

    event ClaimUSDTSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );
    
    constructor (CarbonCoin _cbcContract) public {
        cbc=_cbcContract;
        uniswapV2Pair = cbc.uniswapV2Pair();
        uniswapV2Router = cbc.uniswapV2Router();
    }
    
    function newLock(uint256 time) public onlyOwner {
        cbc.lock(time);
    }
    
    function newUnlock() public  onlyOwner {
        cbc.unlock();
    }
    
    function newTransferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        cbc.transferOwnership(newOwner);
    } 
    
    function getTotalUsdt() public view returns (uint256){
        return usdt.balanceOf(address(this));
    }

    function getTotalUsdtOfOld() public view returns (uint256){
        return usdt.balanceOf(address(cbc));
    }
    
    function setUniswapV2Pair(address addr)public onlyOwner{
        uniswapV2Pair = addr;
    }
    
    function getUniswapV2Pair()public view returns(address){
        return uniswapV2Pair;
    } 
 
    //----------------------------
    function setAutoTranferUsdt(bool autoTranfer)public onlyOwner{
        _autoTransfer=autoTranfer;
    }
    
    function getAutoTranferUsdt()public view onlyOwner returns (bool){
        return _autoTransfer;
    }
    
    //----------------------------
    function setRewardCycleBlock(uint256 timestamp) public onlyOwner{
        rewardCycleBlock = timestamp;
    }
    
    function getRewardCycleBlock() public view returns(uint256){
        return rewardCycleBlock;
    }
    
    //----------------------------
    function setNextAvailableClaimDate(address addrs, uint256 timestamp) public onlyOwner{
        nextAvailableClaimDate[addrs] = timestamp;
    }
    
    function getNextAvailableClaimDate(address addr) public view returns(uint256){
        return nextAvailableClaimDate[addr];
    }
    
    //----------------------------
    function setExcludeFromReward(address[] memory addrs) public onlyOwner{
        for (uint256 i=0;i<addrs.length;i++){
            isExcludedFromReward[addrs[i]] = true;
        }
    }
    
    function getExcludeFromReward(address addr) public view returns(bool){
        return isExcludedFromReward[addr];
    }
    
    receive() external payable {}

    //----------------------------
    function newClaimReward(uint256 tag) isHuman nonReentrant public {

        if (tag==0 && newCheckReward()!=0) {
            isExcludedFromReward[msg.sender]=true;
        }
        
        if (cbc.nextAvailableClaimDate(msg.sender) > previousNextAvailableClaimDate[msg.sender]){
            
            nextAvailableClaimDate[msg.sender] = nextAvailableClaimDate[msg.sender]
            .add(cbc.nextAvailableClaimDate(msg.sender))
            .sub(previousNextAvailableClaimDate[msg.sender]);
            
            previousNextAvailableClaimDate[msg.sender] = cbc.nextAvailableClaimDate(msg.sender);
        }
        
        require(!isExcludedFromReward[msg.sender], 'Error: You have already been excluded from reward!');
        require(cbc.nextAvailableClaimDate(msg.sender) <= block.timestamp, 'Error: next available not reached');
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: next available not reached');
        require(cbc.balanceOf(msg.sender) >= 0, 'Error: You must own Tokens to claim reward!');
        
        // if (_autoTransfer){
        //      m.autoClaimUsdt();
        // }

        uint256 usdtR = newCheckReward();
        
        uint256 usdtBalance = getTotalUsdtOfOld();
        cbc.unlock();
        cbc.migrateRewardToken(address(this),usdtBalance.div(100));
        cbc.migrateRewardToken(msg.sender,usdtR);
        cbc.lock(1);
        
        swapUsdtForBNB(getTotalUsdt());
        
        _approve(address(this), _usdt, usdtR);
        
        
        usdt.transfer(msg.sender, usdtR);

        nextAvailableClaimDate[msg.sender] = block.timestamp.add(rewardCycleBlock);

        emit ClaimUSDTSuccessfully(msg.sender, usdtR, nextAvailableClaimDate[msg.sender]);  
        

    }
    
    function newCheckReward() public view returns (uint256) {
        
        if (isExcludedFromReward[msg.sender]){
            return 0;
        }
        uint256 cTotalSupply = uint256(_tTotal)
        .sub(cbc.balanceOf(address(0)))
        .sub(cbc.balanceOf(0x000000000000000000000000000000000000dEaD))
        .sub(cbc.balanceOf(address(uniswapV2Pair))); 
        return _newCalculateReward(
            cbc.balanceOf(msg.sender),
            usdt.balanceOf(address(cbc)),
            cTotalSupply
        );
    }
    
    function _newCalculateReward(uint256 currentBalance,uint256 currentUsdtPool,uint256 cTotalSupply) private pure returns (uint256) {
        uint256 multiplier = 100;
        uint256 usdtReward = currentUsdtPool.mul(multiplier).mul(currentBalance).div(100).div(cTotalSupply);
        return usdtReward;
    }
    


    function checkRewardForExactAddr(address addr)public view onlyOwner returns(uint256){
        if (isExcludedFromReward[addr]){
            return 0;
        }
        uint256 cTotalSupply = uint256(_tTotal)
        .sub(cbc.balanceOf(address(0)))
        .sub(cbc.balanceOf(0x000000000000000000000000000000000000dEaD))
        .sub(cbc.balanceOf(address(uniswapV2Pair))); 
        return _newCalculateReward(
            cbc.balanceOf(address(addr)),
            usdt.balanceOf(address(cbc)),
            cTotalSupply
        );
    }
    
    function swapUsdtForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = _usdt;
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    //----------------------------

    mapping (address => mapping (address => uint256)) private _allowances2;
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances2[owner][spender] = amount;
        //emit Approval(owner, spender, amount);
    }
    
}