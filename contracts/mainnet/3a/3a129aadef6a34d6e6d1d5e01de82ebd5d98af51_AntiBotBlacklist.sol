//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IAntiBotBlacklist.sol";

contract AntiBotBlacklist is Ownable, IAntiBotBlacklist {
   
      
    using SafeMath for uint256;
    uint256 public blacklistLength;
     /**
     * @dev mapping store blacklist. address=>ExpirationTime 
     */
    mapping(address=>uint256) blacklist;
    
    /**
     * @dev check if the address is in the blacklist or not or expired
     */
    function blacklistCheck(address suspect) external override view returns(bool){
        return blacklist[suspect] < block.timestamp;
    }
    /**
     * @dev check if the address is in the blacklist or not
     */
    function blacklistCheckExpirationTime(address suspect) external override view returns(uint256){
        return blacklist[suspect];
    }
    /**
     * @dev Add an address to the blacklist. Only the owner can add. Owner is the address of the Governance contract.
     */
    function addSuspect(address _suspect,uint256 _expirationTime) external override onlyOwner {
        _addSuspectToBlackList(_suspect,_expirationTime);
    }
    /**
     * @dev Remove an address from the blacklist. Only the owner can remove. Owner is the address of the Governance contract.
     */
    function removeSuspect(address suspect) external override onlyOwner{
        _removeSuspectToBlackList(suspect);
    }
    /**
     * @dev Add multi address to the blacklist. Only the owner can add. Owner is the address of the Governance contract.
     */
    function dddSuspectBatch(address[] memory _addresses,uint256 _expirationTime) external override onlyOwner{
        require(_addresses.length>0,"addresses is empty");
        for(uint i=0;i<_addresses.length;i++){
            _addSuspectToBlackList(_addresses[i],_expirationTime);
        }
    }
    /**
     * @dev Remove multi address from the blacklist. Only the owner can remove. Owner is the address of the Governance contract.
     */
    function removeSuspectBatch(address[] memory _addresses) external override onlyOwner{
        require(_addresses.length>0,"addresses is empty");
        for(uint i=0;i<_addresses.length;i++){
            _removeSuspectToBlackList(_addresses[i]);
        }
    }
    /**
     * @dev internal function to add address to blacklist.
     */
    function _addSuspectToBlackList(address _suspect,uint256 _expirationTime) internal{
        require(_suspect != owner(),"the suspect cannot be owner");
        require(blacklist[_suspect]==0,"the suspect already exist");
        blacklist[_suspect] = _expirationTime;
        blacklistLength = blacklistLength.add(1);
        emit AddSuspect(_suspect);
    }
    /**
     * @dev internal function to remove address from blacklist.
     */
    function _removeSuspectToBlackList(address _suspect) internal{
        require(blacklist[_suspect]>0,"suspect is not in blacklist");
        delete blacklist[_suspect];
        blacklistLength = blacklistLength.sub(1);
        emit RemoveSuspect(_suspect);
    }
}