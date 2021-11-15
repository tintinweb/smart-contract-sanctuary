// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PredictionFeed is Ownable {
    enum PoolType {
        BTC_USDT,
        ETH_USDT,
        BNB_USDT
    }
    enum PoolStatus {
        READY,
        BEGAN,
        LOCKED,
        ENDED
    }
    enum PoolVote {
        UP,
        DOWN,
        SAME
    }

    struct IPool {
        uint256 id;
        uint256 startTime;
        uint256 lockTime;
        uint256 endTime;
        int256 initialPrice;
        int256 finalPrice;
        uint256 balance;
        uint256 upRate;
        uint256 downRate;
        PoolType poolType;
        PoolStatus poolStatus;
    }

    struct IParticipant {
        address owner;
        uint256 amount;
        PoolVote vote;
    }

    struct IWinner {
        address owner;
        uint256 amount;
        bool isClaimed;
    }

    IPool[] public pools;
    uint256 public poolsCount;
    // Pool ID => Participant
    mapping(uint256 => IParticipant[]) public participants;

    // Chainlink Feed Contract Address => AggregatorInterface
    mapping(address => AggregatorV3Interface) private priceFeeds;

    // Chainlink request id => Pool ID
    mapping(bytes32 => uint256) private chainlinkRequests_;
    mapping(PoolType => address) public priceFeedContractAddresses_;

    // Pool winner poolId =>
    mapping(uint256 => IWinner[]) public winners;

    IERC20 private gfx_;

    uint256 READY_TIME = 5 minutes;

    uint256 private fee_;

    /**
     * New Pool Created Event
     * @param poolId pool id
     * @param startTime pool created time
     * @param lockTime pool locked time
     * @param endTime pool locked time
     * @param poolType pool type
     */
    event NewPoolCreated(
        uint256 poolId,
        uint256 startTime,
        uint256 lockTime,
        uint256 endTime,
        string poolType
    );

    /**
     * Pool Started Event
     * @param poolId pool id
     */
    event PoolStarted(uint256 poolId);

    /**
     * Pool Locked Event
     * @param poolId pool id
     */
    event PoolLocked(uint256 poolId, int256 initialPrice);

    /**
     * Pool Ended Event
     * @param poolId pool ID
     */
    event PoolEnded(uint256 poolId, int256 finalPrice, string winner);

    /**
     * Pool Rate updated
     * @param poolId pool id
     * @param balance balance of Pool
     * @param upRate UP rate of pool
     * @param downRate DOWN rate of pool
     */
    event PoolRateUpdated(
        uint256 poolId,
        uint256 balance,
        uint256 upRate,
        uint256 downRate
    );

    /**
     */
    event GFXClaimed(uint256 poolId, address owner, uint256 amount);

    event NewWinner(uint256 poolId, address owner, uint256 amount);

    /**
     */
    event NewLoser(uint256 poolId, address owner);

    /**
     */
    event NewParticipantJoined(
        uint256 poolId,
        address participant,
        uint256 amount,
        string vote
    );

    /**
     */
    event WithdrawBalance(address target, address token, uint256 amount);

    constructor() {
        // Main Net
        priceFeeds[
            0x14e613AC84a31f709eadbdF89C6CC390fDc9540A
        ] = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);
        priceFeeds[
            0x14e613AC84a31f709eadbdF89C6CC390fDc9540A
        ] = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);
        priceFeeds[
            0x14e613AC84a31f709eadbdF89C6CC390fDc9540A
        ] = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);

        // Rinkeby Net
        priceFeeds[
            0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED
        ] = AggregatorV3Interface(0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED);
        priceFeeds[
            0xECe365B379E1dD183B20fc5f022230C044d51404
        ] = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
        priceFeeds[
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ] = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        // Kovan Net
        priceFeeds[
            0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16
        ] = AggregatorV3Interface(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
        priceFeeds[
            0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
        ] = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
        priceFeeds[
            0x9326BFA02ADD2366b30bacB125260Af641031331
        ] = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        // BSC Main NET
        priceFeeds[
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        ] = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        priceFeeds[
            0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf
        ] = AggregatorV3Interface(0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf);
        priceFeeds[
            0x63D407F32Aa72E63C7209ce1c2F5dA40b3AaE726
        ] = AggregatorV3Interface(0x63D407F32Aa72E63C7209ce1c2F5dA40b3AaE726);

        // BSC TEST NET
        priceFeeds[
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        ] = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        priceFeeds[
            0x5741306c21795FdCBb9b265Ea0255F499DFe515C
        ] = AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C);
        priceFeeds[
            0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7
        ] = AggregatorV3Interface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);

        poolsCount = 0;
        fee_ = 100;
    }

    /**
     * Initalize Aggregators
     * @notice Price Feeds
     * Main Net
     *  BNB_USD: 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A
     *  BTC_USD: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     *  ETH_USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     * Rinkeby
     *  BNB_USD: 0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED
     *  BTC_USD: 0xECe365B379E1dD183B20fc5f022230C044d51404
     *  ETH_USD: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     * Kovan
     *  BNB_USD: 0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16
     *  BTC_USD: 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
     *  ETH_USD: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * @notice Oracle Address
     *  Main Net:
     *  Rinkeby: 0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40
     *  Kovan: 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * @notice Chainlink Job ID
     *  Mainnet:
     *  Rinkeby: 60f206a5128040fab7a4cd543456c8c0
     *  Kovan: 29fa9aa13bf1468788b7cc4a500a45b8
     */
    function initialize(
        address _gfx,
        address _btc,
        address _eth,
        address _bnb
    ) public onlyOwner {
        gfx_ = IERC20(_gfx);

        priceFeedContractAddresses_[PoolType.BTC_USDT] = _btc;
        priceFeedContractAddresses_[PoolType.ETH_USDT] = _eth;
        priceFeedContractAddresses_[PoolType.BNB_USDT] = _bnb;
    }

    modifier isValidPoolId(uint256 _poolId) {
        require(_poolId < pools.length, "PredictionFeed: Invalide Pool ID");
        _;
    }

    modifier isValidPoolType(string memory _poolType) {
        require(
            keccak256(abi.encodePacked(_poolType)) ==
                keccak256(abi.encodePacked("BNB")) ||
                keccak256(abi.encodePacked(_poolType)) ==
                keccak256(abi.encodePacked("BTC")) ||
                keccak256(abi.encodePacked(_poolType)) ==
                keccak256(abi.encodePacked("ETH")),
            "PredictionFeed: Invalid Pool Type"
        );
        _;
    }

    modifier isValidTimes(uint256 _startTime, uint256 _endTime) {
        require(
            _startTime > block.timestamp,
            "PredictionFeed: Start time is already gone"
        );
        require(
            _endTime > block.timestamp,
            "PredictionFeed: End time is already gone"
        );
        require(
            _endTime > _startTime + READY_TIME,
            "PredictionFeed: Wrong end time"
        );
        _;
    }

    modifier isValidPoolVote(string memory _vote) {
        require(
            keccak256(abi.encodePacked(_vote)) ==
                keccak256(abi.encodePacked("UP")) ||
                keccak256(abi.encodePacked(_vote)) ==
                keccak256(abi.encodePacked("DOWN")),
            "PredictionFeed: Invalid Vote"
        );
        _;
    }

    modifier canParticipatePool(uint256 _poolId, uint256 _amount) {
        IPool memory pool = pools[_poolId];
        require(
            pool.poolStatus == PoolStatus.BEGAN,
            "PredictionFeed: Pool is not began"
        );
        require(
            block.timestamp >= pool.startTime,
            "PredictionFeed: Pool is not ready to participate"
        );
        require(
            block.timestamp <= pool.lockTime,
            "PredictionFeed: Can't participate pool"
        );

        bool wasParticipated = false;
        for (uint256 i = 0; i < participants[_poolId].length; i++) {
            if (participants[_poolId][i].owner == msg.sender) {
                wasParticipated = true;
            }
        }
        require(!wasParticipated, "PredictionFeed: Already Participated");
        require(_amount > 0, "PredictionFeed: Value is 0");
        _;
    }

    modifier _canStart(uint256 _poolId) {
        IPool memory pool = pools[_poolId];
        require(
            pool.poolStatus == PoolStatus.READY,
            "PriceFeed: Pool is not ready"
        );
        _;
    }

    modifier _canLock(uint256 _poolId) {
        IPool memory pool = pools[_poolId];
        require(
            pool.poolStatus == PoolStatus.BEGAN,
            "PriceFeed: Pool is not began"
        );
        _;
    }

    modifier _canEnd(uint256 _poolId) {
        IPool memory pool = pools[_poolId];
        require(
            pool.poolStatus == PoolStatus.LOCKED,
            "PriceFeed: Pool is not locked"
        );
        _;
    }

    function _updatePoolRate(uint256 _poolId) private {
        uint256 balance = 0;
        uint256 upAmount = 0;
        uint256 downAmount = 0;

        for (uint256 i = 0; i < participants[_poolId].length; i++) {
            balance += participants[_poolId][i].amount;
            if (participants[_poolId][i].vote == PoolVote.UP) {
                upAmount += participants[_poolId][i].amount;
            } else {
                downAmount += participants[_poolId][i].amount;
            }
        }

        pools[_poolId].balance = balance;
        pools[_poolId].upRate = upAmount == 0 ? 0 : (balance * 100) / upAmount;
        pools[_poolId].downRate = downAmount == 0
            ? 0
            : (balance * 100) / downAmount;

        emit PoolRateUpdated(
            _poolId,
            balance,
            pools[_poolId].upRate,
            pools[_poolId].downRate
        );
    }

    function getPoolPrice(uint256 _poolId) public view returns (int256) {
        return
            getLastPrice(priceFeedContractAddresses_[pools[_poolId].poolType]);
    }

    function _presentAward(uint256 _poolId, PoolVote _poolVote) private {
        if (_poolVote == PoolVote.SAME) {
            for (uint256 i = 0; i < participants[_poolId].length; i++) {
                IWinner memory winner;
                winner.owner = participants[_poolId][i].owner;
                winner.amount = (participants[_poolId][i].amount * fee_) / 100;
                winner.isClaimed = false;

                winners[_poolId].push(winner);

                emit NewWinner(_poolId, winner.owner, winner.amount);
            }
        } else {
            for (uint256 i = 0; i < participants[_poolId].length; i++) {
                if (participants[_poolId][i].vote == _poolVote) {
                    uint256 amount = 0;
                    if (_poolVote == PoolVote.UP) {
                        amount =
                            (participants[_poolId][i].amount *
                                pools[_poolId].upRate) /
                            100;
                    } else if (_poolVote == PoolVote.DOWN) {
                        amount =
                            (participants[_poolId][i].amount *
                                pools[_poolId].downRate) /
                            100;
                    } else {
                        amount = participants[_poolId][i].amount;
                    }

                    IWinner memory winner;
                    winner.owner = participants[_poolId][i].owner;
                    winner.amount = (amount * fee_) / 100;
                    winner.isClaimed = false;

                    winners[_poolId].push(winner);

                    emit NewWinner(_poolId, winner.owner, winner.amount);
                } else {
                    emit NewLoser(_poolId, participants[_poolId][i].owner);
                }
            }
        }
    }

    function updateFee(uint256 _fee) public onlyOwner {
        require(_fee <= 100, "PredictionFeed: Invalid Fee");

        fee_ = _fee;
    }

    /**
     * Create New Pool
     * @param _startTime pool start time
     * @param _endTime pool end time
     * @param _poolType enum['BNB', 'BTC', 'ETH']
     * @return pool id
     */
    function createPool(
        uint256 _startTime,
        uint256 _endTime,
        string memory _poolType
    )
        external
        onlyOwner
        isValidPoolType(_poolType)
        isValidTimes(_startTime, _endTime)
        returns (uint256)
    {
        IPool memory pool;
        pool.id = poolsCount;
        pool.startTime = _startTime;
        pool.lockTime = _startTime + READY_TIME;
        pool.endTime = _endTime;
        pool.initialPrice = 0;
        pool.finalPrice = 0;
        pool.balance = 0;
        pool.upRate = 0;
        pool.downRate = 0;
        if (
            keccak256(abi.encodePacked(_poolType)) ==
            keccak256(abi.encodePacked("BNB"))
        ) {
            pool.poolType = PoolType.BNB_USDT;
        } else if (
            keccak256(abi.encodePacked(_poolType)) ==
            keccak256(abi.encodePacked("BTC"))
        ) {
            pool.poolType = PoolType.BTC_USDT;
        } else {
            // ETH
            pool.poolType = PoolType.ETH_USDT;
        }
        pool.poolStatus = PoolStatus.READY;
        pools.push(pool);

        poolsCount++;

        emit NewPoolCreated(
            pool.id,
            pool.startTime,
            pool.lockTime,
            pool.endTime,
            _poolType
        );

        return pool.id;
    }

    /**
     * Start Pool
     */
    function startPool(uint256 _poolId) public onlyOwner _canStart(_poolId) {
        pools[_poolId].poolStatus = PoolStatus.BEGAN;

        emit PoolStarted(_poolId);
    }

    /**
     * Lock Pool
     */
    function lockPool(uint256 _poolId) public onlyOwner _canLock(_poolId) {
        pools[_poolId].poolStatus = PoolStatus.LOCKED;
        pools[_poolId].initialPrice = getPoolPrice(_poolId);

        emit PoolLocked(_poolId, pools[_poolId].initialPrice);
    }

    /**
     * End Pool
     */
    function endPool(uint256 _poolId) public onlyOwner _canEnd(_poolId) {
        string memory winner;

        pools[_poolId].poolStatus = PoolStatus.ENDED;
        pools[_poolId].finalPrice = getPoolPrice(_poolId);

        if (pools[_poolId].finalPrice > pools[_poolId].initialPrice) {
            winner = "UP";
            _presentAward(_poolId, PoolVote.UP);
        } else if (pools[_poolId].finalPrice < pools[_poolId].initialPrice) {
            winner = "DOWN";
            _presentAward(_poolId, PoolVote.DOWN);
        } else {
            winner = "SAME";
            _presentAward(_poolId, PoolVote.SAME);
        }

        emit PoolEnded(_poolId, pools[_poolId].finalPrice, winner);
    }

    /**
     * Participate Pool
     * @param _poolId pool id
     * @param _vote enum ['UP', 'DOWN']
     */
    function participatePool(
        uint256 _poolId,
        string memory _vote,
        uint256 _amount
    )
        public
        isValidPoolId(_poolId)
        isValidPoolVote(_vote)
        canParticipatePool(_poolId, _amount)
    {
        require(_amount > 0, "PredictionFeed: Value is 0");

        IParticipant memory participant;
        participant.owner = msg.sender;
        participant.amount = _amount;
        if (
            keccak256(abi.encodePacked(_vote)) ==
            keccak256(abi.encodePacked("UP"))
        ) {
            participant.vote = PoolVote.UP;
        } else {
            participant.vote = PoolVote.DOWN;
        }

        require(
            gfx_.transferFrom(msg.sender, address(this), _amount),
            "PredictionFeed: Not allowed to transfer"
        );

        participants[_poolId].push(participant);

        emit NewParticipantJoined(_poolId, msg.sender, _amount, _vote);

        _updatePoolRate(_poolId);
    }

    /**
     * Get USD Price
     * @param _address Ethereum Price Feed Contract Address
     */
    function getLastPrice(address _address) public view returns (int256) {
        (, int256 price, , , ) = priceFeeds[_address].latestRoundData();
        return price;
    }

    function balanceOfPool(uint256 _poolId)
        public
        view
        isValidPoolId(_poolId)
        returns (uint256)
    {
        uint256 balance = 0;
        for (uint256 i = 0; i < participants[_poolId].length; i++) {
            balance += participants[_poolId][i].amount;
        }

        return balance;
    }

    function claimGFX(uint256 _poolId)
        public
        isValidPoolId(_poolId)
        returns (bool)
    {
        uint256 length = winners[_poolId].length;
        require(length > 0, "PredictionFeed: No winner");

        for (uint256 i = 0; i < length; i++) {
            if (
                winners[_poolId][i].owner == msg.sender &&
                winners[_poolId][i].isClaimed == false
            ) {
                require(
                    gfx_.transfer(
                        winners[_poolId][i].owner,
                        winners[_poolId][i].amount
                    ),
                    "PricePrediction: Transferring GFX fialed"
                );
                winners[_poolId][i].isClaimed = true;

                emit GFXClaimed(
                    _poolId,
                    winners[_poolId][i].owner,
                    winners[_poolId][i].amount
                );

                return true;
            }
        }

        return false;
    }

    function withdrawBalance(
        address _target,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_target != address(0), "Invalid Target Address");
        require(_token != address(0), "Invalid Token Address");
        require(_amount > 0, "Amount should be bigger than zero");

        IERC20 token = IERC20(_token);
        require(token.transfer(_target, _amount), "Withdraw failed");

        emit WithdrawBalance(_target, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

