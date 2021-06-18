/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.2;



// Part: IPriceOracle

interface IPriceOracle {

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
}

// Part: IStakeManager

interface IStakeManager {
    function stake(uint numStakes) external;
    function unstake(uint[] calldata idxs) external;
    function isCurExec(address addr) external returns (bool);
    function updateExecutor() external returns (uint, uint, uint, address);
    function isUpdatedExec(address addr) external returns (bool);

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

// File: StakeManager.sol

contract StakeManager is IStakeManager, Shared {

    uint public constant STAN_STAKE = 10000 * _E_18;
    uint public constant BLOCKS_IN_EPOCH = 100;

    IOracle private _oracle;
    IERC20 private _AUTO;
    uint private _totalStaked = 0;
    mapping(address => uint) private _stakerToStakedAmount;
    address[] private _stakes;
    Executor private _executor;


    struct Executor{
        address addr;
        uint forEpoch;
    }


    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);


    constructor(IOracle oracle, IERC20 AUTO) {
        _oracle = oracle;
        _AUTO = AUTO;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getOracle() external view returns (IOracle) {
        return _oracle;
    }

    function getAUTO() external view returns (address) {
        return address(_AUTO);
    }

    function getTotalStaked() external view returns (uint) {
        return _totalStaked;
    }

    function getStake(address staker) external view returns (uint) {
        return _stakerToStakedAmount[staker];
    }

    function getStakes() external view returns (address[] memory) {
        return _stakes;
    }

    function getStakesLength() external view returns (uint) {
        return _stakes.length;
    }

    function getStakesSlice(uint startIdx, uint endIdx) external view returns (address[] memory) {
        address[] memory slice = new address[](endIdx - startIdx);
        uint sliceIdx = 0;
        for (uint stakeIdx = startIdx; stakeIdx < endIdx; stakeIdx++) {
            slice[sliceIdx] = _stakes[stakeIdx];
            sliceIdx++;
        }

        return slice;
    }

    function getCurEpoch() public view returns (uint) {
        return (block.number / BLOCKS_IN_EPOCH) * BLOCKS_IN_EPOCH;
    }

    function getExecutor() external view returns (Executor memory) {
        return _executor;
    }

    function isCurExec(address addr) external view override returns (bool) {
        // So that the storage is only loaded once
        Executor memory ex = _executor;
        if (ex.forEpoch == getCurEpoch()) {
            if (ex.addr == addr) {
                return true;
            } else {
                return false;
            }
        }
        // If there're no stakes, allow anyone to be the executor so that a random
        // person can bootstrap the network and nobody needs to be sent any coins
        if (_stakes.length == 0) { return true; }

        return false;
    }

    function getUpdatedExecRes() public view returns (uint epoch, uint randNum, uint idxOfExecutor, address exec) {
        epoch = getCurEpoch();
        // So that the storage is only loaded once
        address[] memory stakes = _stakes;
        // If the executor is out of date and the system already has stake,
        // choose a new executor. This will do nothing if the system is starting
        // and allow someone to stake without needing there to already be existing stakes
        if (_executor.forEpoch != epoch && stakes.length > 0) {
            // -1 because blockhash(seed) in Oracle will return 0x00 if the
            // seed == this block's height
            randNum = _oracle.getRandNum(epoch - 1);
            idxOfExecutor = randNum % stakes.length;
            exec = stakes[idxOfExecutor];
        }
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Staking                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function updateExecutor() external override noFish returns (uint, uint, uint, address) {
        return _updateExecutor();
    }

    function isUpdatedExec(address addr) external override noFish returns (bool) {
        // So that the storage is only loaded once
        Executor memory ex = _executor;
        if (ex.forEpoch == getCurEpoch()) {
            if (ex.addr == addr) {
                return true;
            } else {
                return false;
            }
        } else {
            (, , , address exec) = _updateExecutor();
            if (exec == addr) { return true; }
        }
        if (_stakes.length == 0) { return true; }

        return false;
    }

    // The 1st stake/unstake of an epoch shouldn't change the executor, otherwise
    // a staker could precalculate the effect of how much they stake in order to
    // game the staker selection algo
    function stake(uint numStakes) external nzUint(numStakes) updateExec noFish override {
        uint amount = numStakes * STAN_STAKE;
        // So that the storage is only loaded once
        IERC20 AUTO = _AUTO;
        // Deposit the coins
        uint balBefore = AUTO.balanceOf(address(this));
        require(AUTO.transferFrom(msg.sender, address(this), amount), "SM: transfer failed");
        // This check is a bit unnecessary, but better to be paranoid than r3kt
        require(AUTO.balanceOf(address(this)) - balBefore == amount, "SM: transfer bal check failed");

        for (uint i; i < numStakes; i++) {
            _stakes.push(msg.sender);
        }

        _stakerToStakedAmount[msg.sender] += amount;
        _totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint[] calldata idxs) external nzUintArr(idxs) updateExec noFish override {
        uint amount = idxs.length * STAN_STAKE;
        require(amount <= _stakerToStakedAmount[msg.sender], "SM: not enough stake, peasant");

        for (uint i = 0; i < idxs.length; i++) {
            require(_stakes[idxs[i]] == msg.sender, "SM: idx is not you");
            // Update stakes by moving the last element to the
            // element we're wanting to delete (so it doesn't leave gaps, which is
            // necessary for the _updateExecutor algo)
            _stakes[idxs[i]] = _stakes[_stakes.length-1];
            _stakes.pop();
        }
        
        _stakerToStakedAmount[msg.sender] -= amount;
        _totalStaked -= amount;
        require(_AUTO.transfer(msg.sender, amount));
        emit Unstaked(msg.sender, amount);
    }

    function _updateExecutor() private returns (uint epoch, uint randNum, uint idxOfExecutor, address exec) {
        (epoch, randNum, idxOfExecutor, exec) = getUpdatedExecRes();
        if (exec != _ADDR_0) {
            _executor = Executor(exec, epoch);
        }
    }

    modifier updateExec() {
        // Need to update executor at the start of stake/unstake as opposed to the
        // end of the fcns because otherwise, for the 1st stake/unstake tx in an 
        // epoch, someone could influence the outcome of the executor by precalculating
        // the outcome based on how much they stake and unfairly making themselves the executor
        _updateExecutor();
        _;
    }

    // Ensure the contract is fully collateralised every time
    modifier noFish() {
        _;
        // >= because someone could send some tokens to this contract and disable it if it was ==
        require(_AUTO.balanceOf(address(this)) >= _totalStaked, "SM: something fishy here");
    }
}