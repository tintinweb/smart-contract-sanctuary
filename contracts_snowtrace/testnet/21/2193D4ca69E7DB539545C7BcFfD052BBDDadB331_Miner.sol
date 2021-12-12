pragma solidity 0.8.6;


import "IRegistry.sol";
import "Shared.sol";


contract Miner is Shared {

    IERC20 private _AUTO;
    IRegistry private _reg;
    uint private _AUTOPerReq;
    uint private _AUTOPerExec;
    uint private _AUTOPerReferal;
    // 1k AUTO
    uint public constant MAX_UPDATE_BAL = 1000 * _E_18;
    // 1 AUTO
    uint public constant MIN_REWARD = _E_18;
    // 10k AUTO
    uint public constant MIN_FUND = 10000 * _E_18;
    // This counts the number of executed requests that the requester
    // has mined rewards for
    mapping(address => uint) private _minedReqCounts;
    // This counts the number of executions that the executor has
    // mined rewards for
    mapping(address => uint) private _minedExecCounts;
    // This counts the number of executed requests that the requester
    // has mined rewards for
    mapping(address => uint) private _minedReferalCounts;


    event RatesUpdated(uint newAUTOPerReq, uint newAUTOPerExec, uint newAUTOPerReferal);


    constructor(
        IERC20 AUTO,
        IRegistry reg,
        uint AUTOPerReq,
        uint AUTOPerExec,
        uint AUTOPerReferal
    ) {
        _AUTO = AUTO;
        _reg = reg;
        _AUTOPerReq = AUTOPerReq;
        _AUTOPerExec = AUTOPerExec;
        _AUTOPerReferal = AUTOPerReferal;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Claiming                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function claimMiningRewards() external {
        (uint reqRewardCount, uint execRewardCount, uint referalRewardCount, uint rewards) = 
            getAvailableMiningRewards(msg.sender);
        require(rewards > 0, "Miner: no pending rewards");
        
        _minedReqCounts[msg.sender] += reqRewardCount;
        _minedExecCounts[msg.sender] += execRewardCount;
        _minedReferalCounts[msg.sender] += referalRewardCount;
        require(_AUTO.transfer(msg.sender, rewards));
    }

    function claimReqMiningReward(uint claimCount) external nzUint(claimCount) {
        _claimSpecificMiningReward(_minedReqCounts, _reg.getReqCountOf(msg.sender), claimCount, _AUTOPerReq);
    }

    function claimExecMiningReward(uint claimCount) external nzUint(claimCount) {
        _claimSpecificMiningReward(_minedExecCounts, _reg.getExecCountOf(msg.sender), claimCount, _AUTOPerExec);
    }

    function claimReferalMiningReward(uint claimCount) external nzUint(claimCount) {
        _claimSpecificMiningReward(_minedReferalCounts, _reg.getReferalCountOf(msg.sender), claimCount, _AUTOPerReferal);
    }

    function _claimSpecificMiningReward(
        mapping(address => uint) storage counter,
        uint regCount,
        uint claimCount,
        uint rate
    ) private {
        require(
            claimCount <= regCount - counter[msg.sender],
            "Miner: claim too large"
        );

        counter[msg.sender] += claimCount;
        require(_AUTO.transfer(msg.sender, claimCount * rate));
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Updating params                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function updateAndFund(
        uint newAUTOPerReq,
        uint newAUTOPerExec,
        uint newAUTOPerReferal,
        uint amountToFund
    ) external {
        require(_AUTO.balanceOf(address(this)) <= MAX_UPDATE_BAL, "Miner: AUTO bal too high");
        // So that nobody updates with a small amount of AUTO and makes the rates
        // 1 wei, effectively bricking the contract
        require(
            newAUTOPerReq >= MIN_REWARD &&
            newAUTOPerExec >= MIN_REWARD &&
            newAUTOPerReferal >= MIN_REWARD,
            "Miner: new rates too low"
        );
        require(amountToFund >= MIN_FUND, "Miner: funding too low, peasant");

        // Update rates and fund the Miner
        _AUTOPerReq = newAUTOPerReq;
        _AUTOPerExec = newAUTOPerExec;
        _AUTOPerReferal = newAUTOPerReferal;
        require(_AUTO.transferFrom(msg.sender, address(this), amountToFund));
        emit RatesUpdated(newAUTOPerReq, newAUTOPerExec, newAUTOPerReferal);
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getAUTOPerReq() external view returns (uint) {
        return _AUTOPerReq;
    }

    function getAUTOPerExec() external view returns (uint) {
        return _AUTOPerExec;
    }

    function getAUTOPerReferal() external view returns (uint) {
        return _AUTOPerReferal;
    }

    function getMinedReqCountOf(address addr) external view returns (uint) {
        return _minedReqCounts[addr];
    }

    function getMinedExecCountOf(address addr) external view returns (uint) {
        return _minedExecCounts[addr];
    }

    function getMinedReferalCountOf(address addr) external view returns (uint) {
        return _minedReferalCounts[addr];
    }

    function getAvailableMiningRewards(address addr) public view returns (uint, uint, uint, uint) {
        uint reqRewardCount = _reg.getReqCountOf(addr) - _minedReqCounts[addr];
        uint execRewardCount = _reg.getExecCountOf(addr) - _minedExecCounts[addr];
        uint referalRewardCount = _reg.getReferalCountOf(addr) - _minedReferalCounts[addr];

        uint rewards = 
            (reqRewardCount * _AUTOPerReq) +
            (execRewardCount * _AUTOPerExec) +
            (referalRewardCount * _AUTOPerReferal);
        
        return (reqRewardCount, execRewardCount, referalRewardCount, rewards);
    }
}

pragma solidity 0.8.6;


import "IERC20.sol";


/**
* @title    Registry
* @notice   A contract which is essentially a glorified forwarder.
*           It essentially brings together people who want things executed,
*           and people who want to do that execution in return for a fee.
*           Users register the details of what they want executed, which
*           should always revert unless their execution condition is true,
*           and executors execute the request when the condition is true.
*           Only a specific executor is allowed to execute requests at any
*           given time, as determined by the StakeManager, which requires
*           staking AUTO tokens. This is infrastructure, and an integral
*           piece of the future of web3. It also provides the spark of life
*           for a new form of organism - cyber life. We are the gods now.
* @author   Quantaf1re (James Key)
*/
interface IRegistry {
    
    // The address vars are 20b, total 60, calldata is 4b + n*32b usually, which
    // has a factor of 32. uint112 since the current ETH supply of ~115m can fit
    // into that and it's the highest such that 2 * uint112 + 3 * bool is < 256b
    struct Request {
        address payable user;
        address target;
        address payable referer;
        bytes callData;
        uint112 initEthSent;
        uint112 ethForCall;
        bool verifyUser;
        bool insertFeeAmount;
        bool payWithAUTO;
        bool isAlive;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Hashed Requests                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Creates a new request, logs the request info in an event, then saves
     *          a hash of it on-chain in `_hashedReqs`. Uses the default for whether
     *          to pay in ETH or AUTO
     * @param target    The contract address that needs to be called
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param ethForCall    The ETH to send with the call
     * @param verifyUser  Whether the 1st input of the calldata equals the sender.
     *                      Needed for dapps to know who the sender is whilst
     *                      ensuring that the sender intended
     *                      that fcn and contract to be called - dapps will
     *                      require that msg.sender is the Verified Forwarder,
     *                      and only requests that have `verifyUser` = true will
     *                      be forwarded via the Verified Forwarder, so any calls
     *                      coming from it are guaranteed to have the 1st argument
     *                      be the sender
     * @param insertFeeAmount     Whether the gas estimate of the executor should be inserted
     *                      into the callData
     * @param isAlive       Whether or not the request should be deleted after it's executed
     *                      for the first time. If `true`, the request will exist permanently
     *                      (tho it can be cancelled any time), therefore executing the same
     *                      request repeatedly aslong as the request is executable,
     *                      and can be used to create fully autonomous contracts - the
     *                      first single-celled cyber life. We are the gods now
     * @return id   The id of the request, equal to the index in `_hashedReqs`
     */
    function newReq(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool isAlive
    ) external payable returns (uint id);

    /**
     * @notice  Creates a new request, logs the request info in an event, then saves
     *          a hash of it on-chain in `_hashedReqs`
     * @param target    The contract address that needs to be called
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param ethForCall    The ETH to send with the call
     * @param verifyUser  Whether the 1st input of the calldata equals the sender.
     *                      Needed for dapps to know who the sender is whilst
     *                      ensuring that the sender intended
     *                      that fcn and contract to be called - dapps will
     *                      require that msg.sender is the Verified Forwarder,
     *                      and only requests that have `verifyUser` = true will
     *                      be forwarded via the Verified Forwarder, so any calls
     *                      coming from it are guaranteed to have the 1st argument
     *                      be the sender
     * @param insertFeeAmount     Whether the gas estimate of the executor should be inserted
     *                      into the callData
     * @param payWithAUTO   Whether the sender wants to pay for the request in AUTO
     *                      or ETH. Paying in AUTO reduces the fee
     * @param isAlive       Whether or not the request should be deleted after it's executed
     *                      for the first time. If `true`, the request will exist permanently
     *                      (tho it can be cancelled any time), therefore executing the same
     *                      request repeatedly aslong as the request is executable,
     *                      and can be used to create fully autonomous contracts - the
     *                      first single-celled cyber life. We are the gods now
     * @return id   The id of the request, equal to the index in `_hashedReqs`
     */
    function newReqPaySpecific(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool payWithAUTO,
        bool isAlive
    ) external payable returns (uint id);

    /**
     * @notice  Gets all keccak256 hashes of encoded requests. Completed requests will be 0x00
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqs() external view returns (bytes32[] memory);

    /**
     * @notice  Gets part of the keccak256 hashes of encoded requests. Completed requests will be 0x00.
     *          Needed since the array will quickly grow to cost more gas than the block limit to retrieve.
     *          so it can be viewed in chunks. E.g. for an array of x = [4, 5, 6, 7], x[1, 2] returns [5],
     *          the same as lists in Python
     * @param startIdx  [uint] The starting index from which to start getting the slice (inclusive)
     * @param endIdx    [uint] The ending index from which to start getting the slice (exclusive)
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqsSlice(uint startIdx, uint endIdx) external view returns (bytes32[] memory);

    /**
     * @notice  Gets the total number of requests that have been made, hashed, and stored
     * @return  [uint] The total number of hashed requests
     */
    function getHashedReqsLen() external view returns (uint);
    
    /**
     * @notice      Gets a single hashed request
     * @param id    [uint] The id of the request, which is its index in the array
     * @return      [bytes32] The sha3 hash of the request
     */
    function getHashedReq(uint id) external view returns (bytes32);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                Hashed Requests Unverified                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Creates a new hashed request by blindly storing a raw hash on-chain. It's 
     *          'unverified' because when executing it, it's impossible to tell whether any
     *          ETH was initially sent with the request etc, so executing this request requires
     *          that the request which hashes to `hashedIpfsReq` has `ethForCall` = 0,
     *          `initEthSend` = 0, `verifyUser` = false, and `payWithAUTO` = true
     * @param id    [bytes32] The hash to save. The hashing algo isn't keccak256 like with `newReq`,
     *          it instead uses sha256 so that it's compatible with ipfs - the hash stored on-chain
     *          should be able to be used in ipfs to point to the request which hashes to `hashedIpfsReq`.
     *          Because ipfs doesn't hash only the data stored, it hashes a prepends a few bytes to the
     *          encoded data and appends a few bytes to the data, the hash has to be over [prefix + data + postfix]
     * @return id   The id of the request, equal to the index in `_hashedReqsUnveri`
     */
    function newHashedReqUnveri(bytes32 hashedIpfsReq) external returns (uint id);

    /**
     * @notice  Gets part of the sha256 hashes of ipfs-encoded requests. Completed requests will be 0x00.
     *          Needed since the array will quickly grow to cost more gas than the block limit to retrieve.
     *          so it can be viewed in chunks. E.g. for an array of x = [4, 5, 6, 7], x[1, 2] returns [5],
     *          the same as lists in Python
     * @param startIdx  [uint] The starting index from which to start getting the slice (inclusive)
     * @param endIdx    [uint] The ending index from which to start getting the slice (exclusive)
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqsUnveriSlice(uint startIdx, uint endIdx) external view returns (bytes32[] memory);
    
    /**
     * @notice  Gets all sha256 hashes of ipfs-encoded requests. Completed requests will be 0x00
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqsUnveri() external view returns (bytes32[] memory);

    /**
     * @notice  Gets the total number of unverified requests that have been stored
     * @return  [uint] The total number of hashed unverified requests
     */
    function getHashedReqsUnveriLen() external view returns (uint);
    
    /**
     * @notice      Gets a single hashed unverified request
     * @param id    [uint] The id of the request, which is its index in the array
     * @return      [bytes32] The sha256 hash of the ipfs-encoded request
     */
    function getHashedReqUnveri(uint id) external view returns (bytes32);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Bytes Helpers                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice      Encode a request into bytes
     * @param r     [request] The request to be encoded
     * @return      [bytes] The bytes array of the encoded request
     */
    function getReqBytes(Request memory r) external pure returns (bytes memory);

    /**
     * @notice      Encode a request into bytes the same way ipfs does - by doing hash(prefix | request | postfix)
     * @param r     [request] The request to be encoded
     * @param dataPrefix    [bytes] The prefix that ipfs prepends to this data before hashing
     * @param dataPostfix   [bytes] The postfix that ipfs appends to this data before hashing
     * @return  [bytes] The bytes array of the encoded request
     */
    function getIpfsReqBytes(
        bytes memory r,
        bytes memory dataPrefix,
        bytes memory dataPostfix
    ) external pure returns (bytes memory);

    /**
     * @notice      Get the hash of an encoded request, encoding into bytes the same way ipfs
     *              does - by doing hash(prefix | request | postfix)
     * @param r     [request] The request to be encoded
     * @param dataPrefix    [bytes] The prefix that ipfs prepends to this data before hashing
     * @param dataPostfix   [bytes] The postfix that ipfs appends to this data before hashing
     * @return  [bytes32] The sha256 hash of the ipfs-encoded request
     */
    function getHashedIpfsReq(
        bytes memory r,
        bytes memory dataPrefix,
        bytes memory dataPostfix
    ) external pure returns (bytes32);

    /**
     * @notice      Get the decoded request back from encoded bytes
     * @param rBytes    [bytes] The encoded bytes version of a request
     * @return r    [Request] The request as a struct
     */
    function getReqFromBytes(bytes memory rBytes) external pure returns (Request memory r);

    function insertToCallData(bytes calldata callData, uint expectedGas, uint startIdx) external pure returns (bytes memory);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Executions                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request.
     *              Typically known by seeing the `HashedReqAdded` event emitted with `newReq`
     * @param expectedGas   [uint] The gas that the executor expects the execution to cost,
     *                      known by simulating the the execution of this tx locally off-chain.
     *                      This can be forwarded as part of the requested call such that the
     *                      receiving contract knows how much gas the whole execution cost and
     *                      can do something to compensate the exact amount (e.g. as part of a trade).
     *                      Cannot be more than 10% above the measured gas cost by the end of execution
     * @return gasUsed      [uint] The gas that was used as part of the execution. Used to know `expectedGas`
     */
    function executeHashedReq(
        uint id,
        Request calldata r,
        uint expectedGas
    ) external returns (uint gasUsed);

    /**
     * @notice      Execute a hashedReqUnveri. Hashes `r`, `dataPrefix`, and `dataSuffix`
     *              together in the same way that ipfs does such that the hash stored on-chain
     *              is the same as the hash used to look up on ipfs to see the raw request.
     *              Since `newHashedReqUnveri` does no verification at all since it can't,
     *              `executeHashedReqUnveri` has to instead. There are some things it can't
     *              know, like the amount of ETH sent in the original request call, so they're
     *              forced to be zero
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request. Typically
     *              known by looking up the hash on ipfs
     * @param dataPrefix    [bytes] The data prepended to the bytes form of `r` before being hashed
     *                      in ipfs
     * @param dataSuffix    [bytes] The data appended to the bytes form of `r` before being hashed
     *                      in ipfs
     * @param expectedGas   [uint] The gas that the executor expects the execution to cost,
     *                      known by simulating the the execution of this tx locally off-chain.
     *                      This can be forwarded as part of the requested call such that the
     *                      receiving contract knows how much gas the whole execution cost and
     *                      can do something to compensate the exact amount (e.g. as part of a trade).
     *                      Cannot be more than 10% above the measured gas cost by the end of execution
     * @return gasUsed      [uint] The gas that was used as part of the execution. Used to know `expectedGas`
     */
    function executeHashedReqUnveri(
        uint id,
        Request calldata r,
        bytes memory dataPrefix,
        bytes memory dataSuffix,
        uint expectedGas
    ) external returns (uint gasUsed);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Cancellations                     //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request.
     *              Typically known by seeing the `HashedReqAdded` event emitted with `newReq`
     */
    function cancelHashedReq(
        uint id,
        Request memory r
    ) external;
    
    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request. Typically
     *              known by looking up the hash on ipfs
     * @param dataPrefix    [bytes] The data prepended to the bytes form of `r` before being hashed
     *                      in ipfs
     * @param dataSuffix    [bytes] The data appended to the bytes form of `r` before being hashed
     *                      in ipfs
     */
    function cancelHashedReqUnveri(
        uint id,
        Request memory r,
        bytes memory dataPrefix,
        bytes memory dataSuffix
    ) external;
    
    
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getAUTOAddr() external view returns (address);
    
    function getStakeManager() external view returns (address);

    function getOracle() external view returns (address);
    
    function getUserForwarder() external view returns (address);
    
    function getGasForwarder() external view returns (address);
    
    function getUserGasForwarder() external view returns (address);
    
    function getReqCountOf(address addr) external view returns (uint);
    
    function getExecCountOf(address addr) external view returns (uint);
    
    function getReferalCountOf(address addr) external view returns (uint);
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

pragma solidity 0.8.6;


/**
* @title    Shared contract
* @notice   Holds constants and modifiers that are used in multiple contracts
* @dev      It would be nice if this could be a library, but modifiers can't be exported :(
* @author   Quantaf1re (James Key)
*/
abstract contract Shared {
    address constant internal _ADDR_0 = address(0);
    bytes32 constant internal _NULL = "";
    uint constant internal _E_18 = 10**18;


    /// @dev    Checks that a uint isn't nonzero/empty
    modifier nzUint(uint u) {
        require(u != 0, "Shared: uint input is empty");
        _;
    }

    /// @dev    Checks that an address isn't nonzero/empty
    modifier nzAddr(address a) {
        require(a != _ADDR_0, "Shared: address input is empty");
        _;
    }

    /// @dev    Checks that a bytes array isn't nonzero/empty
    modifier nzBytes(bytes calldata b) {
        require(b.length > 1, "Shared: bytes input is empty");
        _;
    }

    /// @dev    Checks that a bytes array isn't nonzero/empty
    modifier nzBytes32(bytes32 b) {
        require(b != _NULL, "Shared: bytes32 input is empty");
        _;
    }

    /// @dev    Checks that a uint array isn't nonzero/empty
    modifier nzUintArr(uint[] calldata arr) {
        require(arr.length > 0, "Shared: uint arr input is empty");
        _;
    }
}