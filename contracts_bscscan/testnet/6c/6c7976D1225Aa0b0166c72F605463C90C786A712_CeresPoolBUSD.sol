// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../common/ERC20MintBurn.sol";
import "../interface/IPoolManager.sol";
import "../common/Ownable.sol";

contract ASC is ERC20MintBurn, Ownable {

    //****************
    // META DATA
    //****************
    string public override name = "AS Coin";
    string public override symbol = "ASC";
    uint8 public constant override decimals = 18;

    IPoolManager public ipm;

    //****************
    // MODIFIES
    //****************
    modifier onlyPools() {
        require(ipm.pools(msg.sender) == true, "Only pools!");
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint256 _premint, address _owner) Ownable(_owner) {
        _mint(owner(), _premint);
    }


    // ------------------------------------------------------------------------
    // Called by pools, mint new ASC
    // ------------------------------------------------------------------------
    function poolMint(address to, uint256 amount) public onlyPools {
        super._mint(to, amount);
        emit ASCMinted(msg.sender, to, amount);
    }


    // ------------------------------------------------------------------------
    // Called by pools, burn ASC
    // ------------------------------------------------------------------------
    function poolBurnFrom(address from, uint256 amount) public onlyPools {
        super._burnFrom(from, amount);
        emit ASCBurned(from, msg.sender, amount);
    }
    

    // ------------------------------------------------------------------------
    // Set ipm
    // ------------------------------------------------------------------------
    function setPoolManager(address _poolManager) public onlyOwner {
        ipm = IPoolManager(_poolManager);
    }


    //****************
    // EVENTS
    //****************
    event ASCMinted(address indexed from, address indexed to, uint256 amount);
    event ASCBurned(address indexed from, address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../common/ERC20MintBurn.sol";
import "../interface/IPoolManager.sol";
import "../common/Ownable.sol";

contract CRS is ERC20MintBurn, Ownable {


    //****************
    // META DATA
    //****************
    string public override name = "Ceres";
    string public override symbol = "CRS";
    uint8 public constant override decimals = 18;
    
    IPoolManager public ipm;

    //****************
    // MODIFIES
    //****************
    modifier onlyPools() {
        require(ipm.pools(msg.sender) == true, "Only pools!");
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint256 _premint, address _owner) Ownable(_owner) {
        _mint(owner(), _premint);
    }


    // ------------------------------------------------------------------------
    // Called by pools, mint new CRS
    // ------------------------------------------------------------------------
    function poolMint(address to, uint256 amount) public onlyPools {
        super._mint(to, amount);
        emit CRSMinted(msg.sender, to, amount);
    }


    // ------------------------------------------------------------------------
    // Called by pools, burn CRS
    // ------------------------------------------------------------------------
    function poolBurnFrom(address from, uint256 amount) public onlyPools {
        super._burnFrom(from, amount);
        emit CRSBurned(from, msg.sender, amount);
    }
    

    // ------------------------------------------------------------------------
    // Set ipm
    // ------------------------------------------------------------------------
    function setPoolManager(address _poolManager) public onlyOwner {
        ipm = IPoolManager(_poolManager);
    }


    //****************
    // EVENTS
    //****************
    event CRSMinted(address indexed from, address indexed to, uint256 amount);
    event CRSBurned(address indexed from, address indexed to, uint256 amount);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/IOracle.sol";
import "../interface/IChainlink.sol";
import "../common/Ownable.sol";
import "../common/Governable.sol";

contract CeresAnchor is Ownable, Governable {
    
    enum Coin {ASC, CRS}

    //****************
    // PRICER
    //****************
    address public busdAddress;

    IChainlink public busdChainlink;
    uint8 public busdPriceDecimals;

    IOracle public ascBusdOracle;
    IOracle public crsBusdOracle;

    //****************
    // SYSTEM PARAMS
    //****************
    uint256 public collateralRatio; // collateral ratio of asc
    uint256 public lastUpdateTime; // last time update ratio
    uint256 public ratioStep; // step that collateral rate changes every time
    uint256 public priceBand; // threshold of automint / autoredeem
    uint256 public updateCooldown; // cooldown between raito changes 

    uint256 public constant CERES_PRECISION = 1e6;  // 1000000 <=> 1 integer
    uint256 public constant PRICE_TARGET = 1e6;  // 1:1 to USD
    uint256 public seignioragePercent = 5000;

    //****************
    // COEFFICIENT
    //****************
    uint256 public CiRate;
    uint256 public Cp;
    uint256 public Vp;


    //****************
    // MODIFIES
    //****************
    modifier onlyGovernance() {
        require(msg.sender == owner() || msg.sender == timelock() || msg.sender == controller(), "Only Governance!");
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner) Ownable(_owner){
        
        collateralRatio = 850000;
        ratioStep = 2500;
        priceBand = 5000;
        updateCooldown = 3600;

        CiRate = 50000;
        Cp = 1000000;
        Vp = 500000;
    }


    // ------------------------------------------------------------------------
    // Update collateral ratio according to ASC/USD price in current
    // ------------------------------------------------------------------------
    function updateCollateralRatio() public {
        uint256 ascPrice = getASCPrice();
        require(block.timestamp - lastUpdateTime >= updateCooldown, "Wait after cooldown!");

        if (ascPrice > PRICE_TARGET + priceBand) {
            // decrease collateral ratio, minimum to 0
            if (collateralRatio <= ratioStep)
                collateralRatio = 0;
            else
                collateralRatio -= ratioStep;
        } else if (ascPrice < PRICE_TARGET - priceBand) {
            // increase collateral ratio, maximum to 1000000, i.e 100% in CERES_PRECISION
            if (collateralRatio + ratioStep >= 1000000)
                collateralRatio = 1000000;
            else
                collateralRatio += ratioStep;
        }

        // update last time
        lastUpdateTime = block.timestamp;
    }

    // ------------------------------------------------------------------------
    // Setting of system of params
    // ------------------------------------------------------------------------
    function setRatioStep(uint256 newStep) public onlyGovernance {
        ratioStep = newStep;
    }

    function setUpdateCooldown(uint256 newCooldown) public onlyGovernance {
        updateCooldown = newCooldown;
    }

    function setPriceBand(uint256 newBand) public onlyGovernance {
        priceBand = newBand;
    }

    function setCollateralRatio(uint256 newRatio) public onlyGovernance {
        collateralRatio = newRatio;
    }

    function setSeignioragePercent(uint256 newPercent) public onlyGovernance {
        seignioragePercent = newPercent;
    }

    function setCiRate(uint256 newCiRate) public onlyGovernance {
        collateralRatio = newCiRate;
    }

    function setCp(uint256 newCp) public onlyGovernance {
        collateralRatio = newCp;
    }

    function setVp(uint256 newVp) public onlyGovernance {
        collateralRatio = newVp;
    }

    function setController(address newController) public onlyOwner {
        _setController(newController);
    }

    function setTimelock(address newTimelock) public onlyOwner {
        _setTimelock(newTimelock);
    }

    // ------------------------------------------------------------------------
    // Setting of oracles
    // ------------------------------------------------------------------------
    function setAscBusdOracle(address oracleAddr) public onlyGovernance {
        ascBusdOracle = IOracle(oracleAddr);
    }

    function setCrsBusdOracle(address oracleAddr) public onlyGovernance {
        crsBusdOracle = IOracle(oracleAddr);
    }

    function setBusdChainLink(address chainlinkAddress) public onlyGovernance {
        busdChainlink = IChainlink(chainlinkAddress);
        busdPriceDecimals = busdChainlink.getDecimals();
    }

    function setBusdAddress(address newAddress) public onlyGovernance {
        busdAddress = newAddress;
    }
    
    // ------------------------------------------------------------------------
    // Get ASC price in USD
    // ------------------------------------------------------------------------
    function getASCPrice() public view returns (uint256) {
        return oraclePrice(Coin.ASC);
    }

    // ------------------------------------------------------------------------
    // Get CRS price in USD
    // ------------------------------------------------------------------------
    function getCRSPrice() public view returns (uint256) {
        return oraclePrice(Coin.CRS);
    }

    // ------------------------------------------------------------------------
    // Get ASC price in USD
    // ------------------------------------------------------------------------
    function getBUSDPrice() public view returns (uint256) {
        return uint256(busdChainlink.getLatestPrice()) * (CERES_PRECISION) / (uint256(10) ** busdPriceDecimals);
    }

    // ------------------------------------------------------------------------
    // Get coin price in USD - internal
    // ------------------------------------------------------------------------
    function oraclePrice(Coin choice) internal view returns (uint256) {
        // get BUSD price in USD
        uint256 busdPriceInUSD = uint256(busdChainlink.getLatestPrice()) * (CERES_PRECISION) / (uint256(10) ** busdPriceDecimals);

        uint256 priceVsBusd;

        if (choice == Coin.ASC) {
            priceVsBusd = uint256(ascBusdOracle.consult(busdAddress, CERES_PRECISION));
        } else if (choice == Coin.CRS) {
            priceVsBusd = uint256(crsBusdOracle.consult(busdAddress, CERES_PRECISION));
        }

        else revert("INVALID COIN!");

        // return in 1e6 format
        return busdPriceInUSD * CERES_PRECISION / priceVsBusd;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../asset/ASC.sol";
import "../asset/CRS.sol";
import "./CeresAnchor.sol";
import "../interface/IOracle.sol";
import "../interface/IPool.sol";
import "../interface/IStakingManager.sol";

abstract contract CeresPool is Ownable, Governable, IPool {

    uint256 public constant CERES_PRECISION = 1e6;  // 1000000 <=> 1 integer
    uint256 public constant PRICE_TARGET = 1e6;  // 1:1 to USD

    CeresAnchor public ceresAnchor;

    IStakingManager public ism;

    ASC public coinASC;
    address public ascAddress;

    CRS public coinCRS;
    address public crsAddress;

    uint256 public lastMintRatio;  // mint revenue ratio last time

    uint256 public lastRedeemRatio;  // redeem revenue ratio last time

    address public seigniorageGovern;

    //****************
    // MODIFIES
    //****************
    modifier onlyGovernance() {
        require(msg.sender == owner() || msg.sender == timelock() || msg.sender == controller(), "Only Governance!");
        _;
    }

    // ------------------------------------------------------------------------
    // Setters
    // ------------------------------------------------------------------------
    function setStakingManager(address _stakingManager) public onlyGovernance {
        ism = IStakingManager(_stakingManager);
    }

    function setCeresAnchor(address anchorAddress) public onlyGovernance {
        ceresAnchor = CeresAnchor(anchorAddress);
    }

    function setSeigniorageGovern(address _seigniorageGovern) public onlyGovernance {
        seigniorageGovern = _seigniorageGovern;
    }

    function setController(address newController) public onlyOwner {
        _setController(newController);
    }

    function setTimelock(address newTimelock) public onlyOwner {
        _setTimelock(newTimelock);
    }


    function determine() external virtual;

    function mint(uint256 collateralAmount, uint256 crsAmount, uint256 ascOut) internal virtual;

    function redeem(uint256 ascAmount, uint256 collateralOut, uint256 crsOut) internal virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CeresPool.sol";
import "../interface/IStaking.sol";
import "../interface/IMinter.sol";
import "../interface/IRedeemer.sol";

contract CeresPoolBUSD is CeresPool {

    //****************
    // ASSETS
    //****************
    IERC20 public BUSD;
    address public busdAddress;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address busd, address asc, address crs, address _owner) Ownable(_owner) {

        BUSD = IERC20(busd);
        busdAddress = busd;

        coinASC = ASC(asc);
        ascAddress = asc;

        coinCRS = CRS(crs);
        crsAddress = crs;
    }


    // ------------------------------------------------------------------------
    // Determine - auto mint or redeem according to the price of ASC
    // ------------------------------------------------------------------------
    function determine() external onlyGovernance override {

        uint256 ascPrice = ceresAnchor.getASCPrice();
        uint256 crsPrice = ceresAnchor.getCRSPrice();
        uint256 busdPrice = ceresAnchor.getBUSDPrice();
        uint256 colRatio = ceresAnchor.collateralRatio();

        uint256 ascValue;
        if (ascPrice > PRICE_TARGET + ceresAnchor.priceBand()) {

            ascValue = nextMintValue();
            mint(ascValue * colRatio / busdPrice, ascValue * (CERES_PRECISION - colRatio) / crsPrice, ascValue);
            lastMintRatio = ascPrice - PRICE_TARGET;
        } else if (ascPrice < PRICE_TARGET - ceresAnchor.priceBand()) {

            ascValue = nextRedeemValue();
            uint256 colRatioSquare = colRatio ** 2;
            redeem(ascValue, ascValue * colRatioSquare / busdPrice / CERES_PRECISION,
                ascValue * (CERES_PRECISION ** 2 - colRatioSquare) / crsPrice / CERES_PRECISION);
            lastRedeemRatio = PRICE_TARGET - ascPrice;
        }

        // update cr
        ceresAnchor.updateCollateralRatio();
    }


    // ------------------------------------------------------------------------
    // Calculate the mint value next time
    // ------------------------------------------------------------------------
    function nextMintValue() public view returns (uint256){

        // v1: circulating calcu
        uint256 v1 = ceresAnchor.CiRate() * coinASC.totalSupply() * ceresAnchor.Cp() / CERES_PRECISION ** 2;

        // v2: collateral calcu
        address BUSDStakingAddr = ism.stakingAddress(busdAddress);
        address crsStakingAddr = ism.stakingAddress(crsAddress);

        // TODO optimize zero condition
        uint256 vCol = IPool(BUSDStakingAddr).collateralBalance() * ceresAnchor.Vp() * (uint256(10) ** coinASC.decimals())
        / ceresAnchor.collateralRatio() / CERES_PRECISION;
        uint256 vCrs = IPool(crsStakingAddr).collateralBalance() * ceresAnchor.Vp() * (uint256(10) ** coinASC.decimals())
        / (CERES_PRECISION - ceresAnchor.collateralRatio()) / CERES_PRECISION;

        uint256 v2 = SafeMath.min(vCol, vCrs);

        return SafeMath.min(v1, v2);
    }


    // ------------------------------------------------------------------------
    // Calculate the redeem value next time
    // ------------------------------------------------------------------------
    function nextRedeemValue() public view returns (uint256){

        uint256 v1 = ceresAnchor.CiRate() * coinASC.totalSupply() * ceresAnchor.Cp() / CERES_PRECISION ** 2;
        uint256 v2 = collateralBalance() * ceresAnchor.Vp() * (uint256(10) ** coinASC.decimals())
        / ceresAnchor.collateralRatio() / CERES_PRECISION;

        return SafeMath.min(v1, v2);
    }


    function mint(uint256 busdAmount, uint256 crsAmount, uint256 ascOut) internal override {

        uint256 colRaito = ceresAnchor.collateralRatio();

        // seigniorage
        uint256 ascToSeign = ascOut * ceresAnchor.seignioragePercent() / CERES_PRECISION;

        // staking mint
        uint256 ascToBusd = (ascOut - ascToSeign) * colRaito / CERES_PRECISION;
        uint256 ascToCrs = ascOut - ascToSeign - ascToBusd;

        address busdStakingAddr = ism.stakingAddress(busdAddress);
        address crsStakingAddr = ism.stakingAddress(crsAddress);

        // notify mint
        IMinter(busdStakingAddr).notifyMint(ascToBusd, busdAmount);
        IMinter(crsStakingAddr).notifyMint(ascToCrs, crsAmount);

        // mint to
        if (ascToSeign > 0)
            coinASC.poolMint(seigniorageGovern, ascToSeign);

        coinASC.poolMint(busdStakingAddr, ascToBusd);
        coinASC.poolMint(crsStakingAddr, ascToCrs);

    }

    function redeem(uint256 ascAmount, uint256 busdOut, uint256 crsOut) internal override {

        address ascStakingAddr = ism.stakingAddress(ascAddress);

        // nofity redeem
        IRedeemer(ascStakingAddr).notifyRedeem(ascAmount, crsOut, busdOut);

        // collateral transfer to staking
        BUSD.transfer(ascStakingAddr, busdOut);

        // crs mint to staking
        coinCRS.poolMint(ascStakingAddr, crsOut);

    }


    // ------------------------------------------------------------------------
    // Get collateral balalce of this pool in USD - ceres decimals
    // ------------------------------------------------------------------------
    function collateralBalance() public override view returns (uint256){
        return BUSD.balanceOf(address(this)) * ceresAnchor.getBUSDPrice() / uint256(10) ** BUSD.decimals();
    }


    // ------------------------------------------------------------------------
    // Pool migration
    // ------------------------------------------------------------------------
    function migrate(address newPool) external onlyOwner {
        uint256 amount = BUSD.balanceOf(address(this));
        BUSD.transfer(newPool, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "../common/Context.sol";
import "../interface/IERC20.sol";
import "../library/SafeMath.sol";


// Due to compiling issues, _name, _symbol, and _decimals were removed


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20MintBurn is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic governing control mechanism, where
 * there is an governing account that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governing account will be empty. This
 * can later be changed by governor or owner.
 *
 */
abstract contract Governable is Context {
    
    address internal _controller;
    address internal _timelock;

    event ControllerTransferred(address indexed previousController, address indexed newController);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);
    
    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }
    
    /**
     * @dev Returns the address of the current timelock.
     */
    function timelock() public view virtual returns (address) {
        return _timelock;
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(controller() == _msgSender(), "Controller: caller is not the controller");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the timelock.
     */
    modifier onlyTimelock() {
        require(timelock() == _msgSender(), "Timelock: caller is not the timelock");
        _;
    }

    /**
     * @dev Transfers controller of the contract to a new account
     * Can only be called by the current controller.
     */
    function transferController(address newController) public virtual onlyController {
        require(newController != address(0), "Controller: new controller is the zero address");
        _setController(newController);
    }

    /**
    * @dev Leaves the contract without controller. It will not be possible to call
     * `onlyController` functions anymore. Can only be called by the current owner.
     */
    function renounceController() public virtual onlyController {
        _setController(address(0));
    }

    function _setController(address newController) internal {
        address old = _controller;
        _controller = newController;
        emit ControllerTransferred(old, newController);
    }
    
    /**
     * @dev Transfers timelock of the contract to a new account
     * Can only be called by the current timelock.
     */
    function transferTimelock(address newTimelock) public virtual onlyTimelock {
        require(newTimelock != address(0), "Timelock: new timelock is the zero address");
        _setTimelock(newTimelock);
    }
    
    /**
    * @dev Leaves the contract without timelock. It will not be possible to call
     * `onlyTimelock` functions anymore. Can only be called by the current owner.
     */
    function renounceTimelock() public virtual onlyTimelock {
        _setTimelock(address(0));
    }

    function _setTimelock(address newTimelock) internal {
        address old = _timelock;
        _timelock = newTimelock;
        emit TimelockTransferred(old, newTimelock);
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
    constructor(address _owner_) {
        _setOwner(_owner_);
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
        require(owner() == _msgSender(), "Only Owner!");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlink {

    function getLatestPrice() external view returns (int);

    function getDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     * metadata functions - name
     */
    function name() external view returns (string memory);


    /**
     * metadata functions - symbol
     */
    function symbol() external view returns (string memory);

    /**
     * metadata functions - decimals
     */
    function decimals() external view returns (uint8);
    

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
pragma solidity ^0.8.4;
import "./IPool.sol";

interface IMinter is IPool{

    function notifyMint(uint256 ascAmount, uint256 collateralAmount) external;

    function claimMintWithPercent(uint256 percent) external;

    function reinvestMint() external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {

    function consult(address token, uint amountIn) external view returns (uint amountOut);

    function update() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPool {

    function collateralBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoolManager {

    function pools(address sender) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRedeemer {

    function notifyRedeem(uint256 ascAmount, uint256 collateral0Amount, uint256 collateral1Amount) external;

    function claimRedeemWithPercent(uint256 percent) external;

    function reinvestRedeem() external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking {

    struct UserLock {
        uint256 shareAmount;
        uint256 timeEnd;
    }

    // Views
    function totalStaking() external view returns (uint256);

    function stakingBalanceOf(address account) external view returns (uint256);
    
    function totalShare() external view returns (uint256);

    function shareBalanceOf(address account) external view returns (uint256);

    function yieldAPR() external view returns (uint256);
    
    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 shareAmount) external;

    function withdrawAll(uint256 shareAmount) external;

    function reinvestReward() external;
    
    function notifyReinvest(address account, uint256 amount) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingManager {

    function stakings(address sender) external view returns (bool);

    function stakingAddress(address staingToken) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }

    /**
    * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}