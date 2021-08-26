// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LBC.sol";

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}



struct Investor {                             
    mapping(uint256 => uint256) balance;        // balance[fundable]        = uint
    mapping(uint256 => uint256) interest;       // interest[fundable]       = uint
    uint256 treasuryBalance;                    // treasuryBalance          = uint

    mapping(uint256 => bool) isStaking;         // isStaking[fundable]      = boolean
    bool isInstitutional;                       // isInstitutional          = boolean
}

struct Fundable {
    string name;                                // name                     = string
    uint256 balance;                            // balance                  = uint
    uint256 goal;                               // goal                     = uint
    uint256 owed;                               // owed                     = uint          (how much the smart contract contains versus amount invested)
    uint256 interest;                           // interest                 = uint          (how much interest has been accumulated)               

    bool isFunding;                             // isFunding                = boolean
    bool isFunded;                              // isFunded                 = boolean       (not necessarily needed, simply useful for the website)
    bool isEarning;                             // isEarning                = boolean
    bool isExchangeable;                        // isExchangeable           = boolean
    bool isComplete;                            // isComplete               = boolean
    
    uint256 rate;                               // rate                     = uint          (rate at which interest is accumulated)
    uint256 start;                              // start                    = uint          (time since fund began earning)                 Period is: finish - start
    uint256 finish;                             // finish                   = uint          (time since fund finished earning)
    uint256 lendingInterest;                    // lendingInterest          = uint          (immediate interest, typically 1%)
    
    bool isContinuous;                          // isContinuous             = boolean 
    bool isFlatInterest;                        // isFlatInterest           = boolean       (whether the interest is cumulative or flat)
}   

struct Fund {
    string name;                                // name                     = string
    string supplier;                            // supplier                 = string        (this assumes that suppliers are what define funds)
    bool isComplete;                            // isComplete               = boolean
    uint256[] fundableList;                     // fundableList[index]      = uint
    uint256[] fundableRank;
}



