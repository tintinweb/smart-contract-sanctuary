pragma solidity 0.4.25;

// File: contracts/contract_address_locator/interfaces/IContractAddressLocator.sol

/**
 * @title Contract Address Locator Interface.
 */
interface IContractAddressLocator {
    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) external view returns (address);

    /**
     * @dev Determine whether or not a contract address relates to one of the identifiers.
     * @param _contractAddress The contract address to look for.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the contract address relates to one of the identifiers.
     */
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

// File: contracts/contract_address_locator/ContractAddressLocatorHolder.sol

/**
 * @title Contract Address Locator Holder.
 * @dev Hold a contract address locator, which maps a unique identifier to every contract address in the system.
 * @dev Any contract which inherits from this contract can retrieve the address of any contract in the system.
 * @dev Thus, any contract can remain "oblivious" to the replacement of any other contract in the system.
 * @dev In addition to that, any function in any contract can be restricted to a specific caller.
 */
contract ContractAddressLocatorHolder {
    bytes32 internal constant _IAuthorizationDataSource_ = "IAuthorizationDataSource";
    bytes32 internal constant _ISGNConversionManager_    = "ISGNConversionManager"      ;
    bytes32 internal constant _IModelDataSource_         = "IModelDataSource"        ;
    bytes32 internal constant _IPaymentHandler_          = "IPaymentHandler"            ;
    bytes32 internal constant _IPaymentManager_          = "IPaymentManager"            ;
    bytes32 internal constant _IPaymentQueue_            = "IPaymentQueue"              ;
    bytes32 internal constant _IReconciliationAdjuster_  = "IReconciliationAdjuster"      ;
    bytes32 internal constant _IIntervalIterator_        = "IIntervalIterator"       ;
    bytes32 internal constant _IMintHandler_             = "IMintHandler"            ;
    bytes32 internal constant _IMintListener_            = "IMintListener"           ;
    bytes32 internal constant _IMintManager_             = "IMintManager"            ;
    bytes32 internal constant _IPriceBandCalculator_     = "IPriceBandCalculator"       ;
    bytes32 internal constant _IModelCalculator_         = "IModelCalculator"        ;
    bytes32 internal constant _IRedButton_               = "IRedButton"              ;
    bytes32 internal constant _IReserveManager_          = "IReserveManager"         ;
    bytes32 internal constant _ISagaExchanger_           = "ISagaExchanger"          ;
    bytes32 internal constant _ISogurExchanger_           = "ISogurExchanger"          ;
    bytes32 internal constant _SgnToSgrExchangeInitiator_ = "SgnToSgrExchangeInitiator"          ;
    bytes32 internal constant _IMonetaryModel_               = "IMonetaryModel"              ;
    bytes32 internal constant _IMonetaryModelState_          = "IMonetaryModelState"         ;
    bytes32 internal constant _ISGRAuthorizationManager_ = "ISGRAuthorizationManager";
    bytes32 internal constant _ISGRToken_                = "ISGRToken"               ;
    bytes32 internal constant _ISGRTokenManager_         = "ISGRTokenManager"        ;
    bytes32 internal constant _ISGRTokenInfo_         = "ISGRTokenInfo"        ;
    bytes32 internal constant _ISGNAuthorizationManager_ = "ISGNAuthorizationManager";
    bytes32 internal constant _ISGNToken_                = "ISGNToken"               ;
    bytes32 internal constant _ISGNTokenManager_         = "ISGNTokenManager"        ;
    bytes32 internal constant _IMintingPointTimersManager_             = "IMintingPointTimersManager"            ;
    bytes32 internal constant _ITradingClasses_          = "ITradingClasses"         ;
    bytes32 internal constant _IWalletsTradingLimiterValueConverter_        = "IWalletsTLValueConverter"       ;
    bytes32 internal constant _BuyWalletsTradingDataSource_       = "BuyWalletsTradingDataSource"      ;
    bytes32 internal constant _SellWalletsTradingDataSource_       = "SellWalletsTradingDataSource"      ;
    bytes32 internal constant _WalletsTradingLimiter_SGNTokenManager_          = "WalletsTLSGNTokenManager"         ;
    bytes32 internal constant _BuyWalletsTradingLimiter_SGRTokenManager_          = "BuyWalletsTLSGRTokenManager"         ;
    bytes32 internal constant _SellWalletsTradingLimiter_SGRTokenManager_          = "SellWalletsTLSGRTokenManager"         ;
    bytes32 internal constant _IETHConverter_             = "IETHConverter"   ;
    bytes32 internal constant _ITransactionLimiter_      = "ITransactionLimiter"     ;
    bytes32 internal constant _ITransactionManager_      = "ITransactionManager"     ;
    bytes32 internal constant _IRateApprover_      = "IRateApprover"     ;
    bytes32 internal constant _SGAToSGRInitializer_      = "SGAToSGRInitializer"     ;

    IContractAddressLocator private contractAddressLocator;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) internal {
        require(_contractAddressLocator != address(0), "locator is illegal");
        contractAddressLocator = _contractAddressLocator;
    }

    /**
     * @dev Get the contract address locator.
     * @return The contract address locator.
     */
    function getContractAddressLocator() external view returns (IContractAddressLocator) {
        return contractAddressLocator;
    }

    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) internal view returns (address) {
        return contractAddressLocator.getContractAddress(_identifier);
    }



    /**
     * @dev Determine whether or not the sender relates to one of the identifiers.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the sender relates to one of the identifiers.
     */
    function isSenderAddressRelates(bytes32[] _identifiers) internal view returns (bool) {
        return contractAddressLocator.isContractAddressRelates(msg.sender, _identifiers);
    }

    /**
     * @dev Verify that the caller is mapped to a given identifier.
     * @param _identifier The identifier.
     */
    modifier only(bytes32 _identifier) {
        require(msg.sender == getContractAddress(_identifier), "caller is illegal");
        _;
    }

}

