contract Token { 
    function issue(address _recipient, uint256 _value) returns (bool success) {} 
    function totalSupply() constant returns (uint256 supply) {}
    function unlock() returns (bool success) {}
}

contract SCLCrowdsale {

    // Crowdsale details
    address public beneficiary; // Company address multisig (95% funding)
    address public creator; // Creator (5% funding)
    address public confirmedBy; // Address that confirmed beneficiary
    uint256 public minAmount = 294 ether; // ≈ 250k SCL
    uint256 public maxAmount = 100000 ether; // ≈ 50 mln SCL
    uint256 public maxSupply = 50000000 * 10**8; // 50 mln SCL
    uint256 public minAcceptedAmount = 40 finney; // 1/25 ether

    // Eth to SCL rate
    uint256 public ratePreICO = 850;
    uint256 public rateWaiting = 0;
    uint256 public rateAngelDay = 750;
    uint256 public rateFirstWeek = 700;
    uint256 public rateSecondWeek = 650;
    uint256 public rateThirdWeek = 600;
    uint256 public rateLastWeek = 550;

    uint256 public ratePreICOEnd = 10 days;
    uint256 public rateWaitingEnd = 20 days;
    uint256 public rateAngelDayEnd = 21 days;
    uint256 public rateFirstWeekEnd = 28 days;
    uint256 public rateSecondWeekEnd = 35 days;
    uint256 public rateThirdWeekEnd = 42 days;
    uint256 public rateLastWeekEnd = 49 days;

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

    // SCL token
    Token public sclToken;

    // Invested balances
    mapping (address => uint256) balances;


    /**
     * Throw if at stage other than current stage
     * 
     * @param _stage expected stage to test for
     */
    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            throw;
        }
        _;
    }
    

    /**
     * Throw if sender is not beneficiary
     */
    modifier onlyBeneficiary() {
        if (beneficiary != msg.sender) {
            throw;
        }
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
     * Construct
     *
     * @param _tokenAddress The address of the SCL token contact
     */
    function SCLCrowdsale(address _tokenAddress, address _beneficiary, address _creator, uint256 _start) {
        sclToken = Token(_tokenAddress);
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
     * Convert `_wei` to an amount in SCL using 
     * the current rate
     *
     * @param _wei amount of wei to convert
     * @return The amount in SCL
     */
    function toSCL(uint256 _wei) returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended && now >= start && now <= end) {

            // Check for preico
            if (now <= start + ratePreICOEnd) {
                rate = ratePreICO;
            }

            // Check for waiting period
            else if (now <= start + rateWaitingEnd) {
                rate = rateWaiting;
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

        return _wei * rate * 10**8 / 1 ether; // 10**8 for 8 decimals
    }


    /**
     * Function to end the crowdsale by setting 
     * the stage to Ended
     */
    function endCrowdsale() atStage(Stages.InProgress) {

        // Crowdsale not ended yet
        if (now < end) {
            throw;
        }

        stage = Stages.Ended;
    }


    /**
     * Transfer appropriate percentage of raised amount 
     * to the company address
     */
    function withdraw() onlyBeneficiary atStage(Stages.Ended) {

        // Confirm that minAmount is raised
        if (raised < minAmount) {
            throw;
        }

        if (!sclToken.unlock()) {
            throw;
        }

        uint256 ethBalance = this.balance;

        // 5% eth
        uint256 ethFees = ethBalance * 5 / 10**2;
        if (!creator.send(ethFees)) {
            throw;
        }

        // 95% eth
        if (!beneficiary.send(ethBalance - ethFees)) {
            throw;
        }

        stage = Stages.Withdrawn;
    }


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end
     */
    function refund() atStage(Stages.Ended) {

        // Only allow refunds if minAmount is not raised
        if (raised >= minAmount) {
            throw;
        }

        uint256 receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }

    
    /**
     * Receives Eth and issue SCL tokens to the sender
     */
    function () payable atStage(Stages.InProgress) {

        // Crowdsale not started yet
        if (now < start) {
            throw;
        }

        // Crowdsale expired
        if (now > end) {
            throw;
        }

        // Enforce min amount
        if (msg.value < minAcceptedAmount) {
            throw;
        }
 
        uint256 received = msg.value;
        uint256 valueInSCL = toSCL(msg.value);

        // Period between pre-ico and ico
        if (valueInSCL == 0) {
            throw;
        }

        if (!sclToken.issue(msg.sender, valueInSCL)) {
            throw;
        }

        // Fees
        uint256 sclFees = valueInSCL * 5 / 10**2;

        // 5% tokens
        if (!sclToken.issue(creator, sclFees)) {
            throw;
        }

        if (now <= start + ratePreICOEnd) {

            // Fees
            uint256 ethFees = received * 5 / 10**2;

            // 5% eth
            if (!creator.send(ethFees)) {
                throw;
            }

            // During pre-ico - Non-Refundable
            if (!beneficiary.send(received - ethFees)) {
                throw;
            }

        } else {

            // During the ICO
            balances[msg.sender] += received; // 100% refundable
        }

        raised += received;

        // Check maxAmount raised
        if (raised >= maxAmount || sclToken.totalSupply() >= maxSupply) {
            stage = Stages.Ended;
        }
    }
}