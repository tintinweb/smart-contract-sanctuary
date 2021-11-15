pragma solidity ^0.8.4;

import "./IUniftyGovernanceConsumer.sol";
import "./IUniftyGovernance.sol";
import "./IERC20Simple.sol";

contract LaunchVault is IUniftyGovernanceConsumer{

    // the governance this consumer is assigned to
    IUniftyGovernance public gov;

    // unt address
    address public untAddress;

    // duration in seconds an allocation in the governance - for peers of this consumer - should freeze
    uint256 public minAllocationDuration; // default: 86400 * 10 should be 10 days after acceptance
    uint256 public allocationExpirationTime; // will be set upon adding this as peer based on minAllocationDuration
    
    // check if the peer is registered with this consumer
    // since this consumer has only one peer (itself) we don't need a mapping or array of peers
    bool public isPeer;

    // reward rate for UNT
    uint256 public untRate;

    uint256 public graceTime;

    string public uriPeer;

    string public consumerName;

    string public consumerDscription;

    address public owner;

    uint256 public collectedUnt;

    uint256 public lastCollectionTime;

    uint256 public nifCap;

    uint256[] public priceProviders;

    uint256 public lastCollectionBlock;
    
    bool public pausing;
    
    bool public withdrawOnPause;

    mapping(address => uint256) public accountDebt;
    mapping(address => uint256) public accountCredit;
    mapping(address => uint256) public accountPrevAmount;
    
    event Credited(address indexed user, uint256 untCredited);
    event CreditPaid(address indexed user, uint256 untPaid);

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
        uint256 _minAllocationDuration,
        uint256 _nifCap,
        uint256 _untRate,
        uint256[] memory _priceProviders
    ){

        gov = _gov;
        owner = msg.sender;
        consumerName = _name;
        consumerDscription = _description;
        uriPeer = _peerUri;
        graceTime = _graceTime;
        minAllocationDuration = _minAllocationDuration;
        nifCap = _nifCap;
        untRate = _untRate;
        priceProviders = _priceProviders;
        untAddress = 0xF8fCC10506ae0734dfd2029959b93E6ACe5b2a70;
        // untrate: 3858024690000000000
    }

    /**
     * In case we want to move to a new governance
     *
     * */
    function setGovernance(IUniftyGovernance _gov) external lock{

        require(owner == msg.sender, "setGovernance: not the owner.");
        require(address(_gov) != address(0), "setGovernance: cannot move to the null address.");

        // we need to reset the peer status as this is a new governance
        isPeer = false;

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

    function setNifCap(uint256 _nifCap) external lock{

        require(owner == msg.sender, "setNifCap: not the owner.");

        nifCap = _nifCap;

    }
    
    function setPausing(bool _pausing, bool _withdrawOnPause) external lock{

        require(owner == msg.sender, "setPausing: not the owner.");

        pausing = _pausing;
        withdrawOnPause = _withdrawOnPause;

    }

    function setUntRateAndPriceProviders(uint256 _untRate, uint256[] calldata _priceProviders) external lock{

        require(owner == msg.sender, "setUntRateAndPriceProviders: not the owner.");

        untRate = _untRate;
        priceProviders = _priceProviders;

    }

    function setMinAllocationDuration(uint256 _minAllocationDuration) external lock{

        require(owner == msg.sender, "setMinAllocationDuration: not the owner.");

        minAllocationDuration = _minAllocationDuration;
        
        if(allocationExpirationTime != 0){
            
            allocationExpirationTime = block.timestamp + _minAllocationDuration;
        }

    }

    function setNameAndDescription(string calldata _name, string calldata _description) external lock{

        require(owner == msg.sender, "setNameAndDescription: not the owner.");

        consumerName = _name;
        consumerDscription = _description;

    }

    function transferOwnership(address _newOwner) external lock{

        require(owner == msg.sender, "transferOwnership: not the owner.");

        owner = _newOwner;
    }

    /**
     * ############################
     * #
     * # INTERFACE IMPLEMENTATIONS
     * #
     * ########################################
     * */

    /**
    * Withdraws UNT rewards for accounts that stake in the governance and allocated their funds to this consumer and peer.
    *
    * Must return the amount of withdrawn UNT.
    *
    * */
    function withdraw() override external lock returns(uint256){

        require(!pausing || ( pausing && withdrawOnPause ), "withdraw: pausing, sorry.");

        (IUniftyGovernanceConsumer con,address peer,,,) = gov.accountInfo(msg.sender);
        
        require(con == this && peer == address(this) && isPeer, "withdraw: access denied.");
        
        // must be the same as in frozen() since a witdraw is equivalent to dellocate() and allocationUpdate() as they may perform payouts
        require(!frozen(msg.sender), "withdraw: you are withdrawing too early.");

        collectUnt();
        uint256 _earned = ( ( collectedUnt * accountPrevAmount[msg.sender] ) / 10**18 ) - accountDebt[msg.sender];
        accountDebt[msg.sender] = ( collectedUnt * accountPrevAmount[msg.sender] ) / 10**18;

        uint256 paid = payout(msg.sender, _earned);

        return paid;
    }

    function payout(address _to, uint256 _amount) internal returns(uint256) {
        
        // adding the credited unt from allocationUpdate() if payouts were frozen at that time
        
        uint256 credit = accountCredit[_to];
        accountCredit[_to] = 0;
        _amount += credit;
        
        // if the earned exceeds the available grant left, we just take the rest.
        // we won't be able to take more than that anyway but prevent errors and 
        // allow the last one withdrawing to take what is left from the overall grant.
        
        uint256 grantLeft = gov.earnedUnt(this);
        
        if(_amount > grantLeft){
            
            _amount = grantLeft;
        }
        
        require(_amount != 0, "payout: nothing to pay out.");

        gov.mintUnt(_amount);

        IERC20Simple(untAddress).transfer(_to, _amount);
        
        emit Withdrawn(_to, _amount);
        
        if(credit != 0 && _amount <= grantLeft){

            emit CreditPaid(_to, credit);
        }
        
        return _amount;
    }

    /**
    * Must return the account's _current_ UNT earnings (as of current blockchain state).
    *
    * Used in the frontend.
    * */
    function earned(address _account) override external view returns(uint256){

        (IUniftyGovernanceConsumer con,address peer,,,) = gov.accountInfo(_account);

        if(con != this || peer != address(this) || !isPeer){

            return 0;
        }

        return ( ( collectedUnt * accountPrevAmount[_account] ) / 10**18 ) - accountDebt[_account];
    }

    /**
     * Same as earned() except adding a live component that may be inaccurate due to not yet occurred state-changes.
     *
     * If unsure how to implement, call and return earned() inside.
     *
     * Used in the frontend.
     * */
    function earnedLive(address _account) override external view returns(uint256){

        (IUniftyGovernanceConsumer con,address peer,,,) = gov.accountInfo(_account);

        if(con != this || peer != address(this) || !isPeer){

            return 0;
        }

        uint256 coll = collectedUnt;

        uint256 alloc = gov.consumerPeerNifAllocation(this, address(this));

        if (block.number > lastCollectionBlock && alloc != 0) {

            coll += ( accumulatedUnt() * 10**18 ) / alloc;
        }

        return ( ( coll * accountPrevAmount[_account] ) / 10**18 ) - accountDebt[_account];
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

        if( _peer != address(this) || !isPeer){

            uint256[] memory n;
            return ("",0,n);
        }

        return ("r", untRate * 86400 * 365, priceProviders);
    }

    function accumulatedUnt() internal view returns(uint256){

        if(lastCollectionTime == 0){

            return 0;
        }

        return ( block.timestamp - lastCollectionTime ) * untRate;
    }

    /**
     * Collect the current UNT based on real-time nif allocations
     * 
     * */
    function collectUnt() internal{

        uint256 alloc = gov.consumerPeerNifAllocation(this, address(this));

        if(alloc != 0){

            collectedUnt += ( accumulatedUnt() * 10**18 ) / alloc;
        }

        lastCollectionTime = block.timestamp;
        lastCollectionBlock = block.number;
    }
    
    /**
     * Override of collectUnt() being used to allow calculations based on previous allocations
     */
    function collectUnt(uint256 nifAllocation) internal{

        if(nifAllocation != 0){

            collectedUnt += ( accumulatedUnt() * 10**18 ) / nifAllocation;
        }

        lastCollectionTime = block.timestamp;
        lastCollectionBlock = block.number;
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
        require(_peer == address(this), "whitelistPeer: this consumer only allows itself as peer.");
        require(!isPeer, "whitelistPeer: peer exists already.");

        isPeer = true;
        
        allocationExpirationTime = block.timestamp + minAllocationDuration;
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
        require(_peer == address(this), "removePeerFromWhitelist: this consumer only allows itself as peer.");
        require(isPeer, "removePeerFromWhitelist: peer not whitelisted.");

        isPeer = false;
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
        require(_peer == address(this) && isPeer, "allocate: invalid peer.");

        (,,,,uint256 amount) = gov.accountInfo(_account);

        uint256 alloc = gov.consumerPeerNifAllocation(this, address(this));

        if(alloc > nifCap || pausing){

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
        require(_peer == address(this) && isPeer, "allocationUpdate: invalid peer.");

        if(accountPrevAmount[_account] == 0){

            return (true, 0);
        }

        (,,,,uint256 amount) = gov.accountInfo(_account);

        uint256 alloc = gov.consumerPeerNifAllocation(this, address(this));

        if(alloc > nifCap){
            
            return (false, 0);
        }
        
        collectUnt(prevAllocation);
        
        uint256 _earned = ( ( collectedUnt * accountPrevAmount[_account] ) / 10**18 ) - accountDebt[_account];

        accountDebt[_account] = ( collectedUnt * amount ) / 10**18;
        
        accountPrevAmount[_account] = amount;
        
        uint256 actual = _earned;
        
        if(!frozen(_account) && !pausing){

            actual = payout(_account, _earned);

        }else{

            accountCredit[_account] += _earned;

            emit Credited(_account, _earned);
        }

        return (true, actual);

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
        require(_peer == address(this) && isPeer, "dellocate: invalid peer.");

        if(accountPrevAmount[_account] == 0){

            return 0;
        }

        collectUnt(prevAllocation);
        
        uint256 _earned = ( ( collectedUnt * accountPrevAmount[_account] ) / 10**18 ) - accountDebt[_account];
        accountDebt[_account] = 0;
        accountPrevAmount[_account] = 0;
        
        uint256 actual = _earned;
        
        if(pausing){
            
            accountCredit[_account] += _earned;

            emit Credited(_account, _earned);
            
        }else{
            
            actual = payout(_account, _earned);
        }
        
        return actual;
    }

    /**
     * Must return the time in seconds that is left until the allocation
     * of a user to the peer he is allocating to expires.
     *
     * */
    function timeToUnfreeze(address _account) override external view returns(uint256){

        (IUniftyGovernanceConsumer con, address peer,,,) = gov.accountInfo(_account);

        if(con != this || peer != address(this) || !isPeer || pausing){

            return 0;
        }

        uint256 _target = allocationExpirationTime + graceTime;
        return _target >= block.timestamp ? _target - block.timestamp : 0;
    }

    /**
     * Called by the governance to determine if allocated stakes of an account in the governance should stay frozen.
     * If this returns true, the governance won't release NIF upon unstaking.
     *
     * */
    function frozen(address _account) override public view returns(bool){

        (IUniftyGovernanceConsumer con, address peer,,,) = gov.accountInfo(_account);

        // since this consumer is also the only peer, we can return false if the account is not allocating to it.
        // in more complex implementation, this consumer would need to check for the actual existence of the peer given.
        // nevertheless we check if this consumer is being whitelisted to respect governance decisions.
        if(con != this || peer != address(this) || !isPeer || pausing){

            return false;
        }

        if( block.timestamp > allocationExpirationTime + graceTime ){

            return false;
        }

        return true;

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

        return _peer == address(this) && isPeer;
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

        return _peer == address(this) && isPeer ? uriPeer : "";
    }

    /**
     * If there are any nif caps per peer, this function should return those.
     * 
     * */
    function peerNifCap(address _peer) override external view returns(uint256){
        
        if(_peer != address(this) || !isPeer){

            return 0;
        }
        
        return nifCap;
        
    }

}

pragma solidity ^0.8.4;

/**
 * @dev Simple Interface with a subset of the ERC20 standard as defined in the EIP needed by the DAO (and not more).
 */
interface IERC20Simple {

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.8.4;

import "./IUniftyGovernanceConsumer.sol";

interface IUniftyGovernance{

    /**
     * Returns the current epoch number.
     * */
    function epoch() external returns(uint256);
    
    /**
     * Returns the overall grantable $UNT left in the governance contract.
     * */
    function grantableUnt() external returns(uint256);
    
    /**
     * Can only be called by a registered consumer and _amount cannot exceed the granted $UNT
     * as per current emission rate.
     * */
    function mintUnt(uint256 _amount) external;
    
    /**
     * Returns the account info for the given 
     * _account parameters:
     * 
     * ( 
     *  IUniftyGovernanceConsumer consumer,
     *  address peer,  
     *  uint256 allocationTime,
     *  uint256 unstakableFrom,
     *  uint256 amount
     * )
     * */
    function accountInfo(address _account) external view returns(IUniftyGovernanceConsumer, address, uint256, uint256, uint256);
    
    /**
     * Returns the consumer info for the given _consumer.
     * 
     * (
     *  uint256 grantStartTime,
     *  uint256 grantRateSeconds,
     *  uint256 grantSizeUnt,
     *  address[] peers
     * )
     * 
     * */
    function consumerInfo(IUniftyGovernanceConsumer _consumer) external view returns(uint256, uint256, uint256, address[] calldata, string[] calldata);
    
    /**
     * Returns the amount of accounts allocating to the given _peer of _consumer.
     * */
    function nifAllocationLength(IUniftyGovernanceConsumer _consumer, address _peer) external view returns(uint256);
    
    /**
     * Returns the currently available $UNT for the given _consumer.
     * */
    function earnedUnt(IUniftyGovernanceConsumer _consumer) external view returns(uint256);
    
    /**
     * Returns true if the governance is pausing. And fals if not.
     * It is recommended but not mandatory to take this into account in your own implemenation.
     * */
    function isPausing() external view returns(bool);
    
    /**
     * The amount of $NIF being allocated to the given _peer of _consumer.
     * */
    function consumerPeerNifAllocation(IUniftyGovernanceConsumer _consumer, address _peer) external view returns(uint256);
}

pragma solidity ^0.8.4;

/**
 * Mandatory interface for a UniftyGovernanceConsumer.
 * 
 * */
interface IUniftyGovernanceConsumer{
    
    /**
     * Must be emitted in withdraw() function.
     * 
     * */
    event Withdrawn(address indexed user, uint256 untEarned);

    /**
     * The name of this consumer must be requestable.
     * 
     * This information is supposed to be used in clients.
     * 
     * */
    function name() external view returns(string calldata);
    
    /**
     * The description for this consumer must be requestable.
     * 
     * This information is supposed to be used in clients.
     * 
     * */
    function description() external view returns(string calldata);
    
    /**
     * Peer whitelist required to be implemented.
     * If no peers should be used, this can have an empty implementation.
     * 
     * Example would be to vote for farms in the governance being included.
     * Accepted peers can then be added to the consumer's internal whitelist and get further benefits like UNT.
     * 
     * Must contain a check if the caller has been the governance.
     * 
     * */
    function whitelistPeer(address _peer) external;
    
    /**
     * Peer whitelist removal required to be implemented.
     * If no peers should be used, this can have an empty implementation.
     * 
     * Example would be to vote for farms in the governance being removed and exluded.
     * 
     * Must contain a check if the caller has been the governance.
     * 
     * */
    function removePeerFromWhitelist(address _peer) external;
    
    /**
     * Called by the governance to signal an allocation event.
     * 
     * The implementation must limit calls to the governance and should
     * give the consumer a chance to handle allocations (like timestamp updates)
     * 
     * Returns true if the allocation has been accepted, false if not.
     * 
     * Must contain a check if the caller has been the governance.
     * */
    function allocate(address _account, uint256 prevAllocation, address _peer) external returns(bool);
    
    /**
     * Called by the governance upon staking if the allocation for a user and a peer changes.
     * The consumer has then the ability to check what has been changed and act accordingly.
     *
     * Must contain a check if the caller has been the governance.
     * */
    function allocationUpdate(address _account, uint256 prevAmount, uint256 prevAllocation, address _peer) external returns(bool, uint256);
    
    /**
     * Called by the governance to signal an dellocation event.
     * 
     * The implementation must limit calls to the governance and should
     * give the consumer a chance to handle allocations (like timestamp updates)
     * 
     * This functions is also called by the governance before it calls allocate.
     * This must be akten into account to avoid side-effects.
     * */
    function dellocate(address _account, uint256 prevAllocation, address _peer) external returns(uint256);
    
    /**
     * Called by the governance to determine if allocated stakes of an account in the governance should stay frozen.
     * If this returns true, the governance won't release NIF upon unstaking.
     * 
     * */
    function frozen(address _account) external view returns(bool);
    
    /**
     * Returns true if the peer is whitelisted, otherwise false.
     * 
     * */
    function peerWhitelisted(address _peer) external view returns(bool);
    
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
    function peerUri(address _peer) external view returns(string calldata);
    
    /**
     * Must return the time in seconds that is left until the allocation 
     * of a user to the peer he is allocating to expires.
     * 
     * */
    function timeToUnfreeze(address _account) external view returns(uint256);
    
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
    function apInfo(address _peer) external view returns(string memory, uint256, uint256[] memory);
    
    /**
     * Withdraws UNT rewards for accounts that stake in the governance and allocated their funds to this consumer and peer.
     * 
     * Must return the amount of withdrawn UNT.
     * 
     * */
    function withdraw() external returns(uint256);
    
    /**
     * Must return the account's _current_ UNT earnings (as of current blockchain state).
     * 
     * Used in the frontend.
     * */
    function earned(address _account) external view returns(uint256);
    
    /**
     * Same as earned() except adding a live component that may be inaccurate due to not yet occurred state-changes.
     * 
     * If unsure how to implement, call and return earned() inside.
     * 
     * Used in the frontend.
     * */
    function earnedLive(address _account) external view returns(uint256);
    
    /**
     * If there are any nif caps per peer, this function should return those.
     * 
     * */
    function peerNifCap(address _peer) external view returns(uint256);
}

