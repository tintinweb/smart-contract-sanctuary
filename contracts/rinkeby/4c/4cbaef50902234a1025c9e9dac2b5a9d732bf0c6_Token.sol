//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface ILiquidityRestrictor {
    function assureByAgent(
        address token,
        address from,
        address to
    ) external returns (bool allow, string memory message);

    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message);
}

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);
}

contract Token is ERC20, Ownable, Pausable {
    constructor() ERC20('DeFly Ball Token', 'DEFLY') {
        _mint(msg.sender, 100000000 * 10**18);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    IAntisnipe public antisnipe = IAntisnipe(0x755d87Dd1f0B636D902d8f0910080D0044bA892F);
    ILiquidityRestrictor public liquidityRestrictor =
        ILiquidityRestrictor(0xeD1261C063563Ff916d7b1689Ac7Ef68177867F2);

    bool public antisnipeEnabled = true;
    bool public liquidityRestrictionEnabled = true;

    event AntisnipeDisabled(uint256 timestamp, address user);
    event LiquidityRestrictionDisabled(uint256 timestamp, address user);
    event AntisnipeAddressChanged(address addr);
    event LiquidityRestrictionAddressChanged(address addr);

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0) || to == address(0)) return;
        if (liquidityRestrictionEnabled && address(liquidityRestrictor) != address(0)) {
            (bool allow, string memory message) = liquidityRestrictor
                .assureLiquidityRestrictions(from, to);
            require(allow, message);
        }

        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(antisnipe.assureCanTransfer(msg.sender, from, to, amount));
        }
    }

    function setAntisnipeDisable() external onlyOwner {
        require(antisnipeEnabled);
        antisnipeEnabled = false;
        emit AntisnipeDisabled(block.timestamp, msg.sender);
    }

    function setLiquidityRestrictorDisable() external onlyOwner {
        require(liquidityRestrictionEnabled);
        liquidityRestrictionEnabled = false;
        emit LiquidityRestrictionDisabled(block.timestamp, msg.sender);
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
        emit AntisnipeAddressChanged(addr);
    }

    function setLiquidityRestrictionAddress(address addr) external onlyOwner {
        liquidityRestrictor = ILiquidityRestrictor(addr);
        emit LiquidityRestrictionAddressChanged(addr);
    }
}