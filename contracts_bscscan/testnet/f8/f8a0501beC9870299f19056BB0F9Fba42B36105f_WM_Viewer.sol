/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
interface LastCA {
//Testnet only
    function viewHIndexs(uint256 No_) external view returns (address);
}
interface NewCA {
    function viewAtThresholds(uint256 Tier) external view returns (bool);
    function viewIfPaidOut(uint256 Tier) external view returns (bool);
    function viewYourBuyTicketsPerTier(uint256 Tier, address Wallet) external view returns (uint256);
    function viewYourRewardTicketsPerTier(uint256 Tier, address Wallet) external view returns (uint256);
    function viewYourBonusTicketsPerTier(uint256 Tier, address Wallet) external view returns (uint256);
    function viewNoofTierTickets(uint256 Tier) external view returns (uint256);
    function viewNoofTierBuyers(uint256 Tier) external view returns (uint256);
    function viewTierWinners(uint256 Tier) external view returns (address);
    function viewTickets(uint256 Tier, uint256 TicketNo) external view returns (address);
    function viewTotalTicketsPerWallet(address Wallet) external view returns (uint256);
    function isExcludedFromFee(address account) external view returns(bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
//Testnet only
    function PlanB() external;
    function PlanC(uint256 PayoutFactor_) external;
    function AddBuyer(address to_, uint256 tickets_) external;
    function AddRewardTickets(address add_, uint256 tickets_) external;
    function EnablePayouts() external;
    function SetTierPaidOut(uint256 Tier, bool enabled_) external;
    function SetTier_AtThreshold(uint256 Tier, bool enabled_) external;
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
   function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract WM_Viewer is Ownable, NewCA, LastCA {
    using Address for address;
    address public WMCA;
    constructor () {
    }
    function viewAtThresholds(uint256 Tier) external view override returns (bool) {
        return NewCA(WMCA).viewAtThresholds(Tier);
    }
    function viewIfPaidOut(uint256 Tier) external view override returns (bool) {
          return NewCA(WMCA).viewIfPaidOut(Tier);  
    }
    function viewYourBuyTicketsPerTier(uint256 Tier, address Wallet_) external view override returns (uint256) {
        return NewCA(WMCA).viewYourBuyTicketsPerTier(Tier, Wallet_);
    }
    function viewYourRewardTicketsPerTier(uint256 Tier, address Wallet_) external view override returns (uint256) {
        return NewCA(WMCA).viewYourRewardTicketsPerTier(Tier, Wallet_);
    }
    function viewYourBonusTicketsPerTier(uint256 Tier, address Wallet_) external view override returns (uint256) {
          return NewCA(WMCA).viewYourBonusTicketsPerTier(Tier, Wallet_);  
    }
    function viewNoofTierTickets(uint256 Tier) external view override returns (uint256) {
        return NewCA(WMCA).viewNoofTierTickets(Tier);
    }
    function viewNoofTierBuyers(uint256 Tier) external view override returns (uint256) {
        return NewCA(WMCA).viewNoofTierBuyers(Tier);
    }
    function viewTierWinners(uint256 Tier) external view override returns (address) {
        return NewCA(WMCA).viewTierWinners(Tier);
    }
    function viewTickets(uint256 Tier, uint256 TicketNo) external view override returns (address) {
        return NewCA(WMCA).viewTickets(Tier, TicketNo);
    }
    function viewTotalTicketsPerWallet(address Wallet) external view override returns (uint256) {
         return NewCA(WMCA).viewTotalTicketsPerWallet(Wallet);   
    }
    function isExcludedFromFee(address account) external view override returns (bool) {
         return NewCA(WMCA).isExcludedFromFee(account);   
    }
    function name() external view override returns (string memory) {
         return NewCA(WMCA).name();   
    }
    function symbol() external view override returns (string memory) {
         return NewCA(WMCA).symbol();   
    }
    function decimals() external view override returns (uint8) {
         return NewCA(WMCA).decimals();   
    }
    function totalSupply() external view override returns (uint256) {
         return NewCA(WMCA).totalSupply();    
    }
    function balanceOf(address account) external view override returns (uint256) {
        return NewCA(WMCA).balanceOf(account);        
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
         return NewCA(WMCA).allowance(owner, spender);   
    }
//Testnet only    
    function PlanB() external override {
        return NewCA(WMCA).PlanB();   
    }
    function PlanC(uint256 PayoutFactor_) external override {
        return NewCA(WMCA).PlanC(PayoutFactor_);    
    }
//Testnet only    
    function viewHIndexs(uint256 No) external view override returns (address) {
        return LastCA(0x4c82275cC86b283Fd690230581f334302191507A).viewHIndexs(No);
    }
//Testnet only     
    function AddRewardTickets(address add_, uint256 tickets_) external override {
        NewCA(WMCA).AddRewardTickets(add_, tickets_);    
    }
//Testnet only     
    function AddBuyer(address Wallet, uint256 NoOfTickets) external override {
        NewCA(WMCA).AddBuyer(Wallet, NoOfTickets); 
    }
//Testnet only    
    function SetTierPaidOut(uint256 Tier, bool enabled_) external override {
        NewCA(WMCA).SetTierPaidOut(Tier, enabled_);
    }
    function SetTier_AtThreshold(uint256 Tier, bool enabled_) external override {
        NewCA(WMCA).SetTier_AtThreshold(Tier, enabled_);        
    }
//Testnet only    
    function EnablePayouts() external override {
         NewCA(WMCA).EnablePayouts();   
    }
//Testnet only    
    function WMAddBuyers(uint256 from, uint256 to, uint256 NoOfTickets) external {
        address _AofNoH;         
        for (uint i = from; i <= to; i++) {
            _AofNoH = LastCA(0x4c82275cC86b283Fd690230581f334302191507A).viewHIndexs(i);
            NewCA(WMCA).AddBuyer(_AofNoH, NoOfTickets);
        }
    }
//onlyOwner    
    function setContractAddress(address WMCA_) external {
        WMCA = WMCA_;
    }
}