/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: LicenseRef-LICENSE



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



interface IRoleManager {
    function isAdmin(address account) external returns (bool);

    function isIDOManager(address account) external returns (bool);

    function isIDOModerator(address account) external returns (bool);
}



interface IContractsManager {
    function idoFactory() external view returns (address);

    function roleManager() external view returns (address);

    function votingManager() external view returns (address);

    function fundingManager() external view returns (address);

    function stakingManager() external view returns (address);

    function tokenAddress() external view returns (address);

    function pcsRouter() external view returns (address);

    function lpLocker() external view returns (address);
}





library IDODetailsStorage {
    struct BasicIdoDetails {
        uint tokenPrice; // in BNB
        uint softCap; // in BNB
        uint hardCap; // in BNB
        uint minPurchasePerWallet; // in BNB
        uint maxPurchasePerWallet; // in BNB
        uint saleStartTime; // unix
        uint saleEndTime; // unix
        uint headStart; // in Seconds
    }

    struct VotingDetails {
        uint voteStartTime; // unix
        uint voteEndTime; // unix
    }

    struct PCSListingDetails {
        uint listingRate; // in BNB
        uint lpLockDuration; // in seconds

        uint8 allocationToLPInBP; // in BP
    }

    struct ProjectInformation {
        string saleTitle;
        string saleDescription;
        string website;
        string telegram;
        string github;
        string twitter;
        string logo;
        string whitePaper;
        string kyc;
    }
}





library  FundingTypes {
    enum FundingType { FCFS, AUCTION }
}



library IDOStates {
    enum IDOState {
        UNDER_MODERATION,
        IN_VOTING,
        IN_FUNDING,
        LAUNCHED,
        REJECTED, // rejected by moderator
        FAILED, // Failed in voting state
        CANCELLED // Cancelled because not reached soft-cap or owner cancelled because of some issues
    }

    function updateState(IDOState _oldState, IDOState _newState) internal {

        require(_newState != IDOState.UNDER_MODERATION, 'IDOStates: Cannot update state to UNDER_MODERATION');

        if(_newState == IDOState.IN_VOTING) {
            require(_oldState == IDOState.UNDER_MODERATION, 'IDOStates: Only UNDER_MODERATION to IN_VOTING allowed');
        }

        if(_newState == IDOState.IN_FUNDING) {
            require(_oldState == IDOState.IN_VOTING, 'IDOStates: Only IN_VOTING to IN_FUNDING allowed');
        }

        if(_newState == IDOState.LAUNCHED) {
            require(_oldState == IDOState.IN_FUNDING, 'IDOStates: Only IN_FUNDING to LAUNCHED allowed');
        }

        if(_newState == IDOState.REJECTED) {
            require(_oldState == IDOState.UNDER_MODERATION, 'IDOStates: Only UNDER_MODERATION to REJECTED allowed');
        }

        if(_newState == IDOState.FAILED) {
            require(_oldState == IDOState.UNDER_MODERATION
                || _oldState == IDOState.IN_VOTING, 'IDOStates: Only UNDER_MODERATION, IN_VOTING to FAILED allowed');
        }

        if(_newState == IDOState.CANCELLED) {
            require(_oldState == IDOState.IN_FUNDING, 'IDOStates: Only IN_FUNDING to CANCELLED allowed');
        }

        _oldState = _newState;
    }
}



