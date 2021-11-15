// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iUSDV.sol";
import "./interfaces/iROUTER.sol";

contract Vader is iERC20 {
    // ERC-20 Parameters
    string public override name;
    string public override symbol;
    uint256 public override decimals;
    uint256 public override totalSupply;

    // ERC-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Parameters
    bool private inited;
    bool public emitting;
    bool public minting;
    uint256 _1m;
    uint256 public baseline;
    uint256 public emissionCurve;
    uint256 public maxSupply;
    uint256 public secondsPerEra;
    uint256 public currentEra;
    uint256 public nextEraTime;
    uint256 public feeOnTransfer;

    address public VETHER;
    address public USDV;
    address public UTILS;
    address public burnAddress;
    address public rewardAddress;
    address public DAO;

    event NewEra(uint256 currentEra, uint256 nextEraTime, uint256 emission);

    // Only DAO can execute
    modifier onlyDAO() {
        require(msg.sender == DAO, "Not DAO");
        _;
    }
    // Stop flash attacks
    modifier flashProof() {
        require(isMature(), "No flash");
        _;
    }

    function isMature() public view returns (bool) {
        return iUSDV(USDV).isMature();
    }

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {
        name = "VADER PROTOCOL TOKEN";
        symbol = "VADER";
        decimals = 18;
        _1m = 10**6 * 10**decimals; //1m
        baseline = _1m;
        totalSupply = 0;
        maxSupply = 2 * _1m;
        currentEra = 1;
        secondsPerEra = 1; //86400;
        nextEraTime = block.timestamp + secondsPerEra;
        emissionCurve = 900;
        DAO = msg.sender;
        burnAddress = 0x0111011001100001011011000111010101100101;
    }

    // Can only be called once
    function init(
        address _vether,
        address _USDV,
        address _utils
    ) external {
        require(inited == false);
        inited = true;
        VETHER = _vether;
        USDV = _USDV;
        UTILS = _utils;
        rewardAddress = _USDV;
    }

    //========================================iERC20=========================================//
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // iERC20 Transfer function
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // iERC20 Approve, change allowance functions
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // iERC20 TransferFrom function
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // TransferTo function
    // Risks: User can be phished, or tx.origin may be deprecated, optionality should exist in the system.
    function transferTo(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(tx.origin, recipient, amount);
        return true;
    }

    // Internal transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "sender");
        require(recipient != address(this), "recipient");
        _balances[sender] -= amount;
        uint256 _fee = iUTILS(UTILS).calcPart(feeOnTransfer, amount); // Critical functionality
        if (_fee >= 0 && _fee <= amount) {
            // Stops reverts if UTILS corrupted
            amount -= _fee;
            _burn(msg.sender, _fee);
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _checkEmission();
    }

    // Internal mint (upgrading and daily emissions)
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "recipient");
        if ((totalSupply + amount) >= maxSupply) {
            amount = maxSupply - totalSupply; // Safety, can't mint above maxSupply
        }
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Burn supply
    function burn(uint256 amount) public virtual override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external virtual override {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "address err");
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    //=========================================DAO=========================================//
    // Can start
    function flipEmissions() external onlyDAO {
        if (emitting) {
            emitting = false;
        } else {
            emitting = true;
        }
    }

    // Can stop
    function flipMinting() external onlyDAO {
        if (minting) {
            minting = false;
        } else {
            minting = true;
        }
    }

    // Can set params
    function setParams(uint256 newEra, uint256 newCurve) external onlyDAO {
        secondsPerEra = newEra;
        emissionCurve = newCurve;
    }

    // Can set reward address
    function setRewardAddress(address newAddress) external onlyDAO {
        rewardAddress = newAddress;
    }

    // Can change UTILS
    function changeUTILS(address newUTILS) external onlyDAO {
        require(newUTILS != address(0), "address err");
        UTILS = newUTILS;
    }

    // Can change DAO
    function changeDAO(address newDAO) external onlyDAO {
        require(newDAO != address(0), "address err");
        DAO = newDAO;
    }

    // Can purge DAO
    function purgeDAO() external onlyDAO {
        DAO = address(0);
    }

    //======================================EMISSION========================================//
    // Internal - Update emission function
    function _checkEmission() private {
        if ((block.timestamp >= nextEraTime) && emitting) {
            // If new Era and allowed to emit
            currentEra += 1; // Increment Era
            nextEraTime = block.timestamp + secondsPerEra; // Set next Era time
            uint256 _emission = getDailyEmission(); // Get Daily Dmission
            _mint(rewardAddress, _emission); // Mint to the Rewad Address
            feeOnTransfer = iUTILS(UTILS).getFeeOnTransfer(totalSupply, maxSupply); // UpdateFeeOnTransfer
            if (feeOnTransfer > 1000) {
                feeOnTransfer = 1000;
            } // Max 10% if UTILS corrupted
            emit NewEra(currentEra, nextEraTime, _emission); // Emit Event
        }
    }

    // Calculate Daily Emission
    function getDailyEmission() public view returns (uint256) {
        uint256 _adjustedMax;
        if (totalSupply <= baseline) {
            // If less than 1m, then adjust cap down
            _adjustedMax = (maxSupply * totalSupply) / baseline; // 2m * 0.5m / 1m = 2m * 50% = 1.5m
        } else {
            _adjustedMax = maxSupply; // 2m
        }
        return (_adjustedMax - totalSupply) / (emissionCurve); // outstanding / curve
    }

    //======================================ASSET MINTING========================================//
    // VETHER Owners to Upgrade
    function upgrade(uint256 amount) external {
        require(iERC20(VETHER).transferFrom(msg.sender, burnAddress, amount));
        _mint(msg.sender, amount);
    }

    // Directly redeem back to VADER (must have sent USDV first)
    function redeem() external returns (uint256 redeemAmount) {
        return redeemToMember(msg.sender);
    }

    // Redeem on behalf of member (must have sent USDV first)
    function redeemToMember(address member) public flashProof returns (uint256 redeemAmount) {
        if (minting) {
            uint256 _amount = iERC20(USDV).balanceOf(address(this));
            iERC20(USDV).burn(_amount);
            redeemAmount = iROUTER(iUSDV(USDV).ROUTER()).getVADERAmount(_amount); // Critical pricing functionality
            _mint(member, redeemAmount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transferTo(address, uint256) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function curatePool(address token) external;

    function listAnchor(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUSDV {
    function ROUTER() external view returns (address);

    function isMature() external view returns (bool);

    function setParams(uint256 newDelay) external;

    function convert(uint256 amount) external returns (uint256 convertAmount);

    function convertForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeem(uint256 amount) external returns (uint256 redeemAmount);

    function redeemForMember(address member, uint256 amount) external returns (uint256 redeemAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function isBase(address token) external view returns (bool base);

    function calcValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcValueInToken(address token, uint256 amount) external view returns (uint256);

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) external view returns (uint256);

    function calcSwapValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcSwapValueInToken(address token, uint256 amount) external view returns (uint256);

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view;

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare);

    function getReducedShare(uint256 amount) external view returns (uint256);

    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection);

    function getCoverage(address member, address token) external view returns (uint256);

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external returns (uint256 debt, uint256 baseValue);

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256);

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external returns (uint256 interestOwed);

    function getInterestPayment(address collateralAsset, address debtAsset) external view returns (uint256);

    function getDebtLoading(address collateralAsset, address debtAsset) external view returns (uint256);

    function calcPart(uint256 bp, uint256 total) external pure returns (uint256);

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) external pure returns (uint256);

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256);

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external view returns (uint256);

    function getSlipAdustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) external view returns (uint256);

    function calcSynthUnits(
        uint256 b,
        uint256 B,
        uint256 P
    ) external view returns (uint256);

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) external pure returns (uint256);

    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) external pure returns (uint256);

    function sortArray(uint256[] memory array) external pure returns (uint256[] memory);
}

