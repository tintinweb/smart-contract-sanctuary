/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/libraries/SafeERC20.sol

pragma solidity >=0.7.5;

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}


// File contracts/interfaces/ITreasury.sol

pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}


// File contracts/interfaces/IOlympusAuthority.sol

pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}


// File contracts/types/OlympusAccessControlled.sol

pragma solidity >=0.7.5;

abstract contract OlympusAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}


// File contracts/allocators/MetaGovernanceAllocator.sol

pragma solidity ^0.8.10;


interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function unstake( uint _amount, bool _trigger ) external;
    function claim ( address _recipient ) external;
}

/// @title   Meta Governance Allocator
/// @author  Olympus
/// @notice  Manages BTRFLY or LOBI from treasury to stake back to treasury
contract MetaGovernanceAllocator is OlympusAccessControlled {
    using SafeERC20 for IERC20;

    /// @notice Olympus Treasury
    ITreasury internal treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);
    /// @notice BTRFLY token address
    address internal immutable BTRFLY = 0xC0d4Ceb216B3BA9C3701B291766fDCbA977ceC3A;
    /// @notice Staked BTRFLY token address
    address internal immutable xBTRFLY = 0xCC94Faf235cC5D3Bf4bEd3a30db5984306c86aBC;
    /// @notice Redacted staking contract
    address internal immutable redactedStaking = 0xBdE4Dfb0dbb0Dd8833eFb6C5BD0Ce048C852C487;
    /// @notice LOBI token address
    address internal immutable LOBI = 0xDEc41Db0c33F3F6f3cb615449C311ba22D418A8d;
    /// @notice Staked LOBI token address
    address internal immutable sLOBI = 0x8Ab17e2cd4F894F8641A31f99F673a5762F53c8e;
    /// @notice LOBI Staking contract
    address internal immutable lobiStaking = 0x3818eff63418e0a0BA3980ABA5fF388b029b6d90;

    /// CONSTRUCTOR ///

    ///  @param _authority  Address of the Olympus Authority contract
    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

    /// POLICY FUNCTIONS ///

    /// @notice  If vault has been updated through authority contract update treasury address
    function updateTreasury() external onlyGuardian {
        require(authority.vault() != address(0), "Zero address: Vault");
        require(address(authority.vault()) != address(treasury), "No change");
        treasury = ITreasury(authority.vault());
    }

    /// @notice           Stakes either BTRFLY or LOBI from treasury
    /// @param _redacted  Bool if staking to redacted or lobi
    /// @param _amount    Amount of token that will be withdrawn from treasury and staked
    function stake(bool _redacted, uint _amount) external onlyGuardian {
        (address staking, address token,) = _redactedOrLobi(_redacted);

        // retrieve amount of token from treasury
        treasury.manage(token, _amount); 

        // approve token to be spent by staking
        IERC20(token).approve(staking, _amount);

        // stake token to treasury
        IStaking(staking).stake(_amount, address(treasury));

        // claim stake for treasury
        IStaking(staking).claim(address(treasury));
    }

    /// @notice           Unstakes either BTRFLY or LOBI from treasury
    /// @param _redacted  Bool if unstakiung to redacted or lobi
    /// @param _amount    Amount of token that will be withdrawn from treasury and unstaked
    function unstake(bool _redacted, uint _amount) external onlyGuardian {
        (address staking, address token, address stakedToken) = _redactedOrLobi(_redacted);
        
        // retrieve amount of staked token from treasury
        treasury.manage(stakedToken, _amount); 

        // approve staked token to be spent by staking contract
        IERC20(stakedToken).approve(staking, _amount);

        // unstake token
        IStaking(staking).unstake(_amount, false);

        // send token back to treasury
        IERC20(token).safeTransfer(address(treasury), _amount);
    }


    /// INTERNAL VIEW FUNCTIONS ///

    /// @notice              Returns addresses depending on wanting to interact with redacted or lobi
    /// @param _redacted     Bool if address for redacted or lobi
    /// @return staking      Address of staking contract
    /// @return token        Address of native token
    /// @return stakedToken  Address of staked token
    function _redactedOrLobi(bool _redacted) internal view returns (address staking, address token, address stakedToken) {
        if(_redacted) {
            staking = redactedStaking;
            token = BTRFLY;
            stakedToken = xBTRFLY;
        } else {
            staking = lobiStaking;
            token = LOBI;
            stakedToken = sLOBI;
        }
    }

}