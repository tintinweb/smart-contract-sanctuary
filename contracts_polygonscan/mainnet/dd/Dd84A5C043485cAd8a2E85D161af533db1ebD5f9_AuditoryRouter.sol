// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IAuditoryAssetPool.sol";

contract AuditoryRouter {
    constructor(address _auditoryAssetPool) {
        auditoryAssetPool = _auditoryAssetPool;
    }

    event LiquidityAdded(address user, uint256 amount);
    event LiquidityWithdrawn(address user, uint256 amount);

    address public auditoryAssetPool;

    function addLiquidity() public payable {
        uint256 _amount = msg.value;
        address _address = msg.sender;
        require(_amount > 0);
        uint256 remainingPoolFund = IAuditoryAssetPool(auditoryAssetPool)
        .remainingPoolValue();
        uint256 _amountToDeposit;
        require(
            remainingPoolFund > 0,
            "AssetPool is alread been Liquidated enough!"
        );
        if (_amount > remainingPoolFund) {
            _amountToDeposit = remainingPoolFund;
        }
        IAuditoryAssetPool(auditoryAssetPool).deposit{value: _amountToDeposit}(
            _address
        );
        emit LiquidityAdded(_address, _amount);
        if (_amount > remainingPoolFund)
            payable(msg.sender).transfer(_amount - remainingPoolFund);
    }

    function removeLiquidity(uint256 _amount) public payable {
        address _address = msg.sender;

        IAuditoryAssetPool(auditoryAssetPool).withdraw(_address, _amount);
        emit LiquidityWithdrawn(_address, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAuditoryAssetPool {
    function deposit(address sender) external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(address sender, uint256 amount) external;

    function remainingPoolValue() external returns (uint256);
}