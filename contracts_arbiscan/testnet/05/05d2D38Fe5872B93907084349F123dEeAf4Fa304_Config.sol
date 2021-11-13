// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IConfig.sol";
import "./utils/Initializable.sol";

contract Config is IConfig, Initializable {
    address public override priceOracle;
    address public admin;

    uint256 public override rebasePriceGap;
    uint256 public override initMarginRatio; //if 1000, means margin ratio >= 10%
    uint256 public override liquidateThreshold; //if 10000, means debt ratio < 100%
    uint256 public override liquidateFeeRatio; //if 100, means liquidator bot get 1% as fee
    uint8 public override beta; // 50-100

    modifier onlyAdmin() {
        require(msg.sender == admin, "Ownable: REQUIRE_ADMIN");
        _;
    }

    function initialize(address _admin, uint8 _beta) public initializer {
        admin = _admin;
        beta = _beta;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function setPriceOracle(address newOracle) external override onlyAdmin {
        require(newOracle != address(0), "Config: ZERO_ADDRESS");
        emit PriceOracleChanged(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function setRebasePriceGap(uint256 newGap) external override onlyAdmin {
        require(newGap > 0, "Config: ZERO_GAP");
        emit RebasePriceGapChanged(rebasePriceGap, newGap);
        rebasePriceGap = newGap;
    }

    function setInitMarginRatio(uint256 _initMarginRatio) external override onlyAdmin {
        require(_initMarginRatio >= 500, "ratio >= 500");
        initMarginRatio = _initMarginRatio;
    }

    function setLiquidateThreshold(uint256 _liquidateThreshold) external override onlyAdmin {
        require(_liquidateThreshold > 9000 && _liquidateThreshold <= 10000, "9000 < liquidateThreshold <= 10000");
        liquidateThreshold = _liquidateThreshold;
    }

    function setLiquidateFeeRatio(uint256 _liquidateFeeRatio) external override onlyAdmin {
        require(_liquidateFeeRatio > 0 && _liquidateFeeRatio <= 2000, "0 < liquidateFeeRatio <= 2000");
        liquidateFeeRatio = _liquidateFeeRatio;
    }

    function setBeta(uint8 _beta) external override onlyAdmin {
        beta = _beta;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IConfig {
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);

    function priceOracle() external view returns (address);

    function beta() external view returns (uint8);

    function initMarginRatio() external view returns (uint256);

    function liquidateThreshold() external view returns (uint256);

    function liquidateFeeRatio() external view returns (uint256);

    function rebasePriceGap() external view returns (uint256);

    function setPriceOracle(address newOracle) external;

    function setBeta(uint8 _beta) external;

    function setRebasePriceGap(uint256 newGap) external;

    function setInitMarginRatio(uint256 _initMarginRatio) external;

    function setLiquidateThreshold(uint256 _liquidateThreshold) external;

    function setLiquidateFeeRatio(uint256 _liquidateFeeRatio) external;
}

pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}