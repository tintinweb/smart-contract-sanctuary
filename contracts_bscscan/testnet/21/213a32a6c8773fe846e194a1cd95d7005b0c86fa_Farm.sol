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

    // Farm Basic
    uint256 private oneFarmJoinMinAmount;
    uint256 private twoFarmJoinMinAmount;
    uint256 private oneFarmNowTotalCount;
    uint256 private twoFarmNowTotalCount;
    uint256 private oneFarmNowTotalJoinAmount;
    uint256 private twoFarmNowTotalJoinAmount;
    uint256 private nowFarmTotalBeanProfitAmount;

    // Financial Basic
    uint256 private financialJoinMinAmount;


    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address indexed _to, uint256 _amount);
    event AddressList(address indexed _account, address _lpTokenContract, address _beanTokenContract, address _genesisAddress);
    event SwitchState(address indexed _account, bool _oneFarmSwitchState, bool _twoFarmSwitchState, bool _financialSwitchState);
    event JoinMin(address indexed _account, uint256 _oneFarmJoinMinAmount, uint256 _twoFarmJoinMinAmount, uint256 _financialJoinMinAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 1800;
          lpTokenContract = ERC20(0xE1296259eF5d2b17391c5436c97f75AE6152c3CE);
          beanTokenContract = ERC20(0x80155Da601659E6A31F7B967cc7caBE19f0ed5Cc);
          genesisAddress = address(0x7B4F375263D8c0c33205c52566265f0AbF846B50);
          oneFarmSwitchState = true;
          twoFarmSwitchState  = true;
          financialSwitchState = true;
          oneFarmJoinMinAmount = 1 * 10 ** 18;// min 1lp
          twoFarmJoinMinAmount = 100 * 10 ** 18;// min 100bean
          financialJoinMinAmount = 100 * 10 ** 18;// min 100bean
    }

    // ================= Contact Query  =====================

    function getPublicBasic() public view returns (uint256 DayTime,ERC20 LpTokenContract,ERC20 BeanTokenContract,address GenesisAddress,bool OneFarmSwitchState,bool TwoFarmSwitchState,bool FinancialSwitchState,
      uint256 OneFarmStartTime,uint256 TwoFarmStartTime,uint256 FinancialStartTime,uint256 NextOneFarmYieldTime,uint256 NextTwoFarmYieldTime)
    {
        return (dayTime,lpTokenContract,beanTokenContract,genesisAddress,oneFarmSwitchState,twoFarmSwitchState,financialSwitchState,
          oneFarmStartTime,twoFarmStartTime,financialStartTime,nextOneFarmYieldTime,nextTwoFarmYieldTime);
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

    function setJoinMinAmount(uint256 _oneFarmJoinMinAmount,uint256 _twoFarmJoinMinAmount,uint256 _financialJoinMinAmount) public onlyOwner returns (bool) {
        oneFarmJoinMinAmount = _oneFarmJoinMinAmount;
        twoFarmJoinMinAmount = _twoFarmJoinMinAmount;
        financialJoinMinAmount = _financialJoinMinAmount;
        emit JoinMin(msg.sender, _oneFarmJoinMinAmount,_twoFarmJoinMinAmount,_financialJoinMinAmount);
        return true;
    }

}