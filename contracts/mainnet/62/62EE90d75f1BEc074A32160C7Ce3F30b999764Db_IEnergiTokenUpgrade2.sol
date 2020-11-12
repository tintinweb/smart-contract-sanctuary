// Copyright (C) 2020 Energi Core

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.0;

interface IEnergiTokenUpgrade2 {

    function owner() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function initialized() external view returns (bool);

    function vault() external view returns (address);

    function minRedemptionAmount() external view returns (uint);

    function upgradeInitialized() external view returns (bool);

    function setOwner(address _owner) external;

    function setSymbol(string calldata _symbol) external;

    function setVault(address _vault) external;

    function setMinRedemptionAmount(uint _minRedemptionAmount) external;

    function mint(address recipient, uint amount) external;

    function burn(address recipient, uint amount) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
