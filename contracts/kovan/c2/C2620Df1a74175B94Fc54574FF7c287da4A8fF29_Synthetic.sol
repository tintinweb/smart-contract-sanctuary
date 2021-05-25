// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./token/ERC20/IERC20.sol";
import "./access/Ownable.sol";
import "./IStdReference.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;
}

contract Synthetic is Ownable {
    IERC20Burnable public systheticAsset;
    IERC20 public dolly;
    IStdReference public bandOracle;

    mapping(string => string[2]) public pairsToQuote;
    mapping(string => address) public pairsToAddress;
    mapping(address => string) public addressToPairs;

    uint256 public denominator = 1e18; // 1 scaled by 1e18
    uint256 public liquidationRatio = 1e18 + 75e16; // 1.75 scaled by 1e18
    uint256 public collateralRatio = 1e18 + 5e17; // 1.5 scaled by 1e18

    struct MintingNote {
        address minter;
        IERC20Burnable asset; // synthetic
        IERC20 assetBacked; // dolly
        uint256 assetAmount;
        uint256 assetBackedAmount;
        uint256 currentRatio;
        uint256 canMintRemainning;
        uint256 canWithdrawRemainning;
        uint256 startMintingDate;
        uint256 pastDays;
    }

    mapping(address => mapping(address => MintingNote)) public minter; // lender => asset => MintingNote

    constructor(IERC20 _dolly, IStdReference _ref) public {
        dolly = _dolly; // use Dolly as collateral
        bandOracle = _ref;
        pairsToQuote["TSLA/USD"] = ["TSLA", "USD"];

        pairsToAddress["TSLA/USD"] = 0x65cAC0F09EFdB88195a002E8DD4CBF6Ec9BC7f60;

        addressToPairs[0x65cAC0F09EFdB88195a002E8DD4CBF6Ec9BC7f60] = "TSLA/USD";
    }

    // user need to approve for synthetic mint at dolly contract first.
    function mintSynthetic(
        IERC20Burnable _synthetic,
        uint256 _amount, // amount of synthetic that want to mint
        uint256 _backedAmount // amount of Dolly that you want to collateral
    ) external {
        MintingNote storage mn = minter[_msgSender()][address(_synthetic)];
        require(mn.minter == address(0));

        uint256 exchangeRate = getRate(addressToPairs[address(_synthetic)]);
        uint256 assetBackedAtRateAmount =
            (mn.assetAmount * exchangeRate) / denominator;
        require(
            _backedAmount >=
                (assetBackedAtRateAmount * collateralRatio) / denominator
        );
        _synthetic.mint(_msgSender(), _backedAmount);

        require(dolly.transferFrom(_msgSender(), address(this), _backedAmount));
        mn.minter = _msgSender();
        mn.asset = _synthetic;
        mn.assetAmount = _amount;
        mn.assetBackedAmount = _backedAmount;
    }

    // user need to approve for burn at SyntheticAsset before call this function.
    function redeemSynthetic(IERC20Burnable _synthetic, uint256 _amount)
        external
    {
        _synthetic.burnFrom(_msgSender(), _amount);
        dolly.transfer(_msgSender(), 1 ether);
    }

    function liquidate() external {}

    function getRate(string memory _pairs) internal view returns (uint256) {
        require(isSupported(_pairs));
        IStdReference.ReferenceData memory data =
            bandOracle.getReferenceData(
                pairsToQuote[_pairs][0],
                pairsToQuote[_pairs][1]
            );
        return data.rate;
    }

    function isSupported(string memory _pairs) public view returns (bool) {
        return pairsToQuote[_pairs].length > 0;
    }

    function setPairsToQuote(
        string memory _pairs,
        string[2] memory baseAndQuote
    ) external onlyOwner {
        pairsToQuote[_pairs] = baseAndQuote;
    }

    function setPairsToAddress(string memory _pairs, address _syntheticAddress)
        external
        onlyOwner
    {
        pairsToAddress[_pairs] = _syntheticAddress;
    }

    function setAddressToPairs(address _syntheticAddress, string memory _pairs)
        external
        onlyOwner
    {
        addressToPairs[_syntheticAddress] = _pairs;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(
        string[] memory _bases,
        string[] memory _quotes
    ) external view returns (ReferenceData[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}