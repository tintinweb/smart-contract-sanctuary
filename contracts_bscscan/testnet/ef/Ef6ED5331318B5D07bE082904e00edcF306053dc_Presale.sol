pragma solidity ^0.8.6;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IDex.sol";
import "./IStruct.sol";

interface ILPLockerFactory is IStruct{
    function lockLP(
        address _lpAddress,
        uint256 _amount,
        uint256 _unlockDate,
        address _lpOwner,
        TokenVesting memory _tokenVesting
    ) external payable returns (bool);
}

contract Presale is ReentrancyGuard, Initializable, IStruct {
    using Address for address payable;

    mapping(address => Contributions) private _contributions;
    mapping(address => UserVesting) private usersVesting;
    mapping(address => bool) private _isWhitelisted;

    struct Contributions {
        uint256 weiContribution;
        uint256 tokensPurchased;
        bool claimed;
    }

    struct UserVesting {
        uint256 tokensWithdrawn;
        uint256 lastCycleClaimed;
    }

    IERC20Metadata public token;
    uint256 private decimals;

    address public burnAddress;
    address public pair;
    address public presaleFactory;
    string public utilsLink;

    Taxes public taxes;

    modifier onlyPresaleFactory() {
        require(msg.sender == presaleFactory);
        _;
    }

    modifier onlyPresaleCreator() {
        require(msg.sender == presaleCreator);
        _;
    }

    enum Status {
        NOT_STARTED,
        STARTED,
        FAILED,
        FILLED
    }
    enum Result {
        PENDING,
        CANCELLED,
        FINALIZED
    }

    Result public result = Result.PENDING;

    TokenVesting private tokenVesting = TokenVesting(0,0,0,0,false);

    PresaleInfo private presaleInfo;

    uint256 public fundsRaised;
    uint256 public tokensSold;
    uint256 public tokensClaimed;
    uint256 public presaleFinalizedTimestamp;
    bool public whitelistEnabled;
    address payable public presaleCreator;

    InvestorsVesting private investorsVesting;
    TeamVesting private teamVesting;
    ListingInfo private listingInfo;

    event TokensPurchased(
        address user,
        uint256 weiAmount,
        uint256 tokensAmount
    );
    event ContributionWithdrawn(address user, uint256 weiAmount);
    event TokensClaimed(address user, uint256 tokensAmount);
    event TeamTokensClaimed(address user, uint256 tokensAmount);

    function initialize(PresaleInfo calldata _presaleInfo, ListingInfo calldata _listingInfo, bool _whitelistEnabled, 
        InvestorsVesting calldata _investorsVesting, TeamVesting calldata _teamVesting, 
        address payable _presaleCreator, address _token, string memory _utilsLink, Taxes calldata _taxes) public initializer  returns (bool) {
        presaleFactory = msg.sender;
        presaleInfo = PresaleInfo(
            _presaleInfo.presaleRate,
            _presaleInfo.minPurchase,
            _presaleInfo.maxPurchase,
            _presaleInfo.softCap,
            _presaleInfo.hardCap,
            _presaleInfo.startDate,
            _presaleInfo.endDate );

        listingInfo.router = IRouter(_listingInfo.router);
        listingInfo.liquidityLockTime = _listingInfo.liquidityLockTime * 1 days;
        listingInfo.listingRate = _listingInfo.listingRate;
        listingInfo.liquidityPercentage = _listingInfo.liquidityPercentage;
        listingInfo.LPLockerFactory = _listingInfo.LPLockerFactory;
        whitelistEnabled = _whitelistEnabled;
        presaleCreator = _presaleCreator;
        token = IERC20Metadata(_token);
        decimals = IERC20Metadata(_token).decimals();
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        utilsLink = _utilsLink;
        taxes = _taxes;

        if (_investorsVesting.vestingEnabled == true) {
            investorsVesting.vestingEnabled = true;
            setInvestorsVesting(
                _investorsVesting.vestingFirstPercentage,
                _investorsVesting.vestingCycle,
                _investorsVesting.vestingTokensPerCyclePercentage
            );
        }
        if (_teamVesting.vestingEnabled == true) {
            teamVesting.vestingEnabled = true;
            setTeamVesting(
                _teamVesting.vestingTotalTokens,
                _teamVesting.vestingFirstReleaseTimestamp,
                _teamVesting.vestingFirstPercentage,
                _teamVesting.vestingCycle,
                _teamVesting.vestingTokensPerCyclePercentage
            );
        }

        return true;
    }

    function setInvestorsVesting(
        uint256 _vestingFirstPercentage,
        uint256 _vestingCycle,
        uint256 _vestingTokensPerCyclePercentage
    ) internal {
        require(
            _vestingFirstPercentage < 100 &&
                _vestingTokensPerCyclePercentage < 100 &&
                _vestingFirstPercentage + _vestingTokensPerCyclePercentage <= 100,
            "First release for presale and Percent token release each cycle must <= 100%"
        );
        require( _vestingCycle > 1,"Vesting period each cycle must be 1 or more");
        investorsVesting.vestingFirstPercentage = _vestingFirstPercentage;
        investorsVesting.vestingCycle = _vestingCycle * 1 days;
        investorsVesting.vestingTokensPerCyclePercentage = _vestingTokensPerCyclePercentage;
    }

    function setTeamVesting(
        uint256 _vestingTotalTokens,
        uint256 _vestingFirstReleaseTimestamp,
        uint256 _vestingFirstPercentage,
        uint256 _vestingCycle,
        uint256 _vestingTokenPerCycle
    ) internal {
        require(_vestingFirstPercentage < 100 && _vestingTokenPerCycle < 100 && 
            _vestingFirstPercentage + _vestingTokenPerCycle <= 100,
            "First release for presale and Percent token release each cycle must <= 100%"
        );
        require(_vestingCycle > 1, "Vesting period each cycle must > 1");
        require(_vestingTotalTokens > 1,"Total team vesting tokens must be > 1");
        teamVesting.vestingTotalTokens = _vestingTotalTokens ;
        teamVesting.vestingFirstReleaseTimestamp = _vestingFirstReleaseTimestamp * 1 days;
        teamVesting.vestingFirstPercentage = _vestingFirstPercentage;
        teamVesting.vestingCycle = _vestingCycle * 1 days;
        teamVesting.vestingTokensPerCyclePercentage = _vestingTokenPerCycle;
    }

    function checkCurrentStatus() public view returns (Status output) {
        if (block.timestamp >= presaleInfo.startDate && block.timestamp < presaleInfo.endDate && result == Result.PENDING) {
            if (fundsRaised < presaleInfo.hardCap) return Status.STARTED;
            else if (fundsRaised == presaleInfo.hardCap) return Status.FILLED;
        } else if (block.timestamp >= presaleInfo.endDate && fundsRaised < presaleInfo.softCap)
            return Status.FAILED;
        else if (block.timestamp >= presaleInfo.endDate && fundsRaised >= presaleInfo.softCap)
            return Status.FILLED;
    }

    function buyTokens() external payable nonReentrant {
        require( checkCurrentStatus() == Status.STARTED, "Presale must be started");
        if(whitelistEnabled){
            require(_isWhitelisted[msg.sender], "Only whitelisted users can partecipate");
        }
        require(msg.sender != presaleCreator, "Presale creator can't buy tokens");
        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);
        uint256 tokensAmt = _getTokenAmount(weiAmount) * 10**decimals;
        fundsRaised += weiAmount;
        _contributions[msg.sender].weiContribution += weiAmount;
        _contributions[msg.sender].tokensPurchased += tokensAmt;
        tokensSold += tokensAmt;
        emit TokensPurchased(msg.sender, weiAmount, tokensAmt);
    }

    function withdrawContribution() external nonReentrant {
        require( checkCurrentStatus() == Status.FAILED || result == Result.CANCELLED, "Presale not cancelled yet" );
        uint256 bnbToWithdraw = _contributions[msg.sender].weiContribution;
        uint256 tokensPurchased = _contributions[msg.sender].tokensPurchased;
        _contributions[msg.sender].weiContribution = 0;
        _contributions[msg.sender].tokensPurchased = 0;
        tokensSold -= tokensPurchased;
        payable(msg.sender).sendValue(bnbToWithdraw);
        emit ContributionWithdrawn(msg.sender, bnbToWithdraw);
    }

    function claimVestingTokens() external nonReentrant {
        require( investorsVesting.vestingEnabled, "VESTING DISABLED: You must use claimTokens" );
        require(result == Result.FINALIZED, "Presale must be finalized");

        (uint256 tokensClaimable,uint256 currentCycle) = getUserTokensWithdrawable(msg.sender);
        require(tokensClaimable > 0, "Insufficient amount");
        tokensClaimed += tokensClaimable;
        usersVesting[msg.sender].tokensWithdrawn += tokensClaimable;
        usersVesting[msg.sender].lastCycleClaimed = currentCycle;
        token.transfer(msg.sender, tokensClaimable);
        emit TokensClaimed(msg.sender, tokensClaimable);
    }

    function claimTeamVestingTokens() external nonReentrant onlyPresaleCreator{
        require(teamVesting.vestingEnabled, "VESTING DISABLED");
        require(result == Result.FINALIZED, "Presale must be finalized");
        (uint256 tokensClaimable,uint256 currentCycle) = getTeamTokensWithdrawable();
        require(tokensClaimable > 0, "Insufficient amount");
        tokensClaimed += tokensClaimable;
        usersVesting[msg.sender].tokensWithdrawn += tokensClaimable;
        usersVesting[msg.sender].lastCycleClaimed = currentCycle;
        token.transfer(msg.sender, tokensClaimable);
        emit TeamTokensClaimed(msg.sender, tokensClaimable);
    }

    function claimTokens() external nonReentrant {
        require(!investorsVesting.vestingEnabled,"VESTING ENABLED: You must use claimVestingTokens");
        require(result == Result.FINALIZED, "Presale must be finalized");
        require(_contributions[msg.sender].claimed == false, "You have already claimed");
        (, uint256 tokensToClaim, ) = checkContribution(msg.sender);
        _contributions[msg.sender].claimed = true;
        require(tokensToClaim > 0, "Nothing to claim");
        tokensClaimed += tokensToClaim;
        token.transfer(msg.sender, tokensToClaim);
        emit TokensClaimed(msg.sender, tokensToClaim);
    }
    
    function finalizePresale() external onlyPresaleCreator {
        require(checkCurrentStatus() == Status.FILLED && result == Result.PENDING, "Presale has not been filled" );
        result = Result.FINALIZED;
        uint256 bnbForPresaleCreator = (((fundsRaised *  (100 - listingInfo.liquidityPercentage)) / 100) * (100 - taxes.feesInBnb)) / 100;
        uint256 bnbForFee = ((fundsRaised * (100 - listingInfo.liquidityPercentage)) * taxes.feesInBnb / 100) - bnbForPresaleCreator;
        uint256 bnbForLiquidity = fundsRaised - bnbForFee - bnbForPresaleCreator;
        uint256 tokensForFees = (((presaleInfo.presaleRate * presaleInfo.hardCap) * taxes.feesInTokens / 100) / 10**18) * 10**decimals;
        uint256 tokensForLiquidity = (listingInfo.listingRate * bnbForLiquidity / 10**18) * 10**decimals;

        // Check if a pair already exist, if not, create the pair
        address get_pair = IFactory(listingInfo.router.factory()).getPair(address(token),listingInfo.router.WETH()
        );
        if (get_pair == address(0)) {
            pair = IFactory(listingInfo.router.factory()).createPair(address(token),listingInfo.router.WETH());
        } else {
            pair = get_pair;
            // Check if the pair already hold WBNB,if yes, rebalance the pool
            IERC20 WBNB = IERC20(listingInfo.router.WETH());
            uint256 wbnbBalance = WBNB.balanceOf(pair);
            if(wbnbBalance > 0){
                uint256 tokens_to_rebalance = (wbnbBalance * listingInfo.listingRate / 10**18) * 10**decimals;
                token.transfer(pair, tokens_to_rebalance);
                IPair(pair).sync();
            }
        }

        token.approve(address(listingInfo.router), tokensForLiquidity);
        (,,uint256 lpAmount) = listingInfo.router.addLiquidityETH{value: bnbForLiquidity}(
            address(token),
            tokensForLiquidity,
            1,
            1,
            address(this),
            block.timestamp
        );
        IERC20(pair).approve(listingInfo.LPLockerFactory, lpAmount);
        require(ILPLockerFactory(listingInfo.LPLockerFactory).lockLP(pair,lpAmount,listingInfo.liquidityLockTime + block.timestamp,presaleCreator, tokenVesting),"Failed to lock LP");

        // take BNB and tokens fees
        payable(presaleFactory).sendValue(bnbForFee);
        token.transfer(presaleFactory, tokensForFees);

        // send BNB to presale creator
        if (bnbForPresaleCreator > 0)
            presaleCreator.sendValue(bnbForPresaleCreator);

        // burn remaining tokens
        uint256 tokensToBurn = token.balanceOf(address(this)) - tokensSold - teamVesting.vestingTotalTokens;
        token.transfer(burnAddress, tokensToBurn);

        presaleFinalizedTimestamp = block.timestamp;
    }

    function cancelPresale() external onlyPresaleCreator {
        require(result == Result.PENDING, "Presale should be pending");
        result = Result.CANCELLED;
        token.transfer(presaleCreator, token.balanceOf(address(this)));
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require( beneficiary != address(0), "Presale: beneficiary is the zero address" );
        require(weiAmount != 0, "Presale: weiAmount is 0");
        require(weiAmount >= presaleInfo.minPurchase, "have to send at least: minPurchase");
        require( _contributions[beneficiary].weiContribution + weiAmount <= presaleInfo.maxPurchase, "can't buy more than: maxPurchase" );
        require((fundsRaised + weiAmount) <= presaleInfo.hardCap, "Hard Cap reached");
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return (weiAmount * presaleInfo.presaleRate) / 10**18;
    }

    // Use this only to calculate withdrawable tokens with vesting
    function getTeamTokensWithdrawable()public view returns (uint256, uint256) {

        // Calculate the first release based on vestingFirstPercentage
        if(block.timestamp < (teamVesting.vestingFirstReleaseTimestamp + presaleFinalizedTimestamp)){
            return (0, 0);
        }
     
        (, uint256 tokensToClaim, ) = checkContribution(presaleCreator);

        // Check current cycle and in case there are withdrawble tokens,add them to totalTokensWithdrawable
        uint256 currCycle = ((block.timestamp - teamVesting.vestingFirstReleaseTimestamp) / 1 days) / teamVesting.vestingCycle;
        
        // Calculate the first release based on vestingFirstPercentage
        uint256 firstVesting = 0;
        if( usersVesting[msg.sender].tokensWithdrawn == 0 ){ 
            firstVesting = tokensToClaim * teamVesting.vestingFirstPercentage / 100;
        }
        uint256 cycleVesting = ( (teamVesting.vestingTokensPerCyclePercentage * teamVesting.vestingTotalTokens )/100 ) * (currCycle - usersVesting[presaleCreator].lastCycleClaimed);
        // Check current cycle and in case there are withdrawble tokens,add them to totalTokensWithdrawable
        if( tokensToClaim == 0 ){
            return ( 0, currCycle);
        } else if ( usersVesting[presaleCreator].tokensWithdrawn + cycleVesting > tokensToClaim ){
            return (  tokensToClaim - usersVesting[presaleCreator].tokensWithdrawn, currCycle );
        } else {
            return ( firstVesting + cycleVesting, currCycle );
        }
    }

     // Use this only to calculate withdrawable tokens with vesting
    function getUserTokensWithdrawable(address _user)public view returns (uint256, uint256) {
        // Re-calculate tokens available in case a rebase happened

        (, uint256 tokensToClaim, ) = checkContribution(_user);
   
        // Check current cycle and in case there are withdrawble tokens,add them to totalTokensWithdrawable
        uint256 currCycle = ((block.timestamp - presaleFinalizedTimestamp) / 1 days) / investorsVesting.vestingCycle;
        
        // Calculate the first release based on vestingFirstPercentage
        uint256 firstVesting = 0;
        if( usersVesting[msg.sender].tokensWithdrawn == 0 ){ 
            firstVesting = tokensToClaim * investorsVesting.vestingFirstPercentage / 100;
        }

        uint256 cycleVesting = ( (investorsVesting.vestingTokensPerCyclePercentage * tokensToClaim )/100 ) * (currCycle - usersVesting[_user].lastCycleClaimed);
        // Check current cycle and in case there are withdrawble tokens,add them to totalTokensWithdrawable
     
        if( tokensToClaim == 0 ){
            return ( 0, currCycle);
        } else if ( usersVesting[_user].tokensWithdrawn + cycleVesting > tokensToClaim ){
            return (  tokensToClaim - usersVesting[_user].tokensWithdrawn, currCycle );
        } else {
            return ( firstVesting + cycleVesting, currCycle );
        }
        
    }

    function checkContribution(address addr) public view returns (uint256, uint256 tokensToClaim, bool){
        if(_contributions[addr].claimed) return ( _contributions[addr].weiContribution, 0, _contributions[addr].claimed);
        uint256 tokensRemainingDenominator = (tokensSold + teamVesting.vestingTotalTokens) - tokensClaimed;

        if(tokensRemainingDenominator == 0){
            tokensToClaim = 0;
        }
        else{
            if(addr == presaleCreator){
                tokensToClaim = (token.balanceOf(address(this))  * teamVesting.vestingTotalTokens) / tokensRemainingDenominator;
            }
            else{
                tokensToClaim = (token.balanceOf(address(this))  * _contributions[addr].tokensPurchased) / tokensRemainingDenominator;
            }   
        }
        return (_contributions[addr].weiContribution, tokensToClaim, _contributions[addr].claimed);
    }

    function setWhitelist(address[] memory accounts, bool value) external payable  onlyPresaleCreator{
        require(msg.value >= taxes.updateWhitelistFee, "Tax is not met");
        require(whitelistEnabled, "Whitelist is not enabled");
        for(uint256 i = 0; i < accounts.length; i++){
            _isWhitelisted[accounts[i]] = value;
        }
        if(msg.value - taxes.updateWhitelistFee > 0) payable(msg.sender).sendValue(msg.value - taxes.updateWhitelistFee);
    }

    function setUserWhitelisted(address account, bool value) external payable onlyPresaleCreator{
        require(whitelistEnabled, "Whitelist is not enabled");
        require(msg.value >= taxes.updateWhitelistFee, "Tax is not met");
        require(_isWhitelisted[account] != value, "Value already set");
        _isWhitelisted[account] = value;
        if(msg.value - taxes.updateWhitelistFee > 0) payable(msg.sender).sendValue(msg.value - taxes.updateWhitelistFee);    
    }

    function setUtilsLink(string memory newLink) external onlyPresaleCreator payable{
        require(msg.value >= taxes.updateUtilsLinkFee, "Fee is not met");
        utilsLink = newLink;
        if(msg.value - taxes.updateUtilsLinkFee > 0) payable(msg.sender).sendValue(msg.value - taxes.updateUtilsLinkFee);
    }

    function checkWhitelistedAccount(address account) external view returns(bool){
        return _isWhitelisted[account];
    }

    function getListingInfo() external view returns(uint256, uint256, uint256, address, address){
        return (
            listingInfo.listingRate, 
            listingInfo.liquidityPercentage, 
            listingInfo.liquidityLockTime,
            listingInfo.LPLockerFactory,
            address(listingInfo.router)
            );
    }

    function getInvestorsVesting() external view returns(uint256, uint256, uint256, bool){
        return (
            investorsVesting.vestingCycle,
            investorsVesting.vestingFirstPercentage,
            investorsVesting.vestingTokensPerCyclePercentage,
            investorsVesting.vestingEnabled
            );
    }


    function getTeamVesting() external view returns(uint256, uint256, uint256, uint256, uint256, bool){
        return (
            teamVesting.vestingCycle,
            teamVesting.vestingTotalTokens,
            teamVesting.vestingFirstReleaseTimestamp,
            teamVesting.vestingFirstPercentage,
            teamVesting.vestingTokensPerCyclePercentage,
            teamVesting.vestingEnabled
            );
    }

    function getPresaleInfo() external view returns(PresaleInfo memory){
        return presaleInfo;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

//SPDX-License-Identifier: MIT
import "./IDex.sol";

pragma solidity ^0.8.6;

interface IStruct{
    struct TokenVesting {
        uint256 firstReleaseDate; // Indicate the date for the first release
        uint256 cycle; // User will need to wait for this amount of time (days) to receive their tokens
        uint256 firstPercentage; // The first batch of the total presale tokens that will be released
        uint256 tokensPerCyclePercentage; // How many tokens will be released each cycle
        bool enabled; // "true" is enabled, "false" otherwise
    }

    //Presale
    struct PresaleInfo {
        uint256  presaleRate;
        uint256  minPurchase;
        uint256  maxPurchase;
        uint256  softCap;
        uint256  hardCap;
        uint256  startDate;
        uint256  endDate;
    }

    //Vesting: Investors
    struct InvestorsVesting{
        uint256 vestingCycle; // Investors will need to wait for this amount of time (days) to receive their tokens
        uint256 vestingFirstPercentage; // The first batch of the total presale tokens that will be released 
        uint256 vestingTokensPerCyclePercentage; // How many tokens will be released each cycle
        bool vestingEnabled;
    }
        
    //Vesting: Team
    struct TeamVesting{
        uint256 vestingCycle;
        uint256 vestingTotalTokens;
        uint256 vestingFirstReleaseTimestamp;
        uint256 vestingFirstPercentage;
        uint256 vestingTokensPerCyclePercentage;
        bool vestingEnabled;
    }
    
    //Listing
    struct ListingInfo {
        uint256 listingRate;
        uint256 liquidityPercentage;
        uint256 liquidityLockTime;
        address LPLockerFactory;
        IRouter router;
    }

    //Taxes
    struct Taxes{
        uint256 feesInTokens;
        uint256 feesInBnb;
        uint256 updateUtilsLinkFee;
        uint256 updateWhitelistFee;
    }
}