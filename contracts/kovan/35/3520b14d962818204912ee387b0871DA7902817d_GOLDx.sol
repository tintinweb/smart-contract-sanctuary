/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity 0.5.16;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
    event OwnerUpdate     (address indexed owner, address indexed newOwner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;
    address      public  newOwner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    // Warning: you should absolutely sure you want to give up authority!!!
    function disableOwnership() public onlyOwner {
        owner = address(0);
        emit OwnerUpdate(msg.sender, owner);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "AcceptOwnership: only new owner do this.");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    ///[snow] guard is Authority who inherit DSAuth.
    function setAuthority(DSAuthority authority_)
        public
        onlyOwner
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "ds-auth-non-owner");
        _;
    }

    function isOwner(address src) internal view returns (bool) {
        return bool(src == owner);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract Pausable is DSAuth {
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
        require(!paused, "whenNotPaused: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "whenPaused: not paused");
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
    function pause() public whenNotPaused auth {
        paused = true;
        emit Paused(owner);
    }

    /**
     * @dev Called by the contract owner to unpause, returns to normal state.
     */
    function unpause() public whenPaused auth {
        paused = false;
        emit Unpaused(owner);
    }
}

contract ReentrancyGuard {
    bool internal notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true
        require(notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        notEntered = true;
    }
}

interface IERC20 {
    function approve(address spender, uint amount) external;
    function transfer(address recipient, uint amount) external;
    function transferFrom(address sender, address recipient, uint amount) external;

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function decimals() external view returns (uint);
}

contract ERC20SafeTransfer {
    function doTransferOut(address _token, address _to, uint _amount) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool _result;

        token.transfer(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    _result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    _result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return _result;
    }

    function doTransferFrom(address _token, address _from, address _to, uint _amount) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool _result;

        token.transferFrom(_from, _to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    _result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    _result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return _result;
    }
}

interface IPAXG {
    function feeParts() external view returns (uint256);
    function feeRate() external view returns (uint256);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}

contract GOLDx is Pausable, ReentrancyGuard, ERC20SafeTransfer {
    using SafeMath for uint256;

    // --- ERC20 Data ---
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Data ---
    bool private initialized;           // Flags for initializing data

    address public token;               // Basic anchored asset
    address public pendingToken;        // New replacing anchored asset

    uint256 public unit;                // The exchange rate
    uint256 public pendingUnit;         // New exchange rate

    uint256 public minMintAmount;
    uint256 public minBurnAmount;
    uint256 public pendingMinMintAmount;
    uint256 public pendingMinBurnAmount;

    address public feeRecipient;
    mapping(bytes4 => uint256) public fee;
    mapping(address => bool) public blacklists;
    uint256 public upgradeTime;

    uint256 constant ONE = 10**18;

    // --- Event ---
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    event Mint(address indexed dst, uint256 pie);
    event Burn(address indexed src, uint256 wad);
    event FeeCollected(address indexed src, address indexed dst, uint256 value);

    event BlacklistAdded(address indexed account);
    event BlacklistRemoved(address indexed account);

    // --- Modifier ---
    /**
     * @dev Modifier to make a function callable when the contract is before upgrading.
     */
    modifier notUpgrading() {
        require(upgradeTime == 0 || upgradeTime > now, "notUpgrading: Upgrading!");
        _;
    }

    /**
     * The constructor is used here to ensure that the implementation contract is initialized.
     * An uncontrolled implementation contract might lead to misleading state for users
     * who accidentally interact with it.
     */
    constructor(string memory _name, string memory _symbol, address _token) public {
        initialize(_name, _symbol, _token);
    }

    // --- Init ---
    // This function is used with contract proxy, do not modify this function.
    function initialize(string memory _name, string memory _symbol, address _token) public {
        require(!initialized, "initialize: Already initialized!");
        name = _name;
        symbol = _symbol;
        token = _token;
        decimals = 18;
        owner = msg.sender;
        feeRecipient = msg.sender;
        notEntered = true;
        unit = 31103476800000000000;
        initialized = true;
    }

    // ******************************
    // **** Authorized functions ****
    // ******************************

    /**
     * @dev Authorized function to set a new exchange rate when wraps anchored asset to GOLDx.
     */
    function setUnit(uint256 _newUnit) external auth {
        require(_newUnit > 0, "setUnit: New unit should be greater than 0!");
        require(_newUnit != unit, "setUnit: New unit should be different!");
        unit = _newUnit;
    }

    /**
     * @dev Authorized function to set the minimum valid amount when mints GOLDx.
     */
    function setMinMintAmount(uint256 _minMintAmount) external auth {
        require(_minMintAmount != minMintAmount,
                "setMinMintAmount: New minimum minting amount should be different!");
        minMintAmount = _minMintAmount;
    }

    /**
     * @dev Authorized function to set the minimum valid amount when burns GOLDx.
     */
    function setMinBurnAmount(uint256 _minBurnAmount) external auth {
        require(_minBurnAmount != minBurnAmount,
                "setMinBurnAmount: New minimum burning amount should be different!");
        minBurnAmount = _minBurnAmount;
    }

    /**
     * @dev Authorized function to set a new account to receive fee.
     */
    function setFeeRecipient(address _feeRecipient) external auth {
        require(_feeRecipient != feeRecipient,
                "setFeeRecipient: New fee recipient should be different!");
        require(_feeRecipient != address(0),
                "setFeeRecipient: New fee recipient should not be zero address!");
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Authorized function to set fee for operation`_sig`.
     * @param _sig Function to set fee, and uses its selector to represent it.
     * @param _fee New fee when executes this function.
     */
    function setFee(bytes4 _sig, uint256 _fee) external auth {
        require(_fee != fee[_sig], "setFee: New fee should be different!");
        fee[_sig] = _fee;
    }

    /**
     * @dev Authorized function to add an account`_account` to the blacklist.
     * @param _account The address to the blacklist.
     */
    function addBlacklist(address _account) external auth {
        require(!blacklists[_account], "addBlacklist: Account has been in the blacklist!");
        blacklists[_account] = true;
        emit BlacklistAdded(_account);
    }

    /**
     * @dev Authorized function to remove an account`_account` from the blacklist.
     * @param _account The address to remove from the blacklist.
     */
    function removeBlacklist(address _account) external auth {
        require(blacklists[_account], "removeBlacklist: Account is not in the blacklist!");
        blacklists[_account] = false;
        emit BlacklistRemoved(_account);
    }

    /**
     * @dev Authorized function to set config for upgrading to new anchored asset.
     * @param _upgradeTime The timestamp when contract will upgrade protocol.
     * @param _token New anchored asset.
     * @param _unit New exchange rate when wraps new anchored asset to GOLDx.
     * @param _minMintAmount Minimum minting amount when uses the new anchored asset.
     * @param _minBurnAmount Minimum burning amount when uses the new anchored asset.
     */
    function upgradeProtocol(
        uint256 _upgradeTime,
        address _token,
        uint256 _unit,
        uint256 _minMintAmount,
        uint256 _minBurnAmount
    ) external auth {
        require(_upgradeTime > now, "upgradeProtocol: Upgrading time should be greater than now!");
        require(_token != address(0), "upgradeProtocol: New anchored asset should not be zero address!");
        upgradeTime = _upgradeTime;
        pendingToken = _token;
        pendingUnit = _unit;
        pendingMinMintAmount = _minMintAmount;
        pendingMinBurnAmount = _minBurnAmount;
    }

    /**
     * @dev Authorized function to remove current reserve only when reaches the upgrading time.
     */
    function removeReserve() external auth {
        require(upgradeTime > 0 && upgradeTime <= now, "removeReserve: Too early to remove reserve!");
        uint256 _balance = IERC20(token).balanceOf(address(this));
        if (_balance > 0) {
            require(doTransferOut(token, msg.sender, _balance), "removeReserve: Transfer out failed!");
        }
    }

    /**
     * @dev Authorized function to confirm upgrading only when exceeds the upgrading time.
     */
    function confirmUpgrade() external auth {
        require(upgradeTime > 0 && upgradeTime <= now, "confirmUpgrade:  Too early to confirm upgrading!");
        token = pendingToken;
        unit = pendingUnit;
        minMintAmount = pendingMinMintAmount;
        minBurnAmount = pendingMinBurnAmount;
        cancelUpgrade();
    }

    /**
     * @dev Authorized function to cancel upgrading.
     */
    function cancelUpgrade() public auth {
        require(getOutstanding() == 0, "cancelUpgrade: Add more current anchored asset!");
        upgradeTime = 0;
        pendingToken = address(0);
        pendingUnit = 0;
        pendingMinMintAmount = 0;
        pendingMinBurnAmount = 0;
    }

    /**
     * @dev Authorized function to retrieve asset from account in the blacklist.
     */
    function retrieveBlackAddress(address _address) external auth {
        require(blacklists[_address], "retrieveBlackAddress: Address is not frozen!");
        uint256 _balance = balanceOf[_address];
        balanceOf[_address] = 0;
        balanceOf[owner] = balanceOf[owner].add(_balance);
        emit Transfer(_address, owner, _balance);
    }

    /**
     * @dev Authorized function to wipe asset from account in the blacklist.
     */
    function wipeBlackAddress(address _address) external auth {
        require(blacklists[_address], "wipeBlackAddress: Address is not frozen!");
        uint256 _balance = balanceOf[_address];
        balanceOf[_address] = 0;
        totalSupply = totalSupply.sub(_balance);
        emit Transfer(_address, address(0), _balance);
    }

    // --- Math ---
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y) / ONE;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(ONE) / y;
    }

    // ****************************
    // **** Internal functions ****
    // ****************************
    /**
     * @dev Checks whether the preconditions are met.
     */
    function checkPrecondition(address _src, address _dst, uint256 _wad) internal {
        require(!blacklists[_src] && !blacklists[_dst], "checkPrecondition: Address is frozen!");
        require(balanceOf[_src] >= _wad, "checkPrecondition: Insufficient balance!");
        if (_src != _dst && allowance[_src][_dst] != uint256(-1)) {
            require(allowance[_src][_dst] >= _wad, "checkPrecondition: Insufficient allowance!");
            allowance[_src][_dst] = allowance[_src][_dst].sub(_wad);
        }
    }

    function transfer(address _src, address _dst, uint256 _wad) internal whenNotPaused notUpgrading {
        uint256 _fee = getFee(fee[this.transfer.selector], _wad);
        uint256 _principle = _wad.sub(_fee);
        balanceOf[_src] = balanceOf[_src].sub(_wad);
        balanceOf[_dst] = balanceOf[_dst].add(_principle);
        emit Transfer(_src, _dst, _principle);
        if (_fee > 0) {
            balanceOf[feeRecipient] = balanceOf[feeRecipient].add(_fee);
            emit FeeCollected(_src, feeRecipient, _fee);
        }
    }

    // **************************
    // **** Public functions ****
    // **************************
    /**
     * @dev Wraps anchored asset to get GOLDx.
     * @param _dst Account who will get GOLDx.
     * @param _pie Amount to mint, scaled by 1e18.
     */
    function mint(address _dst, uint256 _pie) external whenNotPaused notUpgrading nonReentrant {
        require(!blacklists[msg.sender] && !blacklists[_dst], "mint: Address is frozen!");
        uint256 _balance = IERC20(token).balanceOf(address(this));
        require(doTransferFrom(token, msg.sender, address(this), _pie), "mint: TransferFrom failed!");
        uint256 _wad = rmul(
            convertDecimals(
                IERC20(token).decimals(),
                decimals,
                IERC20(token).balanceOf(address(this)).sub(_balance)
            ),
            unit
        );
        require(_wad > 0 && _wad >= minMintAmount, "mint: Do not satisfy min minting amount!");
        uint256 _fee = getFee(fee[msg.sig], _wad);
        uint256 _principle = _wad.sub(_fee);
        balanceOf[_dst] = balanceOf[_dst].add(_principle);
        totalSupply = totalSupply.add(_wad);
        emit Transfer(address(0), _dst, _principle);
        emit Mint(_dst, _principle);
        if (_fee > 0) {
            balanceOf[feeRecipient] = balanceOf[feeRecipient].add(_fee);
            emit Transfer(address(0), feeRecipient, _fee);
            emit FeeCollected(address(0), feeRecipient, _fee);
        }
    }

    /**
     * @dev Unwraps GlodX to get anchored asset.
     * @param _src Account who will burn GOLDx.
     * @param _wad Amount to burn, scaled by 1e18.
     */
    function burn(address _src, uint256 _wad) external whenNotPaused notUpgrading {
        checkPrecondition(_src, msg.sender, _wad);
        require(_wad >= minBurnAmount, "burn: Do not satisfy min burning amount!");
        uint256 _fee = getFee(fee[msg.sig], _wad);
        uint256 _principle = _wad.sub(_fee);
        balanceOf[_src] = balanceOf[_src].sub(_wad);
        totalSupply = totalSupply.sub(_principle);
        emit Transfer(_src, address(0), _principle);
        emit Burn(_src, _principle);
        if (_fee > 0) {
            balanceOf[feeRecipient] = balanceOf[feeRecipient].add(_fee);
            emit Transfer(_src, feeRecipient, _fee);
            emit FeeCollected(_src, feeRecipient, _fee);
        }
        uint256 _pie = getRedeemAmount(_principle);
        if (_pie > 0) {
            require(doTransferOut(token, msg.sender, _pie), "burn: Transfer out failed!");
        }
    }

    // --- ERC20 ---
    function transfer(address _dst, uint256 _wad) external returns (bool) {
        return transferFrom(msg.sender, _dst, _wad);
    }

    function transferFrom(address _src, address _dst, uint256 _wad) public returns (bool) {
        checkPrecondition(_src, msg.sender, _wad);
        transfer(_src, _dst, _wad);
        return true;
    }

    function approve(address _spender, uint256 _wad) external returns (bool) {
        allowance[msg.sender][_spender] = _wad;
        emit Approval(msg.sender, _spender, _wad);
        return true;
    }

    // ***************************
    // ***** Query functions *****
    // ***************************
    /**
     * @dev Gets total amount of anchored asset of account`_src`.
     * @param _src Account to query.
     */
    function getTokenBalance(address _src) external view returns (uint256) {
        return getRedeemAmount(balanceOf[_src]);
    }

    /**
     * @dev Gets corresponding anchored asset based on the amount of GOLDx.
     * @param _wad Amount of GOLDx, scaled by 1e18.
     */
    function getRedeemAmount(uint256 _wad) public view returns (uint256) {
        return
            convertDecimals(
                decimals,
                IERC20(token).decimals(),
                rdiv(_wad, unit)
            );
    }

    /**
     * @dev Gets outstanding amount.
     */
    function getOutstanding() public view returns (uint256) {
        int256 _amount = getOutstanding(token, unit);
        return _amount > 0 ? uint256(_amount) : 0;
    }

    /**
     * @dev Gets outstanding amount based on anchored asset`_token` and exchange rate`_uint`.
     * @return int256 negative number means insufficient reserve.
     *          positive number means enough reserve.
     */
    function getOutstanding(address _token, uint256 _unit) public view returns (int256) {
        uint256 _amount = convertDecimals(
            decimals,
            IERC20(_token).decimals(),
            rdiv(totalSupply, _unit)
        );
        return int256(_amount - IERC20(_token).balanceOf(address(this)));
    }

    /**
     * @dev Gets execution fee based on the amount`_amount`.
     */
    function getFee(uint256 _feeRate, uint256 _amount) public pure returns (uint256) {
        if (_feeRate == 0) return 0;

        return rmul(_amount, _feeRate);
    }

    /**
     * @dev Gets corresponding output amount based on input decimal`_srcDecimals`, input amount`_amount`
     *      and output decimal`_dstDecimals`.
     */
    function convertDecimals(
        uint256 _srcDecimals,
        uint256 _dstDecimals,
        uint256 _amount
    ) public pure returns (uint256) {
        if (_srcDecimals == 0 || _dstDecimals == 0 || _amount == 0) return 0;

        if (_srcDecimals > _dstDecimals)
            return _amount / 10**_srcDecimals.sub(_dstDecimals);

        return _amount.mul(10**_dstDecimals.sub(_srcDecimals));
    }

    function getBaseData() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            unit,
            decimals,
            IERC20(token).decimals(),
            fee[this.mint.selector],
            fee[this.burn.selector],
            IPAXG(token).feeParts(),
            IPAXG(token).feeRate(),
            paused || (upgradeTime > 0 && upgradeTime <= now)
        );
    }
}