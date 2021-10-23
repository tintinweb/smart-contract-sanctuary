// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IConfig.sol";
import "./utils/Ownable.sol";

contract Config is IConfig, Ownable {
    address public override priceOracle;
    uint256 public override rebasePriceGap;
    uint256 public override initMarginRatio; //if 1000, means margin ratio >= 10%
    uint256 public override liquidateThreshold; //if 10000, means debt ratio < 100%
    uint256 public override liquidateFeeRatio; //if 100, means liquidator bot get 1% as fee

    uint256 public override liquidateIncentive;
    bool public override onlyPCV;
    uint8 public override beta; // 50-100

    constructor() {}

    function admin() external view override returns (address) {
        return _admin;
    }

    function pendingAdmin() external view override returns (address) {
        return _pendingAdmin;
    }

    function acceptAdmin() external override {
        _acceptAdmin();
    }

    function setPendingAdmin(address newPendingAdmin) external override {
        _setPendingAdmin(newPendingAdmin);
    }

    function setLiquidateIncentive(uint256 newIncentive) external override {}

    function setPriceOracle(address newOracle) external override {
        require(newOracle != address(0), "Config: ZERO_ADDRESS");
        emit PriceOracleChanged(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function setRebasePriceGap(uint256 newGap) external override {
        require(newGap > 0, "Config: ZERO_GAP");
        emit RebasePriceGapChanged(rebasePriceGap, newGap);
        rebasePriceGap = newGap;
    }

    function setInitMarginRatio(uint256 _initMarginRatio) external onlyAdmin {
        require(_initMarginRatio >= 500, "ratio >= 500");
        initMarginRatio = _initMarginRatio;
    }

    function setLiquidateThreshold(uint256 _liquidateThreshold) external onlyAdmin {
        require(_liquidateThreshold > 9000 && _liquidateThreshold <= 10000, "9000 < liquidateThreshold <= 10000");
        liquidateThreshold = _liquidateThreshold;
    }

    function setLiquidateFeeRatio(uint256 _liquidateFeeRatio) external onlyAdmin {
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
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event LiquidateIncentiveChanged(uint256 oldIncentive, uint256 newIncentive);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);

    function pendingAdmin() external view returns (address);

    function admin() external view returns (address);

    function priceOracle() external view returns (address);

    function beta() external view returns (uint8);

    function liquidateIncentive() external view returns (uint256);

    function initMarginRatio() external view returns (uint256);

    function liquidateThreshold() external view returns (uint256);

    function liquidateFeeRatio() external view returns (uint256);

    function rebasePriceGap() external view returns (uint256);

    function onlyPCV() external view returns (bool);

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

    function setPriceOracle(address newOracle) external;

    function setBeta(uint8 _beta) external;

    function setLiquidateIncentive(uint256 newIncentive) external;

    function setRebasePriceGap(uint256 newGap) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public _admin;
    address public _pendingAdmin;

    event OwnershipTransfer(address indexed previousAdmin, address indexed pendingAdmin);
    event OwnershipAccept(address indexed currentAdmin);

    constructor() {
        _admin = msg.sender;
    }

    function _setPendingAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Ownable: new admin is the zero address");
        require(newAdmin != _pendingAdmin, "Ownable: already set");
        _pendingAdmin = newAdmin;
        emit OwnershipTransfer(_admin, newAdmin);
    }

    function _acceptAdmin() public {
        require(msg.sender == _pendingAdmin, "Ownable: not pendingAdmin");
        _admin = _pendingAdmin;
        _pendingAdmin = address(0);
        emit OwnershipAccept(_pendingAdmin);
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender, "Ownable: caller is not the admin");
        _;
    }
}