pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract BlindBox is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // BlindBox Basic
    Invite private inviteContract;
    ERC20 private macTokenContract;
    ERC721 private magicNftContract;
    address private officialAddress;
    bool private boxSwitchState;
    uint256 private boxStartTime;
    uint256 private boxJoinTotalCount;
    uint256 private boxPayTotalAmount;
    uint256 private boxOpenPayAmount;

    // Account Info
    mapping(address => BoxAccount) private boxAccounts;
    struct BoxAccount {
        uint256 totalCount;
        uint256 totolProfitAmount;
        uint256 [] boxOrdersIndex;
    }
    mapping(uint256 => BoxOrder) private boxOrders;
    struct BoxOrder {
        uint256 index;
        address account;
        uint256 openTime;
        uint256 tokenId;
        uint256 payAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _macTokenContract, address _magicNftContract ,address _officialAddress);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event OpenPayAmount(address indexed _account, uint256 _boxOpenPayAmount);
    event OpenBox(address indexed _account, uint256 _boxJoinTotalCount, uint256 _boxOpenPayAmount,uint256 _tokenId);


    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          magicNftContract = ERC721(0x5e06953ed988785D10fE2952bdb80985C3F67771);
          officialAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          boxSwitchState = false;
          boxOpenPayAmount = 100 * 10 ** 18; // 1000 coin
    }

    // ================= Box Operation  =================

    function openBox() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(boxSwitchState,"-> boxSwitchState: box has not started yet.");
        require(macTokenContract.balanceOf(msg.sender)>=boxOpenPayAmount,"-> boxOpenPayAmount: Insufficient address token balance.");
        require(magicNftContract.balanceOf(address(this))>0,"-> nft balance: Insufficient number of NFTs.");

        // Orders dispose
        boxJoinTotalCount += 1;// total number + 1
        boxPayTotalAmount += boxOpenPayAmount;
        boxAccounts[msg.sender].totalCount += 1;
        boxAccounts[msg.sender].totolProfitAmount += boxOpenPayAmount;
        boxAccounts[msg.sender].boxOrdersIndex.push(boxJoinTotalCount);// update boxAccounts

        // Calculate tokenid
        magicNftContract.balanceOf(address(this));

        uint256 tokenId = boxTokenId();

        boxOrders[boxJoinTotalCount] = BoxOrder(boxJoinTotalCount,msg.sender,block.timestamp,tokenId,boxOpenPayAmount);// add boxOrders

        macTokenContract.safeTransferFrom(address(msg.sender), officialAddress, boxOpenPayAmount);// Transfer mac to officialAddress
        magicNftContract.sunshineTransferFrom(address(this), address(msg.sender), tokenId);// nft to this
        emit OpenBox(msg.sender, boxJoinTotalCount, boxOpenPayAmount, tokenId);// set log

        return true;// return result
    }

    function boxTokenId() private view returns (uint256 TokenId) {
        uint256 balance = magicNftContract.balanceOf(address(this));
        uint256 random = block.timestamp;// Todo
        uint256 index = random.mod(balance);
        return magicNftContract.tokenOfOwnerByIndex(address(this),index);
    }

    // ================= Contact Query  =====================

    function getBoxBasic() public view returns (Invite InviteContract,ERC20 MacTokenContract,ERC721 MagicNftContract,address OfficialAddress,bool BoxSwitchState,uint256 BoxStartTime,
        uint256 BoxJoinTotalCount,uint256 BoxPayTotalAmount,uint256 BoxOpenPayAmount) {
        return (inviteContract,macTokenContract,magicNftContract,officialAddress,boxSwitchState,boxStartTime,boxJoinTotalCount,boxPayTotalAmount,boxOpenPayAmount);
    }

    function boxAccountOf(address _account) public view returns (uint256 TotalCount,uint256 TotolProfitAmount,uint256 [] memory BoxOrdersIndex){
        BoxAccount storage account = boxAccounts[_account];
        return (account.totalCount,account.totolProfitAmount,account.boxOrdersIndex);
    }

    function boxOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,uint256 OpenTime,uint256 TokenId,uint256 PayAmount){
        BoxOrder storage order = boxOrders[_orderIndex];
        return (order.index,order.account,order.openTime,order.tokenId,order.payAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _macTokenContract,address _magicNftContract,address _officialAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        macTokenContract = ERC20(_macTokenContract);
        magicNftContract = ERC721(_magicNftContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _inviteContract, _macTokenContract, _magicNftContract, _officialAddress);
        return true;
    }

    function setBoxSwitchState(bool _boxSwitchState) public onlyOwner returns (bool) {
        boxSwitchState = _boxSwitchState;
        if(boxStartTime==0){
            boxStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _boxSwitchState);
        return true;
    }

    function setBoxOpenPayAmount(uint256 _boxOpenPayAmount) public onlyOwner returns (bool) {
        boxOpenPayAmount = _boxOpenPayAmount;
        emit OpenPayAmount(msg.sender, _boxOpenPayAmount);
        return true;
    }

}