/**
 *Submitted for verification at Etherscan.io on 2021-09-01
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

         uint256 amount;
     }

     struct Stat {
         uint256 initialVolume;
         uint256 bets;
         uint256 players;
     }

     uint32 startDate;

     uint256 cycle;
     mapping (uint256 => Stat) stats;
     mapping (uint256 => Round[]) queue;

     uint256 public PERIOD = 2 hours; ///

     constructor(address token, uint256 vol) public Ownable(msg.sender) {
         CCO = IERC20(token);
         queue[cycle].push(Round(uint32(now), 0)); ///
         startDate = uint32(now); /// start date
         stats[cycle].initialVolume = vol;
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
         require(isStarted());

         (uint256 volume, uint256 filled, uint256 available) = getParameters(cycle, queue[cycle].length-1);

         if (amount >= available) {
             CCO.transfer(from, amount.sub(available));
             amount = available;
         }

         users[from].batches.push(Batch(cycle, queue[cycle].length-1, amount));

         if (users[from].batches.length == 1) {
             stats[cycle].players++;
         } else if (
             users[from].batches[users[from].batches.length-2].cycle < cycle
             ) {
             stats[cycle].players++;
         }

         stats[cycle].bets++;
         queue[cycle][queue[cycle].length-1].amount = queue[cycle][queue[cycle].length-1].amount.add(amount);

         if (volume == filled + amount) {
             queue[cycle].push(Round(uint32(now), 0));
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

     function restart(uint32 start, uint256 vol) public onlyOwner {
         require(now - queue[cycle][queue[cycle].length-1].start > PERIOD, "Too early");
         cycle++;
         startDate = start;
         queue[cycle].push(Round(startDate, 0));
         if (queue[cycle-1].length > 2) {
             CCO.transfer(msg.sender, stats[cycle-1].initialVolume.mul(90).div(100));
         }
         stats[cycle].initialVolume = vol;
     }

     function getWithdrawn(address account) public view returns(uint256 withdrawable) {
         return users[account].withdrawn;
     }

     function getWithdrawable(address account) public view returns(uint256 withdrawable) {
         for (uint256 i; i < users[account].batches.length; i++) {
             uint256 _cycle = users[account].batches[i].cycle;
             if (users[account].batches[i].index + 2 < queue[_cycle].length) {
                 withdrawable = withdrawable.add(users[account].batches[i].amount.mul(2));
             } else if (_cycle < cycle) {
                 if (users[account].batches[i].index == queue[_cycle].length - 1) {
                     withdrawable = withdrawable.add(users[account].batches[i].amount);
                 } else {
                     (uint vol,,) = getParameters(_cycle, queue[_cycle].length - 2);
                     withdrawable = withdrawable.add(getInsurance(_cycle) * users[account].batches[i].amount / vol);
                 }
             }
          }
         withdrawable = withdrawable.sub(users[account].withdrawn);
     }

     function getParameters(uint256 _cycle, uint256 index) public view returns(uint256 volume, uint256 filled, uint256 available) {
         volume = stats[_cycle].initialVolume;

         for (uint256 i; i < index; i++) {
             volume = volume.mul(210).div(100);
         }

         filled = queue[_cycle][index].amount;
         available = volume.sub(filled);
     }

     function getCurrentGameInfo() public view returns(uint256 _cycle, uint256 round, uint256 bets, uint256 players, uint256 volume, uint256 filled, uint256 available) {
         _cycle = cycle;
         round = queue[cycle].length.sub(1);

         (volume, filled, available) = getParameters(_cycle, round);

         bets = stats[cycle].bets;
         players = stats[cycle].players;
     }

     function getGamesInfo(uint256 _cycle, uint256 from, uint256 to) public view returns(uint256 bets, uint256 players, uint256[] memory volume, uint256[] memory filled, uint256[] memory available) {
         if (queue[cycle].length < to) {
             to = queue[cycle].length-1;
         }

         require(to >= from);

         uint256 length = to - from;

         bets = stats[_cycle].bets;
         players = stats[_cycle].players;

         volume = new uint256[](length);
         filled = new uint256[](length);
         available = new uint256[](length);

         for (uint256 i; i < length; i++) {
             (volume[i], filled[i], available[i]) = getParameters(_cycle, from + i);
         }
     }

     function getTimer() public view returns(uint256 time) {
         return queue[cycle][queue[cycle].length.sub(1)].start + PERIOD;
     }

     function getBatch(address account, uint256 i) public view returns(uint256 index, uint256 amount) {
         return (users[account].batches[i].index, users[account].batches[i].amount);
     }

     function getAmountOfRounds() public view returns(uint256) {
         return queue[cycle].length;
     }

     function getInsurance(uint _cycle) public view returns(uint256 insurance) {
         if (queue[_cycle].length > 2) {
             uint256 vol = stats[_cycle].initialVolume;
             insurance = vol.div(10);

             if (queue[_cycle].length >= 3) {
                 for (uint256 i; i < queue[_cycle].length - 2; i++) {
                     vol = vol.mul(210).div(100);
                     insurance = insurance.add(vol.div(10));
                 }
             }
         } else if (queue[_cycle].length > 1) {
             insurance = stats[_cycle].initialVolume;
         }
     }

     function isStarted() public view returns(bool) {
         return (now >= startDate && now < getTimer());
     }

     function getUserStats(address account) public view returns(uint256 totalBets, uint256 totalProfit, uint256 totalWithdrawn, uint256 totalWithdrawable) {
         totalBets = users[account].batches.length;
         totalWithdrawn = getWithdrawn(account);
         totalWithdrawable = getWithdrawable(account);
         totalProfit = totalWithdrawn + totalWithdrawable;
     }

     function getUserGames(address account, uint256 from, uint256 to) public view returns(uint256[] memory _cycle, uint256[] memory start, uint256[] memory finish, uint256[] memory totalBets, uint256[] memory totalPlayers, uint256[] memory profit) {
         uint256 amountOfCycles = users[account].batches[users[account].batches.length-1].cycle - users[account].batches[0].cycle + 1;

         if (to > amountOfCycles) {
             to = amountOfCycles;
         }

         require(to >= from);

         uint256 length = to - from;

         _cycle = new uint256[](length);
         start = new uint256[](length);
         finish = new uint256[](length);
         totalBets = new uint256[](length);
         totalPlayers = new uint256[](length);
         profit = new uint256[](length);

         for (uint256 i = 0; i < length; i++) {
             _cycle[i] = users[account].batches[from + i].cycle;
             start[i] = queue[_cycle[i]][0].start;
             if (cycle > _cycle[i]) {
                 finish[i] = queue[_cycle[i + 1]][0].start;
             }
             totalBets[i] = stats[_cycle[i]].bets;
             totalPlayers[i] = stats[_cycle[i]].players;

             profit[i] = getWithdrawn(account) + getWithdrawable(account);///
         }
     }

 }