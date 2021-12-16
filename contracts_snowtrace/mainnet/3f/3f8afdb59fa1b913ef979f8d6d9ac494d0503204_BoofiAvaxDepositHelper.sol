/**
 *Submitted for verification at snowtrace.io on 2021-12-16
*/

// File contracts/interfaces/IHauntedHouse.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IHauntedHouse {
    struct TokenInfo {
        address rewarder; // Address of rewarder for token
        address strategy; // Address of strategy for token
        uint256 lastRewardTime; // Last time that BOOFI distribution occurred for this token
        uint256 lastCumulativeReward; // Value of cumulativeAvgZboofiPerWeightedDollar at last update
        uint256 storedPrice; // Latest value of token
        uint256 accZBOOFIPerShare; // Accumulated BOOFI per share, times ACC_BOOFI_PRECISION.
        uint256 totalShares; //total number of shares for the token
        uint256 totalTokens; //total number of tokens deposited
        uint128 multiplier; // multiplier for this token
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
    }
    function BOOFI() external view returns (address);
    function strategyPool() external view returns (address);
    function performanceFeeAddress() external view returns (address);
    function updatePrice(address token, uint256 newPrice) external;
    function updatePrices(address[] calldata tokens, uint256[] calldata newPrices) external;
    function tokenList() external view returns (address[] memory);
    function tokenParameters(address tokenAddress) external view returns (TokenInfo memory);
    function deposit(address token, uint256 amount, address to) external;
    function harvest(address token, address to) external;
    function withdraw(address token, uint256 amountShares, address to) external;
}


// File contracts/interfaces/IWAVAX.sol

pragma solidity >=0.5.0;

interface IWAVAX {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}


// File contracts/BoofiAvaxDepositHelper.sol

pragma solidity ^0.8.6;


contract BoofiAvaxDepositHelper {

    IHauntedHouse public immutable hauntedHouse;
    IWAVAX public constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    constructor(
        IHauntedHouse _hauntedHouse
        ){
        require(address(_hauntedHouse) != address(0), "zero bad");
        hauntedHouse = _hauntedHouse;
        WAVAX.approve(address(_hauntedHouse), MAX_UINT);
    }

    function deposit() external payable {
        _deposit(msg.sender);
    }

    function depositTo(address to) external payable {
        _deposit(to);
    } 

    function _deposit(address to) internal {
        uint256 amount = msg.value;
        WAVAX.deposit{value: amount}();
        hauntedHouse.deposit(address(WAVAX), amount, to);
    }
}