/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}


/// @title The interface for Graviton OTC contract
/// @notice Exchanges ERC20 token for GTON with a linear unlocking schedule
/// @author Anton Davydov - <[email protected]>
interface IOTC {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Address of GTON
    function base() external view returns (IERC20);

    /// @notice Address of ERC20 token to sell GTON for
    function quote() external view returns (IERC20);

    /// @notice amount of quote tokens needed to receive one GTON
    function price() external view returns (uint256);

    /// @notice last time price was updated
    function setPriceLast() external view returns (uint256);

    /// @notice updates price
    function setPrice(uint256 _price) external;

    /// @notice Look up if `user` is allowed to set price
    function canSetPrice(address user) external view returns (bool);

    /// @notice Sets `setter` permission to open new governance balances to `_canSetPrice`
    /// @dev Can only be called by the current owner.
    function setCanSetPrice(address setter, bool _canSetPrice) external;

    /// @notice Minimum amount of GTON to exchange
    function lowerLimit() external view returns (uint256);

    /// @notice Maximum amount of GTON to exchange
    function upperLimit() external view returns (uint256);

    /// @notice last time limits were updated
    function setLimitsLast() external view returns (uint256);

    /// @notice updates exchange limits
    function setLimits(uint256 _lowerLimit, uint256 _upperLimit) external;

    /// @notice claim starting time to set for otc deals
    function cliffAdmin() external view returns (uint256);

    /// @notice total vesting period to set for otc deals
    function vestingTimeAdmin() external view returns (uint256);

    /// @notice number of claims over vesting period to set for otc deals
    function numberOfTranchesAdmin() external view returns (uint256);

    /// @notice last time vesting parameters were updated
    function setVestingParamsLast() external view returns (uint256);

    /// @notice updates vesting parameters
    /// @param _cliff claim starting time
    /// @param _vestingTimeAdmin total vesting period
    /// @param _numberOfTranchesAdmin number of claims over vesting period
    function setVestingParams(
        uint256 _cliff,
        uint256 _vestingTimeAdmin,
        uint256 _numberOfTranchesAdmin
    ) external;

    /// @notice beginning of vesting period for `account`
    function startTime(address account) external view returns (uint256);

    /// @notice claim starting time set for otc deal with `account`
    function cliff(address account) external view returns (uint256);

    /// @notice total vesting period set for otc deal with `account`
    function vestingTime(address account) external view returns (uint256);

    /// @notice number of claims over vesting period set for otc deal with `account`
    function numberOfTranches(address account) external view returns (uint256);

    /// @notice amount of GTON vested for `account`
    function vested(address account) external view returns (uint256);

    /// @notice amount of GTON claimed by `account`
    function claimed(address account) external view returns (uint256);

    /// @notice last time GTON was claimed by `account`
    function claimLast(address account) external view returns (uint256);

    /// @notice total amount of vested GTON
    function vestedTotal() external view returns (uint256);

    /// @notice amount of GTON claimed by all accounts
    function claimedTotal() external view returns (uint256);

    /// @notice exchanges quote tokens for vested GTON according to a set price
    /// @param amount amount of GTON to exchange
    function exchange(uint256 amount) external;

    /// @notice transfers a share of vested GTON to the caller
    function claim() external;

    /// @notice transfers quote tokens to the owner
    function collect() external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the owner updates the price via `#setPrice`.
    /// @param _price amount of quote tokens needed to receive one GTON
    event SetPrice(uint256 _price);

    /// @notice Event emitted when the `setter` permission is updated via `#setCanSetPrice`
    /// @param owner The owner account at the time of change
    /// @param setter The account whose permission to set price was updated
    /// @param newBool Updated permission
    event SetCanSetPrice(
        address indexed owner,
        address indexed setter,
        bool indexed newBool
    );

    /// @notice Event emitted when the owner updates exchange limits via `#setLimits`.
    /// @param _lowerLimit minimum amount of GTON to exchange
    /// @param _upperLimit maximum amount of GTON to exchange
    event SetLimits(uint256 _lowerLimit, uint256 _upperLimit);

