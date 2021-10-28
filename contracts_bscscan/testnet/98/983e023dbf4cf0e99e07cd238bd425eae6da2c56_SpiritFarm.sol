pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract SpiritFarm is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // SpiritFarm Basic
    uint256 private dayTime;
    bool private farmSwitchState;
    uint256 private farmStartTime;
    uint256 private nextFarmYieldTime;
    uint256 private nowDailyReward;
    uint256 private farmJoinTotalCount;
    uint256 private farmAccountTotalCount;
    uint256 private useAgentiaPayAmount;
    uint256 private totalNetOutputDtu;

    // Address List
    Invite private inviteContract;
    ERC20 private spiritFragmentContract;
    ERC20 private dtuTokenContract;
    ERC20 private usdtTokenContract;
    address private oraclePairDtuAddress;
    address private miningMachines1000Address;

    // Account Info
    mapping(uint256 => address) private orderAccounts;
    mapping(address => FarmAccount) private farmAccounts;
    struct FarmAccount {
        uint256 joinTotalCount;
        uint256 nowProfitAmount;
        uint256 totalProfitAmount;
        uint256 [] ordersIndex;
    }
    mapping(uint256 => FarmOrder) private farmOrders;
    struct FarmOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 endTime;
        bool isUseAgentia;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _spiritFragmentContract, address _dtuTokenContract, address _usdtTokenContract, address _oraclePairDtuAddress, address _miningMachines1000Address);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event JoinFarm(address indexed _account, uint256 _farmJoinTotalCount);
    event UseAgentia(address indexed _account, uint256 _index, uint256 _payDtuAmount);
    event SetUseAgentiaPayAmount(address indexed _account, uint256 _useAgentiaPayAmount);
    event FarmYield(address indexed _account, uint256 _dayNum, uint256 _dailyReward, uint256 _existSpiritCount, uint256 _profitAmount);
    event Claim(address indexed _account, uint256 _nowProfitAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          /* dayTime = 86400;
          farmSwitchState = false;
          nowDailyReward = 178400 * 10 ** 18;// 178400 Reward
          inviteContract = Invite(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          spiritFragmentContract = ERC20(0x16cc8665d182dffa29052718c225E08E26dAf876);
          dtuTokenContract = ERC20(0xC9F94C1cffFb9AF6e7Fd4F18d8D4a8425270be69);
          usdtTokenContract = ERC20(0x55d398326f99059fF775485246999027B3197955);
          oraclePairDtuAddress = address(0x8A64E8472E1EeE34B961228D3008f7a197cd8f01);
          miningMachines1000Address = = address(0x37Edd76a966bb81A489f177681ee5b8aE62E298a);
          useAgentiaPayAmount = 360 * 10 ** 18;// pay 400*90% usdt */

          /* dayTime = 86400; */
          dayTime = 3;
          farmSwitchState = false;
          nowDailyReward = 178400 * 10 ** 18;// 178400 Reward
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          spiritFragmentContract = ERC20(0xbd2905f857Ac3Fd20D741e68efb4445831bd77D7);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
          usdtTokenContract = ERC20(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          oraclePairDtuAddress = address(0x72783C370f41117822de2A214C42Fe39fdFAD748);
          miningMachines1000Address = address(0x37Edd76a966bb81A489f177681ee5b8aE62E298a);
          useAgentiaPayAmount = 360 * 10 ** 18;// pay 400*90% usdt
    }

    // ================= Farm Operation  =================

    function getOraclePairDtuUsdt() public view returns (uint256) {
        uint256 pairDtu = dtuTokenContract.balanceOf(oraclePairDtuAddress);
        uint256 pairUsdt = usdtTokenContract.balanceOf(oraclePairDtuAddress);
        return pairDtu.mul(1000000).div(pairUsdt);
    }

    function dailyRewardOf(uint256 _dayNum) public view returns (uint256 DailyReward){
        uint256 out1 = _dayNum.div(120);// 120
        uint256 out2 = _dayNum.div(60);// 60
        uint256 dayDailyReward = nowDailyReward;
        for(uint256 i = 0; i < out1 ; i++){
            dayDailyReward = dayDailyReward.mul(90).div(100);// 90%
        }

        if(out2>=6){
            dayDailyReward = dayDailyReward.mul(39).div(100); // 39%
        }else{
            uint256 installValue = 64;
            dayDailyReward = dayDailyReward.mul(installValue.sub(out2.mul(5))).div(100); // 64 - out2
        }

        return dayDailyReward;
    }

    function getExistSpiritCount() public view returns (uint256 ExistSpiritCount){
        uint256 existSpiritCount;
        for(uint256 i=1;i<=farmJoinTotalCount;i++){
            if(block.timestamp<farmOrders[i].endTime){
                existSpiritCount += 1;
            }
        }
        return existSpiritCount;
    }

    function toFarmYield() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(block.timestamp>=nextFarmYieldTime,"-> nextFarmYieldTime: The start time has not been reached.");

        // Yield dispose
        uint256 secondDiff = nextFarmYieldTime.sub(farmStartTime);
        uint256 dayNum = secondDiff.div(dayTime).add(15);// dayNum + 15 day
        uint256 dailyReward = dailyRewardOf(dayNum);
        uint256 existSpiritCount = getExistSpiritCount();
        // MiningMachines100
        if(dayNum>=16&&dayNum<=45){
            existSpiritCount += 1000;
            // Transfer
            dtuTokenContract.safeTransfer(miningMachines1000Address, dailyReward.div(existSpiritCount).mul(1000));// Transfer dtu to miningMachines1000Address address
        }
        uint256 profitAmount = dailyReward.div(existSpiritCount);
        for(uint256 i=1;i<=farmJoinTotalCount;i++){
            if(block.timestamp<farmOrders[i].endTime){
                farmAccounts[farmOrders[i].account].nowProfitAmount += profitAmount;// update farmAccountProfit
            }
        }
        nextFarmYieldTime += dayTime;// update nextFarmYieldTime
        totalNetOutputDtu += dailyReward;

        emit FarmYield(msg.sender,dayNum,dailyReward,existSpiritCount,profitAmount);// set log
        return true;// return result
    }

    function claim() public returns (bool) {
        // Data validation
        uint256 nowProfitAmount = farmAccounts[msg.sender].nowProfitAmount;
        require(nowProfitAmount>0,"-> nowProfitAmount: Your current withdrawable income is 0.");

        // Withdrawal dispose
        farmAccounts[msg.sender].nowProfitAmount = 0;
        farmAccounts[msg.sender].totalProfitAmount += nowProfitAmount;// update farmAccountProfit

        // Transfer
        dtuTokenContract.safeTransfer(address(msg.sender), nowProfitAmount);// Transfer dtu to farm address

        emit Claim(msg.sender, nowProfitAmount);// set log
        return true;// return result
    }

    function useAgentia(uint256 _index) public returns (bool) {
        // Data validation
        FarmOrder storage order =  farmOrders[_index];
        require(order.account==msg.sender,"-> account: error account.");
        require(block.timestamp<order.endTime,"-> endTime: error endTime.");
        require(!order.isUseAgentia,"-> isUseAgentia: error isUseAgentia.");

        uint256 payDtuAmount = useAgentiaPayAmount.div(15).mul(getOraclePairDtuUsdt()).div(1000000);
        require(dtuTokenContract.balanceOf(msg.sender)>=payDtuAmount,"-> payDtuAmount: Insufficient address dtu balance.");

        // Orders dispose
        farmOrders[_index].isUseAgentia = true;
        farmOrders[_index].endTime += dayTime.mul(2);

        // Transfer
        dtuTokenContract.safeTransferFrom(address(msg.sender), address(0), payDtuAmount);// Transfer dtu to address(0) address

        emit UseAgentia(msg.sender, _index, payDtuAmount);// set log
        return true;// return result
    }

    function joinFarm() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(spiritFragmentContract.balanceOf(msg.sender)>=4,"-> _joinAmount: Insufficient address token balance.");

        // Orders dispose
        farmJoinTotalCount += 1;// total number + 1
        if(farmAccounts[msg.sender].joinTotalCount <= 0){
            farmAccountTotalCount += 1;// account number +1
            orderAccounts[farmAccountTotalCount] = msg.sender;
        }

        farmAccounts[msg.sender].joinTotalCount += 1;
        farmAccounts[msg.sender].ordersIndex.push(farmJoinTotalCount);// add farmAccount
        farmOrders[farmJoinTotalCount] = FarmOrder(farmJoinTotalCount,msg.sender,block.timestamp,block.timestamp.add(dayTime.mul(30)),false);// add farmOrders

        // Transfer
        spiritFragmentContract.safeTransferFrom(address(msg.sender),address(this),4);// spiritF to this

        emit JoinFarm(msg.sender, farmJoinTotalCount);// set log
        return true;// return result
    }

    // ================= Farm Query  =====================

    function getFarmBasic() public view returns (uint256 DayTime,Invite InviteContract,ERC20 SpiritFragmentContract,ERC20 DtuTokenContract,ERC20 UsdtTokenContract,address OraclePairDtuAddress,
      bool FarmSwitchState,uint256 FarmStartTime,uint256 NextFarmYieldTime,uint256 NowDailyReward,uint256 FarmJoinTotalCount,uint256 FarmAccountTotalCount,uint256 UseAgentiaPayAmount,uint256 TotalNetOutputDtu)
    {
        return (dayTime,inviteContract,spiritFragmentContract,dtuTokenContract,usdtTokenContract,oraclePairDtuAddress,
          farmSwitchState,farmStartTime,nextFarmYieldTime,nowDailyReward,farmJoinTotalCount,farmAccountTotalCount,useAgentiaPayAmount,totalNetOutputDtu);
    }

    function farmAccountOf(address _account) public view returns (uint256 JoinTotalCount,uint256 NowProfitAmount,uint256 TotalProfitAmount,uint256 [] memory OrdersIndex){
        FarmAccount storage account =  farmAccounts[_account];
        return (account.joinTotalCount,account.nowProfitAmount,account.totalProfitAmount,account.ordersIndex);
    }

    function farmOrdersOf(uint256 _joinOrderIndex) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 EndTime,bool IsUseAgentia) {
        FarmOrder storage order =  farmOrders[_joinOrderIndex];
        return (order.index,order.account,order.joinTime,order.endTime,order.isUseAgentia);
    }

    function orderAccountsOf(uint256 _index) public view returns (address Account){
        return orderAccounts[_index];
    }

    function isHaveSpiritOf(address _account) public view returns (uint256 JoinTotalCount){
        return farmAccounts[_account].joinTotalCount;
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _spiritFragmentContract,address _dtuTokenContract,address _usdtTokenContract,address _oraclePairDtuAddress,address _miningMachines1000Address) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        spiritFragmentContract = ERC20(_spiritFragmentContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        usdtTokenContract = ERC20(_usdtTokenContract);
        oraclePairDtuAddress = _oraclePairDtuAddress;
        miningMachines1000Address = _miningMachines1000Address;
        emit AddressList(msg.sender, _inviteContract, _spiritFragmentContract, _dtuTokenContract, _usdtTokenContract, _oraclePairDtuAddress, _miningMachines1000Address);
        return true;
    }

    function setFarmSwitchState(bool _farmSwitchState) public onlyOwner returns (bool) {
        farmSwitchState = _farmSwitchState;
        if(farmStartTime==0&&farmSwitchState){
              farmStartTime = block.timestamp;// set farmStartTime
              nextFarmYieldTime = farmStartTime.add(dayTime);// set nextFarmYieldTime
        }
        emit SwitchState(msg.sender, _farmSwitchState);
        return true;
    }

    function setUseAgentiaPayAmount(uint256 _useAgentiaPayAmount) public onlyOwner returns (bool) {
        useAgentiaPayAmount = _useAgentiaPayAmount;
        emit SetUseAgentiaPayAmount(msg.sender, _useAgentiaPayAmount);
        return true;
    }

}