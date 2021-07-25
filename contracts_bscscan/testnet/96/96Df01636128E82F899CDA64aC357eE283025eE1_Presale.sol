// SPDX-License-Identifier: Unlicensed

/**

    This is the official presale contract for : https://shibaearn.com/
    TG : https://t.me/shibaearnofficial
    Twitter : https://twitter.com/ShibaEarn

    SHIBAEARN - 1st Ever Multi Chain Triple Reflection Token

*/

pragma solidity ^0.8.0;
import 'Ownable.sol';
import { ReentrancyGuard } from 'ReentrancyGuard.sol';
import { IERC20 } from 'ERC20.sol';



contract Presale is ReentrancyGuard, Ownable {
    // Maps user to the number of tokens owned
    mapping (address => uint256) public tokensOwned;
    // The block when the user claimed tokens prevously
    mapping (address => uint256) public lastTokensClaimed;
    // The number of unclaimed tokens the user has
    mapping (address => uint256) public tokensUnclaimed;
    // Whitelisted addresses
    mapping (address => bool) public whitelisted;

    bool public onlyWhitelister = false;

    IERC20 shibearnToken;

    // Sale ended
    bool isSaleActive;
    // Starting timestamp normal
    uint256 public totalTokensSold = 0;
    uint256 public tokensPerBNB = 300_000_000_000;
    uint256 bnbReceived = 0;
    bool public claimEnabled;

    uint256 public timestampStarted;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor () {
        isSaleActive = false;
        claimEnabled = false;
    }

    // Handles people sending BNB to address
    receive() external payable {
        buy(msg.sender);
    }

    function buy (address beneficiary) public payable nonReentrant {
        require(isSaleActive, "Sale is not active yet");

        address _buyer = beneficiary;
        uint256 _bnbSent = msg.value;
        uint256 tokens = _bnbSent / 1e9 * tokensPerBNB;

        require (_bnbSent >= 0.01 ether, "BNB is lesser than min value");
        require (_bnbSent <= 7 ether, "BNB is greater than max value");
        require (bnbReceived <= 1500 ether, "Hardcap reached");

        tokensOwned[_buyer] = tokensOwned[_buyer]+(tokens);

        // Changed to prevent botting of presale
        require(tokensOwned[_buyer] <= tokensPerBNB * 7 ether, "Can't buy more than 7 BNB worth of tokens");

        tokensUnclaimed[_buyer] = tokensUnclaimed[_buyer]+(tokens);
        totalTokensSold = totalTokensSold+(tokens);
        bnbReceived = bnbReceived+(msg.value);
        emit TokenBuy(beneficiary, tokens);
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        if (_isSaleActive) {
            timestampStarted = block.timestamp;
        }
        isSaleActive = _isSaleActive;
    }

    function getTokensOwned () external view returns (uint256) {
        return tokensOwned[msg.sender];
    }

    function getTokensUnclaimed () external view returns (uint256) {
        return tokensUnclaimed[msg.sender];
    }

    function getLastTokensClaimed () external view returns (uint256) {
        return lastTokensClaimed[msg.sender];
    }

    function getshibearnTokensLeft() external view returns (uint256) {
        return shibearnToken.balanceOf(address(this));
    }

    function setClaimEnabled(bool _enabled) external onlyOwner {
        claimEnabled = _enabled;
    }


    function addWhitelisters(address[] calldata accounts) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            whitelisted[accounts[i]] = true;
        }
    }

    function claimTokens() external nonReentrant {
        require (claimEnabled == true, "Claiming tokens not yet enabled.");
        require (isSaleActive == false, "Sale is still active");
        require (tokensOwned[msg.sender] > 0, "User should own some ShibaEarn tokens");
        require (tokensUnclaimed[msg.sender] > 0, "User should have unclaimed ShibaEarn tokens");
        require (shibearnToken.balanceOf(address(this)) >= tokensOwned[msg.sender], "There are not enough ShibaEarn tokens to transfer");

        tokensUnclaimed[msg.sender] = tokensUnclaimed[msg.sender]-(tokensOwned[msg.sender]);
        lastTokensClaimed[msg.sender] = block.number;

        shibearnToken.transfer(msg.sender, tokensOwned[msg.sender]);
        emit TokenClaim(msg.sender, tokensOwned[msg.sender]);
    }

    function setToken(IERC20 ShibaEarnToken) public onlyOwner {
        shibearnToken = ShibaEarnToken;
    }

    function withdrawFunds () external onlyOwner {
        payable((msg.sender)).transfer(address(this).balance);
    }

    function withdrawMarketingFunds () external onlyOwner {
        payable((msg.sender)).transfer(address(this).balance/(10));
    }

    function withdrawUnsoldTokens() external onlyOwner {
        shibearnToken.transfer(msg.sender, shibearnToken.balanceOf(address(this)));
    }
}