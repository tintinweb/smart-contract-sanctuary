pragma solidity =0.5.16;

import "./libraries/SafeMathM.sol";
import "./libraries/ZapStorage.sol";
import "./libraries/ZapDispute.sol";
import "./libraries/ZapStake.sol";
import "./libraries/ZapLibrary.sol";
import "./libraries/ZapTransfer.sol";
import "../token/ZapTokenBSC.sol";
import "./Vault.sol";

/**
 * @title Zap Oracle System
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * The logic for this contract is in ZapLibrary.sol, ZapDispute.sol, ZapStake.sol,
 * and ZapTransfer.sol
 */
contract Zap {
    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    ); //emitted when a new dispute is initialized
    event NewChallenge(
        bytes32 _currentChallenge,
        uint256 indexed _currentRequestId,
        uint256 _difficulty,
        uint256 _multiplier,
        string _query,
        uint256 _totalTips
    ); //emits when a new challenge is created (either on mined block or when a new request is pushed forward on waiting system)
    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip,
        uint256 _totalTips
    );
    event NewRequestOnDeck(
        uint256 indexed _requestId,
        string _query,
        bytes32 _onDeckQueryHash,
        uint256 _onDeckTotalTips
    ); //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request
    event DataRequested(
        address indexed _sender,
        string _query,
        string _querySymbol,
        uint256 _granularity,
        uint256 indexed _requestId,
        uint256 _totalTips
    ); //Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); //ERC20 Approval event
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    using SafeMathM for uint256;

    using ZapDispute for ZapStorage.ZapStorageStruct;
    using ZapLibrary for ZapStorage.ZapStorageStruct;
    using ZapStake for ZapStorage.ZapStorageStruct;

    ZapStorage.ZapStorageStruct zap;
    ZapTokenBSC public token;

    address payable public owner;

    constructor(address zapTokenBsc) public {
        token = ZapTokenBSC(zapTokenBsc);
        owner = msg.sender;
    }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function balanceOf(address _user) public view returns (uint256 balance) {
        return token.balanceOf(_user);
    }

    /*Functions*/

    /**
     * @dev Helps initialize a dispute by assigning it a disputeId
     * when a miner returns a false on the validate array(in Zap.ProofOfWork) it sends the
     * invalidated value information to POS voting
     * @param _requestId being disputed
     * @param _timestamp being disputed
     * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
     * requires 5 miners to submit a value.
     */
    function beginDispute(
        uint256 _requestId,
        uint256 _timestamp,
        uint256 _minerIndex
    ) external {
        ZapStorage.Request storage _request = zap.requestDetails[_requestId];
        //require that no more than a day( (24 hours * 60 minutes)/10minutes=144 blocks) has gone by since the value was "mined"
        require(block.number - _request.minedBlockNum[_timestamp] <= 144);
        require(_request.minedBlockNum[_timestamp] > 0);
        require(_minerIndex < 5);

        //_miner is the miner being disputed. For every mined value 5 miners are saved in an array and the _minerIndex
        //provided by the party initiating the dispute
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash = keccak256(
            abi.encodePacked(_miner, _requestId, _timestamp)
        );

        //Ensures that a dispute is not already open for the that miner, requestId and timestamp
        require(zap.disputeIdByDisputeHash[_hash] == 0);

        doTransfer(
            msg.sender,
            address(this),
            zap.uintVars[keccak256("disputeFee")]
        );

        //Increase the dispute count by 1
        zap.uintVars[keccak256("disputeCount")] =
            zap.uintVars[keccak256("disputeCount")] +
            1;

        //Sets the new disputeCount as the disputeId
        uint256 disputeId = zap.uintVars[keccak256("disputeCount")];

        //maps the dispute hash to the disputeId
        zap.disputeIdByDisputeHash[_hash] = disputeId;
        //maps the dispute to the Dispute struct
        zap.disputesById[disputeId] = ZapStorage.Dispute({
            hash: _hash,
            isPropFork: false,
            reportedMiner: _miner,
            reportingParty: msg.sender,
            proposedForkAddress: address(0),
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });

        //Saves all the dispute variables for the disputeId
        zap.disputesById[disputeId].disputeUintVars[
            keccak256("requestId")
        ] = _requestId;
        zap.disputesById[disputeId].disputeUintVars[
            keccak256("timestamp")
        ] = _timestamp;
        zap.disputesById[disputeId].disputeUintVars[
            keccak256("value")
        ] = _request.valuesByTimestamp[_timestamp][_minerIndex];
        zap.disputesById[disputeId].disputeUintVars[
            keccak256("minExecutionDate")
        ] = now + 7 days;
        zap.disputesById[disputeId].disputeUintVars[
            keccak256("blockNumber")
        ] = block.number;
        zap.disputesById[disputeId].disputeUintVars[
            keccak256("minerSlot")
        ] = _minerIndex;
        zap.disputesById[disputeId].disputeUintVars[keccak256("fee")] = zap
        .uintVars[keccak256("disputeFee")];

        //Values are sorted as they come in and the official value is the median of the first five
        //So the "official value" miner is always minerIndex==2. If the official value is being
        //disputed, it sets its status to inDispute(currentStatus = 3) so that users are made aware it is under dispute
        if (_minerIndex == 2) {
            zap.requestDetails[_requestId].inDispute[_timestamp] = true;
        }
        zap.stakerDetails[_miner].currentStatus = 3;
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }

    /**
     * @dev Allows token holders to vote
     * @param _disputeId is the dispute id
     * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
     */
    function vote(uint256 _disputeId, bool _supportsDispute) external {
        zap.vote(_disputeId, _supportsDispute);
    }

    /**
     * @dev tallies the votes.
     * @param _disputeId is the dispute id
     */
    function tallyVotes(uint256 _disputeId) external {
        (address _from, address _to, uint256 _disputeFee) = zap.tallyVotes(
            _disputeId
        );

        approve(_from, _disputeFee);
        // token.transferFrom(_from, _to, _disputeFee);
        doTransfer(_from, _to, _disputeFee);
    }

    /**
     * @dev Allows for a fork to be proposed
     * @param _propNewZapAddress address for new proposed Zap
     */
    function proposeFork(address _propNewZapAddress) external {
        zap.proposeFork(_propNewZapAddress);
    }

    /**
     * @dev Request to retreive value from oracle based on timestamp. The tip is not required to be
     * greater than 0 because there are no tokens in circulation for the initial(genesis) request
     * @param _c_sapi string API being requested be mined
     * @param _c_symbol is the zshort string symbol for the api request
     * @param _granularity is the number of decimals miners should include on the submitted value
     * @param _tip amount the requester is willing to pay to be get on queue. Miners
     * mine the onDeckQueryHash, or the api with the highest payout pool
     */
    function requestData(
        string calldata _c_sapi,
        string calldata _c_symbol,
        uint256 _granularity,
        uint256 _tip
    ) external {
        //Require at least one decimal place
        require(_granularity > 0);

        //But no more than 18 decimal places
        require(_granularity <= 1e18);

        //If it has been requested before then add the tip to it otherwise create the queryHash for it
        string memory _sapi = _c_sapi;
        string memory _symbol = _c_symbol;
        require(bytes(_sapi).length > 0);
        require(bytes(_symbol).length < 64);

        // make sure user has enough in wallet to tip
        require(balanceOf(msg.sender) >= _tip, "You do not have enough to tip.");
        // can only tip 1000 max
        require(_tip <= 1000, "Tip cannot be greater than 1000 Zap Tokens.");
        
        // require(balanceOf(address(this)) >= 1000);
        bytes32 _queryHash = keccak256(abi.encodePacked(_sapi, _granularity));

        //If this is the first time the API and granularity combination has been requested then create the API and granularity hash
        //otherwise the tip will be added to the requestId submitted
        if (zap.requestIdByQueryHash[_queryHash] == 0) {
            zap.uintVars[keccak256("requestCount")]++;
            uint256 _requestId = zap.uintVars[keccak256("requestCount")];
            zap.requestDetails[_requestId] = ZapStorage.Request({
                queryString: _sapi,
                dataSymbol: _symbol,
                queryHash: _queryHash,
                requestTimestamps: new uint256[](0)
            });
            zap.requestDetails[_requestId].apiUintVars[
                keccak256("granularity")
            ] = _granularity;
            zap.requestDetails[_requestId].apiUintVars[
                keccak256("requestQPosition")
            ] = 0;
            zap.requestDetails[_requestId].apiUintVars[
                keccak256("totalTip")
            ] = 0;
            zap.requestIdByQueryHash[_queryHash] = _requestId;

            //If the tip > 0 it tranfers the tip to this contract
            if (_tip > 0) {
                doTransfer(msg.sender, address(this), _tip);
            }
            updateOnDeck(_requestId, _tip);
            emit DataRequested(
                msg.sender,
                zap.requestDetails[_requestId].queryString,
                zap.requestDetails[_requestId].dataSymbol,
                _granularity,
                _requestId,
                _tip
            );
        }
        //Add tip to existing request id since this is not the first time the api and granularity have been requested
        else {
            addTip(zap.requestIdByQueryHash[_queryHash], _tip);
        }
    }

    /**
     * @dev Proof of work is called by the miner when they submit the solution (proof of work and value)
     * @param _nonce uint submitted by miner
     * @param _requestId the apiId being mined
     * @param _value of api query
     */
    function submitMiningSolution(
        string calldata _nonce,
        uint256 _requestId,
        uint256 _value
    ) external {
        zap.submitMiningSolution(_nonce, _requestId, _value);

        ZapStorage.Details[5] memory a = zap.currentMiners;

        address vaultAddress = zap.addressVars[keccak256('_vault')];
        require(vaultAddress != address(0));
        Vault vault = Vault(vaultAddress);

        uint256 minerReward = zap.uintVars[keccak256("currentMinerReward")];

        for (uint256 i = 0; i < 5; i++) {
            if (a[i].miner != address(0)){
                token.approve(address(this), minerReward);
                token.transferFrom(address(this), address(vault), minerReward);
                vault.deposit(a[i].miner, minerReward);
            }
        }

        zap.uintVars[keccak256("currentMinerReward")] = 0;
    }

    /**
     * @dev This function allows miners to deposit their stake.
     */
    function depositStake() external {
        // require balance is >= here before it hits NewStake()
        uint256 stakeAmount = zap.uintVars[keccak256("stakeAmount")];
        require(token.balanceOf(msg.sender) >= stakeAmount);
        zap.depositStake();

        // EXPERIMENTAL, needs to be tested
        address vaultAddress = zap.addressVars[keccak256('_vault')];
        require(vaultAddress != address(0));
        Vault vault = Vault(vaultAddress);

        token.approve(address(this), stakeAmount);
        token.transferFrom(msg.sender, vaultAddress, stakeAmount);
        vault.deposit(msg.sender, stakeAmount);
    }

    /**
     * @dev This function allows stakers to request to withdraw their stake (no longer stake)
     * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
     * can withdraw the stake
     */
    function requestStakingWithdraw() external {
        zap.requestStakingWithdraw();
    }

    /**
     * @dev This function allows users to withdraw their stake after a 7 day waiting period from request
     */
    function withdrawStake() external {
        zap.withdrawStake();

        address vaultAddress = zap.addressVars[keccak256('_vault')];
        require(vaultAddress != address(0));
        Vault vault = Vault(vaultAddress);

        token.transferFrom(
            vaultAddress,
            msg.sender,
            vault.userBalance(msg.sender)
        );
    }

    /**
     * @dev This function approves a _spender an _amount of tokens to use
     * @param _spender address
     * @param _amount amount the spender is being approved for
     * @return true if spender appproved successfully
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        return token.approve(_spender, _amount);
    }

    /**
     * @dev Allows for a transfer of tokens to _to
     * @param _to The address to send tokens to
     * @param _amount The amount of tokens to send
     * @return true if transfer is successful
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        // return zap.transfer(_to,_amount);
        uint256 previousBalance = balanceOf(msg.sender);
        updateBalanceAtNow(msg.sender, previousBalance - _amount);
        previousBalance = balanceOf(_to);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateBalanceAtNow(_to, previousBalance + _amount);
        return token.transfer(_to, _amount);
    }

    /**
     * @notice Send _amount tokens to _to from _from on the condition it
     * is approved by _from
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        // return zap.transferFrom(_from,_to,_amount);
        uint256 previousBalance = balanceOf(_from);
        updateBalanceAtNow(_from, previousBalance - _amount);
        previousBalance = balanceOf(_to);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateBalanceAtNow(_to, previousBalance + _amount);
        return token.transferFrom(_from, _to, _amount);
    }

    /**
     * @dev Getter for the current variables that include the 5 requests Id's
     * @return the challenge, 5 requestsId, difficulty and tip
     */
    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _challenge,
            uint256[5] memory _requestIds,
            uint256 _difficutly,
            uint256 _tip
        )
    {
        return zap.getNewCurrentVariables();
    }

    /**
        Migrated functions from ZapTransfer.sol
     */

    /**
     * @dev Completes POWO transfers by updating the balances on the current block number
     * @param _from address to transfer from
     * @param _to addres to transfer to
     * @param _amount to transfer
     */
    function doTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(_amount > 0);
        require(_to != address(0));
        require(allowedToTrade(_from, _amount)); //allowedToTrade checks the stakeAmount is removed from balance if the _user is staked
        uint256 previousBalance = balanceOf(_from); // actual token balance
        previousBalance = balanceOf(_to); // actual token balance
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        transferFrom(_from, _to, _amount); // do the actual transfer to ZapToken
        // token.transferFrom(_from, _to, _amount); // do the actual transfer to ZapToken
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * and removing the staked amount from their balance if they are staked
     * @param _user address of user
     * @param _amount to check if the user can spend
     * @return true if they are allowed to spend the amount being checked
     */
    function allowedToTrade(address _user, uint256 _amount)
        public
        view
        returns (bool)
    {
        // dont delete until we're production ready
        // dont delete until we're production ready
        // dont delete until we're production ready
        if (zap.stakerDetails[_user].currentStatus > 0) {
            //Removes the stakeAmount from balance if the _user is staked
            if (
                balanceOf(_user).sub(_amount) >= 0
                // .sub(zap.uintVars[keccak256('stakeAmount')]) //took this out since we're already taking the stake out of their wallet
            ) {
                return true;
            }
        } else if (balanceOf(_user).sub(_amount) >= 0) {
            return true;
        }
        // dont delete until production ready
        // dont delete until production ready
        // dont delete until production ready
    }

    /**
     * @dev Updates balance for from and to on the current block number via doTransfer
     * @param _value is the new balance
     */
    // remove checkpoints and pass in address _user to retrieve directly from storage
    function updateBalanceAtNow(address _user, uint256 _value) public {
        ZapStorage.Checkpoint[] storage checkpoints = zap.balances[_user];
        if (
            (checkpoints.length == 0) ||
            (checkpoints[checkpoints.length - 1].fromBlock < block.number)
        ) {
            ZapStorage.Checkpoint storage newCheckPoint = checkpoints[
                checkpoints.length++
            ];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            ZapStorage.Checkpoint storage oldCheckPoint = checkpoints[
                checkpoints.length - 1
            ];
            oldCheckPoint.value = uint128(_value);
        }
    }

    /**
     * @dev Getter for balance for owner on the specified _block number
     * @param _block is the block number to search the balance on
     * @return the balance at the checkpoint
     */
    function getBalanceAt(address _user, uint256 _block)
        public
        view
        returns (uint256)
    {
        ZapStorage.Checkpoint[] storage checkpoints = zap.balances[_user];
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /**
        Migrated from ZapLibrary
     */
    /**
     * @dev Add tip to Request value from oracle
     * @param _requestId being requested to be mined
     * @param _tip amount the requester is willing to pay to be get on queue. Miners
     * mine the onDeckQueryHash, or the api with the highest payout pool
     */
    function addTip(uint256 _requestId, uint256 _tip) public {
        require(_requestId > 0);
        // make sure user has enough in wallet to tip
        require(balanceOf(msg.sender) >= _tip, "You do not have enough to tip.");
        require(_tip <= 1000, "Tip cannot be greater than 1000 Zap Tokens.");

        // require(balanceOf(address(this)) >= 1000);

        // get latest block balance of ZM
        ZapStorage.Checkpoint[] storage checkpoints = zap.balances[
            address(this)
        ];
        uint256 lastestZMBal = checkpoints[checkpoints.length - 1].value;

        //If the tip > 0 transfer the tip to this contract
        if (_tip > 0) {
            doTransfer(msg.sender, address(this), _tip);
        }

        //Update the information for the request that should be mined next based on the tip submitted
        updateOnDeck(_requestId, _tip);
        emit TipAdded(
            msg.sender,
            _requestId,
            _tip,
            zap.requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        );
    }

    /**
     * @dev This function updates APIonQ and the requestQ when requestData or addTip are ran
     * @param _requestId being requested
     * @param _tip is the tip to add
     */
    function updateOnDeck(uint256 _requestId, uint256 _tip) internal {
        ZapStorage.Request storage _request = zap.requestDetails[_requestId];
        uint256 onDeckRequestId = ZapGettersLibrary.getTopRequestID(zap);
        //If the tip >0 update the tip for the requestId
        if (_tip > 0) {
            _request.apiUintVars[keccak256("totalTip")] = _request
            .apiUintVars[keccak256("totalTip")]
            .add(_tip);
        }
        //Set _payout for the submitted request
        uint256 _payout = _request.apiUintVars[keccak256("totalTip")];

        //If there is no current request being mined
        //then set the currentRequestId to the requestid of the requestData or addtip requestId submitted,
        // the totalTips to the payout/tip submitted, and issue a new mining challenge
        if (zap.uintVars[keccak256("currentRequestId")] == 0) {
            _request.apiUintVars[keccak256("totalTip")] = 0;
            zap.uintVars[keccak256("currentRequestId")] = _requestId;
            zap.uintVars[keccak256("currentTotalTips")] = _payout;
            zap.currentChallenge = keccak256(
                abi.encodePacked(
                    _payout,
                    zap.currentChallenge,
                    blockhash(block.number - 1)
                )
            ); // Save hash for next proof
            emit NewChallenge(
                zap.currentChallenge,
                zap.uintVars[keccak256("currentRequestId")],
                zap.uintVars[keccak256("difficulty")],
                zap
                    .requestDetails[zap.uintVars[keccak256("currentRequestId")]]
                    .apiUintVars[keccak256("granularity")],
                zap
                    .requestDetails[zap.uintVars[keccak256("currentRequestId")]]
                    .queryString,
                zap.uintVars[keccak256("currentTotalTips")]
            );
        } else {
            //If there is no OnDeckRequestId
            //then replace/add the requestId to be the OnDeckRequestId, queryHash and OnDeckTotalTips(current highest payout, aside from what
            //is being currently mined)
            if (
                _payout >
                zap.requestDetails[onDeckRequestId].apiUintVars[
                    keccak256("totalTip")
                ] ||
                (onDeckRequestId == 0)
            ) {
                //let everyone know the next on queue has been replaced
                emit NewRequestOnDeck(
                    _requestId,
                    _request.queryString,
                    _request.queryHash,
                    _payout
                );
            }

            //if the request is not part of the requestQ[51] array
            //then add to the requestQ[51] only if the _payout/tip is greater than the minimum(tip) in the requestQ[51] array
            if (_request.apiUintVars[keccak256("requestQPosition")] == 0) {
                uint256 _min;
                uint256 _index;
                (_min, _index) = Utilities.getMin(zap.requestQ);
                //we have to zero out the oldOne
                //if the _payout is greater than the current minimum payout in the requestQ[51] or if the minimum is zero
                //then add it to the requestQ array aand map its index information to the requestId and the apiUintvars
                if (_payout > _min || _min == 0) {
                    zap.requestQ[_index] = _payout;
                    zap
                    .requestDetails[zap.requestIdByRequestQIndex[_index]]
                    .apiUintVars[keccak256("requestQPosition")] = 0;
                    zap.requestIdByRequestQIndex[_index] = _requestId;
                    _request.apiUintVars[
                        keccak256("requestQPosition")
                    ] = _index;
                }
            }
            //else if the requestid is part of the requestQ[51] then update the tip for it
            else if (_tip > 0) {
                zap.requestQ[
                    _request.apiUintVars[keccak256("requestQPosition")]
                ] += _tip;
            }
        }
    }

    /**
     * Increase the approval of ZapMaster for the Vault
     */
    function increaseVaultApproval() public returns (bool) {
        address vaultAddress = zap.addressVars[keccak256('_vault')];
        require(vaultAddress != address(0));
        Vault vault = Vault(vaultAddress);
        return vault.increaseApproval();
    }
}