// File: contracts/sogur/interfaces/ISGRAuthorizationManager.sol

/**
 * @title SGR Authorization Manager Interface.
 */
interface ISGRAuthorizationManager {
    /**
     * @dev Determine whether or not a user is authorized to buy SGR.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedToBuy(address _sender) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to sell SGR.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedToSell(address _sender) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to transfer SGR to another user.
     * @param _sender The address of the source user.
     * @param _target The address of the target user.
     * @return Authorization status.
     */
    function isAuthorizedToTransfer(address _sender, address _target) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized to transfer SGR from one user to another user.
     * @param _sender The address of the custodian user.
     * @param _source The address of the source user.
     * @param _target The address of the target user.
     * @return Authorization status.
     */
    function isAuthorizedToTransferFrom(address _sender, address _source, address _target) external view returns (bool);

    /**
     * @dev Determine whether or not a user is authorized for public operation.
     * @param _sender The address of the user.
     * @return Authorization status.
     */
    function isAuthorizedForPublicOperation(address _sender) external view returns (bool);
}

// File: contracts/voting/ProposalVoting.sol

/**
 * @title Proposal Voting.
 */
contract ProposalVoting is ContractAddressLocatorHolder {
    string public constant VERSION = "1.0.0";

    string public description;

    uint256 public choicesCount;

    mapping(address => uint256) public votes;

    address[] public voters;

    uint256 public startBlock;
    uint256 public endBlock;

    event ProposalVoteCasted(address indexed voter, uint256 choice);

    /*
    * @dev Create the contract.
    * @param _contractAddressLocator The contract address locator.
    * @param _description The voting description.
    * @param _startBlock The voting start block.
    * @param _endBlock The voting end block.
    * @param _choicesCount Choices count.
    */
    constructor(IContractAddressLocator _contractAddressLocator, string _description, uint256 _startBlock, uint256 _endBlock, uint256 _choicesCount) ContractAddressLocatorHolder(_contractAddressLocator) public
    {

        require(_startBlock > block.number, "invalid start block");
        require(_endBlock > _startBlock, "invalid end block");
        require(_choicesCount <= 4, "invalid choices count");

        bytes memory _bytes = bytes(_description);
        require(_bytes.length != 0, "invalid empty description");

        description = _description;

        startBlock = _startBlock;
        endBlock = _endBlock;

        choicesCount = _choicesCount;
    }

    /**
     * @dev Return the contract which implements the ISGRAuthorizationManager interface.
     */
    function getSGRAuthorizationManager() public view returns (ISGRAuthorizationManager) {
        return ISGRAuthorizationManager(getContractAddress(_ISGRAuthorizationManager_));
    }

    /**
    * @dev throw if called when not active.
    */
    modifier onlyIfActive() {
        require(isActive(), "voting proposal not active");
        _;
    }


    /**
    * @dev throw if called when user already voted.
    */
    modifier onlyIfUserVoteAbsent() {
        require(votes[msg.sender] == 0, "voting proposal already voted");
        _;
    }

    /**
    * @dev throw if called with invalid choice index.
    */
    modifier onlyIfValidChoiceIndex(uint256 _choiceIndex) {
        require(_choiceIndex < choicesCount, "invalid voting choice index");
        _;
    }


    /**
    * @dev throw if called when user is not authorized.
    */
    modifier onlyIfAuthorizedUser() {
        ISGRAuthorizationManager sgrAuthorizationManager = getSGRAuthorizationManager();
        bool senderIsAuthorized = sgrAuthorizationManager.isAuthorizedForPublicOperation(msg.sender);
        require(senderIsAuthorized, "user is not authorized");
        _;
    }

    /**
    * @dev Is active.
    * @return is voting active.
    */
    function isActive() public view returns (bool) {
        uint256 currentBlockNumber = block.number;
        return currentBlockNumber >= startBlock && currentBlockNumber <= endBlock;
    }

    /**
    * @dev Get total voters count .
    * @return total voters count.
    */
    function getTotalVoters() external view returns (uint256) {
        return voters.length;
    }

    /**
    * @dev Get voters range.
    * @return voters range.
    */
    function getVotersRange(uint256 _startIndex, uint256 _count) external view returns (address[] memory) {
        uint256 rangeCount = _count;
        if (rangeCount > voters.length - _startIndex) {
            rangeCount = voters.length - _startIndex;
        }
        address[] memory rangeVoters = new address[](rangeCount);

        for (uint256 i = 0; i < rangeCount; i++) {
            rangeVoters[i] = voters[_startIndex + i];
        }

        return rangeVoters;
    }

    /**
    * @dev Get all voters.
    * @return all voters.
    */
    function getAllVoters() external view returns (address[] memory) {
        return voters;
    }


    /**
    * @dev Cast a vote.
    * @param _choiceIndex the vote choice index.
    */
    function castVote(uint256 _choiceIndex) internal onlyIfActive onlyIfUserVoteAbsent onlyIfValidChoiceIndex(_choiceIndex) onlyIfAuthorizedUser
    {
        uint256 base1ChoiceIndex = _choiceIndex + 1;
        address sender = msg.sender;
        votes[sender] = base1ChoiceIndex;
        voters.push(sender);
        emit ProposalVoteCasted(sender, base1ChoiceIndex);
    }
}

// File: contracts/voting/OTCProviderProposalVoting.sol

contract OTCProviderProposalVoting is ProposalVoting {

    string[3] public choices = ["B2C2", "Woorton", "Cumberland"];

    constructor(IContractAddressLocator _contractAddressLocator, uint256 _startBlock, uint256 _endBlock) ProposalVoting(_contractAddressLocator, "Proposal for Determining the Identity of Sögur Primary Liquidity Provider", _startBlock, _endBlock, 3) public {}

    function voteB2C2() public
    {
        castVote(0);
    }

    function voteWoorton() public
    {
        castVote(1);
    }

    function voteCumberland() public
    {
        castVote(2);
    }
}