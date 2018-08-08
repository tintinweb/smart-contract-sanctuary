pragma solidity ^0.4.15;

/*
- The ZTT pre-sale will last between September 5 to 15 with a 5% bonus payable in ZTT on all purchases.
- The ICO is expected to start September 15, 2017, and run for exactly 30 days.
- The PreICO price is 290ZTT/ETH. Bonus of 25 ZTT on the first day. The first week price is 250 ZTT/ETH. The price then increases approximately 26%/week and 3.6%/raised ZTT in multiples of minimum amount to be raised. In the first day, price is 275 - times funds raised discount factor. In first, second, third and fourth week, price is 250, 198, 157, 125 respectively times discount factor. The discount factor for each successive multiple (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, etc) of the minimum funds raised so far, of 1, .966, .933, .901, .871, .841, .812, .785, .758, .732, .707, etc.
- Tradable when issued to the public for consideration, after the ICO closes.
- Dividends of 4% per annum are payable as increased territory size
- Deputy Mayor crypto-currency governance role.
- Democratic governance applies to traffic congestion. All crowd funders who own ZTT coins are "Deputy Mayors" of their district below and may democratically advise ZeroTraffic on congested areas in their district on a regular basis. District maybe re-centered.
- Coins are optionally retractable and redeemable by ZeroTraffic, individually from each owner any time after 5 years after IOD. Once an owner is exchanged, the market price average for the last 5 days shall be used to compute payment.
- At least 1250 ZTTs&#39; are required to fill the role of Deputy Mayor.
- Price per each non-exclusive circle of radius 1/2 km, around any ZTT coin owner specified GPS point, for a map of traffic standstill congestion management advice = (1250 ZTT). Additional size regions are priced for a R&#39; km radius at (R&#39;/R)**2 *price for 1/2km radius in ZTT coin.
- To be exempt from securities laws, there is no share ownership to ZTT coin holders, right to dividends, proceeds from sales. The parties agree that the Howey test is not met: "investment of money from an expectation of profits arising from a common enterprise depending solely on the efforts of a promoter or third party". Proceeds will fund initial and continuing development and business development, depending on level of funds raised, for several years.
- Funds raised in ICO are refundable if minimum isn&#39;t met during ICO and presale, however funds raised during the PreICO are not subject to refund on minimum raise.
*/