pragma solidity =0.5.16;

//Slightly modified SafeMath library - includes a min and max function, removes useless div function
library SafeMathM {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (uint256) {
        return a > b ? uint256(a) : uint256(b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

pragma solidity ^0.5.1;

/**
 * @title Zap Oracle Storage Library
 * @dev Contains all the variables/structs used by Zap
 */

// Libraries contain reusable Solidity types
library ZapStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint256 value;
        address miner;
    }

    struct Dispute {
        bytes32 hash; //unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int256 tally; //current tally of votes for - against measure
        bool executed; //is the dispute settled
        bool disputeVotePassed; //did the vote pass?
        bool isPropFork; //true for fork proposal NEW
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress; //new fork address (if fork proposal)
        mapping(bytes32 => uint256) disputeUintVars;
        //Each of the variables below is saved in the mapping disputeUintVars for each disputeID
        //e.g. ZapStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestId");//apiID of disputed value
        // uint keccak256("timestamp");//timestamp of distputed value
        // uint keccak256("value"); //the value being disputed
        // uint keccak256("minExecutionDate");//7 days from when dispute initialized
        // uint keccak256("numberOfVotes");//the number of parties who have voted on the measure
        // uint keccak256("blockNumber");// the blocknumber for which votes will be calculated from
        // uint keccak256("minerSlot"); //index in dispute array
        // uint keccak256("quorum"); //quorum for dispute vote NEW
        // uint keccak256("fee"); //fee paid corresponding to dispute
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }

    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute
        uint256 startDate; //stake start date
    }

    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }

    struct Request {
        string queryString; //id to string api
        string dataSymbol; //short name for api request
        bytes32 queryHash; //hash of api string and granularity e.g. keccak256(abi.encodePacked(_sapi,_granularity))
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        //Each of the variables below is saved in the mapping apiUintVars for each api request
        //e.g. requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        //These are the variables saved in this mapping:
        // uint keccak256("granularity"); //multiplier for miners
        // uint keccak256("requestQPosition"); //index in requestQ
        // uint keccak256("totalTip");//bonus portion of payout
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        mapping(uint256 => uint256) finalValues; //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    struct ZapStorageStruct {
        bytes32 currentChallenge; //current challenge to be solved
        uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
        uint256[] newValueTimestamps; //array of all timestamps requested
        Details[5] currentMiners; //This struct is for organizing the five mined values to find the median
        mapping(bytes32 => address) addressVars;
        //Address fields in the Zap contract are saved the addressVars mapping
        //e.g. addressVars[keccak256("zapContract")] = address
        //These are the variables saved in this mapping:
        // address keccak256("zapContract");//Zap address
        // address  keccak256("zapTokenContract");//ZapToken address
        // address  keccak256("_owner");//Zap Owner address
        // address  keccak256("_deity");//Zap Owner that can do things at will
        // address  keccak256("_vault");//Address of the vault contract set in Zap.sol
        mapping(bytes32 => uint256) uintVars;
        //uint fields in the Zap contract are saved the uintVars mapping
        //e.g. uintVars[keccak256("decimals")] = uint
        //These are the variables saved in this mapping:
        // keccak256("decimals");    //18 decimal standard ERC20
        // keccak256("disputeFee");//cost to dispute a mined value
        // keccak256("disputeCount");//totalHistoricalDisputes
        // keccak256("total_supply"); //total_supply of the token in circulation
        // keccak256("stakeAmount");//stakeAmount for miners (we can cut gas if we just hardcode it in...or should it be variable?)
        // keccak256("stakerCount"); //number of parties currently staked
        // keccak256("timeOfLastNewValue"); // time of last challenge solved
        // keccak256("difficulty"); // Difficulty of current block
        // keccak256("currentTotalTips"); //value of highest api/timestamp PayoutPool
        // keccak256("currentRequestId"); //API being mined--updates with the ApiOnQ Id
        // keccak256("requestCount"); // total number of requests through the system
        // keccak256("slotProgress");//Number of miners who have mined this value so far
        // keccak256("miningReward");//Mining Reward in PoWo tokens given to all miners per value
        // keccak256("timeTarget"); //The time between blocks (mined Oracle values)
        // keccak256("currentMinerReward"); //The last reward given to miners on creation of a new block
        mapping(bytes32 => mapping(address => bool)) minersByChallenge; //This is a boolean that tells you if a given challenge has been completed by a given miner
        mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
        mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
        mapping(uint256 => Dispute) disputesById; //disputeId=> Dispute details
        mapping(address => Checkpoint[]) balances; //balances of a party given blocks
        mapping(address => mapping(address => uint256)) allowed; //allowance for a given party and approver
        mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
        mapping(uint256 => Request) requestDetails; //mapping of apiID to details
        mapping(bytes32 => uint256) requestIdByQueryHash; // api bytes32 gets an id = to count of requests array
        mapping(bytes32 => uint256) disputeIdByDisputeHash; //maps a hash to an ID for each dispute
    }
}

