pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract SpiritEarnings is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Earnings Basis
    uint256 private cdTime;
    Invite private inviteContract;
    ERC20 private dtuTokenContract;
    address private officialAddress;

    bool private earningsSwitchState;
    uint256 private earningsJoinTotalCount;

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
    event AddressList(address indexed _account, Invite _inviteContract, address _dtuTokenContract, address _officialAddress);
    event EarningsBasis(address indexed _account, bool _earningsSwitchState, uint256 _cdTime);
    event JoinEarnings(address indexed _account, uint256 _earningsJoinTotalCount, uint256 _earningsAmount);


    // ================= Initial Value ===============

    constructor () public {
          /* cdTime = 3600; */
          cdTime = 120;
          inviteContract = Invite(	0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
          officialAddress = address(0x8A64E8472E1EeE34B961228D3008f7a197cd8f01);
          earningsSwitchState = true;
    }

    // ================= Earnings Operation  =====================

    function joinEarnings(uint256 _earningsAmount) public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

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

    function getEarningsBasis() public view returns (uint256 CdTime,Invite InviteContract,ERC20 DtuTokenContract,address OfficialAddress,bool EarningsSwitchState,uint256 EarningsJoinTotalCount) {
        return (cdTime,inviteContract,dtuTokenContract,officialAddress,earningsSwitchState,earningsJoinTotalCount);
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

    function setAddressList(Invite _inviteContract,address _dtuTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _inviteContract, _dtuTokenContract, _officialAddress);
        return true;
    }

    function setEarningsBasis(bool _earningsSwitchState,uint256 _cdTime) public onlyOwner returns (bool) {
        earningsSwitchState = _earningsSwitchState;
        cdTime = _cdTime;
        emit EarningsBasis(msg.sender, _earningsSwitchState, _cdTime);
        return true;
    }

}