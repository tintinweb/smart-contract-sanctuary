/// SPDX-License-Identifier: GNU Affero General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MochiAccessControl.sol";

/**
 * @title Mochi
 * @author Liqhtworks LLC
 * @notice Mochi Game Core Contract
 */
contract Mochi is MochiAccessControl, PausableUpgradeable {

    /*************
    STRUCTS
    *************/
    
    struct Player {
        uint256 ethBalance;
        uint256 tokens;
        bool playing;
    }

    /*************
    GLOBAL VARIABLES
    *************/

    IERC20 public token;
    
    /// @dev percentage of locked funds that can be moved to investment opportunities
    uint256 public maxReallocation;
    
    /// @dev Amount locked from users being in journeys.
    uint256 public amountLocked;

    /// @dev Amount that users can withdraw from the contract at any time.
    /// ... we can't simply use address(this).balance - amountLocked for this because some
    /// ... of the contract's balance will be reallocated with `moveFunds`
    uint256 public amountUnlocked;

    /// @dev Amount that the contract is "owed" from funds being moved.
    uint256 public amountOwed;

    address public newContractAddress;
    address payable public withdrawalAddress;

    uint256 private _withdrawalAddressBalance;

    mapping(address => Player) internal players;

    /// @dev Name of community
    string public communityName;

    /*************
    EVENTS
    *************/

    /// @dev emitted when deposits are made into the contract
    event Deposit(address indexed depositor, uint256 indexed amount, uint256 indexed updatedBalance);

    /// @dev emitted when withdraws are made from the contract
    event Withdraw(address indexed withdrawer, uint256 indexed amount, uint256 indexed remainingBalance);

    /// @dev emitted when withdraws are made on behalf of a player
    event WithdrawForPlayer(address indexed player, uint256 indexed amount, uint256 indexed remainingBalance);

    /// @dev emitted when withdraws are made on behalf of a player
    event WithdrawContractBalance(uint256 indexed amount);

    /// @dev emitted when withdraws are made on behalf of a player
    event WithdrawSlashedBalance(uint256 indexed amount);

    /// @dev emitted when player starts their journey
    event PlayerStartedJourney(address indexed player);

    /// @dev emitted when player has ended their journey
    event PlayerEndedJourney(address indexed player, uint256 indexed ethBalance, uint256 indexed tokens);

    /// @dev emitted when we set a new contract address
    event TopUpForPlayer(address indexed player, uint256 indexed amount, uint256 indexed updatedBalance);

    /// @dev emitted when we set a new withdrawal address
    event WithdrawalAddressUpdated(address indexed newWithdrawalAddress);

    /// @dev emitted when funds are moved to another address (for investment opportunities)
    event FundsMoved(address indexed to, uint256 indexed amount, uint256 indexed remainingBalance);

    /// @dev emitted when funds are received (e.g. returning invested funds to the contract)
    event FundsReceived(address indexed from, uint256 indexed amount, uint256 indexed updatedBalance);

    /// @dev emitted when we set a new contract address
    event ContractUpgrade(address indexed newContract);

    /// @dev emitted when we set a new maxReallocation (% of locked funds)
    event MaxReallocationUpdated(uint256 percentage);

    /// @dev emitted when funds are withdrawn and contractBalance falls below maxReallocation
    event InsufficientBalanceForPlayerWithdrawal(uint256 indexed diff);

    /// @dev emitted when a player claims their earned mochi tokens
    event TokensClaimed(address indexed player, uint256 indexed amount);

    /// @dev emitted when player data and funds are seeded to the contract e.g. during migration
    event PlayerDataAndFundsSeeded(uint256 indexed contractBalance);

    /// @dev emitted when the community name has been updated
    event CommunityNameUpdated(string indexed oldName, string indexed newName);

    /*************
    MODIFIERS
    *************/

    /// @dev Throws if called by an account other than an owner.
    modifier onlyOwner() {
        require(hasRole(OWNER, msg.sender), "AccessControl: Caller is not the Owner");
        _;
    }

    /// @dev Throws if called by an account that is not a fund manager.
    modifier onlyFundManager() {
        require(hasRole(FUND_MANAGER, msg.sender), "AccessControl: Caller is not a Fund Manager");
        _;
    }

    /// @dev Throws if called by an account that is not a journey manager.
    modifier onlyJourneyManager() {
        require(hasRole(JOURNEY_MANAGER, msg.sender), "AccessControl: Caller is not a Journey Manager");
        _;
    }
    
    /*************
    CONSTRUCTOR
    *************/

    function initialize(address _token, string memory _communityName) public initializer {
        withdrawalAddress = payable(msg.sender);
        maxReallocation = 50;
        token = IERC20(_token);
        _owner = msg.sender;
        communityName = _communityName;

        __AccessControl_init();
        
        // create roles, deployer is granted all roles by at initialization.
        _setupRole(JOURNEY_MANAGER, msg.sender);
        _setupRole(FUND_MANAGER, msg.sender);
        _setupRole(OWNER, msg.sender);

        // make OWNER the role admin for all roles.
        _setRoleAdmin(OWNER, OWNER);
        _setRoleAdmin(JOURNEY_MANAGER, OWNER);
        _setRoleAdmin(FUND_MANAGER, OWNER);
    }

    /*************
    SETTER FUNCTIONS
    *************/

    /**
     * @notice Sets a new contract address if an upgrade is needed
     * @param _newAddress - the address where the new contract is
     */
    function setNewAddress(address _newAddress) external virtual onlyOwner {
        require(_newAddress != address(0), "setNewAddress: new contractAddress must be non-zero");
        newContractAddress = _newAddress;
        emit ContractUpgrade(_newAddress);
    }

    /**
     * @notice Sets a new withdrawalAddress
     * @param newWithdrawalAddress - the address where we'll send the funds
     */
    function setWithdrawalAddress(address payable newWithdrawalAddress)
        external
        virtual
        onlyOwner
    {
        require(
            newWithdrawalAddress != address(0),
            "setWithdrawalAddress: new withdrawalAddress must be non-zero"
        );

        // update global variable
        withdrawalAddress = newWithdrawalAddress;

        emit WithdrawalAddressUpdated(newWithdrawalAddress);
    }

    /**
     * @notice Sets a new limit for the amount of funds that can be moved to investment opportunities
     * This is the percentage of amountLocked + amountUnlocked, which should equal address(this).balance + amountOwed
     * @param percentage The max percentage of funds that can be moved
     */
    function setMaxReallocation(uint256 percentage) external virtual onlyOwner {
        require(percentage <= 100, "maxReallocation percentage cannot exceed 100");
        maxReallocation = percentage;
        emit MaxReallocationUpdated(percentage);
    }

    /**
     * @notice Allows contract owner to modify the community name
     * @param _communityName - string of the new community name
     */
    function setCommunityName(string memory _communityName) external virtual onlyOwner {
        string memory oldName = communityName;
        communityName = _communityName;
        emit CommunityNameUpdated(oldName, communityName);
    }

    /**
     * @notice Allows admin to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows admin to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*************
    JOURNEY MANAGEMENT
    *************/

    /**
     * @notice Allows owner to update a player's status to playing
     * @param _players addresses of the player whose journeys are starting
     */
    function startJourney(address[] memory _players) external virtual onlyJourneyManager
    {
        uint256 amountToLock;

        for (uint256 i = 0; i < _players.length; i++) {
            players[_players[i]].playing = true;
            // "lock" the player's ethBalance
            amountToLock += players[_players[i]].ethBalance;
            emit PlayerStartedJourney(_players[i]);
        }

        // update global variable once we are outside the for loop to save gas
        amountLocked += amountToLock;
        amountUnlocked -= amountToLock;
    }

    /**
     * @notice Allows owner to update a player's status to "not playing" and update eth and poolToken balances
     * @param _players addresses of the player whose journeys have ended
     * @param _ethBalances the player's updated ETH holdings
     * @param _tokens earned Mochi tokens
     */
    function endJourney(
        address[] memory _players,
        uint256[] memory _ethBalances,
        uint256[] memory _tokens)
        external
        virtual
        onlyJourneyManager
    {

        uint256 amountToUnlock;
        uint256 amountSlashed;
        
        for (uint256 i = 0; i < _players.length; i++) {
            // add slashed funds to Mochi balance
            // slashed funds = currentBalance - updatedBalance. Could be 0 if they didn't get slashed
            amountSlashed += players[_players[i]].ethBalance - _ethBalances[i];

            // unlock the user's original ethBalance
            // slashed funds simply get reallocated to withdrawal address
            // ... but need to unlock the deposited amount for accurate accounting of `amountLocked`            
            amountToUnlock += players[_players[i]].ethBalance;

            // update player's withdrawable ethBalance, tokens and playing status
            players[_players[i]].ethBalance = _ethBalances[i];
            players[_players[i]].tokens += _tokens[i];
            players[_players[i]].playing = false;

            emit PlayerEndedJourney(_players[i], _ethBalances[i], _tokens[i]);
        }

        // update global variable once we are outside the for loop to save gas
        amountLocked -= amountToUnlock;
        amountUnlocked += amountToUnlock;
        _withdrawalAddressBalance += amountSlashed;

    }

    /*************
    FUND MANAGEMENT
    *************/

    /**
     * @notice Deposit ether into bank
     * @return The balance of the user after the deposit is made
     */
    function deposit() external payable virtual whenNotPaused returns (uint256) {
        players[msg.sender].ethBalance += msg.value;

        // if player is in a journey, lock the deposited amount
        if (players[msg.sender].playing) {
            amountLocked += msg.value;
        } else {
        // otherwise, add to amountUnlocked for accurate accounting
            amountUnlocked += msg.value;
        }
        
        emit Deposit(msg.sender, msg.value, players[msg.sender].ethBalance);

        return players[msg.sender].ethBalance;
    }

    /**
     * @notice Withdraw ether from bank
     * @dev Can only withdraw up to `msg.sender` ethBalance
     * Cannot withdraw while in a journey
     * @param amount amount you want to withdraw
     */
    function withdraw(uint256 amount) external virtual whenNotPaused returns (uint256 remainingBal) {
        require(
            amount <= players[msg.sender].ethBalance,
            "Withdraw amount must not exceed ethBalance"
        );
        require(
            !players[msg.sender].playing,
            "Cannot withdraw while in a journey"
        );

        players[msg.sender].ethBalance -= amount;

        amountUnlocked -= amount;

        emit Withdraw(msg.sender, amount, players[msg.sender].ethBalance);

        payable(msg.sender).transfer(amount);

        // if withdrawal brings contract balance below maxReallocation%, emit event to alert admin to send funds back
        if (address(this).balance < (maxReallocation * (amountLocked + amountUnlocked) / 100)) {
            emit InsufficientBalanceForPlayerWithdrawal((maxReallocation * (amountLocked + amountUnlocked) / 100) - address(this).balance);
        }

        return players[msg.sender].ethBalance;
    }

    /**
     * @notice Withdraw ether for player
     * @dev Can only withdraw up to `player` ethBalance
     * Cannot withdraw while in a journey
     * @param amount amount you want to withdraw
     * @param player the players address the owner is withdrawing for
     */
    function withdrawForPlayer(
        address payable player,
        uint256 amount
    )
        external
        virtual
        onlyOwner
        returns (uint256 remainingBal) 
    {
        require(
            amount <= players[player].ethBalance,
            "Withdraw amount must not exceed player's ethBalance"
        );
        require(
            !players[player].playing,
            "Cannot withdraw while player is in a journey"
        );

        players[player].ethBalance -= amount;

        amountUnlocked -= amount;

        emit WithdrawForPlayer(player, amount, players[player].ethBalance);

        payable(player).transfer(amount);
        
        // if withdrawal brings contract balance below maxReallocation%, emit event to alert admin to send funds back
        if (address(this).balance < (maxReallocation * (amountLocked + amountUnlocked) / 100)) {
            emit InsufficientBalanceForPlayerWithdrawal((maxReallocation * (amountLocked + amountUnlocked) / 100) - address(this).balance);
        }

        return players[player].ethBalance;
    }

    /**
     * @notice Increase a player's balance by msg.value
     * msg.value must be more than 0
     * @param player player address to top up
     */
    function topUpForPlayer(address player)
        external
        virtual
        payable
        returns (uint256 updatedBalance)
    {
        require(msg.value > 0, "topUpAmount must be more than 0");
        players[player].ethBalance += msg.value;
        
        // if player is in a journey, lock the topUpAmount
        if (players[player].playing) {
            amountLocked += msg.value;
        } else {
        // otherwise, add to amountUnlocked for accurate accounting
            amountUnlocked += msg.value;
        }

        emit TopUpForPlayer(player, msg.value, players[player].ethBalance);

        return players[player].ethBalance;
    }

    /**
     * @notice Move funds to an external contract and wallet for investment purposes
     * @dev Can only be called by owner, cannot exceed maxReallocation percentage of (amountLocked + amountUnlocked)
     * @param _to The address to move funds to
     * @param _amount The amount of funds to move
     */
    function moveFunds(
        address payable _to,
        uint256 _amount
    )
        external
        virtual
        onlyFundManager
        returns (uint256)
    {
        require(
            _to != address(0), "cannot move funds to zero address"
        );
        require(
            address(this).balance > maxReallocation * (amountLocked + amountUnlocked) / 100,
            "maxReallocation already reached"
        );
        require(
            _amount <= (maxReallocation * (amountLocked + amountUnlocked) / 100) - amountOwed, 
            "amount exceeds maxReallocation"
        );

        // add to amountOwed to the contract
        amountOwed += _amount;

        emit FundsMoved(_to, _amount, address(this).balance - _amount);
        
        // transfer funds to external address
        _to.transfer(_amount);

        return address(this).balance;
    }

    /**
     * @notice Receives funds back from external address (e.g. Mochi returning invested funds)
     * `msg.value` cannot exceed the amountOwed to the contract
     * @return The updated contract balance
     */
    function receiveFunds() external payable virtual onlyFundManager returns (uint256) {
        require(msg.value <= amountOwed, "cannot exceed amountOwed");
        uint256 amount = msg.value;

        amountOwed -= amount;

        emit FundsReceived(msg.sender, amount, address(this).balance);

        return address(this).balance;
    }

    /**
     * @notice Allows contract to receive funds and player data during migration.
     * Only callable by owner.
     * Updates amountLocked/amountUnlocked according to their `playing` status and `ethBalance`
     * Reverts if sum of ethBalances != msg.value
     * @param _players an array of player addresses
     * @param _ethBalances an array of players' ETH balances
     * @param _tokens an array of players' claimable tokens
     * @param _tokens an array of players' playing status
     */
    function receiveFundsAndPlayerData(
        address[] calldata _players,
        uint256[] calldata _ethBalances,
        uint256[] calldata _tokens,
        bool[] calldata _playing)
        external
        virtual
        payable
        onlyOwner
    {
        // require(called only once) ? TBD
        
        uint256 totalEthBalance;
        uint256 _amountLocked = 0;
        uint256 _amountUnlocked = 0;
        
        // populate PlayerStructs
        for (uint256 i = 0; i < _players.length; i++) {
            players[_players[i]].ethBalance = _ethBalances[i];
            players[_players[i]].tokens = _tokens[i];
            players[_players[i]].playing = _playing[i];
            
            if (_playing[i]) {
                _amountLocked += _ethBalances[i];
            } else {
                _amountUnlocked += _ethBalances[i];
            }
            totalEthBalance += _ethBalances[i];
        }
        
        // function all will revert if the sum of ethBalances does not equal to the amount sent in
        // this is to keep accounting accurate in the contract
        require(totalEthBalance == msg.value, "msg.value should equal the sum of ethBalances");

        // update global vars outside the for loop to save gas
        amountLocked += _amountLocked;
        amountUnlocked += _amountUnlocked;

        emit PlayerDataAndFundsSeeded(address(this).balance);
    }


    /**
     * @notice Withdraw the slashed funds to the withdrawalAddress
     * @dev will revert if withdrawalAddress has not been set
     */
    function withdrawSlashedBalance() external virtual onlyFundManager {
        uint256 _balance = _withdrawalAddressBalance;
        
        // Slashed balance is withdrawn from the `unlocked` bucket
        amountUnlocked -= _balance;
        
        _withdrawalAddressBalance = 0;

        emit WithdrawSlashedBalance(_balance);

        withdrawalAddress.transfer(_balance);

        // if withdrawal brings contract balance below maxReallocation%, emit event to alert admin to send funds back
        if (address(this).balance < (maxReallocation * (amountLocked + amountUnlocked) / 100)) {
            emit InsufficientBalanceForPlayerWithdrawal((maxReallocation * (amountLocked + amountUnlocked) / 100) - address(this).balance);
        }

    }

    /**
     * @notice Withdraw the entire contract balance to the withdrawalAddress
     */
    function withdrawContractBalance() external virtual onlyOwner {
        uint256 _balance = address(this).balance;
        emit WithdrawContractBalance(_balance);
        withdrawalAddress.transfer(_balance);
    }

    /**
     * @notice Allows users to claim their earned tokens
     * Transfers the claim amount from the game contract to the user
     */
    function claimTokens() external virtual {
        uint256 amount = players[msg.sender].tokens;
        players[msg.sender].tokens = 0;
        emit TokensClaimed(msg.sender, amount);
        token.transfer(msg.sender, amount);
    }

    /*************
    VIEW FUNCTIONS
    *************/

    /**
     * @notice Gets the ethBalance, tokens, and playingStatus for `player`
     * @param player Address of player to query
     * @return ethBalance tuple of the Player struct
     */
    function getPlayerInfo(address player) external virtual view returns (uint256 ethBalance, uint256 tokens, bool playing) {
        return (players[player].ethBalance, players[player].tokens, players[player].playing);
    }
    
    /**
     * @notice Gets the ethBalance, tokens, and playingStatus for a set of `players`
     * @param _players Addresses of players to query
     * @return playersInfo array of Player objects retrieved
     */
    function getAllPlayersInfo(address[] memory _players) external virtual view returns (Player[] memory playersInfo) {
        Player[] memory toReturn = new Player[](_players.length);
        for (uint256 i = 0; i < _players.length; i++) {
            toReturn[i] = players[_players[i]];
        }
        return toReturn;
    }

    /**
     * @notice Gets the balance of the sender
     * @param player The address of the player we want to check the withdrawable token balance for
     * @return uint256 representing the amount owned by the sender
     */
    function claimableTokens(address player) external view returns (uint256) {
        return players[player].tokens;
    }

    /**
     * @notice Gets the totalBalance of the contract
     * @return uint256 representing the total balance of the contract
     */
    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Gets the amount of amountLocked that is available to be reallocated using `moveFunds`
     * @return uint256 of amountLocked that can be moved
     */
    function amountAvailableToReallocate() external virtual view returns (uint256) {
        // NOTE: amountOwed should never exceed (maxReallocation * (amountLocked + amountUnlocked) / 100)
        // because of the require statement in `moveFunds`

        // if we still haven't reached maxReallocation of (amountLocked + amountUnlocked) i.e. what the contract balance *should* have if amountOwed = 0,
        // return the difference until we reach maxReallocation
        if (address(this).balance > maxReallocation * (amountLocked + amountUnlocked) / 100) {
            return address(this).balance - (maxReallocation * (amountLocked + amountUnlocked) / 100);
        } else {
            return 0;
        }
    }

    /**
     * @notice Gets the balance of funds assigned to withdrawalAddress (from slashed funds)
     * @return withdrawalAddressBalance
     */
    function getWithdrawalAddressBalance() external view returns (uint256) {
        return _withdrawalAddressBalance;
    }

    /**
     * @notice Retrieve the version number of the Game contract
     * @return String of the contract version
     */
    function version() external virtual pure returns (string memory) {
        return "1.0.0";
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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

/// SPDX-License-Identifier: GNU Affero General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Mochi Access Control
 * @author Liqhtworks LLC
 * @notice Mochi Role Management Contract
 */
contract MochiAccessControl is AccessControlUpgradeable {

    // Roles
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant JOURNEY_MANAGER = keccak256("JOURNEY_MANAGER");
    bytes32 public constant FUND_MANAGER = keccak256("FUND_MANAGER");

    address internal _owner;

    /*************
    ROLE MANAGEMENT
    *************/

    /**
     * @dev Grant an account fund management privileges
     * Can only be called by the `roleAdmin` for FUND_MANAGER
     * @param _newFundManager to add
     */
    function addFundManager(address _newFundManager) external {
        grantRole(FUND_MANAGER, _newFundManager);
    }

    /**
     * @dev Revoke an account's fund management privileges
     * Can only be called by the `roleAdmin` for FUND_MANAGER
     * @param _fundManager to remove
     */
    function removeFundManager(address _fundManager) external {
        revokeRole(FUND_MANAGER, _fundManager);
    }

    /**
     * @dev Grant an account journey management privileges
     * Can only be called by the `roleAdmin` for JOURNEY_MANAGER
     * @param _newJourneyManager to add
     */
    function addJourneyManager(address _newJourneyManager) external {
        grantRole(JOURNEY_MANAGER, _newJourneyManager);
    }

    /**
     * @dev Revoke an account's journey management privileges
     * Can only be called by the `roleAdmin` for JOURNEY_MANAGER
     * @param _journeyManager to remove
     */
    function removeJourneyManager(address _journeyManager) external {
        revokeRole(JOURNEY_MANAGER, _journeyManager);
    }

    /**
     * @dev Grant an account owner privileges
     * Can only be called by an OWNER
     * @param _newOwner to add
     */
    function addOwner(address _newOwner) external {
        grantRole(OWNER, _newOwner);
    }

    /**
     * @dev Revoke an account's owner privileges
     * Can only be called by an OWNER
     * @param _addr of owner to remove
     */
    function removeOwner(address _addr) external {
        revokeRole(OWNER, _addr);
    }

    /*************
    ROLE CHECKERS
    *************/

    /**
      * @dev returns true if a given account has fund management privileges
      * @param addr account to check
      * @return admin status
     */
    function isAFundManager(address addr) external view returns (bool) {
        return hasRole(FUND_MANAGER, addr);
    }

    /**
      * @dev returns true if a given account has journey management privileges
      * @param addr account to check
      * @return admin status
     */
    function isAJourneyManager(address addr) external view returns (bool) {
        return hasRole(JOURNEY_MANAGER, addr);
    }

    /**
      * @dev returns true if a given account has owner privileges
      * @param addr account to check
      * @return admin status
     */
    function isAnOwner(address addr) external view returns (bool) {
        return hasRole(OWNER, addr);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

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