pragma solidity =0.5.16;

import './ZapStorage.sol';
import './ZapTransfer.sol';

/**
 * @title Zap Dispute
 * @dev Contais the methods related to disputes. Zap.sol references this library for function's logic.
 */

library ZapDispute {
    using SafeMathM for uint256;

    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    ); //emitted when a new dispute is initialized
    event Voted(
        uint256 indexed _disputeID,
        bool _position,
        address indexed _voter
    ); //emitted when a new vote happens
    event DisputeVoteTallied(
        uint256 indexed _disputeID,
        int256 _result,
        address indexed _reportedMiner,
        address _reportingParty,
        bool _active
    ); //emitted upon dispute tally
    event NewZapAddress(address _newZap); //emmited when a proposed fork is voted true

    /*Functions*/

    /**
     * @dev Allows token holders to vote
     * @param _disputeId is the dispute id
     * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
     */
    function vote(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId,
        bool _supportsDispute
    ) public {
        ZapStorage.Dispute storage disp = self.disputesById[_disputeId];

        //Get the voteWeight or the balance of the user at the time/blockNumber the disupte began
        uint256 voteWeight = ZapTransfer.balanceOfAt(
            self,
            msg.sender,
            disp.disputeUintVars[keccak256('blockNumber')]
        );

        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true);

        //Requre that the user had a balance >0 at time/blockNumber the disupte began
        require(voteWeight > 0);

        //ensures miners that are under dispute cannot vote
        require(self.stakerDetails[msg.sender].currentStatus != 3);

        //Update user voting status to true
        disp.voted[msg.sender] = true;

        //Update the number of votes for the dispute
        disp.disputeUintVars[keccak256('numberOfVotes')] += 1;

        //Update the quorum by adding the voteWeight
        disp.disputeUintVars[keccak256('quorum')] += voteWeight;

        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        //otherwise decrease it
        if (_supportsDispute) {
            disp.tally = disp.tally + int256(voteWeight);
        } else {
            disp.tally = disp.tally - int256(voteWeight);
        }

        //Let the network know the user has voted on the dispute and their casted vote
        emit Voted(_disputeId, _supportsDispute, msg.sender);
    }

    /**
     * @dev tallies the votes.
     * @param _disputeId is the dispute id
     */
    function tallyVotes(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId
    ) public returns (address _from, address _to, uint _disputeFee) {

        ZapStorage.Dispute storage disp = self.disputesById[_disputeId];
        ZapStorage.Request storage _request = self.requestDetails[
            disp.disputeUintVars[keccak256('requestId')]
        ];

        
        uint disputeFeeForDisputeId = disp.disputeUintVars[keccak256("fee")];
        address disputeFeeWinnerAddress;
        
        //Ensure this has not already been executed/tallied
        require(disp.executed == false);

        //Ensure the time for voting has elapsed
        require(now > disp.disputeUintVars[keccak256('minExecutionDate')]);

        //If the vote is not a proposed fork
        if (disp.isPropFork == false) {
            ZapStorage.StakeInfo storage stakes = self.stakerDetails[
                disp.reportedMiner
            ];
            //If the vote for disputing a value is succesful(disp.tally >0) then unstake the reported
            // miner and transfer the stakeAmount and dispute fee to the reporting party
            if (disp.tally > 0) {
                //Changing the currentStatus and startDate unstakes the reported miner and allows for the
                //transfer of the stakeAmount
                stakes.currentStatus = 0;
                stakes.startDate = now - (now % 86400);

                //Decreases the stakerCount since the miner's stake is being slashed
                self.uintVars[keccak256('stakerCount')]--;
                updateDisputeFee(self);

                //Transfers the StakeAmount from the reported miner to the reporting party
                ZapTransfer.doTransfer(
                    self,
                    disp.reportedMiner,
                    disp.reportingParty,
                    self.uintVars[keccak256('stakeAmount')]
                );


                //Returns the dispute fee to the reporting party
                // don't need to run this because tokens transfer will be an actual state change.
                // ZapTransfer.doTransfer(
                //     self,
                //     address(this),
                //     disp.reportingParty,
                //     disp.disputeUintVars[keccak256('fee')]
                // );
                
                //Set the dispute state to passed/true
                disp.disputeVotePassed = true;

                //If the dispute was succeful(miner found guilty) then update the timestamp value to zero
                //so that users don't use this datapoint
                if (
                    _request.inDispute[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] == true
                ) {
                    _request.finalValues[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] = 0;
                }
                

                disputeFeeWinnerAddress = disp.reportingParty;

                // return (address(this), disp.reportingParty, disputeFeeForDisputeId);

                //If the vote for disputing a value is unsuccesful then update the miner status from being on
                //dispute(currentStatus=3) to staked(currentStatus =1) and tranfer the dispute fee to the miner
            } else {
                //Update the miner's current status to staked(currentStatus = 1)
                stakes.currentStatus = 1;

                //tranfer the dispute fee to the miner
                // // token is transfer using token.transferFrom right after tallyVotes() in zap.sol
                // ZapTransfer.doTransfer(
                //     self,
                //     address(this),
                //     disp.reportedMiner,
                //     disp.disputeUintVars[keccak256('fee')]
                // );

                if (
                    _request.inDispute[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] == true
                ) {
                    _request.inDispute[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] = false;
                }
                
                disputeFeeWinnerAddress = disp.reportedMiner;

                // return (address(this), disp.reportedMiner, disputeFeeForDisputeId);

            }
            //If the vote is for a proposed fork require a 20% quorum before exceduting the update to the new zap contract address
        } else {
            if (disp.tally > 0) {
                require(
                    disp.disputeUintVars[keccak256('quorum')] >
                        ((self.uintVars[keccak256('total_supply')] * 20) / 100)
                );
                self.addressVars[keccak256('zapContract')] = disp
                .proposedForkAddress;
                disp.disputeVotePassed = true;
                emit NewZapAddress(disp.proposedForkAddress);
            }
        }

        //update the dispute status to executed
        disp.executed = true;
        emit DisputeVoteTallied(
            _disputeId,
            disp.tally,
            disp.reportedMiner,
            disp.reportingParty,
            disp.disputeVotePassed
        );
        return (address(this), disputeFeeWinnerAddress, disputeFeeForDisputeId);
    }

    /**
     * @dev Allows for a fork to be proposed
     * @param _propNewZapAddress address for new proposed Zap
     */
    function proposeFork(
        ZapStorage.ZapStorageStruct storage self,
        address _propNewZapAddress
    ) public {
        bytes32 _hash = keccak256(abi.encodePacked(_propNewZapAddress));
        require(self.disputeIdByDisputeHash[_hash] == 0);
        ZapTransfer.doTransfer(
            self,
            msg.sender,
            address(this),
            self.uintVars[keccak256('disputeFee')]
        ); //This is the fork fee
        self.uintVars[keccak256('disputeCount')]++;
        uint256 disputeId = self.uintVars[keccak256('disputeCount')];
        self.disputeIdByDisputeHash[_hash] = disputeId;
        self.disputesById[disputeId] = ZapStorage.Dispute({
            hash: _hash,
            isPropFork: true,
            reportedMiner: msg.sender,
            reportingParty: msg.sender,
            proposedForkAddress: _propNewZapAddress,
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });
        self.disputesById[disputeId].disputeUintVars[
            keccak256('blockNumber')
        ] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256('fee')] = self
        .uintVars[keccak256('disputeFee')];
        self.disputesById[disputeId].disputeUintVars[
            keccak256('minExecutionDate')
        ] = now + 7 days;
    }

    /**
     * @dev this function allows the dispute fee to fluctuate based on the number of miners on the system.
     * The floor for the fee is 15.
     */
    function updateDisputeFee(ZapStorage.ZapStorageStruct storage self) public {
        //if the number of staked miners divided by the target count of staked miners is less than 1
        if (
            (self.uintVars[keccak256('stakerCount')] * 1000) /
                self.uintVars[keccak256('targetMiners')] <
            1000
        ) {
            //Set the dispute fee at stakeAmt * (1- stakerCount/targetMiners)
            //or at the its minimum of 15
            self.uintVars[keccak256('disputeFee')] = SafeMathM.max(
                15,
                self.uintVars[keccak256('stakeAmount')].mul(
                    1000 -
                        (self.uintVars[keccak256('stakerCount')] * 1000) /
                        self.uintVars[keccak256('targetMiners')]
                ) / 1000
            );
        } else {
            //otherwise set the dispute fee at 15 (the floor/minimum fee allowed)
            self.uintVars[keccak256('disputeFee')] = 15;
        }
    }
}

