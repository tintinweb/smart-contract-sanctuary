// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../interfaces/IMochiProfile.sol";
import "../interfaces/IMochiEngine.sol";

///@notice this is where policies including some math is registered will be able to swap the profile when current profile is not suitable
///@dev this profile is built with https://docs.google.com/spreadsheets/d/1T2WKpwj5QmueR7O8R9AXNbnHLc-rJ_-8DLdRI2eJZqA
contract MochiProfileV0 is IMochiProfile {
    using Float for float;
    using Float for uint256;
    IMochiEngine public immutable engine;

    IMochiProfile public immutable oldProfile;

    uint256 public override liquidityRequirement;

    uint256 public override minimumDebt;

    mapping(address => AssetClass) internal _assetClass;

    mapping(address => uint256) internal _creditCap;

    uint256 public immutable secPerYear;

    uint256 public override delay;

    constructor(address _engine) {
        secPerYear = 31536000;
        engine = IMochiEngine(_engine);
        oldProfile = IMochiEngine(_engine).mochiProfile();

        liquidityRequirement = 1000000e18; // 1million dollar
        minimumDebt = 1000e18;
        delay = 3 minutes;
    }

    modifier onlyGov() {
        require(msg.sender == engine.governance(), "!gov");
        _;
    }

    function assetClass(address _asset)
        public
        view
        override
        returns (AssetClass)
    {
        if(_assetClass[_asset] == AssetClass.Invalid) {
            return oldProfile.assetClass(_asset);
        }
        return _assetClass[_asset];
    }

    function creditCap(address _asset)
        public
        view
        override
        returns(uint256)
    {
        if(_creditCap[_asset] == 0) {
            return oldProfile.creditCap(_asset);
        }
        return _creditCap[_asset];
    }

    function changeLiquidityRequirement(uint256 _requirement)
        external
        override
        onlyGov
    {
        liquidityRequirement = _requirement;
    }

    function registerAsset(address _asset) external {
        uint256 liq = engine.cssr().getLiquidity(_asset);
        require(liq >= liquidityRequirement, "<liquidity");
        _register(_asset, AssetClass.Sigma);
    }

    function registerAssetByGov(
        address[] calldata _asset,
        AssetClass[] calldata _classes
    ) external onlyGov {
        for (uint256 i = 0; i < _asset.length; i++) {
            _register(_asset[i], _classes[i]);
            engine.vaultFactory().deployVault(_asset[i]);
        }
    }

    function _register(address _asset, AssetClass _class) internal {
        _assetClass[_asset] = _class;
    }

    function changeMinimumDebt(uint256 _debt) external override onlyGov {
        minimumDebt = _debt;
    }

    function changeAssetClass(
        address[] calldata _assets,
        AssetClass[] calldata _classes
    ) external override onlyGov {
        for (uint256 i = 0; i < _assets.length; i++) {
            _assetClass[_assets[i]] = _classes[i];
        }
    }

    function changeCreditCap(
        address[] calldata _assets,
        uint256[] calldata _caps
    ) external onlyGov {
        for (uint256 i = 0; i < _assets.length; i++) {
            _creditCap[_assets[i]] = _caps[i];
        }
    }

    function setDelay(uint256 _delay) external onlyGov {
        delay = _delay;
    }

    ///@notice The Collateral Factor at which the users vault will be liquidated
    function liquidationFactor(address _asset)
        public
        view
        override
        returns (float memory)
    {
        AssetClass class = assetClass(_asset);
        if (class == AssetClass.Stable) {
            return float({numerator: 95, denominator: 100});
        } else if (class == AssetClass.Alpha) {
            return float({numerator: 85, denominator: 100});
        } else if (class == AssetClass.Gamma) {
            return float({numerator: 80, denominator: 100});
        } else if (class == AssetClass.Delta) {
            return float({numerator: 75, denominator: 100});
        } else if (class == AssetClass.Zeta) {
            return float({numerator: 65, denominator: 100});
        } else if (class == AssetClass.Sigma) {
            return float({numerator: 60, denominator: 100});
        } else {
            revert("invalid");
        }
    }

    function riskFactor(address _asset) public view returns (uint256) {
        AssetClass class = assetClass(_asset);
        if (class == AssetClass.Stable) {
            return 1;
        } else if (class == AssetClass.Alpha) {
            return 2;
        } else if (class == AssetClass.Gamma) {
            return 3;
        } else if (class == AssetClass.Delta) {
            return 4;
        } else if (class == AssetClass.Zeta) {
            return 5;
        } else if (class == AssetClass.Sigma) {
            return 6;
        } else {
            revert("invalid");
        }
    }

    function maxCollateralFactor(address _asset)
        public
        view
        override
        returns (float memory)
    {
        AssetClass class = assetClass(_asset);
        if (class == AssetClass.Stable) {
            return float({numerator: 90, denominator: 100});
        } else if (class == AssetClass.Alpha) {
            return float({numerator: 80, denominator: 100});
        } else if (class == AssetClass.Gamma) {
            return float({numerator: 75, denominator: 100});
        } else if (class == AssetClass.Delta) {
            return float({numerator: 65, denominator: 100});
        } else if (class == AssetClass.Zeta) {
            return float({numerator: 55, denominator: 100});
        } else if (class == AssetClass.Sigma) {
            return float({numerator: 45, denominator: 100});
        } else {
            revert("invalid");
        }
    }

    function baseFee() public pure returns (float memory) {
        return float({numerator: 24, denominator: 1000});
    }

    function liquidationFee(address _asset)
        public
        view
        override
        returns (float memory)
    {
        AssetClass class = assetClass(_asset);
        if (class == AssetClass.Stable) {
            return float({numerator: 45, denominator: 1000});
        } else if (class == AssetClass.Alpha) {
            return float({numerator: 100, denominator: 1000});
        } else if (class == AssetClass.Gamma) {
            return float({numerator: 125, denominator: 1000});
        } else if (class == AssetClass.Delta) {
            return float({numerator: 150, denominator: 1000});
        } else if (class == AssetClass.Zeta) {
            return float({numerator: 175, denominator: 1000});
        } else if (class == AssetClass.Sigma) {
            return float({numerator: 200, denominator: 1000});
        } else {
            revert("invalid");
        }
    }

    function keeperFee(address _asset)
        public
        view
        override
        returns (float memory)
    {
        AssetClass class = assetClass(_asset);
        if (class == AssetClass.Stable) {
            return float({numerator: 5, denominator: 1000});
        } else if (class == AssetClass.Alpha) {
            return float({numerator: 10, denominator: 1000});
        } else if (class == AssetClass.Gamma) {
            return float({numerator: 15, denominator: 1000});
        } else if (class == AssetClass.Delta) {
            return float({numerator: 20, denominator: 1000});
        } else if (class == AssetClass.Zeta) {
            return float({numerator: 25, denominator: 1000});
        } else if (class == AssetClass.Sigma) {
            return float({numerator: 30, denominator: 1000});
        } else {
            revert("invalid");
        }
    }

    function maxFee(AssetClass _class) public pure returns (float memory) {
        if (_class == AssetClass.Stable) {
            return float({numerator: 35, denominator: 1000});
        } else if (_class == AssetClass.Alpha) {
            return float({numerator: 40, denominator: 1000});
        } else if (_class == AssetClass.Gamma) {
            return float({numerator: 45, denominator: 1000});
        } else if (_class == AssetClass.Delta) {
            return float({numerator: 50, denominator: 1000});
        } else if (_class == AssetClass.Zeta) {
            return float({numerator: 525, denominator: 10000});
        } else if (_class == AssetClass.Sigma) {
            return float({numerator: 55, denominator: 1000});
        } else {
            revert("invalid");
        }
    }

    function stabilityFee(address _asset)
        public
        view
        override
        returns (float memory)
    {
        float memory base = baseFee();
        AssetClass class = assetClass(_asset);
        float memory max = maxFee(class);
        float memory u = utilizationRatio(_asset);
        if (u.gt(float({numerator: 1, denominator: 1}))) {
            return max;
        }
        return base.add(max.sub(base).mul(u));
    }

    function calculateFeeIndex(
        address _asset,
        uint256 _currentIndex,
        uint256 _lastAccrued
    ) external view override returns (uint256) {
        float memory feePerYear = stabilityFee(_asset);
        uint256 timePassed = block.timestamp - _lastAccrued;
        float memory feeAccumulated = feePerYear.mul(
            float({numerator: timePassed, denominator: secPerYear})
        );
        return _currentIndex + _currentIndex.multiply(feeAccumulated);
    }

    ///@dev returns utilization ratio scaled with 1e18
    function utilizationRatio(address _asset)
        public
        view
        override
        returns (float memory ratio)
    {
        IMochiVault vault = engine.vaultFactory().getVault(_asset);
        uint256 debts = vault.debts();
        uint256 cap = creditCap(_asset);
        return float({numerator: debts, denominator: cap});
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

enum AssetClass {
    Invalid,
    Stable,
    Alpha,
    Gamma,
    Delta,
    Zeta,
    Sigma,
    Revoked
}

interface IMochiProfile {
    function assetClass(address _asset) external view returns (AssetClass);

    function liquidityRequirement() external view returns (uint256);

    function minimumDebt() external view returns (uint256);

    function changeAssetClass(
        address[] calldata _asset,
        AssetClass[] calldata _class
    ) external;

    function changeLiquidityRequirement(uint256 _requirement) external;

    function changeMinimumDebt(uint256 _debt) external;

    function calculateFeeIndex(
        address _asset,
        uint256 _currentIndex,
        uint256 _lastAccrued
    ) external view returns (uint256);

    function creditCap(address _asset) external view returns (uint256);

    function delay() external view returns (uint256);

    function liquidationFactor(address _asset)
        external
        view
        returns (float memory);

    function maxCollateralFactor(address _asset)
        external
        view
        returns (float memory);

    function stabilityFee(address _asset) external view returns (float memory);

    function liquidationFee(address _asset)
        external
        view
        returns (float memory);

    function keeperFee(address _asset) external view returns (float memory);

    function utilizationRatio(address _asset)
        external
        view
        returns (float memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@mochifi/vmochi/contracts/interfaces/IVMochi.sol";
import "@mochifi/cssr/contracts/interfaces/ICSSRRouter.sol";
import "./IMochiProfile.sol";
import "./IDiscountProfile.sol";
import "./IMochiVault.sol";
import "./IFeePool.sol";
import "./IReferralFeePool.sol";
import "./ILiquidator.sol";
import "./IUSDM.sol";
import "./IMochi.sol";
import "./IMinter.sol";
import "./IMochiNFT.sol";
import "./IMochiVaultFactory.sol";

interface IMochiEngine {
    function mochi() external view returns (IMochi);

    function vMochi() external view returns (IVMochi);

    function usdm() external view returns (IUSDM);

    function cssr() external view returns (ICSSRRouter);

    function governance() external view returns (address);

    function treasury() external view returns (address);

    function operationWallet() external view returns (address);

    function mochiProfile() external view returns (IMochiProfile);

    function discountProfile() external view returns (IDiscountProfile);

    function feePool() external view returns (IFeePool);

    function referralFeePool() external view returns (IReferralFeePool);

    function liquidator() external view returns (ILiquidator);

    function minter() external view returns (IMinter);

    function nft() external view returns (IMochiNFT);

    function vaultFactory() external view returns (IMochiVaultFactory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

struct float {
    uint256 numerator;
    uint256 denominator;
}

library Float {
    function multiply(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.numerator / f.denominator;
    }

    function inverse(float memory f) internal pure returns(float memory) {
        require(f.numerator != 0 && f.denominator != 0, "div 0");
        return float({
            numerator: f.denominator,
            denominator: f.numerator
        });
    }

    function divide(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.denominator / f.numerator;
    }

    function add(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator + a.denominator*b.numerator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }
    
    function sub(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator - b.numerator*a.denominator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function mul(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator * b.numerator,
            denominator : a.denominator * b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function gt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator > a.denominator * b.numerator;
    }

    function lt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator < a.denominator * b.numerator;
    }

    function gte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator >= a.denominator * b.numerator;
    }

    function lte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator <= a.denominator * b.numerator;
    }

    function equals(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator == b.numerator * a.denominator;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IVMochi {
    function locked(address _user) external view returns(int128, uint256);
    function depositFor(address _user, uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

interface ICSSRRouter {
    function update(address _asset, bytes memory _data)
        external
        returns (float memory);

    function getPrice(address _asset) external view returns (float memory);

    function getLiquidity(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

interface IDiscountProfile {
    function discount(address _user) external view returns (float memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
struct Detail {
    Status status;
    uint256 collateral;
    uint256 debt;
    uint256 debtIndex;
    address referrer;
}

enum Status {
    Invalid, // not minted
    Idle, // debt = 0, collateral = 0
    Collaterized, // debt = 0, collateral > 0
    Active, // debt > 0, collateral > 0
    Liquidated
}

interface IMochiVault {
    function liveDebtIndex() external view returns (uint256);

    function details(uint256 _nftId)
        external
        view
        returns (
            Status,
            uint256 collateral,
            uint256 debt,
            uint256 debtIndexe,
            address refferer
        );

    function status(uint256 _nftId) external view returns (Status);

    function asset() external view returns (IERC20);

    function deposits() external view returns (uint256);

    function debts() external view returns (uint256);

    function claimable() external view returns (int256);

    function currentDebt(uint256 _nftId) external view returns (uint256);

    function initialize(address _asset) external;

    function deposit(uint256 _nftId, uint256 _amount) external;

    function withdraw(
        uint256 _nftId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function borrow(
        uint256 _nftId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function repay(uint256 _nftId, uint256 _amount) external;

    function liquidate(
        uint256 _nftId,
        uint256 _collateral,
        uint256 _usdm
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IFeePool {
    function updateReserve() external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IReferralFeePool {
    function addReward(address _recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface ILiquidator {
    event Triggered(uint256 _auctionId, uint256 _price);
    event Settled(uint256 _auctionId, uint256 _price);

    function triggerLiquidation(address _asset, uint256 _nftId) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IUSDM is IERC20, IERC3156FlashLender {
    function mint(address _recipient, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMochi is IERC20 {}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IMinter {
    function mint(address _to, uint256 _amount) external;

    function hasPermission(address _user) external view returns (bool);

    function isVault(address _vault) external view returns(bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMochiNFT is IERC721Enumerable {
    struct MochiInfo {
        address asset;
    }

    function asset(uint256 _id) external view returns (address);

    function mint(address _asset, address _owner) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IMochiVault.sol";

interface IMochiVaultFactory {
    function updateTemplate(address _template) external;

    function deployVault(address _asset) external returns (IMochiVault);

    function getVault(address _asset) external view returns (IMochiVault);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}