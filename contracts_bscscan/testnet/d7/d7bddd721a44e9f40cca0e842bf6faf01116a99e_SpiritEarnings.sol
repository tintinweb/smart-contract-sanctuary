pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract SpiritFarm {
    function isHaveSpiritOf(address _account) public view returns (uint256 JoinTotalCount);
}

contract SpiritEarnings is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Earnings Basis
    uint256 private cdTime;
    SpiritFarm private spiritFarmContract;
    ERC20 private dtuTokenContract;
    address private officialAddress;

    bool private earningsSwitchState;
    uint256 private earningsJoinTotalCount;
    uint256 private nowEndIndex;

    // Account
    mapping(address => EarningsAccount) private earningsAccounts;
    struct EarningsAccount {
        uint256 totalJoinCount;
        uint256 [] earningsOrdersIndex;
    }
    mapping(uint256 => EarningsOrder) private earningsOrders;
    struct EarningsOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 earningsAmount;
        bool isEarnings;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, SpiritFarm _spiritFarmContract, address _dtuTokenContract, address _officialAddress);
    event EarningsBasis(address indexed _account, bool _earningsSwitchState, uint256 _cdTime);
    event JoinEarnings(address indexed _account, uint256 _earningsJoinTotalCount, uint256 _earningsAmount);
    event UpdateEarningsStatusByIndex(address indexed _account, uint256 _index, bool _value);
    event UpdateEarningsAmountByIndex(address indexed _account, uint256 _index, uint256 _earningsAmount);
    event ToFarmYieldByInterval(address indexed _account, uint256 _startIndex, uint256 _entIndex);
    event ToFarmYieldByIndex(address indexed _account, uint256 _index);


    // ================= Initial Value ===============

    constructor () public {
          /* cdTime = 3600; */
          cdTime = 120;
          spiritFarmContract = SpiritFarm(0x26C3Fc3DCDd0Ce8Ad67Bc3A3973790Aa663656CF);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
          officialAddress = address(0x8A64E8472E1EeE34B961228D3008f7a197cd8f01);
          earningsSwitchState = true;
    }

    // ================= Earnings Operation  =====================

    function toFarmYieldByIndex(uint256 _index) public onlyOwner returns (bool) {
        require(_index<=earningsJoinTotalCount,"-> _index: not exist.");
        require(!earningsOrders[_index].isEarnings,"-> isEarnings: not false.");

        dtuTokenContract.safeTransfer(earningsOrders[_index].account,earningsOrders[_index].earningsAmount);// Transfer dtu to farm address
        earningsOrders[_index].isEarnings = true;

        emit ToFarmYieldByIndex(msg.sender, _index);
        return true;
    }

    function toFarmYieldByInterval(uint256 _startIndex,uint256 _count) public onlyOwner returns (bool) {
        require(_startIndex<=earningsJoinTotalCount,"-> _startIndex: not exist.");

        uint256 entIndex = _startIndex.add(_count);
        if(entIndex>=earningsJoinTotalCount){
            entIndex = earningsJoinTotalCount.add(1);
        }

        for(uint256 i=_startIndex;i<entIndex;i++){
            if(!earningsOrders[i].isEarnings){
                dtuTokenContract.safeTransfer(earningsOrders[i].account,earningsOrders[i].earningsAmount);// Transfer dtu to farm address
                earningsOrders[i].isEarnings = true;
            }
        }

        nowEndIndex = entIndex;// update entIndex
        emit ToFarmYieldByInterval(msg.sender, _startIndex, entIndex);
        return true;
    }

    function updateEarningsStatusByIndex(uint256 _index,bool _value) public onlyOwner returns (bool) {
        require(_index<=earningsJoinTotalCount,"-> _index: not exist.");
        earningsOrders[_index].isEarnings = _value;
        emit UpdateEarningsStatusByIndex(msg.sender, _index, _value);
        return true;
    }

    function updateEarningsAmountByIndex(uint256 _index,uint256 _earningsAmount) public onlyOwner returns (bool) {
        require(_index<=earningsJoinTotalCount,"-> _index: not exist.");
        earningsOrders[_index].earningsAmount = _earningsAmount;
        emit UpdateEarningsAmountByIndex(msg.sender, _index, _earningsAmount);
        return true;
    }

    // ================= Earnings Operation  =====================

    function joinEarnings(uint256 _earningsAmount) public returns (bool) {
        // SpiritFarm check
        require(spiritFarmContract.isHaveSpiritOf(msg.sender)>0,"-> spiritFarm: The number of sprites you have ever owned is 0.");

        // Data validation
        require(earningsSwitchState,"-> earningsSwitchState: earnings has not started yet.");

        earningsJoinTotalCount += 1;

        earningsAccounts[msg.sender].totalJoinCount += 1;
        earningsAccounts[msg.sender].earningsOrdersIndex.push(earningsJoinTotalCount);

        earningsOrders[earningsJoinTotalCount] = EarningsOrder(earningsJoinTotalCount,msg.sender,block.timestamp,_earningsAmount,false);// add earningsOrders

        emit JoinEarnings(msg.sender, earningsJoinTotalCount, _earningsAmount);
        return true;
    }

    // ================= Contact Query  =====================

    function getEarningsBasis() public view returns (uint256 CdTime,SpiritFarm SpiritFarmContract,ERC20 DtuTokenContract,address OfficialAddress,bool EarningsSwitchState,uint256 EarningsJoinTotalCount,uint256 NowEndIndex) {
        return (cdTime,spiritFarmContract,dtuTokenContract,officialAddress,earningsSwitchState,earningsJoinTotalCount,nowEndIndex);
    }

    function earningsAccountOf(address _account) public view returns (uint256 TotalJoinCount,uint256 [] memory EarningsOrdersIndex) {
        EarningsAccount storage account = earningsAccounts[_account];
        return (account.totalJoinCount,account.earningsOrdersIndex);
    }

    function earningsOrderOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 EarningsAmount,bool IsEarnings){
        EarningsOrder storage order = earningsOrders[_index];
        return (order.index,order.account,order.joinTime,order.earningsAmount,order.isEarnings);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(SpiritFarm _spiritFarmContract,address _dtuTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        spiritFarmContract = SpiritFarm(_spiritFarmContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _spiritFarmContract, _dtuTokenContract, _officialAddress);
        return true;
    }

    function setEarningsBasis(bool _earningsSwitchState,uint256 _cdTime) public onlyOwner returns (bool) {
        earningsSwitchState = _earningsSwitchState;
        cdTime = _cdTime;
        emit EarningsBasis(msg.sender, _earningsSwitchState, _cdTime);
        return true;
    }

}