pragma solidity =0.5.16;

import "./ZapStorage.sol";
import "./ZapTransfer.sol";
import "./ZapDispute.sol";
// import "hardhat/console.sol";

/**
* @title Zap Dispute
* @dev Contais the methods related to miners staking and unstaking. Zap.sol 
* references this library for function's logic.
*/

library ZapStake {
    event NewStake(address indexed _sender);//Emits upon new staker
    event StakeWithdrawn(address indexed _sender);//Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender);//Emits when a staker begins the 7 day withdraw period

    /*Functions*/
    
    /**
    * @dev This function stakes the five initial miners, sets the supply and all the constant variables.
    * This function is called by the constructor function on ZapMaster.sol
    */
    function init(ZapStorage.ZapStorageStruct storage self) public{
        require(self.uintVars[keccak256("decimals")] == 0);
        //Give this contract 10000000 Zap Token as the starting balance within Zap-Miner

        ZapTransfer.updateBalanceAtNow(self.balances[address(this)], 10000000);

        // //the initial 5 miner addresses are specfied below
        // //changed payable[5] to 6
        address payable[6] memory _initalMiners = [
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            address(0xcd3B766CCDd6AE721141F452C550Ca635964ce71),
            address(0x2546BcD3c84621e976D8185a91A922aE77ECEc30),
            address(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E),
            address(0xdD2FD4581271e230360230F9337D5c0430Bf44C0),
            address(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199)
        ];
        //Stake each of the 5 miners specified above
        for(uint i=0;i<6;i++){//6th miner to allow for dispute
            //Miner balance is set at 1000 at the block that this function is ran
            ZapTransfer.updateBalanceAtNow(self.balances[_initalMiners[i]],500000);

            newStake(self, _initalMiners[i]);
        }

        //update the total suppply
        self.uintVars[keccak256("total_supply")] += 3000000;//6th miner to allow for dispute
        //set Constants
        self.uintVars[keccak256("decimals")] = 18;
        self.uintVars[keccak256("targetMiners")] = 200;
        self.uintVars[keccak256("stakeAmount")] = 500000;
        self.uintVars[keccak256("disputeFee")] = 970;
        self.uintVars[keccak256("timeTarget")]= 600;
        self.uintVars[keccak256("timeOfLastNewValue")] = now - now  % self.uintVars[keccak256("timeTarget")];
        self.uintVars[keccak256("difficulty")] = 1;
    }


    /**
    * @dev This function allows stakers to request to withdraw their stake (no longer stake)
    * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
    * can withdraw the deposit
    */
    function requestStakingWithdraw(ZapStorage.ZapStorageStruct storage self) public {
        ZapStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require that the miner is staked
        require(stakes.currentStatus == 1);

        //Change the miner staked to locked to be withdrawStake
        stakes.currentStatus = 2;

        //Change the startDate to now since the lock up period begins now
        //and the miner can only withdraw 7 days later from now(check the withdraw function)
        stakes.startDate = now -(now % 86400);

        //Reduce the staker count
        self.uintVars[keccak256("stakerCount")] -= 1;
        ZapDispute.updateDisputeFee(self);
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
    * @dev This function allows users to withdraw their stake after a 7 day waiting period from request 
    */
    function withdrawStake(ZapStorage.ZapStorageStruct storage self) public {
        ZapStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have 
        //passed by since they locked for withdraw
        require(now - (now % 86400) - stakes.startDate >= 7 days, "Can't withdraw yet. Need to wait at LEAST 7 days from stake start date.");
        require(stakes.currentStatus == 2);
        stakes.currentStatus = 0;

        /*
            NOT TOTALLY SURE OF THESE FUNCTON NAMES.
            BUT THE LOGIC SHOULD BE SOMETHING LIKE THIS...
            // msg.sender is the staker that wants to withdraw their tokens
            previousBalance = balanceOf(msg.sender); // grab the balance of the staker
            updateBalanceAtNow(self.balancecs(msg.sender), previousBalance) // update 
            tranferFrom(vault, msg.sender);
            
            // updates the storage portion that keeps track of balances at a block. set it to 0 since staker is unstaking
            updateBalanceAtNow(self.balancecs(msg.sender), 0) 
        */
        emit StakeWithdrawn(msg.sender);
    }

    /**
    * @dev This function allows miners to deposit their stake.
    */
    function depositStake(ZapStorage.ZapStorageStruct storage self) public {
      newStake(self, msg.sender);
      //self adjusting disputeFee
      ZapDispute.updateDisputeFee(self);
    }

    /**
    * @dev This function is used by the init function to succesfully stake the initial 5 miners.
    * The function updates their status/state and status start date so they are locked it so they can't withdraw
    * and updates the number of stakers in the system.
    */
    function newStake(ZapStorage.ZapStorageStruct storage self, address staker) internal {
        // require(ZapTransfer.balanceOf(self,staker) >= self.uintVars[keccak256("stakeAmount")]);
        //Ensure they can only stake if they are not currrently staked or if their stake time frame has ended
        //and they are currently locked for witdhraw
        require(self.stakerDetails[staker].currentStatus == 0 || self.stakerDetails[staker].currentStatus == 2);
        self.uintVars[keccak256("stakerCount")] += 1;
        self.stakerDetails[staker] = ZapStorage.StakeInfo({
            currentStatus: 1,
            //this resets their stake start date to today
            startDate: now - (now % 86400)
        });
        // self.uintVars[keccak256("stakeAmount")]
        ZapTransfer.updateBalanceAtNow(self.balances[staker], self.uintVars[keccak256("stakeAmount")]);

        emit NewStake(staker);
    }

     /**
    * @dev Getter function for the requestId being mined 
    * @return variables for the current minin event: Challenge, 5 RequestId, difficulty and Totaltips
    */
    function getNewCurrentVariables(ZapStorage.ZapStorageStruct storage self) internal view returns(bytes32 _challenge,uint[5] memory _requestIds,uint256 _difficulty, uint256 _tip){
        for(uint i=0;i<5;i++){
            _requestIds[i] =  self.currentMiners[i].value;
        }
        return (self.currentChallenge,_requestIds,self.uintVars[keccak256("difficulty")],self.uintVars[keccak256("currentTotalTips")]);
    }
}

pragma solidity =0.5.16;

import './SafeMathM.sol';
import './Utilities.sol';
import './ZapStorage.sol';
import './ZapTransfer.sol';
import './ZapDispute.sol';
import './ZapStake.sol';
import './ZapGettersLibrary.sol';

/**
 * @title Zap Oracle System Library
 * @dev Contains the functions' logic for the Zap contract where miners can submit the proof of work
 * along with the value and smart contracts can requestData and tip miners.
 */
library ZapLibrary {
    using SafeMathM for uint256;

    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip,
        uint256 _totalTips
    );
    event DataRequested(
        address indexed _sender,
        string _query,
        string _querySymbol,
        uint256 _granularity,
        uint256 indexed _requestId,
        uint256 _totalTips
    ); //Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event NewChallenge(
        bytes32 _currentChallenge,
        uint256 indexed _currentRequestId,
        uint256 _difficulty,
        uint256 _multiplier,
        string _query,
        uint256 _totalTips
    ); //emits when a new challenge is created (either on mined block or when a new request is pushed forward on waiting system)
    event NewRequestOnDeck(
        uint256 indexed _requestId,
        string _query,
        bytes32 _onDeckQueryHash,
        uint256 _onDeckTotalTips
    ); //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request
    event NewValue(
        uint256 indexed _requestId,
        uint256 _time,
        uint256 _value,
        uint256 _totalTips,
        bytes32 _currentChallenge
    ); //Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event NonceSubmitted(
        address indexed _miner,
        string _nonce,
        uint256 indexed _requestId,
        uint256 _value,
        bytes32 _currentChallenge
    ); //Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event OwnershipTransferred(
        address indexed _previousOwner,
        address indexed _newOwner
    );

    /*Functions*/

    /**
     * @dev This fucntion is called by submitMiningSolution and adjusts the difficulty, sorts and stores the first
     * 5 values received, pays the miners, the dev share and assigns a new challenge
     * @param _nonce or solution for the PoW  for the requestId
     * @param _requestId for the current request being mined
     */
    function newBlock(
        ZapStorage.ZapStorageStruct storage self,
        string memory _nonce,
        uint256 _requestId
    ) internal {
        ZapStorage.Request storage _request = self.requestDetails[_requestId];

        // If the difference between the timeTarget and how long it takes to solve the challenge this updates the challenge
        //difficulty up or donw by the difference between the target time and how long it took to solve the prevous challenge
        //otherwise it sets it to 1
        int256 _newDiff = int256(self.uintVars[keccak256('difficulty')]) +
            (int256(self.uintVars[keccak256('difficulty')]) *
                (int256(self.uintVars[keccak256('timeTarget')]) -
                    int256(
                        now - self.uintVars[keccak256('timeOfLastNewValue')]
                    ))) /
            100;
        if (_newDiff <= 0) {
            self.uintVars[keccak256('difficulty')] = 1;
        } else {
            self.uintVars[keccak256('difficulty')] = uint256(_newDiff);
        }

        //Sets time of value submission rounded to 1 minute
        self.uintVars[keccak256('timeOfLastNewValue')] =
            now -
            (now % 1 minutes);

        //The sorting algorithm that sorts the values of the first five values that come in
        ZapStorage.Details[5] memory a = self.currentMiners;
        uint256 i;
        for (i = 1; i < 5; i++) {
            uint256 temp = a[i].value;
            address temp2 = a[i].miner;
            uint256 j = i;
            while (j > 0 && temp < a[j - 1].value) {
                a[j].value = a[j - 1].value;
                a[j].miner = a[j - 1].miner;
                j--;
            }
            if (j < i) {
                a[j].value = temp;
                a[j].miner = temp2;
            }
        }

        //Pay the miners
        if (self.uintVars[keccak256('currentReward')] == 0) {
            self.uintVars[keccak256('currentReward')] = 6e18;
        }
        if (self.uintVars[keccak256('currentReward')] > 1e18) {
            self.uintVars[keccak256('currentReward')] =
                self.uintVars[keccak256('currentReward')] -
                (self.uintVars[keccak256('currentReward')] * 30612633181126) /
                1e18;
            self.uintVars[keccak256('devShare')] =
                ((self.uintVars[keccak256('currentReward')] / 1e18) * 50) /
                100;
        } else {
            self.uintVars[keccak256('currentReward')] = 1e18;
        }

        uint256 baseReward = self.uintVars[keccak256('currentReward')] / 1e18;
        self.uintVars[keccak256('currentMinerReward')] =
            baseReward +
            self.uintVars[keccak256('currentTotalTips')] /
            5;

        // for (i = 0; i < 5; i++) {
        //     ZapTransfer.doTransfer(
        //         self,
        //         address(this),
        //         a[i].miner,
        //         baseReward + self.uintVars[keccak256('currentTotalTips')] / 5
        //     );
        // }
        emit NewValue(
            _requestId,
            self.uintVars[keccak256('timeOfLastNewValue')],
            a[2].value,
            self.uintVars[keccak256('currentTotalTips')] -
                (self.uintVars[keccak256('currentTotalTips')] % 5),
            self.currentChallenge
        );

        //update the total supply
        // self.uintVars[keccak256("total_supply")] +=  self.uintVars[keccak256("devShare")] + self.uintVars[keccak256("currentReward")]*5 - (self.uintVars[keccak256("currentTotalTips")]);
        self.uintVars[keccak256('total_supply')] += 275;

        //pay the dev-share
        ZapTransfer.doTransfer(
            self,
            address(this),
            self.addressVars[keccak256('_owner')],
            self.uintVars[keccak256('devShare')]
        ); //The ten there is the devshare
        //Save the official(finalValue), timestamp of it, 5 miners and their submitted values for it, and its block number
        _request.finalValues[
            self.uintVars[keccak256('timeOfLastNewValue')]
        ] = a[2].value;
        _request.requestTimestamps.push(
            self.uintVars[keccak256('timeOfLastNewValue')]
        );
        //these are miners by timestamp
        _request.minersByValue[
            self.uintVars[keccak256('timeOfLastNewValue')]
        ] = [a[0].miner, a[1].miner, a[2].miner, a[3].miner, a[4].miner];
        _request.valuesByTimestamp[
            self.uintVars[keccak256('timeOfLastNewValue')]
        ] = [a[0].value, a[1].value, a[2].value, a[3].value, a[4].value];
        _request.minedBlockNum[
            self.uintVars[keccak256('timeOfLastNewValue')]
        ] = block.number;
        //map the timeOfLastValue to the requestId that was just mined

        self.requestIdByTimestamp[
            self.uintVars[keccak256('timeOfLastNewValue')]
        ] = _requestId;
        //add timeOfLastValue to the newValueTimestamps array
        self.newValueTimestamps.push(
            self.uintVars[keccak256('timeOfLastNewValue')]
        );
        //re-start the count for the slot progress to zero before the new request mining starts
        self.uintVars[keccak256('slotProgress')] = 0;
        self.uintVars[keccak256('currentRequestId')] = ZapGettersLibrary
        .getTopRequestID(self);
        //if the currentRequestId is not zero(currentRequestId exists/something is being mined) select the requestId with the hightest payout
        //else wait for a new tip to mine
        if (self.uintVars[keccak256('currentRequestId')] > 0) {
            //Update the current request to be mined to the requestID with the highest payout
            self.uintVars[keccak256('currentTotalTips')] = self
            .requestDetails[self.uintVars[keccak256('currentRequestId')]]
            .apiUintVars[keccak256('totalTip')];
            //Remove the currentRequestId/onDeckRequestId from the requestQ array containing the rest of the 50 requests
            self.requestQ[
                self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .apiUintVars[keccak256('requestQPosition')]
            ] = 0;

            //unmap the currentRequestId/onDeckRequestId from the requestIdByRequestQIndex
            self.requestIdByRequestQIndex[
                self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .apiUintVars[keccak256('requestQPosition')]
            ] = 0;

            //Remove the requestQposition for the currentRequestId/onDeckRequestId since it will be mined next
            self
            .requestDetails[self.uintVars[keccak256('currentRequestId')]]
            .apiUintVars[keccak256('requestQPosition')] = 0;

            //Reset the requestId TotalTip to 0 for the currentRequestId/onDeckRequestId since it will be mined next
            //and the tip is going to the current timestamp miners. The tip for the API needs to be reset to zero
            self
            .requestDetails[self.uintVars[keccak256('currentRequestId')]]
            .apiUintVars[keccak256('totalTip')] = 0;

            //gets the max tip in the in the requestQ[51] array and its index within the array??
            uint256 newRequestId = ZapGettersLibrary.getTopRequestID(self);
            //Issue the the next challenge
            self.currentChallenge = keccak256(
                abi.encodePacked(
                    _nonce,
                    self.currentChallenge,
                    blockhash(block.number - 1)
                )
            ); // Save hash for next proof
            emit NewChallenge(
                self.currentChallenge,
                self.uintVars[keccak256('currentRequestId')],
                self.uintVars[keccak256('difficulty')],
                self
                    .requestDetails[
                    self.uintVars[keccak256('currentRequestId')]
                ]
                    .apiUintVars[keccak256('granularity')],
                self
                    .requestDetails[
                    self.uintVars[keccak256('currentRequestId')]
                ]
                    .queryString,
                self.uintVars[keccak256('currentTotalTips')]
            );
            emit NewRequestOnDeck(
                newRequestId,
                self.requestDetails[newRequestId].queryString,
                self.requestDetails[newRequestId].queryHash,
                self.requestDetails[newRequestId].apiUintVars[
                    keccak256('totalTip')
                ]
            );
        } else {
            self.uintVars[keccak256('currentTotalTips')] = 0;
            self.currentChallenge = '';
        }
    }

    /**
     * @dev Proof of work is called by the miner when they submit the solution (proof of work and value)
     * @param _nonce uint submitted by miner
     * @param _requestId the apiId being mined
     * @param _value of api query
     */
    function submitMiningSolution(
        ZapStorage.ZapStorageStruct storage self,
        string memory _nonce,
        uint256 _requestId,
        uint256 _value
    ) public {
        //requre miner is staked
        require(self.stakerDetails[msg.sender].currentStatus == 1);

        //Check the miner is submitting the pow for the current request Id
        require(_requestId == self.uintVars[keccak256('currentRequestId')]);

        //Saving the challenge information as unique by using the msg.sender
        require(
            uint256(
                sha256(
                    abi.encodePacked(
                        ripemd160(
                            abi.encodePacked(
                                keccak256(
                                    abi.encodePacked(
                                        self.currentChallenge,
                                        msg.sender,
                                        _nonce
                                    )
                                )
                            )
                        )
                    )
                )
            ) %
                self.uintVars[keccak256('difficulty')] ==
                0
        );

        //Make sure the miner does not submit a value more than once
        require(
            self.minersByChallenge[self.currentChallenge][msg.sender] == false
        );

        // Set miner reward to zero to prevent it from giving rewards before a block is mined
        self.uintVars[keccak256('currentMinerReward')] = 0;

        //Save the miner and value received
        self
        .currentMiners[self.uintVars[keccak256('slotProgress')]]
        .value = _value;
        self.currentMiners[self.uintVars[keccak256('slotProgress')]].miner = msg
        .sender;

        //Add to the count how many values have been submitted, since only 5 are taken per request
        self.uintVars[keccak256('slotProgress')]++;

        //Update the miner status to true once they submit a value so they don't submit more than once
        self.minersByChallenge[self.currentChallenge][msg.sender] = true;

        emit NonceSubmitted(
            msg.sender,
            _nonce,
            _requestId,
            _value,
            self.currentChallenge
        );

        //If 5 values have been received, adjust the difficulty otherwise sort the values until 5 are received
        if (self.uintVars[keccak256('slotProgress')] == 5) {
            newBlock(self, _nonce, _requestId);
        }
    }
}

