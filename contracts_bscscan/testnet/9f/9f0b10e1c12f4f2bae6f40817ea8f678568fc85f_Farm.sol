pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // Farm Basic
    uint256 private dayTime;
    ERC20 private cuseTokenContract;
    ERC721 private cuseNftContract;
    address private genesisAddress;
    bool private farmSwitchState;
    uint256 private farmStartTime;
    uint256 private farmNowTotalCount;
    uint256 private farmNowJoinCount;

    // Account Info
    mapping(address => FarmAccount) private farmAccounts;
    struct FarmAccount {
        uint256 totalCount;
        uint256 nowJoinCount;
        uint256 totolProfitAmount;
        uint256 [] farmOrdersIndex;
    }
    mapping(uint256 => FarmOrder) private farmOrders;
    struct FarmOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinTime;
        uint256 exitTime;
        uint256 tokenId;
        uint256 apy;
        uint256 profitAmount;
        uint256 exitProfitIndex;
        uint256 lastProfitTime;
    }

    // Inviter Info
    bool public inviterRewards;
    mapping(address => address) private inviterAddress;
    mapping(address => uint256) public accountInviterRewardAmount;

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _cuseTokenContract, address _cuseNftContract ,address _genesisAddress);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event InviterRewards(address indexed _account, bool _inviterRewards);
    event BindingInvitation(address indexed _account,address _inviterAddress);
    event JoinFarm(address indexed _account, uint256 _farmNowTotalCount, uint256 _tokenId);
    event ExitFarm(address indexed _account, uint256 _orderIndex, uint256 _tokenId);
    event Claim(address indexed _account, uint256 _orderIndex, uint256 _exitDiff, uint256 _profitAmount);
    event ToInviterRewards(address indexed _account, uint256 _orderIndex, uint256 _profitAmount,uint256 _rewards_level);


    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 1800;
          cuseTokenContract = ERC20(0x971f1EA8caa7eAC25246E58b59acbB7818F112D0);
          cuseNftContract = ERC721(0xfc8AE87E4Fb6760cF3D90749eb4FC9E6D0362919);
          farmSwitchState = true;
          inviterRewards = true;
    }

    // ================= Farm Operation  =================

    function toInviterRewards(address _sender,uint256 _orderIndex,uint256 _profitAmount) private returns (bool) {
        // max = 3
        address inviter = _sender;
        uint256 rewards_level;
        for(uint256 i=1;i<=3;i++){
            inviter = inviterAddress[inviter];
            if(i==1&&inviter!=address(0)){
                cuseTokenContract.safeTransfer(inviter, _profitAmount.mul(500).div(1000));// Transfer cuse to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(500).div(1000);
            }else if(i==2&&inviter!=address(0)){
                cuseTokenContract.safeTransfer(inviter, _profitAmount.mul(250).div(1000));// Transfer cuse to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(250).div(1000);
            }else if(i==3&&inviter!=address(0)){
                cuseTokenContract.safeTransfer(inviter, _profitAmount.mul(125).div(1000));// Transfer cuse to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(125).div(1000);
            }else{
                rewards_level = i.sub(1);
                i = 2021;// end for
            }
        }
        emit ToInviterRewards(_sender,_orderIndex,_profitAmount,rewards_level);
    }

    function claim(uint256 _orderIndex) public returns (bool) {
        // Data validation
        FarmOrder storage order =  farmOrders[_orderIndex];
        require(order.account==msg.sender,"-> account: This order does not belong to you.");
        require(order.exitProfitIndex!=2,"-> exitProfitIndex: This order has no withdrawable revenue.");

        uint256 profitAmount;
        uint256 exitDiff;
        if(order.exitProfitIndex==0){
            exitDiff = block.timestamp.sub(order.lastProfitTime);
            profitAmount = order.apy.div(365).div(dayTime).mul(exitDiff);
        }else if(order.exitProfitIndex==1){
            exitDiff = order.exitTime.sub(order.lastProfitTime);
            profitAmount = order.apy.div(365).div(dayTime).mul(exitDiff);

            farmOrders[_orderIndex].exitProfitIndex = 2;// Finish the last extraction
        }

        farmOrders[_orderIndex].profitAmount += profitAmount;
        farmOrders[_orderIndex].lastProfitTime = block.timestamp;
        farmAccounts[msg.sender].totolProfitAmount += profitAmount;// update farmAccounts

        // Transfer
        cuseTokenContract.safeTransfer(address(msg.sender), profitAmount);// Transfer cuse to farm address
        emit Claim(msg.sender,_orderIndex,exitDiff,profitAmount);// set log

        if(inviterRewards){
            toInviterRewards(msg.sender,_orderIndex,profitAmount);// rewards 3
        }
        return true;// return result
    }

    function profitAmountOf(uint256 _orderIndex) public view returns (uint256 ProfitAmount) {
        // Data validation
        FarmOrder storage order = farmOrders[_orderIndex];
        if(order.exitProfitIndex==0){
            uint256 exitDiff = block.timestamp.sub(order.lastProfitTime);
            return order.apy.div(365).div(dayTime).mul(exitDiff);
        }else if(order.exitProfitIndex==1){
            uint256 exitDiff = order.exitTime.sub(order.lastProfitTime);
            return order.apy.div(365).div(dayTime).mul(exitDiff);
        }else{
            return 0;
        }
    }

    // ================= Deposit Operation  =================

    function exitFarm(uint256 _orderIndex) public returns (bool) {
        FarmOrder storage order =  farmOrders[_orderIndex];
        require(order.isExist,"-> isExist: Your farmOrder does not exist.");
        require(order.account==msg.sender,"-> account: This order is not yours.");

        farmOrders[_orderIndex].isExist = false;
        farmOrders[_orderIndex].exitTime = block.timestamp;
        farmOrders[_orderIndex].exitProfitIndex = 1;
        farmAccounts[msg.sender].nowJoinCount -= 1;
        farmNowJoinCount -= 1;

        // Transfer
        cuseNftContract.sunshineTransferFrom(address(this),address(msg.sender),farmOrders[_orderIndex].tokenId);// Transfer nft to farm address
        emit ExitFarm(msg.sender, _orderIndex, farmOrders[_orderIndex].tokenId);// set log

        return true;// return result
    }

    function joinFarm(address _inviterAddress,uint256 _tokenId) public returns (bool) {
        // Data validation
        require(msg.sender!=genesisAddress,"-> genesisAddress: Genesis address cannot participate in mining.");
        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(cuseNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");

        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(inviterAddress[_inviterAddress]!=address(0),"-> _inviterAddress: The invitee has not participated in the farm yet.");
            }
            inviterAddress[msg.sender] = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }

        // Orders dispose
        farmNowTotalCount += 1;// total number + 1
        farmNowJoinCount += 1;
        farmAccounts[msg.sender].totalCount += 1;
        farmAccounts[msg.sender].nowJoinCount += 1;
        farmAccounts[msg.sender].farmOrdersIndex.push(farmNowTotalCount);// update farmAccounts

        uint256 tokenApy;
        if(_tokenId<=100){
            tokenApy = 100*10**18;
        }else{
            tokenApy = 50*10**18; // 1 years => X coin
        }

        farmOrders[farmNowTotalCount] = FarmOrder(farmNowTotalCount,msg.sender,true,block.timestamp,0,_tokenId,tokenApy,0,0,block.timestamp);// add farmOrders

        cuseNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft to this
        emit JoinFarm(msg.sender, farmNowTotalCount, _tokenId);// set log

        return true;// return result
    }

    // ================= Contact Query  =====================

    function getFarmBasic() public view returns (uint256 DayTime,ERC20 CuseTokenContract,ERC721 CuseNftContract,address GenesisAddress,bool FarmSwitchState,uint256 FarmStartTime,uint256 FarmNowTotalCount,uint256 FarmNowJoinCount) {
        return (dayTime,cuseTokenContract,cuseNftContract,genesisAddress,farmSwitchState,farmStartTime,farmNowTotalCount,farmNowJoinCount);
    }

    function farmAccountOf(address _account) public view returns (uint256 TotalCount,uint256 NowJoinCount,uint256 TotolProfitAmount,uint256 [] memory FarmOrdersIndex){
        FarmAccount storage account = farmAccounts[_account];
        return (account.totalCount,account.nowJoinCount,account.totolProfitAmount,account.farmOrdersIndex);
    }

    function farmOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,bool IsExist,uint256 JoinTime,uint256 ExitTime,uint256 TokenId,uint256 Apy,uint256 ProfitAmount){
        FarmOrder storage order = farmOrders[_orderIndex];
        return (order.index,order.account,order.isExist,order.joinTime,order.exitTime,order.tokenId,order.apy,order.profitAmount);
    }

    function inviterAddressOf(address _account) public view returns (address InviterAddress) {
        return inviterAddress[_account];
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _cuseTokenContract,address _cuseNftContract,address _genesisAddress) public onlyOwner returns (bool) {
        cuseTokenContract = ERC20(_cuseTokenContract);
        cuseNftContract = ERC721(_cuseNftContract);
        genesisAddress = _genesisAddress;
        emit AddressList(msg.sender, _cuseTokenContract, _cuseNftContract, _genesisAddress);
        return true;
    }

    function setFarmSwitchState(bool _farmSwitchState) public onlyOwner returns (bool) {
        farmSwitchState = _farmSwitchState;
        if(farmStartTime==0){
            farmStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _farmSwitchState);
        return true;
    }

    function setInviterRewards(bool _inviterRewards) public onlyOwner returns (bool) {
        inviterRewards = _inviterRewards;
        emit InviterRewards(msg.sender, _inviterRewards);
        return true;
    }

}