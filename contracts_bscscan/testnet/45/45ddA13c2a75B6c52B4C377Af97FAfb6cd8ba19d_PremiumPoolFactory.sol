// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../PremiumPool.sol";
import "../interfaces/IPremiumPoolFactory.sol";

contract PremiumPoolFactory is IPremiumPoolFactory {
    constructor() {}

    function newPremiumPool(address _currency, uint256 _minimum) external override returns (address) {
        PremiumPool _premiumPool = new PremiumPool(msg.sender, _currency, _minimum);
        address _premiumPoolAddr = address(_premiumPool);

        return _premiumPoolAddr;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./libraries/TransferHelper.sol";
import "./interfaces/IPremiumPool.sol";

contract PremiumPool is IPremiumPool {
    address private cohort;

    mapping(uint16 => uint256) private _balances; // protocol => premium
    mapping(uint16 => uint256) private _premiumReward; // protocol => total premium reward

    uint256 private _minimumPremium;
    address public override currency;

    event PremiumDeposited(uint16 indexed protocolIdx, uint256 amount);
    event TransferAsset(address indexed _to, uint256 _amount);

    constructor(
        address _cohort,
        address _currency,
        uint256 _minimum
    ) {
        cohort = _cohort;
        currency = _currency;
        _minimumPremium = _minimum;
    }

    modifier onlyCohort() {
        require(msg.sender == cohort, "UnoRe: Not cohort");
        _;
    }

    function balanceOf(uint16 _protocolIdx) external view override returns (uint256) {
        return _balances[_protocolIdx];
    }

    /**
     * @dev This function gives the total premium reward after coverage
     */
    function premiumRewardOf(uint16 _protocolIdx) external view override returns (uint256) {
        return _premiumReward[_protocolIdx] == 0 ? _balances[_protocolIdx] : _premiumReward[_protocolIdx];
    }

    function minimumPremium() external view override returns (uint256) {
        return _minimumPremium;
    }

    /**
     * @dev Once premiumReward is set, it is fixed value, not changed according to balance
     */
    function setPremiumReward(uint16 _protocolIdx) external override onlyCohort {
        _premiumReward[_protocolIdx] = _balances[_protocolIdx];
    }

    /**
     * It is a bit confusing thing, there's only balance increase without transfer.
     * But it is Okay, because this PremiumPool and depositPremium function is fully controlled
     * by Cohort and depositPremium function in Cohort smart contract.
     */
    function depositPremium(uint16 _protocolIdx, uint256 _amount) external override onlyCohort {
        _balances[_protocolIdx] += _amount;
        emit PremiumDeposited(_protocolIdx, _amount);
    }

    function withdrawPremium(
        address _to,
        uint16 _protocolIdx,
        uint256 _amount
    ) external override onlyCohort {
        require(_balances[_protocolIdx] >= _amount, "UnoRe: Insufficient Premium");
        _balances[_protocolIdx] -= _amount;
        TransferHelper.safeTransfer(currency, _to, _amount);
    }

    function transferAsset(
        uint16 _protocolIdx,
        address _to,
        uint256 _amount
    ) external override onlyCohort {
        _balances[_protocolIdx] -= _amount;
        TransferHelper.safeTransfer(currency, _to, _amount);
        emit TransferAsset(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPoolFactory {
    function newPremiumPool(address _currency, uint256 _minimum) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
    function depositPremium(uint16 _protocolIdx, uint256 _amount) external;

    function withdrawPremium(
        address _to,
        uint16 _protocolIdx,
        uint256 _amount
    ) external;

    function transferAsset(
        uint16 _protocolIdx,
        address _to,
        uint256 _amount
    ) external;

    function minimumPremium() external returns (uint256);

    function balanceOf(uint16 _protocolIdx) external view returns (uint256);

    function premiumRewardOf(uint16 _protocolIdx) external returns (uint256);

    function currency() external view returns (address);

    function setPremiumReward(uint16 _protocolIdx) external;
}

