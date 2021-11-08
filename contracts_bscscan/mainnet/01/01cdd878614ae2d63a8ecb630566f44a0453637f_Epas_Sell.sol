pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./Token.sol";

contract Epas_Sell is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event TokensTransferred(address holder, uint256 amount);
    
    // EPAS token contract...
    address public EPAS = 0x5806EEb6ea9FEFccEe58f7A942eCf38A148C2829;
    address public teamAddress = 0x7e612D19719901b27c168E0190C32D9Ba1991080;
    
    // unstaking possible after 10 days
    uint public constant cliffTime = 0 days;
    
    // Token rate..
    uint256 public Rate = 1e2;
    
    // Token lock time..
    uint256 public SycleTime = 20 days;
    
    uint256 public totalWithRewards;
    uint256 private stakingAndDaoTokens = 1e7;
    uint256 public WithdrawStartedAt = 0;
    
    bool public sellEnabled = false;
    bool public WithdrawEnabled = false;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint256) public depositedTokens;
    mapping (address => uint256) public totalboughtTokens;
    
    function updateAccount(address account) private {
        uint256 pendingDivs = 0;
        
        uint256 timeDiff = block.timestamp.sub(WithdrawStartedAt);
        uint256 stakedAmount = depositedTokens[account];
        
        if (timeDiff > SycleTime) {
            pendingDivs = depositedTokens[account];
        }
        
        if (timeDiff <= SycleTime) {
            pendingDivs = stakedAmount.mul(100).mul(timeDiff).div(SycleTime).div(1e2);
        }
        
        if (pendingDivs != 0) {
            Token(EPAS).transfer(msg.sender, pendingDivs);
            depositedTokens[account] = depositedTokens[account].sub(pendingDivs);
            totalboughtTokens[account] = totalboughtTokens[account].add(pendingDivs);
            totalWithRewards = totalWithRewards.add(pendingDivs);
            emit TokensTransferred(account, pendingDivs);
        }
    }
    
    function claimDivs() public {
        require(WithdrawEnabled, 'Withdraw has not enabled yet.');
        updateAccount(msg.sender);
    }
    
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }
    
    function _buyToken() public payable {
        require(msg.value > 0, "Wrong amount to buy token.");
        require(sellEnabled, "Sell has not enabled yet.");
        uint256 bnbAmount = msg.value;
        uint256 tokenAmount = Rate.mul(bnbAmount);
        
        Token(EPAS).transferFrom(teamAddress, address(this), tokenAmount);
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(tokenAmount);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
        }
    }
    
    function getStakingAndDaoAmount() public view returns (uint256) {
        if (totalWithRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint256 remaining = stakingAndDaoTokens.sub(totalWithRewards);
        return remaining;
    }
    
    // function to allow admin to set EPAS token address..
    function setEPASAddress(address _EPASAadd) public onlyOwner {
        require(sellEnabled, "Not possible to change after sell enabled.");
        EPAS = _EPASAadd;
    }
    
    // function to allow admin to set reward interval..
    function setSycleTime(uint256 _SycleTime) public onlyOwner {
        SycleTime = _SycleTime;
    }
    
    // function to allow admin to set staking and dao tokens amount..
    function setStakingAndDaoTokens(uint256 _stakingAndDaoTokens) public onlyOwner {
        stakingAndDaoTokens = _stakingAndDaoTokens;
    }
    
    // function to allow admin to set reward rate..
    function setRate(uint256 _Rate) public onlyOwner {
        Rate = _Rate;
    }
    
     // function to allow admin to enable sell..
    function startSell() external onlyOwner {
        sellEnabled = true;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_tokenAddress != EPAS, "You can't transfer EPAS token.");
        
        Token(_tokenAddress).transfer(_to, _amount);
    }
    
    function enabledWithdraw() public onlyOwner {
        WithdrawEnabled = true;
        WithdrawStartedAt = block.timestamp;
    }
    
    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }
    
    // function to allow admin to transfer BNB from this contract..
    function transferBNB(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
        sellEnabled = false;
    }
    
    receive() external payable {
        _buyToken();
    }
}