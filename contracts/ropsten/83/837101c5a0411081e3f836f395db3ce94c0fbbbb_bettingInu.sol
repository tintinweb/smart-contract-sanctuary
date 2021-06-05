// SPDX-License-Identifier: UNLICENSED
// testnet code, not for use
pragma solidity ^0.8.4;
import "./ERC20.sol";
contract bettingInu is ERC20("WOOINU used for betting", "BINU"){
    event betCreated(string name, uint256 reward, string choiceA, string choiceB, uint256 end );
    event betFinalized(uint256 index, bool choiceAorB);
    event userBet(uint256 index,uint256 amount, address sender, bool choice);
    event rewardCollected(address user, uint256 index, uint256 rewardAmount);
    struct _bet {
        uint256 totalReward;
        uint256 voteA;
        uint256 voteB;
        string name;
        string choiceA;
        string choiceB;
        uint256 end;
        bool winningChoice;
        bool finalized;
    }
    struct _lock{
        uint256 amount;
        uint256 enddate;
    }
    struct _bet_{
        bool choice;
        uint256 amount;
    }
    _bet[] private _bets;
    IERC20 private _tokenContract;
    address private _owner;
    uint256 private _lockAmount;
    mapping (address => _lock) private _locks;
    mapping (address => mapping(uint256 => _bet_)) private _amountBetted;
    constructor (IERC20 __tokenContract){
        _tokenContract = __tokenContract;
        _lockAmount = 0;
        _owner = _msgSender();
    }
    function checkForLock(address from, uint256 amount) internal view{
        _lock memory fromLock = _locks[from];
        unchecked{
        require(balanceOf(from) - fromLock.amount >= amount || fromLock.enddate <= block.timestamp, "BINU: You can only transfer unLocked BINU's");
        }
    }
    function _beforeTokenTransfer(address from, address to , uint256 amount) internal virtual override(ERC20){
       checkForLock(from, amount);
    }
    function tokenContract() external view returns (IERC20){
        return _tokenContract;
    }
    function owner() external view returns (address){
        return _owner;
    }
    function lockAmount() external view returns (uint256){
        return _lockAmount;
    }
    function bets() external view returns (_bet[] memory){
        return _bets;
    }
    function betByIndex(uint256 index) external view returns (_bet memory){
        return _bets[index];
    }
    function lock(address user) external view returns (_lock memory){
        return _locks[user];
    }
    function transferOwnership(address newOwner) external{
        require (_msgSender() == _owner, "BINU: You have to be the owner to do this");
        _owner = newOwner;
    }

    function createBet(string memory choiceA, string memory choiceB, string memory name, uint256 end) payable external {
        require (_msgSender() == _owner, "BINU: You have to be the owner to do this");
        _bet memory __bet;
        __bet.totalReward = msg.value;
        __bet.name = name;
        __bet.choiceA = choiceA;
        __bet.choiceB = choiceB;
        __bet.end = end;
        _bets.push(__bet);
        emit betCreated(name, msg.value, choiceA, choiceB, end);
    }
    function bet(uint256 index, uint256 amount, bool __bet) external {
        address sender = _msgSender();
        _bet memory theBet = _bets[index];
        require(theBet.end > block.timestamp, "BINU: The betting period has already ended");
        unchecked{
        require(balanceOf(sender) - _amountBetted[sender][index].amount >= amount, "BINU: You do not have enough BINU");
        }
        if (theBet.end > _locks[sender].enddate){
            _locks[sender].enddate = theBet.end;
        }
        _amountBetted[sender][index].amount += amount;
        if (__bet == true){
            _bets[index].voteA += amount;
            _amountBetted[sender][index].choice = true;
        }else{
            _bets[index].voteB += amount;
            _amountBetted[sender][index].choice = false;
        }
        emit userBet(index, amount, sender, __bet);
        
    }
    function add(uint256 amount) external {
        address sender = _msgSender();
        _tokenContract.transferFrom(sender, address(this), amount);
        _locks[sender] = _lock(amount, (block.timestamp + _lockAmount));
        _mint(sender, amount);
    }
    function redeem(uint256 amount) external {
        address sender = _msgSender();
        checkForLock(sender, amount);
        _burn(sender, amount);
        _tokenContract.transfer(sender, amount);
    }
    function collectRewards(uint256 index) external{
        address sender = _msgSender();
        _bet memory theBet = _bets[index]; 
        require(bytes(theBet.name).length > 0, "BINU: That Bet doesn't exist");
        require(_amountBetted[sender][index].amount > 0, "BINU: You haven't voted on that yet");
        require(block.timestamp >= theBet.end, "BINU: The bet hasn't expired yet");
        require (theBet.finalized == true, "BINU: Please wait until the results of this bet have been published");
        require (theBet.winningChoice == _amountBetted[sender][index].choice, "BINU: You chose the wrong choice");
        uint256 amountToReward;
        if (theBet.winningChoice == true){
        amountToReward = (((theBet.totalReward * 1e18) / (theBet.voteA)) * _amountBetted[sender][index].amount) / 1e18;
        }else{
            amountToReward = (((theBet.totalReward * 1e18) / (theBet.voteB)) * _amountBetted[sender][index].amount) / 1e18;
        }
        payable(sender).transfer(amountToReward);
        emit rewardCollected(sender, index, amountToReward);
    }
    function finalizeBet(uint256 index, bool choiceAorB) external {
        require (_msgSender() == _owner, "BINU: You do not have permission to do this");
        require(_bets[index].end > block.timestamp, "BINU: This bet has not ended yet");
        _bets[index].finalized = true;
        _bets[index].winningChoice = choiceAorB;
        emit betFinalized(index, choiceAorB);
    }
}