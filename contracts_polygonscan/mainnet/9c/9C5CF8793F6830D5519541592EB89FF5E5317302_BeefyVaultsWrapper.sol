// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;

interface IVaultsWrapper {
    function deposit(address _vault, uint256) external payable;

    function withdraw(address _vault, uint256) external;

    function balanceOf(address _vault, address) external view returns (uint256);

    function pricePerShare(address _vault) external view returns (uint256);

    // pricePerShare Numerator
    function ppsNum(address _vault) external view returns (uint256);

    // pricePerShare Numerator
    function ppsDenom(address _vault) external view returns (uint256);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice Wrapper for Vaults to standardize interfaces
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../IVaultsWrapper.sol";

interface IBeefyVault {
    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 _amount) external;

    function getPricePerFullShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 _shares) external;
}

contract BeefyVaultsWrapper is IVaultsWrapper {
    function deposit(address _vault, uint256 _amount)
        external
        payable
        override
    {
        IBeefyVault(_vault).deposit(_amount);
    }

    function withdraw(address _vault, uint256 _amount) external override {
        IBeefyVault(_vault).withdraw(_amount);
    }

    // --- View Functions ---
    function balanceOf(address _vault, address _user)
        external
        view
        override
        returns (uint256)
    {
        return IBeefyVault(_vault).balanceOf(_user);
    }

    function pricePerShare(address _vault)
        external
        view
        override
        returns (uint256)
    {
        return IBeefyVault(_vault).getPricePerFullShare();
    }

    function ppsNum(address _vault) external view override returns (uint256) {
        return IBeefyVault(_vault).balance();
    }

    function ppsDenom(address _vault) external view override returns (uint256) {
        return IBeefyVault(_vault).totalSupply();
    }
}