contract InvestApp {
    string public name = "InvestApp";
    address public owner;
    LBC public lbc;
    AggregatorV3Interface private priceFeed;
    uint256 public conversionRate;
    uint256 private week = 60 * 60 * 24 * 7;

    // Works in 18 decimals, expect for converionRate (use as is)

    // ethUtil.isValidAddress(address)                  // Might use this to prevent against short address attack  (might not be necessary)

    address[] public investorList;                      // investorList[index]      = address
    mapping(address => Investor) public investors;      // investors[address]       = struct
    mapping(address => bool) public whitelist;          // whitelist[address]       = boolean

    Fund[] private funds;                               // funds[index]             = struct        (fund is a struct)
    Fundable[] private fundables;                       // fundables[index]         = struct
    uint256 private treasuryBalance;

    constructor(LBC _lbc) payable {
        lbc = _lbc;
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        owner = msg.sender;
        whitelist[owner] = true;
    }



    event DepositDistributed(
        address _investor, 
        uint256 _fund, 
        uint256 _amount
    );

    event WithdrawlProcessed(
        uint256 _fundable, 
        address _account, 
        uint256 _amount
    );

    event FundCreated(
        string _name, 
        string _supplier, 
        uint256 _fund, 
        uint256[] _fundables
    );

    event FundableCreated(
        uint256 _fundable, 
        uint256 _amount,
        uint256 _rate,
        uint256 _finish
    );

    event FundableEarning(uint256 _fundable);

    event FundableExchangeable(uint256 _fundable);

    event AccountingError(
        address _account,
        uint256 _balance,
        uint256 _lbcBalance
    );



    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier whitelisted {
        require(whitelist[msg.sender]);
        _;
    }



    // INVESTOR FUNCTIONS

    function invest(uint256 _fund) external payable whitelisted {
        // // Update Conversion Rate
        // updateConversionRate();

        // Get a converted value
        uint256 stableAmount = msg.value * conversionRate;

        // Require investment to be of value (can be set greater)
        require(
            stableAmount >= 100e18,
            "investment must be greater than $100"
        );

        // Distribute the funds
        distributeFunds(msg.sender, _fund, stableAmount);

        // Update treasuries
        treasuryBalance += investors[msg.sender].treasuryBalance;
        lbc.mint(address(this), investors[msg.sender].treasuryBalance);

        // Transfer LBC to investor
        lbc.transfer(msg.sender, stableAmount);

        // Emit a DepositDistributed event
        emit DepositDistributed(msg.sender, _fund, stableAmount);
    }

    function withdraw(uint256 _fundable) external whitelisted {
        // // Update Conversion Rate
        // updateConversionRate();

        uint256 investorBalance = investors[msg.sender].balance[_fundable];
        uint256 totalLBC = lbc.balanceOf(msg.sender);

        // Get a converted value
        uint256 stableAmount = investorBalance / conversionRate;   

        // Check and potentially update withdrawal finish
        if (fundables[_fundable].finish + week <= block.timestamp) {
            completeFundable(_fundable);
        }

        // Require investor to be staking in this fundable
        require(
            investors[msg.sender].isStaking[_fundable],
            "investor must be staking LBC in this fundable"
        ); 

        // Require fundable to be exchageable
        require(
            fundables[_fundable].isExchangeable,
            "the fundable must be within exchange window before investors can begin withdrawing their funds"
        );    

        // Make sure they have less staked than their total LBC count
        if (totalLBC < investorBalance) {
            emit AccountingError(msg.sender, investorBalance, totalLBC);
            require(
                totalLBC >= investorBalance,
                "ERROR: investorBalance > totalLBC"
            ); // might just reduce this block of code to this
        }

        // Require this contract to have necessary funds
        require(
            address(this).balance >= stableAmount,
            "contract has insufficient funds"
        );

        // Update investors staking statuses
        investors[msg.sender].balance[_fundable] = 0;
        investors[msg.sender].isStaking[_fundable] = false;

        // Perform withdraw
        lbc.burn(msg.sender, investorBalance);
        payable(msg.sender).transfer(stableAmount);

        // Emit a WithdrawlProcessed event
        emit WithdrawlProcessed(_fundable, msg.sender, stableAmount);
    }

    function investTreasury() external payable whitelisted {
        // // Update Conversion Rate
        // updateConversionRate();

        uint256 stableAmount = msg.value / conversionRate;

        emit Test(stableAmount);

        // Require all funds to be complete
        for (uint256 fund; fund < funds.length; fund++) {
            require(
                funds[fund].isComplete,
                "all funds must be complete"
            );
        }

        // Put remaining balance into investor's treasury
        treasuryBalance += stableAmount;
        lbc.mint(msg.sender, stableAmount);
        investors[msg.sender].treasuryBalance += stableAmount;
    }

    function institutionalInvestment(address _address, uint256 _fund, uint256 _amount) external onlyOwner {
        // Update list of investors
        if (!whitelist[_address]) {
            newInvestor(_address, true);
        }

        // Distribute the funds
        distributeFunds(_address, _fund, _amount);

        // Update treasuries
        treasuryBalance += investors[_address].treasuryBalance;
        lbc.mint(_address, investors[_address].treasuryBalance);

        // Transfer LBC to investor
        lbc.transfer(_address, _amount);

        // Emit a DepositDistributed event
        emit DepositDistributed(_address, _fund, _amount);
    }



    // MAINTENANCE FUNCTIONS

    function setConversionRate(uint256 _conversionRate) external onlyOwner {
        // external
        conversionRate = _conversionRate / 100;
    }

    function updateConversionRate() public { // Provided by Chainlink
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 price = uint256(answer);
        uint256 decimals = priceFeed.decimals();
        conversionRate = price / (10**decimals);
    }

    function exchangeToDAI(uint256 _amount) public onlyOwner {
                                                                            // Maybe add this at some point to keep investments stable
    }

    function issueInterest() external payable onlyOwner {
        address recipient;
        uint256 fundable;
        uint256 interest;
        uint256 totalInterest;

        // Iterate through investor
        for (uint256 investorIndex; investorIndex < investorList.length; investorIndex++) {
            
            // Assign address to recipient
            recipient = investorList[investorIndex];

            // Reset totalInterest value
            totalInterest = 0;

            // Iterate through funds
            for (uint256 fundIndex; fundIndex < funds.length; fundIndex++) {
                
                // Iterate through fundables
                for (uint256 fundableIndex; fundableIndex < funds[fundIndex].fundableList.length; fundableIndex++) {

                    fundable = funds[fundIndex].fundableList[fundableIndex];

                    // Check if the recipient is staking into this fundable
                    if (investors[recipient].isStaking[fundable]) {

                        if (fundables[fundable].isEarning && !fundables[fundable].isFlatInterest) {
                            // Award interest for each current staker
                            interest = investors[recipient].balance[fundable] * fundables[fundable].rate / 100;

                            // Update ledger
                            investors[recipient].interest[fundable] += interest;
                            investors[recipient].balance[fundable] += interest;
                            fundables[fundable].interest += interest;
                            fundables[fundable].owed += interest;

                            // Update totalInterest
                            totalInterest += interest;
                        }
                    }
                }
            }

            if (totalInterest != 0) {
                lbc.mint(recipient, totalInterest);
            }
        }
    }



    // SETUP FUNCTIONS

    function newInvestor(address _investor, bool _isInstitutional) public onlyOwner {
        // Whitelist investor
        whitelist[_investor] = true;

        // Add investor to list of investors
        investorList.push(_investor);

        // Update investor isInstitutional status
        investors[_investor].isInstitutional = _isInstitutional;
    }

    function newFund(
        string memory _name, 
        string memory _supplier, 
        string[] memory _names, 
        uint256[] memory _goals, 
        bool[] memory _areContinuous, 
        uint256[] memory _rates, 
        uint256[] memory _periods,
        uint256[] memory _lendingInterests,
        bool[] memory _isFlatInterests
    ) 
        external 
        onlyOwner 
    {
        
        // Create fund
        funds.push(Fund(
            _name, 
            _supplier,
            false, 
            new uint256[](0),
            new uint256[](0)
        ));

        // Create fundables for the fund
        for (uint256 i; i < _goals.length; i++) {
            newFundable(funds.length - 1, _names[i], _goals[i], _areContinuous[i], _rates[i], _periods[i], _lendingInterests[i], _isFlatInterests[i]);
        }       

        // Emit a FundCreated event
        emit FundCreated(_name, _supplier, funds.length - 1, funds[funds.length - 1].fundableList);

        // Empty treasury
        for (uint256 investorIndex; investorIndex < investorList.length; investorIndex++) {
            distributeFunds(investorList[investorIndex], funds.length - 1, 0);
        }
    }

    function newFundable(
        uint256 _fund, 
        string memory _name, 
        uint256 _goal, 
        bool _isContinuous, 
        uint256 _rate, 
        uint256 _period,
        uint256 _lendingInterest, 
        bool _isFlatInterest
    ) 
        public 
        onlyOwner 
    {
        // Require fund to be active
        require(
            !funds[_fund].isComplete,
            "cannot add a fundable to an already complete fund"
        );

        // Create a new fundable
        fundables.push(Fundable(
            _name,
            0,
            _goal * 1e18,
            0,
            0,
            true,
            false,
            false,
            false,
            false,
            _rate,
            0,
            _period,
            _lendingInterest,
            _isContinuous,
            _isFlatInterest
        ));

        // Add fundable to fund
        funds[_fund].fundableList.push(fundables.length - 1);
        funds[_fund].fundableRank.push(funds[_fund].fundableList.length - 1);

        // Mint necessary LBC
        if (treasuryBalance < _goal * 1e18) {
            lbc.mint(address(this), _goal * 1e18 - treasuryBalance);        // Move this to Fund to save on gas prices
            treasuryBalance = 0;
        } else {
            treasuryBalance -= _goal * 1e18;
        }
        

        // Emit fundableCreated event
        emit FundableCreated(fundables.length - 1, _goal, _rate, _period);
    }



    // FUNDABLE FUNCTIONS
    
    function drainFundable(uint256 _fundable) external onlyOwner {  // Only use this if the funding is satisfactory! //// contract might auto convert to stablecoin
        // // Update Conversion Rate
        // updateConversionRate();

        uint256 stableAmount = fundables[_fundable].balance / conversionRate;

        // Require contract balance to be greater than fundable balance
        require(stableAmount <= address(this).balance);

        // Drain fundable
        payable(owner).transfer(stableAmount);
        fundables[_fundable].owed += fundables[_fundable].balance;

        // Issue the lending interest amounts
        issueSpecificInterest(_fundable, fundables[_fundable].lendingInterest);

        // Update fundable statuses
        fundableIsEarning(_fundable);
    }

    function fillFundable(uint256 _fundable) external payable onlyOwner {
        // Update fundable status if owed is non-zero
        fundables[_fundable].owed = 0;

        // Issue isFlatInterest ( if applicable)
        if (fundables[_fundable].isFlatInterest) {
            issueSpecificInterest(_fundable, fundables[_fundable].rate);
        }

        // Update fundable status
        fundableIsExchangeable(_fundable);
    }

    function completeFundable(uint256 _fundable) public onlyOwner {
        // Require fundable to not be completed
        require(
            !fundables[_fundable].isComplete,
            "fundable is already completed!"
        );

        // Ignore if fundable is continuous
        if (!fundables[_fundable].isContinuous) {
            // Update fundable states
            fundables[_fundable].isExchangeable = false;
            fundables[_fundable].isComplete = true;

            // Rollover fundable
            rolloverFundable(_fundable);
        }
    }

    function updateRank(uint256 _fund, uint256[] memory _ranks) external onlyOwner {
        // Replace current ranks (order in which fundables are filled)
        funds[_fund].fundableRank = _ranks;
    }

    function rolloverFundable(uint256 _fundable) public onlyOwner {
        address investor;

        // Rollover any outstanding funds
        for (uint256 investorIndex; investorIndex < investorList.length; investorIndex++) {
            investor = investorList[investorIndex];
            investors[investor].treasuryBalance += investors[investor].balance[_fundable];
            investors[investor].balance[_fundable] = 0;

            // Distribute treasury contents
            distributeTreasury(investor);
        }
    }



    // FUNDABLE STATUS FUNCTIONS

    function fundableIsFunding(uint256 _fundable) private {
        require(
            fundables[_fundable].isFunding, 
            "fundable is already funded"
        );

        fundables[_fundable].isFunding = false;
        fundables[_fundable].isFunded = true;
    }

    function fundableIsEarning(uint256 _fundable) private {
        require(
            !fundables[_fundable].isEarning,
            "fundable is already earning!"
        );

        fundables[_fundable].isFunding = false;
        fundables[_fundable].isEarning = true;

        // Update start and finish time for the issuing of interest
        fundables[_fundable].start = block.timestamp;
        fundables[_fundable].finish += fundables[_fundable].start;          // this is just an estimation

        // Emit a FundableEarning event
        emit FundableEarning(_fundable);
    }
    
    function fundableIsExchangeable(uint256 _fundable) private {
        // Require fundable to not be completed
        require(
            !fundables[_fundable].isExchangeable,
            "fundable is already exchangeable!"
        );

        // Update fundable states but let continuous fundables continue to earn interest
        if (!fundables[_fundable].isContinuous) {
            fundables[_fundable].isEarning = false;
        }
        fundables[_fundable].isExchangeable = true;

        // Update finish time
        fundables[_fundable].finish = block.timestamp;

        // Emit a FundableExchangeable event
        emit FundableExchangeable(_fundable);
    }



    // MISCELLANEOUS BACKGROUND FUNCTIONS --> maybe able to make libraries for these

    function distributeFunds(address _investor, uint256 _fund, uint256 _amount) private {
        require(
            !funds[_fund].isComplete, 
            "fund is already completed and cannot accept any more funds"
        );

        uint256 fundable;
        uint256 rank;
        uint256 amount = _amount + investors[_investor].treasuryBalance;        // treasuryBalance should be zero for regular investments
        uint256 deposit;

        // Sequentially fill fund's components
        for (uint256 rankIndex; rankIndex < funds[_fund].fundableRank.length && amount > 0; rankIndex++) {

            rank = funds[_fund].fundableRank[rankIndex];
            fundable = funds[_fund].fundableList[rank];

            if (fundables[fundable].isFunding) {

                if (fundables[fundable].balance + amount <= fundables[fundable].goal) {
                    deposit = amount;
                }
                else {
                    deposit = fundables[fundable].goal - fundables[fundable].balance;
                    fundableIsFunding(fundable);
                }

                amount -= deposit;
                investors[_investor].balance[fundable] += deposit;
                fundables[fundable].balance += deposit;

                investors[_investor].isStaking[fundable] = true;
            }
        }

        // Put remaining balance into investor's treasury
        investors[_investor].treasuryBalance = amount;
        
        // Distribute remaining funds
        if (amount != 0) {
            funds[_fund].isComplete = true;
            distributeTreasury(_investor);
        }
    }

    function distributeTreasury(address _investor) private {
        for (uint256 fund; fund < funds.length && investors[_investor].treasuryBalance > 0; fund++) {
            if (!funds[fund].isComplete) {
                distributeFunds(_investor, fund, 0);
            }
        }
    }

    function issueSpecificInterest(uint256 _fundable, uint256 _rate) private {
        uint256 interest;
        address recipient;
        for (uint256 investorIndex; investorIndex < investorList.length; investorIndex++) {
            recipient = investorList[investorIndex];
            if (investors[recipient].isStaking[_fundable]) {
                interest = fundables[_fundable].balance * _rate / 100;
                investors[recipient].balance[_fundable] += interest;
                lbc.mint(recipient, interest);
            }
        }
    }



    // GETTER FUNCTIONS

    function getWhitelisted(address _account)
        external 
        view 
        returns (bool _whitelisted) 
    {
        return whitelist[_account];
    }

    function getInvestorBalance(address _investor, uint256 _fundable)
        external 
        view 
        returns (uint256 _balance) 
    {
        return investors[_investor].balance[_fundable];
    }
    
    function getIsStaking(address _investor, uint256 _fundable)
        public
        view
        returns (bool _isStaking)
    {
        return investors[_investor].isStaking[_fundable];
    }

    function getNumFunds()
        public
        view
        returns (uint _length) 
    {
        return funds.length;
    }

    function getFund(uint256 _fundIndex)
        public
        view
        returns (Fund memory _fund) 
    {
        return funds[_fundIndex];
    }

    function getNumFundables()          /// This might not be needed, as their index is found through their respective fund's fundableList
        public
        view
        returns (uint _length) 
    {
        return fundables.length;
    }

    function getFundable(uint256 _fundableIndex)
        public
        view
        returns (Fundable memory _fundable) 
    {
        return fundables[_fundableIndex];
    }





    // ============================================================== Remove after testing ============================================================== //

    event Test(uint256 _test);

    function abortTest() public onlyOwner { 
        lbc.abortTest();
        selfdestruct(payable(owner)); 
    }
}