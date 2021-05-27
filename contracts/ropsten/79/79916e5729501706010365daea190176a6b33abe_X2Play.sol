/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity 0.5.12;

contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0), "Ownable: initial owner is the zero address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    function _isOwner(address account) internal view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
 interface IERC20 {
     function transfer(address to, uint256 value) external returns (bool);
     function approve(address spender, uint256 value) external returns (bool);
     function transferFrom(address from, address to, uint256 value) external returns (bool);
     function totalSupply() external view returns (uint256);
     function balanceOf(address who) external view returns (uint256);
     function allowance(address owner, address spender) external view returns (uint256);
     function mint(address to, uint256 value) external returns (bool);
     function burnFrom(address from, uint256 value) external;
 }

 contract X2Play is Ownable {

     IERC20 public CCO;

     struct User {
         Batch[] batches;
         uint256 withdrawn;
     }

     mapping (address => User) public users;

     struct Batch {
         uint256 cycle;
         uint256 index;
         uint256 amount;
     }

     struct Round {
         uint256 start;
         uint256 amount;
         uint256 last;

         uint256 bets;
         uint256 players;
     }


     uint256 startDate;
     uint256 initialVolume;

     uint256 cycle;
     mapping (uint256 => Round[]) queue;

     constructor(address token, uint256 vol) public Ownable(msg.sender) {
         CCO = IERC20(token);
         queue[cycle].push(Round(vol, 0, now, 0, 0));
         startDate = now;
         initialVolume = vol;
     }

     function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external {
         require(token == address(CCO));
         (extraData);
         invest(from, amount);
     }

     function invest(address from, uint256 amount) public {
         CCO.transferFrom(from, address(this), amount);
         _invest(from, amount);
     }

     function _invest(address from, uint256 amount) internal {
         require(startDate <= now);
         queue[cycle][queue[cycle].length-1].last = now;

         (uint256 volume, uint256 filled, uint256 available) = getParameters(queue[cycle].length-1);

         if (amount >= available) {
             CCO.transfer(from, amount - available);
             amount = available;
         }

         queue[cycle][queue[cycle].length-1].amount += amount;
         queue[cycle][queue[cycle].length-1].bets++;
         queue[cycle][queue[cycle].length-1].players++;
         users[from].batches.push(Batch(cycle, queue[cycle].length-1, amount));

         if (volume == filled + amount) {
             queue[cycle].push(Round(volume * 210 / 100, 0, now, 0, 0));
         }
     }

     function reinvest(uint256 amount) public {
         require(amount <= getWithdrawable(msg.sender), "User has no this amount yet");
         users[msg.sender].withdrawn += amount;
         _invest(msg.sender, amount);
     }

     function withdraw(uint256 amount) public {
         require(amount > getWithdrawable(msg.sender), "User has no such amount to withdraw yet");
         users[msg.sender].withdrawn += amount;
         CCO.transfer(msg.sender, amount);
     }

     function restart(uint256 start) public onlyOwner {
         require(now - queue[cycle][queue[cycle].length-1].last > 30 days, "Too early");
         cycle++;
         queue[cycle].push(Round(start, 0, now, 0, 0));
     }

     function getWithdrawn(address account) public view returns(uint256 withdrawable) {
         return users[account].withdrawn;
     }

     function getWithdrawable(address account) public view returns(uint256 withdrawable) {
         for (uint256 i; i < users[account].batches.length; i++) {
             if (users[account].batches[i].index + 2 < queue[cycle].length) {
                 withdrawable += users[account].batches[i].amount * 2;
             }
         }
         withdrawable -= users[account].withdrawn;
     }

     function getParameters(uint256 index) public view returns(uint256 volume, uint256 filled, uint256 available) {
         volume = initialVolume;

         for (uint256 i; i < index; i++) {
             volume = volume * 210 / 100;
         }

         filled = queue[cycle][index].amount;
         available = volume - filled;
     }

     function getGameInfo() public view returns(uint256 _cycle, uint256 round, uint256 bets, uint256 players, uint256 volume, uint256 filled, uint256 available) {
         _cycle = cycle;
         round = queue[cycle].length;

         (volume, filled, available) = getParameters(round);

         bets = queue[cycle][round].bets;
         players = queue[cycle][round].players;
     }

     function getBatch(address account, uint256 i) public view returns(uint256 index, uint256 amount) {
         return (users[account].batches[i].index, users[account].batches[i].amount);
     }

     function getAmountOfRounds() public view returns(uint256) {
         return queue[cycle].length;
     }

     function getInsurance(address account) public view returns(uint256 insurance) {
         if (users[account].batches.length > 1) {
             insurance = initialVolume * 10 / 100;
         }
         for (uint256 i; i < users[account].batches.length-1; i++) {
             insurance = insurance * 210 / 100;
         }
     }

     function isStarted() public view returns(bool) {
         return (now >= startDate);
     }

     function getUserStats(address account) public view returns(uint256 totalBets, uint256 totalProfit, uint256 totalWithdrawn, uint256 totalWithdrawable) {
         totalBets = users[account].batches.length;
         totalWithdrawn = getWithdrawn(account);
         totalWithdrawable = getWithdrawable(account);
         totalProfit = totalWithdrawn + totalWithdrawable;
     }

     function getUserGames(address account, uint256 from, uint256 to) public view returns(uint256[] memory _cycle, uint256[] memory round, uint256[] memory start, uint256[] memory finish, uint256[] memory totalPlayers, uint256[] memory profit) {
         uint256 amountOfBatches = users[account].batches.length;

         if (to > amountOfBatches) {
             to = amountOfBatches;
         }

         require(to < from);

         uint256 length = to - from;

         _cycle = new uint256[](length);
         round = new uint256[](length);
         start = new uint256[](length);
         finish = new uint256[](length);
         totalPlayers = new uint256[](length);
         profit = new uint256[](length);

         for (uint256 i = 0; i < length; i++) {
             _cycle[i] = users[account].batches[from + i].cycle;
             round[i] = users[account].batches[from + i].index;
             start[i] = queue[_cycle[i]][round[i]].start;
             if (queue[_cycle[i]].length-1 > round[i]) {
                 finish[i] = queue[_cycle[i]][round[i+1]].start;
             }
             totalPlayers[i] = queue[_cycle[i]][round[i+1]].players;
             if (round[i] + 2 < queue[_cycle[i]].length) {
                 profit[i] = users[account].batches[from + i].amount * 2;
             }///
         }
     }

 }