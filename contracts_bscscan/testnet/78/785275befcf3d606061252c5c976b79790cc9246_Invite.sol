pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Invite Basic
    bool private switchState;
    uint256 private startTime;
    address private genesisAddress;
    uint256 private nowTotalCount;

    mapping(address => address) private inviterAddress;
    mapping(address => uint256) private accountInviterCount;

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event Switch(address indexed _account, bool _switchState);
    event AddressList(address indexed _account, address _genesisAddress);
    event BindingInvitation(address indexed _account, address _inviterAddress);
    event JoinInvite(address indexed _account, uint256 _nowTotalCount);

    // ================= Initial Value ===============

    constructor () public {
          genesisAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          switchState = true;
    }

    // ================= Deposit Operation  =================

    function joinInvite(address _inviterAddress) public returns (bool) {
        // Data validation
        require(switchState,"-> switchState: Inviter has not started yet.");
        require(msg.sender!=genesisAddress,"-> genesisAddress: Genesis address cannot participate in mining.");
        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");

        // Invite dispose
        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(inviterAddress[_inviterAddress]!=address(0),"-> _inviterAddress: The invitee has not participated in the invite yet.");
            }
            inviterAddress[msg.sender] = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }else{
            require(false,"-> joinInvite: No need to add again.");
        }

        // Basic dispose
        nowTotalCount += 1;
        accountInviterCount[_inviterAddress] += 1;

        emit JoinInvite(msg.sender, nowTotalCount);
        return true;
    }

    // ================= Contact Query  =====================

    function getBasic() public view returns (bool SwitchState,uint256 StartTime,address GenesisAddress,uint256 NowTotalCount) {
        return (switchState,startTime,genesisAddress,nowTotalCount);
    }

    function inviterAddressOf(address _account) public view returns (address InviterAddress){
        return inviterAddress[_account];
    }

    function accountInviterCountOf(address _account) public view returns (uint256 InviterCount){
        return accountInviterCount[_account];
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _genesisAddress) public onlyOwner returns (bool) {
        genesisAddress = _genesisAddress;
        emit AddressList(msg.sender, _genesisAddress);
        return true;
    }

    function setSwitchState(bool _switchState) public onlyOwner returns (bool) {
        switchState = _switchState;
        if(startTime==0){
              startTime = block.timestamp;
        }
        emit Switch(msg.sender, _switchState);
        return true;
    }

}