pragma solidity ^0.4.24;

// SafeMath library
library SafeMath {
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		assert(c >= _a);
		return c;
	}

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_a >= _b);
		return _a - _b;
	}

	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
     return 0;
    }
		uint256 c = _a * _b;
		assert(c / _a == _b);
		return c;
	}

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return _a / _b;
	}
}

// Contract must have an owner
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "onlyOwner wrong");
    _;
  }

  function setOwner(address _owner) onlyOwner public {
    owner = _owner;
  }
}

interface WTAGameBook {
  function getPlayerIdByAddress(address _addr) external view returns (uint256);
  function getPlayerAddressById(uint256 _id) external view returns (address);
  function getPlayerRefById(uint256 _id) external view returns (uint256);
  function getGameIdByAddress(address _addr) external view returns (uint256);
  function getGameAddressById(uint256 _id) external view returns (address);
  function isAdmin(address _addr) external view returns (bool);
}

interface WTAGameRun {
  function getCurrentRoundStartTime() external view returns (uint256);
  function getCurrentRoundEndTime() external view returns (uint256);
  function getCurrentRoundWinner() external view returns (uint256);
}

interface ERC20Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _addr) external view returns (uint256);
  function decimals() external view returns (uint8);
}

// The WTA Token Pool that stores and handles token information
contract WTATokenPool is Ownable {
  using SafeMath for uint256;

  uint256 constant private DAY_IN_SECONDS = 86400;
  string public name = "WTATokenPool V0.5";
  string public version = "0.5";

  // various token related stuff
  struct TokenInfo {
    ERC20Token token;
    address addr;
    uint8 decimals;
    address payaddr;
    uint256 bought;
    uint256 safed;
    uint256 potted;
    uint256 price;
    uint256 buypercent;
    uint256 potpercent;
    uint256 lockperiod;
    uint256 tid;
    bool active;
  }

  // Player&#39;s time-locked safe to store tokens
  struct PlayerSafe {
    mapping (uint256 => uint256) lockValue;
    mapping (uint256 => uint256) lockTime;
    uint256 locks;
    uint256 withdraws;
    uint256 withdrawn;
  }

  uint256 public tokenNum = 0;
  mapping (uint256 => TokenInfo) public tokenPool;
  mapping (address => bool) public tokenInPool;

  mapping (uint256 => mapping(uint256 => PlayerSafe)) public playerSafes;
  WTAGameBook public gamebook;

  event TokenBought(uint256 _tid, uint256 _pid, uint256 _amount);
  event TokenLocked(uint256 _tid, uint256 _pid, uint256 _amount, uint256 _locktime);
  event TokenFundPaid(uint256 _tid, address indexed _paddr, uint256 _value);
  event TokenPotFunded(uint256 _tid, uint256 _amount);
  event TokenPotWon(uint256 _tid, uint256 _pid, uint256 _amount);
  event TokenWithdrawn(uint256 _tid, uint256 _pid, uint256 _amount);

  event InactiveTokenEmptied(uint256 _tid, address indexed _addr, uint256 _amount);
  event WrongTokenEmptied(address indexed _token, address indexed _addr, uint256 _amount);
  event WrongEtherEmptied(address indexed _addr, uint256 _amount);

  // initial tokens
  // IMPORTANT: price needs to be in Wei per 1 unit of token
  // IMPORTANT: percent needs to be in %
  // _tokenAddress: list of token addresses need to be added to the pool at contract creation
  // _payAddress: list of token owner addresses which receives the payments
  // _price: list of token prices
  // _buypercent: list of how much token needs to be allocated to players relative to the listed buying price, in percentage form, for example 200 means 200%
  // _potpercent: list of how much token needs to be allocated to the pot relative to the listed buying price, in percentage form, for example 40 means 40%
  // _lockperiod: list of timelock periods for tokens allocated to the players before they can withdraw them, in seconds
  // _gamebook: the address of the GameBook contract
  constructor(address[] _tokenAddress, address[] _payAddress, uint256[] _price, uint256[] _buypercent, uint256[] _potpercent, uint256[] _lockperiod, address _gamebook) public {
    require((_tokenAddress.length == _payAddress.length) && (_payAddress.length == _price.length) && (_price.length == _buypercent.length) && (_buypercent.length == _potpercent.length), "TokenPool constructor wrong");
    tokenNum = _tokenAddress.length;
    for (uint256 i = 0; i < tokenNum; i++) {
      tokenPool[i].token = ERC20Token(_tokenAddress[i]);
      tokenPool[i].addr = _tokenAddress[i];
      tokenPool[i].decimals = tokenPool[i].token.decimals();
      tokenPool[i].payaddr = _payAddress[i];
      tokenPool[i].bought = 0;
      tokenPool[i].safed = 0;
      tokenPool[i].potted = 0;
      tokenPool[i].price = _price[i];
      tokenPool[i].buypercent = _buypercent[i];
      tokenPool[i].potpercent = _potpercent[i];
      tokenPool[i].lockperiod = _lockperiod[i];
      tokenPool[i].tid = i;
      tokenPool[i].active = true;
      tokenInPool[_tokenAddress[i]] = true;
    }
    gamebook = WTAGameBook(_gamebook);
  }

  modifier isAdmin() {
    require(gamebook.isAdmin(msg.sender), "isAdmin wrong");
    _;
  }

  modifier isGame() {
    require(gamebook.getGameIdByAddress(msg.sender) > 0, "isGame wrong");
    _;
  }

  modifier isPaid() {
    // paymnent must be greater than 1GWei and less than 100k ETH
    require((msg.value > 1000000000) && (msg.value < 100000000000000000000000), "isPaid wrong");
    _;
  }

  // admins may set a token to be active or inactive in the games
  function setTokenActive(uint256 _tid, bool _active) isAdmin public {
    require(_tid < tokenNum, "setTokenActive wrong");
    tokenPool[_tid].active = _active;
  }

  // IMPORTANT: price needs to be in Wei per 1 unit of token
  // admins may add new tokens into the pool
  function addToken(address _tokenAddress, address _payAddress, uint256 _price, uint256 _buypercent, uint256 _potpercent, uint256 _lockperiod) isAdmin public {
    tokenPool[tokenNum].token = ERC20Token(_tokenAddress);
    tokenPool[tokenNum].addr = _tokenAddress;
    tokenPool[tokenNum].decimals = tokenPool[tokenNum].token.decimals();
    tokenPool[tokenNum].payaddr = _payAddress;
    tokenPool[tokenNum].bought = 0;
    tokenPool[tokenNum].safed = 0;
    tokenPool[tokenNum].potted = 0;
    tokenPool[tokenNum].price = _price;
    tokenPool[tokenNum].buypercent = _buypercent;
    tokenPool[tokenNum].potpercent = _potpercent;
    tokenPool[tokenNum].lockperiod = _lockperiod;
    tokenPool[tokenNum].tid = tokenNum;
    tokenPool[tokenNum].active = true;
    tokenInPool[_tokenAddress] = true;
    tokenNum++;
  }

  function tokenBalance(uint256 _tid) public view returns (uint256 _balance) {
    return tokenPool[_tid].token.balanceOf(address(this)).sub(tokenPool[_tid].safed).sub(tokenPool[_tid].potted);
  }

  function tokenBuyable(uint256 _tid, uint256 _eth) public view returns (bool _buyable) {
    if (!tokenPool[_tid].active) return false;
    uint256 buyAmount = (_eth).mul(tokenPool[_tid].buypercent).div(100).mul(uint256(10)**tokenPool[_tid].decimals).div(tokenPool[_tid].price);
    uint256 potAmount = (_eth).mul(tokenPool[_tid].potpercent).div(100).mul(uint256(10)**tokenPool[_tid].decimals).div(tokenPool[_tid].price);
    return (tokenPool[_tid].token.balanceOf(address(this)).sub(tokenPool[_tid].safed).sub(tokenPool[_tid].potted) > (buyAmount + potAmount));
  }

  // Handles the buying of Tokens
  function buyToken(uint256 _tid, uint256 _pid) isGame isPaid public payable {
    require(gamebook.getPlayerAddressById(_pid) != address(0x0), "buyToken need valid player");
    require(_tid < tokenNum, "buyToken need valid token");
    require(tokenPool[_tid].active, "buyToken need active token");

    uint256 buyAmount = (msg.value).mul(tokenPool[_tid].buypercent).div(100).mul(uint256(10)**tokenPool[_tid].decimals).div(tokenPool[_tid].price);
    uint256 potAmount = (msg.value).mul(tokenPool[_tid].potpercent).div(100).mul(uint256(10)**tokenPool[_tid].decimals).div(tokenPool[_tid].price);
    require(tokenPool[_tid].token.balanceOf(address(this)).sub(tokenPool[_tid].safed).sub(tokenPool[_tid].potted) > (buyAmount + potAmount), "buyToken need more balance");

    tokenPool[_tid].bought = tokenPool[_tid].bought.add(buyAmount);
    tokenPool[_tid].safed = tokenPool[_tid].safed.add(buyAmount);
    tokenPool[_tid].potted = tokenPool[_tid].potted.add(potAmount);

    emit TokenBought(_tid, _pid, buyAmount);
    emit TokenPotFunded(_tid, potAmount);

    uint256 lockStartTime = WTAGameRun(msg.sender).getCurrentRoundStartTime();
    tokenSafeLock(_tid, _pid, buyAmount, lockStartTime);

    tokenPool[_tid].payaddr.transfer(msg.value);

    emit TokenFundPaid(_tid, tokenPool[_tid].payaddr, msg.value);
  }

  // handling the Pot Winning
  function winPot(uint256[] _tids) isGame public {
    require(now > WTAGameRun(msg.sender).getCurrentRoundEndTime(), "winPot need round end");
    uint256 lockStartTime = WTAGameRun(msg.sender).getCurrentRoundStartTime();
    uint256 winnerId = WTAGameRun(msg.sender).getCurrentRoundWinner();
    require(gamebook.getPlayerAddressById(winnerId) != address(0x0), "winPot need valid player");
    for (uint256 i = 0; i< _tids.length; i++) {
      uint256 tid = _tids[i];
      if (tokenPool[tid].active) {
        uint256 potAmount = tokenPool[tid].potted;
        tokenPool[tid].potted = 0;
        tokenPool[tid].safed = tokenPool[tid].safed.add(potAmount);

        tokenSafeLock(tid, winnerId, potAmount, lockStartTime);

        emit TokenPotWon(tid, winnerId, potAmount);
      }
    }
  }

  // lock the Tokens allocated to players with a timelock
  function tokenSafeLock(uint256 _tid, uint256 _pid, uint256 _amount, uint256 _start) private {
    uint256 lockTime = _start + tokenPool[_tid].lockperiod;
    uint256 lockNum = playerSafes[_pid][_tid].locks;
    uint256 withdrawNum = playerSafes[_pid][_tid].withdraws;

    if (lockNum > 0 && lockNum > withdrawNum) {
      if (playerSafes[_pid][_tid].lockTime[lockNum-1] == lockTime) {
        playerSafes[_pid][_tid].lockValue[lockNum-1] = playerSafes[_pid][_tid].lockValue[lockNum-1].add(_amount);
      } else {
        playerSafes[_pid][_tid].lockTime[lockNum] = lockTime;
        playerSafes[_pid][_tid].lockValue[lockNum] = _amount;
        playerSafes[_pid][_tid].locks++;
      }
    } else {
      playerSafes[_pid][_tid].lockTime[lockNum] = lockTime;
      playerSafes[_pid][_tid].lockValue[lockNum] = _amount;
      playerSafes[_pid][_tid].locks++;
    }

    emit TokenLocked(_tid, _pid, _amount, lockTime);
  }

  // show a player&#39;s allocated tokens
  function showPlayerSafeByAddress(address _addr, uint256 _tid) public view returns (uint256 _locked, uint256 _unlocked, uint256 _withdrawable) {
    uint256 pid = gamebook.getPlayerIdByAddress(_addr);
    require(pid > 0, "showPlayerSafeByAddress wrong");
    return showPlayerSafeById(pid, _tid);
  }

  function showPlayerSafeById(uint256 _pid, uint256 _tid) public view returns (uint256 _locked, uint256 _unlocked, uint256 _withdrawable) {
    require(gamebook.getPlayerAddressById(_pid) != address(0x0), "showPlayerSafeById need valid player");
    require(_tid < tokenNum, "showPlayerSafeById need valid token");
    uint256 locked = 0;
    uint256 unlocked = 0;
    uint256 withdrawable = 0;
    uint256 withdraws = playerSafes[_pid][_tid].withdraws;
    uint256 locks = playerSafes[_pid][_tid].locks;
    uint256 count = 0;
    for (uint256 i = withdraws; i < locks; i++) {
      if (playerSafes[_pid][_tid].lockTime[i] < now) {
        unlocked = unlocked.add(playerSafes[_pid][_tid].lockValue[i]);
        if (count < 50) withdrawable = withdrawable.add(playerSafes[_pid][_tid].lockValue[i]);
      } else {
        locked = locked.add(playerSafes[_pid][_tid].lockValue[i]);
      }
      count++;
    }
    return (locked, unlocked, withdrawable);
  }

  // player may withdraw tokens after the timelock period
  function withdraw(uint256 _tid) public {
    require(_tid < tokenNum, "withdraw need valid token");
    uint256 pid = gamebook.getPlayerIdByAddress(msg.sender);
    require(pid > 0, "withdraw need valid player");
    uint256 withdrawable = 0;
    uint256 i = playerSafes[pid][_tid].withdraws;
    uint256 count = 0;
    uint256 locks = playerSafes[pid][_tid].locks;
    for (; (i < locks) && (count < 50); i++) {
      if (playerSafes[pid][_tid].lockTime[i] < now) {
        withdrawable = withdrawable.add(playerSafes[pid][_tid].lockValue[i]);
        playerSafes[pid][_tid].withdraws = i + 1;
      } else {
        break;
      }
      count++;
    }

    assert((tokenPool[_tid].token.balanceOf(address(this)) >= withdrawable) && (tokenPool[_tid].safed >= withdrawable));
    tokenPool[_tid].safed = tokenPool[_tid].safed.sub(withdrawable);
    playerSafes[pid][_tid].withdrawn = playerSafes[pid][_tid].withdrawn.add(withdrawable);
    require(tokenPool[_tid].token.transfer(msg.sender, withdrawable), "withdraw transfer wrong");

    emit TokenWithdrawn(_tid, pid, withdrawable);
  }

  // Safety measures
  function () public payable {
    revert();
  }

  function emptyInactiveToken(uint256 _tid) isAdmin public {
    require(_tid < tokenNum, "emptyInactiveToken need valid token");
    require(tokenPool[_tid].active == false, "emptyInactiveToken need token inactive");
    uint256 amount = tokenPool[_tid].token.balanceOf(address(this)).sub(tokenPool[_tid].safed);
    tokenPool[_tid].potted = 0;
    require(tokenPool[_tid].token.transfer(msg.sender, amount), "emptyInactiveToken transfer wrong");

    emit InactiveTokenEmptied(_tid, msg.sender, amount);
  }

  function emptyWrongToken(address _addr) isAdmin public {
    require(tokenInPool[_addr] == false, "emptyWrongToken need wrong token");
    ERC20Token wrongToken = ERC20Token(_addr);
    uint256 amount = wrongToken.balanceOf(address(this));
    require(amount > 0, "emptyWrongToken need more balance");
    require(wrongToken.transfer(msg.sender, amount), "emptyWrongToken transfer wrong");

    emit WrongTokenEmptied(_addr, msg.sender, amount);
  }

  function emptyWrongEther() isAdmin public {
    // require all tokens to be inactive before emptying ether
    for (uint256 i=0; i < tokenNum; i++) {
      require(tokenPool[i].active == false, "emptyWrongEther need all tokens inactive");
    }
    uint256 amount = address(this).balance;
    require(amount > 0, "emptyWrongEther need more balance");
    msg.sender.transfer(amount);

    emit WrongEtherEmptied(msg.sender, amount);
  }

}