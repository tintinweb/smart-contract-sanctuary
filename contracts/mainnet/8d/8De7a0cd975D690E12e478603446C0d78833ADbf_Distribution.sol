/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity 0.4.24;

contract Ownable {
    address public owner;
    address public pendingOwner;
    mapping(address => bool) public managers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetManager(address indexed owner, address indexed newManager);
    event RemoveManager(address indexed owner, address indexed previousManager);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "non-owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than a manager.
     */
    modifier onlyManager() {
        require(managers[msg.sender], "non-manager");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns true if the user(`account`) is the a manager.
     */
    function isManager(address _account) public view returns (bool) {
        return managers[_account];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner_`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != owner, "transferOwnership: the same owner.");
        require(pendingOwner != _newOwner, "transferOwnership : the same pendingOwner.");
        pendingOwner = _newOwner;
    }

    /**
     * @dev Accepts ownership of the contract.
     * Can only be called by the settting new owner(`pendingOwner`).
     */
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "AcceptOwnership: only new owner do this.");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Set a new user(`account`) as a manager.
     * Can only be called by the current owner.
     */
    function setManager(address _account) external onlyOwner {
        require(_account != address(0), "setManager: account cannot be a zero address.");
        require(!isManager(_account), "setManager: Already a manager address.");
        managers[_account] = true;
        emit SetManager(owner, _account);
    }

    /**
     * @dev Remove a previous manager account.
     * Can only be called by the current owner.
     */
    function removeManager(address _account) external onlyOwner {
        require(_account != address(0), "RemoveManager: _account cannot be a zero address.");
        require(isManager(_account), "RemoveManager: Not an admin address.");
        managers[_account] = false;
        emit RemoveManager(owner, _account);
    }
}

contract Pausable is Ownable {
    bool public paused;

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        paused = false;
    }

    /**
     * @dev Called by the contract owner to pause, triggers stopped state.
     */
    function pause() public whenNotPaused onlyOwner {
        paused = true;
        emit Paused(owner);
    }

    /**
     * @dev Called by the contract owner to unpause, returns to normal state.
     */
    function unpause() public whenPaused onlyOwner {
        paused = false;
        emit Unpaused(owner);
    }
}

interface IERC20 {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
    function balanceOf(address account) external view returns (uint);
    function decimals() external view returns (uint);
}

contract ERC20SafeTransfer {
    function doTransferOut(address _token, address _to, uint _amount) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transfer(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doTransferFrom(address _token, address _from, address _to, uint _amount) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transferFrom(_from, _to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }
}

contract ILendfMeData {
    function getLiquidity(address account) public view returns (int);
}

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
    }
}

contract Distribution is Pausable, ERC20SafeTransfer {
    using DSMath for uint;
    // --- Data ---
    bool private initialized;                   // Flag of initialize data.

    address public DF;
    address public LendfMeData;

    uint public start;                          // When will the contract start.
    uint public step;                           // Duration of each period.

    uint[] public distributionRatio;            // Accumulated distribution ratio based on every period.
    uint public totalRatio;

    uint public totalAmount;                    // Total amount of asset to distribute.
    uint public totalLockedValue;               // Total net value.
    mapping (address => uint) public claimed;   // Amount that user has claimed.
    uint public totalClaimed;                   // Total amount of asset has claimed.

    /**
     * @dev emitted when user cliams.
     */
    event Claim(address _src, uint _amount);

    /**
     * @dev Modifier to make a function callable only when the contract is not expired.
     */
    modifier unclocked() {
        require(start + step * distributionRatio.length.sub(1) >= now, "unclocked: Contract has been locked!");
        _;
    }

    /**
     * The constructor is used here to ensure that the implementation contract is initialized.
     * An uncontrolled implementation contract might lead to misleading state for users who
     * accidentally interact with it.
     */
    constructor(
        address _token,
        uint _totalAmount,
        address _lendfMeData,
        uint _totalLockedValue,
        uint _start,
        uint _step,
        uint[] memory _distributionRatio
    ) public {
        initialize(_token, _totalAmount, _lendfMeData, _totalLockedValue, _start, _step, _distributionRatio);
    }

    // --- Init ---
    // This function is used with contract proxy, do not modify this function.
    function initialize(
        address _token,
        uint _totalAmount,
        address _lendfMeData,
        uint _totalLockedValue,
        uint _start,
        uint _step,
        uint[] memory _distributionRatio
    ) public {
        require(!initialized, "initialize: Already initialized.");
        owner = msg.sender;
        managers[msg.sender] = true;
        initialized = true;
        DF = _token;
        totalAmount = _totalAmount;
        LendfMeData = _lendfMeData;
        totalLockedValue = _totalLockedValue;
        start = _start;
        step = _step;
        setDistributionRatio(_distributionRatio);
    }

    // ***************************
    // **** Manager functions ****
    // ***************************

    /**
     * @dev Manager function to set which asset will be distributed.
     * @param _token Asset that users will get by claiming.
     */
    function setToken(address _token) external onlyManager {
        require(DF != _token, "setToken: Asset is same as the previous!");
        DF = _token;
    }

    function setTotalAmount(uint _totalAmount) external onlyManager {
        require(totalAmount < _totalAmount, "setTotalAmount: New total amount should be greater than previous!");
        totalAmount = _totalAmount;
    }

    function setLendfMeData(address _lendfMeData) external onlyManager {
        require(LendfMeData != _lendfMeData, "setLendfMeData: New data contract should be different!");
        LendfMeData = _lendfMeData;
    }

    function setTotalLiquidity(uint _totalLockedValue) external onlyManager {
        require(totalLockedValue < _totalLockedValue,
                "setTotalLiquidity: New locked value should be greater than previous!");
        totalLockedValue = _totalLockedValue;
    }

    function setStartTime(uint _start) external onlyManager {
        require(start != _start, "setStartTime: New start time should be different!");
        start = _start;
    }

    function setStep(uint _step) external onlyManager {
        require(step != _step, "setStep:  New step should be different!");
        step = _step;
    }

    /**
     * @dev Manager function to set distribution ratio.
     * @param _distributionRatio Array that distribution ratio at each period.
     */
    function setDistributionRatio(uint[] memory _distributionRatio) public onlyManager {
        delete distributionRatio;
        // first set to 0, cause contract does not support claim yet.
        distributionRatio.push(0);
        uint _sum;
        for (uint i = 0; i < _distributionRatio.length; i++) {
            _sum = _sum.add(_distributionRatio[i]);
            distributionRatio.push(_sum);
        }
        // last set to 0, cause contract has experid.
        distributionRatio.push(0);
        totalRatio = _sum;
    }

    // ***************************
    // ***** Owner functions *****
    // ***************************

    /**
     * @dev Owner function to transfer asset`_token` out when contract has expired.
     * @param _token Reserve asset, generally spaking it should be DF.
     * @param _recipient Account to receive asset.
     * @param _amount Amount of asset to withdraw.
     */
    function removeReserve(address _token, address _recipient, uint _amount) external onlyOwner {
        require(start + step * distributionRatio.length.sub(1) < now, "removeReserve: Too early to remove!");
        require(doTransferOut(_token, _recipient, _amount), "removeReserve: Transfer out failed!");
    }

    /**
     * @dev Owner function to transfer asset`_token` to this contract to start or move on.
     * @param _amount Amount of asset to add.
     */
    function addReserve(uint _amount) external onlyOwner {
		require(doTransferFrom(DF, msg.sender, address(this), _amount), "addReserve: TransferFrom failed!");
	}

    // **************************
    // *** Internal functions ***
    // **************************

    /**
     * @dev Claims to get specified amount of asset, but only when the contract is not paused and not expired.
     * @param _src Account who will receive distributed asset.
     * @param _amount Amount to claim, scaled by 1e18.
     */
    function claim(address _src, uint _amount) internal whenNotPaused unclocked {
        require(_amount > 0, "claim: Amount to claim should be greater than 0!");
        claimed[_src] = claimed[_src].add(_amount);
        totalClaimed = totalClaimed.add(_amount);
        emit Claim(_src, _amount);

        require(doTransferOut(DF, _src, _amount), "claim(address,uint): Transfer failed!");
    }

    // **************************
    // **** Public functions ****
    // **************************

    /**
     * @dev Gets all distributed asset during one distributing period.
     */
    function claim() external {
        address _src = msg.sender;
        claim(_src, getCurrentClaimableAmount(_src));
    }

    /**
     * @dev Gets some distributed asset.
     * @param _amount Amount that user wants to claim.
     */
    function claim(uint _amount) external {
        address _src = msg.sender;
        require(getCurrentClaimableAmount(_src) >= _amount, "claim(uint): Too large amount to claim!");
        claim(_src, _amount);
    }

    /**
     * @dev Returns account liquidity in terms of eth-wei value, scaled by 1e18.
     * @param _src The account to examine.
     */
    function getAccountLiquidity(address _src) public view returns (uint) {
        int _liquidity = ILendfMeData(LendfMeData).getLiquidity(_src);
        if (_liquidity <= 0)
            return 0;
        return uint(_liquidity);
    }

    /**
     * @dev Returns amount of released asset up to now.
     */
    function getCurrentUnlockedAmount() public view returns (uint) {
        if (step == 0)
            return 0;
        uint _stage = now > start ? (now - start).div(step) : 0;
        if (_stage >= distributionRatio.length)
            return 0;
        return totalAmount.mul(distributionRatio[_stage]).div(totalRatio);
    }

    /**
     * @dev Returns total amount that user`_src` can claim based on `_unlockAmount`.
     * @param _src The account to examine.
     * @param _unlockAmount Released amount during current period.
     */
    function calculateClaimableAmount(address _src, uint _unlockAmount) public view returns (uint) {
        return getAccountLiquidity(_src).mul(_unlockAmount).div(totalLockedValue);
    }

    /**
     * @dev Returns maximum valid amount that user`_src` can claim up to now.
     * @param _src The account to examine.
     */
    function getCurrentClaimableAmount(address _src) public view returns (uint) {
        uint _amount = calculateClaimableAmount(_src, getCurrentUnlockedAmount());
        return _amount < claimed[_src] ? 0 : _amount.sub(claimed[_src]);
    }

    /**
     * @dev Returns total amount that user`_src` can claim at the current period.
     * @param _src The account to examine.
     */
    function getTotalClaimableAmount(address _src) public view returns (uint) {
        uint _amount = calculateClaimableAmount(_src, totalAmount);
        return start + step * distributionRatio.length.sub(1) < now ? 0 : (_amount < claimed[_src] ? 0 : _amount.sub(claimed[_src]));
    }

    /**
     * @dev Returns remaining amount that user`_src` can claim up to now.
     * @param _src The account to examine.
     */
    function getUnclaimedAmount(address _src) external view returns (uint) {
        return getTotalClaimableAmount(_src).sub(getCurrentClaimableAmount(_src));
    }

    /**
     * @dev Returns details that user`_src` claims.
     * @param _src The account to examine.
     * @return uint[] Array that start times for each period.
     *         uint[] Array that the maximum amount to claim in every period.
     */
    function getClaimableList(address _src) external view returns (uint[] memory, uint[] memory) {

        uint _length = distributionRatio.length - 2;
        uint[] memory _timeList = new uint[](_length);
        uint[] memory _amountList = new uint[](_length);
        uint _start = start;
        uint _step = step;
        for (uint i = 1; i <= _length; i++) {
            _timeList[i - 1] = _start + i * _step;
            _amountList[i - 1] = calculateClaimableAmount(_src, totalAmount.mul(distributionRatio[i].sub(distributionRatio[i - 1])).div(totalRatio));
        }

        return(_timeList, _amountList);
    }

    /**
     * @dev Returns remaining period details that user`_src` can claim.
     * @param _src The account to examine.
     * @return uint[] Array that start times for each remaining period.
     *         uint[] Array that the maximum amount to claim in every remaining period.
     */
    function getRemainingClaimableList(address _src) external view returns (uint[] memory, uint[] memory) {

        uint _start = start;
        uint _step = step;
        uint _stage = now > _start.add(_step) ? (now - _start).div(_step) : 0;
        uint _length = distributionRatio.length - 2;
        _length = _length < _stage ? 0 : _length - _stage;
        uint[] memory _timeList = new uint[](_length);
        uint[] memory _amountList = new uint[](_length);
        for (uint i = 1; i <= _length; i++) {
            _timeList[i - 1] = _start + (_stage + i) * _step;
            _amountList[i - 1] = calculateClaimableAmount(_src, totalAmount.mul(distributionRatio[_stage + i].sub(distributionRatio[_stage + i - 1])).div(totalRatio));
        }

        return(_timeList, _amountList);
    }

    /**
     * @dev Returns current period.
     */
    function getCurrentStage() external view returns (uint) {
        uint _stage = now > start ? (now - start).div(step) : 0;
        return _stage > distributionRatio.length ? distributionRatio.length : _stage;
    }

    /**
     * @dev Returns basic contract data.
     * @return uint Total net value of the LendfMe contract.
     *         uint Toal net value of user`_src`.
     *         uint Maximun amount that user`_src` can claim during this distribution.
     *         uint Remaining amount that user`_src` can claim up to now.
     *         uint Amount that user has claimed.
     *         uint Maximum valid amount that user`_src` can claim up to now.
     */
    function getDistributionData(address _src) external view returns (uint, uint, uint, uint, uint, uint) {
        uint _shareAmount = calculateClaimableAmount(_src, totalAmount);
        uint _unlockedAmount = calculateClaimableAmount(_src, getCurrentUnlockedAmount());
        return (
            totalLockedValue,
            getAccountLiquidity(_src),
            _shareAmount,
            _shareAmount > _unlockedAmount ? _shareAmount - _unlockedAmount : 0,
            claimed[_src],
            getCurrentClaimableAmount(_src)
        );
    }
}