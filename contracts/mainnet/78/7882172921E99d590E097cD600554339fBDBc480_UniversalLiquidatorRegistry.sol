// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "ozV3/access/Ownable.sol";
import "./interfaces/IUniversalLiquidatorRegistry.sol";

contract UniversalLiquidatorRegistry is Ownable, IUniversalLiquidatorRegistry {
  address constant public farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);

  address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  address constant public wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address constant public renBTC = address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
  address constant public sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
  address constant public dego = address(0x88EF27e69108B2633F8E1C184CC37940A075cC02);
  address constant public uni = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
  address constant public comp = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
  address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

  address constant public idx = address(0x0954906da0Bf32d5479e25f46056d22f08464cab);
  address constant public idle = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);

  address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant public mis = address(0x4b4D2e899658FB59b1D518b68fe836B100ee8958);
  address constant public bsg = address(0xB34Ab2f65c6e4F764fFe740ab83F982021Faed6d);
  address constant public bas = address(0xa7ED29B253D8B4E3109ce07c80fc570f81B63696);
  address constant public bsgs = address(0xA9d232cC381715aE791417B624D7C4509D2c28DB);
  address constant public kbtc = address(0xE6C3502997f97F9BDe34CB165fBce191065E068f);

  address public override universalLiquidator;

  function setUniversalLiquidator(address _ul) public override onlyOwner {
    require(_ul != address(0), "new universal liquidator is nill");
    universalLiquidator = _ul;
  }

  // path[UNISWAP][tokenA][tokenB]
  mapping (bytes32 => mapping(address => mapping(address => address[])) ) public dexPaths;

  constructor() public {
    bytes32 uniDex = bytes32(uint256(keccak256("uni")));
    bytes32 sushiDex = bytes32(uint256(keccak256("sushi")));

    // preset for the already in use crops
    dexPaths[uniDex][weth][farm] = [weth, farm];
    dexPaths[uniDex][dai][farm] = [dai, weth, farm];
    dexPaths[uniDex][usdc][farm] = [usdc, farm];
    dexPaths[uniDex][usdt][farm] = [usdt, weth, farm];

    dexPaths[uniDex][wbtc][farm] = [wbtc, weth, farm];
    dexPaths[uniDex][renBTC][farm] = [renBTC, weth, farm];

    // use Sushiswap for SUSHI, convert into WETH
    dexPaths[sushiDex][sushi][weth] = [sushi, weth];

    dexPaths[uniDex][dego][farm] = [dego, weth, farm];
    dexPaths[uniDex][crv][farm] = [crv, weth, farm];
    dexPaths[uniDex][comp][farm] = [comp, weth, farm];

    dexPaths[uniDex][idx][farm] = [idx, weth, farm];
    dexPaths[uniDex][idle][farm] = [idle, weth, farm];

    // use Sushiswap for MIS -> USDT
    dexPaths[sushiDex][mis][usdt] = [mis, usdt];
    dexPaths[uniDex][bsg][farm] = [bsg, dai, weth, farm];
    dexPaths[uniDex][bas][farm] = [bas, dai, weth, farm];
    dexPaths[uniDex][bsgs][farm] = [bsgs, dai, weth, farm];
    dexPaths[uniDex][kbtc][farm] = [kbtc, wbtc, weth, farm];
  }

  function getPath(bytes32 dex, address inputToken, address outputToken) public override view returns(address[] memory) {
    require(dexPaths[dex][inputToken][outputToken].length > 1, "Liquidation path is not set");
    return dexPaths[dex][inputToken][outputToken];
  }

  function setPath(bytes32 dex, address inputToken, address outputToken, address[] memory path) external override onlyOwner {
    // path could also be an empty array

    require(inputToken == path[0],
      "The first token of the Uniswap route must be the from token");
    require(outputToken == path[path.length - 1],
      "The last token of the Uniswap route must be the to token");

    // path can also be empty
    dexPaths[dex][inputToken][outputToken] = path;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

interface IUniversalLiquidatorRegistry {

  function universalLiquidator() external view returns(address);

  function setUniversalLiquidator(address _ul) external;

  function getPath(
    bytes32 dex,
    address inputToken,
    address outputToken
  ) external view returns(address[] memory);

  function setPath(
    bytes32 dex,
    address inputToken,
    address outputToken,
    address[] memory path
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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