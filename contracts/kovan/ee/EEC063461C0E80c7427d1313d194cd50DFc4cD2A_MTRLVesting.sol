//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract MTRLVesting {
    /// @notice blockNumber that vesting will start
    uint256 public immutable vestingStartBlock;

    /// @notice tokens will be unlocked per this cycle
    uint256 public immutable UNLOCK_CYCLE;

    /// @notice amount of tokens that will be unlocked per month
    uint256 public constant UNLOCK_AMOUNT = 1000000e18; // 1M

    /// @notice admin
    address public admin;

    /// @notice address that will receive unlocked tokens
    address public wallet;

    /// @notice vesting token (in our case, MTRL)
    IERC20 public token;

    /// @notice true when nth month is unlocked
    mapping(uint256 => bool) public isUnlocked;

    constructor(
        IERC20 _token,
        address _admin,
        address _wallet,
        uint256 _vestingStartBlock,
        uint256 _unlockCycle
    ) {
        require(_vestingStartBlock != 0, 'constructor: invalid vesting start block');
        require(address(_token) != address(0), 'constructor: invalid MTRL');
        require(_admin != address(0), 'constructor: invalid admin');
        require(_wallet != address(0), 'constructor: invalid wallet');

        admin = _admin;
        token = _token;
        vestingStartBlock = _vestingStartBlock;
        UNLOCK_CYCLE = _unlockCycle;
        wallet = _wallet;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, 'onlyAdmin: caller is not the owner');
        _;
    }

    event SetWallet(address indexed _newWallet);
    event Claimed(uint256 indexed _amount, uint256 indexed _index, address _wallet);

    /// @dev transfer ownership
    function transferOwnership(address _newAdmin) external onlyAdmin {
        require(admin != _newAdmin && _newAdmin != address(0), 'transferOwnership: invalid admin');
        admin = _newAdmin;
    }

    /// @dev setWallet
    /// @param _newWallet new address of wallet that will receive unlocked tokens
    function setWallet(address _newWallet) external onlyAdmin {
        require(_newWallet != address(0) && _newWallet != wallet, 'setWallet: invalid wallet');
        wallet = _newWallet;
        emit SetWallet(_newWallet);
    }

    /// @dev anyone can call this function to transfer unlocked tokens to the wallet
    function claim() external {
        require(block.number >= vestingStartBlock, 'claim: vesting not started');

        uint256 vestingBalance = token.balanceOf(address(this));
        require(vestingBalance > 0, 'claim: no tokens');

        // record claiming month index
        uint256 index;
        uint256 transferAmount;
        if (block.number - vestingStartBlock >= UNLOCK_CYCLE) {
            index = (block.number - vestingStartBlock) / UNLOCK_CYCLE;

            if (!isUnlocked[index]) {
                transferAmount = vestingBalance < UNLOCK_AMOUNT
                    ? token.balanceOf(address(this))
                    : UNLOCK_AMOUNT;
                isUnlocked[index] = true;

                token.transfer(wallet, transferAmount);
            }
        }

        emit Claimed(transferAmount, index, wallet);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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