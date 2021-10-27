// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IBEP20.sol";

contract MysticPresale is Ownable, ReentrancyGuard {
    bool private fundByTokens = false;
    IBEP20 public fundToken;

    uint256 public startTime;
    uint256 public duration;

    uint256 public rate;
    uint256 public cap;
    uint256 public tokensSold;

    // Max sell per user in currency
    uint256 public maxSell;
    // Min contribution per TX in currency
    uint256 public minSell;

    uint256 public raised;
    uint256 public participants;

    mapping(address => uint256) public balances;

    bool public isWhitelistEnabled = false;
    mapping(address => bool) public whitelisted;

    event RateChanged(uint256 newRate);
    event MinChanged(uint256 value);
    event MaxChanged(uint256 value);
    event StartChanged(uint256 newStartTime);
    event DurationChanged(uint256 newDuration);
    event WhitelistChanged(bool newEnabled);

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _startTime, uint256 _saleDuration, uint256 _rate, uint256 _cap, bool _whitelist, address _fundToken) {
        startTime = _startTime;
        duration = _saleDuration;
        rate = _rate;
        cap = _cap;
        isWhitelistEnabled = _whitelist;
        whitelisted[msg.sender] = true;
        fundByTokens = _fundToken != address(0);
        if (fundByTokens) {
            fundToken = IBEP20(_fundToken);
        }
    }

    modifier ongoingSale(){
        require(isLive(), "Presale is not live");
        _;
    }

    function isLive() public view returns (bool) {
        return block.timestamp > startTime && block.timestamp < startTime + duration;
    }

    function getMinMaxLimits() external view returns (uint256, uint256) {
        return (minSell, maxSell);
    }

    function setMin(uint256 value) public onlyOwner {
        require(maxSell == 0 || value <= maxSell, "Must be smaller than max");
        minSell = value;
        emit MinChanged(value);
    }

    function setMax(uint256 value) public onlyOwner {
        require(minSell == 0 || value >= minSell, "Must be bigger than min");
        maxSell = value;
        emit MaxChanged(value);
    }

    function setRate(uint256 newRate) public onlyOwner {
        require(!isLive(), "Presale is live, rate change not allowed");
        rate = newRate;
        emit RateChanged(rate);
    }

    function setStartTime(uint256 newStartTime) public onlyOwner {
        startTime = newStartTime;
        emit StartChanged(startTime);
    }

    function setSaleDuration(uint256 newDuration) public onlyOwner {
        duration = newDuration;
        emit DurationChanged(duration);
    }

    function setWhitelistEnabled(bool enabled) public onlyOwner {
        isWhitelistEnabled = enabled;
        emit WhitelistChanged(enabled);
    }

    function calculatePurchaseAmount(uint purchaseAmountWei) public view returns (uint256) {
        return purchaseAmountWei * rate;
    }

    receive() external payable {
        require(!fundByTokens, "This presale is funded by tokens, use buyTokens(value)");
        buyTokens();
    }

    function buyTokens() public payable ongoingSale nonReentrant returns (bool) {
        require(!fundByTokens, "Sale: presale is funded by tokens but value is missing");
        require(!isWhitelistEnabled || whitelisted[msg.sender], "Sale: not in whitelist");

        uint256 amount = calculatePurchaseAmount(msg.value);
        require(minSell == 0 || msg.value >= minSell, "Sale: amount is too small");
        require(amount != 0, "Sale: amount is 0");
        require(tokensSold + amount <= cap, "Sale: cap reached");

        address beneficiary = msg.sender;

        tokensSold = tokensSold + amount;
        balances[beneficiary] = balances[beneficiary] + amount;

        require(maxSell == 0 || (balances[beneficiary] / rate) <= maxSell, "Sale: amount exceeds max");

        raised = raised + msg.value;
        participants = participants + 1;

        emit TokensPurchased(_msgSender(), beneficiary, msg.value, amount);
        return true;
    }

    /**
    * The fund token must be first approved to be transferred by presale contract for the given "value".
    */
    function buyTokens(uint256 value) public ongoingSale nonReentrant returns (bool) {
        require(fundByTokens, "Sale: funding by tokens is not allowed");
        require(!isWhitelistEnabled || whitelisted[msg.sender], "Sale: not whitelisted");
        require(fundToken.allowance(msg.sender, address(this)) >= value, 'Sale: fund token not approved');

        uint256 amount = calculatePurchaseAmount(value);
        require(minSell == 0 || value >= minSell, "Sale: amount is too small");
        require(amount != 0, "Sale: amount is 0");
        require(tokensSold + amount <= cap, "Sale: cap reached");

        require(fundToken.transferFrom(msg.sender, address(this), value), 'Sale: failed to transfer payment');

        address beneficiary = msg.sender;

        tokensSold = tokensSold + amount;
        balances[beneficiary] = balances[beneficiary] + amount;

        require(maxSell == 0 || (balances[beneficiary] / rate) <= maxSell, "Sale: amount exceeds max");

        raised = raised + value;
        participants = participants + 1;

        emit TokensPurchased(_msgSender(), beneficiary, value, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function withdrawBalance(uint256 amount) external onlyOwner {
        if (fundByTokens) {
            fundToken.transfer(owner(), amount);
        } else {
            payable(owner()).transfer(amount);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        if (fundByTokens && fundToken.balanceOf(address(this)) > 0) {
            fundToken.transfer(owner(), fundToken.balanceOf(address(this)));
        }
    }

    function batchAddWhitelisted(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }
}