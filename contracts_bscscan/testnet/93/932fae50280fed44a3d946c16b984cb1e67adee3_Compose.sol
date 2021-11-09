pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Compose is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // Compose Basic
    Invite private inviteContract;
    ERC721 private magicNftContract;
    ERC721 private platinumNftContract;
    address private officialAddress;
    bool private switchState;
    uint256 private startTime;
    uint256 private joinTotalCount;
    uint256 private successCount;
    uint256 private randNonce = 0;

    // Account Info
    mapping(address => ComposeAccount) private composeAccounts;
    struct ComposeAccount {
        uint256 joinTotalCount;
        uint256 successCount;
        uint256 [] composeOrdersIndex;
    }
    mapping(uint256 => ComposeOrder) private composeOrders;
    struct ComposeOrder {
        uint256 index;
        address account;
        uint256 composeTime;
        uint256 composeTokenId;
        uint256 [] payTokens;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _magicNftContract, address _platinumNftContract ,address _officialAddress);
    event SetSwitchState(address indexed _account, bool _switchState);
    event JoinCompose(address indexed _account, uint256 _joinTotalCount, uint256 [] _payTokens, uint256 _tokenId);


    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          magicNftContract = ERC721(0xe6cCcd4F557fC5338671Aa8d64DF3bEF6BaC9Bcd);
          platinumNftContract = ERC721(0xBc363E1560fDfF55E823580E0C072959E04b5202);
          officialAddress = address(0x2A90751681279Be0CaBDC6951d7edB24803de1b4);
          switchState = false;
    }

    // ================= Compose Operation  =================

    function joinCompose(uint256 [] memory _payTokens) public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(switchState,"-> switchState: compose has not started yet.");

        uint256 payCount;
        if(_payTokens[0]<=80){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[0])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[0]);// nft1 to this
        }
        if(_payTokens[1]>=81&&_payTokens[1]<=400){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[1])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[1]);// nft1 to this
        }
        if(_payTokens[2]>=401&&_payTokens[2]<=800){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[2])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[2]);// nft1 to this
        }
        if(_payTokens[3]>=801&&_payTokens[3]<=2000){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[3])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[3]);// nft1 to this
        }
        if(_payTokens[4]>=2001&&_payTokens[4]<=4000){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[4])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[4]);// nft1 to this
        }
        if(_payTokens[5]>=4001&&_payTokens[5]<=12000){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[5])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[5]);// nft1 to this
        }
        if(_payTokens[6]>=12000&&_payTokens[5]<=40000){
            payCount += 1;
            require(magicNftContract.ownerOf(_payTokens[6])==msg.sender,"-> ownerOf: Owner does not belong to the current address.");
            magicNftContract.sunshineTransferFrom(address(msg.sender),officialAddress,_payTokens[6]);// nft1 to this
        }

        require(payCount>=7,"-> payCount: Cards must be 7 different.");

        // Calculate tokenid
        uint256 tokenId = composeTokenId();

        // Orders dispose
        joinTotalCount += 1;// total number + 1
        composeAccounts[msg.sender].joinTotalCount += 1;
        if(tokenId>0){
            successCount += 1;
            composeAccounts[msg.sender].successCount += 1; // success
            platinumNftContract.sunshineTransferFrom(address(this), address(msg.sender), tokenId);// nft2 to this
        }
        composeAccounts[msg.sender].composeOrdersIndex.push(joinTotalCount);// update composeAccounts
        composeOrders[joinTotalCount] = ComposeOrder(joinTotalCount,msg.sender,block.timestamp,tokenId,_payTokens);// add composeOrders

        emit JoinCompose(msg.sender, joinTotalCount, _payTokens, tokenId);// set log

        return true;// return result
    }

    function composeTokenId() private returns (uint256 TokenId) {
        uint256 balance = platinumNftContract.balanceOf(address(this));
        uint256 random = randomNumber();
        random = block.timestamp.add(random);
        random = random.mod(10);
        if(random >= 5){     // 50%
           uint256 index = block.timestamp.mod(balance);
           return platinumNftContract.tokenOfOwnerByIndex(address(this),index);
        }else{
           return 0;
        }
    }

    // ================= Contact Query  =====================

    function getComposeBasic() public view returns (Invite InviteContract,ERC721 MagicNftContract,ERC721 PlatinumNftContract,address OfficialAddress,bool SwitchState,uint256 StartTime,uint256 JoinTotalCount,uint256 SuccessCount) {
        return (inviteContract,magicNftContract,platinumNftContract,officialAddress,switchState,startTime,joinTotalCount,successCount);
    }

    function composeAccountOf(address _account) public view returns (uint256 JoinTotalCount,uint256 SuccessCount,uint256 [] memory ComposeOrdersIndex){
        ComposeAccount storage account = composeAccounts[_account];
        return (account.joinTotalCount,account.successCount,account.composeOrdersIndex);
    }

    function composeOrdersOf(uint256 _orderIndex) public view returns (uint256 Index,address Account,uint256 ComposeTime,uint256 ComposeTokenId,uint256 [] memory PayTokens){
        ComposeOrder storage order = composeOrders[_orderIndex];
        return (order.index,order.account,order.composeTime,order.composeTokenId,order.payTokens);
    }

    // Random return 0-9 integer
    function randomNumber() private returns(uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10;
        randNonce++;
        return rand;
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _magicNftContract,address _platinumNftContract,address _officialAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        magicNftContract = ERC721(_magicNftContract);
        platinumNftContract = ERC721(_platinumNftContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _inviteContract, _magicNftContract, _platinumNftContract, _officialAddress);
        return true;
    }

    function setSwitchState(bool _switchState) public onlyOwner returns (bool) {
        switchState = _switchState;
        if(startTime==0&&_switchState){
            startTime = block.timestamp;
        }
        emit SetSwitchState(msg.sender, _switchState);
        return true;
    }


}