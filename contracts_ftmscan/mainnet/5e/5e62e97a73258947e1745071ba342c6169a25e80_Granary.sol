/**
 *Submitted for verification at FtmScan.com on 2022-01-15
*/

/*


FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU


KK   KK   CCCCC   CCCCC       GGGGG  U    U  RRRRR     U    U
KK KKK   CC      CC          G       U    U  RR   R    U    U
KKKK     CC      CC         G  GGG   U    U  RRRRR     U    U
KK KK    CC      CC      O  G    G   U    U  RR R      U    U
KK  KKK  CCCCCC  CCCCCC      GGGGG    UUUU   RR  RRR    UUUU



					*************************
					**                     **
					**  GRANARY & WORKERS  **
					**    ftm.guru/GRAIN   **
					**  kcc.guru/kompound  **
					**                     **
					*************************


Create a farm & vault for your own projects for free with ftm.guru

            			Contact us at:
			https://discord.com/invite/QpyfMarNrV
        			https://t.me/FTM1337

*/
/*
	- KOMPOUND PROTOCOL -
    https://kcc.guru/kompound
    - GRANARY & WORKERS -
    https://ftm.guru/GRAIN

    Yield Compounding Service
    Created by Guru Network

    Community Mediums:
        https://discord.com/invite/QpyfMarNrV
        https://medium.com/@ftm1337
        https://twitter.com/ftm1337
        https://twitter.com/kucino
        https://t.me/ftm1337
        https://t.me/kccguru
    Other Products:
        KUCINO CASINO - The First and Most used Casino of KCC
        fmc.guru - FantomMarketCap : On-Chain Data Aggregator
        ELITE - ftm.guru is an indie growth-hacker for Fantom
*/
/*

		FREQUENTLY ASKED QUESTIONS


	Q.1	WHY USE THIS VAULT?
	Ans	Most of the popular vaults' owners can switch "strategy" and steal (a.k.a. hard-rug) your valuable assets.
		Granaries or Kompound Protocol cannot change its own behaviour or strategy once its deployed on-chain.
		Our code uses unchangeable constants for tokens and external contracts. All fees & incentives are capped.
			Unlike the other (you-know-who) famous vaults.


	Q.2 WHAT IS ELITENESS?
	Ans	Simply holding ELITE (ftm.guru) token in your wallet ascribes you Eliteness.
		It is required to earn worker incentives from this Granary.
		Deposits incur nil fee if the user posseses adequate eliteness.
		 	ELITE has a fixed supply of 250.


*/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

//ftm.guru's Universal On-chain TVL Calculator
//Source: https://ftm.guru/rawdata/tvl
interface ITVL {
	//Using Version = 6
	function p_lpt_coin_usd(address lp) external view returns(uint256);
}

interface IMasterchef {
	// Info of each pool.
	struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accDMDPerShare;
        uint256 depositFeeBP;
	}
	// Info of each user.
	struct UserInfo {
		uint256 amount; // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt.
	}

	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function emergencyWithdraw(uint256 _pid) external;

	function userInfo(uint256, address) external view returns (UserInfo memory);

	function poolInfo(uint256) external view returns (PoolInfo memory);

	function totalAllocPoint() external view returns (uint256);

	function pendingDMD(uint256 _pid, address _user) external view returns (uint256);
}
interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */

	function totalSupply() external view returns (uint256);
	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */

	function balanceOf(address account) external view returns (uint256);
	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */

	function transfer(address recipient, uint256 amount) external returns (bool);
	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */

	function allowance(address owner, address spender) external view returns (uint256);
	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * IMPORTANT: Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */

	function approve(address spender, uint256 amount) external returns (bool);
	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);
	/**
	 * @dev Emitted when the allowance of a `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the new allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
	//Uniswap-style Pair (LPT)

	function getReserves() external view returns (uint112, uint112, uint32);
}
interface IRouter {

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);
}
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 * - Addition cannot overflow.
	 */

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 * - Subtraction cannot overflow.
	 */

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 * - Subtraction cannot overflow.
	 */

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}
	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 * - Multiplication cannot overflow.
	 */

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}
	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}
	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}
	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}
	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}




