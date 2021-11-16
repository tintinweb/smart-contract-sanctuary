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

    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          airdropSwitchState = true;
          airdropRewardMacAmount = 10 * 10 ** 18; // 10 coin
    }

    // ================= Box Operation  =================

    function joinAirdrop() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");
        require(inviteContract.accountInviterCountOf(msg.sender)>=2,"-> Invite: The number of people you invited has not reached 5.");

        // Data validation
        require(airdropSwitchState,"-> airdropSwitchState: airdrop has not started yet.");
        require(!airdropAccounts[msg.sender].isJoinAirdrop,"-> isJoinAirdrop: Your account has received airdrop.");

        // Orders dispose
        airdropJoinTotalCount += 1;// total number + 1
        airdropRewardMacAmount += airdropRewardMacAmount;
        airdropAccounts[msg.sender].isJoinAirdrop = true;
        airdropAccounts[msg.sender].airdropRewardMacAmount = airdropRewardMacAmount;
        airdropAccounts[msg.sender].rewardOrderIndex = airdropJoinTotalCount;

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