library Constants {
    uint constant DAY = 86400;
    uint constant HOUR = 3600;
    uint constant MINUTE = 60;
}



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract IDODetails {
    using IDOStates for IDOStates.IDOState;
    using FundingTypes for FundingTypes.FundingType;

    uint public idoId;

    address public preSale;
    address public treasury;

    uint public lpLockerId;

    IContractsManager private contractsManager;

    address public tokenAddress;
    address public ownerAddress;
    IDODetailsStorage.BasicIdoDetails public basicIdoDetails;
    IDODetailsStorage.VotingDetails public votingDetails;
    IDODetailsStorage.PCSListingDetails public pcsListingDetails;
    IDODetailsStorage.ProjectInformation public projectInformation;

    FundingTypes.FundingType public fundingType;
    IDOStates.IDOState public state;

    uint inHeadStartTill;

    constructor(
        address _contractsManager, // help in testing easily!!!
        address _ownerAddress,
        address _tokenAddress,
        uint _idoId,
        IDODetailsStorage.BasicIdoDetails memory _basicIdoDetails,
        IDODetailsStorage.VotingDetails memory _votingDetails,
        IDODetailsStorage.PCSListingDetails memory _pcsListingDetails,
        IDODetailsStorage.ProjectInformation memory _projectInformation
    ) {
        validateTokenAddress(_tokenAddress);
        validateVoteParams(_votingDetails.voteStartTime, _votingDetails.voteEndTime);
        validateSaleParams(_basicIdoDetails.saleStartTime, _basicIdoDetails.saleEndTime, _basicIdoDetails.headStart, _votingDetails.voteEndTime);

        contractsManager = IContractsManager(_contractsManager);

        tokenAddress = _tokenAddress;
        ownerAddress = _ownerAddress;

        idoId = _idoId;

        basicIdoDetails = _basicIdoDetails;
        votingDetails = _votingDetails;
        pcsListingDetails = _pcsListingDetails;
        projectInformation = _projectInformation;

        state = IDOStates.IDOState.UNDER_MODERATION;
    }

    modifier onlyProjectOwnerOrIDOModerator() {
        IRoleManager roleManager = IRoleManager(contractsManager.roleManager());
        require(msg.sender == ownerAddress || roleManager.isIDOModerator(msg.sender), 'IDODetails: Only Project Owner or IDO Moderators allowed');
        _;
    }

    modifier onlyIDOManager() {
        IRoleManager roleManager = IRoleManager(contractsManager.roleManager());
        require(roleManager.isIDOManager(msg.sender), 'IDODetails: Only IDO Managers allowed');
        _;
    }

    modifier onlyInModeration() {
        require(state == IDOStates.IDOState.UNDER_MODERATION, 'IDODetails: Only allowed in UNDER_MODERATION state');
        _;
    }

    function validateTokenAddress(address _tokenAddress) internal view {
        require(!Address.isContract(_tokenAddress), 'IDODetails: Token should be a contract');
        // Probably add more validations here to make sure token is compatible with us ??
    }

    function validateSaleParams(uint _saleStartTime, uint _saleEndTime, uint _headStart, uint _voteEndTime) internal pure {
        require(_saleStartTime >= _voteEndTime + Constants.HOUR * 4, 'IDODetails: Sale can only start after at-least 4 hours of vote end time');
        require(_saleEndTime > _saleStartTime && _saleEndTime - _saleStartTime >= Constants.HOUR, 'IDODetails: Sale should run for at-least 1 hour');
        require(_saleEndTime - _saleStartTime <= Constants.DAY * 2, 'IDODetails: Sale can only run for max 2 days');
        require(_headStart >= Constants.MINUTE * 5, 'IDODetails: HeadStart should be of at-least 5 mins');
        require((_saleEndTime - _saleStartTime) / 2 >= _headStart, 'IDODetails: HeadStart cannot be more then 50% of time');
    }

    function validateVoteParams(uint _voteStartTime, uint _voteEndTime) internal view {
        require(_voteStartTime >= block.timestamp + Constants.MINUTE * 15, 'IDODetails: Voting can start only after at-least 15 mins from now');
        require(_voteEndTime <= block.timestamp + Constants.DAY * 7, 'IDODetails: Voting should end within 7 days from now');
        require(_voteEndTime > _voteStartTime && _voteEndTime - _voteStartTime > Constants.HOUR * 4, 'IDODetails: Voting should be allowed for at-least 4 hours');
    }

    function updateTokenAddress(address _tokenAddress) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        tokenAddress = _tokenAddress;
    }

    function updateOwnerAddress(address _ownerAddress) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        ownerAddress = _ownerAddress;
    }

    function updateTokenPrice(uint _tokenPrice) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        basicIdoDetails.tokenPrice = _tokenPrice;
    }

    function updateSoftCap(uint _softCap) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        basicIdoDetails.softCap = _softCap;
    }

    function updateHardCap(uint _hardCap) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        basicIdoDetails.hardCap = _hardCap;
    }

    function updateMinPurchasePerWallet(uint _minPurchasePerWallet) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        basicIdoDetails.minPurchasePerWallet = _minPurchasePerWallet;
    }

    function updateMaxPurchasePerWallet(uint _maxPurchasePerWallet) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        basicIdoDetails.maxPurchasePerWallet = _maxPurchasePerWallet;
    }

    function updateSaleStartTime(uint _saleStartTime) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        validateSaleParams(_saleStartTime, basicIdoDetails.saleEndTime, basicIdoDetails.headStart, votingDetails.voteEndTime);
        basicIdoDetails.saleStartTime = _saleStartTime;
    }

    function updateSaleEndTime(uint _saleEndTime) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        validateSaleParams(basicIdoDetails.saleStartTime, _saleEndTime, basicIdoDetails.headStart, votingDetails.voteEndTime);
        basicIdoDetails.saleEndTime = _saleEndTime;
    }

    function updateHeadStart(uint _headStart) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        validateSaleParams(basicIdoDetails.saleStartTime, basicIdoDetails.saleEndTime, _headStart, votingDetails.voteEndTime);
        basicIdoDetails.headStart = _headStart;
    }

    function updateVotingStartTime(uint _voteStartTime) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        validateVoteParams(_voteStartTime, votingDetails.voteEndTime);
        votingDetails.voteStartTime = _voteStartTime;
    }

    function updateVotingEndTime(uint _voteEndTime) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        validateVoteParams(votingDetails.voteStartTime, _voteEndTime);
        votingDetails.voteEndTime = _voteEndTime;
    }

    function updateListingRate(uint _listingRate) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        pcsListingDetails.listingRate = _listingRate;
    }

    function updateLpLockDuration(uint _lpLockDuration) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        pcsListingDetails.lpLockDuration = _lpLockDuration; // @todo: some validations here as well, i think
    }

    function updateAllocationToLPInBP(uint8 _allocationToLPInBP) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        pcsListingDetails.allocationToLPInBP = _allocationToLPInBP;
    }

    function updateSaleTitle(string memory _saleTitle) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.saleTitle = _saleTitle;
    }

    function updateSaleDescription(string memory _saleDescription) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.saleDescription = _saleDescription;
    }

    function updateWebsite(string memory _website) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.website = _website;
    }

    function updateTelegram(string memory _telegram) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.telegram = _telegram;
    }

    function updateGithub(string memory _github) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.github = _github;
    }

    function updateTwitter(string memory _twitter) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.twitter = _twitter;
    }

    function updateLogo(string memory _logo) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.logo = _logo;
    }

    function updateWhitePaper(string memory _whitePaper) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.whitePaper = _whitePaper;
    }

    function updateKyc(string memory _kyc) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        projectInformation.kyc = _kyc;
    }

    function updateFundingType(FundingTypes.FundingType _fundingType) public onlyProjectOwnerOrIDOModerator onlyInModeration {
        fundingType = _fundingType;
    }

    function updateState(IDOStates.IDOState _newState) public onlyIDOManager {
        state.updateState(_newState);
    }

    function updatePreSaleAddress(address _preSale) public onlyIDOManager {
        preSale = _preSale;
    }

    function updateTreasuryAddress(address _treasury) public onlyIDOManager {
        treasury = _treasury;
    }

    function updateInHeadStartTill(uint _inHeadStartTill) public onlyIDOManager {
        inHeadStartTill = _inHeadStartTill;
    }

    function updateLpLockerId(uint _lpLockerId) public onlyIDOManager {
        lpLockerId = _lpLockerId;
    }

    function getTokensToBeSold() public view returns (uint) { // Returns in full token, not in decimals
        return basicIdoDetails.hardCap / basicIdoDetails.tokenPrice;
    }
}

