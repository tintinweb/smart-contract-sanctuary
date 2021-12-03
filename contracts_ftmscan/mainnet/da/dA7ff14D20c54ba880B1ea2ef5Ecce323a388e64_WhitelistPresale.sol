// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract WhitelistPresale is Crowdsale, TimedCrowdsale
{
    using SafeERC20 for IERC20;

    address[] public whitelist;

    uint public hardCap;
    uint public allocationCap;

    bool public claimOpen;

    constructor(uint allocationCap_, uint hardCap_, address[] memory whitelist_, uint numerator_, uint denominator_, address wallet_, address subject_, address token_, uint openingTime, uint closingTime)
    Crowdsale(numerator_, denominator_, wallet_, IERC20(subject_), IERC20(token_))
    TimedCrowdsale(openingTime, closingTime)
    {
        whitelist = whitelist_;
        allocationCap = allocationCap_;
        hardCap = hardCap_;
        claimOpen = false;
    }

    function getPurchasableAmount(address wallet, uint amount) public view returns (uint)
    {
        if (purchasedAddresses[wallet] >= allocationCap)
            return 0;

        amount = (amount + subjectRaised) > hardCap ? (hardCap - subjectRaised) : amount;
        return amount - purchasedAddresses[wallet];
    }

    function setCap(uint hardCap_, uint allocationCap_) external onlyOwner
    {
        hardCap = hardCap_;
        allocationCap = allocationCap_;
    }

    function openClaim() external onlyOwner
    {
        claimOpen = true;
    }

    function closeClaim() external onlyOwner
    {
        claimOpen = false;
    }

    function addWallets(address[] memory wallets) external onlyOwner
    {
        for (uint i; i < wallets.length; i++)
            whitelist.push(wallets[i]);
    }

    function verify(address wallet) internal view returns (bool)
    {
        for (uint i; i < whitelist.length; i++)
            if (whitelist[i] == wallet)
                return true;

        return false;
    }

    function depositTokens(uint amount) external onlyOwner
    {
        token.safeTransferFrom(msg.sender, wallet, amount);
    }

    function buyTokens(uint amount) external onlyWhileOpen
    {
        amount = getPurchasableAmount(msg.sender, amount);

        require(amount > 0, "Presale Alert: Purchase amount is 0.");
        require(purchasedAddresses[msg.sender] + amount <= allocationCap, "Presale Alert: Purchase amount is above cap.");
        require(allocationCap - purchasedAddresses[msg.sender] <= allocationCap, "Presale Alert: User has already purchased max amount.");
        require(verify(msg.sender), "Presale Alert: Wallet is not whitelisted.");

        subject.safeTransferFrom(msg.sender, wallet, amount);

        subjectRaised += amount;
        purchasedAddresses[msg.sender] += amount;

        emit TokenPurchased(msg.sender, amount);
    }

    function claim() external nonReentrant
    {
        require(hasClosed(), "Presale Alert: Presale hasn't closed yet.");
        require(!claimed[msg.sender], "Presale Alert: Tokens already claimed.");
        require(claimOpen, "The claim hasn't been opened yet.");

        uint tokenAmount = getTokenAmount(purchasedAddresses[msg.sender]);
        require(tokenAmount > 0, "Presale Alert: Address was not a participant.");

        require(address(token) != address(0), "Presale Alert: Token hasn't been set yet.");
        token.safeTransfer(msg.sender, tokenAmount);
        claimed[msg.sender] = true;

        emit TokenClaimed(msg.sender, tokenAmount);
    }
}