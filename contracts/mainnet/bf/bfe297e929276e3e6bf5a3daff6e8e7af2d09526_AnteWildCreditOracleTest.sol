/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity >=0.7.0;

/// @title The interface for the Ante V0.5 Ante Test
/// @notice The Ante V0.5 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);
}
pragma solidity >=0.7.0;

/// @title Ante V0.5 Ante Test smart contract
/// @notice Abstract inheritable contract that supplies syntactic sugar for writing Ante Tests
/// @dev Usage: contract YourAnteTest is AnteTest("String descriptor of test") { ... }
abstract contract AnteTest is IAnteTest {
    /// @inheritdoc IAnteTest
    address public override testAuthor;
    /// @inheritdoc IAnteTest
    string public override testName;
    /// @inheritdoc IAnteTest
    string public override protocolName;
    /// @inheritdoc IAnteTest
    address[] public override testedContracts;

    /// @dev testedContracts and protocolName are optional parameters which should
    /// be set in the constructor of your AnteTest
    /// @param _testName The name of the Ante Test
    constructor(string memory _testName) {
        testAuthor = msg.sender;
        testName = _testName;
    }

    /// @notice Returns the testedContracts array of addresses
    /// @return The list of tested contracts as an array of addresses
    function getTestedContracts() external view returns (address[] memory) {
        return testedContracts;
    }

    /// @inheritdoc IAnteTest
    function checkTestPasses() external virtual override returns (bool) {}
}

pragma solidity >=0.8.0;

interface IPriceOracle {
    function tokenPrice(address _token) external view returns (uint256);
}

// Ante Test to check if the Wild Credit reward pools Controller's token price is always within 1% of the UniswapV3Price oracle
// This will be useful in the event Wild Credit ever changes the price oracle and there would be discrepancies
contract AnteWildCreditOracleTest is
    AnteTest("Wild.Credit Controller price oracle is always the within 1% of Wild.Credit UniswapV3Oracle")
{
    // this is the uniswap v3 oracle deployed by wild credit
    IPriceOracle public constant uniswapV3Oracle = IPriceOracle(0x3D619bc03014917d3B27B3B86452346af36e58de);
    // this is the controller contract, we use the IPriceOracle interface as it has the same tokenPrice function
    IPriceOracle public constant controllerPriceOracle = IPriceOracle(0x45ee906E9CFAE0aabDB194D6180A3A119D4376C4);
    uint256 accuracy = 10e12;

    // these are the tokens used in wild credit rewardDistribution
    address[] tokenList = [
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
        0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b, // AXS
        0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0, // MATIC
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, // AAVE
        0xc00e94Cb662C3520282E6f5717214004A7f26888, // COMP
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F, // SNX
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, // MKR
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, // UNI
        0x514910771AF9Ca656af840dff83E8264EcF986CA, // LINK
        0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
        0xbC396689893D065F41bc2C6EcbeE5e0085233447, // PERP
        0x111111111117dC0aa78b770fA6A738034120C302, // 1INCH
        0x0391D2021f89DC339F60Fff84546EA23E337750f, // BOND
        0x08A75dbC7167714CeaC1a8e43a8d643A4EDd625a // WILD (this is not used in reward distribution and lending pairs but is in the oracle contract, we add it here just in case)
    ];

    constructor() {
        protocolName = "Wild Credit";
        testedContracts = [address(controllerPriceOracle)];
    }

    function checkTestPasses() public view override returns (bool) {
        // get add reward pools and check if prices match
        for (uint256 i = 0; i < tokenList.length; i++) {
            address token = tokenList[i];
            uint256 price1 = uniswapV3Oracle.tokenPrice(token);
            uint256 price2 = controllerPriceOracle.tokenPrice(token);

            // return false if price1 or price2 is 0
            if (price1 == 0 || price2 == 0) {
                return false;
            }

            if (!(((price1 * accuracy) / price2 > 99e11) && ((price2 * accuracy) / price1 > 99e11))) {
                return false;
            }
        }
        return true;
    }
}