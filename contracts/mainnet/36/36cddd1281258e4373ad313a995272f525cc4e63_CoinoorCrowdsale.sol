pragma solidity ^0.4.15;

contract IToken { 
    function issue(address _recipient, uint256 _value) returns (bool);
    function totalSupply() constant returns (uint256);
    function unlock() returns (bool);
}

contract CoinoorCrowdsale {

    // Crowdsale details
    address public beneficiary; // Company address multisig (100% eth + 4.9 mln tokens)
    address public creator; // Creator (.25 mln tokens)
    address public marketing; // Marketing team (2.5 mln tokens)
    address public bounty; // Bounty (100k tokens)
    address public confirmedBy; // Address that confirmed beneficiary
    uint256 public maxSupply = 65000000 * 10**8; // 65 mln tokens
    uint256 public minAcceptedAmount = 40 finney; // 1/25 ether

    // Eth to CNR rate
    uint256 public ratePreICO = 450; // 50% bonus
    uint256 public rateWaiting = 0;
    uint256 public rateAngelDay = 420; // 40% bonus
    uint256 public rateFirstWeek = 390; // 30% bonus
    uint256 public rateSecondWeek = 375; // 25% bonus
    uint256 public rateThirdWeek = 360; // 20% bonus
    uint256 public rateLastWeek = 330; // 10% bonus

    uint256 public ratePreICOEnd = 10 days;
    uint256 public rateWaitingEnd = 20 days;
    uint256 public rateAngelDayEnd = 21 days;
    uint256 public rateFirstWeekEnd = 28 days;
    uint256 public rateSecondWeekEnd = 35 days;
    uint256 public rateThirdWeekEnd = 42 days;
    uint256 public rateLastWeekEnd = 49 days;

    enum Stages {
        Deploying,
        InProgress,
        Ended
    }

    Stages public stage = Stages.Deploying;

    // Crowdsale state
    uint256 public start;
    uint256 public end;
    uint256 public raised;

    // Token
    IToken public token;


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
     * Construct
     *
     * @param _tokenAddress The address of the token contact
     * @param _beneficiary The address of the beneficiary
     * @param _creator The address of the tech team
     * @param _marketing The address of the marketing team
     * @param _bounty The address of the bounty wallet
     * @param _start The timestamp of the start date
     */
    function CoinoorCrowdsale(address _tokenAddress, address _beneficiary, address _creator, address _marketing, address _bounty, uint256 _start) {
        token = IToken(_tokenAddress);
        beneficiary = _beneficiary;
        creator = _creator;
        marketing = _marketing;
        bounty = _bounty;
        start = _start;
        end = start + rateLastWeekEnd;
    }


    /**
     * Deploy and start the crowdsale
     */
    function init() atStage(Stages.Deploying) {
        stage = Stages.InProgress;

        // Create tokens
        if (!token.issue(beneficiary, 4900000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }

        if (!token.issue(creator, 2500000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }

        if (!token.issue(marketing, 2500000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }

        if (!token.issue(bounty, 100000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }
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
     * Convert `_wei` to an amount in tokens using 
     * the current rate
     *
     * @param _wei amount of wei to convert
     * @return The amount in tokens
     */
    function toTokens(uint256 _wei) returns (uint256 amount) {
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
        require(now > end);

        stage = Stages.Ended;
        if (!token.unlock()) {
            stage = Stages.InProgress;
        }
    }


    /**
     * Transfer appropriate percentage of raised amount 
     * to the company address
     */
    function withdraw() onlyBeneficiary atStage(Stages.Ended) {
        beneficiary.transfer(this.balance);
    }

    
    /**
     * Receives Eth and issue tokens to the sender
     */
    function () payable atStage(Stages.InProgress) {

        // Crowdsale not started yet
        require(now >= start);

        // Crowdsale expired
        require(now <= end);

        // Enforce min amount
        require(msg.value >= minAcceptedAmount);
 
        address sender = msg.sender;
        uint256 received = msg.value;
        uint256 valueInTokens = toTokens(received);

        // Period between pre-ico and ico
        require(valueInTokens > 0);

        // Track
        raised += received;

        // Check max supply
        if (token.totalSupply() + valueInTokens >= maxSupply) {
            stage = Stages.Ended;
        }

        // Create tokens
        if (!token.issue(sender, valueInTokens)) {
            revert();
        }

        // 100% eth
        if (!beneficiary.send(received)) {
            revert();
        }
    }
}