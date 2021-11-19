// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interfaces/OracleRegistry.sol";
import "./interfaces/Oracle.sol";
import "./interfaces/LandSaleOracle.sol";

contract LandSaleOracleImpl is LandSaleOracle {
    // IlluviumOracleRegistry address
    address public illuviumOracleRegistry;
    address public weth;
    address public ilv;

    constructor(
        address _illuviumOracleRegistry,
        address _weth,
        address _ilv
    ) {
        require(_illuviumOracleRegistry != address(0), "Illuvium Oracle Registry cannot be zero");
        require(_weth != address(0), "WETH cannot be zero");
        require(_ilv != address(0), "ILV cannot be zero");

        illuviumOracleRegistry = _illuviumOracleRegistry;
        weth = _weth;
        ilv = _ilv;
    }

    /**
     * @notice get Ilv token amount equivalent to certain ethereum amount
     * @param ethIn ethereum amount
     */
    function ethToIlv(uint256 ethIn) external override returns (uint256) {
        address oracle = OracleRegistry(illuviumOracleRegistry).getOracle(weth, ilv);
        Oracle(oracle).update();
        return Oracle(oracle).consult(weth, ethIn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Land Sale Oracle Interface
 *
 * @notice Supports the Land Sale with the ETH/ILV conversion required,
 *       marker interface is required to support ERC165 lookups
 */
interface LandSaleOracle {
    /**
     * @notice Powers the ETH/ILV Land token price conversion, used when
     *      selling the land for sILV to determine how much sILV to accept
     *      instead of the nominated ETH price
     *
     * @notice Note that sILV price is considered to be equal to ILV price
     *
     * @param ethOut amount of ETH sale contract is expecting to get
     * @return ilvIn amount of sILV sale contract should accept instead
     */
    function ethToIlv(uint256 ethOut) external returns (uint256 ilvIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface Oracle {
    /**
     * @notice Updates the oracle with the price values if required, for example
     *      the cumulative price at the start and end of a period, etc.
     *
     * @dev This function is part of the oracle maintenance flow
     */
    function update() external;

    /**
     * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
     *      bought if the specified amount of token A to be sold
     *
     * @dev This function is part of the oracle usage flow
     *
     * @param token token A (token to sell) address
     * @param amountIn amount of token A to sell
     * @return amountOut amount of token B to be bought
     */
    function consult(address token, uint256 amountIn) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @title Oracle Registry interface
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 */

interface OracleRegistry {
    /**
     * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
     *
     * @param tokenA token A (token to sell) address
     * @param tokenB token B (token to buy) address
     * @return pairOracle pair price oracle address for A/B token pair
     */
    function getOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}