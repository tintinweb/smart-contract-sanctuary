pragma solidity ^0.8.7;

import "./IUniftyGovernanceConsumer.sol";
import "./IUniftyGovernance.sol";
import "./IUntPriceOracle.sol";
import "./IExhibition.sol";
import "./IERC20Simple.sol";

contract ExhibitionConsumer is IUniftyGovernanceConsumer{

    IUniftyGovernance public gov;
    IUntPriceOracle public priceOracle;
    address public owner;
    address public exhibition;
    address public untAddress;
    address public nifAddress;
    bool public pausing;
    bool public withdrawOnPause;
    uint256 public exhibitionDuration;
    uint256 public allocationDuration;
    uint256 public override allocationEnd;
    uint256 public exhibitionStart;
    uint256 public override exhibitionEnd;
    uint256 public untRate;
    uint256 public untRateExhibitionController;
    uint256 public controllerVestingDuration;
    uint256 public collectedUnt;
    uint256 public lastCollectionUpdate;
    uint256 public lastCollectionBlock;
    uint256 public optionExerciseDuration;
    uint256 public paidToController;
    uint256 public override graceTime;
    uint256 public version;
    uint256[] public priceProviders;
    string public uriPeer;
    string public consumerName;
    string public consumerDscription;
    mapping(address => uint256) public accountDebt;
    mapping(address => uint256) public accountReserved;
    mapping(address => uint256) public accountPrevAmount;

    event Reserved(address indexed user, uint256 untReserved);

    // re-entrancy protection
    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'LaunchVault: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * Consumers must hold a reference to the governance.
     * The constructor is the best place to set it up.
     *
     * */
    constructor(
        IUniftyGovernance _gov,
        string memory _name,
        string memory _description,
        string memory _peerUri,
        uint256 _graceTime,
        uint256 _untRateStakers,
        uint256 _untRateExhibitionController,
        uint256[] memory _priceProviders
    ){

        gov = _gov;
        consumerName = _name;
        consumerDscription = _description;
        uriPeer = _peerUri;
        graceTime = _graceTime;
        untRate = _untRateStakers;
        untRateExhibitionController = _untRateExhibitionController;
        priceProviders = _priceProviders;
        priceOracle = IUntPriceOracle(0x79da5be12AC0d9306579deeBc0A8c8dF2A335E9E);
        untAddress = 0xB11A9a955C4DaFaFB20a9bA7d57CDd9269D0E9ce;
        nifAddress = 0xb93370D549A4351FA52b3f99Eb5c252506e5a21e;
        exhibitionDuration = 300; //86400*30;
        allocationDuration = 300; // 86400*3;
        controllerVestingDuration = 300; //86400*30*6;
        optionExerciseDuration = 12000;//86400*30;
        unlocked = 1;
        version = 1;
        owner = msg.sender;
        // untrate: 1000000000000000000
        // untrateExhibitionController: 1000000000000000000
    }

    /**
     * ############################
     * #
     * # INTERFACE IMPLEMENTATIONS
     * #
     * ########################################
     * */

    /**
    * Withdraws UNT solely for artists. No options involved here.
    *
    * */
    function withdraw() override external lock returns(uint256){

        require(!pausing || ( pausing && withdrawOnPause ), "withdraw: pausing, sorry.");
        require(exhibition != address(0), "withdraw: access denied.");
        require(!isOptionWithdraw(msg.sender), "withdraw: please try optionWithdraw().");
        require(msg.sender == IExhibition(exhibition).controller(), "withdraw: not the exhibition controller.");
        require(block.timestamp > exhibitionEnd + graceTime, "withdraw: you are withdrawing too early.");

        uint256 balance = ( ( exhibitionEnd - allocationEnd ) * untRateExhibitionController ) - paidToController;
        uint256 _earned = ( ( ( ( block.timestamp - exhibitionEnd ) * 10**18 ) / controllerVestingDuration ) * balance ) / 10**18;

        if(_earned > balance){

            _earned = balance;
        }

        paidToController += _earned;

        uint256 paid = payout(msg.sender, _earned);

        return paid;
    }

    /**
    * Withdraws UNT solely for exhibition collectors or stakers. Both have the option to
    * get discounted UNT based on the price set in the unt price oracle.
    *
    * */
    function optionWithdraw(uint256 _amountUnt) override external payable lock returns(uint256){

        require(!pausing || ( pausing && withdrawOnPause ), "optionWithdraw: pausing, sorry.");
        require(exhibition != address(0), "optionWithdraw: exhibition not set, access denied.");
        require(isOptionWithdraw(msg.sender), "optionWithdraw: not allowed to perform an option withdraw.");
        require(block.timestamp < exhibitionEnd + optionExerciseDuration, "optionWithdraw: option exercise window closed.");
        require(_amountUnt > 0, "optionWithdraw: amount of unt must be larger than 0.");

        if(msg.sender == IExhibition(exhibition).controller()){

            uint256 endTime = block.timestamp;

            if(endTime > exhibitionEnd){

                endTime = exhibitionEnd;
            }

            uint256 _earned = ( ( endTime - allocationEnd ) * untRateExhibitionController ) - paidToController;
            require(_earned >= _amountUnt, "optionWithdraw: requested more unt than available.");
            paidToController += _amountUnt;

        } else {

            (IUniftyGovernanceConsumer con,address peer,,,) = gov.accountInfo(msg.sender);
            require(con == this && peer != address(0) && peer == exhibition, "optionWithdraw: access denied.");

            collectUnt();
            uint256 _earned = ( accountReserved[msg.sender] + ( ( collectedUnt * accountPrevAmount[msg.sender] ) / 10**18 ) ) - accountDebt[msg.sender];
            require(_earned >= _amountUnt, "optionWithdraw: requested more unt than available.");
            accountDebt[msg.sender] += _amountUnt;
        }

        uint256 paid = payout(msg.sender, _amountUnt);

        (,uint256 ethPrice,,) = priceOracle.getUntPrices();
        uint256 price = (_amountUnt * ethPrice * 10**8) / 10**18;
        
        require(msg.value >= price, "optionWithdraw: insufficient eth sent.");
        
        payable(IExhibition(exhibition).uniftyFeeAddress()).transfer(price);

        return paid;
    }

    function isOptionWithdraw(address _account) override public view returns(bool){

        return !( IExhibition(exhibition).isArtistExhibition() && _account == IExhibition(exhibition).controller() );
    }

    function payout(address _to, uint256 _amount) internal returns(uint256) {

        require(_amount != 0, "payout: nothing to pay out.");

        gov.mintUnt(_amount);

        IERC20Simple(untAddress).transfer(_to, _amount);

        emit Withdrawn(_to, _amount);

        return _amount;
    }

    /**
    * Must return the account's _current_ UNT earnings (as of current blockchain state).
    *
    * Used in the frontend.
    * */
    function earned(address _account) override external view returns(uint256){

        if(_account == IExhibition(exhibition).controller()){

            uint256 endTime = block.timestamp;

            if (endTime < allocationEnd ) {
                return 0;
            }

            if(endTime > exhibitionEnd){

                endTime = exhibitionEnd;
            }

            return ( ( endTime - allocationEnd ) * untRateExhibitionController ) - paidToController;
        }

        (IUniftyGovernanceConsumer con,address peer,,,) = gov.accountInfo(_account);

        if(con != this || peer != exhibition || exhibition == address(0)){

            return 0;
        }

        return ( accountReserved[_account] + ( ( collectedUnt * accountPrevAmount[_account] ) / 10**18 ) ) - accountDebt[_account];
    }

    /**
     * Same as earned() except adding a live component that may be inaccurate due to not yet occurred state-changes.
     *
     * If unsure how to implement, call and return earned() inside.
     *
     * Used in the frontend.
     * */
    function earnedLive(address _account) override external view returns(uint256){

        if(_account == IExhibition(exhibition).controller()){

            uint256 endTime = block.timestamp;

            if (endTime < allocationEnd ) {
                return 0;
            }

            if(endTime > exhibitionEnd){

                endTime = exhibitionEnd;
            }

            return ( ( endTime - allocationEnd ) * untRateExhibitionController ) - paidToController;
        }

        (IUniftyGovernanceConsumer con,address peer,,,) = gov.accountInfo(_account);

        if(con != this || peer != exhibition || exhibition == address(0)){

            return 0;
        }

        uint256 coll = collectedUnt;

        uint256 alloc = gov.consumerPeerNifAllocation(this, exhibition);

        if (block.number > lastCollectionBlock && alloc != 0) {

            coll += ( accumulatedUnt() * 10**18 ) / alloc;
        }

        return ( accountReserved[_account] + ( ( coll * accountPrevAmount[_account] ) / 10**18 ) ) - accountDebt[_account];
    }

    function accumulatedUnt() public view returns(uint256){

        if(lastCollectionUpdate == 0 || lastCollectionUpdate >= exhibitionEnd || block.timestamp < allocationEnd ){

            return 0;
        }

        if(block.timestamp >= exhibitionEnd){

            return ( exhibitionEnd - lastCollectionUpdate ) * untRate;
        }

        return ( ( block.timestamp - lastCollectionUpdate ) * untRate );
    }

    /**
     * Collect the current UNT based on real-time nif allocations
     *
     * */
    function collectUnt() internal{

        uint256 alloc = gov.consumerPeerNifAllocation(this, exhibition);

        if(alloc != 0){

            collectedUnt += ( accumulatedUnt() * 10**18 ) / alloc;
        }

        lastCollectionUpdate = block.timestamp;
        lastCollectionBlock = block.number;
    }

    /**
     * Override of collectUnt() being used to allow calculations based on previous allocations
     */
    function collectUnt(uint256 nifAllocation) internal{

        if(nifAllocation != 0){

            collectedUnt += ( accumulatedUnt() * 10**18 ) / nifAllocation;
        }

        lastCollectionUpdate = block.timestamp;
        lastCollectionBlock = block.number;
    }

    /**
     * _peer parameter to apply the AP info for.
     *
     * Frontend function to help displaying apr/apy and similar strategies.
     *
     * The first index of the returned tuple should return "r" if APR or "y" if APY.
     *
     * The second index of the returned tuple should return the actual APR/Y value for the consumer.
     * 18 decimals precision required.
     *
     * The 2nd uint256[] array should return a list of proposed services for price discovery on the client-side.
     *
     * 0 = uni-v2 unt/eth
     * 1 = uni-v2 unt/usdt
     * 2 = uni-v2 unt/usdc
     * 3 = uni-v3 unt/eth
     * 4 = uni-v3 unt/usdt
     * 5 = uni-v3 unt/usdc
     * 6 = kucoin unt/usdt
     * 7 = binance unt/usdt
     *
     * The rate and list should be udpatable/extendible through an admin function due to possible updates on the client-side.
     * (e.g. adding more exchanges)
     *
     * */
    function apInfo(address _peer) override external view returns(string memory, uint256, uint256[] memory){

        if( _peer != exhibition || exhibition == address(0) ){

            uint256[] memory n;
            return ("",0,n);
        }

        return ("r", untRate * 86400 * 365, priceProviders);
    }

    /**
     * Peer whitelist required to be implemented.
     * If no peers should be used, this can have an empty implementation.
     *
     * Example would be to vote for farms in the governance being included.
     * Accepted peers can then be added to the consumer's internal whitelist and get further benefits like UNT.
     *
     * Must contain a check if the caller has been the governance.
     *
     * Must return a string holding the name of the peer (being used for client display).
     * */
    function whitelistPeer(address _peer) override external lock{

        require(IUniftyGovernance(msg.sender) == gov, "whitelistPeer: access denied.");
        require(exhibition != _peer, "whitelistPeer: peer exists already.");

        exhibition = _peer;

        // exhibitionDuration is equal to the actual exhibition duration
        exhibitionStart = block.timestamp;
        exhibitionEnd = exhibitionStart + exhibitionDuration;
        allocationEnd = exhibitionStart + allocationDuration;
    }

    /**
     * Peer whitelist removal required to be implemented.
     * If no peers should be used, this can have an empty implementation.
     *
     * Example would be to vote for farms in the governance being removed and exluded.
     *
     * Must contain a check if the caller has been the governance.
     *
     * */
    function removePeerFromWhitelist(address _peer) override external lock{

        require(IUniftyGovernance(msg.sender) == gov, "removePeerFromWhitelist: access denied.");
        require(_peer == exhibition, "removePeerFromWhitelist: peer not whitelisted.");

        exhibition = address(0);
    }

    /**
     * Called by the governance to signal an allocation event.
     *
     * The implementation must limit calls to the governance and should
     * give the consumer a chance to handle allocations (like timestamp updates)
     *
     * Returns true if the allocation has been accepted, false if not.
     * */
    function allocate(address _account, uint256 prevAllocation, address _peer) override external lock returns(bool){

        require(IUniftyGovernance(msg.sender) == gov, "allocate: access denied.");
        require(_peer == exhibition && exhibition != address(0), "allocate: invalid peer.");
        require(_account != IExhibition(exhibition).controller(), "allocate: exbibition controller is not allowed to allocate.");

        (,,,,uint256 amount) = gov.accountInfo(_account);

        if(block.timestamp > allocationEnd || pausing){

            return false;
        }

        accountPrevAmount[_account] = amount;

        collectUnt();
        accountDebt[_account] = ( collectedUnt * amount ) / 10**18;

        return true;
    }

    /**
     * Called by the governance upon staking if the allocation for a user and a peer changes.
     * The consumer has then the ability to check what has been changed and act accordingly.
     *
     * Must contain a check if the caller has been the governance.
     * */
    function allocationUpdate(address _account, uint256 prevAmount, uint256 prevAllocation, address _peer) override external lock returns(bool, uint256){

        require(IUniftyGovernance(msg.sender) == gov, "allocationUpdate: access denied.");
        require(_peer == exhibition && exhibition != address(0), "allocationUpdate: invalid peer.");

        if(accountPrevAmount[_account] == 0){

            return (true, 0);
        }

        (,,,,uint256 amount) = gov.accountInfo(_account);

        if(amount > accountPrevAmount[_account] && block.timestamp >= allocationEnd){

            return (false, 0);
        }

        collectUnt(prevAllocation);

        uint256 _earned = ( ( collectedUnt * accountPrevAmount[_account] ) / 10**18 ) - accountDebt[_account];

        accountDebt[_account] = ( collectedUnt * amount ) / 10**18;

        accountPrevAmount[_account] = amount;

        accountReserved[_account] += _earned;

        emit Reserved(_account, _earned);

        return (true, _earned);

    }

    /**
     * Called by the governance to signal an dellocation event.
     *
     * The implementation must limit calls to the governance and should
     * give the consumer a chance to handle allocations (like timestamp updates)
     *
     * */
    function dellocate(address _account, uint256 prevAllocation, address _peer) override external lock returns(uint256){

        require(IUniftyGovernance(msg.sender) == gov, "dellocate: access denied.");
        require(_peer == exhibition && exhibition != address(0), "dellocate: invalid peer.");

        if(accountPrevAmount[_account] == 0){

            return 0;
        }

        collectUnt(prevAllocation);

        uint256 _earned = ( ( collectedUnt * accountPrevAmount[_account] ) / 10**18 ) - accountDebt[_account];
        accountDebt[_account] = 0;
        accountPrevAmount[_account] = 0;

        accountReserved[_account] += _earned;

        emit Reserved(_account, _earned);

        return _earned;
    }

    /**
     * Must return the time in seconds that is left until the allocation
     * of a user to the peer he is allocating to expires.
     *
     * */
    function timeToUnfreeze(address _account) override external view returns(uint256){

        (,,,,uint256 amount) = gov.accountInfo(_account);

        if(amount != 0 && block.timestamp >= allocationEnd && exhibitionEnd > block.timestamp){

            return exhibitionEnd - block.timestamp;
        }

        return 0;
    }

    /**
     * Called by the governance to determine if allocated stakes of an account in the governance should stay frozen.
     * If this returns true, the governance won't release NIF upon unstaking.
     *
     * */
    function frozen(address _account) override public view returns(bool){

        (,,,,uint256 amount) = gov.accountInfo(_account);

        if(amount != 0 && block.timestamp >= allocationEnd && block.timestamp < exhibitionEnd){

            return true;
        }

        return false;
    }

    /**
     * The name of this consumer must be requestable.
     *
     * This information is supposed to be used in clients.
     *
     * */
    function name() override view external returns(string memory){

        return consumerName;
    }

    /**
     * The description for this consumer must be requestable.
     *
     * This information is supposed to be used in clients.
     *
     * */
    function description() override view external returns(string memory){

        return consumerDscription;
    }


    /**
     * Returns true if the peer is whitelisted, otherwise false.
     *
     * */
    function peerWhitelisted(address _peer) override view external returns(bool){

        return _peer == exhibition && exhibition != address(0);
    }

    /**
     * Should return a URI, pointing to a json file in the format:
     *
     * {
     *   name : '',
     *   description : '',
     *   external_link : '',
     * }
     *
     * Can throw an error if the peer is not whitelisted or return an empty string if there is no further information.
     * Since this is supposed to be called by clients, those have to catch errors and handle empty return values themselves.
     *
     * */
    function peerUri(address _peer) override external view returns(string memory){

        return _peer == exhibition && exhibition != address(0) ? uriPeer : "";
    }

    /**
     * If there are any nif caps per peer, this function should return those.
     *
     * */
    function peerNifCap(address _peer) override external view returns(uint256){

        return 0;
    }

    /**
     * In case we want to move to a new governance
     *
     * */
    function setGovernance(IUniftyGovernance _gov) external lock{

        require(owner == msg.sender, "setGovernance: not the owner.");
        require(address(_gov) != address(0), "setGovernance: cannot move to the null address.");

        exhibition = address(0);

        gov = _gov;
    }

    function setPeerUri(string calldata _uri) external lock{

        require(owner == msg.sender, "setPeerUri: not the owner.");

        uriPeer = _uri;
    }

    function setGraceTime(uint256 _graceTime) external lock{

        require(owner == msg.sender, "setGraceTime: not the owner.");

        graceTime = _graceTime;
    }

    function setPausing(bool _pausing, bool _withdrawOnPause) external lock{

        require(owner == msg.sender, "setPausing: not the owner.");

        pausing = _pausing;
        withdrawOnPause = _withdrawOnPause;
    }


    function setPriceProviders(uint256[] calldata _priceProviders) external lock{

        require(owner == msg.sender, "setUntRateAndPriceProviders: not the owner.");

        priceProviders = _priceProviders;
    }

    function setDurations(
        uint256 _exhibitionDuration,
        uint256 _allocationDuration,
        uint256 _controllerVestingDuration,
        uint256 _optionExerciseDuration) external lock{

        require(owner == msg.sender, "setDurations: not the owner.");

        exhibitionDuration = _exhibitionDuration;
        allocationDuration = _allocationDuration;
        controllerVestingDuration = _controllerVestingDuration;
        optionExerciseDuration = _optionExerciseDuration;
    }

    function setNameAndDescription(string calldata _name, string calldata _description) external lock{

        require(owner == msg.sender, "setNameAndDescription: not the owner.");

        consumerName = _name;
        consumerDscription = _description;
    }

    function setPriceOracle(IUntPriceOracle _priceOracle) external lock{

        require(owner == msg.sender, "setUntPriceOracle: not the owner.");

        priceOracle = _priceOracle;
    }

    function setRates(uint256 _untRateStakers, uint256 _untRateExhibitionController) external lock{

        require(owner == msg.sender, "setRates: not the owner.");

        untRate = _untRateStakers;
        untRateExhibitionController = _untRateExhibitionController;
    }

    function continueExhibition() external lock{

        require(owner == msg.sender, "continueExhibition: not the owner.");

        exhibitionEnd = block.timestamp + exhibitionDuration;
        allocationEnd = block.timestamp + allocationDuration;
        collectUnt();
    }

    function optionsRelease() external lock{

        require(owner == msg.sender, "optionRelease: not the owner.");
        require(block.timestamp >= exhibitionEnd + optionExerciseDuration, "optionsRelease: options not releasable yet.");

        uint256 grantLeft = gov.earnedUnt(this);

        if(!isOptionWithdraw(IExhibition(exhibition).controller())){

            grantLeft -= ( ( exhibitionEnd - allocationEnd ) * untRateExhibitionController ) - paidToController;
        }

        gov.mintUnt(grantLeft);

        IERC20Simple(untAddress).transfer(IExhibition(exhibition).uniftyFeeAddress(), grantLeft);
    }

    function emergencyRelease(uint256 _amount) external lock{

        require(owner == msg.sender, "emergencyRelease: not the owner.");

        gov.mintUnt(_amount);

        IERC20Simple(untAddress).transfer(IExhibition(exhibition).uniftyFeeAddress(), _amount);
    }

    function transferOwnership(address _newOwner) external lock{

        require(owner == msg.sender, "transferOwnership: not the owner.");

        owner = _newOwner;
    }
}