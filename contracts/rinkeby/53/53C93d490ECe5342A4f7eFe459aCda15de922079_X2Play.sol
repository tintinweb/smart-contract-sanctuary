/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity 0.5.12;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

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
     using SafeMath for uint256;

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
         uint32 start;
         uint32 last;

         uint256 amount;
         uint256 bets;
         uint256 players;
     }

     uint32 startDate;
     uint256 initialVolume;

     uint256 cycle;
     mapping (uint256 => Round[]) queue;

     constructor(address token, uint256 vol) public Ownable(msg.sender) {
         CCO = IERC20(token);
         queue[cycle].push(Round(uint32(now), uint32(now), 0, 0, 0)); ///
         startDate = uint32(now);
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

         (uint256 volume, uint256 filled, uint256 available) = getParameters(queue[cycle].length-1);

         if (amount >= available) {
             CCO.transfer(from, amount.sub(available));
             amount = available;
         }

         users[from].batches.push(Batch(cycle, queue[cycle].length-1, amount));

         if (users[from].batches.length == 1) {
             queue[cycle][queue[cycle].length-1].players++;
         } else if (
             users[from].batches[users[from].batches.length-2].cycle < cycle
             ||
             users[from].batches[users[from].batches.length-2].index < queue[cycle].length-1
             ) {
             queue[cycle][queue[cycle].length-1].players++;
         }


         queue[cycle][queue[cycle].length-1].bets++;
         queue[cycle][queue[cycle].length-1].amount = queue[cycle][queue[cycle].length-1].amount.add(amount);
         queue[cycle][queue[cycle].length-1].last = uint32(now);

         if (volume == filled + amount) {
             queue[cycle].push(Round(uint32(now), uint32(now), 0, 0, 0));
         }
     }

     function reinvest(uint256 amount) public {
         require(amount <= getWithdrawable(msg.sender), "User has no this amount yet");
         users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(amount);
         _invest(msg.sender, amount);
     }

     function withdraw(uint256 amount) public {
         require(amount <= getWithdrawable(msg.sender), "User has no such amount to withdraw yet");
         users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(amount);
         CCO.transfer(msg.sender, amount);
     }

     function restart(uint256 start) public onlyOwner {
         require(now - queue[cycle][queue[cycle].length-1].last > 1 days, "Too early");
         cycle++;
         queue[cycle].push(Round(0, uint32(now), 0, 0, 0));
         CCO.transfer(msg.sender, initialVolume);
         initialVolume = start;
     }

     function getWithdrawn(address account) public view returns(uint256 withdrawable) {
         return users[account].withdrawn;
     }

     function getWithdrawable(address account) public view returns(uint256 withdrawable) {
         for (uint256 i; i < users[account].batches.length; i++) {
             if (users[account].batches[i].index + 2 < queue[cycle].length) {
                 withdrawable = withdrawable.add(users[account].batches[i].amount.mul(2));
             }
         }
         withdrawable = withdrawable.sub(users[account].withdrawn);
     }

     function getParameters(uint256 index) public view returns(uint256 volume, uint256 filled, uint256 available) {
         volume = initialVolume;

         for (uint256 i; i < index; i++) {
             volume = volume.mul(210).div(100);
         }

         filled = queue[cycle][index].amount;
         available = volume.sub(filled);
     }

     function getCurrentGameInfo() public view returns(uint256 _cycle, uint256 round, uint256 bets, uint256 players, uint256 volume, uint256 filled, uint256 available, uint256 lastTx) {
         _cycle = cycle;
         round = queue[cycle].length.sub(1);

         (volume, filled, available) = getParameters(round);

         bets = queue[cycle][round].bets;
         players = queue[cycle][round].players;
         lastTx = queue[cycle][round].last;
     }

     function getGamesInfo(uint256 _cycle, uint256 from, uint256 to) public view returns(uint256[] memory bets, uint256[] memory players, uint256[] memory volume, uint256[] memory filled, uint256[] memory available) {
         if (queue[cycle].length < to) {
             to = queue[cycle].length;
         }

         require(to >= from);

         uint256 length = to.sub(from);

         bets = new uint256[](length);
         players = new uint256[](length);
         volume = new uint256[](length);
         filled = new uint256[](length);
         available = new uint256[](length);

         for (uint256 i; i < length; i++) {
             (volume[i], filled[i], available[i]) = getParameters(from + i);

             bets[i] = queue[_cycle][from + i].bets;
             players[i] = queue[_cycle][from + i].players;
         }
     }

     function getLastTx() public view returns(uint256 lastTx) {
         return queue[cycle][queue[cycle].length.sub(1)].last;
     }

     function getBatch(address account, uint256 i) public view returns(uint256 index, uint256 amount) {
         return (users[account].batches[i].index, users[account].batches[i].amount);
     }

     function getAmountOfRounds() public view returns(uint256) {
         return queue[cycle].length;
     }

     function getInsurance(address account) public view returns(uint256 insurance) {
         if (users[account].batches.length > 1) {
             insurance = initialVolume.mul(10).div(100);
         }
         for (uint256 i; i < users[account].batches.length-1; i++) {
             insurance = insurance.mul(210).div(100);
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

     function getUserGames(address account, uint256 from, uint256 to) public view returns(uint256[] memory _cycle, uint256[] memory round, uint256[] memory start, uint256[] memory finish, uint256[] memory totalBets, uint256[] memory totalPlayers, uint256[] memory profit) {
         uint256 amountOfBatches = users[account].batches.length;

         if (to > amountOfBatches) {
             to = amountOfBatches;
         }

         require(to >= from);

         uint256 length = to - from;

         _cycle = new uint256[](length);
         round = new uint256[](length);
         start = new uint256[](length);
         finish = new uint256[](length);
         totalBets = new uint256[](length);
         totalPlayers = new uint256[](length);
         profit = new uint256[](length);

         for (uint256 i = 0; i < length; i++) {
             _cycle[i] = users[account].batches[from + i].cycle;
             round[i] = users[account].batches[from + i].index;
             start[i] = queue[_cycle[i]][round[i]].start;
             if (queue[_cycle[i]].length-1 > round[i]) {
                 finish[i] = queue[_cycle[i]][round[i+1]].start;
             }
             totalBets[i] = queue[_cycle[i]][round[i]].bets;
             totalPlayers[i] = queue[_cycle[i]][round[i]].players;
             if (round[i] + 2 < queue[_cycle[i]].length) {
                 profit[i] = users[account].batches[from + i].amount * 2;
             }
         }
     }

 }