pragma solidity =0.5.16;

import './SafeMathM.sol';
import './ZapStorage.sol';

/**
 * @title Zap Transfer
 * @dev Contais the methods related to transfers and ERC20. Zap.sol and ZapGetters.sol
 * reference this library for function's logic.
 */
library ZapTransfer {
    using SafeMathM for uint256;

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); //ERC20 Approval event

    /*Functions*/

    /**
     * @param _user address of party with the balance
     * @param _spender address of spender of parties said balance
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(
        ZapStorage.ZapStorageStruct storage self,
        address _user,
        address _spender
    ) public view returns (uint256) {
        return self.allowed[_user][_spender];
    }

    /**
     * @dev Completes POWO transfers by updating the balances on the current block number
     * @param _from address to transfer from
     * @param _to addres to transfer to
     * @param _amount to transfer
     */
    function doTransfer(
        ZapStorage.ZapStorageStruct storage self,
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(_amount > 0);
        require(_to != address(0));
        require(allowedToTrade(self, _from, _amount)); //allowedToTrade checks the stakeAmount is removed from balance if the _user is staked
        uint256 previousBalance = balanceOfAt(self, _from, block.number);
        updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        previousBalance = balanceOfAt(self, _to, block.number);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
        previousBalance = balanceOfAt(self, _to, block.number);
    }

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber specified
     */
    function balanceOfAt(
        ZapStorage.ZapStorageStruct storage self,
        address _user,
        uint256 _blockNumber
    ) public view returns (uint256) {
        if (
            (self.balances[_user].length == 0) ||
            (self.balances[_user][0].fromBlock > _blockNumber)
        ) {
            return 0;
        } else {
            return getBalanceAt(self.balances[_user], _blockNumber);
        }
    }

    /**
     * @dev Getter for balance for owner on the specified _block number
     * @param checkpoints gets the mapping for the balances[owner]
     * @param _block is the block number to search the balance on
     * @return the balance at the checkpoint
     */
    function getBalanceAt(
        ZapStorage.Checkpoint[] storage checkpoints,
        uint256 _block
    ) public view returns (uint256) {
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * and removing the staked amount from their balance if they are staked
     * @param _user address of user
     * @param _amount to check if the user can spend
     * @return true if they are allowed to spend the amount being checked
     */
    function allowedToTrade(
        ZapStorage.ZapStorageStruct storage self,
        address _user,
        uint256 _amount
    ) public view returns (bool) {
        if (self.stakerDetails[_user].currentStatus > 0) {
            //Removes the stakeAmount from balance if the _user is staked
            if (
                balanceOfAt(self, _user, block.number).sub(_amount) >= 0
            ) {
                return true;
            }
        } else if (balanceOfAt(self, _user, block.number).sub(_amount) >= 0) {
            return true;
        }
        return false;
    }

    /**
     * @dev Updates balance for from and to on the current block number via doTransfer
     * @param checkpoints gets the mapping for the balances[owner]
     * @param _value is the new balance
     */
    function updateBalanceAtNow(
        ZapStorage.Checkpoint[] storage checkpoints,
        uint256 _value
    ) public {
        if (
            (checkpoints.length == 0) ||
            (checkpoints[checkpoints.length - 1].fromBlock < block.number)
        ) {
            ZapStorage.Checkpoint storage newCheckPoint = checkpoints[
                checkpoints.length++
            ];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            ZapStorage.Checkpoint storage oldCheckPoint = checkpoints[
                checkpoints.length - 1
            ];
            oldCheckPoint.value = uint128(_value);
        }
    }
}

