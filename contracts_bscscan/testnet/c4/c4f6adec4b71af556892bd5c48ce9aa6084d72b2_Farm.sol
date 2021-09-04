pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Public Basic
    uint256 private dayTime;
    ERC20 private lpTokenContract;
    ERC20 private beanTokenContract;
    address private genesisAddress;
    bool private oneFarmSwitchState;
    bool private twoFarmSwitchState;
    bool private financialSwitchState;
    uint256 private oneFarmStartTime;
    uint256 private twoFarmStartTime;
    uint256 private financialStartTime;
    uint256 private nextOneFarmYieldTime;
    uint256 private nextTwoFarmYieldTime;

    mapping(address => address) private inviterAddress;

    // Farm Basic
    uint256 private oneFarmJoinMinAmount;
    uint256 private twoFarmJoinMinAmount;
    uint256 private oneFarmNowTotalCount;
    uint256 private twoFarmNowTotalCount;
    uint256 private oneFarmNowTotalJoinAmount;
    uint256 private twoFarmNowTotalJoinAmount;
    mapping(address => FarmAccount) private oneFarmAccounts;
    mapping(address => FarmAccount) private twoFarmAccounts;
    struct FarmAccount {
        uint256 joinCount;
        uint256 nowTotalJoinAmount;
        uint256 nowTotalProfitAmount;
        uint256 [] farmOrdersIndex;
    }
    mapping(uint256 => FarmOrder) private oneFarmOrders;
    mapping(uint256 => FarmOrder) private twoFarmOrders;
    struct FarmOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinTime;
        uint256 exitTime;
        uint256 joinAmount;
        uint256 profitAmount;
    }
    uint256 dayBeanProfit = 25000 * 10 ** 18;
    bool public inviterRewards;
    mapping(address => uint256) public accountInviterRewardAmount;

    // Financial Basic
    DepositDailyChemicalRate public depositDailyChemicalRate;
    struct DepositDailyChemicalRate {
        uint256 daily7;
        uint256 daily15;
        uint256 daily30;
        uint256 daily60;
        uint256 daily90;
        uint256 updateTime;
        uint256 depositMinAmount;
        uint256 nowDepositTotalAmount;
        uint256 nowDepositExitProfit;
        uint256 nowDepositTotalJoinCount;
        uint256 nowDepositTotalAccountCount;
    }
    mapping(address => uint256) public depositAccountJoinCount;
    mapping(address => mapping(uint256 => DepositAccountOrder)) public depositAccountOrders;
    struct DepositAccountOrder {
        address account;
        uint256 index;
        bool isExist;
        uint256 joinAmount;
        uint256 daily;
        uint256 rate;
        uint256 joinTime;
        uint256 exitTime;
        uint256 exitAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _lpTokenContract, address _beanTokenContract, address _genesisAddress);
    event SwitchState(address indexed _account, bool _oneFarmSwitchState, bool _twoFarmSwitchState, bool _financialSwitchState);
    event JoinMin(address indexed _account, uint256 _oneFarmJoinMinAmount, uint256 _twoFarmJoinMinAmount, uint256 _depositMinAmount);
    event InviterRewards(address indexed _account, bool _inviterRewards);
    event BindingInvitation(address indexed _account,address _inviterAddress);
    event JoinFarm(address indexed _account, uint256 _joinAmount, uint256 _farmNowTotalCount, uint256 _farmId);
    event ExitFarm(address indexed _account, uint256 _orderIndex, uint256 _farmId);
    event FarmYield(address indexed _account, uint256 _farmId, uint256 _dayBeanProfit, uint256 _farmNowTotalCount);
    event WithdrawalFarmYield(address indexed _account, uint256 _farmId, uint256 _nowTotalProfitAmount);
    event ToInviterRewards(address indexed _account, uint256 _farmId, uint256 _profitAmount,uint256 _rewards_level);
    event JoinDeposit(address indexed _account, uint256 _depositAccountJoinCount, uint256 _joinAmount, uint256 _daily, uint256 _accountDepositRate);
    event ExitDeposit(address indexed _account, uint256 _depositAccountJoinCount, uint256 _joinAmount, uint256 _daily, uint256 _accountDepositRate, uint256 _exitAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 1800;
          lpTokenContract = ERC20(0x80155Da601659E6A31F7B967cc7caBE19f0ed5Cc);
          beanTokenContract = ERC20(0xE1296259eF5d2b17391c5436c97f75AE6152c3CE);
          genesisAddress = address(0x7B4F375263D8c0c33205c52566265f0AbF846B50);
          oneFarmSwitchState = true;
          twoFarmSwitchState  = true;
          financialSwitchState = true;
          oneFarmJoinMinAmount = 1 * 10 ** 18;// min 1lp
          twoFarmJoinMinAmount = 100 * 10 ** 18;// min 100bean
          inviterRewards = true;
          depositDailyChemicalRate = DepositDailyChemicalRate(7*5,15*6,30*7,60*9,90*10,block.timestamp,1 * 10 ** 18,0,0,0,0);// add depositDailyChemicalRate
    }

    // ================= Deposit Operation  =================

    function exitDeposit(uint256 _depositAccountJoinCount) public returns (bool) {
        // Data validation
        DepositAccountOrder storage order =  depositAccountOrders[msg.sender][_depositAccountJoinCount];
        require(order.isExist,"isExist: Your deposit order does not exist");
        require(block.timestamp.sub(order.joinTime)>=order.daily.mul(dayTime),"-> daily: Your time deposit is not due.");

        // Orders dispose
        beanTokenContract.safeTransfer(address(msg.sender), order.joinAmount);// Transfer bean to user address
        beanTokenContract.safeTransfer(address(msg.sender), order.joinAmount.mul(order.rate).div(1000));// Transfer bean to user address
        uint256 exitAmount = order.joinAmount + order.joinAmount.mul(order.rate).div(1000);
        depositAccountOrders[msg.sender][_depositAccountJoinCount].isExist = false;
        depositAccountOrders[msg.sender][_depositAccountJoinCount].exitTime = block.timestamp;
        depositAccountOrders[msg.sender][_depositAccountJoinCount].exitAmount = exitAmount;

        // now deposit data
        depositDailyChemicalRate.nowDepositTotalAmount -= order.joinAmount;
        depositDailyChemicalRate.nowDepositExitProfit += exitAmount.sub(order.joinAmount);

        emit ExitDeposit(msg.sender,order.index,order.joinAmount,order.daily,order.rate,exitAmount);

        if(inviterRewards){
            toInviterRewards(msg.sender,3,exitAmount.sub(order.joinAmount));// rewards 6
        }
        return true;
    }

    function joinDeposit(address _inviterAddress,uint256 _joinAmount,uint256 _daily) public returns (bool) {
        // Data validation
        require(financialSwitchState,"-> financialSwitchState: Lend has not started yet.");
        require(msg.sender!=genesisAddress,"-> genesisAddress: Genesis address cannot participate in mining.");
        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");
        require(_joinAmount>=depositDailyChemicalRate.depositMinAmount,"-> _joinAmount: Deposit cannot be less than the minimum deposit amount.");
        require(beanTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> beanTokenContract: Insufficient address usdt balance.");

        // Orders dispose
        uint256 accountDepositRate;
        if(_daily==7){
            accountDepositRate = depositDailyChemicalRate.daily7;
        }else if(_daily==15){
            accountDepositRate = depositDailyChemicalRate.daily15;
        }else if(_daily==30){
            accountDepositRate = depositDailyChemicalRate.daily30;
        }else if(_daily==60){
            accountDepositRate = depositDailyChemicalRate.daily60;
        }else if(_daily==90){
            accountDepositRate = depositDailyChemicalRate.daily90;
        }else{
            require(false,"-> _daily: No this product.");
        }

        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(inviterAddress[_inviterAddress]!=address(0),"-> _inviterAddress: The invitee has not participated in the farm yet.");
            }
            inviterAddress[msg.sender] = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }

        beanTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);// bean to this

        uint256 nowDepositAccountJoinCount = depositAccountJoinCount[msg.sender].add(1);
        depositAccountOrders[msg.sender][nowDepositAccountJoinCount] = DepositAccountOrder(msg.sender,nowDepositAccountJoinCount,true,_joinAmount,_daily,accountDepositRate,block.timestamp,0,0);// add DepositAccountOrder
        depositAccountJoinCount[msg.sender] += 1;

        // now deposit data
        depositDailyChemicalRate.nowDepositTotalAmount += _joinAmount;
        depositDailyChemicalRate.nowDepositTotalJoinCount += 1;
        if(depositAccountJoinCount[msg.sender]==1){
            depositDailyChemicalRate.nowDepositTotalAccountCount += 1; // add new account
        }

        emit JoinDeposit(msg.sender, nowDepositAccountJoinCount, _joinAmount, _daily, accountDepositRate);
        return true;
    }

    // ================= Farm Operation  =================

    function toInviterRewards(address _sender,uint256 _farmId,uint256 _profitAmount) private returns (bool) {
        // max = 6
        address inviter = _sender;
        uint256 rewards_level;
        for(uint256 i=1;i<=6;i++){
            inviter = inviterAddress[inviter];
            if(i==1&&inviter!=address(0)){
                beanTokenContract.safeTransfer(inviter, _profitAmount.mul(500).div(1000));// Transfer bean to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(500).div(1000);
            }else if(i==2&&inviter!=address(0)){
                beanTokenContract.safeTransfer(inviter, _profitAmount.mul(250).div(1000));// Transfer bean to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(250).div(1000);
            }else if(i==3&&inviter!=address(0)){
                beanTokenContract.safeTransfer(inviter, _profitAmount.mul(125).div(1000));// Transfer bean to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(125).div(1000);
            }else if(i==4&&inviter!=address(0)){
                beanTokenContract.safeTransfer(inviter, _profitAmount.mul(62).div(1000));// Transfer bean to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(62).div(1000);
            }else if(i==5&&inviter!=address(0)){
                beanTokenContract.safeTransfer(inviter, _profitAmount.mul(31).div(1000));// Transfer bean to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(31).div(1000);
            }else if(i==6&&inviter!=address(0)){
                beanTokenContract.safeTransfer(inviter, _profitAmount.mul(12).div(1000));// Transfer bean to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(12).div(1000);
            }else{
                rewards_level = i;
                i = 7;// end for
            }
        }
        emit ToInviterRewards(_sender,_farmId,_profitAmount,rewards_level);
    }

    function withdrawalFarmYield(uint256 _farmId) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");
        if(_farmId==1){
            uint256 nowTotalProfitAmount = oneFarmAccounts[msg.sender].nowTotalProfitAmount;
            require(nowTotalProfitAmount>0,"-> nowTotalProfitAmount: Your current withdrawable income is 0.");

            // Withdrawal dispose
            oneFarmAccounts[msg.sender].nowTotalProfitAmount = 0;// update farmAccounts

            // Transfer
            beanTokenContract.safeTransfer(address(msg.sender), nowTotalProfitAmount);// Transfer bean to farm address
            emit WithdrawalFarmYield(msg.sender,_farmId, nowTotalProfitAmount);// set log

            if(inviterRewards){
                toInviterRewards(msg.sender,_farmId,nowTotalProfitAmount);// rewards 6
            }
        }else{
            uint256 nowTotalProfitAmount = twoFarmAccounts[msg.sender].nowTotalProfitAmount;
            require(nowTotalProfitAmount>0,"-> nowTotalProfitAmount: Your current withdrawable income is 0.");

            // Withdrawal dispose
            twoFarmAccounts[msg.sender].nowTotalProfitAmount = 0;// update farmAccounts

            // Transfer
            beanTokenContract.safeTransfer(address(msg.sender), nowTotalProfitAmount);// Transfer bean to farm address
            emit WithdrawalFarmYield(msg.sender,_farmId, nowTotalProfitAmount);// set log

            if(inviterRewards){
                toInviterRewards(msg.sender,_farmId,nowTotalProfitAmount);// rewards 6
            }
        }
        return true;// return result
    }

    function toFarmYield(uint256 _farmId) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");
        if(_farmId==1){
            require(oneFarmSwitchState,"-> oneFarmSwitchState: farm has not started yet.");
            require(block.timestamp>=nextOneFarmYieldTime,"-> nextOneFarmYieldTime: The start time has not been reached.");

            // Yield dispose
            uint256 profitAmount;
            for(uint256 i=1;i<=oneFarmNowTotalCount;i++){
                if(oneFarmOrders[i].isExist){
                    profitAmount = oneFarmOrders[i].joinAmount.mul(dayBeanProfit).div(oneFarmNowTotalJoinAmount);// update oneFarmOrders
                    oneFarmOrders[i].profitAmount += profitAmount;
                    oneFarmAccounts[oneFarmOrders[i].account].nowTotalProfitAmount += profitAmount;
                }
            }
            nextOneFarmYieldTime += dayTime;// update nextOneFarmYieldTime
            emit FarmYield(msg.sender,_farmId,dayBeanProfit,oneFarmNowTotalCount);// set log
        }else{
            require(twoFarmSwitchState,"-> twoFarmSwitchState: farm has not started yet.");
            require(block.timestamp>=nextTwoFarmYieldTime,"-> nextTwoFarmYieldTime: The start time has not been reached.");

            // Yield dispose
            uint256 profitAmount;
            for(uint256 i=1;i<=twoFarmNowTotalCount;i++){
                if(twoFarmOrders[i].isExist){
                    profitAmount = twoFarmOrders[i].joinAmount.mul(dayBeanProfit).div(twoFarmNowTotalJoinAmount);// update twoFarmOrders
                    twoFarmOrders[i].profitAmount += profitAmount;
                    twoFarmAccounts[twoFarmOrders[i].account].nowTotalProfitAmount += profitAmount;
                }
            }
            nextTwoFarmYieldTime += dayTime;// update nextTwoFarmYieldTime
            emit FarmYield(msg.sender,_farmId,dayBeanProfit,twoFarmNowTotalCount);// set log
        }
        return true;// return result
    }

    function exitFarm(uint256 _farmId,uint256 _orderIndex) public returns (bool) {
        if(_farmId==1){
            FarmOrder storage order =  oneFarmOrders[_orderIndex];
            require(order.isExist,"-> isExist: Your oneFarmOrder does not exist.");
            require(order.account==msg.sender,"-> account: This order is not yours.");

            oneFarmOrders[_orderIndex].isExist = false;
            oneFarmOrders[_orderIndex].exitTime = block.timestamp;
            oneFarmAccounts[msg.sender].nowTotalJoinAmount -= order.joinAmount;
            oneFarmNowTotalJoinAmount -= order.joinAmount;

            // Transfer
            lpTokenContract.safeTransfer(address(msg.sender), order.joinAmount);// Transfer lp to farm address
            emit ExitFarm(msg.sender, _orderIndex, _farmId);// set log
        }else{
            FarmOrder storage order =  twoFarmOrders[_orderIndex];
            require(order.isExist,"-> isExist: Your twoFarmOrder does not exist.");
            require(order.account==msg.sender,"-> account: This order is not yours.");

            twoFarmOrders[_orderIndex].isExist = false;
            twoFarmOrders[_orderIndex].exitTime = block.timestamp;
            twoFarmAccounts[msg.sender].nowTotalJoinAmount -= order.joinAmount;
            twoFarmNowTotalJoinAmount -= order.joinAmount;

            // Transfer
            beanTokenContract.safeTransfer(address(msg.sender), order.joinAmount);// Transfer bean to farm address
            emit ExitFarm(msg.sender, _orderIndex, _farmId);// set log
        }
        return true;// return result
    }

    function joinFarm(address _inviterAddress,uint256 _joinAmount,uint256 _farmId) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");
        require(msg.sender!=genesisAddress,"-> genesisAddress: Genesis address cannot participate in mining.");
        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");

        if(_farmId==1){
            require(oneFarmSwitchState,"-> oneFarmSwitchState: farm has not started yet.");
            require(_joinAmount>=oneFarmJoinMinAmount,"-> oneFarmJoinMinAmount: The addition amount cannot be less than the minimum addition amount.");
            require(lpTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> _joinAmount: Insufficient address lp balance.");
        }else{
            require(twoFarmSwitchState,"-> twoFarmSwitchState: farm has not started yet.");
            require(_joinAmount>=twoFarmJoinMinAmount,"-> twoFarmJoinMinAmount: The addition amount cannot be less than the minimum addition amount.");
            require(beanTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> _joinAmount: Insufficient address lp balance.");
        }

        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(inviterAddress[_inviterAddress]!=address(0),"-> _inviterAddress: The invitee has not participated in the farm yet.");
            }
            inviterAddress[msg.sender] = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }

        // Orders dispose
        if(_farmId==1){
            oneFarmNowTotalCount += 1;// total number + 1
            oneFarmNowTotalJoinAmount += _joinAmount;
            oneFarmAccounts[msg.sender].joinCount += 1;
            oneFarmAccounts[msg.sender].nowTotalJoinAmount += _joinAmount;
            oneFarmAccounts[msg.sender].farmOrdersIndex.push(oneFarmNowTotalCount);// update oneFarmAccounts
            oneFarmOrders[oneFarmNowTotalCount] = FarmOrder(oneFarmNowTotalCount,msg.sender,true,block.timestamp,0,_joinAmount,0);// add oneFarmOrders

            lpTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);// lp to this
            emit JoinFarm(msg.sender, _joinAmount, oneFarmNowTotalCount, _farmId);// set log
        }else{
            twoFarmNowTotalCount += 1;// total number + 1
            twoFarmNowTotalJoinAmount += _joinAmount;
            twoFarmAccounts[msg.sender].joinCount += 1;
            twoFarmAccounts[msg.sender].nowTotalJoinAmount += _joinAmount;
            twoFarmAccounts[msg.sender].farmOrdersIndex.push(twoFarmNowTotalCount);// update oneFarmAccounts
            twoFarmOrders[twoFarmNowTotalCount] = FarmOrder(twoFarmNowTotalCount,msg.sender,true,block.timestamp,0,_joinAmount,0);// add twoFarmOrders

            beanTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);// lp to this
            emit JoinFarm(msg.sender, _joinAmount, twoFarmNowTotalCount, _farmId);// set log
        }
        return true;// return result
    }

    // ================= Contact Query  =====================

    function getPublicBasic() public view returns (uint256 DayTime,ERC20 LpTokenContract,ERC20 BeanTokenContract,address GenesisAddress,bool OneFarmSwitchState,bool TwoFarmSwitchState,bool FinancialSwitchState,
      uint256 OneFarmStartTime,uint256 TwoFarmStartTime,uint256 FinancialStartTime,uint256 NextOneFarmYieldTime,uint256 NextTwoFarmYieldTime)
    {
        return (dayTime,lpTokenContract,beanTokenContract,genesisAddress,oneFarmSwitchState,twoFarmSwitchState,financialSwitchState,
          oneFarmStartTime,twoFarmStartTime,financialStartTime,nextOneFarmYieldTime,nextTwoFarmYieldTime);
    }

    function farmAccountOf(uint256 _farmId,address _account) public view returns (uint256 JoinCount,uint256 NowTotalJoinAmount,uint256 NowTotalProfitAmount,uint256 [] memory FarmOrdersIndex){
        if(_farmId==1){
            FarmAccount storage account =  oneFarmAccounts[_account];
            return (account.joinCount,account.nowTotalJoinAmount,account.nowTotalProfitAmount,account.farmOrdersIndex);
        }else{
            FarmAccount storage account =  twoFarmAccounts[_account];
            return (account.joinCount,account.nowTotalJoinAmount,account.nowTotalProfitAmount,account.farmOrdersIndex);
        }
    }

    function farmOrdersOf(uint256 _farmId,uint256 _index) public view returns (uint256 Index,address Account,bool IsExist,uint256 JoinTime,uint256 ExitTime,uint256 JoinAmount,uint256 ProfitAmount){
        if(_farmId==1){
            FarmOrder storage order =  oneFarmOrders[_index];
            return (order.index,order.account,order.isExist,order.joinTime,order.exitTime,order.joinAmount,order.profitAmount);
        }else{
            FarmOrder storage order =  oneFarmOrders[_index];
            return (order.index,order.account,order.isExist,order.joinTime,order.exitTime,order.joinAmount,order.profitAmount);
        }
    }

    function inviterAddressOf(address _account) public view returns (address InviterAddress) {
        return inviterAddress[_account];
    }

    function getFarmBasic() public view returns (uint256 DayBeanProfit,uint256 OneFarmJoinMinAmount,uint256 TwoFarmJoinMinAmount,uint256 OneFarmNowTotalCount,uint256 TwoFarmNowTotalCount
      ,uint256 OneFarmNowTotalJoinAmount,uint256 TwoFarmNowTotalJoinAmount)
    {
        return (dayBeanProfit,oneFarmJoinMinAmount,twoFarmJoinMinAmount,oneFarmNowTotalCount,twoFarmNowTotalCount,oneFarmNowTotalJoinAmount,twoFarmNowTotalJoinAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _lpTokenContract,address _beanTokenContract,address _genesisAddress) public onlyOwner returns (bool) {
        lpTokenContract = ERC20(_lpTokenContract);
        beanTokenContract = ERC20(_beanTokenContract);
        genesisAddress = _genesisAddress;
        emit AddressList(msg.sender, _lpTokenContract, _beanTokenContract, _genesisAddress);
        return true;
    }

    function setFarmSwitchState(bool _oneFarmSwitchState,bool _twoFarmSwitchState,bool _financialSwitchState) public onlyOwner returns (bool) {
        oneFarmSwitchState = _oneFarmSwitchState;
        twoFarmSwitchState = _twoFarmSwitchState;
        financialSwitchState = _financialSwitchState;
        if(oneFarmStartTime==0){
              oneFarmStartTime = block.timestamp;
              nextOneFarmYieldTime = oneFarmStartTime.add(dayTime);
        }
        if(twoFarmStartTime==0){
              twoFarmStartTime = block.timestamp;
              nextTwoFarmYieldTime = twoFarmStartTime.add(dayTime);
        }
        if(financialStartTime==0){
              financialStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _oneFarmSwitchState,_twoFarmSwitchState,_financialSwitchState);
        return true;
    }

    function setJoinMinAmount(uint256 _oneFarmJoinMinAmount,uint256 _twoFarmJoinMinAmount,uint256 _depositMinAmount) public onlyOwner returns (bool) {
        oneFarmJoinMinAmount = _oneFarmJoinMinAmount;
        twoFarmJoinMinAmount = _twoFarmJoinMinAmount;
        depositDailyChemicalRate.depositMinAmount = _depositMinAmount;
        emit JoinMin(msg.sender, _oneFarmJoinMinAmount,_twoFarmJoinMinAmount,_depositMinAmount);
        return true;
    }

    function setInviterRewards(bool _inviterRewards) public onlyOwner returns (bool) {
        inviterRewards = _inviterRewards;
        emit InviterRewards(msg.sender, _inviterRewards);
        return true;
    }

}