pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Auction is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // Auction Basic
    uint256 private dayTime;
    Invite private inviteContract;
    ERC20 private macTokenContract;
    ERC721 private magicNftContract;
    ERC721 private platinumNftContract;
    address private officialAddress;
    address private platinumShareAddress;
    bool private auctionSwitchState;
    uint256 private auctionStartTime;
    uint256 private auctionJoinTotalCount;
    uint256 private auctionFee;

    // Account Info
    mapping(address => AuctionAccount) private auctionAccounts;
    struct AuctionAccount {
        uint256 totalCount;
        uint256 totolProfitAmount;
        uint256 [] auctionOrdersIndex;
    }
    mapping(uint256 => AuctionOrder) private auctionOrders;
    struct AuctionOrder {
        uint256 index;
        address account;
        uint256 status;// 0 - not auction ; 1 - auction ing ; 2 - exit
        uint256 nftType;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 auctionAmount;
        uint256 maxAmount;
        uint256 payFeeAmount;
        address lastUser;
        uint256 lastAmount;
        uint256 lastTime;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event SwitchState(address indexed _account, bool _auctionSwitchState);
    event AuctionFee(address indexed _account, uint256 _auctionFee);
    event AddressList(address indexed _account, address _inviteContract, address _macTokenContract, address _magicNftContract, address _platinumNftContract, address _officialAddress, address _platinumShareAddress);
    event JoinAuction(address indexed _account, uint256 _orderIndex, uint256 _nftType, uint256 _tokenId, uint256 _auctionAmount);
    event ExitAuction(address indexed _account, uint256 _orderIndex, uint256 _tokenId, uint256 _auctionAmount, uint256 _payFeeAmount);
    event AuctionShop(address indexed _account, uint256 _orderIndex, uint256 _auctionAmount);


    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 600;
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          magicNftContract = ERC721(0x5e06953ed988785D10fE2952bdb80985C3F67771);
          platinumNftContract = ERC721(0xBc363E1560fDfF55E823580E0C072959E04b5202);
          officialAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          platinumShareAddress = address(0x2A90751681279Be0CaBDC6951d7edB24803de1b4);
          auctionSwitchState = false;
          auctionFee = 50; // div(1000)
    }

    // ================= Auction Operation  =================

    function auctionShop(uint256 _orderIndex,uint256 _auctionAmount) public returns (bool) {
          // Invite check
          require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

          // Data validation
          AuctionOrder storage order =  auctionOrders[_orderIndex];
          require(auctionSwitchState,"-> auctionSwitchState: auction has not started yet.");
          require(order.startTime<=block.timestamp,"-> _startTime: The start time is not reached.");
          require(order.status!=2,"-> status: The card no longer exists.");
          require(_auctionAmount>order.lastAmount,"-> lastAmount: The participating amount must be greater than the current auction amount.");
          require(_auctionAmount<=order.maxAmount,"-> maxAmount: The participating amount must be less than or equal to the maximum amount of the current auction.");
          require(macTokenContract.balanceOf(msg.sender)>=_auctionAmount,"-> _auctionAmount: Insufficient address token balance.");

          // auctionOrders
          if(order.status==1){
              // Transfer
              macTokenContract.safeTransfer(auctionOrders[_orderIndex].lastUser, auctionOrders[_orderIndex].lastAmount);// Transfer mac to lastUser address
          }else{
              auctionOrders[_orderIndex].status = 1; // update status
          }

          // Transfer
          macTokenContract.safeTransferFrom(msg.sender, address(this), _auctionAmount);// Transfer mac to this
          auctionOrders[_orderIndex].lastUser = msg.sender;
          auctionOrders[_orderIndex].lastAmount = _auctionAmount;
          auctionOrders[_orderIndex].lastTime = block.timestamp;

          emit AuctionShop(msg.sender, _orderIndex, _auctionAmount);// set log

          return true;// return result
    }

    function exitAuction(uint256 _orderIndex) public returns (bool) {
          // Data validation
          AuctionOrder storage order =  auctionOrders[_orderIndex];
          require(order.index!=0,"-> index: The card no longer exists.");
          require(order.status!=2,"-> status: The card no longer exists.");
          require(order.account==msg.sender,"-> account: This order is not yours.");
          require(block.timestamp>=order.endTime,"-> endTime: The end time has not been reached yet.");

          // Transfer
          if(order.nftType==1){
              magicNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft1 to shop address
          }else{
              platinumNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft2 to shop address
          }

          // Transfer 2 MAC
          uint256 payFeeAmount;
          if(order.status==1){
              payFeeAmount = order.lastAmount.mul(auctionFee).div(1000);
              auctionOrders[_orderIndex].payFeeAmount = payFeeAmount;

              uint256 profitAmount = order.auctionAmount.sub(payFeeAmount);
              auctionAccounts[order.account].totolProfitAmount += profitAmount;

              macTokenContract.safeTransferFrom(address(msg.sender), order.account, profitAmount);// Transfer mac to online Address
              macTokenContract.safeTransferFrom(address(msg.sender), officialAddress, payFeeAmount.mul(40).div(100));// Transfer mac to official Address 40%
              macTokenContract.safeTransferFrom(address(msg.sender), platinumShareAddress, payFeeAmount.mul(60).div(100));// Transfer mac to platinumShare Address 60%
          }

          auctionOrders[_orderIndex].status = 2;
          auctionOrders[_orderIndex].payFeeAmount = payFeeAmount;
          emit ExitAuction(msg.sender, _orderIndex, order.tokenId, order.lastAmount, payFeeAmount);// set log

          return true;// return result
    }

    function joinAuction(uint256 _nftType,uint256 _tokenId,uint256 _auctionAmount,uint256 _startTime,uint256 _auctionDay) public returns (bool) {
          // Invite check
          require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

          // Data validation
          require(auctionSwitchState,"-> auctionSwitchState: auction has not started yet.");
          require(_startTime>=block.timestamp,"-> _startTime: The start time must be greater than the current time.");
          require(_auctionDay>=1&&_auctionDay<=30,"-> _auctionDay: The auction must be between 1 and 30 days old.");

          uint256 _endTime = _startTime.add(dayTime.mul(_auctionDay));

          uint256 nftValue;
          if(_nftType==1){
              require(magicNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
              magicNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft1 to this

              if(_tokenId<=80){
                  nftValue = 100000*10**18; // not max
              }else if(_tokenId>=81&&_tokenId<=400){
                  nftValue = 2000*10**18;
              }else if(_tokenId>=401&&_tokenId<=800){
                  nftValue = 1500*10**18;
              }else if(_tokenId>=801&&_tokenId<=2000){
                  nftValue = 800*10**18;
              }else if(_tokenId>=2001&&_tokenId<=4000){
                  nftValue = 500*10**18;
              }else if(_tokenId>=4001&&_tokenId<=12000){
                  nftValue = 300*10**18;
              }else{
                  nftValue = 100*10**18;
              }

          }else if(_nftType==2){
              require(platinumNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
              platinumNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft2 to this

              nftValue = 100000000000000*10**18;// not max
          }else{
              require(false,"-> _nftType: The NFT type is incorrect.");
          }

          // _auctionAmount value max
          require(_auctionAmount<nftValue.mul(2),"-> _auctionAmount: The starting price must be less than the maximum value.");

          // Orders dispose
          auctionJoinTotalCount += 1;// total number + 1
          auctionAccounts[msg.sender].totalCount += 1;
          auctionAccounts[msg.sender].auctionOrdersIndex.push(auctionJoinTotalCount);// update auctionAccounts
          auctionOrders[auctionJoinTotalCount] = AuctionOrder(auctionJoinTotalCount,msg.sender,0,_nftType,_tokenId,_startTime,_endTime,_auctionAmount,nftValue.mul(2),0,address(0),_auctionAmount,0);// add auctionOrders

          emit JoinAuction(msg.sender, auctionJoinTotalCount, _nftType, _tokenId, _auctionAmount);// set log

          return true;// return result
    }

    // ================= Contact Query  =====================

    function getAuctionBasic() public view returns (uint256 DayTime,Invite InviteContract,ERC20 MacTokenContract,ERC721 MagicNftContract,ERC721 PlatinumNftContract,address OfficialAddress,address PlatinumShareAddress,
        bool AuctionSwitchState,uint256 AuctionStartTime,uint256 AuctionJoinTotalCount,uint256 NowAuctionFee) {
        return (dayTime,inviteContract,macTokenContract,magicNftContract,platinumNftContract,officialAddress,platinumShareAddress,auctionSwitchState,auctionStartTime,auctionJoinTotalCount,auctionFee);
    }

    function auctionAccountOf(address _account) public view returns (uint256 TotalCount,uint256 TotolProfitAmount,uint256 [] memory AuctionOrdersIndex){
        AuctionAccount storage account = auctionAccounts[_account];
        return (account.totalCount,account.totolProfitAmount,account.auctionOrdersIndex);
    }

    function auctionOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,uint256 Status,uint256 TokenId,uint256 NftType,
        uint256 StartTime,uint256 EndTime,uint256 AuctionAmount,uint256 MaxAmount,address LastUser,uint256 LastAmount,uint256 LastTime){
        AuctionOrder storage order = auctionOrders[_orderIndex];
        return (order.index,order.account,order.status,order.tokenId,order.nftType,order.startTime,order.endTime,order.auctionAmount,order.maxAmount,
          order.lastUser,order.lastAmount,order.lastTime);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _macTokenContract,address _magicNftContract,address _platinumNftContract,address _officialAddress,address _platinumShareAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        macTokenContract = ERC20(_macTokenContract);
        magicNftContract = ERC721(_magicNftContract);
        platinumNftContract = ERC721(_platinumNftContract);
        officialAddress = _officialAddress;
        platinumShareAddress = _platinumShareAddress;
        emit AddressList(msg.sender, _inviteContract, _macTokenContract, _magicNftContract, _platinumNftContract, _officialAddress, _platinumShareAddress);
        return true;
    }

    function setAuctionSwitchState(bool _auctionSwitchState) public onlyOwner returns (bool) {
        auctionSwitchState = _auctionSwitchState;
        if(auctionStartTime==0){
            auctionStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _auctionSwitchState);
        return true;
    }

    function setAuctionFee(uint256 _auctionFee) public onlyOwner returns (bool) {
        auctionFee = _auctionFee;
        emit AuctionFee(msg.sender, _auctionFee);
        return true;
    }

}