contract Granary
{
	using SafeMath for uint256;

	constructor (address _w, address _m, address _e, uint8 _p, address _R, address[] memory _rA, address[] memory _rB, string memory _id, address _v)
	{
		want=IERC20(_w);
		mc=IMasterchef(_m);
		earn=IERC20(_e);
		allnums[0]=_p;	//pid
		router = _R;
		routeA = _rA;
		routeB = _rB;
		id=_id;//GRAIN#ID
		utvl=_v;
		//Approvals
		//mc to take what it may want
		IERC20(address(want)).approve(address(mc),uint256(-1));
		//router to sell what we earn
		IERC20(address(earn)).approve(address(router),uint256(-1));
        //router to add routeA[routeA.length-1]
		IERC20(_rA[_rA.length-1]).approve(address(router),uint256(-1));
		//router to add routeB[routeB.length-1]
		IERC20(_rB[_rB.length-1]).approve(address(router),uint256(-1));
		dao = 0x167D87A906dA361A10061fe42bbe89451c2EE584;
		treasury = dao;
	}
	modifier DAO {require(msg.sender==dao,"Only E.L.I.T.E. D.A.O. Treasury can rescue treasures!");_;}
	struct Elites {
		address ELITE;
		uint256 ELITES;
	}
	Elites[] public Eliteness;

	function pushElite(address elite, uint256 elites) public DAO {
        Eliteness.push(Elites({ELITE:elite,ELITES:elites}));
    }

	function pullElite(uint256 n) public DAO {
        Eliteness[n]=Eliteness[Eliteness.length-1];Eliteness.pop();
    }
	//@xref takeFee=eliteness(msg.sender)?false:true;

	function eliteness(address u) public view returns(bool)
	{
		if(Eliteness.length==0){return(true);}//When nobody is an Elite, everyone is an Elite.
		for(uint i;i<Eliteness.length;i++){
			if(IERC20(Eliteness[i].ELITE).balanceOf(u)>=Eliteness[i].ELITES)
			{
				return(true);
			}
		}
		return(false);
	}

	function config(//address _w,
		uint256 _mw, uint256 _wi, uint256 _pf, address _t, uint256 _df) public DAO
	{
		allnums[4] = _mw;
		treasury = _t;
		//Max 10%, 1e6 = 100%
		require(_wi<1e5,"!wi: high");allnums[3] = _wi;
		require(_pf<1e5,"!pf: high");allnums[2] = _pf;
		require(_df<1e5,"!df: high");allnums[1] = _df;
	}
	uint8 RG = 0;
	modifier rg {
		require(RG == 0,"!RG");
		RG = 1;
		_;
		RG = 0;
	}

	function isContract(address account) internal view returns (bool)
	{
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly { codehash := extcodehash(account) }
		return (codehash != accountHash && codehash != 0x0);
	}
	//Using getter functions to circumvent "Stack too deep!" errors
	string public id;
	/*
	string public name;
	string public symbol;
	uint8  public decimals = 18;
	*/
	function name() public view returns(string memory){return(string(abi.encodePacked("ftm.guru/GRAIN/", id)));}
	function symbol() public view returns(string memory){return(string(abi.encodePacked("GRAIN#", id)));}
	function decimals() public pure returns(uint256){return(18);}

	uint256 public totalSupply;
	IERC20 public want;
	IERC20 public earn;
	address public router;
	address[] public routeA;
	address[] public routeB;
	IMasterchef public mc;
	bool public emergency = false;
	address public dao;
	address public treasury;
	address public utvl;
	/*
	uint8 public pid;
	uint256 public df = 1e3;//deposit fee = 0.1%, 1e6=100%
	uint256 public pf = 1e4;//performance fee to treasury, paid from profits = 1%, 1e6=100%
	uint256 public wi = 1e4;//worker incentive, paid from profits = 1%, 1e6=100%
	uint256 public mw;//Minimum earnings to reinvest
	uint64[2] ct;//Timestamp of first & latest Kompound
	*/
	//Using array to avoid "Stack too deep!" errors
	uint256[7] public allnums = [
		0,	//pid		0       constant
		1e3,//df		1       config, <= 10% (1e5), default 0.1%
		1e4,//pf		2       config, <= 10% (1e5), default 1%
		1e4,//wi		3       config, <= 10% (1e5), default 1%
		1,	//mw		4       config, default 1 (near zero)
		0,	//ct[0]		5       nonce, then constant
		0	//ct[1]		6       up only
	];
	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
	mapping (address => uint) public  balanceOf;
	mapping (address => mapping (address => uint)) public  allowance;

	function approve(address guy) public returns (bool) {
		return approve(guy, uint(-1));
	}

	function approve(address guy, uint wad) public returns (bool) {
		allowance[msg.sender][guy] = wad;
		emit Approval(msg.sender, guy, wad);
		return true;
	}

	function transfer(address dst, uint wad) public returns (bool) {
		return transferFrom(msg.sender, dst, wad);
	}

	function transferFrom(address src, address dst, uint wad) public returns (bool)
	{
		require(balanceOf[src] >= wad,"Insufficient Balance");
		if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
			require(allowance[src][msg.sender] >= wad);
			allowance[src][msg.sender] -= wad;
		}
		balanceOf[src] -= wad;
		balanceOf[dst] += wad;
		emit Transfer(src, dst, wad);
		return true;
	}
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Compounded(address indexed user, uint256 amount);

	function deposit(uint256 _amt) public rg
	{
		require(!emergency,"Its an emergency. Please don't deposit.");
		//require(isContract(msg.sender)==false,"Humans only");
		//require(msg.sender==tx.origin,"Humans only");
		//Some fancy math to take care of Fee-on-Transfer tokens
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(allnums[0],address(this)).amount;
		require(want.transferFrom(msg.sender,address(this),_amt), "Unable to onboard");
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty deposit");
		mc.deposit(allnums[0],D);
		//Some more fancy math to take care of Deposit Fee
		uint256 mcba = mc.userInfo(allnums[0],address(this)).amount;
		uint256 M = mcba.sub(mcbb,"Dirty stake");
		//require(M>mindep,"Deposit Too Low");
		uint256 _mint = 0;
		(totalSupply > 0)
			// k: SharePerDeposit should be constant before & after
			// Mint = SharesPerDeposit * IncreaseInDeposit
			// bal += (totalSupply / oldDeposits) * thisDeposit
			?	_mint = ( M.mul(totalSupply) ).div(mcbb)
			:	_mint = M;
		totalSupply += _mint;
		uint256 _fee;
		//allnums[1]===df, deposit fee
		if(allnums[1]>0){_fee = eliteness(msg.sender)? 0 : (_mint.mul(allnums[1])).div(1e6);}//gas savings
		if(_fee>0)//gas savings
		{
			balanceOf[treasury] += _fee;
			emit Transfer(address(0), treasury, _fee);
		}
		balanceOf[msg.sender] += _mint.sub(_fee);
		emit Transfer(address(0), msg.sender, _mint.sub(_fee));
		//hardWork()
		//allnums[4]===mw, min work : smallest harvest
		if(earn.balanceOf(address(this)) > allnums[4]) {work(address(this));}
	}

	function withdraw(uint256 _amt) public rg
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		require(balanceOf[msg.sender] >= _amt,"Insufficient Balance");
		//Burn _amt of Vault Tokens
		balanceOf[msg.sender] -= _amt;
		uint256 ts = totalSupply;
		totalSupply -= _amt;
		emit Transfer(msg.sender, address(0), _amt);
		uint256 vbb = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(allnums[0],address(this)).amount;
		// W  = DepositsPerShare * SharesBurnt
		uint256 W = ( _amt.mul(mcbb) ).div(ts);
		mc.withdraw(allnums[0],W);
		uint256 vba = want.balanceOf(address(this));
		uint256 D = vba.sub(vbb,"Dirty withdrawal");
	   	require(want.transfer(msg.sender,D), "Unable to deboard");
	   	//hardWork()
		if(earn.balanceOf(address(this)) > allnums[4]) {work(address(this));}
	}

	function doHardWork() public rg
	{
		require(eliteness(msg.sender),"Elites only!");
		salvage();
		require(earn.balanceOf(address(this)) > allnums[4], "Not much work to do!");
		work(msg.sender);
	}

	function salvage() public
	{
		//harvest()
		mc.withdraw(allnums[0],0);
	}

	function work(address ben) internal
	{
		require(!emergency,"Its an emergency. Use emergencyWithdraw() please.");
		//has inputs from salvage() if this work is done via doHardWork()
		IRouter R = IRouter(router);
		IERC20 A = IERC20(routeA[routeA.length-1]);
		IERC20 B = IERC20(routeB[routeB.length-1]);
		uint256 vbb = (earn.balanceOf(address(this))).div(2);
		R.swapExactTokensForTokensSupportingFeeOnTransferTokens(vbb,1,routeA,address(this),block.timestamp);
		R.swapExactTokensForTokensSupportingFeeOnTransferTokens(vbb,1,routeB,address(this),block.timestamp);
		R.addLiquidity(
			address(A),
			address(B),
			A.balanceOf(address(this)),
			B.balanceOf(address(this)),
			(A.balanceOf(address(this)).mul(90).div(100)),
			(B.balanceOf(address(this)).mul(90).div(100)),
			address(this),
			block.timestamp
		);
		uint256 D = want.balanceOf(address(this));
		uint256 mcbb = mc.userInfo(allnums[0],address(this)).amount;
		mc.deposit(allnums[0],D);
		uint256 mcba = mc.userInfo(allnums[0],address(this)).amount;
		uint256 M = mcba.sub(mcbb,"Dirty stake");
		//Performance Fee Mint, conserves TVL
		uint256 _mint = 0;
		//allnums[5] & allnums[6] are First & Latest Compound's timestamps. Used in info() for APY of AUM.
		if(allnums[5]==0){allnums[5]=uint64(block.timestamp);}//only on the first run
		allnums[6]=uint64(block.timestamp);
		(totalSupply > 0)
			// k: SharePerDeposit should be constant before & after
			// Mint = SharesPerDeposit * IncreaseInDeposit
			// bal += (totalSupply / oldDeposits) * thisDeposit
			?	_mint = ( M.mul(totalSupply) ).div(mcbb)
			:	_mint = M;
		//allnums[2] === pf, Performance Fee
		balanceOf[treasury] += (_mint.mul(allnums[2])).div(1e6);
		//Worker Incentive Mint, conserves TVL
		address worker = ben == address(this) ? treasury : ben;
		//allnums[3] === wi, Worker Incentive
		balanceOf[worker] += (_mint.mul(allnums[3])).div(1e6);
		totalSupply += ((_mint.mul(allnums[2])).div(1e6)).add( (_mint.mul(allnums[3])).div(1e6) );
		emit Transfer(address(0), treasury, (_mint.mul(allnums[2])).div(1e6));
		emit Transfer(address(0), worker, (_mint.mul(allnums[3])).div(1e6));
	}




	function declareEmergency() public DAO
	{
		require(!emergency,"Emergency already declared.");
		mc.emergencyWithdraw(allnums[0]);
		emergency=true;
	}

	function revokeEmergency() public DAO
	{
		require(emergency,"Emergency not declared.");
		uint256 D = want.balanceOf(address(this));
		mc.deposit(allnums[0],D);
		emergency=false;
	}

	function emergencyWithdraw(uint256 _amt) public rg
	{
		require(emergency,"Its not an emergency. Use withdraw() instead.");
		require(balanceOf[msg.sender] >= _amt,"Insufficient Balance");
		uint256 ts = totalSupply;
		//Burn _amt of Vault Tokens
		balanceOf[msg.sender] -= _amt;
		totalSupply -= _amt;
		emit Transfer(msg.sender, address(0), _amt);
		uint256 vbb = want.balanceOf(address(this));
		uint256 W = ( _amt.mul(vbb) ).div(ts);
	   	require(want.transfer(msg.sender,W), "Unable to deboard");
	}




	function rescue(address tokenAddress, uint256 tokens) public DAO returns (bool success)
	{
		//Generally, there are not supposed to be any tokens in this contract itself:
		//Upon Deposits, the assets go from User to the MasterChef of Strategy,
		//Upon Withdrawals, the assets go from MasterChef of Strategy to the User, and
		//Upon HardWork, the harvest is reconverted to want and sent to MasterChef of Strategy.
		//Never allow draining main "want" token from the Granary:
		//Main token can only be withdrawn using the EmergencyWithdraw
		require(tokenAddress != address(want), "Funds are Safu in emergency!");
		if(tokenAddress==address(0)) {(success, ) = dao.call{value:tokens}("");return success;}
		else if(tokenAddress!=address(0)) {return IERC20(tokenAddress).transfer(dao, tokens);}
		else return false;
	}

	//Read-Only Functions
	//Useful for performance analysis
	function info() public view returns (uint256, uint256, uint256, IMasterchef.UserInfo memory, IMasterchef.PoolInfo memory, uint256, uint256)
	{
		uint256 aum = mc.userInfo(allnums[0],address(this)).amount + IERC20(want).balanceOf(address(this));
		uint256 roi = aum*1e18/totalSupply;//ROI: 1e18 === 1x
		uint256 apy = ((roi-1e18)*(365*86400)*100)/(allnums[6]-allnums[5]);//APY: 1e18 === 1%
		return(
			aum,
			roi,
			apy,
			mc.userInfo(allnums[0],address(this)),
            mc.poolInfo(allnums[0]),
			mc.totalAllocPoint(),
			mc.pendingDMD(allnums[0],address(this))
		);
	}

	//TVL in USD, 1e18===$1.
	//Source code Derived from ftm.guru's Universal On-chain TVL Calculator: https://ftm.guru/rawdata/tvl
	function tvl() public view returns(uint256)
	{
		ITVL tc = ITVL(utvl);
		uint256 aum = mc.userInfo(allnums[0],address(this)).amount + IERC20(want).balanceOf(address(this));
		return ((tc.p_lpt_coin_usd(address(want))).mul(aum)).div(1e18);
	}

}