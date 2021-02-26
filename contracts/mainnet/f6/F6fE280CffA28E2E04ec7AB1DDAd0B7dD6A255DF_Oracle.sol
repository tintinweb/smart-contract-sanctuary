// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";
import "./interfaces/IKeeperOracle.sol";
import "./ERC20/IERC20.sol";
import "./utils/Ownable.sol";
import "./interfaces/IOracle.sol";

contract Oracle is IOracle, Ownable {
    mapping(address => address) public chainlinkPriceUSD;
    mapping(address => address) public chainlinkPriceETH;

    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IKeeperOracle public uniswapKeeperOracle = IKeeperOracle(0x73353801921417F465377c8d898c6f4C0270282C);
    IKeeperOracle public sushiswapKeeperOracle = IKeeperOracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);

    constructor () {
        chainlinkPriceUSD[weth] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
        chainlinkPriceUSD[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // wBTC
        chainlinkPriceUSD[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // renBTC
        chainlinkPriceUSD[0x4688a8b1F292FDaB17E9a90c8Bc379dC1DBd8713] = 0x0ad50393F11FfAc4dd0fe5F1056448ecb75226Cf; // COVER
        chainlinkPriceUSD[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9; // DAI
        chainlinkPriceUSD[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC
        chainlinkPriceUSD[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D; // USDT

        chainlinkPriceETH[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = 0x7c5d4F8345e66f68099581Db340cd65B078C41f4; // YFI
        chainlinkPriceETH[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = 0xe572CeF69f43c2E488b33924AF04BDacE19079cf; // SUSHI
        chainlinkPriceETH[0x4E15361FD6b4BB609Fa63C81A2be19d873717870] = 0x2DE7E4a9488488e0058B95854CC2f7955B35dC9b; // FTM
        chainlinkPriceETH[0x2ba592F78dB6436527729929AAf6c908497cB200] = 0x82597CFE6af8baad7c0d441AA82cbC3b51759607; // CREAM
        chainlinkPriceETH[0x4688a8b1F292FDaB17E9a90c8Bc379dC1DBd8713] = 0x7B6230EF79D5E97C11049ab362c0b685faCBA0C2; // COVER
        initializeOwner();
    }

    /// @notice Returns price in USD multiplied by 1e8, chainlink.latestAnswer returns 1e8 for all answers, KeeperOracle.current returns 1e18
    function getPriceUSD(address _asset) external override view returns (uint256 price) {
        // Iftoken has ChainLink USD oracle
        if (chainlinkPriceUSD[_asset] != address(0)) {
            price = IChainLinkOracle(chainlinkPriceUSD[_asset]).latestAnswer();
        } else { // Fetch token price in ETH
            // wethPrice(USD) is 1e8
            uint256 wethPrice = IChainLinkOracle(chainlinkPriceUSD[weth]).latestAnswer();
            
            // If token has ChainLink ETH oracle
            if (chainlinkPriceETH[_asset] != address(0)) {
                // all price returned in ETH are 1e18
                uint256 _priceInETH = IChainLinkOracle(chainlinkPriceETH[_asset]).latestAnswer();
                // all price returned in USD are 1e8
                price = _priceInETH * wethPrice / 1e18;
            } else { // All Keeper oracle prices are in ETH (1e8)
                uint256 decimals = IERC20(_asset).decimals();

                // If token has SushiSwap Keeper oracle
                address sushiPair = sushiswapKeeperOracle.pairFor(_asset, weth);
                if (sushiswapKeeperOracle.observationLength(sushiPair) > 0) {
                    uint256 _priceInETH = sushiswapKeeperOracle.current(_asset, 10 ** decimals, weth);
                    price = _priceInETH * wethPrice / 1e18;
                } else { // If token has Uniswap Keeper oracle
                
                    // Fetch Uniswap pair here to avoid extra call above
                    address uniPair = uniswapKeeperOracle.pairFor(_asset, weth);
                    if (uniswapKeeperOracle.observationLength(uniPair) > 0) {
                        uint256 _priceInETH = uniswapKeeperOracle.current(_asset, 10 ** decimals, weth);
                        price = _priceInETH * wethPrice / 1e18;
                    }
                }
            }
        }
    }

    function updateFeedETH(address _asset, address _feed) external override onlyOwner {
        chainlinkPriceETH[_asset] = _feed; // 0x0 to remove feed
    }
    
    function updateFeedUSD(address _asset, address _feed) external override onlyOwner {
        chainlinkPriceUSD[_asset] = _feed; // 0x0 to remove feed
    }

    function setSushiKeeperOracle(address _sushiOracle) external override onlyOwner {
        require(_sushiOracle != address(0), "Oracle: IKeeperOracle is 0");
        sushiswapKeeperOracle = IKeeperOracle(_sushiOracle);
    }

    function setUniKeeperOracle(address _uniOracle) external override onlyOwner {
        require(_uniOracle != address(0), "Oracle: IKeeperOracle is 0");
        uniswapKeeperOracle = IKeeperOracle(_uniOracle);
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IKeeperOracle {
    function current(address, uint, address) external view returns (uint256);
    function pairFor(address, address) external view returns (address);
    function observationLength(address) external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Ruler: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;

interface IOracle {
    function getPriceUSD(address _asset) external view returns (uint256 price);
    
    // admin functions
    function updateFeedETH(address _asset, address _feed) external;
    function updateFeedUSD(address _asset, address _feed) external;
    function setSushiKeeperOracle(address _sushiOracle) external;
    function setUniKeeperOracle(address _uniOracle) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}