contract Token { 
    function issue(address _recipient, uint256 _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function owner() returns (address _owner);
}

contract ZTCrowdsale {

    // Crowdsale details
    address public beneficiary; // Company address
    address public creator; // Creator address
    address public confirmedBy; // Address that confirmed beneficiary
    uint256 public minAmount = 20000 ether; 
    uint256 public maxAmount = 400000 ether; 
    uint256 public minAcceptedAmount = 40 finney; // 1/25 ether

    // Eth to ZT rate
    uint256 public ratePreICO = 290;
    uint256 public rateAngelDay = 275;
    uint256 public rateFirstWeek = 250;
    uint256 public rateSecondWeek = 198;
    uint256 public rateThirdWeek = 157;
    uint256 public rateLastWeek = 125;

    uint256 public ratePreICOEnd = 10 days;
    uint256 public rateAngelDayEnd = 11 days;
    uint256 public rateFirstWeekEnd = 18 days;
    uint256 public rateSecondWeekEnd = 25 days;
    uint256 public rateThirdWeekEnd = 32 days;
    uint256 public rateLastWeekEnd = 39 days;

    enum Stages {
        InProgress,
        Ended,
        Withdrawn
    }

    Stages public stage = Stages.InProgress;

    // Crowdsale state
    uint256 public start;
    uint256 public end;
    uint256 public raised;

    // ZT token
    Token public ztToken;

    // Invested balances
    mapping (address => uint256) balances;


    /**
     * Throw if at stage other than current stage
     * 
     * @param _stage expected stage to test for
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }


    /**
     * Throw if sender is not beneficiary
     */
    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender);
        _;
    }


    /** 
     * Get balance of `_investor` 
     * 
     * @param _investor The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }


    /**
     * Most params are hardcoded for clarity
     *
     * @param _tokenAddress The address of the ZT token contact
     */
    function ZTCrowdsale(address _tokenAddress, address _beneficiary, address _creator, uint256 _start) {
        ztToken = Token(_tokenAddress);
        beneficiary = _beneficiary;
        creator = _creator;
        start = _start;
        end = start + rateLastWeekEnd;
    }


    /**
     * For testing purposes
     *
     * @return The beneficiary address
     */
    function confirmBeneficiary() onlyBeneficiary {
        confirmedBy = msg.sender;
    }


    /**
     * Convert `_wei` to an amount in ZT using 
     * the current rate
     *
     * @param _wei amount of wei to convert
     * @return The amount in ZT
     */
    function toZT(uint256 _wei) returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended && now >= start && now <= end) {

            // Check for preico
            if (now <= start + ratePreICOEnd) {
                rate = ratePreICO;
            }

            // Check for angelday
            else if (now <= start + rateAngelDayEnd) {
                rate = rateAngelDay;
            }

            // Check first week
            else if (now <= start + rateFirstWeekEnd) {
                rate = rateFirstWeek;
            }

            // Check second week
            else if (now <= start + rateSecondWeekEnd) {
                rate = rateSecondWeek;
            }

            // Check third week
            else if (now <= start + rateThirdWeekEnd) {
                rate = rateThirdWeek;
            }

            // Check last week
            else if (now <= start + rateLastWeekEnd) {
                rate = rateLastWeek;
            }
        }

        uint256 ztAmount = _wei * rate * 10**8 / 1 ether; // 10**8 for 8 decimals

        // Increase price after min amount is reached
        if (raised > minAmount) {
            uint256 multiplier = raised / minAmount; // Remainder discarded
            for (uint256 i = 0; i < multiplier; i++) {
                ztAmount = ztAmount * 965936329 / 10**9;
            }
        }

        return ztAmount;
    }


    /**
     * Function to end the crowdsale by setting 
     * the stage to Ended
     */
    function endCrowdsale() atStage(Stages.InProgress) {

        // Crowdsale not ended yet
        require(now >= end);

        stage = Stages.Ended;
    }


    /**
     * Transfer appropriate percentage of raised amount 
     * to the company address
     */
    function withdraw() atStage(Stages.Ended) {

        // Confirm that minAmount is raised
        require(raised >= minAmount);

        uint256 ethBalance = this.balance;
        uint256 ethFees = ethBalance * 5 / 10**3; // 0.005
        creator.transfer(ethFees);
        beneficiary.transfer(ethBalance - ethFees);

        stage = Stages.Withdrawn;
    }


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end
     */
    function refund() atStage(Stages.Ended) {

        // Only allow refunds if minAmount is not raised
        require(raised < minAmount);

        uint256 receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }

    
    /**
     * Receives Eth and issue ZT tokens to the sender
     */
    function () payable atStage(Stages.InProgress) {

        // Require Crowdsale started
        require(now > start);

        // Require Crowdsale not expired
        require(now < end);

        // Enforce min amount
        require(msg.value >= minAcceptedAmount);
        
        address sender = msg.sender;
        uint256 received = msg.value;
        uint256 valueInZT = toZT(msg.value);
        if (!ztToken.issue(sender, valueInZT)) {
            revert();
        }

        if (now <= start + ratePreICOEnd) {

            // Fees
            uint256 ethFees = received * 5 / 10**3; // 0.005

            // 0.5% eth
            if (!creator.send(ethFees)) {
                revert();
            }

            // During pre-ico - Non-Refundable
            if (!beneficiary.send(received - ethFees)) {
                revert();
            }

        } else {

            // During the ICO
            balances[sender] += received; // 100% refundable
        }

        raised += received;

        // Check maxAmount raised
        if (raised >= maxAmount) {
            stage = Stages.Ended;
        }
    }
}