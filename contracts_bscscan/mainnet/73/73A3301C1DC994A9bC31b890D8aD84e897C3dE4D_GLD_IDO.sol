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
    address public tokenAddress = 0x470FDBAb033193AF0B9FCC9A96EF540a2AE78268;
    
    uint256 public rewardRate;
    uint256 public rewardInterval;
    
    uint256 public tokenPrice = 100;
    uint256 public maximumTokenCanBuy = 3e22;
    uint256 public minimumTokenCanBuy = 1e22;

    bool public isSellActivedForPublic = false;
    bool public isSellEnabled = false;
    bool public canWithdrawToken = false;
    
    uint256 public cliffTime;
    
    uint256 public totalClaimedRewards;
    
    uint256 public totalStakeAmount;
    uint256 public totalTokenBought;
    
    uint256 public stakingAndDaoTokens = 100000000e18;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint256) public depositedTokens;
    mapping (address => uint256) public stakingTime;
    mapping (address => uint256) public lastClaimedTime;
    mapping (address => uint256) public totalEarnedTokens;
    mapping (address => bool) public isWhitelisted;
    mapping (address => uint256) private _totalTokenBought;

    constructor() {
        //transferOwnership(0x79962b1bC9AE16C8dDb8B1aC4BD18Ec48a796cBd);
    }
    
    function updateAccount(address account) private {
        uint256 pendingDivs = getDivs(account);
        if (pendingDivs > 0) {
            require(Token(tokenAddress).transfer(account, pendingDivs), "Could not transfer tokens..");
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
        require(BUSD_Amount >= 1e20, "Please buy 100 to 300 BUSD equal of GLD..");
        require(isSellEnabled, "Sell not enabled yet, or sell ended..");
        require(totalStakeAmount <= stakingAndDaoTokens, "All token has been sold out..");

        uint256 numberOfGLD = BUSD_Amount.mul(tokenPrice);
        uint256 remainingAmountCanBuy = (maximumTokenCanBuy).sub(_totalTokenBought[msg.sender]);
        
        if (!isSellActivedForPublic) {
            require(isWhitelisted[msg.sender], "Your not Whitelisted..");
            require(depositedTokens[msg.sender] > 0, "You have bought tokens, no more for you..");
        }

        if (isWhitelisted[msg.sender]) {
            if (numberOfGLD > remainingAmountCanBuy) {
                numberOfGLD = remainingAmountCanBuy;
                BUSD_Amount = remainingAmountCanBuy.div(tokenPrice);
            }
        }

        require(BUSD_Amount > 0, "You have bought tokens, not any more..");

        if (numberOfGLD <= maximumTokenCanBuy && isWhitelisted[msg.sender] && !isSellActivedForPublic) {
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance..");
            depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(numberOfGLD);
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }

        if (numberOfGLD > maximumTokenCanBuy && isWhitelisted[msg.sender] && !isSellActivedForPublic) {
            numberOfGLD = maximumTokenCanBuy;
            BUSD_Amount = maximumTokenCanBuy.div(tokenPrice);
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance..");
            depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(numberOfGLD);
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }

        if (numberOfGLD <= maximumTokenCanBuy && isSellActivedForPublic) {
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance..");
            
            uint256 tokenAmount = depositedTokens[msg.sender];
            if (tokenAmount > 0) {
                depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(tokenAmount);
            }
            
            totalStakeAmount = totalStakeAmount.add(numberOfGLD);
            totalTokenBought = totalTokenBought.add(numberOfGLD);
            totalEarnedTokens[msg.sender] = totalEarnedTokens[msg.sender].add(numberOfGLD);
            _totalTokenBought[msg.sender] = _totalTokenBought[msg.sender].add(numberOfGLD);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            }
        }

        if (numberOfGLD > maximumTokenCanBuy && isSellActivedForPublic) {
            numberOfGLD = maximumTokenCanBuy;
            BUSD_Amount = maximumTokenCanBuy.div(tokenPrice);
            require(Token(BUSDtoken).transferFrom(msg.sender, address(this), BUSD_Amount), "Insufficient Token Allowance..");
            
            uint256 tokenAmount = depositedTokens[msg.sender];
            if (tokenAmount > 0) {
                depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(tokenAmount);
            }
            
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
        for (uint256 i = 0; i < _holders.length; i++) {
            isWhitelisted[_holders[i]] = true;
            depositedTokens[_holders[i]] = depositedTokens[_holders[i]].add(maximumTokenCanBuy);
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 amount = Token(BUSDtoken).balanceOf(address(this));
        Token(BUSDtoken).transfer(msg.sender, amount);
    }

    function enableTokensWithdraw() public onlyOwner {
        require(!canWithdrawToken, "Already enabled..");
        canWithdrawToken = true;
    }

    function disableTokensWithdraw() public onlyOwner {
        require(canWithdrawToken, "Already disabled..");
        canWithdrawToken = false;
    }

    function enableForPublic() public onlyOwner {
        require(!isSellActivedForPublic, "Already enabled..");
        isSellActivedForPublic = true;
    }

    function disableForPublic() public onlyOwner {
        require(isSellActivedForPublic, "Already disabled..");
        isSellActivedForPublic = false;
    }

    function enableTokenSell() public onlyOwner {
        require(!isSellEnabled, "Already enabled..");
        isSellEnabled = true;
    }

    function disableTokenSell() public onlyOwner {
        require(isSellEnabled, "Already disabled..");
        isSellEnabled = false;
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
    
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }
    
    function setMaximumTokenAmountForBuy(uint256 _tokenAmount) public onlyOwner {
        maximumTokenCanBuy = _tokenAmount;
    }
    
    function setMinimumTokenAmountForBuy(uint256 _tokenAmount) public onlyOwner {
        minimumTokenCanBuy = _tokenAmount;
    }
    
    function setBUSDTokenAddress(address _tokenAdd) public onlyOwner {
        BUSDtoken = _tokenAdd;
    }
    
    function setGLDTokenAddress(address _tokenAdd) public onlyOwner {
        tokenAddress = _tokenAdd;
    }

    function setTotalTokenBoughtAmount(uint256 amount) public onlyOwner {
        totalTokenBought = amount;
    }

    function transferBNB() public {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // function to allow admin to claim *any* BEP20 tokens sent to this contract
    function transferAnyBEP20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
            Token(_tokenAddress).transfer(_to, _amount);
    }

    receive() external payable {

    }
}