/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.2;



// Part: IForwarder

interface IForwarder {

    function forward(
        address target,
        bytes calldata callData
    ) external payable returns (bool success, bytes memory returnData);

}

// Part: IPriceOracle

interface IPriceOracle {

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
}

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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

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

    constructor () {
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

// Part: IOracle

interface IOracle {
    // Needs to output the same number for the whole epoch
    function getRandNum(uint salt) external view returns (uint);

    function getPriceOracle() external view returns (IPriceOracle);

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
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

// Part: IStakeManager

interface IStakeManager {

    struct Executor{
        address addr;
        uint forEpoch;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getOracle() external view returns (IOracle);

    function getAUTO() external view returns (address);

    function getTotalStaked() external view returns (uint);

    function getStake(address staker) external view returns (uint);

    function getStakes() external view returns (address[] memory);

    function getStakesLength() external view returns (uint);

    function getStakesSlice(uint startIdx, uint endIdx) external view returns (address[] memory);

    function getCurEpoch() external view returns (uint);

    function getExecutor() external view returns (Executor memory);

    function isCurExec(address addr) external view returns (bool);

    function getUpdatedExecRes() external view returns (uint epoch, uint randNum, uint idxOfExecutor, address exec);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Staking                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function updateExecutor() external returns (uint, uint, uint, address);

    function isUpdatedExec(address addr) external returns (bool);

    function stake(uint numStakes) external;

    function unstake(uint[] calldata idxs) external;
}

// File: Registry.sol

contract Registry is IRegistry, Shared, ReentrancyGuard {
    
    // Constant public
    uint public constant GAS_OVERHEAD_AUTO = 70500;
    uint public constant GAS_OVERHEAD_ETH = 47000;
    uint public constant BASE_BPS = 10000;
    uint public constant PAY_AUTO_BPS = 11000;
    uint public constant PAY_ETH_BPS = 13000;

    // Constant private
    bytes private constant _EMPTY_BYTES = "";
    
    IERC20 private _AUTO;
    IStakeManager private _stakeMan;
    IOracle private _oracle;
    IForwarder private _veriForwarder;
    // We need to have 2 separete arrays for adding requests with and without
    // eth because, when comparing the hash of a request to be executed to the
    // stored hash, we have no idea what the request had for the eth values
    // that was originally stored as a hash and therefore would need to store
    // an extra bool saying where eth was sent with the new request. Instead, 
    // that can be known implicitly by having 2 separate arrays.
    bytes32[] private _hashedReqs;
    bytes32[] private _hashedReqsUnveri;
    // This counts the number of times each requester has had a request executed
    mapping(address => uint) private _reqCounts;
    // This counts the number of times each staker has executed a request
    mapping(address => uint) private _execCounts;
    // This counts the number of times each referer has been identified in an
    // executed tx
    mapping(address => uint) private _referalCounts;
    
    
    // This is defined in IRegistry. Here for convenience
    // The address vars are 20b, total 60, calldata is 4b + n*32b usually, which
    // has a factor of 32. uint120 since the current ETH supply of ~115m can fit
    // into that and it's the highest such that 2 * uint120 + 2 * bool is < 256b
    // struct Request {
    //     address payable requester;
    //     address target;
    //     address payable referer;
    //     bytes callData;
    //     uint120 initEthSent;
    //     uint120 ethForCall;
    //     bool verifySender;
    //     bool payWithAUTO;
    // }

    // Easier to parse when using native types rather than structs
    event HashedReqAdded(
        uint indexed id,
        address payable requester,
        address target,
        address payable referer,
        bytes callData,
        uint120 initEthSent,
        uint120 ethForCall,
        bool verifySender,
        bool payWithAUTO
    );
    event HashedReqRemoved(uint indexed id, bool wasExecuted);
    event HashedReqUnveriAdded(uint indexed id);
    event HashedReqUnveriRemoved(uint indexed id, bool wasExecuted);


    constructor(
        IERC20 AUTO,
        IStakeManager staker,
        IOracle oracle,
        IForwarder veriForwarder
    ) ReentrancyGuard() {
        _AUTO = AUTO;
        _stakeMan = staker;
        _oracle = oracle;
        _veriForwarder = veriForwarder;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Hashed Requests                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function newReq(
        address target,
        address payable referer,
        bytes calldata callData,
        uint120 ethForCall,
        bool verifySender,
        bool payWithAUTO
    )
        external
        payable
        override
        nzAddr(target)
        targetNotThis(target)
        validEth(payWithAUTO, ethForCall)
        returns (uint id)
    {
        Request memory r = Request(payable(msg.sender), target, referer, callData, uint120(msg.value), ethForCall, verifySender, payWithAUTO);
        bytes32 hashedIpfsReq = keccak256(getReqBytes(r));

        id = _hashedReqs.length;
        emit HashedReqAdded(
            id,
            r.requester,
            r.target,
            r.referer,
            r.callData,
            r.initEthSent,
            r.ethForCall,
            r.verifySender,
            r.payWithAUTO
        );
        _hashedReqs.push(hashedIpfsReq);
    }

    function getHashedReqs() external view override returns (bytes32[] memory) {
        return _hashedReqs;
    }

    function getHashedReqsSlice(uint startIdx, uint endIdx) external view returns (bytes32[] memory) {
        return _getBytes32Slice(_hashedReqs, startIdx, endIdx);
    }

    function getHashedReqsLen() external view override returns (uint) {
        return _hashedReqs.length;
    }
    
    function getHashedReq(uint id) external view override returns (bytes32) {
        return _hashedReqs[id];
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                Hashed Requests Unverified                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function newHashedReqUnveri(bytes32 hashedIpfsReq)
        external
        override
        nzBytes32(hashedIpfsReq)
        returns (uint id)
    {
        id = _hashedReqsUnveri.length;
        _hashedReqsUnveri.push(hashedIpfsReq);
        emit HashedReqUnveriAdded(id);
    }
    
    function getHashedReqsUnveri() external view override returns (bytes32[] memory) {
        return _hashedReqsUnveri;
    }

    function getHashedReqsUnveriSlice(uint startIdx, uint endIdx) external view returns (bytes32[] memory) {
        return _getBytes32Slice(_hashedReqsUnveri, startIdx, endIdx);
    }

    function getHashedReqsUnveriLen() external view override returns (uint) {
        return _hashedReqsUnveri.length;
    }
    
    function getHashedReqUnveri(uint id) external view override returns (bytes32) {
        return _hashedReqsUnveri[id];
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Hash Helpers                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getReqBytes(Request memory r) public pure override returns (bytes memory) {
        return abi.encode(r);
    }

    function getIpfsReqBytes(
        bytes memory r,
        bytes memory dataPrefix,
        bytes memory dataPostfix
    ) public pure override returns (bytes memory) {
        return abi.encodePacked(
            dataPrefix,
            r,
            dataPostfix
        );
    }

    function getHashedIpfsReq(
        bytes memory r,
        bytes memory dataPrefix,
        bytes memory dataPostfix
    ) public pure override returns (bytes32) {
        return sha256(getIpfsReqBytes(r, dataPrefix, dataPostfix));
    }

    function getReqFromBytes(bytes memory rBytes) public pure override returns (Request memory r) {
        (r) = abi.decode(rBytes, (Request));
    }
    

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Executions                       //
    //                                                          //
    //////////////////////////////////////////////////////////////


    /**
     * @dev validCalldata needs to be before anything that would convert it to memory
     *      since that is persistent and would prevent validCalldata, that requries
     *      calldata, from working. Can't do the check in _execute for the same reason.
     *      Note: targetNotThis and validEth are used in newReq.
     *      validCalldata is only used here because it causes an unknown
     *      'InternalCompilerError' when using it with newReq
     */
    function executeHashedReq(
        uint id,
        Request calldata r
    )
        external
        override
        validExec
        nonReentrant
        noFish(r)
        validCalldata(r)
        verReq(id, r)
        returns (uint gasUsed)
    {
        uint startGas = gasleft();
        delete _hashedReqs[id];
        gasUsed = _execute(r, startGas - gasleft(), msg.data.length * 20);
        
        emit HashedReqRemoved(id, true);
    }

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
    )
        external
        override
        validExec
        nonReentrant
        noFish(r)
        targetNotThis(r.target)
        verReqIPFS(id, r, dataPrefix, dataSuffix)
        returns (uint gasUsed)
    {
        require(
            r.initEthSent == 0 &&
            r.ethForCall == 0 &&
            r.payWithAUTO == true &&
            r.verifySender == false,
            "Reg: cannot verify. Nice try ;)"
        );

        uint startGas = gasleft();
        delete _hashedReqsUnveri[id];
        // 1000 extra is needed compared to executeHashedReq because of the extra checks
        gasUsed = _execute(r, startGas - gasleft(), (msg.data.length * 20) + 1000);
        
        emit HashedReqUnveriRemoved(id, true);
    }

    function _execute(Request memory r, uint gasUsedInDelete, uint extraOverhead) private returns (uint gasUsed) {
        uint startGas = gasleft();

        // Make the call that the user requested
        bool success;
        bytes memory returnData;
        if (r.verifySender) {
            (success, returnData) = _veriForwarder.forward{value: r.ethForCall}(r.target, r.callData);
        } else {
            (success, returnData) = r.target.call{value: r.ethForCall}(r.callData);
        }
        // Need this if statement because if the call succeeds, the tx will revert
        // with an EVM error because it can't decode 0x00. If a tx fails with no error
        // message, maybe that's a problem? But if it failed without a message then it's
        // gonna be hard to know what went wrong regardless
        if (!success) {
            revert(abi.decode(returnData, (string)));
        }
        // require(success, string(returnData));
        
        // Store AUTO rewards
        // It's cheaper to store the cumulative rewards than it is to send
        // an AUTO transfer directly since the former changes 1 storage
        // slot whereas the latter changes 2. The rewards are actually stored
        // in a different contract that reads the reward storage of this contract
        // because of the danger of someone using call to call to AUTO and transfer
        // out tokens. It could be prevented by preventing r.target being set to AUTO,
        // but it's better to be paranoid and totally separate the contracts.
        // Need to include these storages in the gas cost that the user pays since
        // they benefit from part of it and the costs can vary depending on whether
        // the amounts changed from were 0 or non-0
        _reqCounts[r.requester] += 1;
        _execCounts[msg.sender] += 1;
        if (r.referer != _ADDR_0) {
            _referalCounts[r.referer] += 1;
        }

        IOracle orac = _oracle;
        _stakeMan.getStakes();
        uint gasPrice = orac.getGasPriceFast();
        _stakeMan.getStakes();

        uint callGasUsed = (startGas - gasleft());
        gasUsed = 5000 + callGasUsed + extraOverhead;

        _stakeMan.getStakes();
        uint gasRefunded = 15000;

        if (r.payWithAUTO) {
            _stakeMan.getStakesLength();
            gasUsed += GAS_OVERHEAD_AUTO;
            if (gasRefunded > gasUsed / 2) {
                gasUsed = (gasUsed / 2) + 700;
            } else {
                gasUsed += 855;
                gasUsed -= gasRefunded;
            }

            uint totalAUTO = gasUsed * gasPrice * orac.getAUTOPerETH() * PAY_AUTO_BPS / (BASE_BPS * _E_18);

            // Send the executor their bounty
            require(_AUTO.transferFrom(r.requester, msg.sender, totalAUTO));
        } else {
            _stakeMan.getStakes();
            gasUsed += GAS_OVERHEAD_ETH;
            if (gasRefunded > gasUsed / 2) {
                gasUsed = (gasUsed / 2) + 700;
            } else {
                gasUsed += 855;
                gasUsed -= gasRefunded;
            }

            _stakeMan.getStakes();
            uint totalETH = gasUsed * gasPrice * PAY_ETH_BPS / BASE_BPS;
            uint ethReceived = r.initEthSent - r.ethForCall;

            // Send the executor their bounty
            require(ethReceived >= totalETH, "Reg: not enough eth sent");
            payable(msg.sender).transfer(totalETH);
            _stakeMan.getStakes();

            // Refund excess to the requester
            uint excess = ethReceived - totalETH;
            if (excess > 0) {
                r.requester.transfer(excess);
            }

            _stakeMan.getTotalStaked();
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Cancellations                     //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    
    function cancelHashedReq(
        uint id,
        Request memory r
    )
        external
        override
        nonReentrant
        verReq(id, r)
    {
        require(msg.sender == r.requester, "Reg: not the requester");
        
        // Cancel the request
        emit HashedReqRemoved(id, false);
        delete _hashedReqs[id];
        
        // Send refund
        if (r.initEthSent > 0) {
            r.requester.transfer(r.initEthSent);
        }
    }
    
    function cancelHashedReqUnveri(
        uint id,
        Request memory r,
        bytes memory dataPrefix,
        bytes memory dataSuffix
    )
        external
        override
        nonReentrant
        verReqIPFS(id, r, dataPrefix, dataSuffix)
    {
        require(msg.sender == r.requester, "Reg: not the requester");
        
        // Cancel the request
        emit HashedReqUnveriRemoved(id, false);
        delete _hashedReqsUnveri[id];
    }
    
    
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getAUTO() external view override returns (IERC20) {
        return _AUTO;
    }
    
    function getStakeManager() external view override returns (address) {
        return address(_stakeMan);
    }
    
    function getOracle() external view override returns (address) {
        return address(_oracle);
    }
    
    function getVerifiedForwarder() external view override returns (address) {
        return address(_veriForwarder);
    }

    function getReqCountOf(address addr) external view override returns (uint) {
        return _reqCounts[addr];
    }
    
    function getExecCountOf(address addr) external view override returns (uint) {
        return _execCounts[addr];
    }
    
    function getReferalCountOf(address addr) external view override returns (uint) {
        return _referalCounts[addr];
    }

    function _getBytes32Slice(bytes32[] memory arr, uint startIdx, uint endIdx) private pure returns (bytes32[] memory) {
        bytes32[] memory slice = new bytes32[](endIdx - startIdx);
        uint sliceIdx = 0;
        for (uint arrIdx = startIdx; arrIdx < endIdx; arrIdx++) {
            slice[sliceIdx] = arr[arrIdx];
            sliceIdx++;
        }

        return slice;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Modifiers                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    modifier targetNotThis(address target) {
        require(target != address(this) && target != address(_AUTO), "Reg: nice try ;)");
        _;
    }

    modifier validEth(bool payWithAUTO, uint ethForCall) {
        if (payWithAUTO) {
            // When paying with AUTO, there's no reason to send more ETH than will
            // be used in the future call
            require(ethForCall == msg.value, "Reg: ethForCall not msg.value");
        } else {
            // When paying with ETH, ethForCall needs to be lower than msg.value
            // since some ETH is needed to be left over for paying the fee + bounty
            require(ethForCall <= msg.value, "Reg: ethForCall too high");
        }
        _;
    }

    modifier validCalldata(Request calldata r) {
        if (r.verifySender) {
            require(abi.decode(r.callData[4:36], (address)) == r.requester, "Reg: calldata not verified");
        }
        _;
    }

    modifier validExec() {
        require(_stakeMan.isUpdatedExec(msg.sender), "Reg: not executor or expired");
        _;
    }

    modifier noFish(Request calldata r) {
        uint ethStartBal = address(this).balance;

        _;

        if (r.payWithAUTO) {
            require(address(this).balance >= ethStartBal - r.ethForCall, "Reg: something fishy here");
        } else {
            require(address(this).balance >= ethStartBal - r.initEthSent, "Reg: something fishy here");
        }
    }

    // Verify that a request is the same as the one initially stored. This also
    // implicitly checks that the request hasn't been deleted as the hash of the
    // request isn't going to be address(0)
    modifier verReq(
        uint id,
        Request memory r
    ) {
        require(
            keccak256(getReqBytes(r)) == _hashedReqs[id], 
            "Reg: request not the same"
        );
        _;
    }

    // Verify that a request is the same as the one initially stored. This also
    // implicitly checks that the request hasn't been deleted as the hash of the
    // request isn't going to be address(0)
    modifier verReqIPFS(
        uint id,
        Request memory r,
        bytes memory dataPrefix,
        bytes memory dataSuffix
    ) {
        require(
            getHashedIpfsReq(getReqBytes(r), dataPrefix, dataSuffix) == _hashedReqsUnveri[id], 
            "Reg: unveri request not the same"
        );
        _;
    }
    
    receive() external payable {}
}