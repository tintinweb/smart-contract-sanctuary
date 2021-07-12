pragma solidity 0.6.0;
import "./ERC20Interface.sol";
import "./SafeMath.sol";

contract RainbowMine {

    using SafeMath for uint256;

    address payable owner;

    struct PlatformData {
        uint256 totalInsuredAssets;
        uint256 totalLossesAssets;
    }
    //Environmental statistics
    PlatformData public platformDataManager;

    address public rbTokenAddress;
    uint256 constant public RB_TOKEN_MINE_TOTAL = 300000000 * 1e18;

    struct MineManagerStruct {
        uint256 totalMinersCount;
        uint256 mineTotalTokens;
        //10:Have authority to mine
        mapping(address => uint256) minersPermissions;
    }
    MineManagerStruct public mineManager;

    event MineTokensEvent(address miner,address user,uint256 mineTokens);

    constructor() public {
        owner = msg.sender;
        mineManager = MineManagerStruct({totalMinersCount: 0,mineTotalTokens:0});
        platformDataManager = PlatformData({totalInsuredAssets: 0,totalLossesAssets: 0});
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    //Protocol upgrade, transfer tokens
    function rbTokenMigration(uint256 _tokenAmount,address _receive)public onlyOwner{
        require(_tokenAmount > 0,"rbTokenMigration##value error .");
        require(_receive != address(0),"rbTokenMigration##Receive address error .");
        ERC20 rbToken = ERC20(rbTokenAddress);
        require(_tokenAmount <= rbToken.balanceOf(address(this)),"rbTokenMigration##Lack of balance .");
        require(rbToken.transfer(_receive,_tokenAmount),"rbTokenMigration##rbTokenMigration error .");
    }

    function setRabinbowMineAddress(address _addr)public onlyOwner {
        require(_addr != address(0),"setRabinbowMineAddress##RainbowMineAddress error .");
        uint256 authority = mineManager.minersPermissions[_addr];
        require(authority != 10,"setRabinbowMineAddress##Has authorized .");
        mineManager.minersPermissions[_addr] = 10;
        mineManager.totalMinersCount = mineManager.totalMinersCount.add(1);
    }

    function removeRainbowMineAddress(address _addr)public onlyOwner {
        require(_addr != address(0),"removeRainbowMineAddress##RainbowMineAddress error .");
        uint256 authority = mineManager.minersPermissions[_addr];
        require(authority == 10,"removeRainbowMineAddress##No Authority .");
        mineManager.minersPermissions[_addr] = 0;
        mineManager.totalMinersCount = mineManager.totalMinersCount.sub(1);
    }

    function setRBTokenAddress(address _addr)public onlyOwner {
        require(_addr != address(0),"setRBTokenAddress##RainbowTokenAddress error .");
        rbTokenAddress = _addr;
    }

    function getMinerPermission(address miner) private returns(bool){
        uint256 authority = mineManager.minersPermissions[miner];
        if(authority == 10){
            return true;
        }else{
            return false;
        }
    }

    function startMine(uint256 userTotalAssets,uint256 loseAssets,address receiveAddress) public returns(uint256){
        require(getMinerPermission(msg.sender),"No permission .");
        require(receiveAddress != address(0),"rec address error .");
        require(rbTokenAddress != address(0),"RainbowTokenAddress no init .");
        ERC20 rbToken = ERC20(rbTokenAddress);
        uint256 tokenMineBalance = rbToken.balanceOf(address(this));
        require(tokenMineBalance > 0,"No RB");
        require(userTotalAssets > 0,"No userTotalAssets");
        require(loseAssets > 0,"No loseAssets");

        (uint256 state,uint256 userTokens) = getUserClaimAmount(userTotalAssets,loseAssets,receiveAddress);
        require(state > 0,"startMine-userTokens-error .");
        require(rbToken.transfer(receiveAddress,userTokens),"user receive tokens error !");
        mineManager.mineTotalTokens = mineManager.mineTotalTokens.add(userTokens);

        platformDataManager.totalInsuredAssets = platformDataManager.totalInsuredAssets.add(userTotalAssets);
        platformDataManager.totalLossesAssets = platformDataManager.totalLossesAssets.add(loseAssets);
        emit MineTokensEvent(msg.sender,receiveAddress,userTokens);

        return userTokens;
    }

    function getUserClaimAmount(uint256 userTotalAssets,uint256 loseAssets,address user) public view returns(uint256 state,uint256 userTokens){
        if(rbTokenAddress == address(0)){
            //RBTokenAddress no init .
            return(0,0);
        }

        ERC20 rbToken = ERC20(rbTokenAddress);
        uint256 tokenMineBalance = rbToken.balanceOf(address(this));
        if(tokenMineBalance == 0){
            //No RB
            return(0,2);
        }
        if(userTotalAssets == 0){
            //No userTotalAssets
            return(0,3);
        }
        if(loseAssets == 0){
            //No loseAssets
            return(0,4);
        }

        uint256 baseOutRB = releaseRulesRB(userTotalAssets);
        uint256 loseOutRB = releaseRulesRB(loseAssets);

        uint256 outRBStage = mineManager.mineTotalTokens.add(baseOutRB);
        if(outRBStage <= (10000000 * 1e18)){
            loseOutRB = loseOutRB.mul(20);
        }else if(outRBStage <= (20000000 * 1e18)){
            loseOutRB = loseOutRB.mul(10);
        }else if(outRBStage <= (60000000 * 1e18)){
            loseOutRB = loseOutRB.mul(6);
        }else{
            loseOutRB = loseOutRB.mul(4);
        }
        uint256 totalOutRB = baseOutRB.add(loseOutRB);
        if(totalOutRB == 0){
            //TotalOutDSE error
            return(0,5);
        }
        uint256 realMineTokens = 0;
        if(tokenMineBalance > totalOutRB){
            realMineTokens = totalOutRB;
        }else{
            realMineTokens = tokenMineBalance;
        }
        return(1,realMineTokens);
    }


    function releaseRulesRB(uint256 assertsAmount)private view returns(uint256){

        ERC20 rbToken = ERC20(rbTokenAddress);

        uint256 tokenSurplusBalance = rbToken.balanceOf(address(this));
        uint256 tokenFree = RB_TOKEN_MINE_TOTAL.sub(tokenSurplusBalance);

        uint256 userTotalAssertRatio = assertsAmount.mul(2).mul(35).div(10000);

        uint256 tokenTotalRatio = RB_TOKEN_MINE_TOTAL.div(1e18);
        uint256 tokenFreeRatio = tokenFree.div(1e18);
        uint256 tokenDifficulty = mulDiv(userTotalAssertRatio,tokenFreeRatio,tokenTotalRatio);
        uint256 mineTokens = userTotalAssertRatio.sub(tokenDifficulty);
        return mineTokens;
    }

    function getTotalTokensOfMine()public view returns(uint256){
        return mineManager.mineTotalTokens;
    }

    function getPlatformData()public view returns(uint256 totalAssets,uint256 loseAssets){
        return(platformDataManager.totalInsuredAssets,platformDataManager.totalLossesAssets);
    }

    // Receive ETH
    fallback() external payable {}
    receive() external payable {}

     function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }
}