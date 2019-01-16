pragma solidity ^0.5.0;

// File: contracts/interfaces/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/helpers/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/helpers/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: contracts/helpers/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d8aabdb5bbb798ea">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b3d2dfd6cbd6caf3dedacbd1cac7d6c09ddadc">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

// File: contracts/ownerships/ClusterRole.sol

contract ClusterRole {
    address private _cluster;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _cluster = msg.sender;
    }

    /**
     * @return the address of the owner.
     */
    function cluster() public view returns (address) {
        return _cluster;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyCluster() {
        require(isCluster());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isCluster() public view returns (bool) {
        return msg.sender == _cluster;
    }
}

// File: contracts/ResponsibleCrowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard, ClusterRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private _token;

    uint256 private _rate;
    uint256 private _weiRaised;
    uint256 private _tokensSold;

    struct Investor {
        uint256 eth;
        uint256 tokens;
    }

    // Get Investor token/eth balances by address
    mapping(address => Investor) internal _balances;

    event Deposited(address indexed beneficiary, uint256 weiAmount, uint256 tokensAmount);
    event EthTransfered(address indexed beneficiary,uint256 weiAmount);
    event TokensTransfered(address indexed beneficiary, uint256 tokensAmount);

    /**
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address token) public {
        _rate = rate;
        _token = IERC20(token);
    }

    // -----------------------------------------
    // EXTERNAL
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer fund with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn&#39;t be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _calculateTokensAmount(weiAmount);
        _processPurchase(beneficiary, weiAmount, tokens);

        emit Deposited(beneficiary, weiAmount, tokens);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(weiAmount != 0, "_preValidatePurchase: amount should be bigger then 0");
        require(beneficiary != address(0), "_preValidatePurchase: invalid beneficiary address");
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _calculateTokensAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn&#39;t necessarily emit/send tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal {
        _weiRaised = _weiRaised.add(weiAmount);
        _tokensSold = _tokensSold.add(tokenAmount);
        _balances[beneficiary].eth = _balances[beneficiary].eth.add(weiAmount);
        _balances[beneficiary].tokens = _balances[beneficiary].tokens.add(tokenAmount);
    }

    // -----------------------------------------
    // FUNDS INTERNAL
    // -----------------------------------------

    function _withdrawTokens(address beneficiary, uint256 amount) internal {
        _token.safeTransfer(beneficiary, amount);
        emit TokensTransfered(beneficiary, amount);
    }

    function _withdrawEther(address payable beneficiary, uint256 amount) internal {
        beneficiary.transfer(amount);
        emit EthTransfered(beneficiary, amount);
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the amount of tokens sold.
     */
    function tokensSold() public view returns (uint256) {
        return _tokensSold;
    }

    /**
     * @return the balance of tokens of crowdsale contract
     */
    function crowdsaleTokenBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @dev 1
     */
    function getInvestorBalances(address investor) public view returns (uint256, uint256) {
        return (
            _balances[investor].eth,
            _balances[investor].tokens
        );
    }
}

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime Crowdsale opening time
     * @param closingTime Crowdsale closing time
     */
    constructor (uint256 rate, address token, uint256 openingTime, uint256 closingTime) public
    Crowdsale(rate, token) {
        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}

/**
 * @title ResponsibleCrowdsale
 * @dev Main crowdsale contract
 */
