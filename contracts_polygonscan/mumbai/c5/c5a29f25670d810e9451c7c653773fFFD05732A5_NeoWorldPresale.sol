// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";
import "../types/Ownable.sol";

interface IAlphaWorld {
    function mint(address account_, uint256 amount_) external;
}

contract NeoWorldPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount; // Amount USDC deposited by user
        uint256 debt; // total WORLD claimed thus aWORLD debt
        uint256 payout; // total WORLD to be claimed
        bool claimed; // True if a user has claimed WORLD
    }

    struct TeamInfo {
        uint256 numWhitelist; // number of whitelists
        uint256 amount; // Amout USDC deposited by team
        uint256 debt; // total WORLD claimed thus aWORLD debt
        bool claimed; // True if a team member has claimed WORLD
    }

    // Tokens to raise (USDC) & (FRAX) and for offer (aWORLD) which can be swapped for (WORLD)
    IERC20 public USDC; // for user deposits
    IERC20 public aWORLD;
    IERC20 public WORLD;

    address public DAO; // Multisig treasury to send proceeds to

    uint256 public price = 1 * 1e18; // 1 USDC per WORLD

    uint256 public minCap = 500 * 1e18; // 500 USDC cap per whitelisted user

    uint256 public maxCap = 1500 * 1e18; // 1500 USDC cap per whitelisted user

    uint256 public totalRaisedUSDC; // total USDC raised by sale

    uint256 public totalDebt; // total aWORLD and thus WORLD owed to users

    bool public started; // true when sale is started

    bool public ended; // true when sale is ended

    bool public claimable; // true when sale is claimable

    bool public claimAlpha; // true when aWORLD is claimable

    bool public contractPaused; // circuit breaker

    mapping(address => UserInfo) public userInfo;

    mapping(address => TeamInfo) public teamInfo;

    mapping(address => bool) public whitelisted; // True if user is whitelisted

    mapping(address => bool) public whitelistedTeam; // True if team member is whitelisted

    mapping(address => uint256) public WORLDClaimable; // amount of WORLD claimable by address

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address token, address indexed who, uint256 amount);
    event Mint(address token, address indexed who, uint256 amount);
    event SaleStarted(uint256 block);
    event SaleEnded(uint256 block);
    event ClaimUnlocked(uint256 block);
    event ClaimAlphaUnlocked(uint256 block);
    event AdminWithdrawal(address token, uint256 amount);

    constructor(
        address _aWORLD,
        address _WORLD,
        address _USDC,
        address _DAO
    ) {
        require( _aWORLD != address(0) );
        aWORLD = IERC20(_aWORLD);
        require( _WORLD != address(0) );
        WORLD = IERC20(_WORLD);
        require( _USDC != address(0) );
        USDC = IERC20(_USDC);
        require( _DAO != address(0) );
        DAO = _DAO;
    }

    //* @notice modifer to check if contract is paused
    modifier checkIfPaused() {
        require(contractPaused == false, "NeoWorld Presale contract is paused");
        _;
    }
    /**
     *  @notice adds a single whitelist to the sale
     *  @param _address: address to whitelist
     */
    function addWhitelist(address _address) external onlyOwner {
        require(!started, "Sale has already started");
        whitelisted[_address] = true;
    }

    /**
     *  @notice adds multiple whitelist to the sale
     *  @param _addresses: dynamic array of addresses to whitelist
     */
    function addMultipleWhitelist(address[] calldata _addresses) external onlyOwner {
        require(!started, "Sale has already started");
        require(_addresses.length <= 999, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    /**
     *  @notice removes a single whitelist from the sale
     *  @param _address: address to remove from whitelist
     */
    function removeWhitelist(address _address) external onlyOwner {
        require(!started, "Sale has already started");
        whitelisted[_address] = false;
    }

    // @notice Starts the sale
    function start() external onlyOwner {
        require(!started, "Sale has already started");
        started = true;
        emit SaleStarted(block.number);
    }

    // @notice Ends the sale
    function end() external onlyOwner {
        require(started, "Sale has not started");
        require(!ended, "Sale has already ended");
        ended = true;
        emit SaleEnded(block.number);
    }

    // @notice lets users claim WORLD
    // @dev send sufficient WORLD before calling
    function claimUnlock() external onlyOwner {
        require(ended, "Sale has not ended");
        require(!claimable, "Claim has already been unlocked");
        require(WORLD.balanceOf(address(this)) >= totalDebt, 'not sufficient WORLD Presale contract balance');
        claimable = true;
        emit ClaimUnlocked(block.number);
    }


    // @notice lets users claim aWORLD
    function claimAlphaUnlock() external onlyOwner {
        require(claimable, "Claim has not been unlocked");
        require(!claimAlpha, "Claim Alpha has already been unlocked");
        claimAlpha = true;
        emit ClaimAlphaUnlocked(block.number);
    }

    // @notice lets owner pause contract
    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }
    /**
     *  @notice transfer ERC20 token to DAO multisig
     *  @param _token: token address to withdraw
     *  @param _amount: amount of token to withdraw
     */
    function adminWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20( _token ).safeTransfer( address(msg.sender), _amount );
        emit AdminWithdrawal(_token, _amount);
    }

    /**
     *  @notice it deposits USDC for the sale
     *  @param _amount: amount of USDC to deposit to sale (18 decimals)
     */
    function deposit(uint256 _amount) external checkIfPaused {
        require(started, 'Sale has not started');
        require(!ended, 'Sale has ended');
        require(whitelisted[msg.sender] == true, 'You are not a whitelisted user');

        UserInfo storage user = userInfo[msg.sender];

        require(
            maxCap >= user.amount.add(_amount),
            'amount is above user limit'
            );

        require(
            minCap <= user.amount.add(_amount),
            'amount is below user limit'
            );

        user.amount = user.amount.add(_amount);
        totalRaisedUSDC = totalRaisedUSDC.add(_amount);

        uint256 payout = _amount.mul(1e18).div(price).div(1e9); // aWORLD to mint for _amount

        totalDebt = totalDebt.add(payout);
        user.payout = user.payout.add(payout);

        USDC.safeTransferFrom( msg.sender, DAO, _amount );

        IAlphaWorld( address(aWORLD) ).mint( msg.sender, payout );

        emit Deposit(msg.sender, _amount);
    }

    /**
     *  @notice it deposits aWORLD to withdraw WORLD from the sale
     *  @param _amount: amount of aWORLD to deposit to sale (9 decimals)
     */
    function withdraw(uint256 _amount) external checkIfPaused {
        require(claimable, 'WORLD is not yet claimable');
        require(_amount > 0, 'Claim amount must be greater than zero');

        UserInfo storage user = userInfo[msg.sender];
    
        require(_amount <= user.payout, "Claim amount is above user limit");

        user.debt = user.debt.add(_amount);
        totalDebt = totalDebt.sub(_amount);

        user.payout = user.payout.sub(_amount);

        aWORLD.safeTransferFrom( msg.sender, address(this), _amount );

        WORLD.safeTransfer( msg.sender, _amount );

        emit Mint(address(aWORLD), msg.sender, _amount);
        emit Withdraw(address(WORLD), msg.sender, _amount);
    }

    // @notice it returns claimable amount of WORLD for a user
    function getUserClaimableBalance() external view returns ( uint256 ) {
        UserInfo storage user = userInfo[msg.sender];
        return user.payout;
    }

    // @notice it checks a users USDC allocation remaining
    function getUserRemainingAllocation(address _user) external view returns ( uint256 ) {
        UserInfo memory user = userInfo[_user];
        return maxCap.sub(user.amount);
    }
    // @notice it claims aWORLD back from the sale
    function claimAlphaWORLD() external checkIfPaused {
        require(claimAlpha, 'aWORLD is not yet claimable');

        UserInfo storage user = userInfo[msg.sender];

        require(user.debt > 0, 'msg.sender has not participated');
        require(!user.claimed, 'msg.sender has already claimed');

        user.claimed = true;

        uint256 payout = user.debt;
        user.debt = 0;

        aWORLD.safeTransfer( msg.sender, payout );

        emit Withdraw(address(aWORLD),msg.sender, payout);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}