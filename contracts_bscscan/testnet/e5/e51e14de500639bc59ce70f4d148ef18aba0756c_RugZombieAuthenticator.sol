/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity >=0.7.0 <0.9.0;

// import "./token/BEP20/IBEP20.sol";

// SPDX-License-Identifier: MIT
/**
 * @title RugZombieAuthenticator
 * @author Saad Sarwar
 */

interface IZombieToken {
    function mint(address _to, uint256 _amount) external;
    function delegates(address delegator) external view returns (address);
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function transferOwnership(address newOwner) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function liftLaunchWhaleDetection() external;
    function decimals() external view returns (uint8);
}

interface DrFrankenstein {
    struct UserInfoDrFrankenstien {
        uint256 amount;                 // How many LP tokens the user has provided.
        uint256 rewardDebt;             // Reward debt. See explanation below.
        uint256 tokenWithdrawalDate;    // Date user must wait until before early withdrawal fees are lifted.
        // User grave info
        uint256 rugDeposited;               // How many rugged tokens the user deposited.
        bool paidUnlockFee;                 // true if user paid the unlock fee.
        uint256  nftRevivalDate;            // Date user must wait until before harvesting their nft.
    }
    

    function poolLength() external view returns (uint256);
    function userInfo(uint tokenId, address userAddress) external view returns (UserInfoDrFrankenstien memory);
}
 
contract RugZombieAuthenticator{
    uint256 public totalCatacombs = 0;
    address public burnAddr = 0x000000000000000000000000000000000000dEaD; // Burn address
    uint256 public burnAmount; // Burn amount
    address public drFrankensteinAddress; // Dr Frankenstein contract address
    address public tokenContractAddress; // zombie token contract address
    IZombieToken public zombie;
    
    constructor (uint256 _burnAmount, address _drFrankenstein, address _tokenContractAddress) {
        burnAmount = _burnAmount * 10**IZombieToken(_tokenContractAddress).decimals();
        drFrankensteinAddress = _drFrankenstein;
        tokenContractAddress = _tokenContractAddress;
    }
    
      // Info of each user.
    struct UnlockedCatacombsInfo {
        uint256 amount;     // How many Zombie tokens the user has provided.
        uint256 burnDate;   // Date burned.
        uint256 catacombId; // id of the catacomb unlocked.
    }
    
    mapping (address => UnlockedCatacombsInfo) public unlockedCatacombsInfo;
    
    function getPools (address userAddress) public view returns(uint256) {
        uint256 totalAmount = 0;
        uint256 poolLength = DrFrankenstein(drFrankensteinAddress).poolLength();
        for (uint256 index = 0; index < poolLength; index++) {
            DrFrankenstein.UserInfoDrFrankenstien memory usrInfo = DrFrankenstein(drFrankensteinAddress).userInfo(index + 1, userAddress);
            totalAmount = totalAmount + usrInfo.amount;
        }
        return totalAmount;
    }
    
    function UnlockCatacombs () public returns (bool){
        // just one per wallet
        require(unlockedCatacombsInfo[msg.sender].catacombId == 0, "Only one catacomb allowed per address.");
        IZombieToken(tokenContractAddress).transferFrom(msg.sender, burnAddr, burnAmount);
        unlockedCatacombsInfo[msg.sender] = UnlockedCatacombsInfo(burnAmount, block.timestamp, totalCatacombs + 1);
        totalCatacombs = totalCatacombs + 1;
        return true;
    }
    
}