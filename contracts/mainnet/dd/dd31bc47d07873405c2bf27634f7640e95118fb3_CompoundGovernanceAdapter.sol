// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../ERC20.sol";
import { ProtocolAdapter } from "../ProtocolAdapter.sol";


/**
 * @dev CompMarketState contract interface.
 * Only the functions required for CompoundGovernanceAdapter contract are added.
 * The CompMarketState struct is available here
 * github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerStorage.sol.
 */
struct CompMarketState {
    uint224 index;
    uint32 block;
}


/**
 * @dev Comptroller contract interface.
 * Only the functions required for CompoundGovernanceAdapter contract are added.
 * The Comptroller contract is available here
 * github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol.
 */
interface Comptroller {
    function getAllMarkets() external view returns (address[] memory);
    function compBorrowState(address) external view returns (CompMarketState memory);
    function compSupplyState(address) external view returns (CompMarketState memory);
    function compBorrowerIndex(address, address) external view returns (uint256);
    function compSupplierIndex(address, address) external view returns (uint256);
    function compAccrued(address) external view returns (uint256);
}


/**
 * @dev CToken contract interface.
 * Only the functions required for CompoundGovernanceAdapter contract are added.
 * The CToken contract is available here
 * github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol.
 */
interface CToken {
    function borrowBalanceStored(address) external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}


/**
 * @title Asset adapter for Compound Governance.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract CompoundGovernanceAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    /**
     * @return Amount of unclaimed COMP by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address account) external view override returns (uint256) {
        uint256 balance = Comptroller(COMPTROLLER).compAccrued(account);
        address[] memory allMarkets = Comptroller(COMPTROLLER).getAllMarkets();

        for (uint256 i = 0; i < allMarkets.length; i++) {
            balance += borrowerComp(account, allMarkets[i]);
            balance += supplierComp(account, allMarkets[i]);
        }

        return balance;
    }

    function borrowerComp(address account, address cToken) internal view returns (uint256) {
        uint256 borrowerIndex = Comptroller(COMPTROLLER).compBorrowerIndex(cToken, account);

        if (borrowerIndex > 0) {
            uint256 borrowIndex = uint256(Comptroller(COMPTROLLER).compBorrowState(cToken).index);
            require(borrowIndex >= borrowerIndex, "CGA: underflow!");
            uint256 deltaIndex = borrowIndex - borrowerIndex;
            uint256 borrowerAmount = mul(
                CToken(cToken).borrowBalanceStored(account),
                1e18
            ) / CToken(cToken).borrowIndex();
            uint256 borrowerDelta = mul(borrowerAmount, deltaIndex) / 1e36;
            return borrowerDelta;
        } else {
            return 0;
        }
    }

    function supplierComp(address account, address cToken) internal view returns (uint256) {
        uint256 supplierIndex = Comptroller(COMPTROLLER).compSupplierIndex(cToken, account);
        uint256 supplyIndex = uint256(Comptroller(COMPTROLLER).compSupplyState(cToken).index);
        if (supplierIndex == 0 && supplyIndex > 0) {
            supplierIndex = 1e36;
        }
        require(supplyIndex >= supplierIndex, "CGA: underflow!");
        uint256 deltaIndex = supplyIndex - supplierIndex;
        uint256 supplierAmount = CToken(cToken).balanceOf(account);
        uint256 supplierDelta = mul(supplierAmount, deltaIndex) / 1e36;

        return supplierDelta;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "CGA: mul overflow");

        return c;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


/**
 * @title Protocol adapter interface.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
interface ProtocolAdapter {

    /**
     * @dev MUST return "Asset" or "Debt".
     * SHOULD be implemented by the public constant state variable.
     */
    function adapterType() external pure returns (string memory);

    /**
     * @dev MUST return token type (default is "ERC20").
     * SHOULD be implemented by the public constant state variable.
     */
    function tokenType() external pure returns (string memory);

    /**
     * @dev MUST return amount of the given token locked on the protocol by the given account.
     */
    function getBalance(address token, address account) external view returns (uint256);
}