pragma solidity =0.5.16;



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        // assert(b > 0); // Solidity automatically throws when dividing by 0

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;

    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(b <= a);

        return a - b;

    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }

}



 contract ERC20Basic {

    uint256 public totalSupply = 100000000000000000000000000;

    function balanceOf(address who)  public view returns (uint256);

    function transfer(address to, uint256 value)  public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}



/**

 * @title ERC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

 contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender)  public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)  public returns (bool);

    function approve(address spender, uint256 value)  public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**

    * @dev transfer token for a specified address

    * @param _to The address to transfer to.

    * @param _value The amount to be transferred.

    */

    function transfer(address _to, uint256 _value)  public returns (bool) {

        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.

        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;

    }

    /**

    * @dev Gets the balance of the specified address.

    * @param _owner The address to query the the balance of.

    * @return balance : An uint256 representing the amount owned by the passed address.

    */

    function balanceOf(address _owner)  public view returns (uint256 balance) {

        return balances[_owner];

    }

}

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public { owner = msg.sender; }

    function getOwner() external view returns (address) {
        return owner;
    }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StandardToken is ERC20, BasicToken {

    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) allowed;

    /**

     * @dev Transfer tokens from one address to another

     * @param _from address The address which you want to send tokens from

     * @param _to address The address which you want to transfer to

     * @param _value uint256 the amount of tokens to be transferred

     */

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {

        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met

        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        emit Transfer(_from, _to, _value);

        return true;

    }

    /**

     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.

     *

     * Beware that changing an allowance with this method brings the risk that someone may use both the old

     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this

     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:

     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

     * @param _spender The address which will spend the funds.

     * @param _value The amount of tokens to be spent.

     */

    function approve(address _spender, uint256 _value)  public returns (bool) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    /**

     * @dev Function to check the amount of tokens that an owner allowed to a spender.

     * @param _owner address The address which owns the funds.

     * @param _spender address The address which will spend the funds.

     * @return remaining A uint256 specifying the amount of tokens still available for the spender.

     */

    function allowance(address _owner, address _spender)  public view returns (uint256 remaining) {

        return allowed[_owner][_spender];

    }

    /**

     * approve should be called when allowed[_spender] == 0. To increment

     * allowed value is better to use this function to avoid 2 calls (and wait until

     * the first transaction is mined)

     * From MonolithDAO Token.sol

     */

    function increaseApproval (address _spender, uint _addedValue) public

        returns (bool success) {

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

    function decreaseApproval (address _spender, uint _subtractedValue) public

        returns (bool success) {

        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {

            allowed[msg.sender][_spender] = 0;

        } else {

            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

}



contract MintableToken is StandardToken, Ownable {

    using SafeMath for uint256;

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {

        require(!mintingFinished);

        _;

    }



    /**

     * @dev Function to mint tokens

     * @param _to The address that will receive the minted tokens.

     * @param _amount The amount of tokens to mint.

     * @return A boolean that indicates if the operation was successful.

     */

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {

        totalSupply = totalSupply.add(_amount);

        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);

        emit Transfer(address(0), _to, _amount);

        return true;

    }



    /**

     * @dev Function to stop minting new tokens.

     * @return True if the operation was successful.

     */

    function finishMinting() onlyOwner public returns (bool) {

        mintingFinished = true;

        emit MintFinished();

        return true;

    }

}



contract ZapTokenBSC is MintableToken {

    string public name = "Zap BEP20";

    string public symbol = "ZAPB";

    uint8 public decimals = 18;

    constructor() public {
        balances[msg.sender] = totalSupply;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function allocate(address to, uint amount) public{

        mint(to,amount);

    }

}

pragma solidity =0.5.16;

import './libraries/SafeMathM.sol';
import './ZapMaster.sol';

contract Vault {
    using SafeMathM for uint256;

    address public zapToken;
    ZapMaster zapMaster;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => bool)) keys;

    uint256 constant MAX_INT = 2**256 - 1;

    constructor (address token, address master) public {
        zapToken = token;
        zapMaster = ZapMaster(address(uint160(master)));
        
        token.call(abi.encodeWithSignature("approve(address,uint256)", master, MAX_INT));
    }

    function increaseApproval() public returns (bool) {
        (bool s, bytes memory balance) = zapToken.call(abi.encodeWithSignature("allowance(address,address)", address(this), zapMaster));
        uint256 amount = MAX_INT.sub(toUint256(balance, 0));
        (bool success, bytes memory data) = zapToken.call(abi.encodeWithSignature("increaseApproval(address,uint256)", zapMaster, amount));
        return success;
    }

    function lockSmith(address miniVault, address authorizedUser) public {
        require(msg.sender == miniVault, "You do not own this vault.");
        require(msg.sender != address(0) || miniVault != msg.sender, "The zero address can not own a vault.");

        // gives the mini-vault owner keys if they don't already have
        if (!keys[miniVault][msg.sender]){
            keys[miniVault][miniVault] = true;
        }

        keys[miniVault][authorizedUser] = true;
    }

    function hasAccess(address user, address miniVault) public view returns (bool) {
        require(msg.sender != address(0) || miniVault != msg.sender, "The zero address does not own a vault.");
        return keys[miniVault][user];
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function deposit(address userAddress, uint256 value) public {
        require(userAddress != address(0), "The zero address does not own a vault.");
        require(hasAccess(msg.sender, userAddress), "You are not authorized to access this vault.");
        balances[userAddress] = balances[userAddress].add(value);
    }

    function withdraw(address userAddress, uint256 value) public {
        require(userAddress != address(0), "The zero address does not own a vault.");
        require(hasAccess(msg.sender, userAddress), "You are not authorized to access this vault.");
        require(userBalance(userAddress) >= value, "Your balance is insufficient.");
        balances[userAddress] = balances[userAddress].sub(value);
    }

    function userBalance(address userAddress) public view returns (uint256 balance) {
        return balances[userAddress];
    }
}

pragma solidity =0.5.16;

//Functions for retrieving min and Max in 51 length array (requestQ)
//Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol

library Utilities {
    /// @dev Returns the minimum value and position in an array.
    //@note IT IGNORES THE 0 INDEX
    function getMin(uint256[51] memory arr)
        internal
        pure
        returns (uint256 min, uint256 minIndex)
    {
        assembly {
            minIndex := 50
            min := mload(add(arr, mul(minIndex, 0x20)))
            for {
                let i := 49
            } gt(i, 0) {
                i := sub(i, 1)
            } {
                let item := mload(add(arr, mul(i, 0x20)))
                if lt(item, min) {
                    min := item
                    minIndex := i
                }
            }
        }
    }

    // function getMin(uint[51] memory data) internal pure returns(uint256 minimal,uint minIndex) {
    //       minIndex = data.length - 1;
    //       minimal = data[minIndex];
    //       for(uint i = data.length-1;i > 0;i--) {
    //           if(data[i] < minimal) {
    //               minimal = data[i];
    //               minIndex = i;
    //           }
    //       }
    // }

    function getMax(uint256[51] memory arr)
        internal
        pure
        returns (uint256 max, uint256 maxIndex)
    {
        assembly {
            for {
                let i := 0
            } lt(i, 51) {
                i := add(i, 1)
            } {
                let item := mload(add(arr, mul(i, 0x20)))
                if lt(max, item) {
                    max := item
                    maxIndex := i
                }
            }
        }
    }
}

pragma solidity =0.5.16;

import './SafeMathM.sol';
import './ZapStorage.sol';
import './Utilities.sol';

/**
 * @title Zap Getters Library
 * @dev This is the getter library for all variables in the Zap Token system. ZapGetters references this
 * libary for the getters logic
 */
library ZapGettersLibrary {
    using SafeMathM for uint256;

    event NewZapAddress(address _newZap); //emmited when a proposed fork is voted true

    /*Functions*/

    //The next two functions are onlyOwner functions.  For Zap to be truly decentralized, we will need to transfer the Deity to the 0 address.
    //Only needs to be in library
    /**
     * @dev This function allows us to set a new Deity (or remove it)
     * @param _newDeity address of the new Deity of the zap system
     */
    function changeDeity(
        ZapStorage.ZapStorageStruct storage self,
        address _newDeity
    ) internal {
        require(self.addressVars[keccak256('_deity')] == msg.sender);
        self.addressVars[keccak256('_deity')] = _newDeity;
    }

    //Only needs to be in library
    /**
     * @dev This function allows the deity to upgrade the Zap System
     * @param _zapContract address of new updated ZapCore contract
     */
    function changeZapContract(
        ZapStorage.ZapStorageStruct storage self,
        address _zapContract
    ) internal {
        require(self.addressVars[keccak256('_deity')] == msg.sender);
        self.addressVars[keccak256('zapContract')] = _zapContract;
        emit NewZapAddress(_zapContract);
    }

    function changeVaultContract(
        ZapStorage.ZapStorageStruct storage self,
        address _vaultAddress
    ) internal {
        require(self.addressVars[keccak256('_owner')] == msg.sender);
        self.addressVars[keccak256('_vault')] = _vaultAddress;
    }

    /*Zap Getters*/

    /**
     * @dev This function tells you if a given challenge has been completed by a given miner
     * @param _challenge the challenge to search for
     * @param _miner address that you want to know if they solved the challenge
     * @return true if the _miner address provided solved the
     */
    function didMine(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _challenge,
        address _miner
    ) internal view returns (bool) {
        return self.minersByChallenge[_challenge][_miner];
    }

    /**
     * @dev Checks if an address voted in a dispute
     * @param _disputeId to look up
     * @param _address of voting party to look up
     * @return bool of whether or not party voted
     */
    function didVote(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId,
        address _address
    ) internal view returns (bool) {
        return self.disputesById[_disputeId].voted[_address];
    }

    /**
     * @dev allows Zap to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("zapContract")]
     */
    function getAddressVars(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _data
    ) internal view returns (address) {
        return self.addressVars[_data];
    }

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * @return bool executed where true if it has been voted on
     * @return bool disputeVotePassed
     * @return bool isPropFork true if the dispute is a proposed fork
     * @return address of reportedMiner
     * @return address of reportingParty
     * @return address of proposedForkAddress
     * @return uint of requestId
     * @return uint of timestamp
     * @return uint of value
     * @return uint of minExecutionDate
     * @return uint of numberOfVotes
     * @return uint of blocknumber
     * @return uint of minerSlot
     * @return uint of quorum
     * @return uint of fee
     * @return int count of the current tally
     */
    function getAllDisputeVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId
    )
        internal
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        )
    {
        ZapStorage.Dispute storage disp = self.disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.isPropFork,
            disp.reportedMiner,
            disp.reportingParty,
            disp.proposedForkAddress,
            [
                disp.disputeUintVars[keccak256('requestId')],
                disp.disputeUintVars[keccak256('timestamp')],
                disp.disputeUintVars[keccak256('value')],
                disp.disputeUintVars[keccak256('minExecutionDate')],
                disp.disputeUintVars[keccak256('numberOfVotes')],
                disp.disputeUintVars[keccak256('blockNumber')],
                disp.disputeUintVars[keccak256('minerSlot')],
                disp.disputeUintVars[keccak256('quorum')],
                disp.disputeUintVars[keccak256('fee')]
            ],
            disp.tally
        );
    }

    /**
     * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
     * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request
     */
    function getCurrentVariables(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (
            bytes32,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            self.currentChallenge,
            self.uintVars[keccak256('currentRequestId')],
            self.uintVars[keccak256('difficulty')],
            self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .queryString,
            self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .apiUintVars[keccak256('granularity')],
            self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .apiUintVars[keccak256('totalTip')]
        );
    }

    /**
     * @dev Checks if a given hash of miner,requestId has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _hash
    ) internal view returns (uint256) {
        return self.disputeIdByDisputeHash[_hash];
    }

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
     * @param _disputeId is the dispute id;
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the disputeUintVars under the Dispute struct
     * @return uint value for the bytes32 data submitted
     */
    function getDisputeUintVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId,
        bytes32 _data
    ) internal view returns (uint256) {
        return self.disputesById[_disputeId].disputeUintVars[_data];
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @return value for timestamp of last proof of work submited
     * @return true if the is a timestamp for the lastNewValue
     */
    function getLastNewValue(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256, bool)
    {
        return (
            retrieveData(
                self,
                self.requestIdByTimestamp[
                    self.uintVars[keccak256('timeOfLastNewValue')]
                ],
                self.uintVars[keccak256('timeOfLastNewValue')]
            ),
            true
        );
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @param _requestId being requested
     * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
     */
    function getLastNewValueById(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId
    ) internal view returns (uint256, bool) {
        ZapStorage.Request storage _request = self.requestDetails[_requestId];
        if (_request.requestTimestamps.length > 0) {
            return (
                retrieveData(
                    self,
                    _requestId,
                    _request.requestTimestamps[
                        _request.requestTimestamps.length - 1
                    ]
                ),
                true
            );
        } else {
            return (0, false);
        }
    }

    /**
     * @dev Gets blocknumber for mined timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up blocknumber
     * @return uint of the blocknumber which the dispute was mined
     */
    function getMinedBlockNum(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].minedBlockNum[_timestamp];
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return the 5 miners' addresses
     */
    function getMinersByRequestIdAndTimestamp(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (address[5] memory) {
        return self.requestDetails[_requestId].minersByValue[_timestamp];
    }

    /**
     * @dev Get the name of the token
     * @return string of the token name
     */
    function getName(ZapStorage.ZapStorageStruct storage self)
        internal
        pure
        returns (string memory)
    {
        return 'Zap BEP20';
    }

    /**
     * @dev Counts the number of values that have been submited for the request
     * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
     * request so far
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].requestTimestamps.length;
    }

    /**
     * @dev Getter function for the specified requestQ index
     * @param _index to look up in the requestQ array
     * @return uint of reqeuestId
     */
    function getRequestIdByRequestQIndex(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _index
    ) internal view returns (uint256) {
        require(_index <= 50);
        return self.requestIdByRequestQIndex[_index];
    }

    /**
     * @dev Getter function for requestId based on timestamp
     * @param _timestamp to check requestId
     * @return uint of reqeuestId
     */
    function getRequestIdByTimestamp(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _timestamp
    ) internal view returns (uint256) {
        return self.requestIdByTimestamp[_timestamp];
    }

    /**
     * @dev Getter function for requestId based on the qeuaryHash
     * @param _queryHash hash(of string api and granularity) to check if a request already exists
     * @return uint requestId
     */
    function getRequestIdByQueryHash(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _queryHash
    ) internal view returns (uint256) {
        return self.requestIdByQueryHash[_queryHash];
    }

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ arrray
     */
    function getRequestQ(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256[51] memory)
    {
        return self.requestQ;
    }

    /**
     * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
     * for the requestId specified
     * @param _requestId to look up
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the apiUintVars under the requestDetails struct
     * @return uint value of the apiUintVars specified in _data for the requestId specified
     */
    function getRequestUintVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        bytes32 _data
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].apiUintVars[_data];
    }

    /**
     * @dev Gets the API struct variables that are not mappings
     * @param _requestId to look up
     * @return string of api to query
     * @return string of symbol of api to query
     * @return bytes32 hash of string
     * @return bytes32 of the granularity(decimal places) requested
     * @return uint of index in requestQ array
     * @return uint of current payout/tip for this requestId
     */
    function getRequestVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId
    )
        internal
        view
        returns (
            string memory,
            string memory,
            bytes32,
            uint256,
            uint256,
            uint256
        )
    {
        ZapStorage.Request storage _request = self.requestDetails[_requestId];
        return (
            _request.queryString,
            _request.dataSymbol,
            _request.queryHash,
            _request.apiUintVars[keccak256('granularity')],
            _request.apiUintVars[keccak256('requestQPosition')],
            _request.apiUintVars[keccak256('totalTip')]
        );
    }

    /**
     * @dev This function allows users to retireve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(
        ZapStorage.ZapStorageStruct storage self,
        address _staker
    ) internal view returns (uint256, uint256) {
        return (
            self.stakerDetails[_staker].currentStatus,
            self.stakerDetails[_staker].startDate
        );
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestampt to look up miners for
     * @return address[5] array of 5 addresses ofminers that mined the requestId
     */
    function getSubmissionsByTimestamp(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (uint256[5] memory) {
        return self.requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }

    /**
     * @dev Get the symbol of the token
     * @return string of the token symbol
     */
    function getSymbol(ZapStorage.ZapStorageStruct storage self)
        internal
        pure
        returns (string memory)
    {
        return 'ZAPB';
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestID is the requestId to look up
     * @param _index is the value index to look up
     * @return uint timestamp
     */
    function getTimestampbyRequestIDandIndex(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestID,
        uint256 _index
    ) internal view returns (uint256) {
        return self.requestDetails[_requestID].requestTimestamps[_index];
    }

    /**
     * @dev Getter for the variables saved under the ZapStorageStruct uintVars variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the uintVars under the ZapStorageStruct struct
     * This is an example of how data is saved into the mapping within other functions:
     * self.uintVars[keccak256("stakerCount")]
     * @return uint of specified variable
     */
    function getUintVar(ZapStorage.ZapStorageStruct storage self, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.uintVars[_data];
    }

    /**
     * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
     * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
     */
    function getVariablesOnDeck(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (
            uint256,
            uint256,
            string memory
        )
    {
        uint256 newRequestId = getTopRequestID(self);
        return (
            newRequestId,
            self.requestDetails[newRequestId].apiUintVars[
                keccak256('totalTip')
            ],
            self.requestDetails[newRequestId].queryString
        );
    }

    /**
     * @dev Getter function for the request with highest payout. This function is used withing the getVariablesOnDeck function
     * @return uint _requestId of request with highest payout at the time the function is called
     */
    function getTopRequestID(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256 _requestId)
    {
        uint256 _max;
        uint256 _index;
        (_max, _index) = Utilities.getMax(self.requestQ);
        _requestId = self.requestIdByRequestQIndex[_index];
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (bool) {
        return self.requestDetails[_requestId].inDispute[_timestamp];
    }

    /**
     * @dev Retreive value from oracle based on requestId/timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return uint value for requestId/timestamp submitted
     */
    function retrieveData(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].finalValues[_timestamp];
    }

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalSupply(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256)
    {
        return self.uintVars[keccak256('total_supply')];
    }
}

pragma solidity =0.5.16;

import './ZapGetters.sol';

/**
 * @title Zap Master
 * @dev This is the Master contract with all zap getter functions and delegate call to Zap.
 * The logic for the functions on this contract is saved on the ZapGettersLibrary, ZapTransfer,
 * ZapGettersLibrary, and ZapStake
 */
contract ZapMaster is ZapGetters {
    event NewZapAddress(address _newZap);

    /**
     * @dev The constructor sets the original `zapStorageOwner` of the contract to the sender
     * account, the zap contract to the Zap master address and owner to the Zap master owner address
     * @param _zapContract is the address for the zap contract
     */
    constructor(address _zapContract, address tokenAddress)
        public
        ZapGetters(tokenAddress)
    {
        zap.init();
        zap.addressVars[keccak256('_owner')] = msg.sender;
        zap.addressVars[keccak256('_deity')] = msg.sender;
        zap.addressVars[keccak256('zapContract')] = _zapContract;
        zap.addressVars[keccak256('zapTokenContract')] = tokenAddress;

        emit NewZapAddress(_zapContract);
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @dev Only needs to be in library
     * @param _newDeity the new Deity in the contract
     */

    function changeDeity(address _newDeity) external {
        zap.changeDeity(_newDeity);
    }

    /**
     * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
     * @param _zapContract the address of the new Zap Contract
     */
    function changeZapContract(address _zapContract) external {
        zap.changeZapContract(_zapContract);
    }

    /**
     * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
     * @param _vaultContract the address of the new Vault Contract
     */
    function changeVaultContract(address _vaultContract) external {
        zap.changeVaultContract(_vaultContract);
    }

    /**
     * @dev This is the fallback function that allows contracts to call the zap contract at the address stored
     */
    function() external payable {
        address addr = zap.addressVars[keccak256('zapContract')];
        bytes memory _calldata = msg.data;
        assembly {
            let result := delegatecall(
                not(0),
                addr,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

pragma solidity =0.5.16;

import './libraries/SafeMathM.sol';
import './libraries/ZapStorage.sol';
import './libraries/ZapTransfer.sol';
import './libraries/ZapGettersLibrary.sol';
import './libraries/ZapStake.sol';
import '../token/ZapTokenBSC.sol';

/**
 * @title Zap Getters
 * @dev Oracle contract with all zap getter functions. The logic for the functions on this contract
 * is saved on the ZapGettersLibrary, ZapTransfer, ZapGettersLibrary, and ZapStake
 */
contract ZapGetters {
    using SafeMathM for uint256;

    using ZapTransfer for ZapStorage.ZapStorageStruct;
    using ZapGettersLibrary for ZapStorage.ZapStorageStruct;
    using ZapStake for ZapStorage.ZapStorageStruct;

    ZapStorage.ZapStorageStruct zap;
    ZapTokenBSC token;

    constructor(address zapTokenBsc) public {
        token = ZapTokenBSC(zapTokenBsc);
    }

    /**
     * @param _user address
     * @param _spender address
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(address _user, address _spender)
        public
        view
        returns (uint256)
    {
        //    return zap.allowance(_user,_spender);
        return token.allowance(_user, _spender);
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * @param _user address
     * @param _amount uint of amount
     * @return true if the user is alloed to trade the amount specified
     */
    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool)
    {
        return zap.allowedToTrade(_user, _amount);
    }

    /**
     * @dev Gets balance of owner specified
     * @param _user is the owner address used to look up the balance
     * @return Returns the balance associated with the passed in _user
     */
    function balanceOf(address _user) public view returns (uint256) {
        // return zap.balanceOf(_user);
        return token.balanceOf(_user);
    }

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber
     */
    // function balanceOfAt(address _user, uint _blockNumber) external view returns (uint) {
    //     return zap.balanceOfAt(_user,_blockNumber);
    // }

    /**
     * @dev This function tells you if a given challenge has been completed by a given miner
     * @param _challenge the challenge to search for
     * @param _miner address that you want to know if they solved the challenge
     * @return true if the _miner address provided solved the
     */
    function didMine(bytes32 _challenge, address _miner)
        external
        view
        returns (bool)
    {
        return zap.didMine(_challenge, _miner);
    }

    /**
     * @dev Checks if an address voted in a given dispute
     * @param _disputeId to look up
     * @param _address to look up
     * @return bool of whether or not party voted
     */
    function didVote(uint256 _disputeId, address _address)
        external
        view
        returns (bool)
    {
        return zap.didVote(_disputeId, _address);
    }

    /**
     * @dev allows Zap to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("zapContract")]
     */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return zap.getAddressVars(_data);
    }

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * @return bool executed where true if it has been voted on
     * @return bool disputeVotePassed
     * @return bool isPropFork true if the dispute is a proposed fork
     * @return address of reportedMiner
     * @return address of reportingParty
     * @return address of proposedForkAddress
     * @return uint of requestId
     * @return uint of timestamp
     * @return uint of value
     * @return uint of minExecutionDate
     * @return uint of numberOfVotes
     * @return uint of blocknumber
     * @return uint of minerSlot
     * @return uint of quorum
     * @return uint of fee
     * @return int count of the current tally
     */
    function getAllDisputeVars(uint256 _disputeId)
        public
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        )
    {
        return zap.getAllDisputeVars(_disputeId);
    }

    /**
     * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
     * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request
     */
    function getCurrentVariables()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256
        )
    {
        return zap.getCurrentVariables();
    }

    /**
     * @dev Checks if a given hash of miner,requestId has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256)
    {
        return zap.getDisputeIdByDisputeHash(_hash);
    }

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
     * @param _disputeId is the dispute id;
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the disputeUintVars under the Dispute struct
     * @return uint value for the bytes32 data submitted
     */
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256)
    {
        return zap.getDisputeUintVars(_disputeId, _data);
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @return value for timestamp of last proof of work submited
     * @return true if the is a timestamp for the lastNewValue
     */
    function getLastNewValue() external view returns (uint256, bool) {
        return zap.getLastNewValue();
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @param _requestId being requested
     * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
     */
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool)
    {
        return zap.getLastNewValueById(_requestId);
    }

    /**
     * @dev Gets blocknumber for mined timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up blocknumber
     * @return uint of the blocknumber which the dispute was mined
     */
    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return zap.getMinedBlockNum(_requestId, _timestamp);
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return the 5 miners' addresses
     */
    function getMinersByRequestIdAndTimestamp(
        uint256 _requestId,
        uint256 _timestamp
    ) external view returns (address[5] memory) {
        return zap.getMinersByRequestIdAndTimestamp(_requestId, _timestamp);
    }

    /**
     * @dev Get the name of the token
     * return string of the token name
     */
    function getName() external view returns (string memory) {
        return zap.getName();
    }

    /**
     * @dev Counts the number of values that have been submited for the request
     * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
     * request so far
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256)
    {
        return zap.getNewValueCountbyRequestId(_requestId);
    }

    /**
     * @dev Getter function for the specified requestQ index
     * @param _index to look up in the requestQ array
     * @return uint of reqeuestId
     */
    function getRequestIdByRequestQIndex(uint256 _index)
        external
        view
        returns (uint256)
    {
        return zap.getRequestIdByRequestQIndex(_index);
    }

    /**
     * @dev Getter function for requestId based on timestamp
     * @param _timestamp to check requestId
     * @return uint of reqeuestId
     */
    function getRequestIdByTimestamp(uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return zap.getRequestIdByTimestamp(_timestamp);
    }

    /**
     * @dev Getter function for requestId based on the queryHash
     * @param _request is the hash(of string api and granularity) to check if a request already exists
     * @return uint requestId
     */
    function getRequestIdByQueryHash(bytes32 _request)
        external
        view
        returns (uint256)
    {
        return zap.getRequestIdByQueryHash(_request);
    }

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ arrray
     */
    function getRequestQ() public view returns (uint256[51] memory) {
        return zap.getRequestQ();
    }

    /**
     * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
     * for the requestId specified
     * @param _requestId to look up
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the apiUintVars under the requestDetails struct
     * @return uint value of the apiUintVars specified in _data for the requestId specified
     */
    function getRequestUintVars(uint256 _requestId, bytes32 _data)
        external
        view
        returns (uint256)
    {
        return zap.getRequestUintVars(_requestId, _data);
    }

    /**
     * @dev Gets the API struct variables that are not mappings
     * @param _requestId to look up
     * @return string of api to query
     * @return string of symbol of api to query
     * @return bytes32 hash of string
     * @return bytes32 of the granularity(decimal places) requested
     * @return uint of index in requestQ array
     * @return uint of current payout/tip for this requestId
     */
    function getRequestVars(uint256 _requestId)
        external
        view
        returns (
            string memory,
            string memory,
            bytes32,
            uint256,
            uint256,
            uint256
        )
    {
        return zap.getRequestVars(_requestId);
    }

    /**
     * @dev This function allows users to retireve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        return zap.getStakerInfo(_staker);
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestampt to look up miners for
     * @return address[5] array of 5 addresses ofminers that mined the requestId
     */
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256[5] memory)
    {
        return zap.getSubmissionsByTimestamp(_requestId, _timestamp);
    }

    /**
     * @dev Get the symbol of the token
     * return string of the token symbol
     */
    function getSymbol() external view returns (string memory) {
        return zap.getSymbol();
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestID is the requestId to look up
     * @param _index is the value index to look up
     * @return uint timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index)
        external
        view
        returns (uint256)
    {
        return zap.getTimestampbyRequestIDandIndex(_requestID, _index);
    }

    /**
     * @dev Getter for the variables saved under the ZapStorageStruct uintVars variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the uintVars under the ZapStorageStruct struct
     * This is an example of how data is saved into the mapping within other functions:
     * self.uintVars[keccak256("stakerCount")]
     * @return uint of specified variable
     */
    function getUintVar(bytes32 _data) public view returns (uint256) {
        return zap.getUintVar(_data);
    }

    /**
     * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
     * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
     */
    function getVariablesOnDeck()
        external
        view
        returns (
            uint256,
            uint256,
            string memory
        )
    {
        return zap.getVariablesOnDeck();
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (bool)
    {
        return zap.isInDispute(_requestId, _timestamp);
    }

    /**
     * @dev Retreive value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return zap.retrieveData(_requestId, _timestamp);
    }

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalTokenSupply() external view returns (uint256) {
        return zap.totalSupply();
        // return token.totalSupply;
    }
}