contract ResponsibleCrowdsale is TimedCrowdsale {
    address payable private _user;

    bool private _milestonesSetted;

    uint256 private _milestonesAmount;
    uint256 private _approvedMilestones;
    uint256 private _withdrawProcent;
    uint256 private constant _timeForWaiting = 3 days;
    uint256 private constant _maxMilestonesAmount = 20;

    enum MilestoneStatus { PENDING, SUBMITED, APPROVED }

    struct DisputeState {
        uint256 activeDisputes;
        mapping(address => bool) isAddressOpenedDispute;
        mapping(address => bool) isAddressWinDispute;
        address[] winnedAddressList;
    }

    struct Milestone {
        bytes32 name;
        uint256 finishTimestamp;
        uint256 submitTimestamp;
        MilestoneStatus status;
        DisputeState disputes;
        bool validHash;
        mapping(address => bool) userWasWithdrawn;
    }

    // Mapping of milestones with order
    mapping(uint256 => bytes32) private _milestones;

    // Get detail of each milistone by Hash
    mapping(bytes32 => Milestone) private _milestoneDetails;

    constructor (uint256 rate, address token, uint256 openingTime, uint256 closingTime, address payable crowdsaleOwner)
    public TimedCrowdsale(rate, token, openingTime, closingTime) {
        _user = crowdsaleOwner;
    }

    // -----------------------------------------
    // OWNER FEATURES
    // -----------------------------------------

    function setMilestones(bytes32[] memory names, uint256[] memory timestamps) public onlyCluster {
        require(_milestonesSetted == false, "setMilestones: you can&#39;t set milestones twice");
        require(names.length > 0, "setMilestones: the names should be bigger of 1");
        require(timestamps.length > 0, "setMilestones: the timestamps should be bigger of 1");
        require(names.length == timestamps.length, "setMilestones: the length of names and timestamps should be the same");
        require(names.length <= _maxMilestonesAmount, "setMilestones: the amount of milestones is bigger than 20");

        for (uint256 i = 0; i < names.length; i++) {
            if (i != 0) require(timestamps[i] > timestamps[i - 1], "setMilestones: invalid milestone timestamp");

            bytes32 hash = _generateHash(names[i], timestamps[i], address(this), block.timestamp);
            _milestones[i] = hash;
            _milestoneDetails[hash] = Milestone(names[i], timestamps[i], 0, MilestoneStatus.PENDING, DisputeState(0, new address[](0)), true);
        }

        _milestonesSetted = true;
        _milestonesAmount = names.length;
        _withdrawProcent = 100 / _milestonesAmount;
    }

    function submitMilestone(bytes32 hash) public onlyCluster returns (uint256) {
        if(_approvedMilestones == 0) {
            require(crowdsaleTokenBalance() == tokensSold(), "submitMilestone: the token balance of contract is not enough");
        }
        require(hasClosed(), "submitMilestone: milestones can be released after crowdsale");
        require(_milestones[_approvedMilestones] == hash, "submitMilestone: milestones can been submitted one by one");
        require(_milestoneDetails[hash].finishTimestamp <= block.timestamp, "submitMilestone: can approve the milestone only after its deadline");
        require(_milestoneDetails[hash].status == MilestoneStatus.PENDING, "submitMilestone: the milestone has been already submitted");
        require(_milestoneDetails[hash].submitTimestamp == 0, "submitMilestone: the milestone has been already submited");
        require(_milestoneDetails[hash].validHash, "submitMilestone: the milestone hash is not valid");

        _milestoneDetails[hash].status = MilestoneStatus.SUBMITED;
        _milestoneDetails[hash].submitTimestamp = block.timestamp + _timeForWaiting;

        return _milestoneDetails[hash].submitTimestamp;
    }

    function collectMilestoneInvestment(bytes32 hash) public onlyCluster {
        require(_milestoneDetails[hash].submitTimestamp <= block.timestamp, "collectMilestoneInvestment: the time is not reached yet");
        require(_milestoneDetails[hash].status == MilestoneStatus.SUBMITED, "collectMilestoneInvestment: the milistone is not submited yet or already finished");
        require(_milestoneDetails[hash].disputes.activeDisputes == 0, "collectMilestoneInvestment: the milistone has unsolved disputes");
        require(_milestoneDetails[hash].validHash, "collectMilestoneInvestment: the milestone hash is not valid");

        _milestoneDetails[hash].status = MilestoneStatus.APPROVED;

        uint256 tokensAmount = 0;
        uint256 weiAmount = _calculatePercent(weiRaised());
        uint256 winnedDisputes = _milestoneDetails[hash].disputes.winnedAddressList.length;

        if (winnedDisputes > 0) {
            for (uint256 i = 0; i < winnedDisputes; i++) {
                uint256 investorEth = _balances[_milestoneDetails[hash].disputes.winnedAddressList[i]].eth;
                uint256 investorTokens = _balances[_milestoneDetails[hash].disputes.winnedAddressList[i]].tokens;

                weiAmount = weiAmount.sub(_calculatePercent(investorEth));
                tokensAmount = tokensAmount.add(_calculatePercent(investorTokens));
            }
        }

        _withdrawEther(_user, weiAmount);
        if(tokensAmount != 0) {
            _withdrawTokens(_user, tokensAmount);
        }

        _approvedMilestones++;
    }

    // -----------------------------------------
    // DISPUTS FEATURES
    // -----------------------------------------

    function openDispute(bytes32 hash, address investor) public onlyCluster {
        require(_milestoneDetails[hash].status == MilestoneStatus.SUBMITED, "openDispute: the milistone is not submited");
        require(_milestoneDetails[hash].disputes.isAddressOpenedDispute[investor] == false, "openDispute: the sender already was opened the dispute for this milestone");
        require(_milestoneDetails[hash].submitTimestamp > block.timestamp, "openDispute: the milestone waiting time was finished");
        require(_milestoneDetails[hash].validHash, "openDispute: the milestone hash is not valid");

        _milestoneDetails[hash].disputes.isAddressOpenedDispute[investor] = true;
        _milestoneDetails[hash].disputes.activeDisputes = _milestoneDetails[hash].disputes.activeDisputes.add(1);
    }

    function solveDispute(bytes32 hash, address investor, bool solvedToInvestor) public onlyCluster {
        require(_milestoneDetails[hash].status == MilestoneStatus.SUBMITED, "solveDispute: the milistone is not submited");
        require(_milestoneDetails[hash].disputes.activeDisputes > 0, "solveDispute: no active disputs available");
        require(_milestoneDetails[hash].validHash, "solveDispute: the milestone hash is not valid");

        if (solvedToInvestor == true) {
            _milestoneDetails[hash].disputes.isAddressWinDispute[investor] = true;
            _milestoneDetails[hash].disputes.winnedAddressList.push(investor);
        }

        _milestoneDetails[hash].disputes.activeDisputes = _milestoneDetails[hash].disputes.activeDisputes.sub(1);
    }

    // -----------------------------------------
    // INVESTOR FEATURES
    // -----------------------------------------

    function collectMilistoneResult(bytes32 hash, address payable investor) public onlyCluster {
        require(_milestoneDetails[hash].submitTimestamp <= block.timestamp, "withdrawMilestoneTokens: the time for claim funds was not comes");
        require(_milestoneDetails[hash].disputes.activeDisputes == 0, "withdrawMilestoneTokens: the milistone has unsolved disputes");
        require(_milestoneDetails[hash].userWasWithdrawn[investor] == false, "withdrawMilestoneTokens: the investor already withdrawn his tokens");
        require(_milestoneDetails[hash].validHash, "withdrawMilestoneTokens: the milestone hash is not valid");

        _milestoneDetails[hash].userWasWithdrawn[investor] = true;

        uint256 investedAmount;
        uint256 amountToSend;

        if (_milestoneDetails[hash].disputes.isAddressWinDispute[investor] == false) {
            investedAmount = _balances[investor].tokens;
            amountToSend = _calculatePercent(investedAmount);
            _withdrawTokens(investor, amountToSend);
        } else {
            investedAmount = _balances[investor].eth;
            amountToSend = _calculatePercent(investedAmount);
            _withdrawEther(investor, amountToSend);
        }
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(_milestonesSetted == true);
        super._preValidatePurchase(beneficiary, weiAmount);
    }

    function _generateHash(bytes32 name, uint256 timestamp, address crowdsale, uint256 blockTimestamp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, timestamp, crowdsale, blockTimestamp));
    }

    function _calculatePercent(uint256 amount) internal view returns (uint256) {
        return amount.div(100).mul(_withdrawProcent);
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    function isMilestonesSetted() public view returns (bool) {
        return _milestonesSetted;
    }
    
    function isMilistoneSubmited(bytes32 hash) public view returns (bool) {
        return _milestoneDetails[hash].status == MilestoneStatus.SUBMITED;
    }

    function getAllMilestonesHashes() public view returns (bytes32[] memory milestonesHashArray) {
        milestonesHashArray = new bytes32[](_milestonesAmount);
        for (uint8 i = 0; i < _milestonesAmount; i++) {
            milestonesHashArray[i] = _milestones[i];
        }
        return milestonesHashArray;
    }

    function getMilestoneHashById(uint256 id) public view returns (bytes32) {
        return _milestones[id];
    }

    function getMilestonesLength() public view returns (uint256) {
        return _milestonesAmount;
    }

    function getMilestoneDetails(bytes32 hash) public view returns (bytes32, uint256, uint256, MilestoneStatus status) {
        return (
            _milestoneDetails[hash].name,
            _milestoneDetails[hash].finishTimestamp,
            _milestoneDetails[hash].submitTimestamp,
            _milestoneDetails[hash].status
        );
    }

    function wasInvestorWithdrawn(bytes32 hash, address investor) public view returns (bool) {
        return _milestoneDetails[hash].userWasWithdrawn[investor];
    }

    function onlyInvestor(address investor) public view returns (bool) {
        return _balances[investor].eth != 0 && _balances[investor].tokens != 0;
    }
}