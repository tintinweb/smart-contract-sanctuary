// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// Module Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Libraries
import "./external/ProxyFactory.sol";

// Clone Contracts
import "./Pod.sol";
import "./TokenDrop.sol";

/**
 * @title TokenDropFactory (ProxyFactory) - Clones a TokenDrop Instance
 * @notice Create a TokenDrop smart contract, which is associated with Pod smart contract for distribution of an asset token (i.e. POOL).
 * @dev The PodFactory creates/initializes TokenDrop smart contract. The factory will generally be called from the PodFactory smart contract directly.
 * @author Kames Geraghty
 */
contract TokenDropFactory is ProxyFactory {
    /***********************************|
    |   Constants                       |
    |__________________________________*/
    /**
     * @notice Contract template for deploying proxied Comptrollers
     */
    TokenDrop public tokenDropInstance;

    /***********************************|
    |   Constructor                     |
    |__________________________________*/
    /**
     * @notice Initializes the TokenDropFactory.
     * @dev Initializes the Factory with a TokenDrop instance.
     */
    constructor() {
        // TokenDrop Instance
        tokenDropInstance = new TokenDrop();
    }

    /**
     * @notice Create a TokenDrop smart contract
     * @dev Creates and initializes the TokenDrop Smart Contract with the measure (i.e. Pod) and asset (i.e. POOL) variables
     * @param _measure The token being tracked to calculate user asset rewards
     * @param _asset The token being rewarded when maintaining a positive balance of the "measure" token
     */
    function create(IERC20Upgradeable _measure, IERC20Upgradeable _asset)
        external
        returns (TokenDrop)
    {
        // TokenDrop Deployed
        TokenDrop tokenDrop =
            TokenDrop(deployMinimal(address(tokenDropInstance), ""));

        // TokenDrop Initialize
        tokenDrop.initialize(_measure, _asset);

        // Return TokenDrop addresses
        return tokenDrop;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// solium-disable security/no-inline-assembly
// solium-disable security/no-low-level-calls
contract ProxyFactory {
    event ProxyCreated(address proxy);

    function deployMinimal(address _logic, bytes memory _data)
        public
        returns (address proxy)
    {
        // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
        bytes20 targetBytes = bytes20(_logic);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }

        // Check Proxy instance is not 0x0000000000000000000000000000000000000000
        require(address(proxy) != address(0), "ProxyFactory:invalid-address");

        // Emit ProxyCreated
        emit ProxyCreated(address(proxy));

        if (_data.length > 0) {
            (bool success, ) = proxy.call(_data);
            require(success, "ProxyFactory/constructor-call-failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// Libraries
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

// Module Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Internal Interfaces
import "./IPod.sol";
import "./TokenDrop.sol";
import "./IPodManager.sol";
import "./TokenDropFactory.sol";

// External Interfaces
import "./interfaces/TokenFaucet.sol";
import "./interfaces/IPrizePool.sol";
import "./interfaces/IPrizeStrategyMinimal.sol";

/**
 * @title Pod (Initialize, ERC20Upgradeable, OwnableUpgradeable, IPod) - Reduce User Gas Costs and Increase Odds of Winning via Collective Deposits.
 * @notice Pods turn PoolTogether deposits into shares and enable batched deposits, reudcing gas costs and collectively increasing odds  winning.
 * @dev Pods is a ERC20 token with additional features: shares (representing deposits), batched deposits into PoolTogether PrizePools and claimable rewards.
 * @author Kames Geraghty
 */
contract Pod is
    IPod,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /***********************************|
    |   Constants                       |
    |__________________________________*/
    // Public
    IERC20Upgradeable public token;
    IERC20Upgradeable public ticket;

    TokenFaucet public faucet;
    TokenDrop public tokenDrop;
    address public manager;

    // Private
    IPrizePool private _prizePool;

    /***********************************|
    |   Events                          |
    |__________________________________*/
    /**
     * @dev Emitted when user deposits into Pod float.
     */
    event Deposited(address indexed user, uint256 amount, uint256 shares);

    /**
     * @dev Emitted when user withdraws from the Pod.
     */
    event Withdrawal(address indexed user, uint256 amount, uint256 shares);

    /**
     * @dev Emitted when batch is executed.
     */
    event BatchFloat(uint256 amount);

    /**
     * @dev Emitted when reward asset is claimed by a user.
     */
    event Claimed(address indexed user, uint256 balance);

    /**
     * @dev Emitted when reward asset is claimed by the POD.
     */
    event PodClaimed(uint256 amount);

    /**
     * @dev Emitted when the Pod TokenDrop is set by owner.
     */
    event TokenDropSet(TokenDrop indexed drop);

    /**
     * @dev Emitted when the Pod TokenFaucet is set by owner.
     */
    event TokenFaucetSet(TokenFaucet indexed drop);

    /**
     * @dev Emitted when an ERC20 is withdrawn.
     */
    event ERC20Withdrawn(IERC20Upgradeable indexed target, uint256 amount);

    /**
     * @dev Emitted when an ERC721 is withdrawn.
     */
    event ERC721Withdrawn(IERC721Upgradeable indexed target, uint256 tokenId);

    /**
     * @dev Emitted when Pod manager is transfered.
     */
    event ManagementTransferred(
        address indexed previousmanager,
        address indexed newmanager
    );

    /***********************************|
    |   Modifiers                       |
    |__________________________________*/

    /**
     * @dev Checks is the caller is a manager or owner.
     */

    modifier onlyOwnerOrManager() {
        address _sender = _msgSender();
        require(
            manager == _sender || owner() == _sender,
            "Pod:manager-unauthorized"
        );
        _;
    }

    /**
     * @dev Pause deposits during aware period. Prevents "frontrunning" for deposits into a winning Pod.
     */
    modifier pauseDepositsDuringAwarding() {
        require(
            !IPrizeStrategyMinimal(_prizePool.prizeStrategy()).isRngRequested(),
            "Cannot deposit while prize is being awarded"
        );
        _;
    }

    /***********************************|
    |   Initialize                      |
    |__________________________________*/

    /**
     * @notice Initialize the Pod Smart Contact with the target PrizePool configuration.
     * @dev The Pod Smart Contact is created and initialized using the PodFactory.
     * @param _prizePoolTarget Target PrizePool for deposits and withdraws
     * @param _ticket Non-sponsored PrizePool ticket - is verified during initialization.
     * @param _decimals Set the Pod decimals to match the underlying asset.
     */
    function initialize(
        address _prizePoolTarget,
        address _ticket,
        uint8 _decimals
    ) external initializer {
        // Prize Pool
        _prizePool = IPrizePool(_prizePoolTarget);

        // Contract/Inheritance Configuration
        // ----------------------------------
        // Initialize ReentrancyGuard
        __ReentrancyGuard_init();

        // Initialize ERC20Token
        __ERC20_init_unchained(
            string(
                abi.encodePacked(
                    "Pod ",
                    ERC20Upgradeable(_prizePool.token()).name()
                )
            ),
            string(
                abi.encodePacked(
                    "p",
                    ERC20Upgradeable(_prizePool.token()).symbol()
                )
            )
        );

        // Initialize Owner
        __Ownable_init_unchained();

        // Setup Decimals - Match Underlying Asset
        _setupDecimals(_decimals);

        // Pod Variable/Reference Configuration
        // ------------------------------------

        // PrizePool Tickets
        address[] memory tickets = _prizePool.tokens();

        // Verify ticket matches a PrizePool Ticket
        require(
            address(_ticket) == address(tickets[0]) ||
                address(_ticket) == address(tickets[1]),
            "Pod:initialize-invalid-ticket"
        );

        // Initialize Core ERC20 Tokens
        token = IERC20Upgradeable(_prizePool.token());
        ticket = IERC20Upgradeable(_ticket);
    }

    /***********************************|
    |   Public/External                 |
    |__________________________________*/

    /**
     * @notice Deposit assets into the Pod in exchange for share tokens
     * @param to The address that shall receive the Pod shares
     * @param tokenAmount The amount of tokens to deposit.  These are the same tokens used to deposit into the underlying prize pool.
     * @return The number of Pod shares minted.
     */
    function depositTo(address to, uint256 tokenAmount)
        external
        override
        pauseDepositsDuringAwarding
        nonReentrant
        returns (uint256)
    {
        require(tokenAmount > 0, "Pod:invalid-amount");

        // Allocate Shares from Deposit To Amount
        uint256 shares = _calculateAllocation(tokenAmount);

        // Transfer Token tokenAmount to msg.sender
        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );

        // Mint User Shares
        _mint(to, shares);

        // Emit Deposited
        emit Deposited(to, tokenAmount, shares);

        // Return Shares Minted
        return shares;
    }

    /**
     * @notice Withdraws a users share of the prize pool.
     * @dev The function should first withdraw from the 'float'; i.e. the funds that have not yet been deposited.
     * @param shareAmount The number of Pod shares to burn.
     * @param maxFee Max fee amount for withdrawl if amount isn't available in float.
     * @return The actual amount of tokens that were transferred to the user.  This is the same as the deposit token.
     */
    function withdraw(uint256 shareAmount, uint256 maxFee)
        external
        override
        nonReentrant
        returns (uint256)
    {
        // Check User Balance
        require(
            balanceOf(msg.sender) >= shareAmount,
            "Pod:insufficient-shares"
        );

        // Burn Shares and Return Tokens
        uint256 tokensReturned =
            _burnSharesAndGetTokensReturned(shareAmount, maxFee);

        // Transfer Deposit Token to Message Sender
        token.safeTransfer(msg.sender, tokensReturned);

        // Emit Withdrawal
        emit Withdrawal(msg.sender, tokensReturned, shareAmount);

        return tokensReturned;
    }

    /**
     * @notice Deposit Pod float into PrizePool.
     * @dev Deposits the current float amount into the PrizePool and claims current POOL rewards.
     */
    function batch() public override returns (uint256) {
        // Pod Token Balance
        uint256 float = _podTokenBalance();

        // Approve Prize Pool
        token.safeApprove(address(_prizePool), float);

        // PrizePool Deposit
        _prizePool.depositTo(
            address(this),
            float,
            address(ticket),
            address(this)
        );

        // Emit Batch
        emit BatchFloat(float);

        return float;
    }

    /**
     * @notice Claims TokenDrop asset for PrizePool Pod deposits
     * @dev Claim TokenDrop asset for PrizePool Pod and transfers token(s) to external Pod TokenDrop.
     * @return uint256 claimed amount
     */
    function drop() public returns (uint256) {
        // Claim asset from TokenFaucet if active
        if (address(faucet) != address(0)) {
            faucet.claim(address(this));
        }

        // Run batch (to eliminate "sandwich" attack) and reduce Pod float to zero.
        batch();

        // Check TokenDrop is set for the Pod.
        if (address(tokenDrop) != address(0)) {
            // TokenDrop Asset
            IERC20Upgradeable _asset = IERC20Upgradeable(tokenDrop.asset());

            // Pod asset balance
            uint256 balance = _asset.balanceOf(address(this));

            // Only Transfer asset to TokenDrop if balance above 0
            if (balance > 0) {
                // Approve TokenDrop to withdraw(transfer) reward balance
                _asset.safeApprove(address(tokenDrop), balance);

                // Add reward token to TokenDrop balance
                tokenDrop.addAssetToken(balance);
            }

            // Emit PodClaimed
            emit PodClaimed(balance);

            return balance;
        } else {
            return 0;
        }
    }

    /**
     * @notice Update the Pod Mangeer
     * @dev Update the Pod Manger responsible for handling liquidations.
     * @return bool true
     */
    function setManager(address newManager)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        // Validate Address
        require(newManager != address(0), "Pod:invalid-manager-address");

        // Update Manager
        manager = newManager;

        // Emit ManagementTransferred
        emit ManagementTransferred(manager, newManager);

        return true;
    }

    /**
     * @notice Set TokenFaucet reference
     * @dev Set TokenFaucet reference (if prizepool faucet is updated)
     * @param _faucet TokenDrop address
     * @return bool true
     */
    function setTokenFaucet(TokenFaucet _faucet)
        external
        onlyOwner
        returns (bool)
    {
        // Set TokenFaucet
        faucet = _faucet;

        // Emit TokenFaucetSet
        emit TokenFaucetSet(_faucet);

        return true;
    }

    /**
     * @notice Setup TokenDrop reference
     * @dev Initialize the Pod Smart Contact
     * @param _tokenDrop TokenDrop address
     * @return bool true
     */
    function setTokenDrop(TokenDrop _tokenDrop)
        external
        onlyOwner
        returns (bool)
    {
        // Set TokenDrop smart contract instance
        tokenDrop = _tokenDrop;

        // Emit TokenDropSet
        emit TokenDropSet(_tokenDrop);

        return true;
    }

    /**
     * @notice Withdraw non-core (token/ticket/tokenDrop.asset) ERC20 to Pod manager.
     * @dev Withdraws an ERC20 token amount from the Pod to the PodManager for liquidation to the token and back to the Pod.
     * @param _target ERC20 token to withdraw.
     * @param amount Amount of ERC20 to transfer/withdraw.
     * @return bool true
     */
    function withdrawERC20(IERC20Upgradeable _target, uint256 amount)
        external
        override
        onlyOwnerOrManager
        returns (bool)
    {
        // Lock token/ticket/pool ERC20 transfers
        require(
            address(_target) != address(token) &&
                address(_target) != address(ticket) &&
                (address(tokenDrop) == address(0) ||
                    address(_target) != address(tokenDrop.asset())),
            "Pod:invalid-target-token"
        );

        // Transfer Token
        _target.safeTransfer(msg.sender, amount);

        emit ERC20Withdrawn(_target, amount);

        return true;
    }

    /**
     * @dev Withdraw ER721 reward tokens
     */
    /**
     * @notice Withdraw ER721 token to the Pod owner.
     * @dev Withdraw ER721 token to the Pod owner, which is responsible for deciding what/how to manage the collectible.
     * @param _target ERC721 token to withdraw.
     * @param tokenId The tokenId of the ERC721 collectible.
     * @return bool true
     */
    function withdrawERC721(IERC721Upgradeable _target, uint256 tokenId)
        external
        override
        onlyOwnerOrManager
        returns (bool)
    {
        // Transfer ERC721
        _target.transferFrom(address(this), msg.sender, tokenId);

        // Emit ERC721Withdrawn
        emit ERC721Withdrawn(_target, tokenId);

        return true;
    }

    /***********************************|
    |   Administration                  |
    |__________________________________*/

    /**
     * @notice Zero out the allowance amount of target address to zero.
     * @dev The safeApprove method throws an error if an allowance IS NOT zero. If this unentiionally occurs, this function will reset an allowance.
     * @param _token ERC20 token.
     * @param _target Address with non-zero allowance.
     */
    function emergencyTokenApproveZero(
        IERC20Upgradeable _token,
        address _target
    ) external onlyOwner {
        _token.safeApprove(_target, 0);
    }

    /***********************************|
    |   Internal                        |
    |__________________________________*/

    /**
     * @dev The internal function for the public depositTo function, which calculates a user's allocated shares from deposited amoint.
     * @param amount Amount of "token" deposited into the Pod.
     * @return uint256 The share allocation amount.
     */
    function _calculateAllocation(uint256 amount) internal returns (uint256) {
        uint256 allocation = 0;
        uint256 _totalSupply = totalSupply();

        // Calculate Allocation
        if (_totalSupply == 0) {
            allocation = amount;
        } else {
            allocation = (amount.mul(_totalSupply)).div(balance());
        }

        // Return Allocation Amount
        return allocation;
    }

    /**
     * @dev The internal function for the public withdraw function, which calculates a user's token allocation from burned shares.
     * @param shares The number of Pod shares to burn.
     * @param maxFee Max fee amount for withdrawl if amount isn't available in float.
     * @return uint256 The token amount returned for the burned shares.
     */
    function _burnSharesAndGetTokensReturned(uint256 shares, uint256 maxFee)
        internal
        returns (uint256)
    {
        // Calculate shares underlying tokens
        uint256 amount = _calculateUnderlyingTokens(shares);

        // Burn Shares
        _burn(msg.sender, shares);

        // Check balance
        uint256 currentBalance = token.balanceOf(address(this));

        uint256 actualAmount;
        // Withdrawal Exceeds Current Token Balance
        if (amount > currentBalance) {
            // Calculate withdrawal request amount
            uint256 withdrawRequest = amount.sub(currentBalance);

            // The total withdrawn amount from the Prize Pool
            uint256 withdrawExecuted =
                _withdrawFromPool(withdrawRequest, maxFee);

            actualAmount = currentBalance.add(withdrawExecuted);
            require(amount.sub(actualAmount) <= maxFee, "Pod:max-fee-exceeded");
        } else {
            actualAmount = amount;
        }

        return actualAmount;
    }

    /**
     * @dev Withdraws from Pod prizePool if the float balance can cover the total withdraw amount.
     * @param amount Amount of tokens to withdraw in exchange for the tickets transfered.
     * @param maxFee Max fee amount for withdrawl if amount isn't available in float.
     * @return uint256 The exit fee paid for withdraw from the prizePool instant withdraw method.
     */
    function _withdrawFromPool(uint256 amount, uint256 maxFee)
        internal
        returns (uint256)
    {
        IERC20Upgradeable _token = token;

        uint256 balanceBefore = _token.balanceOf(address(this));

        // Withdraw from Prize Pool
        _prizePool.withdrawInstantlyFrom(
            address(this),
            amount,
            address(ticket),
            maxFee
        );

        uint256 balanceAfter = _token.balanceOf(address(this));

        // Calculate the total withdrawn from the PrizePool by diffing before/after balances
        uint256 totalWithdrawn = balanceAfter.sub(balanceBefore);

        return totalWithdrawn;
    }

    /**
     * @notice Pod current token balance.
     * @dev Request's the Pod's current token balance by calling balanceOf(address(this)).
     * @return uint256 Pod's current token balance.
     */
    function _podTokenBalance() internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Pod current ticket balance.
     * @dev Request's the Pod's current ticket balance by calling balanceOf(address(this)).
     * @return uint256 Pod's current ticket balance.
     */
    function _podTicketBalance() internal view returns (uint256) {
        return ticket.balanceOf(address(this));
    }

    /**
     * @notice Calculate underlying tokens via shares input.
     * @dev Using shares as input calculate the underlying tokens
     * @return Underlying tokens
     */
    function _calculateUnderlyingTokens(uint256 _shares)
        internal
        view
        returns (uint256)
    {
        // Check totalSupply to prevent SafeMath: division by zero
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            return balance().mul(_shares).div(_totalSupply);
        } else {
            return _shares;
        }
    }

    /***********************************|
    |  Views                            |
    |__________________________________*/

    /**
     * @notice The Pod PrizePool reference
     * @dev Returns the address of the Pod prizepool
     * @return address The Pod prizepool
     */
    function prizePool() external view override returns (address) {
        return address(_prizePool);
    }

    /**
     * @notice Calculate the cost of withdrawing from the Pod if the
     * @param amount Amount of tokens to withdraw when calculating early exit fee.
     * @dev Based of the Pod's total token/ticket balance and totalSupply it calculates the pricePerShare.
     */
    function getEarlyExitFee(uint256 amount) external returns (uint256) {
        uint256 tokenBalance = _podTokenBalance();
        if (amount <= tokenBalance) {
            return 0;
        } else {
            // Calculate Early Exit Fee
            (uint256 exitFee, ) =
                _prizePool.calculateEarlyExitFee(
                    address(this),
                    address(ticket),
                    amount.sub(tokenBalance)
                );

            // Early Exit Fee
            return exitFee;
        }
    }

    /**
     * @notice Calculate the cost of the Pod's token price per share. Until a Pod has won or been "airdropped" tokens it's 1.
     * @dev Based of the Pod's total token/ticket balance and totalSupply it calculates the pricePerShare.
     */
    function getPricePerShare() external view override returns (uint256) {
        uint256 _decimals = decimals();
        return _calculateUnderlyingTokens(10**_decimals);
    }

    /**
     * @notice Calculate the underlying assets relative to users balance.
     * @dev Converts share amount to asset amount by checking the Pod's token and ticket balance.
     * @param user User account
     * @return amount Total assets relative to share input.
     */
    function balanceOfUnderlying(address user)
        external
        view
        returns (uint256 amount)
    {
        return _calculateUnderlyingTokens(balanceOf(user));
    }

    /**
     * @notice Measure's the Pod's total balance by adding the vaultTokenBalance and _podTicketBalance
     * @dev The Pod's token and ticket balance are equal in terms of "value" and thus are used to calculate's a Pod's true balance.
     * @return uint256 Pod's token and ticket balance.
     */
    function balance() public view returns (uint256) {
        return _podTokenBalance().add(_podTicketBalance());
    }

    /***********************************|
    | ERC20 Overrides                   |
    |__________________________________*/

    /**
     * @notice Add TokenDrop to mint()
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @param from Account sending tokens
     * @param to Account recieving tokens
     * @param amount Amount of tokens sent
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // If Pod TokenDrop is initalized update calculated balances.
        if (address(tokenDrop) != address(0)) {
            tokenDrop.beforeTokenTransfer(from, to, address(this));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// External Libraries
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

// External Interfaces
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Local Libraries
import "./libraries/ExtendedSafeCast.sol";

/**
 * @title TokenDrop - Calculates Asset Distribution using Measure Token
 * @notice Calculates distribution of POOL rewards for users deposting into PoolTogether PrizePools using the Pod smart contract.
 * @dev A simplified version of the PoolTogether TokenFaucet that simplifies an asset token distribution using totalSupply calculations.
 * @author Kames Cox-Geraghty
 */
contract TokenDrop is ReentrancyGuardUpgradeable {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMathUpgradeable for uint128;
    using SafeMathUpgradeable for uint256;
    using ExtendedSafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /***********************************|
    |   Constants                       |
    |__________________________________*/
    /**
     * @notice The token that is being disbursed
     */
    IERC20Upgradeable public asset;

    /**
     * @notice The token that is user to measure a user's portion of disbursed tokens
     */
    IERC20Upgradeable public measure;

    /**
     * @notice The cumulative exchange rate of measure token supply : dripped tokens
     */
    uint112 public exchangeRateMantissa;

    /**
     * @notice The total amount of tokens that have been dripped but not claimed
     */
    uint112 public totalUnclaimed;

    /**
     * @notice The timestamp at which the tokens were last dripped
     */
    uint32 public lastDripTimestamp;

    /***********************************|
    |   Events                          |
    |__________________________________*/
    /**
     * @dev Emitted when the new asset tokens are added to the disbursement reserve
     */
    event Dropped(uint256 newTokens);

    /**
     * @dev Emitted when a User claims disbursed tokens
     */
    event Claimed(address indexed user, uint256 newTokens);

    /***********************************|
    |   Structs                         |
    |__________________________________*/
    struct UserState {
        uint128 lastExchangeRateMantissa;
        uint128 balance;
    }

    /**
     * @notice The data structure that tracks when a user last received tokens
     */
    mapping(address => UserState) public userStates;

    /***********************************|
    |   Initialize                      |
    |__________________________________*/
    /**
     * @notice Initialize TokenDrop Smart Contract
     * @dev Initialize TokenDrop Smart Contract with the measure (i.e. Pod) and asset (i.e. POOL) variables
     * @param _measure The token being tracked to calculate user asset rewards
     * @param _asset The token being rewarded when maintaining a positive balance of the "measure" token
     */
    function initialize(IERC20Upgradeable _measure, IERC20Upgradeable _asset)
        external
        initializer
    {
        require(address(_measure) != address(0), "Pod:invalid-measure-token");
        require(address(_asset) != address(0), "Pod:invalid-asset-token");

        // Initialize ReentrancyGuard
        __ReentrancyGuard_init();

        // Set measure/asset tokens.
        measure = _measure;
        asset = _asset;
    }

    /***********************************|
    |   Public/External                 |
    |__________________________________*/

    /**
     * @notice Should be called before "measure" tokens are transferred or burned
     * @param from The user who is sending the tokens
     * @param to The user who is receiving the tokens
     *@param token The token token they are burning
     */
    function beforeTokenTransfer(
        address from,
        address to,
        address token
    ) external {
        // must be measure and not be minting
        if (token == address(measure)) {
            // Calcuate to tokens balance
            _captureNewTokensForUser(to);

            // If NOT minting calcuate from tokens balance
            if (from != address(0)) {
                _captureNewTokensForUser(from);
            }
        }
    }

    /**
     * @notice Add Asset to TokenDrop and update with drop()
     * @dev Add Asset to TokenDrop and update with drop()
     * @param amount User account
     */
    function addAssetToken(uint256 amount) external returns (bool) {
        // Transfer asset/reward token from msg.sender to TokenDrop
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Update TokenDrop asset balance
        drop();

        // Return BOOL for transaction gas savings
        return true;
    }

    /**
     * @notice Claim asset rewards
     * @dev Claim asset rewards
     * @param user User account
     */
    function claim(address user) external returns (uint256) {
        UserState memory userState = _computeNewTokensForUser(user);

        uint256 balance = userState.balance;
        userState.balance = 0;
        userStates[user] = userState;

        totalUnclaimed = uint256(totalUnclaimed).sub(balance).toUint112();

        // Internal _nonReentrantTransfer
        _nonReentrantTransfer(user, balance);

        // Emit Claimed
        emit Claimed(user, balance);

        return balance;
    }

    /**
     * @notice Add asset tokens to disburment reserve
     * @dev Should be called immediately before any measure token mints/transfers/burns
     * @return The number of new tokens dropped
     */

    // change to drop
    function drop() public nonReentrant returns (uint256) {
        uint256 assetTotalSupply = asset.balanceOf(address(this));
        uint256 newTokens = assetTotalSupply.sub(totalUnclaimed);

        // if(newTokens > 0)
        if (newTokens > 0) {
            // Check measure token totalSupply()
            uint256 measureTotalSupply = measure.totalSupply();

            // Check measure supply exists
            if (measureTotalSupply > 0) {
                uint256 indexDeltaMantissa =
                    FixedPoint.calculateMantissa(newTokens, measureTotalSupply);
                uint256 nextExchangeRateMantissa =
                    uint256(exchangeRateMantissa).add(indexDeltaMantissa);

                exchangeRateMantissa = nextExchangeRateMantissa.toUint112();
                totalUnclaimed = uint256(totalUnclaimed)
                    .add(newTokens)
                    .toUint112();
                // Emit Dropped
                emit Dropped(newTokens);
            }
        }

        return newTokens;
    }

    /***********************************|
    |   Private/Internal                |
    |__________________________________*/

    /**
     * @dev Transfer asset with reenrancy protection
     * @param user User account
     * @param amount Transfer amount
     */
    function _nonReentrantTransfer(address user, uint256 amount)
        internal
        nonReentrant
    {
        asset.safeTransfer(user, amount);
    }

    /**
     * @notice Captures new tokens for a user
     * @dev This must be called before changes to the user's balance (i.e. before mint, transfer or burns)
     * @param user The user to capture tokens for
     * @return The number of new tokens
     */
    function _captureNewTokensForUser(address user)
        private
        returns (UserState memory)
    {
        UserState memory userState = _computeNewTokensForUser(user);

        userStates[user] = userState;

        return userState;
    }

    /**
     * @notice Compute new token disbursement for a user
     * @dev Calculates a user disbursement via the current measure token balance
     * @param user The user account
     * @return UserState struct
     */
    function _computeNewTokensForUser(address user)
        private
        view
        returns (UserState memory)
    {
        UserState memory userState = userStates[user];
        if (exchangeRateMantissa == userState.lastExchangeRateMantissa) {
            // ignore if exchange rate is same
            return userState;
        }
        uint256 deltaExchangeRateMantissa =
            uint256(exchangeRateMantissa).sub(
                userState.lastExchangeRateMantissa
            );
        uint256 userMeasureBalance = measure.balanceOf(user);
        uint128 newTokens =
            FixedPoint
                .multiplyUintByMantissa(
                userMeasureBalance,
                deltaExchangeRateMantissa
            )
                .toUint128();

        userState = UserState({
            lastExchangeRateMantissa: exchangeRateMantissa,
            balance: userState.balance.add(newTokens).toUint128()
        });

        return userState;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title The PoolTogether Pod specification
interface IPod is IERC20Upgradeable {
    /// @notice Returns the address of the prize pool that the pod is bound to
    /// @return The address of the prize pool
    function prizePool() external view returns (address);

    /// @notice Allows a user to deposit into the Pod
    /// @param to The address that shall receive the Pod shares
    /// @param tokenAmount The amount of tokens to deposit.  These are the same tokens used to deposit into the underlying prize pool.
    /// @return The number of Pod shares minted.
    function depositTo(address to, uint256 tokenAmount)
        external
        returns (uint256);

    /// @notice Withdraws a users share of the prize pool.
    /// @dev The function should first withdraw from the 'float'; i.e. the funds that have not yet been deposited.
    /// if the withdraw is for more funds that can be covered by the float, then a withdrawal is made against the underlying
    /// prize pool.  The user will be charged the prize pool's exit fee on the underlying funds.  The fee can be calculated using PrizePool#calculateEarlyExitFee()
    /// @param shareAmount The number of Pod shares to redeem
    /// @param maxFee Max fee amount for withdrawl.
    /// @return The actual amount of tokens that were transferred to the user.  This is the same as the deposit token.
    function withdraw(uint256 shareAmount, uint256 maxFee)
        external
        returns (uint256);

    /// @notice Calculates the token value per Pod share.
    /// @dev This is useful for those who wish to calculate their balance.
    /// @return The token value per Pod share.
    function getPricePerShare() external view returns (uint256);

    /// @notice Allows someone to batch deposit funds into the underlying prize pool.  This should be called periodically.
    /// @dev This function should deposit the float into the prize pool, and claim any POOL tokens and distribute to users (possibly via adaptation of Token Faucet)
    function batch() external returns (uint256);

    /// @notice Allows the owner of the Pod or the asset manager to withdraw tokens from the Pod.
    /// @dev This function should disallow the withdrawal of tickets or POOL to prevent users from being rugged.
    /// @param token The ERC20 token to withdraw.  Must not be prize pool tickets or POOL tokens.
    function withdrawERC20(IERC20Upgradeable token, uint256 amount)
        external
        returns (bool);

    /// @notice Allows the owner of the Pod or the asset manager to withdraw tokens from the Pod.
    /// @dev This is mainly for Loot Boxes; so Loot Boxes that are won can be transferred out.
    /// @param token The address of the ERC721 to withdraw
    /// @param tokenId The token id to withdraw
    function withdrawERC721(IERC721Upgradeable token, uint256 tokenId)
        external
        returns (bool);

    /// @notice Allows a user to claim POOL tokens for an address.  The user will be transferred their share of POOL tokens.
    // function claim(address user) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// Interface
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPodManager {
    /**
     * @notice liquidate
     * @return uint256 Amount liquidated
     */
    function liquidate(
        address _pod,
        IERC20Upgradeable target,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external returns (bool);

    /**
     * @notice withdrawCollectible
     * @return uint256 Amount liquidated
     */
    function withdrawCollectible(
        address _pod,
        IERC721Upgradeable target,
        uint256 tokenId
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface TokenFaucet {
    function claim(address user) external returns (uint256);

    function asset() external returns (address);

    function dripRatePerSecond() external returns (uint256);

    function exchangeRateMantissa() external returns (uint112);

    function measure() external returns (address);

    function totalUnclaimed() external returns (uint112);

    function lastDripTimestamp() external returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./ControlledTokenInterface.sol";
import "./TokenListenerInterface.sol";

/// @title Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.  Users deposit and withdraw from this contract to participate in Prize Pool.
/// @notice Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
/// @dev Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
interface IPrizePool {
    // WARNING: VERIFY THIS VALID PLACE TO INCLUDE FUNCTION
    function prizeStrategy() external returns (address);

    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    /// @param controlledToken The address of the type of token the user is minting
    /// @param referrer The referrer of the deposit
    function depositTo(
        address to,
        uint256 amount,
        address controlledToken,
        address referrer
    ) external;

    /// @notice Withdraw assets from the Prize Pool instantly.  A fairness fee may be charged for an early exit.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @param controlledToken The address of the token to redeem (i.e. ticket or sponsorship)
    /// @param maximumExitFee The maximum exit fee the caller is willing to pay.  This should be pre-calculated by the calculateExitFee() fxn.
    /// @return The actual exit fee paid
    function withdrawInstantlyFrom(
        address from,
        uint256 amount,
        address controlledToken,
        uint256 maximumExitFee
    ) external returns (uint256);

    /// @notice Withdraw assets from the Prize Pool by placing them into the timelock.
    /// The timelock is used to ensure that the tickets have contributed their fair share of the prize.
    /// @dev Note that if the user has previously timelocked funds then this contract will try to sweep them.
    /// If the existing timelocked funds are still locked, then the incoming
    /// balance is added to their existing balance and the new timelock unlock timestamp will overwrite the old one.
    /// @param from The address to withdraw from
    /// @param amount The amount to withdraw
    /// @param controlledToken The type of token being withdrawn
    /// @return The timestamp from which the funds can be swept
    function withdrawWithTimelockFrom(
        address from,
        uint256 amount,
        address controlledToken
    ) external returns (uint256);

    function withdrawReserve(address to) external returns (uint256);

    /// @notice Returns the balance that is available to award.
    /// @dev captureAwardBalance() should be called first
    /// @return The total amount of assets to be awarded for the current prize
    function awardBalance() external view returns (uint256);

    /// @notice Captures any available interest as award balance.
    /// @dev This function also captures the reserve fees.
    /// @return The total amount of assets to be awarded for the current prize
    function captureAwardBalance() external returns (uint256);

    /// @notice Called by the prize strategy to award prizes.
    /// @dev The amount awarded must be less than the awardBalance()
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of assets to be awarded
    /// @param controlledToken The address of the asset token being awarded
    function award(
        address to,
        uint256 amount,
        address controlledToken
    ) external;

    /// @notice Called by the Prize-Strategy to transfer out external ERC20 tokens
    /// @dev Used to transfer out tokens held by the Prize Pool.  Could be liquidated, or anything.
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of external assets to be awarded
    /// @param externalToken The address of the external asset token being awarded
    function transferExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the Prize-Strategy to award external ERC20 prizes
    /// @dev Used to award any arbitrary tokens held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of external assets to be awarded
    /// @param externalToken The address of the external asset token being awarded
    function awardExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the prize strategy to award external ERC721 prizes
    /// @dev Used to award any arbitrary NFTs held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external NFT token being awarded
    /// @param tokenIds An array of NFT Token IDs to be transferred
    function awardExternalERC721(
        address to,
        address externalToken,
        uint256[] calldata tokenIds
    ) external;

    /// @notice Sweep all timelocked balances and transfer unlocked assets to owner accounts
    /// @param users An array of account addresses to sweep balances for
    /// @return The total amount of assets swept from the Prize Pool
    function sweepTimelockBalances(address[] calldata users)
        external
        returns (uint256);

    /// @notice Calculates a timelocked withdrawal duration and credit consumption.
    /// @param from The user who is withdrawing
    /// @param amount The amount the user is withdrawing
    /// @param controlledToken The type of collateral the user is withdrawing (i.e. ticket or sponsorship)
    /// @return durationSeconds The duration of the timelock in seconds
    function calculateTimelockDuration(
        address from,
        address controlledToken,
        uint256 amount
    ) external returns (uint256 durationSeconds, uint256 burnedCredit);

    /// @notice Calculates the early exit fee for the given amount
    /// @param from The user who is withdrawing
    /// @param controlledToken The type of collateral being withdrawn
    /// @param amount The amount of collateral to be withdrawn
    /// @return exitFee The exit fee
    /// @return burnedCredit The user's credit that was burned
    function calculateEarlyExitFee(
        address from,
        address controlledToken,
        uint256 amount
    ) external returns (uint256 exitFee, uint256 burnedCredit);

    /// @notice Estimates the amount of time it will take for a given amount of funds to accrue the given amount of credit.
    /// @param _principal The principal amount on which interest is accruing
    /// @param _interest The amount of interest that must accrue
    /// @return durationSeconds The duration of time it will take to accrue the given amount of interest, in seconds.
    function estimateCreditAccrualTime(
        address _controlledToken,
        uint256 _principal,
        uint256 _interest
    ) external view returns (uint256 durationSeconds);

    /// @notice Returns the credit balance for a given user.  Not that this includes both minted credit and pending credit.
    /// @param user The user whose credit balance should be returned
    /// @return The balance of the users credit
    function balanceOfCredit(address user, address controlledToken)
        external
        returns (uint256);

    /// @notice Sets the rate at which credit accrues per second.  The credit rate is a fixed point 18 number (like Ether).
    /// @param _controlledToken The controlled token for whom to set the credit plan
    /// @param _creditRateMantissa The credit rate to set.  Is a fixed point 18 decimal (like Ether).
    /// @param _creditLimitMantissa The credit limit to set.  Is a fixed point 18 decimal (like Ether).
    function setCreditPlanOf(
        address _controlledToken,
        uint128 _creditRateMantissa,
        uint128 _creditLimitMantissa
    ) external;

    /// @notice Returns the credit rate of a controlled token
    /// @param controlledToken The controlled token to retrieve the credit rates for
    /// @return creditLimitMantissa The credit limit fraction.  This number is used to calculate both the credit limit and early exit fee.
    /// @return creditRateMantissa The credit rate. This is the amount of tokens that accrue per second.
    function creditPlanOf(address controlledToken)
        external
        view
        returns (uint128 creditLimitMantissa, uint128 creditRateMantissa);

    /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
    /// @param _liquidityCap The new liquidity cap for the prize pool
    function setLiquidityCap(uint256 _liquidityCap) external;

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy.  Must implement TokenListenerInterface
    function setPrizeStrategy(TokenListenerInterface _prizeStrategy) external;

    /// @dev Returns the address of the underlying ERC20 asset
    /// @return The address of the asset
    function token() external view returns (address);

    /// @notice An array of the Tokens controlled by the Prize Pool (ie. Tickets, Sponsorship)
    /// @return An array of controlled token addresses
    function tokens() external view returns (address[] memory);

    /// @notice The timestamp at which an account's timelocked balance will be made available to sweep
    /// @param user The address of an account with timelocked assets
    /// @return The timestamp at which the locked assets will be made available
    function timelockBalanceAvailableAt(address user)
        external
        view
        returns (uint256);

    /// @notice The balance of timelocked assets for an account
    /// @param user The address of an account with timelocked assets
    /// @return The amount of assets that have been timelocked
    function timelockBalanceOf(address user) external view returns (uint256);

    /// @notice The total of all controlled tokens and timelock.
    /// @return The current total of all tokens and timelock.
    function accountedBalance() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

interface IPrizeStrategyMinimal {
    function isRngRequested() external returns (bool);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.4.0;

import "./external/openzeppelin/OpenZeppelinSafeMath_V3_3_0.sol";

/**
 * @author Brendan Asselstine
 * @notice Provides basic fixed point math calculations.
 *
 * This library calculates integer fractions by scaling values by 1e18 then performing standard integer math.
 */
library FixedPoint {
    using OpenZeppelinSafeMath_V3_3_0 for uint256;

    // The scale to use for fixed point numbers.  Same as Ether for simplicity.
    uint256 internal constant SCALE = 1e18;

    /**
        * Calculates a Fixed18 mantissa given the numerator and denominator
        *
        * The mantissa = (numerator * 1e18) / denominator
        *
        * @param numerator The mantissa numerator
        * @param denominator The mantissa denominator
        * @return The mantissa of the fraction
        */
    function calculateMantissa(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        uint256 mantissa = numerator.mul(SCALE);
        mantissa = mantissa.div(denominator);
        return mantissa;
    }

    /**
        * Multiplies a Fixed18 number by an integer.
        *
        * @param b The whole integer to multiply
        * @param mantissa The Fixed18 number
        * @return An integer that is the result of multiplying the params.
        */
    function multiplyUintByMantissa(uint256 b, uint256 mantissa) internal pure returns (uint256) {
        uint256 result = mantissa.mul(b);
        result = result.div(SCALE);
        return result;
    }

    /**
    * Divides an integer by a fixed point 18 mantissa
    *
    * @param dividend The integer to divide
    * @param mantissa The fixed point 18 number to serve as the divisor
    * @return An integer that is the result of dividing an integer by a fixed point 18 mantissa
    */
    function divideUintByMantissa(uint256 dividend, uint256 mantissa) internal pure returns (uint256) {
        uint256 result = SCALE.mul(dividend);
        result = result.div(mantissa);
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

library ExtendedSafeCast {
    /**
     * @dev Converts an unsigned uint256 into a unsigned uint128.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxUint118.
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn't fit in an uint128");
        return uint128(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a unsigned uint112.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxUint112.
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value < 2**112, "SafeCast: value doesn't fit in an uint112");
        return uint112(value);
    }
}

// SPDX-License-Identifier: MIT

// NOTE: Copied from OpenZeppelin Contracts version 3.3.0

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library OpenZeppelinSafeMath_V3_3_0 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./TokenControllerInterface.sol";

/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
interface ControlledTokenInterface is IERC20Upgradeable {
    /// @notice Interface to the contract responsible for controlling mint/burn
    function controller() external view returns (TokenControllerInterface);

    /// @notice Allows the controller to mint tokens for a user account
    /// @dev May be overridden to provide more granular control over minting
    /// @param _user Address of the receiver of the minted tokens
    /// @param _amount Amount of tokens to mint
    function controllerMint(address _user, uint256 _amount) external;

    /// @notice Allows the controller to burn tokens from a user account
    /// @dev May be overridden to provide more granular control over burning
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurn(address _user, uint256 _amount) external;

    /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
    /// @dev May be overridden to provide more granular control over operator-burning
    /// @param _operator Address of the operator performing the burn action via the controller contract
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurnFrom(
        address _operator,
        address _user,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

/// @title An interface that allows a contract to listen to token mint, transfer and burn events.
interface TokenListenerInterface is IERC165Upgradeable {
    /// @notice Called when tokens are minted.
    /// @param to The address of the receiver of the minted tokens.
    /// @param amount The amount of tokens being minted
    /// @param controlledToken The address of the token that is being minted
    /// @param referrer The address that referred the minting.
    function beforeTokenMint(
        address to,
        uint256 amount,
        address controlledToken,
        address referrer
    ) external;

    /// @notice Called when tokens are transferred or burned.
    /// @param from The address of the sender of the token transfer
    /// @param to The address of the receiver of the token transfer.  Will be the zero address if burning.
    /// @param amount The amount of tokens transferred
    /// @param controlledToken The address of the token that was transferred
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        address controlledToken
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/// @title Controlled ERC20 Token Interface
/// @notice Required interface for Controlled ERC20 Tokens linked to a Prize Pool
/// @dev Defines the spec required to be implemented by a Controlled ERC20 Token
interface TokenControllerInterface {
    /// @dev Controller hook to provide notifications & rule validations on token transfers to the controller.
    /// This includes minting and burning.
    /// @param from Address of the account sending the tokens (address(0x0) on minting)
    /// @param to Address of the account receiving the tokens (address(0x0) on burning)
    /// @param amount Amount of tokens being transferred
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}