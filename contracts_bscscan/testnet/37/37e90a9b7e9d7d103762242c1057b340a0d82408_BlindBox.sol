pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract BlindBox is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // BlindBox Basic
    ERC20 private cuseTokenContract;
    ERC721 private cuseNftContract;
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
    event AddressList(address indexed _account, address _cuseTokenContract, address _cuseNftContract ,address _officialAddress);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event OpenPayAmount(address indexed _account, uint256 _boxOpenPayAmount);
    event OpenBox(address indexed _account, uint256 _boxJoinTotalCount, uint256 _boxOpenPayAmount,uint256 _tokenId);


    // ================= Initial Value ===============

    constructor () public {
          cuseTokenContract = ERC20(0x971f1EA8caa7eAC25246E58b59acbB7818F112D0);
          cuseNftContract = ERC721(0xfc8AE87E4Fb6760cF3D90749eb4FC9E6D0362919);
          officialAddress = address(0xF92294D80Fa5B755dE0f95492065FBda6E45a4d9);
          boxSwitchState = true;
          boxOpenPayAmount = 1000 * 10 ** 18; // 1000 coin
    }

    // ================= Box Operation  =================

    function openBox() public returns (bool) {
        // Data validation
        require(boxSwitchState,"-> boxSwitchState: box has not started yet.");
        require(cuseTokenContract.balanceOf(msg.sender)>=boxOpenPayAmount,"-> boxOpenPayAmount: Insufficient address token balance.");
        require(cuseNftContract.balanceOf(address(this))>0,"-> nft balance: Insufficient number of NFTs.");

        // Orders dispose
        boxJoinTotalCount += 1;// total number + 1
        boxPayTotalAmount += boxOpenPayAmount;
        boxAccounts[msg.sender].totalCount += 1;
        boxAccounts[msg.sender].totolProfitAmount += boxOpenPayAmount;
        boxAccounts[msg.sender].boxOrdersIndex.push(boxJoinTotalCount);// update boxAccounts

        // Calculate tokenid
        cuseNftContract.balanceOf(address(this));

        uint256 tokenId = boxTokenId();

        boxOrders[boxJoinTotalCount] = BoxOrder(boxJoinTotalCount,msg.sender,block.timestamp,tokenId,boxOpenPayAmount);// add boxOrders

        cuseTokenContract.safeTransferFrom(address(msg.sender), officialAddress, boxOpenPayAmount);// Transfer cuse to officialAddress
        cuseNftContract.sunshineTransferFrom(address(this), address(msg.sender), tokenId);// nft to this
        emit OpenBox(msg.sender, boxJoinTotalCount, boxOpenPayAmount, tokenId);// set log

        return true;// return result
    }

    function boxTokenId() public view returns (uint256 TokenId) {
        uint256 balance = cuseNftContract.balanceOf(address(this));
        uint256 random = block.timestamp;// Todo
        uint256 index = random.mod(balance);
        return cuseNftContract.tokenOfOwnerByIndex(address(this),index);
    }

    // ================= Contact Query  =====================

    function getBoxBasic() public view returns (ERC20 CuseTokenContract,ERC721 CuseNftContract,address OfficialAddress,bool BoxSwitchState,uint256 BoxStartTime,
        uint256 BoxJoinTotalCount,uint256 BoxPayTotalAmount,uint256 BoxOpenPayAmount) {
        return (cuseTokenContract,cuseNftContract,officialAddress,boxSwitchState,boxStartTime,boxJoinTotalCount,boxPayTotalAmount,boxOpenPayAmount);
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

    function setAddressList(address _cuseTokenContract,address _cuseNftContract,address _officialAddress) public onlyOwner returns (bool) {
        cuseTokenContract = ERC20(_cuseTokenContract);
        cuseNftContract = ERC721(_cuseNftContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _cuseTokenContract, _cuseNftContract, _officialAddress);
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