pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Convert is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // Convert Basic
    Invite private inviteContract;
    ERC20 private macTokenContract;
    ERC721 private magicNftContract;
    ERC721 private platinumNftContract;
    address private officialAddress;
    address private platinumShareAddress;
    bool private convertSwitchState;
    uint256 private convertStartTime;
    uint256 private convertJoinTotalCount;
    uint256 private convertFee;

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
        uint256 nftType;
        uint256 tokenId;
        uint256 joinTime;
        uint256 endTime;
        uint256 convertAmount;
        uint256 payFeeAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event SwitchState(address indexed _account, bool _convertSwitchState);
    event ConvertFee(address indexed _account, uint256 _convertFee);
    event AddressList(address indexed _account, address _inviteContract, address _macTokenContract, address _magicNftContract, address _platinumNftContract, address _officialAddress, address _platinumShareAddress);
    event JoinShop(address indexed _account, uint256 _orderIndex, uint256 _nftType, uint256 _tokenId, uint256 _convertAmount);
    event ExitShop(address indexed _account, uint256 _orderIndex, uint256 _tokenId, uint256 _convertAmount);
    event ConvertShop(address indexed _account, uint256 _orderIndex, uint256 _tokenId, uint256 _convertAmount, uint256 _payFeeAmount);


    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          magicNftContract = ERC721(0x5e06953ed988785D10fE2952bdb80985C3F67771);
          platinumNftContract = ERC721(0xBc363E1560fDfF55E823580E0C072959E04b5202);
          officialAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          platinumShareAddress = address(0x2A90751681279Be0CaBDC6951d7edB24803de1b4);
          convertSwitchState = false;
          convertFee = 50; // div(1000)
    }

    // ================= Convert Operation  =================

    function convertShop(uint256 _orderIndex) public returns (bool) {
          // Invite check
          require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

          // Data validation
          ConvertOrder storage order =  convertOrders[_orderIndex];
          require(convertSwitchState,"-> convertSwitchState: convert has not started yet.");
          require(order.index!=0,"-> index: The card no longer exists.");
          require(order.status==0,"-> status: The card no longer exists.");
          require(macTokenContract.balanceOf(msg.sender)>=order.convertAmount,"-> convertAmount: Insufficient address token balance.");

          uint256 payFeeAmount = order.convertAmount.mul(convertFee).div(1000);
          convertOrders[_orderIndex].status = 1;
          convertOrders[_orderIndex].endTime = block.timestamp;
          convertOrders[_orderIndex].payFeeAmount = payFeeAmount;

          uint256 profitAmount = order.convertAmount.sub(payFeeAmount);
          convertAccounts[order.account].totolProfitAmount += profitAmount;

          // Transfer
          macTokenContract.safeTransferFrom(address(msg.sender), order.account, profitAmount);// Transfer mac to online Address
          macTokenContract.safeTransferFrom(address(msg.sender), officialAddress, payFeeAmount.mul(40).div(100));// Transfer mac to official Address 40%
          macTokenContract.safeTransferFrom(address(msg.sender), platinumShareAddress, payFeeAmount.mul(60).div(100));// Transfer mac to platinumShare Address 60%
          if(order.nftType==1){
              magicNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft1 to convert address
          }else{
              platinumNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft2 to convert address
          }

          emit ConvertShop(msg.sender, _orderIndex, order.tokenId, order.convertAmount, order.payFeeAmount);// set log

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
          if(order.nftType==1){
              magicNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft1 to shop address
          }else{
              platinumNftContract.sunshineTransferFrom(address(this),address(msg.sender),order.tokenId);// Transfer nft2 to shop address
          }
          emit ExitShop(msg.sender, _orderIndex, order.tokenId, order.convertAmount);// set log

          return true;// return result
    }

    function joinShop(uint256 _nftType,uint256 _tokenId,uint256 _convertAmount) public returns (bool) {
          // Invite check
          require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

          // Data validation
          require(convertSwitchState,"-> convertSwitchState: convert has not started yet.");
          if(_nftType==1){
              require(magicNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
              magicNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft1 to this
          }else if(_nftType==2){
              require(platinumNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
              platinumNftContract.sunshineTransferFrom(address(msg.sender),address(this),_tokenId);// nft2 to this
          }else{
              require(false,"-> _nftType: The NFT type is incorrect.");
          }

          // _convertAmount
          uint256 nftValue;
          if(_nftType==1){
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
              nftValue = 100000000000000*10**18;// not max
          }
          require(_convertAmount<=nftValue.mul(2),"-> _convertAmount: The starting price must be less than the maximum value.");

          // Orders dispose
          convertJoinTotalCount += 1;// total number + 1
          convertAccounts[msg.sender].totalCount += 1;
          convertAccounts[msg.sender].convertOrdersIndex.push(convertJoinTotalCount);// update convertAccounts
          convertOrders[convertJoinTotalCount] = ConvertOrder(convertJoinTotalCount,msg.sender,0,_nftType,_tokenId,block.timestamp,0,_convertAmount,0);// add convertOrders

          emit JoinShop(msg.sender, convertJoinTotalCount, _nftType, _tokenId, _convertAmount);// set log

          return true;// return result
    }

    // ================= Contact Query  =====================

    function getConvertBasic() public view returns (Invite InviteContract,ERC20 MacTokenContract,ERC721 MagicNftContract,ERC721 PlatinumNftContract,address OfficialAddress,address PlatinumShareAddress,
        bool ConvertSwitchState,uint256 ConvertStartTime,uint256 ConvertJoinTotalCount,uint256 NowConvertFee) {
        return (inviteContract,macTokenContract,magicNftContract,platinumNftContract,officialAddress,platinumShareAddress,convertSwitchState,convertStartTime,convertJoinTotalCount,convertFee);
    }

    function convertAccountOf(address _account) public view returns (uint256 TotalCount,uint256 TotolProfitAmount,uint256 [] memory ConvertOrdersIndex){
        ConvertAccount storage account = convertAccounts[_account];
        return (account.totalCount,account.totolProfitAmount,account.convertOrdersIndex);
    }

    function convertOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,uint256 Status,uint256 NftType,uint256 TokenId,uint256 JoinTime,
        uint256 EndTime,uint256 ConvertAmount,uint256 PayFeeAmount){
        ConvertOrder storage order = convertOrders[_orderIndex];
        return (order.index,order.account,order.status,order.nftType,order.tokenId,order.joinTime,order.endTime,order.convertAmount,order.payFeeAmount);
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

    function setConvertSwitchState(bool _convertSwitchState) public onlyOwner returns (bool) {
        convertSwitchState = _convertSwitchState;
        if(convertStartTime==0){
            convertStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _convertSwitchState);
        return true;
    }

    function setConvertFee(uint256 _convertFee) public onlyOwner returns (bool) {
        convertFee = _convertFee;
        emit ConvertFee(msg.sender, _convertFee);
        return true;
    }

}