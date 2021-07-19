/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// File: contracts\interfaces\IPoolToken.sol

pragma solidity >=0.5.0;

interface IPoolToken {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
}

// File: contracts\interfaces\IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts\interfaces\IReservesDistributor.sol

pragma solidity >=0.5.0;

interface IReservesDistributor {
	function imx() external view returns (address);
	function xImx() external view returns (address);
	function periodLength() external view returns (uint);
	function lastClaim() external view returns (uint);
	
    event Claim(uint previousBalance, uint timeElapsed, uint amount);
    event NewPeriodLength(uint oldPeriodLength, uint newPeriodLength);
    event Withdraw(uint previousBalance, uint amount);

	function claim() external returns (uint amount);
	function setPeriodLength(uint newPeriodLength) external;
	function withdraw(uint amount) external;
}

// File: contracts\interfaces\IStakingRouter.sol

pragma solidity >=0.5.0;

interface IStakingRouter {
	function imx() external view returns (address);
	function xImx() external view returns (address);
	function reservesDistributor() external view returns (address);
	
	function stakeNoClaim(uint amount) external returns (uint tokens);
	function stake(uint amount) external returns (uint tokens);
	function unstakeNoClaim(uint tokens) external returns (uint amount);
	function unstake(uint tokens) external returns (uint amount);
}

// File: contracts\StakingRouter.sol

pragma solidity =0.5.16;





contract StakingRouter is IStakingRouter {
	address public imx;
	address public xImx;
	address public reservesDistributor;

	constructor(address _imx, address _xImx, address _reservesDistributor) public {
		imx = _imx;
		xImx = _xImx;
		reservesDistributor = _reservesDistributor;
	}

	function stakeNoClaim(uint amount) public returns (uint tokens) {
		IERC20(imx).transferFrom(msg.sender, xImx, amount);
		tokens = IPoolToken(xImx).mint(msg.sender);
	}
	
	function stake(uint amount) external returns (uint tokens) {
		tokens = stakeNoClaim(amount);
		IReservesDistributor(reservesDistributor).claim();
	}
	
	function unstakeNoClaim(uint tokens) public returns (uint amount) {
		IERC20(xImx).transferFrom(msg.sender, xImx, tokens);
		amount = IPoolToken(xImx).redeem(msg.sender);
	}
	
	function unstake(uint tokens) external returns (uint amount) {
		IReservesDistributor(reservesDistributor).claim();
		amount = unstakeNoClaim(tokens);
	}
}