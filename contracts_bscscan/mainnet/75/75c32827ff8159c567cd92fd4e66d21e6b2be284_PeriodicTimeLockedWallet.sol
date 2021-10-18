// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC20.sol";

contract PeriodicTimeLockedWallet
{
    bool public initialized;
    address public owner;
    address public creator;
    uint256 public unlockDate;
    uint256 public createdAt;

    uint256 public unlockPeriod;
    uint public unlockPercentage;

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyCreator {
        require(msg.sender == creator, "Only Creator");
        _;
    }

    mapping (address => uint256) private claimedAmountOf;

    event WalletInitialized(address wallet, uint256 unlockDate);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);

    constructor(address _owner, uint256 _unlockPeriod, uint _unlockPercentage)
    {
        creator = msg.sender;
        owner = _owner;

        initialized = false;
        createdAt = block.timestamp;

        // unlockedAmount = 0;
        unlockPeriod = _unlockPeriod;
        unlockPercentage = _unlockPercentage;
    }

    function initialize(uint256 _unlockDate) external onlyCreator 
    {
        if(initialized) {
            revert("Already Initialized");
        }

        unlockDate =_unlockDate;
        initialized = true;

        emit WalletInitialized(address(this), _unlockDate);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract, uint256 _amount) external onlyOwner
    {
        uint256 unlockedTokenAmount = getUnlockedTokenAmount(_tokenContract);
        require(_amount <= unlockedTokenAmount, "Not enought unlocked tokens available");

        claimedAmountOf[_tokenContract] += _amount;

        emit WithdrewTokens(_tokenContract, owner, unlockedTokenAmount);

        ERC20 token = ERC20(_tokenContract);
        if(!token.transfer(owner, _amount)) revert();
    }

    function balance(address tokenAddress) external view returns (uint256) {
        ERC20 token = ERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    function claimed(address tokenAddress) external view returns (uint256) {
        return claimedAmountOf[tokenAddress];
    }

    function getUnlockedTokenAmount(address tokenAddress) public view returns (uint256)
    {
        if(!initialized) {
            return 0;
        }

        // the amount of tokens already unlocked and transferred
        uint256 claimedAmount = claimedAmountOf[tokenAddress];

        ERC20 token = ERC20(tokenAddress);
        uint256 totaltokenAmount = token.balanceOf(address(this)) + claimedAmount;

        int256 timeDiff = int256(block.timestamp) - int256(unlockDate);
        
        if(timeDiff < 0) 
        {
            // still locked
            return 0;
        }

        uint unlockedUnits = (uint256(timeDiff) / unlockPeriod) + 1;
        uint multiplier = unlockedUnits * unlockPercentage >= 100 ? 100 : unlockedUnits * unlockPercentage;

        return (multiplier * totaltokenAmount) / 100 - claimedAmount;
    }
}