    /// @notice Event emitted when the owner updates vesting parameters via `#setVestingParams`.
    /// @param _cliffAdmin claim starting time to set for otc deals
    /// @param _vestingTimeAdmin total vesting period to set for otc deals
    /// @param _numberOfTranchesAdmin number of tranches to set for otc deals
    event SetVestingParams(uint256 _cliffAdmin, uint256 _vestingTimeAdmin, uint256 _numberOfTranchesAdmin);

    /// @notice Event emitted when OTC exchange is initiated via `#exchange`.
    /// @param account account that initiated the exchange
    /// @param amountQuote amount of quote tokens that `account`
    /// transfers to the contract
    /// @param amountBase amount of GTON vested for `account`
    /// in exchange for quote tokens
    event Exchange(address account, uint256 amountQuote, uint256 amountBase);

    /// @notice Event emitted when an account claims vested GTON via `#Claim`.
    /// @param account account that initiates OTC exchange
    /// @param amount amount of base tokens that the account claims
    event Claim(address account, uint256 amount);

    /// @notice Event emitted when the owner collects quote tokens via `#Collect`.
    /// @param amount amount of quote tokens that the owner collects
    event Collect(uint256 amount);
}


/// @title OTC
/// @author Anton Davydov - <[email protected]>
contract OTC is IOTC {
    /// @inheritdoc IOTC
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IOTC
    IERC20 public override base;
    /// @inheritdoc IOTC
    IERC20 public override quote;

    uint256 public quoteDecimals;
    /// @inheritdoc IOTC
    uint256 public override price;
    /// @inheritdoc IOTC
    uint256 public override setPriceLast;
    /// @inheritdoc IOTC
    mapping (address => bool) public override canSetPrice;
    /// @inheritdoc IOTC
    uint256 public override lowerLimit;
    /// @inheritdoc IOTC
    uint256 public override upperLimit;
    /// @inheritdoc IOTC
    uint256 public override setLimitsLast;
    /// @inheritdoc IOTC
    uint256 public override cliffAdmin;
    /// @inheritdoc IOTC
    uint256 public override vestingTimeAdmin;
    /// @inheritdoc IOTC
    uint256 public override numberOfTranchesAdmin;
    /// @inheritdoc IOTC
    uint256 public override setVestingParamsLast;

    string public VERSION;

    struct Deal {
        uint256 startTime;
        uint256 cliff;
        uint256 vestingTime;
        uint256 numberOfTranches;
        uint256 vested;
        uint256 claimed;
        uint256 claimLast;
    }

    mapping(address => Deal) internal deals;
    /// @inheritdoc IOTC
    uint256 public override vestedTotal;
    /// @inheritdoc IOTC
    uint256 public override claimedTotal;

    uint256 DAY = 86400;

    constructor(
        IERC20 _base,
        IERC20 _quote,
        uint256 _quoteDecimals,
        uint256 _price,
        uint256 _lowerLimit,
        uint256 _upperLimit,
        uint256 _cliffAdmin,
        uint256 _vestingTimeAdmin,
        uint256 _numberOfTranchesAdmin,
        string memory _VERSION
    ) {
        owner = msg.sender;
        base = _base;
        quote = _quote;
        quoteDecimals = _quoteDecimals;
        price = _price;
        lowerLimit = _lowerLimit;
        upperLimit = _upperLimit;
        setPriceLast = _blockTimestamp();
        setLimitsLast = _blockTimestamp();
        setVestingParamsLast = _blockTimestamp();
        canSetPrice[msg.sender] = true;
        cliffAdmin = _cliffAdmin;
        vestingTimeAdmin = _vestingTimeAdmin;
        numberOfTranchesAdmin = _numberOfTranchesAdmin;
        VERSION = _VERSION;
    }

    /// @inheritdoc IOTC
    function startTime(address account) external view override returns (uint256) {
        return deals[account].startTime;
    }

    /// @inheritdoc IOTC
    function cliff(address account) external view override returns (uint256) {
        return deals[account].cliff;
    }

    /// @inheritdoc IOTC
    function vestingTime(address account) external view override returns (uint256) {
        return deals[account].vestingTime;
    }

    /// @inheritdoc IOTC
    function numberOfTranches(address account) external view override returns (uint256) {
        return deals[account].numberOfTranches;
    }

    /// @inheritdoc IOTC
    function vested(address account) external view override returns (uint256) {
        return deals[account].vested;
    }

    /// @inheritdoc IOTC
    function claimed(address account) external view override returns (uint256) {
        return deals[account].claimed;
    }

    /// @inheritdoc IOTC
    function claimLast(address account) external view override returns (uint256) {
        return deals[account].claimLast;
    }

    /// @dev Returns the block timestamp. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc IOTC
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IOTC
    function setPrice(uint256 _price) external override {
        require(_blockTimestamp()-setPriceLast > DAY, "OTC1");
        require(canSetPrice[msg.sender], "ACS");
        setPriceLast = _blockTimestamp();
        price = _price;
        emit SetPrice(_price);
    }

    /// @inheritdoc IOTC
    function setCanSetPrice(address setter, bool _canSetPrice)
        external
        override
        isOwner
    {
        canSetPrice[setter] = _canSetPrice;
        emit SetCanSetPrice(msg.sender, setter, canSetPrice[setter]);
    }

    /// @inheritdoc IOTC
    function setLimits(uint256 _lowerLimit, uint256 _upperLimit) external override isOwner {
        require(_blockTimestamp()-setLimitsLast > DAY, "OTC2");
        setLimitsLast = _blockTimestamp();
        lowerLimit = _lowerLimit;
        upperLimit = _upperLimit;
        emit SetLimits(_lowerLimit, _upperLimit);
    }

    /// @inheritdoc IOTC
    function setVestingParams(
        uint256 _cliffAdmin,
        uint256 _vestingTimeAdmin,
        uint256 _numberOfTranchesAdmin
    ) external override isOwner {
        require(_blockTimestamp()-setVestingParamsLast > DAY, "OTC3");
        setVestingParamsLast = _blockTimestamp();
        cliffAdmin = _cliffAdmin;
        vestingTimeAdmin = _vestingTimeAdmin;
        numberOfTranchesAdmin = _numberOfTranchesAdmin;
        emit SetVestingParams(_cliffAdmin, _vestingTimeAdmin, _numberOfTranchesAdmin);
    }

    /// @inheritdoc IOTC
    function exchange(uint256 amountBase) external override {
        // assigning a struct is cheaper
        // than calling values from mapping multiple times like deals[msg.sender].vested
        Deal memory deal = deals[msg.sender];
        require(deal.vested == 0, "OTC4");
        uint256 undistributed = base.balanceOf(address(this)) - (vestedTotal - claimedTotal);
        require(amountBase <= undistributed, "OTC5");
        require(lowerLimit <= amountBase && amountBase <= upperLimit, "OTC6");
        deal.vested = amountBase;
        vestedTotal += amountBase;
        uint256 amountQuote = ((amountBase*price)/100)/(10**(18-quoteDecimals));
        require(amountQuote > 0, "OTC7");
        deal.cliff = cliffAdmin;
        deal.vestingTime = vestingTimeAdmin;
        deal.numberOfTranches = numberOfTranchesAdmin;
        deal.startTime = _blockTimestamp();
        deals[msg.sender] = deal;
        quote.transferFrom(msg.sender, address(this), amountQuote);
        emit Exchange(msg.sender, amountQuote, amountBase);
    }

    /// @inheritdoc IOTC
    function claim() external override {
        // assigning a struct is cheaper
        // than calling values from mapping multiple times like deals[msg.sender].vested
        Deal memory deal = deals[msg.sender];
        uint256 interval = deal.vestingTime / deal.numberOfTranches;
        require(_blockTimestamp()-deal.startTime > deal.cliff, "OTC8");
        require(_blockTimestamp()-deal.claimLast > interval, "OTC9");
        uint256 intervals = ((_blockTimestamp() - deal.startTime) / interval) + 1; // +1 to claim first interval right after the cliff
        uint256 intervalsAccrued = intervals < deal.numberOfTranches ? intervals : deal.numberOfTranches; // min to cap after vesting time is over
        uint256 amount = ((deal.vested * intervalsAccrued) / deal.numberOfTranches) - deal.claimed;
        deal.claimed += amount;
        claimedTotal += amount;
        deal.claimLast = _blockTimestamp();
        deals[msg.sender] = deal;
        base.transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    /// @inheritdoc IOTC
    function collect() external override isOwner {
        uint256 amount = quote.balanceOf(address(this));
        quote.transfer(msg.sender, amount);
        emit Collect(amount);
    }
}