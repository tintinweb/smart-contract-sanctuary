/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface contract2{
    function editData(address user, uint256 lockedRewards, uint256 firstBlock) external ;
    function definiteStats(address user) external view returns(uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards);
    function claimRewards(address user) external returns(bool);
    function userStats(address user) external view returns(uint256 firstBlock, uint256 claimedDays, uint256 lockedRewards, uint256 claimableRewards);
    
}

interface IERC20{

  function transfer(address recipient, uint256 amount) external returns (bool);

}

interface MCHstakingInterface {
    
    function showBlackUser(address user) external view returns(bool) ;
}

interface Icontract3{
    function withdrawLockedRewards() external ;
    event WithdrawLockedRewards(address indexed user, uint256 amount);
}
contract contract3 is Icontract3{
    
    IERC20 MCF;
    contract2 SC2;
    
    address _owner;

    uint256 private _currentBlock;
    mapping(address => uint256) private claimedMonths;
    mapping (address => bool) private _blackListed;
    
    function setCurrentBlock(uint256 number) external {
        _currentBlock = number;
    }
    
    function currentBlock() external view returns(uint256){
        return _currentBlock;
    }
    
        
    function addToBlackList(address user) external {
        require(_owner == msg.sender);
        _blackListed[user] = true;
    }
    
    constructor(address contract2Address, address MCFaddress){
        _owner = msg.sender;
        SC2 = contract2(contract2Address);
        MCF = IERC20(MCFaddress);
        
        // this.addToBlackList(this.parseAddr("0x9f08963d4f4566e94df5c6edac05a86ce7430d5c"));
        // this.addToBlackList(this.parseAddr("0x044d72125ed99d962989c09bc8eacb70b470edd8"));
        // this.addToBlackList(this.parseAddr("0xfd707a2ba4b28a4cb23b2ba73745e66f3a86fac7"));
    }
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }


    function removeFromBlackList(address user) external {
        require(_owner == msg.sender);
        _blackListed[user] = false;
    } 
    
    function claimedRewards(address user) external view returns(uint256) { 
        (, , uint256 totalLockedRewards) = SC2.definiteStats(user);
        uint256 totalLocked = totalLockedRewards/10;
        return claimedMonths[user] * totalLocked;
    }
    
    function claimableRewards(address user) external view returns(uint256) {
        (, , uint256 totalLockedRewards) = SC2.definiteStats(user);
        (,,uint256 lockedRewards,) = SC2.userStats(user);
        
        if(lockedRewards > totalLockedRewards) {totalLockedRewards = lockedRewards;}
        uint256 rewards;
        uint256 month = (_currentBlock - 12954838) / 199384;
        uint256 _claimMonths = claimedMonths[user];
        while(month > _claimMonths){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){rewards += lockedRewards; break;}
        else{rewards += totalLocked; lockedRewards -=totalLocked; }
        
        ++_claimMonths;
        }
        
        return rewards;
    }
    function withdrawLockedRewards() external override {
        require(_blackListed[msg.sender] == false);
     
        SC2.claimRewards(msg.sender);
        (uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards) = SC2.definiteStats(msg.sender);
        require(_currentBlock > 13154223 && lockedRewards > 0);
        ////////////////////////12755454
        uint256 claimedRewards;
        uint256 month = (_currentBlock - 12954838) / 199384;
        uint256 total;
        while(month > claimedMonths[msg.sender]){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){total += lockedRewards; claimedRewards += lockedRewards; lockedRewards = 0;}
        else{total += totalLocked; claimedRewards += lockedRewards; lockedRewards -=totalLocked; }
        
        ++claimedMonths[msg.sender];
        }
        
        MCF.transfer(msg.sender, total);
        SC2.editData(msg.sender, lockedRewards, firstBlock);
        
        emit WithdrawLockedRewards(msg.sender, claimedRewards);
    }
    
    function emergencyWithdraw(uint256 amount) external {
        require(msg.sender == _owner);
        MCF.transfer(msg.sender, amount);
    }
}