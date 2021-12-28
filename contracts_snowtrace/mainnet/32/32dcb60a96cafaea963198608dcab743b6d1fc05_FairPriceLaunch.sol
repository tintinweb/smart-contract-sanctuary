// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
import "./NRT.sol";
import "./ERC20.sol";
import "./OwnableBase.sol";
import "./SafeMath.sol";

////////////////////////////////////
//
//  Fair Price Launch Contract
//  Every gets the same price in the end
//  Users get issued a non-transferable token  and redeem for the final token
//
////////////////////////////////////
contract FairPriceLaunch is OwnableBase {
    using SafeMath for uint256;

    address public fundsRedeemer;
    // The token used for contributions
    address public investToken;

    // The Non-transferable token used for sale, redeemable for Mag
    NRT public redeemableToken;

    //Limits
    uint256 public maxInvestAllowed;
    uint256 public minInvestAllowed;
    uint256 public maxInvestRemovablePerPeriod;
    uint256 public maxGlobalInvestAllowed;
    uint256 public maxRedeemableToIssue;

    //totals
    uint256 public totalGlobalInvested;
    uint256 public totalGlobalIssued;
    uint256 public totalInvestors;

    //TIMES
    // The time that sale will begin
    uint256 public launchStartTime;
    // length of sale period
    uint256 public saleDuration;
    // launchStartTime.add(sale) durations
    uint256 public launchEndTime;
    //The delay required between investment removal
    uint256 public investRemovalDelay;
    //Prices
    uint256 public startingPrice;
    uint256 public finalPrice;

    //toggles
    // sale has started
    bool public saleEnabled;
    bool public redeemEnabled;
    bool public finalized;

    //EVENTS
    event SaleEnabled(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);

    event Invest(
        address investor,
        uint256 amount,
        uint256 totalInvested,
        uint256 price
    );
    event RemoveInvestment(
        address investor,
        uint256 amount,
        uint256 totalInvested,
        uint256 price
    );
    event IssueNRT(address investor, uint256 amount);

    //Structs

    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }

    struct InvestorInfo {
        uint256 totalInvested;
        uint256 totalRedeemed;
        uint256 totalInvestableExchanged;
        Withdrawal[] withdrawHistory;
        bool hasClaimed;
    }

    mapping(address => InvestorInfo) public investorInfoMap;
    address[] public investorList;

    constructor(
        address _fundsRedeemer,
        address _investToken,
        uint256 _launchStartTime,
        uint256 _saleDuration,
        uint256 _investRemovalDelay,
        uint256 _maxInvestAllowed,
        uint256 _minInvestAllowed,
        uint256 _maxInvestRemovablePerPeriod,
        uint256 _maxGlobalInvestAllowed,
        uint256 _maxRedeemableToIssue,
        uint256 _startingPrice,
        address _redeemableToken
    ) {
        require(
            _launchStartTime > block.timestamp,
            "Start time must be in the future."
        );
        require(
            _minInvestAllowed >= 0,
            "Min invest amount must not be negative"
        );
        require(_startingPrice >= 0, "Starting price must not be negative");
        require(_fundsRedeemer != address(0), "fundsRedeemer address is not set.");

        fundsRedeemer = _fundsRedeemer;
        investToken = _investToken;
        //times
        launchStartTime = _launchStartTime;
        require(_saleDuration < 4 days, "duration too long");
        launchEndTime = _launchStartTime.add(_saleDuration);
        saleDuration = _saleDuration;
        investRemovalDelay = _investRemovalDelay;
        //limits
        maxInvestAllowed = _maxInvestAllowed;
        minInvestAllowed = _minInvestAllowed;
        maxGlobalInvestAllowed = _maxGlobalInvestAllowed;
        maxInvestRemovablePerPeriod = _maxInvestRemovablePerPeriod;
        maxRedeemableToIssue = _maxRedeemableToIssue;
        startingPrice = _startingPrice;
        //NRT is passed in as argument and this contract needs to be set as owner
        redeemableToken = NRT(_redeemableToken);
        saleEnabled = false;
        redeemEnabled = false;
    }

    //User functions
    /**
    @dev Invests the specified amoount of investToken
     */
    function invest(uint256 amountToInvest) public {
        require(saleEnabled, "Sale is not enabled yet");
        require(block.timestamp >= launchStartTime, "Sale has not started yet");
        require(amountToInvest >= minInvestAllowed, "Invest amount too small");
        require(!hasSaleEnded(), "Sale period has ended");
        uint256 buffer = maxGlobalInvestAllowed.div(10000);
        require(
            totalGlobalInvested.add(amountToInvest) <= maxGlobalInvestAllowed + buffer,
            "Maximum Investments reached"
        );

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(
            investor.totalInvested.add(amountToInvest) <= maxInvestAllowed,
            "Max individual investment reached"
        );
        //transact
        require(
            ERC20(investToken).transferFrom(
                msg.sender,
                address(this),
                amountToInvest
            ),
            "transfer failed"
        );
        if (investor.totalInvested == 0) {
            totalInvestors += 1;
            investorList.push(msg.sender);
        }
        investor.totalInvestableExchanged += amountToInvest;
        investor.totalInvested += amountToInvest;
        totalGlobalInvested += amountToInvest;
        //continuously updates finalPrice until the last contribution is made.
        finalPrice = currentPrice();
        emit Invest(
            msg.sender,
            amountToInvest,
            totalGlobalInvested,
            finalPrice
        );
    }

    /**
    @dev Returns the total amount withdrawn by the _address during the last hour
    **/

    function getLastPeriodWithdrawals(address _address)
        public
        view
        returns (uint256 totalWithdrawLastHour)
    {
        InvestorInfo storage investor = investorInfoMap[_address];

        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        for (uint256 i = 0; i < withdrawHistory.length; i++) {
            Withdrawal memory withdraw = withdrawHistory[i];
            if (withdraw.timestamp >= block.timestamp.sub(investRemovalDelay)) {
                totalWithdrawLastHour = totalWithdrawLastHour.add(
                    withdrawHistory[i].amount
                );
            }
        }
    }

    /**
    @dev Removes the specified amount from the users totalInvested balance and returns the amount of investTokens back to them
     */
    function removeInvestment(uint256 amountToRemove) public {
        require(saleEnabled, "Sale is not enabled yet");
        require(block.timestamp >= launchStartTime, "Sale has not started yet");
        require(block.timestamp < launchEndTime, "Sale has ended");
        require(
            totalGlobalInvested < maxGlobalInvestAllowed,
            "Maximum Investments reached, deposits/withdrawal are disabled"
        );

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        //Two checks of funds to prevent over widrawal
        require(
            amountToRemove <= investor.totalInvested,
            "Cannot Remove more than invested"
        );
        
        //Make sure they can't withdraw too often.
        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        uint256 authorizedWithdraw = maxInvestRemovablePerPeriod.sub(
            getLastPeriodWithdrawals(msg.sender)
        );
        require(
            amountToRemove <= authorizedWithdraw,
            "Max withdraw reached for this hour"
        );
        withdrawHistory.push(
            Withdrawal({timestamp: block.timestamp, amount: amountToRemove})
        );
        //transact
        investor.totalInvestableExchanged += amountToRemove;
        investor.totalInvested -= amountToRemove;
        totalGlobalInvested -= amountToRemove;
        require(
            ERC20(investToken).transferFrom(
                address(this),
                msg.sender,
                amountToRemove
            ),
            "transfer failed"
        );

        finalPrice = currentPrice();

        emit RemoveInvestment(
            msg.sender,
            amountToRemove,
            totalGlobalInvested,
            finalPrice
        );
    }

       /**
    @dev Claims the NRT tokens equivalent to their contribution
     */
    function claimRedeemable() public {
        require(redeemEnabled, "redeem not enabled");
        require(block.timestamp >= launchEndTime, "Time to claim has not arrived");

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(!investor.hasClaimed, "Tokens already claimed");
        require(investor.totalInvested > 0, "No investment made");

        uint256 issueAmount = investor.totalInvested.mul(10**9).div(finalPrice);
        investor.hasClaimed = true;
        investor.totalRedeemed = issueAmount;
        totalGlobalIssued = totalGlobalIssued.add(issueAmount);
        redeemableToken.issue(msg.sender, issueAmount);
        emit IssueNRT(msg.sender, issueAmount);
    }

    //getters
    //calculates current price
    function currentPrice() public view returns (uint256) {
        uint256 price = computePrice();
        if (price <= startingPrice) {
            return startingPrice;
        } else {
            return price;
        }
    }

    function computePrice() public view returns (uint256) {
        return totalGlobalInvested.mul(1e9).div(maxRedeemableToIssue);
    }

    function hasSaleEnded() public view returns (bool) {
        return block.timestamp > launchStartTime.add(saleDuration);
    }

    //------ Owner Functions ------

    function enableSale() public onlyOwner {
        saleEnabled = true;
        emit SaleEnabled(true, block.timestamp);
    }

    function enableRedeem() public onlyOwner {
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }

    function withdrawInvestablePool() public onlyOwner {
        require(block.timestamp > launchEndTime, "Sale has not ended");
        uint256 amount = ERC20(investToken).balanceOf(address(this));
        ERC20(investToken).transfer(fundsRedeemer, amount);
        //ERC20(investToken).approve(fundsRedeemer, amount);
        //MagTreasury(fundsRedeemer).deposit(amount, investToken, amount.div(1e9));
    }

    function changeStartTime(uint256 newTime) public onlyOwner {
        require(newTime > block.timestamp, "Start time must be in the future.");
        require(block.timestamp < launchStartTime, "Sale has already started");
        launchStartTime = newTime;
        //update endTime
        launchEndTime = newTime.add(saleDuration);
    }
}