// 代码尽管抄 我们做的是生态 你能把我们的网站也抄了去？ 垃圾土狗别抄了，你看不明白代码
// 后续我们那么多新玩法 那么多新的游戏 新的合约 你能都抄？ 你都能看的懂？ 网站你能更新？
// WE ARE N0.1
// @fw JIN GUAN CHAO
// https://dicebounty.com/
// https://t.me/dicebounty


pragma solidity >=0.8.0;

import { ERC20 } from 'ERC20.sol';
import { ReentrancyGuard } from 'ReentrancyGuard.sol';
import { IUniswapV2Router02 } from "IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "IUniswapV2Factory.sol";
import { Ownable } from 'Ownable.sol';
import { TimelockController } from 'TimelockController.sol';

contract DiceBountyToken is ERC20, Ownable, ReentrancyGuard{
    
    //Map
    mapping (address => bool) private addressIsFirstBuyNOT;
    mapping (address => bool) private noTaxrateAddrFrom;
    mapping (address => bool) private noTaxrateAddrTo;
    mapping (address => uint256) private StakeTimeStamp;
    mapping (address => uint256) private startCalTime;
    mapping (address => bool) private isPrivatePresaleBuyer;
    mapping (address => bool) private isPublicPresaleBuyer;
    mapping (address => uint256) private stakeAmount;
    mapping (address => bool) private isBountyWinner;
    mapping (address => uint256) private BountyWinAmount;
    mapping (address => uint256) private WinnerTimeStamp;
    mapping (address => uint256) private DBWinAmount;
    //
    
    //Variable tax-rate vars
    
    uint256 private constant taxDecimals = 10000;
    uint256 private constant maxTaxRate = 3000;
    uint256 private constant minTaxRate = 0;
    uint256 private constant privateBuyerDiscount = 400;
    uint256 private constant publicBuyerDiscount = 200;
    uint256 private constant daysTaxTozero = 5 days;
    uint256 private constant BountyPoolPercent = 9000;
    uint256 private constant CommunityRewardPercent = 1000;
    
    //Deployed time
    uint256 ContractDeployedTime;
    uint256 totalBountyAmount = 0;
    uint256 totalStakeAmount = 0;
    uint256 totalCommunityRewardAmount = 0;
    uint256 CurrentBountyTriggerTime = 0;
    
    //
    
    bool isStakeStarted = false;
    
    //address
    address PrivatePresaleContract;
    address PublicPresaleContract;
    address BountyAddress;
    address CommunityRewardAddress;
    address liquidityPooolAddress;
    IUniswapV2Router02 private DexRouter;
    address[] PrivatePresaleBuyerAddress;
    address[] publicPresaleBuyerAddress;
    address[] BountyStakeAddress;
    address[] BountyWinnerAddress;
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialBalance,
        address _dexRouter
    ) ERC20(name , symbol){
        DexRouter = IUniswapV2Router02(_dexRouter);
        liquidityPooolAddress = IUniswapV2Factory(DexRouter.factory()).createPair(address(this), DexRouter.WETH());
        _mint(msg.sender, initialBalance);
        ContractDeployedTime = block.timestamp;
        noTaxrateAddrFrom[msg.sender] = true;
        noTaxrateAddrFrom[address(0)] = true;
        noTaxrateAddrFrom[address(this)] = true;
        noTaxrateAddrTo[address(this)] = true;
        startCalTime[msg.sender] = block.timestamp;
        addressIsFirstBuyNOT[msg.sender] = true;
        CommunityRewardAddress = msg.sender;
        BountyAddress = address(this);
        noTaxrateAddrFrom[liquidityPooolAddress] = true;
    }
    
    receive() external payable{
        
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{
        require(from != address(0), "DiceBountyToken: 0 address Banned");
        require(to != address(0), "DiceBountyToken: 0 address Banned");
        
        
        uint256 finalAmount;
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 taxrate = getCurrentTaxrate(from);
        
        finalAmount = (amount * (taxDecimals - taxrate)*1e18)/(taxDecimals*1e18);
        
        if(addressIsFirstBuyNOT[to] == false && to != liquidityPooolAddress){
            finalAmount = amount;
            addressIsFirstBuyNOT[to] = true;
            startCalTime[to] = block.timestamp;
        }
        

        if(noTaxrateAddrTo[to] == true || noTaxrateAddrFrom[from] == true || to == BountyAddress || from == BountyAddress){
            finalAmount = amount;
        }
        
        
        if(from == PrivatePresaleContract){
            PrivatePresaleBuyerAddress.push(from);
        }
        
        if(from == PublicPresaleContract){
            publicPresaleBuyerAddress.push(from);
        }
        
        
        //lottery
        if(amount>10000 && isStakeStarted && to == liquidityPooolAddress){
            if(randUint256(99) == 88){
                address winnerAddress = calculateWinBountyAddress();
                _transfer(address(this),winnerAddress,totalBountyAmount);
                BountyWinnerAddress.push(winnerAddress);
                BountyWinAmount[winnerAddress] = totalBountyAmount;
                WinnerTimeStamp[winnerAddress] = block.timestamp;
                DBWinAmount[winnerAddress] = totalBountyAmount;
                totalBountyAmount = 0;
                CurrentBountyTriggerTime = 0;

            }
            else
            {
                CurrentBountyTriggerTime = CurrentBountyTriggerTime + 1;
                //
            }
        }
        if(noTaxrateAddrTo[to] == false){
            startCalTime[from] = block.timestamp;
            startCalTime[to] = block.timestamp;
        }
        uint256 bountyAmount;
        bountyAmount = amount - finalAmount;
        _balances[BountyAddress] = _balances[BountyAddress]+bountyAmount;
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + finalAmount;
        totalBountyAmount += bountyAmount;
        emit Transfer(from, BountyAddress, bountyAmount);
        emit Transfer(from, to, finalAmount);
    } 
    
    function getCurrentTaxrate(address _address) public view returns(uint256){
        if(addressIsFirstBuyNOT[_address] == false){
            return maxTaxRate;
        }
        uint256 timeInterval = block.timestamp - startCalTime[_address];
        //uint256 timelyTaxRate = maxTaxRate;
        
        uint256 finalTaxRate = maxTaxRate - ((timeInterval*(maxTaxRate-minTaxRate))/daysTaxTozero);
        if(finalTaxRate >= maxTaxRate){
            finalTaxRate = maxTaxRate;
        }
        
        if(finalTaxRate <= minTaxRate){
            finalTaxRate = minTaxRate;
        }
        
        if(noTaxrateAddrFrom[_address] == true)
        {
            finalTaxRate = 0;
        }
        if(_address == liquidityPooolAddress){
            finalTaxRate = 0;
        }
        
        return finalTaxRate;
    }
    
    function getCalStartTime(address _address) public view returns(uint256)
    {
        if(addressIsFirstBuyNOT[_address] == false)
        {
            return 0;
        }
        return startCalTime[_address];
    }
    
    function getFinalAmount(address _from,uint256 amount) public view returns(uint256){
       uint256 taxrate = getCurrentTaxrate(_from);
       uint256 finalAmount = (amount * (taxDecimals - taxrate)*1e18)/(taxDecimals*1e18);
       return finalAmount;
    }
    
    function getPrivatePresaleBuyerAmount() public view returns(uint256){
        return PrivatePresaleBuyerAddress.length;
    }
    
    function getPublicPresaleBuyerAmount() public view returns(uint256){
        return publicPresaleBuyerAddress.length;
    }
    
    function getPrivatePresaleBuyerAddressByIndex(uint256 index) public view returns(address){
        if(index<=PrivatePresaleBuyerAddress.length){
            return PrivatePresaleBuyerAddress[index];
        }
        else{
            return address(0);
        }
    }
    function getPublicPresaleBuyerAddressByIndex(uint256 index) public view returns(address){
        if(index<=publicPresaleBuyerAddress.length){
            return publicPresaleBuyerAddress[index];
        }
        else{
            return address(0);
        }
    }
    
    function setPrivatePresaleAddress(address _address) public onlyOwner{
        require(_address!=address(0), "address 0 banned");
        PrivatePresaleContract = _address;
        noTaxrateAddrFrom[_address] = true;
        noTaxrateAddrTo[_address] = true;
    }
    
    function setPublicPresaleAddress(address _address) public onlyOwner{
        require(_address!=address(0), "address 0 banned");
        PublicPresaleContract = _address;
        noTaxrateAddrFrom[_address] = true;
        noTaxrateAddrTo[_address] = true;
    }
    
    function setCommunityRewardAddress(address _address) public onlyOwner{
        require(_address!=address(0), "address 0 banned");
        CommunityRewardAddress = _address;
        noTaxrateAddrTo[_address] = true;
    }
    
    function setliquidityPooolAddress(address _address) public onlyOwner{
        liquidityPooolAddress = _address;
        //noTaxrateAddrFrom[_address] = true;
        
    }
    
    function MakeCommunityReward(address _to , uint256 _amount) public onlyOwner{
        _mint(_to,_amount * 1e18);
        //Rewards for someone make huge contribution for our community
        //@dev DiceBountyToken
    }
    
    function getIsFirstBuyer(address _address) public view returns(bool){
        return !addressIsFirstBuyNOT[_address];
    }
    
    function StakeTokens(uint256 amount) public {
        require(BountyAddress!=address(0),"Address 0 banned");
        require(isStakeStarted,"bie ji hai mei kai shi ne , Stake hasnt start");
        amount = amount * 1e18;
        _transfer(msg.sender,BountyAddress,amount);
        stakeAmount[msg.sender] =stakeAmount[msg.sender] + amount;
        totalStakeAmount = totalStakeAmount + amount;
        if(stakeAddressIsexist(msg.sender) == false)
        {
             BountyStakeAddress.push(msg.sender);
        }
        StakeTimeStamp[msg.sender] = block.timestamp;
    }
    
    function claimStakedTokens() public{
        require(msg.sender!=address(0),"banned");
        require(stakeAmount[msg.sender] > 0 , "shabi,mei bi ni ling ni ma ne ");
        _transfer(address(this),msg.sender,stakeAmount[msg.sender]);
        totalStakeAmount -= stakeAmount[msg.sender];
        stakeAmount[msg.sender] = 0;
    } 
    
    function claimBounty() public{
        require(msg.sender!=address(0),"banned");
        require(isBountyWinner[msg.sender],"You Never Win Any Bounty");
        _transfer(address(this),msg.sender,totalBountyAmount);
    }
    
    function setGamesContractAddress(address _address) public onlyOwner{
        noTaxrateAddrFrom[_address]  = true;
        noTaxrateAddrTo[_address] = true;
    }
    
    function randUint256(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }
    
    function getStakeAmount() public view returns(uint256){
        require(stakeAmount[msg.sender]>0 , "You have no stake amount");
        return stakeAmount[msg.sender];
        
    }
    
    function getStakeTimeByAddress(address _address) public view returns(uint256){
        require(stakeAmount[_address]>0,"No stake");
        return StakeTimeStamp[_address];
    }
    
    function getTotalStakeAmount() public view returns(uint256){
        require(isStakeStarted,"Stake hasnt start");
        return totalStakeAmount;
    }
    
    function getStakeMemberAmount() public view returns(uint256){
        require(isStakeStarted,"Stake hasnt start");
        require(BountyStakeAddress.length>0,"No Stake Menmbers");
        return BountyStakeAddress.length;
    }
    
    function getStakeAddressByIndex(uint256 _index) public view returns(address){
        require(isStakeStarted,"stake not start");
        return BountyStakeAddress[_index];
    }
    
    function getStakeAmountByAddress(address _address) public view returns(uint256){
        require(isStakeStarted,"stake not start");
        return stakeAmount[_address];
    }
    
    function calculateWinBountyAddress() public view returns(address){
         uint256 Denominator = totalStakeAmount;
         for(uint256 i = 0; i < BountyStakeAddress.length ; i++){
             if(stakeAmount[BountyStakeAddress[i]]>0){
                    if(randUint256(Denominator)<stakeAmount[BountyStakeAddress[i]]){
                        return BountyStakeAddress[i];
                    }
                    else{
                        Denominator = Denominator - stakeAmount[BountyStakeAddress[i]];
                    }
             }
         }
    }
    
    function getBountyWinnerAmount() public view returns(uint256){
        return BountyWinnerAddress.length;
    }
    
    function getBountyWinnerAddressByindex(uint256 _index) public view returns(address){
        return BountyWinnerAddress[_index];
    }
    
    
    
    function getWinnedAmountByAddress(address _address) public view returns(uint256){
        return BountyWinAmount[_address];
    }
    
    function getTotalBountyAmount() public view returns(uint256){
        return totalBountyAmount;
    }
    
    function stakeAddressIsexist(address _address) internal view returns(bool){
        for(uint256 i = 0; i < BountyStakeAddress.length ; i++){
            if(_address == BountyStakeAddress[i]){
                return true;
            }
        }
        return false;
    }
    
    function getBountyAddress() public view returns(address){
        return BountyAddress;
    }
    
    function getBountyWinTimeByAddress(address _address) public view returns(uint256){
        return WinnerTimeStamp[_address];
    }
    
    function getDBWinAmount(address _address) public view returns(uint256){
        return DBWinAmount[_address];
    }
    
    function getCurrentBountyTriggerTime() public view returns(uint256){
        return CurrentBountyTriggerTime;
    }
    
    function getTotalCommunityRewardsAmount() public view returns(uint256){
        require(msg.sender!=address(0),"address 0 banned");
        return totalCommunityRewardAmount;
    }
    
    function getStakeStarted() public view returns(bool){
        return isStakeStarted;
    }
    
    function setBountyContractAddress(address _address)  public onlyOwner {
        BountyAddress = _address;
    }
    
    function refreshTaxRate() public onlyOwner{
        for(uint256 i = 0;i<PrivatePresaleBuyerAddress.length;i++){
            startCalTime[PrivatePresaleBuyerAddress[i]] = block.timestamp;
            addressIsFirstBuyNOT[PrivatePresaleBuyerAddress[i]] = true;
        }
        for(uint256 i = 0;i<publicPresaleBuyerAddress.length;i++){
            startCalTime[publicPresaleBuyerAddress[i]] = block.timestamp;
            addressIsFirstBuyNOT[publicPresaleBuyerAddress[i]] = true;
        }
    }
    
    function lotteryRadomly() public onlyOwner{
                address winnerAddress = calculateWinBountyAddress();
                _transfer(address(this),winnerAddress,totalBountyAmount);
                BountyWinnerAddress.push(winnerAddress);
                BountyWinAmount[winnerAddress] = totalBountyAmount;
                WinnerTimeStamp[winnerAddress] = block.timestamp;
                DBWinAmount[winnerAddress] = totalBountyAmount;
                totalBountyAmount = 0;
                CurrentBountyTriggerTime = 0;
    }
    
    function StartStake(bool _Start) public onlyOwner{
        isStakeStarted = _Start;
    }
}