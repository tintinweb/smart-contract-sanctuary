pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Swap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Swap Basis
    ERC20 private usdtTokenContract;
    ERC20 private cuseTokenContract;
    address private officialAddress;

    bool private oneSwapSwitchState;
    bool private twoSwapSwitchState;
    bool private threeSwapSwitchState;
    bool private releaseSwitchState;

    uint256 private oneSwapMaxJoinAmount;
    uint256 private twoSwapMaxJoinAmount;
    uint256 private threeSwapMaxJoinAmount;

    uint256 private oneSwapNowJoinAmount;
    uint256 private twoSwapNowJoinAmount;
    uint256 private threeSwapNowJoinAmount;

    uint256 private swapAccountJoinMaxCount;
    uint256 private swapNowJoinTotalCount;

    // Account
    mapping(address => SwapAccount) private swapAccounts;
    struct SwapAccount {
        uint256 totalJoinCount;
        uint256 totalPayUsdtAmount;
        uint256 totalSwapCuseAmount;
        uint256 [] swapOrdersIndex;
    }
    mapping(uint256 => SwapOrder) private swapOrders;
    struct SwapOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 swapId;
        uint256 payUsdtAmount;
        uint256 swapCuseAmount;
        bool isRelease;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _usdtTokenContract, address _cuseTokenContract, address _officialAddress);
    event SwitchState(address indexed _account, bool _oneSwapSwitchState, bool _twoSwapSwitchState, bool _threeSwapSwitchState, bool _releaseSwitchState);
    event JoinSwap(address indexed _account, uint256 _swapNowJoinTotalCount, uint256 _swapId, uint256 _payUsdtAmount, uint256 _swapCuseAmount);
    event Release(address indexed _account, uint256 _swapNowJoinTotalCount);

    // ================= Initial Value ===============

    constructor () public {
          usdtTokenContract = ERC20(0xf0EcA9371e1fEb2F3e69205Be398F65479a60a69);
          cuseTokenContract = ERC20(0x971f1EA8caa7eAC25246E58b59acbB7818F112D0);
          officialAddress = address(0xeCF00f3bA5E6BEAD0d7CEB9Fe0B6Cc3E673A65a9);
          oneSwapSwitchState = false;
          twoSwapSwitchState = false;
          threeSwapSwitchState = false;
          releaseSwitchState = false;
          oneSwapMaxJoinAmount = 1000000 * 10 ** 18; // max 100W cuse
          twoSwapMaxJoinAmount = 1000000 * 10 ** 18;
          threeSwapMaxJoinAmount = 1000000 * 10 ** 18;
          swapAccountJoinMaxCount = 5; // account max 5
    }

    // ================= Swap Operation  =====================

    function release() public returns (bool) {
        // Data validation
        require(releaseSwitchState,"-> releaseSwitchState: release has not started yet.");

        // Update presellAccountOrders
        for(uint256 i=1;i<=swapNowJoinTotalCount;i++){
            if(swapOrders[i].isRelease){
                swapOrders[i].isRelease = true;
                cuseTokenContract.safeTransfer(swapOrders[i].account,swapOrders[i].swapCuseAmount);// Transfer cuse to user address
            }
        }
        emit Release(msg.sender,swapNowJoinTotalCount);// set log
        return true;// return result
    }

    function joinSwap(uint256 _payUsdtAmount,uint256 _swapId) public returns (bool) {
        // Data validation
        require(usdtTokenContract.balanceOf(msg.sender)>=_payUsdtAmount,"-> _payUsdtAmount: Insufficient address usdt balance.");
        require(swapAccounts[msg.sender].totalJoinCount<swapAccountJoinMaxCount,"-> swapAccountJoinMaxCount: One address can be bought up to five times.");

        uint256 swapCuseAmount;
        if(_swapId==1){
            require(oneSwapSwitchState,"-> oneSwapSwitchState: Swap has not started yet.");
            swapCuseAmount = _payUsdtAmount.div(15).mul(100);// swapRate = 0.15U
            require(oneSwapNowJoinAmount.add(swapCuseAmount)<=oneSwapMaxJoinAmount,"-> oneSwapMaxJoinAmount: The maximum amount cannot be exceeded.");
            oneSwapNowJoinAmount += swapCuseAmount;

        }else if(_swapId==2){
            require(twoSwapSwitchState,"-> twoSwapSwitchState: Swap has not started yet.");
            swapCuseAmount = _payUsdtAmount.div(20).mul(100);// swapRate = 0.2U
            require(twoSwapNowJoinAmount.add(swapCuseAmount)<=twoSwapMaxJoinAmount,"-> twoSwapMaxJoinAmount: The maximum amount cannot be exceeded.");
            twoSwapNowJoinAmount += swapCuseAmount;

        }else if(_swapId==3){
            require(threeSwapSwitchState,"-> threeSwapSwitchState: Swap has not started yet.");
            swapCuseAmount = _payUsdtAmount.div(25).mul(100);// swapRate = 0.25U
            require(threeSwapNowJoinAmount.add(swapCuseAmount)<=threeSwapMaxJoinAmount,"-> threeSwapMaxJoinAmount: The maximum amount cannot be exceeded.");
            threeSwapNowJoinAmount += swapCuseAmount;

        }else{
            require(false,"-> _swapId: No this product.");
        }

        // Orders dispose
        usdtTokenContract.safeTransferFrom(address(msg.sender),officialAddress,_payUsdtAmount);// usdt to officialAddress

        swapNowJoinTotalCount += 1;
        swapAccounts[msg.sender].totalJoinCount += 1;// add swapAccounts
        swapAccounts[msg.sender].totalPayUsdtAmount += _payUsdtAmount;
        swapAccounts[msg.sender].totalSwapCuseAmount += swapCuseAmount;
        swapAccounts[msg.sender].swapOrdersIndex.push(swapNowJoinTotalCount);

        swapOrders[swapNowJoinTotalCount] = SwapOrder(swapNowJoinTotalCount,msg.sender,block.timestamp,_swapId,_payUsdtAmount,swapCuseAmount,false);// add swapOrders

        emit JoinSwap(msg.sender, swapNowJoinTotalCount, _swapId, _payUsdtAmount, swapCuseAmount);
        return true;
    }

    // ================= Contact Query  =====================

    function getSwapBasic() public view returns (ERC20 UsdtTokenContract,ERC20 CuseTokenContract,address OfficialAddress,bool OneSwapSwitchState,bool TwoSwapSwitchState,bool ThreeSwapSwitchState,
      uint256 OneSwapMaxJoinAmount,uint256 TwoSwapMaxJoinAmount,uint256 ThreeSwapMaxJoinAmount,uint256 OneSwapNowJoinAmount,uint256 TwoSwapNowJoinAmount,uint256 ThreeSwapNowJoinAmount,
      uint256 SwapAccountJoinMaxCount,uint256 SwapNowJoinTotalCount)
    {
        return (usdtTokenContract,cuseTokenContract,officialAddress,oneSwapSwitchState,twoSwapSwitchState,threeSwapSwitchState,
          oneSwapMaxJoinAmount,twoSwapMaxJoinAmount,threeSwapMaxJoinAmount,oneSwapNowJoinAmount,twoSwapNowJoinAmount,threeSwapNowJoinAmount,
          swapAccountJoinMaxCount,swapNowJoinTotalCount);
    }

    function swapAccountOf(address _account) public view returns (uint256 TotalJoinCount,uint256 TotalPayUsdtAmount,uint256 TotalSwapCuseAmount,uint256 [] memory SwapOrdersIndex){
        SwapAccount storage account = swapAccounts[_account];
        return (account.totalJoinCount,account.totalPayUsdtAmount,account.totalSwapCuseAmount,account.swapOrdersIndex);
    }

    function swapOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 SwapId,uint256 PayUsdtAmount,uint256 SwapCuseAmount){
        SwapOrder storage order =  swapOrders[_index];
        return (order.index,order.account,order.joinTime,order.swapId,order.payUsdtAmount,order.swapCuseAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _usdtTokenContract,address _cuseTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        usdtTokenContract = ERC20(_usdtTokenContract);
        cuseTokenContract = ERC20(_cuseTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _usdtTokenContract, _cuseTokenContract, _officialAddress);
        return true;
    }

    function setSwapSwitchState(bool _oneSwapSwitchState,bool _twoSwapSwitchState,bool _threeSwapSwitchState,bool _releaseSwitchState) public onlyOwner returns (bool) {
        oneSwapSwitchState = _oneSwapSwitchState;
        twoSwapSwitchState = _twoSwapSwitchState;
        threeSwapSwitchState = _threeSwapSwitchState;
        releaseSwitchState = _releaseSwitchState;
        emit SwitchState(msg.sender, _oneSwapSwitchState,_twoSwapSwitchState,_threeSwapSwitchState,_releaseSwitchState);
        return true;
    }
}