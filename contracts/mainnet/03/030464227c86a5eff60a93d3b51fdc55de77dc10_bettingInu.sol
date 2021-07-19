// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./ILockableERC20.sol";
import "./IRiskFreeBetting.sol";

/**
███╗   ██╗ █████╗ ████████╗██╗   ██╗██████╗ ███████╗    ██████╗  ██████╗ ██╗   ██╗    ██╗███╗   ██╗██╗   ██╗
████╗  ██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔════╝    ██╔══██╗██╔═══██╗╚██╗ ██╔╝    ██║████╗  ██║██║   ██║
██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝█████╗      ██████╔╝██║   ██║ ╚████╔╝     ██║██╔██╗ ██║██║   ██║
██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗██╔══╝      ██╔══██╗██║   ██║  ╚██╔╝      ██║██║╚██╗██║██║   ██║
██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗    ██████╔╝╚██████╔╝   ██║       ██║██║ ╚████║╚██████╔╝
╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═════╝  ╚═════╝    ╚═╝       ╚═╝╚═╝  ╚═══╝ ╚═════╝ 

* @title WOOINU Betting Contract
* @author Nature Boy Inu <spaceowl.eth>
*/
contract bettingInu is
    IRiskFreeBetting,
    ERC20("Leglock", "LEG"),
    ILockableERC20,
    ERC20Snapshot,
    Ownable
{
    /**
     * @dev Modifier that check if `x` index exists by checking if the index is lower than
     * the amount of bets created, and reverts if index is 0
     * @param index: Index of the bet
     */
    modifier exists(uint256 index) {
        require(
            index < _bets.length && index != 0,
            "LEG: That bet does not exist"
        );
        _;
    }

    /**
     * @dev
     * _bets: Array of all the bets created
     * _tokenContract: The contract of the ERC20
     * _lockLength: After a user adds tokens, this defines how much those tokens will be locked for
     * _locks: A mapping of User => Timestamp of when he can unlock his tokens
     * bets_: A mapping of User => Bet index => _bet_ struct for choice and amount
     * _totalBetted: A mapping of Bet index => Choice => Total amount betted
     */
    bet__[] private _bets;
    IERC20 private _tokenContract;
    uint256 private _lockLength;
    mapping(address => _lock) private _locks;
    mapping(address => mapping(uint256 => _bet_)) private bets_;
    mapping(uint256 => mapping(uint256 => uint256)) private _totalBetted;

    /**
     * @dev Sets the token contract (ERC20) and the total amount for lock, and increases
     * the bets length by 1 using an empty bet
     */
    constructor(IERC20 __tokenContract) {
        _tokenContract = __tokenContract;
        _lockLength = 600;
        bet__ memory bet_;
        _bets.push(bet_);
    }

    /**
     * @return Returns the ERC20 being used
     */
    function tokenContract() external view override returns (IERC20) {
        return _tokenContract;
    }

    /**
     * @return Returns how much time tokens are locked for
     */
    function lockLength() external view override returns (uint256) {
        return _lockLength;
    }

    /**
     * @return The amount of decimals, the same as WOOINU
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @return Returns all the bets that have been done + ongoing bets.
     */
    function bets() external view override returns (bet__[] memory) {
        return _bets;
    }

    /**
     * @return The amount of tokens that have been betted on a choice
     * @param index: The index of the bet
     * @param choice: The choice of the bet
     */
    function totalBetted(uint256 index, uint256 choice)
        external
        view
        override
        returns (uint256)
    {
        require(
            choice <= _bets[index].choices && choice != 0,
            "LEG: That is not a valid bet"
        );
        return _totalBetted[index][choice];
    }

    /**
     * @return Returns a bet by its index
     * @param index: The index of the bet
     */
    function betByIndex(uint256 index)
        external
        view
        override
        returns (bet__ memory)
    {
        return _bets[index];
    }

    /**
     * @return Returns when a user can unlock his coin + the amount he has locked
     * @param user: The user to check
     */
    function lock(address user) external view override returns (_lock memory) {
        return _locks[user];
    }

    /**
     * @return Returns how much a user has betted on a bet
     * @param user: The user to check
     * @param index: The index of the bet
     */
    function betOf(address user, uint256 index)
        external
        view
        override
        returns (_bet_ memory)
    {
        return bets_[user][index];
    }

    /**
     * @dev Function that check if a user can unlock their tokens
     * @param user: The user to unlock for
     */
    function checkForUnlock(address user) internal {
        _lock memory lock_ = _locks[user];
        if (lock_.endDate <= block.timestamp && lock_.endDate != 0) {
            delete _locks[user];
            emit unlock(user, lock_.amount);
            return;
        }
    }

    /**
     * @dev Checks if user has enough unlocked LEG's and reverts
     * if he doesn't, Also unlocks if the lock has ended
     * @param user: The user to check for
     * @param amount: The amount needed for the user to have
     */
    function checkForLock(address user, uint256 amount) internal {
        // Checks for unlock
        checkForUnlock(user);
        if (_locks[user].amount != 0) {
            require(
                balanceOf(user) - _locks[user].amount >= amount,
                "LEG: You can only transfer unlocked or available LEG"
            );
        }
    }

    /**
     * @dev Checks for lock before transfering, calls checkForLock()
     * @param from: User sending the transaction
     * @param to: Not used
     * @param amount: The amount transfered
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        checkForLock(from, amount);
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Creates a bet for people to bet on and takes a snapshot of balances(See [email protected]) and emits betcreated
     * @param metadataURI: The URI used to check for info like image, etc.
     * @param choices: The amount of choices allowed to bet on
     * @param end: How much seconds until the betting period ends
     */
    function createBet(
        string memory metadataURI,
        uint256 end,
        uint256 choices
    ) external payable override onlyOwner {
        uint256 index = _bets.length;
        _snapshot();
        uint256 _end = block.timestamp + end;
        bet__ memory __bet;
        __bet.totalReward = msg.value;
        __bet.metadataURI = metadataURI;
        __bet.end = _end;
        __bet.choices = choices;
        _bets.push(__bet);
        emit betCreated(index, metadataURI, msg.value, _end);
    }

    /**
     * @dev Bets on a bet and emits _bet(), gets balance from snapshot. amount can be 0 to change the choice
     * @param index: The index of the bet
     * @param amount: The amount to bet on it
     * @param __bet: What to bet on
     */
    function bet(
        uint256 index,
        uint256 amount,
        uint256 __bet
    ) external override exists(index) {
        address sender = _msgSender();
        bet__ memory bet_ = _bets[index];
        _bet_ memory amountAndChoice = bets_[sender][index];
        require(
            block.timestamp < bet_.end,
            "LEG: The betting period has ended"
        );
        require(
            __bet <= bet_.choices && __bet != 0,
            "LEG: That is not a valid bet"
        );
        require(
            balanceOfAt(sender, index) - amountAndChoice.amount >= amount,
            "LEG: You do not have enough LEG"
        );
        /// @dev If its a new choice, remove from the old totalBetted and
        /// add to the new choices total betted by (old amount betted + the new amount betted)
        /// if it isn't it will just add on top of it
        if (
            __bet != amountAndChoice.choice && amountAndChoice.choice != 0
        ) {
            _totalBetted[index][amountAndChoice.choice] -= amountAndChoice.amount;
            _totalBetted[index][__bet] += (amountAndChoice.amount + amount);
        } else {
            _totalBetted[index][__bet] += amount;
        }
        bets_[sender][index].amount += amount;
        bets_[sender][index].choice = __bet;
        emit _bet(index, amount, sender, __bet);
    }

    /**
     * @dev Wraps the ERC20 and locks it.
     * Emits _deposit()
     * @param amount: Amount of tokens to wrap
     */
    function deposit(uint256 amount) external override {
        address sender = _msgSender();
        // Unlocks if it hasn't already. This would ensure that its not renewing the lock for already unlocked tokens
        checkForUnlock(sender);
        _tokenContract.transferFrom(sender, address(this), amount);
        _locks[sender] = _lock(
            _locks[sender].amount + amount,
            (block.timestamp + _lockLength)
        );
        _mint(sender, amount);
        emit _deposit(sender, amount);
    }

    /**
     * @dev Redeems the wrapped tokens for the ERC20. Emits withdrawal()
     * @param amount: Amount to redeem
     */
    function withdraw(uint256 amount) external override {
        address sender = _msgSender();
        // Using _burn() will call before token transfer, which will check for locks
        _burn(sender, amount);
        _tokenContract.transfer(sender, amount);
        emit withdrawal(sender, amount);
    }

    /**
     * @dev Public function that returns how much unclaimed rewards a user has
     * for x index, used by collectReward()
     * @param user: The user to check rewards for
     * @param index: The index of a bet to check rewards for
     * @return Amount of unclaimed ETH in wei 
     */
    function unclaimedReward(address user, uint256 index)
        public
        view
        override
        exists(index)
        returns (uint256)
    {
        bet__ memory bet_ = _bets[index];
        require(
            block.timestamp >= bet_.end,
            "LEG: The betting period has not ended"
        );
        require(
            bets_[user][index].amount != 0,
            "LEG: You have not betted on that or you have already collected the reward"
        );
        require(
            bet_.winningChoice != 0,
            "LEG: Please wait until the results of this bet have been published"
        );
        require(
            bet_.winningChoice == bets_[user][index].choice,
            "LEG: You chose the wrong choice"
        );
        return
            (bet_.totalReward * bets_[user][index].amount) /
            _totalBetted[index][bet_.winningChoice];
    }

    /**
     * @dev Collects the reward of winning a bet
     * @param index: The index of the bet to collect rewards from
     */
    function claimReward(uint256 index) external override exists(index) {
        address sender = _msgSender();
        uint256 amountToReward = unclaimedReward(sender, index);
        delete bets_[sender][index];
        payable(sender).transfer(amountToReward);
        emit rewardCollected(sender, index, amountToReward);
    }

    /**
     * @dev A command that can only be used by the owner to choose the winning choice of a bet, emits betFinalized()
     * @param index: The index of the bet to finalize
     * @param winningChoice: The winningChoice of the bet
     */
    function finalizeBet(uint256 index, uint256 winningChoice)
        external
        override
        onlyOwner
        exists(index)
    {
        require(
            _bets[index].end <= block.timestamp,
            "LEG: This bet has not ended yet"
        );
        require(
            winningChoice <= _bets[index].choices,
            "LEG: That is not a valid winning bet"
        );
        require(
            _bets[index].winningChoice == 0,
            "LEG: You have already finalized this bet"
        );
        _bets[index].winningChoice = winningChoice;
        emit betFinalized(index, winningChoice);
    }

    /**
     * @dev A command that only the the owner can call that changes how much time
     * funds are locked for
     * @param newLockLength: The new amount of time locks will be
     */
    function setLockLength(uint256 newLockLength) external onlyOwner {
        _lockLength = newLockLength;
    }

    /**
     * @dev A command that only the owner can call that changes the ERC20 being used for this contract
     * @param newContract: The new ERC20 being used
     */
    function setTokenContract(IERC20 newContract) external onlyOwner {
        _tokenContract = newContract;
    }
}