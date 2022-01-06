// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "../AnteTest.sol";

interface IVault {
    function pricePerShare() external view returns (uint256);
}

// Ante Test to check alUSD supply never exceeds amount of DAI locked in Alchemix
contract Ante_alUSDSupplyTest is AnteTest("alUSD doesn't exceed DAI locked in Alchemix") {
    // https://etherscan.io/address/0xbc6da0fe9ad5f3b0d58160288917aa56653660e9
    address public constant alUSDAddr = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    // https://etherscan.io/token/0x6B175474E89094C44Da98b954EedeAC495271d0F
    address public constant DAIAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // https://etherscan.io/address/0xdA816459F1AB5631232FE5e97a05BBBb94970c95
    address public constant yvDAIAddr = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;

    address public constant AlchemistAddr = 0xc21D353FF4ee73C572425697f4F5aaD2109fe35b;
    address public constant TransmuterAddr = 0xaB7A49B971AFdc7Ee26255038C82b4006D122086;
    address public constant TransmuterBAddr = 0xeE69BD81Bd056339368c97c4B2837B4Dc4b796E7;
    address public constant AlchemistYVAAddr = 0xb039eA6153c827e59b620bDCd974F7bbFe68214A;
    address public constant TransmuterBYVAddr = 0x6Fe02BE0EC79dCF582cBDB936D7037d2eB17F661;

    IERC20 public DAIToken = IERC20(DAIAddr);
    IERC20 public alUSDToken = IERC20(alUSDAddr);
    IERC20 public yvDAIToken = IERC20(yvDAIAddr);
    IVault public yvDAIVault = IVault(yvDAIAddr);

    constructor() {
        protocolName = "Alchemix";
        testedContracts = [alUSDAddr];
    }

    function checkTestPasses() public view override returns (bool) {
        uint256 TransmuterVL = DAIToken.balanceOf(TransmuterAddr) / 1e18;
        uint256 AlchemistVL = DAIToken.balanceOf(AlchemistAddr) / 1e18;
        uint256 TransmuterBVL = DAIToken.balanceOf(TransmuterBAddr) / 1e18;
        uint256 PricePerShare = yvDAIVault.pricePerShare();
        uint256 AlchemistYVAVL = (yvDAIToken.balanceOf(AlchemistYVAAddr) * PricePerShare) / 1e36;
        uint256 TransmuterBYVAVL = (yvDAIToken.balanceOf(TransmuterBYVAddr) * PricePerShare) / 1e36;
        uint256 TotalValueLocked = TransmuterVL + AlchemistVL + TransmuterBVL + AlchemistYVAVL + TransmuterBYVAVL;
        uint256 TotalSupply = alUSDToken.totalSupply() / 1e18;
        return (TotalSupply <= TotalValueLocked);
    }

    function checkTransmuterVL() public view returns (uint256) {
        return DAIToken.balanceOf(TransmuterAddr) / 1e18;
    }

    function checkAlchemistVL() public view returns (uint256) {
        return DAIToken.balanceOf(AlchemistAddr) / 1e18;
    }

    function checkTransmuterBVL() public view returns (uint256) {
        return DAIToken.balanceOf(TransmuterBAddr) / 1e18;
    }

    function checkAlchemistYVAVL() public view returns (uint256) {
        uint256 PricePerShare = yvDAIVault.pricePerShare();
        return (yvDAIToken.balanceOf(AlchemistYVAAddr) * PricePerShare) / 1e36;
    }

    function checkTransmuterBYVAVL() public view returns (uint256) {
        uint256 PricePerShare = yvDAIVault.pricePerShare();
        return (yvDAIToken.balanceOf(TransmuterBYVAddr) * PricePerShare) / 1e36;
    }

    function checkBalance() public view returns (uint256) {
        uint256 TransmuterVL = DAIToken.balanceOf(TransmuterAddr) / 1e18;
        uint256 AlchemistVL = DAIToken.balanceOf(AlchemistAddr) / 1e18;
        uint256 TransmuterBVL = DAIToken.balanceOf(TransmuterBAddr) / 1e18;
        uint256 PricePerShare = yvDAIVault.pricePerShare();
        uint256 AlchemistYVAVL = (yvDAIToken.balanceOf(AlchemistYVAAddr) * PricePerShare) / 1e36;
        uint256 TransmuterBYVAVL = (yvDAIToken.balanceOf(TransmuterBYVAddr) * PricePerShare) / 1e36;
        return TransmuterVL + AlchemistVL + TransmuterBVL + AlchemistYVAVL + TransmuterBYVAVL;
    }

    function checkCirculating() public view returns (uint256) {
        return alUSDToken.totalSupply() / 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity >=0.7.0;

import "./interfaces/IAnteTest.sol";

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

// SPDX-License-Identifier: GPL-3.0-only

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