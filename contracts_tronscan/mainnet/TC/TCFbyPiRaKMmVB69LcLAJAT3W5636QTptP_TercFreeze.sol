//SourceUnit: TercFreeze.sol

// SPDX-License-Identifier: ISC
pragma solidity ^0.5.4;

/// @title Contract for freezing TERC tokens
/// @author CryptoVarna
/// @notice The contract doesn't keep the tokens in itself but instead in a safe wallet
/// @dev All function calls are currently implemented without side effects
contract TercFreeze {

    uint8 public constant DEFAULT_PERIOD = 0;

    enum DepositStatus {
        FROZEN,
        AVAILABLE,
        UNFROZEN,
        EMERGENCY_UNFROZEN,
        CLOSED
    }

    struct Deposit {
        DepositStatus status;
        address holder;
        address recipient;
        uint64 amount;
        uint32 startDate;
        uint16 freezeDays;
        bool rewardsOnTop;
    }

    // Log
    mapping (bytes32 => Deposit) private _vault;

    // Main settings
    trcToken private _tokenId;
    address private _owner;
    address payable private _safeWallet;
    uint64 private _minAmount;

    // Freeze settings
    uint64[] private _freezeAmounts;
    uint16[] private _freezeDays;

    // Events
    event FreezePeriodsChanged(uint64[] freezeAmounts, uint16[] freezeDays);
    event TokensFrozen(address holder, address recipient, uint64 amount, uint16 freezeDays, uint32 startDate, uint32 endDate, bool rewardsOnTop, bytes32 key);
    event DepositStatusChanged(address holder, address recipeint, DepositStatus newStatus, bytes32 key);

    /// Allowes only owner to perform the action
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    /// Constructor
    /// @param tokenId ID of the TERC token
    /// @param safeWallet Address of the wallet where the funds will be kept
    constructor(uint256 tokenId, address payable safeWallet, uint64 minAmount, uint64[] memory freezeAmounts, uint16[] memory freezeDays) public {
        require(tokenId > 1000000, "Invalid token");
        require(safeWallet != address(0), "Invalid address");
        _tokenId = tokenId;
        _owner = msg.sender;
        _safeWallet = safeWallet;
        _minAmount = minAmount;
        setFreezePeriods(freezeAmounts, freezeDays);
    }

    /// Returns the Token ID 
    /// @return trcToken ID
    function tokenId() public view returns (trcToken) {
        return _tokenId;
    }

    /// Returns the owner of the contract
    /// @return address of the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// Returns the address of the safe wallet where all funds are kept
    /// @return address of the wallet
    function safeWallet() public view returns (address) {
        return _safeWallet;
    }

    /// Returns the address of the safe wallet where all funds are kept
    /// @return address of the wallet
    function minAmount() public view returns (uint64) {
        return _minAmount;
    }

    /// Sets the min deposit amount    
    /// @dev only owner can set this
    /// @param newMinAmount new amount
    function setMinAmount(uint64 newMinAmount) external onlyOwner {
        _minAmount = newMinAmount;
    }    

    /// Returns the deposit duration in days allowed for an amount
    /// @param amount Amount of the deposit
    /// @param periodIndex Preferred index from the list of periods
    /// @return uint16 freeze days
    function getFreezeDays(uint64 amount, uint8 periodIndex) public view returns(uint16) {
        uint256 i = _freezeAmounts.length-1;
        while (i > 0 && amount < _freezeAmounts[i]) {
            i --;
        }

        // if period preference is set use it if possible
        if (periodIndex != DEFAULT_PERIOD) {
            require(periodIndex-1 <= i, "Not enough funds for that period");
            i = periodIndex-1;
        }
        return _freezeDays[i];        
    }

    /// Calculates the end date of a deposit
    /// @param startDate Start date of the deposit
    /// @param freezeDays Deposit duration in days
    /// @return uint256 end date
    function getEndDate(uint32 startDate, uint16 freezeDays) public pure returns (uint32) {
        return startDate + freezeDays * 1 days;
    }

    /// Returns the count of the deposits an address has
    /// @return uint256 the count of the deposits
    function getMyDepositsCount() public view returns(uint256) {
        return _findDepositsCount(msg.sender);
    }

    function makeKey(address holder, uint256 index) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }
 
    /// Returns a deposit by key
    /// @param byKey Key of the deposit
    /// @dev if the deposit is not found an error is thrown
    /// @return DepositInfo 
    function getDeposit(bytes32 byKey) public view returns(DepositStatus status, address holder, address recipient, uint64 amount, uint32 startDate, uint16 freezeDays, bool rewardsOnTop, bytes32 key) {
        Deposit memory d = _vault[byKey];  
        require(d.amount > 0, "No deposit found");
        uint32 endDate = getEndDate(d.startDate, d.freezeDays);
        status = (d.status == DepositStatus.FROZEN && now >= endDate) ? DepositStatus.AVAILABLE : d.status;
        holder = d.holder;
        recipient = d.recipient;
        amount = d.amount;
        startDate = d.startDate;
        freezeDays = d.freezeDays;
        rewardsOnTop = d.rewardsOnTop;
        key = byKey;
    }

    /// Returns my deposit by index
    /// @param index Index of the deposit
    /// @dev if the deposit is not found an error is thrown
    /// @return DepositInfo 
    function getMyDeposit(uint256 index) external view returns(DepositStatus status, address holder, address recipient, uint64 amount, uint32 startDate, uint16 freezeDays, bool rewardsOnTop, bytes32 key) {
        (
            status,
            holder,
            recipient,
            amount,
            startDate,
            freezeDays,
            rewardsOnTop,
            key) = getDeposit(makeKey(msg.sender, index));
    }

    /// Returns the freeze periods defined for freezing
    /// @return (uint256[], uint256[]) Array of freeze amounts and days
    function getFreezePeriods() public view returns(uint64[] memory freezeAmounts, uint16[] memory freezeDays) {
        freezeAmounts = _freezeAmounts;
        freezeDays = _freezeDays;
    }

    /// Sets the freeze periods
    /// @param freezeAmounts Array of the amounts in the format [200, 3000, 10000]
    /// @param freezeDays Array of the days to freeze in the format [1, 30, 365]
    /// @dev Only owner
    function setFreezePeriods(uint64[] memory freezeAmounts, uint16[] memory freezeDays) onlyOwner public {
        require(freezeAmounts.length == freezeDays.length, "Input arrays size doesn't match");
        require(freezeAmounts.length > 0, "At least one period is required");
        _freezeAmounts = freezeAmounts;
        _freezeDays = freezeDays;
        emit FreezePeriodsChanged(_freezeAmounts, _freezeDays);
    }

    /// Receives TERC tokens, sends them to the safe wallet and keeps a long of the deposit
    /// @dev In this method the period cannot be changed
    function() external payable {
        _freezeTokens(0, msg.sender, msg.sender, uint64(msg.tokenvalue), msg.tokenid, DEFAULT_PERIOD, false);
    }

    /// Receives TERC tokens, sends them to the safe wallet and keeps a long of the deposit
    /// @param period default (0) or other period from the list of freeze periods prefferred.
    /// @param recipient address where the reward will be paid
    /// @param rewardsOnTop determines wether the rewards will be transferred on top of the contract
    /// @dev Here the period can be chosen
    /// @return bool, true on success
    function freezeTokens(uint8 period, address recipient, bool rewardsOnTop) public payable returns(bytes32) {
        return _freezeTokens(0, msg.sender, recipient, uint64(msg.tokenvalue), msg.tokenid, period, rewardsOnTop);
    }

    /// Receives TERC tokens, sends them to the safe wallet and keeps a long of the deposit
    /// @param period default (0) or other period from the list of freeze periods prefferred.
    /// @param recipient address where the reward will be paid
    /// @param rewardsOnTop determines wether the rewards will be transferred on top of the contract
    /// @dev Here the period can be chosen
    /// @return bool, true on success
    function addTokensToDeposit(bytes32 key, uint8 period, address recipient, bool rewardsOnTop) public payable {
        _freezeTokens(key, msg.sender, recipient, uint64(msg.tokenvalue), msg.tokenid, period, rewardsOnTop);
    }

    /// Tries to unfreeze the tokens and if the time has expired the deposit is marked as UNFROZEN
    /// @param key Key of the deposit
    /// @return bool, true on success
    function unfreezeTokens(bytes32 key) public {
        _unfreezeTokens(msg.sender, key, false);
    }

    /// Unfreezes the tokens by emergency and sets the status of the deposit to EMERGENCY_UNFROZEN
    /// @param key Key of the deposit
    /// @return bool, true on success
    function emergencyUnfreezeTokens(bytes32 key) public {
        _unfreezeTokens(msg.sender, key, true);
    }

    /// Closes a deposit if it is available or unfrozen
    /// @param key Key of the deposit
    /// @dev the deposit can be deleted only if its status is not FROZEN
    /// @return bool, true on success
    function closeDeposit(bytes32 key) public onlyOwner {
        Deposit storage d = _vault[key];
        require(d.amount > 0, "This deposit cannot be found");
        require(d.status != DepositStatus.FROZEN, "You can't close a frozen deposit");
        require(d.status != DepositStatus.CLOSED, "You can't close a closed deposit");

        // Concider deleting 
        d.status = DepositStatus.CLOSED;

        emit DepositStatusChanged(d.holder, d.recipient, DepositStatus.CLOSED, key);
    }

    function _freezeTokens(bytes32 key, address sender, address recipient, uint64 value, trcToken token, uint8 period, bool rewardsOnTop) private returns(bytes32) {
        require(recipient != address(0), "Invalid recipient provided");
        require(token == _tokenId, "The contract doesn't support this token");
        require(value >= _minAmount, "Not enough coins sent");

        _safeWallet.transferToken(value, _tokenId);

        uint32 startDate;
        uint16 freezeDays;
        uint32 endDate;
        bytes32 newKey;
        
        Deposit storage d = _vault[key];
        if (d.holder != address(0)) {
            // Update existing deposit
            require(d.status == DepositStatus.FROZEN, "Invalid deposit state");
            newKey = key;
            startDate = d.startDate;
            value += d.amount;
            freezeDays = getFreezeDays(value, period);
            require(freezeDays >= d.freezeDays, "You cannot select shorter period");
            endDate = getEndDate(startDate, freezeDays);
            d.recipient = recipient;
            d.rewardsOnTop = rewardsOnTop;
            d.freezeDays = freezeDays;
            d.amount = value;
        } else {
            // Create new
            startDate = uint32(now);
            freezeDays = getFreezeDays(value, period);
            endDate = getEndDate(startDate, freezeDays);
            uint256 count = _findDepositsCount(sender);
            newKey = makeKey(sender, count);
            _vault[newKey] = Deposit(DepositStatus.FROZEN, sender, recipient, value, startDate, freezeDays, rewardsOnTop);
        }

        emit TokensFrozen(sender, recipient, value, freezeDays, startDate, endDate, rewardsOnTop, newKey);

        return newKey;
    }
    
    function _unfreezeTokens(address sender, bytes32 key, bool emergency) private {
        Deposit storage d = _vault[key];
        require(d.holder == sender, "This deposit doesn't exist");

        uint32 endDate = getEndDate(d.startDate, d.freezeDays);
        d.status = DepositStatus.UNFROZEN;
        if (emergency == true) {
            if (now < endDate) {
                d.status = DepositStatus.EMERGENCY_UNFROZEN;
            }
        } else {
            require(now >= endDate, "The deposit period hasn't expired yet");
        }

        emit DepositStatusChanged(sender, d.recipient, d.status, key);
    }    

    function _findDepositsCount(address holder) public view returns(uint256) {
        uint256 count = 0;
        bytes32 lastKey = makeKey(holder, count);
        while (_vault[lastKey].amount > 0) {
            count ++;
            lastKey = makeKey(holder, count);
        }
        return count;
    }
}