// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20Snapshot.sol";
import "./Ownable.sol";

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
contract bettingInu is ERC20("WOOINU used for betting", "BINU"), ERC20Snapshot, Ownable{
    /**
    * @dev Event emitted when a bet is created.
    * @return The index, The URI, The reward, and The timestamp of when it ends
    */
    event betCreated(uint256 index, string metadataURI, uint256 reward, uint256 end);

    /**
    * @dev Event emmited when a bets result is given by the owner
    * @return The index and The winning choice
    */
    event betFinalized(uint256 index, uint256 choiceAorB);

    /**
    * @dev Event emmited when a user bets
    * @return Index of the bet, Amount betted, The user and The choice the user chose
    */
    event _bet(uint256 index, uint256 amount, address sender, uint256 choice);

    /**
    * @dev Event emmited when a user collects his reward
    * @return The user, The index of the bet, Amount rewarded
    */
    event rewardCollected(address user, uint256 index, uint256 rewardAmount);

    /**
    * @dev Event emmited when a user deposit WOOINU
    * @return The user, the amount deposited 
    */
    event _deposit(address user, uint256 amount);

    /**
    * @dev Event emmited when a user withdraws WOOINU
    * @return The user, the amount withdrawed
    */
    event withdrawal(address user, uint256 amount);

    /**
    * @dev Event emmited when a user unlocks his WOOINU
    * @return The user
    */
    event unlock(address user, uint256 amount);
    
    /**
    * @dev Modifier that check if `x` index exists by checking if the index is lower than
    * the amount of bets created
    * @param index: Index of the bet
    */
    modifier exists(uint256 index){
        require(index < _bets.length, "BINU: That bet does not exist");
        _;
    }

    /**
    * @dev Struct of a bet
    * @param totalReward: The total amount of $ETH to reward to user
    * @param Choices: Amount of choices 
    * @param metadataURI: A URI for a bets metadata (name, image, etc.)
    * @param end: The timestamp of when the betting period will be finished
    * @param winningChoice: After its finalized, this will show who won
    */
    struct bet__ {
        uint256 totalReward;
        uint256 choices;
        uint256 end;
        uint256 winningChoice;
        string metadataURI;
    }

    /**
    * @dev Struct of a lock
    * @param amount: Amount of coins locked
    * @param endDate: The timestamp of when the coins get unlocked 
    */
    struct _lock{
        uint256 amount;
        uint256 endDate;
    }

    /**
    * @dev A struct to store a users bet, user to make sure the user has betted
    * to collect his reward
    * @param choice: The choice he betted
    * @param amount: Amount of tokens betted
    */
    struct _bet_{
        uint256 choice;
        uint256 amount;
    }

    /**
    * @dev 
    * _bets: Array of all the bets created
    * _tokenContract: The contract of the ERC20
    * _lockAmount: After a user adds tokens, this defines how much those tokens will be locked for
    * _locks: A mapping of User => Timestamp of when he can unlock his tokens
    * bets_: A mapping of User => Bet index => _bet_ struct for choice and amount
    * _totalBetted: A mapping of Bet index => Choice => Total amount betted
    */
    bet__[] private _bets;
    IERC20 private _tokenContract;
    uint256 private _lockAmount;
    mapping (address => _lock) private _locks;
    mapping (address => mapping(uint256 => _bet_)) private bets_;
    mapping (uint256 => mapping(uint256 => uint256)) private _totalBetted;

    /**
    * @dev Sets the token contract (ERC20) and the total amount for lock
    */
    constructor (IERC20 __tokenContract){
        _tokenContract = __tokenContract;
        _lockAmount = 600;
    }

    /**
    * @return Returns the ERC20 being used
    */
    function tokenContract() external view returns (IERC20){
        return _tokenContract;
    }

    /**
    * @return Returns how much time tokens are locked for
    */
    function lockAmount() external view returns (uint256){
        return _lockAmount;
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
    function bets() external view returns (bet__[] memory){
        return _bets;
    }

    /**
    * @return Returns a bet by its index
    * @param index: The index of the bet
    */
    function betByIndex(uint256 index) external view returns (bet__ memory){
        return _bets[index];
    }

    /**
    * @return Returns when a user can unlock his coin + the amount he has locked
    * @param user: The user to check
    */
    function lock(address user) external view returns (_lock memory){
        return _locks[user];
    }

    /**
    * @return Returns how much a user has betted on a bet
    * @param user: The user to check
    * @param index: The index of the bet
    */
    function betOf(address user, uint256 index) external view returns (_bet_ memory){
        return bets_[user][index];
    }
    
    /**
    * @dev Checks if user has enough unlocked BINU's and reverts 
    * if he doesn't, Also unlocks if the lock has ended
    * @param user: The user to check for
    * @param amount: The amount needed for the user to have
    */
    function checkForLock(address user, uint256 amount) internal {
        _lock memory lock_ = _locks[user];
        // Checks for unlock
        if(lock_.endDate <= block.timestamp && lock_.endDate != 0){
            delete _locks[user];
            emit unlock(user, lock_.amount);
            return;
        }
        if (lock_.amount != 0){
            unchecked{
                require(balanceOf(user) - lock_.amount >= amount, "BINU: You can only transfer unlocked or available BINU");
            }
        }
    }

    /**
    * @dev Checks for lock before transfering, calls checkForLock()
    * @param from: User sending the transaction
    * @param to: Not used
    * @param amount: The amount transfered
    */
    function _beforeTokenTransfer(address from, address to , uint256 amount) internal virtual override(ERC20, ERC20Snapshot) {
       checkForLock(from, amount);
       super._beforeTokenTransfer(from, to, amount);
    }

    /**
    * @dev Creates a bet for people to bet on and takes a snapshot of balances(See [email protected]) and emits betcreated
    * @param metadataURI: The uri used to check for info like image, etc.
    * @param choices: The amount of choices allowed to bet on
    * @param end: How much seconds until the betting period ends
    */
    function createBet(string memory metadataURI, uint256 end, uint256 choices) payable external onlyOwner {
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
    * @dev Bets on a NFT and emits _bet(), gets balance from snapshot. amount can be 0 to change the choice
    * @param index: The index of the bet
    * @param amount: The amount to bet on it
    * @param __bet: What to bet on
    */
    function bet(uint256 index, uint256 amount, uint256 __bet) external exists(index){
        address sender = _msgSender();
        bet__ memory bet_ = _bets[index];
        require(block.timestamp < bet_.end, "BINU: The betting period has ended");
        require (__bet <= bet_.choices && __bet != 0, "BINU: That is not a valid bet");
        unchecked{
        require(balanceOfAt(sender, (index + 1)) - bets_[sender][index].amount >= amount, "BINU: You do not have enough BINU");
        }
        bets_[sender][index].amount += amount;
        bets_[sender][index].choice = __bet;
        _totalBetted[index][__bet] += amount;
        emit _bet(index, amount, sender, __bet);
    }

    /**
    * @dev Wraps the ERC20 and locks it. 
    * Emits _deposit()
    * @param amount: Amount of tokens to wrap
    */
    function deposit(uint256 amount) external {
        address sender = _msgSender();
        // Unlocks if it hasn't already. This would ensure that its not renewing the lock for already unlocked tokens
        if (_locks[sender].endDate <= block.timestamp && _locks[sender].endDate != 0){delete _locks[sender];}
        _tokenContract.transferFrom(sender, address(this), amount);
        _locks[sender] = _lock(_locks[sender].amount + amount, (block.timestamp + _lockAmount));
        _mint(sender, amount);
        emit _deposit(sender, amount);
    }

    /**
    * @dev Redeems the wrapped tokens for the ERC20. Emits withdrawal()
    * @param amount: Amount to redeem
    */
    function withdraw(uint256 amount) external {
        address sender = _msgSender();
        checkForLock(sender, amount);
        _burn(sender, amount);
        _tokenContract.transfer(sender, amount);
        emit withdrawal(sender, amount);
    }
    
    /**
    * @dev Public function that returns how much unclaimed rewards a user has
    * for x index, used by collectRewards()
    * @param user: The user to check rewards for
    * @param index: The index of a bet to check rewards for
    * @return Amount of unclaimed ETH in wei */
    function unclaimedReward(address user, uint256 index) public view exists(index) returns (uint256){
        bet__ memory bet_ = _bets[index]; 
        require (block.timestamp >= bet_.end, "BINU: The betting period has not ended");
        require (bets_[user][index].amount != 0, "BINU: You have not betted on that");
        require (bet_.winningChoice != 0, "BINU: Please wait until the results of this bet have been published");
        require (bet_.winningChoice == bets_[user][index].choice, "BINU: You chose the wrong choice");
        return (((bet_.totalReward * 1e18) / (_totalBetted[index][bet_.winningChoice])) * bets_[user][index].amount) / 1e18;
    }
    
    /**
    * @dev Collects the reward of winning a bet
    * @param index: The index of the bet to collect rewards from
    */
    function collectRewards(uint256 index) external exists(index){
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
    function finalizeBet(uint256 index, uint256 winningChoice) external onlyOwner exists(index){
        require(_bets[index].end <= block.timestamp, "BINU: This bet has not ended yet");
        require(winningChoice <= _bets[index].choices, "BINU: That is not a valid winning bet");
        require(_bets[index].winningChoice == 0, "BINU: You have already finalized this bet");
        _bets[index].winningChoice = winningChoice;
        emit betFinalized(index, winningChoice);
    }

    /**
    * @dev A command that only the the owner can call that changes how much time
    * funds are locked for
    * @param newLock: The new amount of time locks will be
    */
    function setLockAmount(uint256 newLock) external onlyOwner {
        _lockAmount = newLock;
    }

    /**
    * @dev A command that only the owner can call that changes the ERC20 being used for this contract
    * @param newContract: The new ERC20 being used
    */
    function setTokenContract(IERC20 newContract) external onlyOwner {
        _tokenContract = newContract;
    }

}