/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Ownable {

	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
		emit OwnershipTransferred(address(0), owner);
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
  
}

interface IMasterChef {
	function deposit(uint256 _pid, uint256 _amount) external;
	function withdraw(uint256 _pid, uint256 _amount) external;
}

interface IBEP20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
}

interface IPancakePair is IBEP20 {
	function allowance(address owner, address spender) external view returns (uint);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function mint(address to) external returns (uint liquidity);
	function burn(address to) external returns (uint amount0, uint amount1);
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

uint256 constant WBNB_BUSD_PID = 252;
address constant ADDR_DEAD = 0x000000000000000000000000000000000000dEaD;
address constant ADDR_WBNB_BUSD = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
address constant ADDR_WBNB_CAKE = 0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6;
address constant ADDR_WBNB_SS = 0x4c865169d7300CA00318e53fcBea7C171f805909;
address constant CHEF_ADDR = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
IPancakePair constant PAIR_WBNB_BUSD = IPancakePair(ADDR_WBNB_BUSD);
IPancakePair constant PAIR_WBNB_CAKE = IPancakePair(ADDR_WBNB_CAKE);
IPancakePair constant PAIR_WBNB_SS = IPancakePair(ADDR_WBNB_SS);
IMasterChef constant CHEF = IMasterChef(CHEF_ADDR);
IBEP20 constant CAKE = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
IBEP20 constant WBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
IBEP20 constant BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

contract Donations is Ownable {
  
	event CakeProcessed(uint amountCake, uint amountWBNB, uint amountSS);
	event Deposit(address from, uint amountWBNB, uint amountUSD, uint amountLP);
	event Withdraw(address to, uint amountWBNB, uint amountUSD, uint amountLP);

	struct Stats {
		uint deposited;
		uint withdrawn;
	}

	struct User {
		uint lp;
		Stats busd;
		Stats wbnb;
	}
	
	uint public totalLPStaked;

  	mapping(address=>User) public users;
  
  	constructor() {}

	function deposit(uint amountWBNB, uint amountBUSD, uint minLP) public {
		WBNB.transferFrom(msg.sender, ADDR_WBNB_BUSD, amountWBNB);
		BUSD.transferFrom(msg.sender, ADDR_WBNB_BUSD, amountBUSD);
		uint liquidity = PAIR_WBNB_BUSD.mint(address(this));
		require(liquidity >= minLP, "not enough LP tokens - reserves may have changed since last quote");
		PAIR_WBNB_BUSD.approve(CHEF_ADDR, liquidity);
		CHEF.deposit(WBNB_BUSD_PID, liquidity);
		User storage user = users[msg.sender];
		user.wbnb.deposited += amountWBNB;
		user.busd.deposited += amountBUSD;
		user.lp += liquidity;
		totalLPStaked += liquidity;
		_processCake();
		emit Deposit(msg.sender, amountWBNB, amountBUSD, liquidity);
	}

	function withdraw(uint amount) public {
		User storage user = users[msg.sender];
		require(user.lp >= amount, "insufficient lp");
		CHEF.withdraw(WBNB_BUSD_PID, amount);
		PAIR_WBNB_BUSD.transfer(ADDR_WBNB_BUSD, amount);
		(uint amountWBNB, uint amountBUSD) = PAIR_WBNB_BUSD.burn(msg.sender);
		user.wbnb.withdrawn += amountWBNB;
		user.busd.withdrawn += amountBUSD;
		user.lp -= amount;
		totalLPStaked -= amount;
		emit Withdraw(msg.sender, amountWBNB, amountBUSD, amount);
		_processCake();
	}

	// Anyone can opt to pay the gas to harvest pending Cake
	function harvest() public {
		CHEF.deposit(WBNB_BUSD_PID, 0);
		_processCake();
	}

	// Helps determine for a given amount of BUSD the parameters to send to deposit()
	function quote(uint amountBUSD) public view returns (uint amountWBNB, uint expectedLP) {
		(uint112 r0, uint112 r1,) = PAIR_WBNB_BUSD.getReserves();
		amountWBNB = r0 * amountBUSD / r1;
		uint supply = PAIR_WBNB_BUSD.totalSupply();
		uint a0 = amountWBNB * supply / r0;
		uint a1 = amountBUSD * supply / r1;
		expectedLP = a0 < a1 ? a0 : a1;
	}

	function _processCake() internal {
        uint amountCake = CAKE.balanceOf(address(this));
		if(amountCake == 0) return; 
    	bytes memory none;
    	uint amountIn;
    	uint amountOut;
    	uint112 r0;
    	uint112 r1;
        uint amountWBNB;
        uint amountSS;
    	// t0=CAKE, t1=WBNB
    	amountIn = amountCake;
    	(r0, r1, ) = PAIR_WBNB_CAKE.getReserves();
    	amountWBNB = amountOut = getAmountOut(amountIn, r0, r1);
    	CAKE.transfer(ADDR_WBNB_CAKE, amountIn);
    	PAIR_WBNB_CAKE.swap(0, amountOut, ADDR_WBNB_SS, none);
    
    	// t0=SS, t1=WBNB
    	amountIn = amountOut;
    	(r0, r1, ) = PAIR_WBNB_SS.getReserves();
    	amountSS = amountOut = getAmountOut(amountIn, r1, r0);
        PAIR_WBNB_SS.swap(amountOut, 0, ADDR_DEAD, none);
    
        emit CakeProcessed(amountCake, amountWBNB, amountSS);
	}

	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 998;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
  
}