interface IIDOFactory {

    function idoIdTracker() external view returns (uint);

    function idoIdToIDODetailsContract(uint) external view returns (address);

    function ownerToIDOs(address) external view returns (uint[] memory);

    function create(
        address _tokenAddress,
        IDODetailsStorage.BasicIdoDetails memory _basicIdoDetails,
        IDODetailsStorage.VotingDetails memory _votingDetails,
        IDODetailsStorage.PCSListingDetails memory _pcsListingDetails,
        IDODetailsStorage.ProjectInformation memory _projectInformation
    ) external returns (IDODetails);

    function approve(uint _idoId, uint _votingStartsAt, uint _votingEndsAt) external;

    function reject(uint _idoId) external;
}



interface IIDODetails {
    function idoId() external view returns (uint);

    function preSale() external view returns (address);

    function treasury() external view returns (address);

    function tokenAddress() external view returns (address);

    function ownerAddress() external view returns (address);

    function basicIdoDetails() external view returns (IDODetailsStorage.BasicIdoDetails memory);

    function votingDetails() external view returns (IDODetailsStorage.VotingDetails memory);

    function pcsListingDetails() external view returns (IDODetailsStorage.PCSListingDetails memory);

    function projectInformation() external view returns (IDODetailsStorage.ProjectInformation memory);

    function fundingType() external view returns (FundingTypes.FundingType);

    function state() external view returns (IDOStates.IDOState);

    function inHeadStartTill() external view returns (uint);

    function updateTokenAddress(address _tokenAddress) external;

    function updateOwnerAddress(address _ownerAddress) external;

    function updateTokenPrice(uint _tokenPrice) external;

    function updateSoftCap(uint _softCap) external;

    function updateHardCap(uint _hardCap) external;

    function updateMinPurchasePerWallet(uint _minPurchasePerWallet) external;

    function updateMaxPurchasePerWallet(uint _maxPurchasePerWallet) external;

    function updateSaleStartTime(uint _saleStartTime) external;

    function updateSaleEndTime(uint _saleEndTime) external;

