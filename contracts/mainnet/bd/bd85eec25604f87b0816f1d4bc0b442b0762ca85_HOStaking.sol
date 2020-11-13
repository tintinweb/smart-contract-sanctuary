pragma solidity 0.6.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}


interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function token0() external view returns (address);
  function token1() external view returns (address);
}

contract HOStaking {

    using SafeMath for uint;

    address private immutable hoToken;
    address private immutable v2Pair;

    uint8 private immutable hoDec;

    uint constant DAY =  60 * 60 * 24; 

    uint constant RATE = 90000;
    uint constant LEAST = 20;

    address _owner;

    constructor(address ho , address v2) public {
      _owner = msg.sender;
      hoToken = ho;
      hoDec = IERC20(ho).decimals();
      v2Pair = v2;
      require(IUniswapV2Pair(v2).token0() == ho || IUniswapV2Pair(v2).token1() == ho, "E/no ho");
    }

    struct Staking {
      uint amount;
      uint stakeTime;
      uint earnTime;   
    }

    mapping(address => Staking) V2Stakings;
    mapping(address => Staking) hoStakings;


    mapping(uint => uint) dayPrices;

    mapping(uint => bool) raiseOver10;

    
    function myV2Staking() external view returns (uint, uint, uint ) {
      return (V2Stakings[msg.sender].amount, V2Stakings[msg.sender].stakeTime, myV2Earn());
    }

    function stakingV2(uint amount) external {
      require(V2Stakings[msg.sender].amount == 0, "E/aleady staking");
      require(IERC20(v2Pair).transferFrom(msg.sender, address(this), amount), "E/transfer error");
      V2Stakings[msg.sender] = Staking(amount, now, now);
    }

    
    function wdV2(uint amount) external {
      uint stakingToal = V2Stakings[msg.sender].amount;
      uint stakingTime = V2Stakings[msg.sender].stakeTime;

      require(stakingToal >= amount, "E/not enough");
      require(now >= stakingTime + 2 * DAY, "E/locked");

      wdV2Earn() ;

      IERC20(v2Pair).transfer(msg.sender, amount);

      if(stakingToal - amount > 0) {
        V2Stakings[msg.sender] = Staking(stakingToal - amount, now, now);
      } else {
        delete V2Stakings[msg.sender];
      }
    }

    
    function myV2Earn() internal view returns (uint) {
      Staking memory s = V2Stakings[msg.sender];
      if(s.amount == 0) {
        return 0;
      }

      uint endDay = getDay(now);
      uint startDay = getDay(s.earnTime);
      if(endDay > startDay) {
        uint earnDays = endDay - startDay;

        uint earns = 0;
        if(earnDays > 0) {
          earns = s.amount.mul(earnDays).mul(RATE).div(10 ** (uint(18).sub(hoDec)));
        }
        return earns;
      } 
      return 0;
    }

    function wdV2Earn() public {
      uint earnsTotal = myV2Earn();

      IERC20(hoToken).transfer(msg.sender, earnsTotal);
      V2Stakings[msg.sender].earnTime = now;
    }

    // ----- for ho staking  ------
    function myHoStaking() external view returns (uint, uint, uint ) {
      return (hoStakings[msg.sender].amount, hoStakings[msg.sender].stakeTime, myHoEarn());
    }

    function stakingHo(uint amount) external {
      require(amount >= LEAST * 10 ** uint(hoDec), "E/not enough");
      require(hoStakings[msg.sender].amount == 0, "E/aleady staking");
      require(IERC20(hoToken).transferFrom(msg.sender, address(this), amount), "E/transfer error");
      
      hoStakings[msg.sender] = Staking(amount, now, now);
    }

    function wdHo(uint amount) external {
      uint stakingToal = hoStakings[msg.sender].amount;
      require(stakingToal >= amount, "E/not enough");

      wdHoEarn();
      
      if(stakingToal - amount >= LEAST * 10 ** uint(hoDec)) {
        IERC20(hoToken).transfer(msg.sender, amount);
        hoStakings[msg.sender] = Staking(stakingToal - amount, now, now);
      } else {
        
        IERC20(hoToken).transfer(msg.sender, stakingToal);
        delete hoStakings[msg.sender];
      }
    }

    
    function myHoEarn() internal view returns (uint) {
      Staking memory s = hoStakings[msg.sender];
      if(s.amount == 0) {
        return 0;
      }

      uint earnDays = getEarnDays(s);
      uint earns = 0;
      if(earnDays > 0) {
        earns = s.amount.div(100) * earnDays;
      }
      return earns;
    }

    

    function wdHoEarn() public {
      uint earnsTotal = myHoEarn();

      IERC20(hoToken).transfer(msg.sender, earnsTotal);

      hoStakings[msg.sender].earnTime = now;
    }

    
    function getEarnDays(Staking memory s) internal view returns (uint) {
    
      uint startDay = getDay(s.earnTime);
    
      uint endDay = getDay(now);

    
      uint earnDays = 0;
      while(endDay > startDay) {
        if(raiseOver10[startDay]) {
          earnDays += 1;
        }
        startDay += 1;
      }
      return earnDays;
    }

    // get 1 ho  =  x eth
    function fetchPrice() internal view returns (uint) {
      (uint reserve0, uint reserve1,) = IUniswapV2Pair(v2Pair).getReserves();
      require(reserve0 > 0 && reserve1 > 0, 'E/INSUFFICIENT_LIQUIDITY');
      uint oneHo = 10 ** uint(hoDec);  

      if(IUniswapV2Pair(v2Pair).token0() == hoToken) {
        return oneHo.mul(reserve1) / reserve0;
      } else {
        return oneHo.mul(reserve0) / reserve1;
      }
    }

    
    function getDay(uint ts) internal pure returns (uint) {   
      return ts / DAY;
    }

    
    function updatePrice() external {
    
      uint d = getDay(now);
    
      uint p = fetchPrice();

      dayPrices[d] = p;
      
      uint lastPrice = dayPrices[d-1];
      
      if(lastPrice > 0) {

        if(p > lastPrice.add(lastPrice/10)) {
          raiseOver10[d] = true;
        }
      }
    }


    modifier onlyOwner() {
      require(isOwner(), "Ownable: caller is not the owner");
      _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function owner() public view returns (address) {
      return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      _owner = newOwner;
    }

    function withdrawHo(uint amount) external onlyOwner {
      IERC20(hoToken).transfer(msg.sender, amount);
    }
}