/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

//SPDX-License-Identifier: mit

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/surveys.sol





// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract surveys is Ownable {
    // Using counters auto increment utils
    using Counters for Counters.Counter;
    Counters.Counter private _surveyPlanIDs;
    Counters.Counter private _surveyIDs;
    Counters.Counter private _answerIDs;

    // Validation metrics
    mapping(address => bool) isValidator;
    mapping(address => bool) isKYCVerified;
    mapping(address => mapping(uint256 => bool)) private surveyParticipants;
    //address, surveyID, answerID
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        private validatorParticipants;

    mapping(address => uint256) valaidatorEarnings;
    mapping(address => uint256) providerEarnings;

    //Mapping users address to survey ID and balance
    mapping(uint256 => uint256) public surveyBalance;
    //surveybalance[msg.sender][_surveyID] = balance;
    uint256 private platformCommision;
    //Validators address => surveyID => Balance
    mapping(address => mapping(uint256 => uint256)) public validatorsProfit;

    IERC20 public sonergyToken;

    // Survey Plans
    // Prep requirements for adding survey plans
    struct SurveyPlans {
        uint256 planID;
        string planName;
        uint256 minAmount;
        uint256 validatorsProfit;
        uint256 providerProfit;
        bool status;
    }

    mapping(uint256 => SurveyPlans) listOfPlans;

    event planCreated(
        uint256 planID,
        string planName,
        uint256 minAmount,
        uint256 validatorsProfit,
        uint256 providerProfit,
        bool status
    );

    // Validators Registration fees
    uint256 public validatorsFee;
    uint256 public kycVerificationFee;

    event kycStatus(address _user, bool isVerified);

    struct SurveyItem {
        address payable owner;
        uint256 surveyID;
        uint256 planID;
        uint256 numOfValidators;
        uint256 amount;
        bool nftStatus;
        bool exist;
        bool completed;
    }

    // mapping the surveyIDs to the number of existing answers
    mapping(uint256 => uint256) numberOfAnswers;
    //Mapping address to surveys
    mapping(uint256 => SurveyItem) listOfSurveys;

    event SurveyItemCreated(
        address owner,
        uint256 surveyID,
        uint256 planID,
        uint256 numOfValidators,
        uint256 amount,
        bool nftStatus,
        bool exist,
        bool completed
    );

    struct AnswerItem {
        address payable provider;
        address payable validator;
        uint256 surveyID;
        uint256 answerID;
        bool isValidated;
        bool isValid;
    }

    //surveyID'S to answerid
    mapping(uint256 => mapping(uint256 => AnswerItem)) listOfAnswers;
    //Users => surveyID's => true

    event AnswerCreated(
        address provider,
        address validator,
        uint256 surveyID,
        uint256 answerID,
        bool isValidated,
        bool isValid
    );

    constructor(
        address _TokenAddress,
        uint256 _validatorsFee,
        uint256 _kycVerificationFee
    ) {
        sonergyToken = IERC20(_TokenAddress);
        validatorsFee = _validatorsFee;
        kycVerificationFee = _kycVerificationFee;
    }

    function addSurveyPlans(
        string memory _planName,
        uint256 _minAmount,
        uint256 _validatorsPercentProfit,
        uint256 _providerProfit,
        bool _display
    ) public onlyOwner {
        _surveyPlanIDs.increment();
        uint256 newPlanID = _surveyPlanIDs.current();

        listOfPlans[newPlanID] = SurveyPlans(
            newPlanID,
            _planName,
            _minAmount,
            _validatorsPercentProfit,
            _providerProfit,
            _display
        );

        emit planCreated(
            newPlanID,
            _planName,
            _minAmount,
            _validatorsPercentProfit,
            _providerProfit,
            _display
        );
    }

    function fetchSurveyPlans() public view returns (SurveyPlans[] memory) {
        uint256 totalPlansCount = _surveyPlanIDs.current();
        uint256 itemIndex = 0;

        SurveyPlans[] memory items = new SurveyPlans[](totalPlansCount);
        // Looping through the Plans and returning the active ones
        for (uint256 i = 0; i < totalPlansCount; i++) {
            if (listOfPlans[i + 1].status == true) {
                uint256 currentID = i + 1;
                SurveyPlans storage currentPlan = listOfPlans[currentID];
                items[itemIndex] = currentPlan;
                itemIndex += 1;
            }
        }

        return items;
    }

    function editSurveyPlan(
        uint256 _planID,
        string memory _planName,
        uint256 _minAmount,
        uint256 _validatorsPercentProfit,
        uint256 _providerProfit,
        bool _display
    ) public onlyOwner {
        listOfPlans[_planID] = SurveyPlans(
            _planID,
            _planName,
            _minAmount,
            _validatorsPercentProfit,
            _providerProfit,
            _display
        );

        emit planCreated(
            _planID,
            _planName,
            _minAmount,
            _validatorsPercentProfit,
            _providerProfit,
            _display
        );
    }

    function verifyUser() public {
        require(isKYCVerified[msg.sender], "You are already verified");
        require(
            sonergyToken.allowance(msg.sender, address(this)) >=
                kycVerificationFee,
            "Non-sufficient funds to complete KYC"
        );
        isKYCVerified[msg.sender] == true;
        emit kycStatus(msg.sender, true);
    }

    function checkKYCStatus(address _user) public view returns (bool) {
        return isKYCVerified[_user];
    }

    function enrollForSurvey(
        address _user,
        uint256 _planID,
        uint256 _numOfValidators,
        uint256 _amount
    ) public payable {
        // get plan details
        require(
            _planExist(_planID) != true,
            "The Plan entered does not exist or its suspended. "
        );

        uint256 planAmount = listOfPlans[_planID].minAmount;

        require(
            _amount >= planAmount,
            "Amount must be greater then the plan Amount"
        );
        require(
            !isKYCVerified[_user],
            "You need to be verified to add a survey."
        );

        require(
            sonergyToken.allowance(_user, address(this)) >= planAmount,
            "Insufficient Sonergy Tokens Available"
        );

        // Initiate funds transfer.
        require(
            sonergyToken.transferFrom(msg.sender, address(this), _amount),
            "Failed to transfer Funds "
        );

        _surveyIDs.increment();
        uint256 newSurveyID = _surveyIDs.current();
        splitFunds(_amount, _planID, newSurveyID);

        // Create a balance for the survey
        listOfSurveys[newSurveyID] = SurveyItem(
            payable(msg.sender),
            newSurveyID,
            _planID,
            _numOfValidators,
            _amount,
            false,
            true,
            false
        );

        // Create number of validators and answer providers

        emit SurveyItemCreated(
            payable(msg.sender),
            newSurveyID,
            _planID,
            _numOfValidators,
            _amount,
            false,
            true,
            false
        );
    }

    function fetchMYSurveys() public view returns (SurveyItem[] memory) {
        uint256 totalSurveyCount = _surveyIDs.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalSurveyCount; i++) {
            if (listOfSurveys[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        SurveyItem[] memory items = new SurveyItem[](itemCount);

        for (uint256 i = 0; i < totalSurveyCount; i++) {
            if (listOfSurveys[i + 1].owner == msg.sender) {
                uint256 currentID = i + 1;
                SurveyItem storage currentItem = listOfSurveys[currentID];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function provideAnswer(uint256 _surveyID) public {
        //Check if survey exist
        require(
            !_surveyExist(_surveyID),
            "Survey ID does not exist on Sonergy"
        );
        // Check if number of answers are complete
        require(
            checkNumberOfAnswers(_surveyID),
            "This survey is already completed"
        );

        require(
            hasParticipated(_surveyID, msg.sender),
            "You cannot Provide an answer again to this survey"
        );
        // Check if its a KYC Certified user
        // Check number of Sonergy Tokens held
        // Provide Answer
        //Check if you have provided answers already

        surveyParticipants[msg.sender][_surveyID] = true;
        // require(hasProviderAnswer)

        _answerIDs.increment();
        uint256 newAnswerID = _answerIDs.current();
        listOfAnswers[_surveyID][newAnswerID] = AnswerItem(
            payable(msg.sender),
            payable(address(0)),
            _surveyID,
            newAnswerID,
            false,
            false
        );

        sendProviderFunds(msg.sender, _surveyID);

        emit AnswerCreated(
            payable(msg.sender),
            payable(address(0)),
            _surveyID,
            newAnswerID,
            false,
            false
        );
    }

    function hasParticipated(uint256 _surveyID, address _user)
        internal
        view
        returns (bool)
    {
        if (surveyParticipants[_user][_surveyID]) {
            return true;
        }
        return false;
    }

    function validateAnswer(
        uint256 _answerID,
        uint256 _surveyID,
        bool _isValid
    ) public {
        //Check if its validator
        require(
            sonergyToken.allowance(msg.sender, address(this)) >= validatorsFee,
            "You dont have the required number of SNERY tokens to be a validator."
        );

        require(
            hasValidated(_surveyID, msg.sender),
            "You have validated this answer already"
        );

        listOfAnswers[_surveyID][_answerID].isValidated = true;
        listOfAnswers[_surveyID][_answerID].isValid = _isValid;

        surveyParticipants[msg.sender][_surveyID] = true;

        sendValidatorsFunds(msg.sender, _surveyID);

        // Send validators fee
    }

    function validatorsEarning(address _user) public view returns (uint256) {
        return valaidatorEarnings[_user];
    }

    function providerEarning(address _user) public view returns (uint256) {
        return providerEarnings[_user];
    }

    function sendValidatorsFunds(address _user, uint256 surveyID) internal {
        uint256 plan = listOfSurveys[surveyID].planID;
        uint256 profit = listOfPlans[plan].validatorsProfit;
        if (profit != 0) {
            uint256 numOfValidators = listOfSurveys[surveyID].numOfValidators;
            uint256 balanceInSurvey = surveyBalance[surveyID];

            if (numOfValidators != 0) {
                uint256 earnings = ((balanceInSurvey * profit) / 100) /
                    numOfValidators;

                listOfSurveys[surveyID].numOfValidators =
                    listOfSurveys[surveyID].numOfValidators -
                    1;

                valaidatorEarnings[_user] += earnings;
            }
        }
    }

    function sendProviderFunds(address _user, uint256 surveyID) internal {
        uint256 plan = listOfSurveys[surveyID].planID;
        uint256 profit = listOfPlans[plan].providerProfit;
        if (profit != 0) {
            uint256 numOfValidators = listOfSurveys[surveyID].numOfValidators;
            uint256 balanceInSurvey = surveyBalance[surveyID];

            if (numOfValidators != 0) {
                uint256 earnings = ((balanceInSurvey * profit) / 100) /
                    numOfValidators;

                listOfSurveys[surveyID].numOfValidators =
                    listOfSurveys[surveyID].numOfValidators -
                    1;

                providerEarnings[_user] += earnings;
            }
        }
    }

    function hasValidated(uint256 _surveyID, address _user)
        internal
        view
        returns (bool)
    {
        if (surveyParticipants[_user][_surveyID]) {
            return true;
        }
        return false;
    }

    function makeNFT(uint256 _surveyID) public returns (uint256) {
        require(_surveyExist(_surveyID), "Survey does not exist");
        require(
            listOfSurveys[_surveyID].owner != msg.sender,
            "You are not the owner of the survey"
        );

        require(
            !checkNumberOfAnswers(_surveyID),
            "Survey is not completed yet."
        );

        listOfSurveys[_surveyID].nftStatus = true;
        return _surveyID;
    }

    function checkNumberOfAnswers(uint256 surveyID) internal returns (bool) {
        uint256 currentAnswers = numberOfAnswers[surveyID];
        uint256 requiredAnswers = listOfSurveys[surveyID].numOfValidators;

        if (currentAnswers == requiredAnswers) {
            listOfSurveys[surveyID].completed = true;
            return true;
        }

        return false;
    }

    function splitFunds(
        uint256 _amount,
        uint256 _planID,
        uint256 newSurveyID
    ) internal {
        uint256 valProfit = listOfPlans[_planID].validatorsProfit;
        uint256 providersProfit = listOfPlans[_planID].providerProfit;

        if (valProfit > 0 && providersProfit > 0) {
            uint256 validatorsCurrentProfit = _amount * (valProfit / 100);
            uint256 providersCurrentProfit = _amount * (providersProfit / 100);
            uint256 adminProfit = msg.value - validatorsCurrentProfit;

            platformCommision += adminProfit;
            uint256 total = validatorsCurrentProfit + providersCurrentProfit;
            surveyBalance[newSurveyID] += total;
        }
    }

    function _surveyExist(uint256 surveyID) internal view returns (bool) {
        if (listOfSurveys[surveyID].exist) {
            return true;
        }
        return false;
    }

    function _planExist(uint256 planID) internal view returns (bool) {
        if (listOfPlans[planID].status) {
            return true;
        }
        return false;
    }
}