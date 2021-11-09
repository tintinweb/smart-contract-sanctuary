pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // Farm Basic
    Invite private inviteContract;
    uint256 private dayTime;
    ERC20 private macTokenContract;
    ERC721 private magicNftContract;
    ERC721 private platinumNftContract;
    address private genesisAddress;
    bool private farmSwitchState;
    uint256 private farmStartTime;
    uint256 private farmNowTotalCount;
    uint256 private farmNowJoinCount;
    uint256 private farmNowJoinMacAmount;
    uint256 private reduceApyMac;

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
        uint256 nftType;
        uint256 tokenId;
        uint256 nftValue;
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
    event AddressList(address indexed _account, address _inviteContract, address _macTokenContract, address _magicNftContract, address _platinumNftContract, address _genesisAddress);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event InviterRewards(address indexed _account, bool _inviterRewards);
    event BindingInvitation(address indexed _account,address _inviterAddress);
    event JoinFarm(address indexed _account, uint256 _farmNowTotalCount, uint256 _nftType, uint256 _tokenId);
    event ExitFarm(address indexed _account, uint256 _orderIndex, uint256 _tokenId);
    event Claim(address indexed _account, uint256 _orderIndex, uint256 _exitDiff, uint256 _profitAmount);
    event ToInviterRewards(address indexed _account, uint256 _orderIndex, uint256 _profitAmount,uint256 _rewards_level);


    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 86400;
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          magicNftContract = ERC721(0x5e06953ed988785D10fE2952bdb80985C3F67771);
          platinumNftContract = ERC721(0xBc363E1560fDfF55E823580E0C072959E04b5202);
          genesisAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          farmSwitchState = true;
          inviterRewards = true;
          reduceApyMac = 100000 * 10 ** 18; // 10W -1%  MAX -50%
    }

    // ================= Farm Operation  =================

    function toInviterRewards(address _sender,uint256 _orderIndex,uint256 _profitAmount) private returns (bool) {
        // max = 2
        address inviter = _sender;
        uint256 rewards_level;
        for(uint256 i=1;i<=2;i++){
            inviter = inviterAddress[inviter];
            if(i==1&&inviter!=address(0)&&farmAccounts[inviter].totalCount>=1){
                macTokenContract.safeTransfer(inviter, _profitAmount.mul(30).div(100));// Transfer mac to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(30).div(100);
            }else if(i==2&&inviter!=address(0)&&farmAccounts[inviter].totalCount>=1){
                macTokenContract.safeTransfer(inviter, _profitAmount.mul(10).div(100));// Transfer mac to inviter address
                accountInviterRewardAmount[inviter] += _profitAmount.mul(10).div(100);
            }else{
                rewards_level = i.sub(1);
                i = 2021;// end for
            }
        }
        emit ToInviterRewards(_sender,_orderIndex,_profitAmount,rewards_level);
    }

    function claim(uint256 _orderIndex) public returns (bool) {
        // Data validation
        FarmOrder storage order = farmOrders[_orderIndex];
        require(order.account==msg.sender,"-> account: This order does not belong to you.");
        require(order.exitProfitIndex!=2,"-> exitProfitIndex: This order has no withdrawable revenue.");

        uint256 reduceApyRate = farmNowJoinMacAmount.div(reduceApyMac);
        if(reduceApyRate==0){
            reduceApyRate = 100; // 100%
        }else if(reduceApyRate>=50){
            reduceApyRate = 50; // 50%
        }else{
            reduceApyRate = 100 - reduceApyRate;
        }
        uint256 nowApy = order.apy.mul(reduceApyRate).div(100);

        uint256 profitAmount;
        uint256 exitDiff;
        if(order.exitProfitIndex==0){
            exitDiff = block.timestamp.sub(order.lastProfitTime);
            profitAmount = order.nftValue.mul(nowApy).div(100).div(365).div(dayTime).mul(exitDiff);
        }else if(order.exitProfitIndex==1){
            exitDiff = order.exitTime.sub(order.lastProfitTime);
            profitAmount = order.nftValue.mul(nowApy).div(100).div(365).div(dayTime).mul(exitDiff);

            farmOrders[_orderIndex].exitProfitIndex = 2;// Finish the last extraction
        }

        farmOrders[_orderIndex].profitAmount += profitAmount;
        farmOrders[_orderIndex].lastProfitTime = block.timestamp;
        farmAccounts[msg.sender].totolProfitAmount += profitAmount;// update farmAccounts

        // Transfer
        macTokenContract.safeTransfer(address(msg.sender), profitAmount);// Transfer mac to farm address
        emit Claim(msg.sender,_orderIndex,exitDiff,profitAmount);// set log

        if(inviterRewards){
            toInviterRewards(msg.sender,_orderIndex,profitAmount);// rewards 3
        }
        return true;// return result
    }

    function profitAmountOf(uint256 _orderIndex) public view returns (uint256 ProfitAmount) {
        // Data validation
        FarmOrder storage order = farmOrders[_orderIndex];

        uint256 reduceApyRate = farmNowJoinMacAmount.div(reduceApyMac);
        if(reduceApyRate==0){
            reduceApyRate = 100; // 100%
        }else if(reduceApyRate>=50){
            reduceApyRate = 50; // 50%
        }else{
            reduceApyRate = 100 - reduceApyRate;
        }
        uint256 nowApy = order.apy.mul(reduceApyRate).div(100);

        if(order.exitProfitIndex==0){
            uint256 exitDiff = block.timestamp.sub(order.lastProfitTime);
            return order.nftValue.mul(nowApy).div(100).div(365).div(dayTime).mul(exitDiff);
        }else if(order.exitProfitIndex==1){
            uint256 exitDiff = order.exitTime.sub(order.lastProfitTime);
            return order.nftValue.mul(nowApy).div(100).div(365).div(dayTime).mul(exitDiff);
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
        farmNowJoinMacAmount += order.nftValue;

        // Transfer
        if(order.nftType==1){
            magicNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft1 to farm address
        }else{
            platinumNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft2 to farm address
        }
        emit ExitFarm(msg.sender, _orderIndex, order.tokenId);// set log

        return true;// return result
    }

    function joinFarm(address _inviterAddress,uint256 _nftType,uint256 _tokenId) public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(msg.sender!=genesisAddress,"-> genesisAddress: Genesis address cannot participate in mining.");
        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");

        // BindingInvitation
        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(inviterAddress[_inviterAddress]!=address(0),"-> _inviterAddress: The invitee has not participated in the farm yet.");
            }
            inviterAddress[msg.sender] = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }

        uint256 nftValue;
        uint256 tokenApy;
        if(_nftType==1){
              require(magicNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
              magicNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft1 to this

              if(_tokenId<=80){
                  nftValue = 5000*10**18;
                  tokenApy = 500;
              }else if(_tokenId>=81&&_tokenId<=400){
                  nftValue = 2000*10**18;
                  tokenApy = 300;
              }else if(_tokenId>=401&&_tokenId<=800){
                  nftValue = 1500*10**18;
                  tokenApy = 200;
              }else if(_tokenId>=801&&_tokenId<=2000){
                  nftValue = 800*10**18;
                  tokenApy = 150;
              }else if(_tokenId>=2001&&_tokenId<=4000){
                  nftValue = 500*10**18;
                  tokenApy = 120;
              }else if(_tokenId>=4001&&_tokenId<=12000){
                  nftValue = 300*10**18;
                  tokenApy = 80;
              }else{
                  nftValue = 100*10**18;
                  tokenApy = 50;
              }
        }else if(_nftType==2){
              require(platinumNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
              platinumNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft2 to this

              nftValue = 10000*10**18;
              tokenApy = 5000;
        }else{
              require(false,"-> _nftType: The NFT type is incorrect.");
        }

        // Orders dispose
        farmNowTotalCount += 1;// total number + 1
        farmNowJoinCount += 1;
        farmNowJoinMacAmount += nftValue;
        farmAccounts[msg.sender].totalCount += 1;
        farmAccounts[msg.sender].nowJoinCount += 1;
        farmAccounts[msg.sender].farmOrdersIndex.push(farmNowTotalCount);// update farmAccounts

        farmOrders[farmNowTotalCount] = FarmOrder(farmNowTotalCount,msg.sender,true,block.timestamp,0,_nftType,_tokenId,nftValue,tokenApy,0,0,block.timestamp);// add farmOrders

        emit JoinFarm(msg.sender, farmNowTotalCount, _nftType, _tokenId);// set log

        return true;// return result
    }

    // ================= Contact Query  =====================

    function getFarmBasic() public view returns (uint256 DayTime,Invite InviteContract,ERC20 MacTokenContract,ERC721 MagicNftContract,ERC721 PlatinumNftContract,address GenesisAddress,bool FarmSwitchState,uint256 FarmStartTime,uint256 FarmNowTotalCount,uint256 FarmNowJoinCount,uint256 FarmNowJoinMacAmount) {
        return (dayTime,inviteContract,macTokenContract,magicNftContract,platinumNftContract,genesisAddress,farmSwitchState,farmStartTime,farmNowTotalCount,farmNowJoinCount,farmNowJoinMacAmount);
    }

    function farmAccountOf(address _account) public view returns (uint256 TotalCount,uint256 NowJoinCount,uint256 TotolProfitAmount,uint256 [] memory FarmOrdersIndex){
        FarmAccount storage account = farmAccounts[_account];
        return (account.totalCount,account.nowJoinCount,account.totolProfitAmount,account.farmOrdersIndex);
    }

    function farmOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,bool IsExist,uint256 JoinTime,uint256 ExitTime,uint256 TokenId,uint256 NftValue,uint256 NftType,uint256 ProfitAmount,
        uint256 ExitProfitIndex,uint256 LastProfitTime){
        FarmOrder storage order = farmOrders[_orderIndex];
        return (order.index,order.account,order.isExist,order.joinTime,order.exitTime,order.tokenId,order.nftValue,order.nftType,order.profitAmount,order.exitProfitIndex,order.lastProfitTime);
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

    function setAddressList(address _inviteContract,address _macTokenContract,address _magicNftContract,address _platinumNftContract,address _genesisAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        macTokenContract = ERC20(_macTokenContract);
        magicNftContract = ERC721(_magicNftContract);
        platinumNftContract = ERC721(_platinumNftContract);
        genesisAddress = _genesisAddress;
        emit AddressList(msg.sender, _inviteContract, _macTokenContract, _magicNftContract, _platinumNftContract, _genesisAddress);
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