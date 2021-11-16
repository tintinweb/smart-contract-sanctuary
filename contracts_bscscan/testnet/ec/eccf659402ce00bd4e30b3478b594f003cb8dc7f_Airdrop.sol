pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
    function accountInviterCountOf(address _account) public view returns (uint256 InviterCount);
}

contract Airdrop is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Airdrop Basic
    Invite private inviteContract;
    ERC20 private macTokenContract;
    bool private airdropSwitchState;
    uint256 private airdropStartTime;
    uint256 private airdropRewardMacAmount;
    uint256 private airdropJoinTotalCount;

    // Account Info
    mapping(address => AirdropAccount) private airdropAccounts;
    struct AirdropAccount {
        bool isJoinAirdrop;
        uint256 airdropRewardMacAmount;
        uint256 rewardOrderIndex;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _macTokenContract);
    event SwitchState(address indexed _account, bool _airdropSwitchState);
    event SetAirdropRewardMacAmount(address indexed _account, uint256 _airdropRewardMacAmount);
    event JoinAirdrop(address indexed _account, uint256 _airdropJoinTotalCount, uint256 _airdropRewardMacAmount);
    event ToInviterRewards(address indexed _account, uint256 _orderIndex, uint256 _profitAmount,uint256 _rewards_level);

    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          airdropSwitchState = true;
          airdropRewardMacAmount = 10 * 10 ** 18; // 10 coin
    }

    // ================= Airdrop Operation  =================

    function toInviterRewards(address _sender,uint256 _airdropJoinTotalCount,uint256 _airdropRewardMacAmount) private returns (bool) {
        // max = 2
        address inviter = _sender;
        uint256 rewards_level;
        for(uint256 i=1;i<=2;i++){
            inviter = inviteContract.inviterAddressOf(inviter);
            if(i==1&&inviter!=address(0)){
                macTokenContract.safeTransfer(inviter, _airdropRewardMacAmount.mul(10).div(100));// Transfer mac to inviter address
            }else if(i==2&&inviter!=address(0)){
                macTokenContract.safeTransfer(inviter, _airdropRewardMacAmount.mul(5).div(100));// Transfer mac to inviter address
            }else{
                rewards_level = i.sub(1);
                i = 2021;// end for
            }
        }
        emit ToInviterRewards(_sender,_airdropJoinTotalCount,_airdropRewardMacAmount,rewards_level);
    }

    function joinAirdrop() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");
        require(inviteContract.accountInviterCountOf(msg.sender)>=5,"-> Invite: The number of people you invited has not reached 5.");

        // Data validation
        require(airdropSwitchState,"-> airdropSwitchState: airdrop has not started yet.");
        require(!airdropAccounts[msg.sender].isJoinAirdrop,"-> isJoinAirdrop: Your account has received airdrop.");

        // Orders dispose
        airdropJoinTotalCount += 1;// total number + 1
        airdropAccounts[msg.sender].isJoinAirdrop = true;
        airdropAccounts[msg.sender].airdropRewardMacAmount = airdropRewardMacAmount;
        airdropAccounts[msg.sender].rewardOrderIndex = airdropJoinTotalCount;

        toInviterRewards(msg.sender,airdropJoinTotalCount,airdropRewardMacAmount);// rewards 2

        macTokenContract.safeTransfer(address(msg.sender), airdropRewardMacAmount);// Transfer mac to airdrop address
        emit JoinAirdrop(msg.sender, airdropJoinTotalCount, airdropRewardMacAmount);// set log

        return true;// return result
    }

    // ================= Contact Query  =====================

    function getAirdropBasic() public view returns (Invite InviteContract,ERC20 MacTokenContract,bool AirdropSwitchState,uint256 AirdropStartTime,uint256 AirdropRewardMacAmount,uint256 AirdropJoinTotalCount) {
        return (inviteContract,macTokenContract,airdropSwitchState,airdropStartTime,airdropRewardMacAmount,airdropJoinTotalCount);
    }

    function airdropAccountOf(address _account) public view returns (bool isJoinAirdrop,uint256 AirdropRewardMacAmount,uint256 RewardOrderIndex){
        AirdropAccount storage account = airdropAccounts[_account];
        return (account.isJoinAirdrop,account.airdropRewardMacAmount,account.rewardOrderIndex);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _macTokenContract) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        macTokenContract = ERC20(_macTokenContract);
        emit AddressList(msg.sender, _inviteContract, _macTokenContract);
        return true;
    }

    function setAirdropSwitchState(bool _airdropSwitchState) public onlyOwner returns (bool) {
        airdropSwitchState = _airdropSwitchState;
        if(airdropStartTime==0&&_airdropSwitchState){
            airdropStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _airdropSwitchState);
        return true;
    }

    function setAirdropRewardMacAmount(uint256 _airdropRewardMacAmount) public onlyOwner returns (bool) {
        airdropRewardMacAmount = _airdropRewardMacAmount;
        emit SetAirdropRewardMacAmount(msg.sender, _airdropRewardMacAmount);
        return true;
    }

}