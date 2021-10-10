pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Shop is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Convert Basic
    Invite private inviteContract;
    ERC20 private dtuTokenContract;
    ERC20 private spiritFragmentContract;
    address private unionPoolAddress;// 3%
    address private developmentFundAddress;// 2%
    bool private convertSwitchState;
    uint256 private convertStartTime;
    uint256 private convertJoinTotalCount;

    // Account Info
    mapping(address => ConvertAccount) private convertAccounts;
    struct ConvertAccount {
        uint256 totalCount;
        uint256 totolProfitAmount;
        uint256 [] convertOrdersIndex;
    }
    mapping(uint256 => ConvertOrder) private convertOrders;
    struct ConvertOrder {
        uint256 index;
        address account;
        uint256 status;// 0 - online ; 1 - convert ; 2 - exit
        uint256 joinTime;
        uint256 endTime;
        uint256 convertAmount;
        uint256 payFeeAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event SwitchState(address indexed _account, bool _convertSwitchState);
    event AddressList(address indexed _account, address _inviteContract, address _dtuTokenContract, address _spiritFragmentContract, address _unionPoolAddress, address _developmentFundAddress);
    event JoinShop(address indexed _account, uint256 _orderIndex, uint256 _convertAmount);
    event ExitShop(address indexed _account, uint256 _orderIndex, uint256 _convertAmount);
    event ConvertShop(address indexed _account, uint256 _orderIndex, uint256 _convertAmount, uint256 _payFeeAmount);

    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          dtuTokenContract = ERC20(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          spiritFragmentContract = ERC20(0xbd2905f857Ac3Fd20D741e68efb4445831bd77D7);
          unionPoolAddress = address(0x13e4A8ddB241AF74846f341dE2A506fdc6646748);
          developmentFundAddress = address(0x4952cE6E663a19eB58109f65419ED09aeE904b0B);
          convertSwitchState = false;
    }

    // ================= Convert Operation  =================

    function convertShop(uint256 _orderIndex) public returns (bool) {
          // Invite check
          require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

          // Data validation
          ConvertOrder storage order =  convertOrders[_orderIndex];
          require(convertSwitchState,"-> convertSwitchState: convert has not started yet.");
          require(order.status==0,"-> status: The card no longer exists.");
          require(dtuTokenContract.balanceOf(msg.sender)>=order.convertAmount,"-> convertAmount: Insufficient address token balance.");

          uint256 payUnionPoolFeeAmount = order.convertAmount.mul(3).div(100);
          uint256 payDevelopmentFundFeeAmount = order.convertAmount.mul(2).div(100);
          convertOrders[_orderIndex].status = 1;
          convertOrders[_orderIndex].endTime = block.timestamp;
          convertOrders[_orderIndex].payFeeAmount = payUnionPoolFeeAmount.add(payDevelopmentFundFeeAmount);

          uint256 profitAmount = order.convertAmount.sub(payUnionPoolFeeAmount.add(payDevelopmentFundFeeAmount));
          convertAccounts[order.account].totolProfitAmount += profitAmount;

          // Transfer
          dtuTokenContract.safeTransferFrom(address(msg.sender), order.account, profitAmount);// Transfer dtu to order.account Address
          dtuTokenContract.safeTransferFrom(address(msg.sender), unionPoolAddress, payUnionPoolFeeAmount);// Transfer dtu to unionPoolAddress Address
          dtuTokenContract.safeTransferFrom(address(msg.sender), developmentFundAddress, payDevelopmentFundFeeAmount);// Transfer dtu to developmentFundAddress Address
          spiritFragmentContract.safeTransfer(address(msg.sender),1);// Transfer spiritFragmentContract to convert address

          emit ConvertShop(msg.sender, _orderIndex, order.convertAmount, order.payFeeAmount);// set log

          return true;// return result
    }

    function exitShop(uint256 _orderIndex) public returns (bool) {
          // Data validation
          ConvertOrder storage order =  convertOrders[_orderIndex];
          require(order.status==0,"-> status: The card no longer exists.");
          require(order.account==msg.sender,"-> account: This order is not yours.");

          convertOrders[_orderIndex].status = 2;
          convertOrders[_orderIndex].endTime = block.timestamp;

          // Transfer
          spiritFragmentContract.safeTransfer(order.account,1);// Transfer spiritFragmentContract to shop address
          emit ExitShop(msg.sender, _orderIndex, order.convertAmount);// set log

          return true;// return result
    }

    function joinShop(uint256 _convertAmount) public returns (bool) {
          // Invite check
          require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

          // Data validation
          require(convertSwitchState,"-> convertSwitchState: convert has not started yet.");
          require(spiritFragmentContract.balanceOf(msg.sender)>=1,"-> spiritFragmentContract: Insufficient address token balance.");

          // Orders dispose
          convertJoinTotalCount += 1;// total number + 1
          convertAccounts[msg.sender].totalCount += 1;
          convertAccounts[msg.sender].convertOrdersIndex.push(convertJoinTotalCount);// update convertAccounts

          convertOrders[convertJoinTotalCount] = ConvertOrder(convertJoinTotalCount,msg.sender,0,block.timestamp,0,_convertAmount,0);// add convertOrders

          spiritFragmentContract.safeTransferFrom(address(msg.sender), address(this), 1);// spiritFragmentContract to this
          emit JoinShop(msg.sender, convertJoinTotalCount, _convertAmount);// set log

          return true;// return result
    }

    // ================= Contact Query  =====================

    function getConvertBasic() public view returns (Invite InviteContract,ERC20 DtuTokenContract,ERC20 SpiritFragmentContract,address UnionPoolAddress,address DevelopmentFundAddress,bool ConvertSwitchState,uint256 ConvertStartTime,uint256 ConvertJoinTotalCount) {
        return (inviteContract,dtuTokenContract,spiritFragmentContract,unionPoolAddress,developmentFundAddress,convertSwitchState,convertStartTime,convertJoinTotalCount);
    }

    function convertAccountOf(address _account) public view returns (uint256 TotalCount,uint256 TotolProfitAmount,uint256 [] memory ConvertOrdersIndex){
        ConvertAccount storage account = convertAccounts[_account];
        return (account.totalCount,account.totolProfitAmount,account.convertOrdersIndex);
    }

    function convertOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,uint256 Status,uint256 JoinTime,uint256 EndTime,uint256 ConvertAmount,uint256 PayFeeAmount) {
        ConvertOrder storage order = convertOrders[_orderIndex];
        return (order.index,order.account,order.status,order.joinTime,order.endTime,order.convertAmount,order.payFeeAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _dtuTokenContract,address _spiritFragmentContract,address _unionPoolAddress,address _developmentFundAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        spiritFragmentContract = ERC20(_spiritFragmentContract);
        unionPoolAddress = _unionPoolAddress;
        developmentFundAddress = _developmentFundAddress;
        emit AddressList(msg.sender, _inviteContract, _dtuTokenContract, _spiritFragmentContract, _unionPoolAddress, _developmentFundAddress);
        return true;
    }

    function setConvertSwitchState(bool _convertSwitchState) public onlyOwner returns (bool) {
        convertSwitchState = _convertSwitchState;
        if(convertStartTime==0&&convertSwitchState){
            convertStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _convertSwitchState);
        return true;
    }

}