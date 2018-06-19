pragma solidity ^0.4.2;
contract token { 
    function transfer(address, uint256){  }
    function balanceOf(address) constant returns (uint256) { }
}

/// @title FairAuction contract
/// @author Christopher Grant - <<span class="__cf_email__" data-cfemail="8be8e3f9e2f8ffe4fbe3eef9cbefeee7fbe3e2a5e6eaf9e0eefff8">[email&#160;protected]</span>>
contract FairAuction {
    /* State */
    address public beneficiary;
    uint public amountRaised; uint public startTime; uint public deadline; uint public memberCount; uint public crowdsaleCap;
    uint256 public tokenSupply;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    mapping (uint => address) accountIndex;
    bool public finalized;

    /* Events */
    event TokenAllocation(address recipient, uint amount);
    event Finalized(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount);
    event FundClaim(address claimant, uint amount);

    /* Initialize relevant crowdsale contract details */
    function FairAuction(
        address fundedAddress,
        uint epochStartTime,
        uint durationInMinutes,
        uint256 capOnCrowdsale,
        token contractAddressOfRewardToken
    ) {
        beneficiary = fundedAddress;
        startTime = epochStartTime;
        deadline = startTime + (durationInMinutes * 1 minutes);
        tokenReward = token(contractAddressOfRewardToken);
        crowdsaleCap = capOnCrowdsale * 1 ether;
        finalized = false;
    }

    /* default function (called whenever funds are sent to the FairAuction) */
    function () payable {
        /* Ensure that auction is ongoing */
        if (now < startTime) throw;
        if (now >= deadline) throw;

        uint amount = msg.value;

        /* Ensure that we do not pass the cap */
        if (amountRaised + amount > crowdsaleCap) throw;

        uint256 existingBalance = balanceOf[msg.sender];

        /* Tally new members (helps iteration later) */
        if (existingBalance == 0) {
            accountIndex[memberCount] = msg.sender;
            memberCount += 1;
        } 
        
        /* Track contribution amount */
        balanceOf[msg.sender] = existingBalance + amount;
        amountRaised += amount;

        /* Fire FundTransfer event */
        FundTransfer(msg.sender, amount);
    }

    /* finalize() can be called once the FairAuction has ended, which will allow withdrawals */
    function finalize() {
        /* Nothing to finalize */
        if (amountRaised == 0) throw;

        /* Auction still ongoing */
        if (now < deadline) {
            /* Don&#39;t terminate auction before cap is reached */
            if (amountRaised < crowdsaleCap) throw;
        }

        /* Snapshot available supply of reward tokens */
        tokenSupply = tokenReward.balanceOf(this);

        /* Mark the FairAuction as finalized */
        finalized = true;
        /* Fire Finalized event */
        Finalized(beneficiary, amountRaised);
    }

    /* individualClaim() can be called by any auction participant once the FairAuction is finalized, to claim the tokens they are owed from the auction */
    function individualClaim() {
        /* Only allow once auction has been finalized */
        if (!finalized) throw;

        /* Grant tokens due */
        tokenReward.transfer(msg.sender, (balanceOf[msg.sender] * tokenSupply / amountRaised));
        /* Fire TokenAllocation event */
        TokenAllocation(msg.sender, (balanceOf[msg.sender] * tokenSupply / amountRaised));
        /* Prevent repeat-withdrawals */
        balanceOf[msg.sender] = 0;
    }

    /* beneficiarySend() can be called once the FairAuction is finalized, to send the crowdsale proceeds to their destination address */
    function beneficiarySend() {
        /* Only allow once auction has been finalized */
        if (!finalized) throw;

        /* Send proceeds to beneficiary */
        if (beneficiary.send(amountRaised)) {
            /* Fire FundClaim event */
            FundClaim(beneficiary, amountRaised);
        }
    }

    /* automaticWithdrawLoop() can be called once the FairAuction is finalized to automatically allocate a batch of auctioned tokens */
    function automaticWithdrawLoop(uint startIndex, uint endIndex) {
        /* Only allow once auction has been finalized */
        if (!finalized) throw;
        
        /* Distribute auctioned tokens fairly among a batch of participants. */
        for (uint i=startIndex; i<=endIndex && i<memberCount; i++) {
            /* Should not occur */
            if (accountIndex[i] == 0)
                continue;
            /* Grant tokens due */
            tokenReward.transfer(accountIndex[i], (balanceOf[accountIndex[i]] * tokenSupply / amountRaised));
            /* Fire TokenAllocation event */
            TokenAllocation(accountIndex[i], (balanceOf[accountIndex[i]] * tokenSupply / amountRaised));
            /* Prevent repeat-withdrawals */
            balanceOf[accountIndex[i]] = 0;
        }
    }
}