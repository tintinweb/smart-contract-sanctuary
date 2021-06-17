/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/// NoRebalanceStabilityFeeTreasury.sol

// Copyright (C) 2018 Rain <[email protected]>, 2020 Reflexer Labs, INC

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

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function approveSAFEModification(address) virtual external;
    function denySAFEModification(address) virtual external;
    function transferInternalCoins(address,address,uint256) virtual external;
    function settleDebt(uint256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
}
abstract contract SystemCoinLike {
    function balanceOf(address) virtual public view returns (uint256);
    function approve(address, uint256) virtual public returns (uint256);
    function transfer(address,uint256) virtual public returns (bool);
    function transferFrom(address,address,uint256) virtual public returns (bool);
}
abstract contract CoinJoinLike {
    function systemCoin() virtual public view returns (address);
    function join(address, uint256) virtual external;
}

contract NoRebalanceStabilityFeeTreasury {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "NoRebalanceStabilityFeeTreasury/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event SetTotalAllowance(address indexed account, uint256 rad);
    event SetPerBlockAllowance(address indexed account, uint256 rad);
    event GiveFunds(address indexed account, uint256 rad);
    event TakeFunds(address indexed account, uint256 rad);
    event PullFunds(address indexed sender, address indexed dstAccount, address token, uint256 rad);

    // --- Structs ---
    struct Allowance {
        uint256 total;
        uint256 perBlock;
    }

    mapping(address => Allowance)                   private allowance;
    mapping(address => mapping(uint256 => uint256)) public pulledPerBlock;

    SAFEEngineLike  public safeEngine;
    SystemCoinLike  public systemCoin;
    CoinJoinLike    public coinJoin;

    uint256 public pullFundsMinThreshold;      // minimum funds that must be in the treasury so that someone can pullFunds [rad]
    uint256 public latestSurplusTransferTime;  // latest timestamp when transferSurplusFunds was called                    [seconds]
    uint256 public contractEnabled;

    modifier accountNotTreasury(address account) {
        require(account != address(this), "NoRebalanceStabilityFeeTreasury/account-cannot-be-treasury");
        _;
    }

    constructor(
        address safeEngine_,
        address coinJoin_
    ) public {
        require(address(CoinJoinLike(coinJoin_).systemCoin()) != address(0), "NoRebalanceStabilityFeeTreasury/null-system-coin");
  
        authorizedAccounts[msg.sender] = 1;
        safeEngine                = SAFEEngineLike(safeEngine_);
        coinJoin                  = CoinJoinLike(coinJoin_);
        systemCoin                = SystemCoinLike(coinJoin.systemCoin());

        systemCoin.approve(address(coinJoin), uint256(-1));

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    uint256 constant HUNDRED = 10 ** 2;
    uint256 constant RAY     = 10 ** 27;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "NoRebalanceStabilityFeeTreasury/add-uint-uint-overflow");
    }
    function addition(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
        if (y <= 0) require(z <= x, "NoRebalanceStabilityFeeTreasury/add-int-int-underflow");
        if (y  > 0) require(z > x, "NoRebalanceStabilityFeeTreasury/add-int-int-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "NoRebalanceStabilityFeeTreasury/sub-uint-uint-underflow");
    }
    function subtract(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
        require(y <= 0 || z <= x, "NoRebalanceStabilityFeeTreasury/sub-int-int-underflow");
        require(y >= 0 || z >= x, "NoRebalanceStabilityFeeTreasury/sub-int-int-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "NoRebalanceStabilityFeeTreasury/mul-uint-uint-overflow");
    }
    function divide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "NoRebalanceStabilityFeeTreasury/div-y-null");
        z = x / y;
        require(z <= x, "NoRebalanceStabilityFeeTreasury/div-invalid");
    }
    function minimum(uint256 x, uint256 y) internal view returns (uint256 z) {
        z = (x <= y) ? x : y;
    }

    // --- Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    /**
     * @notice Join all ERC20 system coins that the treasury has inside SAFEEngine
     */
    function joinAllCoins() internal {
        if (systemCoin.balanceOf(address(this)) > 0) {
          coinJoin.join(address(this), systemCoin.balanceOf(address(this)));
        }
    }
    function settleDebt() public {
        uint256 coinBalanceSelf = safeEngine.coinBalance(address(this));
        uint256 debtBalanceSelf = safeEngine.debtBalance(address(this));

        if (debtBalanceSelf > 0) {
          safeEngine.settleDebt(minimum(coinBalanceSelf, debtBalanceSelf));
        }
    }

    // --- Getters ---
    function getAllowance(address account) public view returns (uint256, uint256) {
        return (allowance[account].total, allowance[account].perBlock);
    }

    // --- SF Transfer Allowance ---
    /**
     * @notice Modify an address' total allowance in order to withdraw SF from the treasury
     * @param account The approved address
     * @param rad The total approved amount of SF to withdraw (number with 45 decimals)
     */
    function setTotalAllowance(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        require(account != address(0), "NoRebalanceStabilityFeeTreasury/null-account");
        allowance[account].total = rad;
        emit SetTotalAllowance(account, rad);
    }
    /**
     * @notice Modify an address' per block allowance in order to withdraw SF from the treasury
     * @param account The approved address
     * @param rad The per block approved amount of SF to withdraw (number with 45 decimals)
     */
    function setPerBlockAllowance(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        require(account != address(0), "NoRebalanceStabilityFeeTreasury/null-account");
        allowance[account].perBlock = rad;
        emit SetPerBlockAllowance(account, rad);
    }

    // --- Stability Fee Transfer (Governance) ---
    /**
     * @notice Governance transfers SF to an address
     * @param account Address to transfer SF to
     * @param rad Amount of internal system coins to transfer (a number with 45 decimals)
     */
    function giveFunds(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        require(account != address(0), "NoRebalanceStabilityFeeTreasury/null-account");

        joinAllCoins();
        settleDebt();

        require(safeEngine.debtBalance(address(this)) == 0, "NoRebalanceStabilityFeeTreasury/outstanding-bad-debt");
        require(safeEngine.coinBalance(address(this)) >= rad, "NoRebalanceStabilityFeeTreasury/not-enough-funds");

        safeEngine.transferInternalCoins(address(this), account, rad);
        emit GiveFunds(account, rad);
    }
    /**
     * @notice Governance takes funds from an address
     * @param account Address to take system coins from
     * @param rad Amount of internal system coins to take from the account (a number with 45 decimals)
     */
    function takeFunds(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        safeEngine.transferInternalCoins(account, address(this), rad);
        emit TakeFunds(account, rad);
    }

    // --- Stability Fee Transfer (Approved Accounts) ---
    /**
     * @notice Pull stability fees from the treasury (if your allowance permits)
     * @param dstAccount Address to transfer funds to
     * @param token Address of the token to transfer (in this case it must be the address of the ERC20 system coin).
     *              Used only to adhere to a standard for automated, on-chain treasuries
     * @param wad Amount of system coins (SF) to transfer (expressed as an 18 decimal number but the contract will transfer
              internal system coins that have 45 decimals)
     */
    function pullFunds(address dstAccount, address token, uint256 wad) external {
        if (dstAccount == address(this)) return;
        require(allowance[msg.sender].total >= multiply(wad, RAY), "NoRebalanceStabilityFeeTreasury/not-allowed");
        require(dstAccount != address(0), "NoRebalanceStabilityFeeTreasury/null-dst");
        require(wad > 0, "NoRebalanceStabilityFeeTreasury/null-transfer-amount");
        require(token == address(systemCoin), "NoRebalanceStabilityFeeTreasury/token-unavailable");
        if (allowance[msg.sender].perBlock > 0) {
          require(addition(pulledPerBlock[msg.sender][block.number], multiply(wad, RAY)) <= allowance[msg.sender].perBlock, "NoRebalanceStabilityFeeTreasury/per-block-limit-exceeded");
        }

        pulledPerBlock[msg.sender][block.number] = addition(pulledPerBlock[msg.sender][block.number], multiply(wad, RAY));

        joinAllCoins();
        settleDebt();

        require(safeEngine.debtBalance(address(this)) == 0, "NoRebalanceStabilityFeeTreasury/outstanding-bad-debt");
        require(safeEngine.coinBalance(address(this)) >= multiply(wad, RAY), "NoRebalanceStabilityFeeTreasury/not-enough-funds");

        // Update allowance
        allowance[msg.sender].total = subtract(allowance[msg.sender].total, multiply(wad, RAY));

        // Transfer money
        safeEngine.transferInternalCoins(address(this), dstAccount, multiply(wad, RAY));

        emit PullFunds(msg.sender, dstAccount, token, multiply(wad, RAY));
    }
}