    function updateHeadStart(uint _headStart) external;

    function updateVotingStartTime(uint _voteStartTime) external;

    function updateVotingEndTime(uint _voteEndTime) external;

    function updateListingRate(uint _listingRate) external;

    function updateLpLockDuration(uint _lpLockDuration) external;

    function updateAllocationToLPInBP(uint8 _allocationToLPInBP) external;

    function updateSaleTitle(string memory _saleTitle) external;

    function updateSaleDescription(string memory _saleDescription) external;

    function updateWebsite(string memory _website) external;

    function updateTelegram(string memory _telegram) external;

    function updateGithub(string memory _github) external;

    function updateTwitter(string memory _twitter) external;

    function updateLogo(string memory _logo) external;

    function updateWhitePaper(string memory _whitePaper) external;

    function updateKyc(string memory _kyc) external;

    function updateFundingType(FundingTypes.FundingType _fundingType) external;

    function updateState(IDOStates.IDOState _newState) external;

    function updatePreSaleAddress(address _preSale) external;

    function updateTreasuryAddress(address _treasury) external;

    function updateInHeadStartTill(uint _inHeadStartTill) external;

    function updateLpLockerId(uint _lpLockerId) external;

    function getTokensToBeSold() external view returns (uint);
}



interface IStakingManager {
    function getVotingPower(address _voter) external view returns (uint);
}



library VotingManagerStorage {
    struct VoteRecord {
        uint votingStartedAt; // for in case vote started after the vote start time, in that case to calculate head start

        uint positiveVoteWeight;
        uint positiveVoteCount;

        uint negativeVoteWeight;
        uint negativeVoteCount;
    }
}



interface IFundingManager {
    function addForFunding(uint _idoId) external;
}

contract VotingManager {
    IContractsManager contractsManager;

    mapping (uint => VotingManagerStorage.VoteRecord) public voteLedger;

    constructor(address _contractsManager) {
        contractsManager = IContractsManager(_contractsManager);
    }

    modifier onlyIDOManager() {
        IRoleManager roleManager = IRoleManager(contractsManager.roleManager());
        require(roleManager.isIDOManager(msg.sender), 'VotingManager: Only IDO Managers allowed');
        _;
    }

    modifier onlyIDOOwner(uint _idoId) {
        IIDOFactory idoFactory = IIDOFactory(contractsManager.idoFactory());
        IIDODetails idoDetails = IIDODetails(idoFactory.idoIdToIDODetailsContract(_idoId));
        require(idoDetails.ownerAddress() == msg.sender, 'VotingManager: Only IDO Owner allowed');
        _;
    }

    function addForVoting(uint _idoId) public onlyIDOOwner(_idoId) { // @todo: this should be allowed by owner of project too
        IIDOFactory idoFactory = IIDOFactory(contractsManager.idoFactory());
        IIDODetails idoDetails = IIDODetails(idoFactory.idoIdToIDODetailsContract(_idoId));

        require(idoDetails.votingDetails().voteEndTime >= block.timestamp + Constants.HOUR * 5, 'VotingManager: Voting can only start at-least 5 hour before end time');
        idoDetails.updateState(IDOStates.IDOState.IN_VOTING);

        VotingManagerStorage.VoteRecord storage voteRecord = voteLedger[_idoId];
        voteRecord.votingStartedAt = idoDetails.votingDetails().voteStartTime >= block.timestamp ? idoDetails.votingDetails().voteStartTime : block.timestamp;
    }

    function vote(uint _idoId, bool _vote) public {
        IIDOFactory idoFactory = IIDOFactory(contractsManager.idoFactory());
        IIDODetails idoDetails = IIDODetails(idoFactory.idoIdToIDODetailsContract(_idoId));

        require(idoDetails.votingDetails().voteStartTime >= block.timestamp && idoDetails.votingDetails().voteEndTime <= block.timestamp, 'VotingManager: Voting period is over');

        IStakingManager _stakingManager = IStakingManager(contractsManager.stakingManager());
        uint votingPower = _stakingManager.getVotingPower(msg.sender);

        require(votingPower > 0, 'VotingManager: You cannot vote with 0 voting power.');

        VotingManagerStorage.VoteRecord storage voteRecord = voteLedger[_idoId];

        if (_vote) {
            // Positive Vote
            voteRecord.positiveVoteWeight += votingPower;
            voteRecord.positiveVoteCount++;
        } else {
            // Negative Vote
            voteRecord.negativeVoteWeight += votingPower;
            voteRecord.negativeVoteCount++;
        }
    }

    function finalizeVotes(uint _idoId) public {
        IFundingManager fundingManager = IFundingManager(contractsManager.fundingManager());

        fundingManager.addForFunding(_idoId);
    }
}