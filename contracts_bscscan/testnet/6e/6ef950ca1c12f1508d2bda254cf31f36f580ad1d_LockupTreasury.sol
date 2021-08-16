// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Governable.sol";

contract LockupTreasury is Configurable, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Address for address;

    bytes32 internal constant MinValueOfBotHolder   = bytes32("MinValueOfBotHolder");
    bytes32 internal constant ANNToken              = bytes32("ANNToken");
    uint internal constant Lockup1Month = 60 * 60 * 24 * 30; // 1 months lock up period

    struct CreateReq {
        // pool name
        string name;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // total amount of token0
        uint amountTotal0;
        // total amount of token1
        uint amountTotal1;
        // the timestamp in seconds the pool will open
        uint openAt;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        uint minAmount1PerWallet;
        bool enableWhiteList;
    }

    struct Pool {
        // pool name
        string name;
        // creator of the pool
        address payable creator;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // total amount of token0
        uint amountTotal0;
        // total amount of token1
        uint amountTotal1;
        // the timestamp in seconds the pool will open
        uint openAt;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        // whether or not whitelist is enable
        bool enableWhiteList;
    }

    // struct Whitelist {
    //     // whether or not whitelist is enable
    //     bool enable;
    //     uint allowAmount;
    // }

    Pool[] public pools;    

    // pool index => the timestamp which the pool filled at
    mapping(uint => uint) public filledAtP;
    // pool index => swap amount of token0
    mapping(uint => uint) public amountSwap0P;
    // pool index => swap amount of token1
    mapping(uint => uint) public amountSwap1P;
    // pool index => the swap pool only allow BOT holder to take part in
    mapping(uint => bool) public onlyANNHolderP;
    // pool index => maximum swap amount1 per wallet, if the value is not set, the default value is zero
    mapping(uint => uint) public minAmount1PerWalletP;
    // team address => pool index => whether or not creator's pool has been claimed
    mapping(address => mapping(uint => bool)) public creatorClaimed;
    // user address => pool index => swapped amount of token0
    mapping(address => mapping(uint => uint)) public myAmountSwapped0;
    // user address => pool index => swapped amount of token1
    mapping(address => mapping(uint => uint)) public myAmountSwapped1;
    // user address => pool index => whether or not my pool has been claimed
    mapping(address => mapping(uint => uint)) public myClaimedAt;
    // user address => pool index => whether or not my pool has been claimed
    mapping(address => mapping(uint => uint)) public myClaimedAmount;
    // pool index => account => whether or not in white list
    mapping(uint => mapping(address => uint)) public whitelistP;
    // pool index => transaction fee
    // mapping(uint => uint) public txFeeP;

    event Created(uint indexed index, address indexed sender, Pool pool);
    event Swapped(uint indexed index, address indexed sender, uint amount0, uint amount1, uint txFee);
    event Claimed(uint indexed index, address indexed sender, uint amount0);
    event UserClaimed(uint indexed index, address indexed sender, uint amount0);

    function initialize() public initializer {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();

        config[MinValueOfBotHolder] = 60 ether;

        config[ANNToken] = uint(0xB8d4DEBc77fE2D412f9bA5B22B33A8f6c4d9aE1e); // ANN
    }

    function initialize_testnet() public {
        initialize();

        config[ANNToken] = uint(0xB8d4DEBc77fE2D412f9bA5B22B33A8f6c4d9aE1e); // ANN
    }

    function initialize_bsc() public {
        initialize();

        config[ANNToken] = uint(0x1188d953aFC697C031851169EEf640F23ac8529C); // ANN
    }

    function create(CreateReq memory poolReq) external nonReentrant {
        uint index = pools.length;
        require(tx.origin == msg.sender, "disallow contract caller");
        require(poolReq.amountTotal0 != 0, "invalid amountTotal0");
        require(poolReq.amountTotal1 != 0, "invalid amountTotal1");
        require(poolReq.openAt >= now, "invalid openAt");
        require(poolReq.closeAt > poolReq.openAt, "invalid closeAt");
        require(poolReq.claimAt == 0 || poolReq.claimAt >= poolReq.closeAt, "invalid closeAt");
        require(bytes(poolReq.name).length <= 15, "length of name is too long");

        if (poolReq.minAmount1PerWallet != 0) {
            minAmount1PerWalletP[index] = poolReq.minAmount1PerWallet;
        }

        // transfer amount of token0 to this contract
        IERC20  _token0 = IERC20(poolReq.token0);
        uint token0BalanceBefore = _token0.balanceOf(address(this));
        _token0.safeTransferFrom(msg.sender, address(this), poolReq.amountTotal0);
        require(
            _token0.balanceOf(address(this)).sub(token0BalanceBefore) == poolReq.amountTotal0,
            "not support deflationary token"
        );

        Pool memory pool;
        pool.name = poolReq.name;
        pool.creator = msg.sender;
        pool.token0 = poolReq.token0;
        pool.token1 = poolReq.token1;
        pool.amountTotal0 = poolReq.amountTotal0;
        pool.amountTotal1 = poolReq.amountTotal1;
        pool.openAt = poolReq.openAt;
        pool.closeAt = poolReq.closeAt;
        pool.claimAt = poolReq.claimAt;
        pool.enableWhiteList = poolReq.enableWhiteList;
        pools.push(pool);

        emit Created(index, msg.sender, pool);
    }

    function swap(uint index, uint amount1) external payable
        nonReentrant
        isPoolExist(index)
        isPoolNotClosed(index)
    {
        address payable sender = msg.sender;
        require(tx.origin == msg.sender, "disallow contract caller");
        Pool memory pool = pools[index];

        if (pool.enableWhiteList) {
            require(whitelistP[index][sender] > 0, "sender not in whitelist");
            require(whitelistP[index][sender] >= myAmountSwapped1[sender][index].add(amount1), "sender purchased more than allowed amount");
        }

        require(pool.openAt <= now, "pool not open");
        require(pool.amountTotal1 > amountSwap1P[index], "swap amount is zero");

        // check if amount1 is exceeded
        uint excessAmount1 = 0;
        uint _amount1 = pool.amountTotal1.sub(amountSwap1P[index]);
        if (_amount1 < amount1) {
            excessAmount1 = amount1.sub(_amount1);
        } else {
            _amount1 = amount1;
        }

        // check if amount0 is exceeded
        uint amount0 = _amount1.mul(pool.amountTotal0).div(pool.amountTotal1);
        uint _amount0 = pool.amountTotal0.sub(amountSwap0P[index]);
        if (_amount0 > amount0) {
            _amount0 = amount0;
        }

        amountSwap0P[index] = amountSwap0P[index].add(_amount0);
        amountSwap1P[index] = amountSwap1P[index].add(_amount1);
        myAmountSwapped0[sender][index] = myAmountSwapped0[sender][index].add(_amount0);
        // check if swapped amount of token1 is exceeded maximum allowance
        if (minAmount1PerWalletP[index] != 0) {
            require(
                myAmountSwapped1[sender][index].add(_amount1) >= minAmount1PerWalletP[index],
                "swapped amount of token1 is lower than min allowance"
            );
            myAmountSwapped1[sender][index] = myAmountSwapped1[sender][index].add(_amount1);
        }

        if (pool.amountTotal1 == amountSwap1P[index]) {
            filledAtP[index] = now;
        }

        // transfer amount of token1 to this contract
        if (pool.token1 == address(0)) {
            require(msg.value == amount1, "invalid amount of ETH");
        } else {
            IERC20(pool.token1).safeTransferFrom(sender, address(this), amount1);
        }

        if (pool.claimAt == 0) {
            if (_amount0 > 0) {
                // send token0 to sender
                IERC20(pool.token0).safeTransfer(sender, _amount0);
            }
        }
        if (excessAmount1 > 0) {
            // send excess amount of token1 back to sender
            if (pool.token1 == address(0)) {
                sender.transfer(excessAmount1);
            } else {
                IERC20(pool.token1).safeTransfer(sender, excessAmount1);
            }
        }

        // send token1 to creator
        uint256 txFee = 0;
        uint256 _actualAmount1 = _amount1;
        if (pool.token1 == address(0)) {
            pool.creator.transfer(_actualAmount1);
        } else {
            IERC20(pool.token1).safeTransfer(pool.creator, _actualAmount1);
        }

        emit Swapped(index, sender, _amount0, _actualAmount1, txFee);
    }

    function creatorClaim(uint index) external
        nonReentrant
        isPoolExist(index)
        isPoolClosed(index)
    {
        require(pools[index].creator == msg.sender, "no permission");
        Pool memory pool = pools[index];

        uint unSwapAmount0 = pool.amountTotal0 - amountSwap0P[index];
        if (unSwapAmount0 > 0) {
            IERC20(pool.token0).safeTransfer(pool.creator, unSwapAmount0);
        }
        IERC20(pool.token1).safeTransfer(pool.creator, IERC20(pool.token1).balanceOf(address(this)));
        emit Claimed(index, msg.sender, amountSwap1P[index]);
    }

    function userClaim(uint index) external
        nonReentrant
        isPoolExist(index)
        isClaimReady(index)
    {
        Pool memory pool = pools[index];
        address sender = msg.sender;
        // require(!myClaimed[sender][index], "claimed");
        uint claimAmount = 0;
        if (myAmountSwapped0[sender][index] > 0) {
            // get sender claimable amount
            claimAmount = getClaimableAmount(index, sender);

            // send token0 to sender
            IERC20(pool.token0).safeTransfer(msg.sender, claimAmount);
        }
        // myClaimedAt[sender][index] = now;
        myClaimedAmount[sender][index] = myClaimedAmount[sender][index].add(claimAmount);
        emit UserClaimed(index, sender, claimAmount);
    }

    function _addWhitelist(uint index, address[] memory whitelist_, uint[] memory amounts) private {
        for (uint i = 0; i < whitelist_.length; i++) {
            whitelistP[index][whitelist_[i]] = amounts[i];
        }
    }

    function addWhitelist(uint index, address[] memory whitelist_, uint[] memory amounts) external {
        require(owner() == msg.sender || pools[index].creator == msg.sender, "no permission");
        _addWhitelist(index, whitelist_, amounts);
    }

    function removeWhitelist(uint index, address[] memory whitelist_) external {
        require(owner() == msg.sender || pools[index].creator == msg.sender, "no permission");
        for (uint i = 0; i < whitelist_.length; i++) {
            delete whitelistP[index][whitelist_[i]];
        }
    }

    function getPoolCount() public view returns (uint) {
        return pools.length;
    }

    function getClaimableAmount(uint index, address user) public view returns (uint) {
        Pool memory pool = pools[index];
        uint claimableAmount = 0;
        if (pool.closeAt > now || pool.claimAt == 0 || pool.claimAt > now) {
            return claimableAmount;
        }

        if (myAmountSwapped0[user][index] > 0) {
            uint purchaseAmount0 = myAmountSwapped0[user][index];
            uint unlockedAmount0 = purchaseAmount0.mul(now.sub(pool.claimAt).div(Lockup1Month)).mul(10).div(100);
            // Available 20% claim of purchase amount at TGE
            claimableAmount = purchaseAmount0.mul(20).div(100) + unlockedAmount0 - myClaimedAmount[user][index];
        }

        return claimableAmount;
    }

    function getMinValueOfBotHolder() public view returns (uint) {
        return config[MinValueOfBotHolder];
    }

    function getANNToken() public view returns (address) {
        return address(config[ANNToken]);
    }

    modifier isPoolClosed(uint index) {
        require(pools[index].closeAt <= now, "this pool is not closed");
        _;
    }

    modifier isPoolNotClosed(uint index) {
        require(pools[index].closeAt > now, "this pool is closed");
        _;
    }

    modifier isClaimReady(uint index) {
        require(pools[index].claimAt != 0, "invalid claim");
        require(pools[index].claimAt <= now, "claim not ready");
        _;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier checkANNHolder(uint index) {
        if (onlyANNHolderP[index]) {
            require(
                IERC20(getANNToken()).balanceOf(msg.sender) >= getMinValueOfBotHolder(),
                "Auction is not enough"
            );
        }
        _;
    }
}