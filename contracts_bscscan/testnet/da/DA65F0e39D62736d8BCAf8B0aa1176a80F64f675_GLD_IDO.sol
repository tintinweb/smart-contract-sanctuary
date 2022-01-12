pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./Token.sol";

contract GLD_IDO is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event TokensTransferred(address holder, uint256 amount);
    
    // BUSD token contract address
    address public BUSDtoken = 0x3de79403e75D1c3709Dd2bce4Adc947337dc4454;
    // Green land NFT token contract address
    address public tokenAddress = 0x786f7262Fc2f059CFF0245a2a1344AE3F4aE9024;
    
    // reward rate 350 % per year
    uint256 public rewardRate = 35000;
    uint256 public rewardInterval = 365 days;
    
    uint256 public tokenPrice = 100;
    uint256 public maximumTokenCanBuy = 3e22;
    uint256 public minimumTokenCanBuy = 1e22;

    bool public isSellPublic = false;
    bool public canWithdrawToken = false;
    
    // unstaking possible after 3 days
    uint256 public cliffTime = 3 days;
    
    uint256 public totalClaimedRewards = 0;
    
    uint256 public totalStakeAmount;
    uint256 public totalTokenBought;
    
    uint256 public depositedRewardsTokens;
    
    uint256 public stakingAndDaoTokens = 100000000e18;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint256) public depositedTokens;
    mapping (address => uint256) public stakingTime;
    mapping (address => uint256) public lastClaimedTime;
    mapping (address => uint256) public totalEarnedTokens;
    mapping (address => bool) public isWhitelisted;
    mapping (address => uint256) private _totalTokenBought;
    
    function updateAccount(address account) private {
        uint256 pendingDivs = getDivs(account);
        if (pendingDivs > 0) {
            require(Token(tokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].sub(pendingDivs);
            emit TokensTransferred(account, pendingDivs);
        }
    }
    
    function getPendingDivs(address _holder) public view returns (uint256) {
        
        uint256 pendingDivs;

        if (canWithdrawToken) {
            pendingDivs = _totalTokenBought[_holder];
        }

        if (!canWithdrawToken) {
            pendingDivs = totalTokenBought;
        }
            
        return pendingDivs;
    }
    
    function getDivs(address _holder) public view returns (uint256) {
        
        uint256 pendingDivs = _totalTokenBought[_holder];
            
        return pendingDivs;
    }
    
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }
    
    function deposit(uint256 BUSD_Amount) public {
        require(BUSD_Amount >= 1e20, "Please buy 100 to 300 BUSD equal of GLD");

        uint256 numberOfGLD = BUSD_Amount.mul(tokenPrice);

        if (!isSellPublic) {
            require(isWhitelisted[msg.sender], "Your not Whitelisted");
        }

        if (numberOfGLD <= maximumTokenCanBuy && isWhitelisted[msg.sender] && !isSellPublic) {
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance");
            depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(numberOfGLD);
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }

        if (numberOfGLD > minimumTokenCanBuy && isWhitelisted[msg.sender] && !isSellPublic) {
            numberOfGLD = maximumTokenCanBuy;
            BUSD_Amount = maximumTokenCanBuy.div(tokenPrice);
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance");
            depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(numberOfGLD);
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }

        if (numberOfGLD >= minimumTokenCanBuy && numberOfGLD <= maximumTokenCanBuy && isSellPublic) {
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance");
            depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(numberOfGLD);
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }

        if (numberOfGLD > minimumTokenCanBuy && isSellPublic) {
            numberOfGLD = maximumTokenCanBuy;
            BUSD_Amount = maximumTokenCanBuy.div(tokenPrice);
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance");
            depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(numberOfGLD);
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }
    }

    function addOnWhitelist(address[] memory _holders) public onlyOwner {
        for (uint256 _holder = 0; _holder < _holders.length; _holder++) {
            isWhitelisted[_holders[_holder]] = true;
        }
    }
    
    function withdraw() public {
        uint256 amount = Token(BUSDtoken).balanceOf(address(this));
        Token(BUSDtoken).transfer(msg.sender, amount);
        canWithdrawToken = true;
    }
    
    function claimDivs() public {
        require(canWithdrawToken, "Wait to end IDO..");
        updateAccount(msg.sender);
    }
    
    function getStakingAndDaoAmount() public view returns (uint256) {
        if (totalClaimedRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint256 remaining = stakingAndDaoTokens.sub(totalClaimedRewards);
        return remaining;
    }
    
    function setCliffTime(uint256 _time) public onlyOwner {
        cliffTime = _time;
    }
    
    function setRewardInterval(uint256 _rewardInterval) public onlyOwner {
        rewardInterval = _rewardInterval;
    }
    
    function setStakingAndDaoTokens(uint256 _stakingAndDaoTokens) public onlyOwner {
        stakingAndDaoTokens = _stakingAndDaoTokens;
    }
    
    function setRewardRate(uint256 _rewardRate) public onlyOwner {
        rewardRate = _rewardRate;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
            
            Token(_tokenAddress).transfer(_to, _amount);
    }
}