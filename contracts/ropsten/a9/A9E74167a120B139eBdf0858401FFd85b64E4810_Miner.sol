/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.2;



// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: Shared

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

// Part: IRegistry

interface IRegistry {
    
    // The address vars are 20b, total 60, calldata is 4b + n*32b usually, which
    // has a factor of 32. uint120 since the current ETH supply of ~115m can fit
    // into that and it's the highest such that 2 * uint120 + 2 * bool is < 256b
    struct Request {
        address payable requester;
        address target;
        address payable referer;
        bytes callData;
        uint120 initEthSent;
        uint120 ethForCall;
        bool verifySender;
        bool payWithAUTO;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Hashed Requests                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Creates a new, raw request. Everything is saved on-chain
     *          in full.
     * @param target    The contract address that needs to be called
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param verifySender  Whether the 1st input of the calldata equals the sender
     * @param payWithAUTO   Whether the sender wants to pay for the request in AUTO
     *                      or ETH. Paying in AUTO reduces the fee
     * @param ethForCall    The ETH to send with the call
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @return id           The id of the request
     */

    function newReq(
        address target,
        address payable referer,
        bytes calldata callData,
        uint120 ethForCall,
        bool verifySender,
        bool payWithAUTO
    ) external payable returns (uint id);

    function getHashedReqs() external view returns (bytes32[] memory);

    function getHashedReqsLen() external view returns (uint);
    
    function getHashedReq(uint id) external view returns (bytes32);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                Hashed Requests Unverified                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function newHashedReqUnveri(bytes32 hashedIpfsReq) external returns (uint id);
    
    function getHashedReqsUnveri() external view returns (bytes32[] memory);

    function getHashedReqsUnveriLen() external view returns (uint);
    
    function getHashedReqUnveri(uint id) external view returns (bytes32);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Hash Helpers                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getReqBytes(Request memory r) external pure returns (bytes memory);

    function getIpfsReqBytes(
        bytes memory r,
        bytes memory dataPrefix,
        bytes memory dataPostfix
    ) external pure returns (bytes memory);

    function getHashedIpfsReq(
        bytes memory r,
        bytes memory dataPrefix,
        bytes memory dataPostfix
    ) external pure returns (bytes32);

    function getReqFromBytes(bytes memory rBytes) external pure returns (Request memory r);
    

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Executions                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function executeHashedReq(
        uint id,
        Request calldata r
    ) external returns (uint gasUsed);

    /**
     * @dev validCalldata needs to be before anything that would convert it to memory
     *      since that is persistent and would prevent validCalldata, that requries
     *      calldata, from working. Can't do the check in _execute for the same reason
     */
    function executeHashedReqUnveri(
        uint id,
        Request calldata r,
        bytes memory dataPrefix,
        bytes memory dataSuffix
    ) external returns (uint gasUsed);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Cancellations                     //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function cancelHashedReq(
        uint id,
        Request memory r
    ) external;
    
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
    
    function getAUTO() external view returns (IERC20);
    
    function getStakeManager() external view returns (address);

    function getOracle() external view returns (address);
    
    function getVerifiedForwarder() external view returns (address);
    
    function getReqCountOf(address addr) external view returns (uint);
    
    function getExecCountOf(address addr) external view returns (uint);
    
    function getReferalCountOf(address addr) external view returns (uint);
}

// File: Miner.sol

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