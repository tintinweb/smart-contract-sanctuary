/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface IYearnVault{
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint256 amount) external;
    function pricePerShare() external view returns(uint256);
    function deposit(uint256 _amount) external;
    //function deposit(uint256 _amount, address recipient) external returns(uint256);
}

interface IWETH is StandardToken{
    function withdraw(uint256 amount) external returns(uint256);
    function deposit() external payable;
}

interface IStakeAndYield {
    function getRewardToken() external view returns(address);
    function totalSupply(uint256 stakeType) external view returns(uint256);
    function notifyRewardAmount(uint256 reward, uint256 stakeType) external;
}

interface IAutomaticMarketMaker {
    function buy(uint256 _tokenAmount) external payable;
    function sell(uint256 tokenAmount, uint256 _etherAmount) external;
    function calculatePurchaseReturn(uint256 etherAmount) external returns (uint256);
    function calculateSaleReturn(uint256 tokenAmount) external returns (uint256);
    function withdrawPayments(address payable payee) external;
}

interface ICurve{
    function get_virtual_price() external view returns(uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_amounts) external payable returns(uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns(uint256);
}


contract Controller is Ownable {
    using SafeMath for uint256;
    uint256 MAX_INT = type(uint256).max;
    
    IWETH public weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public DEUS = 0x3b62F3820e0B035cc4aD602dECe6d796BC325325;
    address public AETH = 0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf;

    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(
    	0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    IYearnVault public yweth = IYearnVault(0xa9fE4601811213c340e850ea305481afF02f5b28);
    IAutomaticMarketMaker public AMM = IAutomaticMarketMaker(0xD77700fC3C78d1Cb3aCb1a9eAC891ff59bC7946D);
    ICurve curve = ICurve(0xA96A65c051bF88B4095Ee1f2451C2A9d43F53Ae2);

    // strategy => vault
    mapping (address => address) public strategies;

    // vault => strategy
    mapping (address => address) public vaults;

    // vault => exitToken
    mapping (address => address) public exitTokens;

    // vault => multiplier
    mapping (address => uint256) public multipliers;

    mapping (address => uint256) public strategyBalances;

    address public operator;

    uint256 public minBuyFromAMM = 1 ether;



    modifier onlyOwnerOrOperator(){
        require(
            msg.sender == owner() || msg.sender == operator,
            "!owner"
        );
        _;
    }

    constructor() public{
   		StandardToken(weth).approve(address(uniswapRouter), MAX_INT);
		StandardToken(weth).approve(address(yweth), MAX_INT);
        StandardToken(DEUS).approve(address(uniswapRouter), MAX_INT);
    }

    modifier onlyStrategy(){
    	require(strategies[msg.sender] != address(0), "!strategy");
    	_;
    }

    modifier onlyVault(){
    	require(vaults[msg.sender] != address(0), "!vault");
    	_;
    }

    modifier onlyExitableVault(){
        require(vaults[msg.sender] != address(0) &&
            exitTokens[msg.sender] != address(0)
            , "!exitable vault");
        _;
    }

    receive() external payable {
	}

    function depositWETH() external payable{
        weth.deposit{value: msg.value}();
    }

    function depositAETH() external payable{
        curve.add_liquidity{value: msg.value}([msg.value, 0],
            0
        );
    }

	function addStrategy(address vault, address strategy, 
        address exitToken, uint256 multiplier,
        address yearnDepositToken,
        address yearnVault
        ) external onlyOwner{
		require(vault != address(0) && strategy!=address(0), "0x0");
		strategies[strategy] = vault;
		vaults[vault] = strategy;

        exitTokens[vault] = exitToken;
        multipliers[vault] = multiplier;

        if(yearnDepositToken != address(0)){
		  StandardToken(yearnDepositToken).approve(yearnVault, MAX_INT);
        }
	}

	function delStrategy(address vault, address strategy) external onlyOwner{
		require(vault != address(0) && strategy!=address(0), "0x0");
		strategies[strategy] = address(0);
		vaults[vault] = address(0);
	}

    function setOperator(address _addr) public onlyOwner{
        operator = _addr;
    }

    function setMultiplier(
        address vault, 
        uint256 multiplier
    ) external onlyOwnerOrOperator{
        require(vaults[vault] != address(0), "!vault");
        multipliers[vault] = multiplier;
    }

	function withdrawETH(uint256 amount) public onlyStrategy{
		msg.sender.transfer(amount);
	}

    function sendExitToken(
        address _user,
        uint256 _amount
    ) public onlyExitableVault{
        uint256 amount = _amount.mul(multipliers[msg.sender]).div(1 ether);
        require(amount > 0, "0 amount");
        StandardToken(exitTokens[msg.sender]).transfer(
            _user, amount
        );
    }

	function depositTokenForStrategy(
        uint256 amount, 
        address yearnVault
    ) public onlyStrategy{
        IYearnVault v = IYearnVault(yearnVault);
        uint256 balanceBefore = v.balanceOf(address(this));
        v.deposit(amount);
        uint256 balance = v.balanceOf(address(this)).sub(
            balanceBefore
        );
        strategyBalances[msg.sender] = strategyBalances[msg.sender].add(balance);
	}

    function withdrawForStrategy(
        uint256 sharesToWithdraw, 
        address yearnVault
        ) public onlyStrategy{

        IYearnVault v = IYearnVault(yearnVault);
        strategyBalances[msg.sender] = strategyBalances[msg.sender].sub(sharesToWithdraw);
        v.withdraw(sharesToWithdraw);
    }

	function buyForStrategy(
		uint256 amount,
        address rewardToken,
        address recipient
    ) public onlyStrategy{
    	address[] memory path;

        uint256[] memory amounts;
        uint256 tokenAmount = amount;
        if(amount < minBuyFromAMM){
            path = new address[](3);
        	path[0] = address(weth);
        	path[1] = DEUS;
        	path[2] = rewardToken;
        }else{
            path = new address[](2);
            path[0] = DEUS;
            path[1] = rewardToken;

            weth.withdraw(amount);
            tokenAmount = AMM.calculatePurchaseReturn(amount);
            AMM.buy{value: amount}(tokenAmount);
        }

        amounts = uniswapRouter.swapExactTokensForTokens(
            tokenAmount, 1, path, recipient, block.timestamp
        );

    	IStakeAndYield(recipient).notifyRewardAmount(
    		amounts[amounts.length-1], 
    		2 // yield
    	);
	}

    function setMinBuyFromAMM(uint256 _val) public onlyOwner{
        minBuyFromAMM = _val;
    }

    function setStrategyBalance(address stra, uint256 amount) public onlyOwner{
        strategyBalances[stra] = amount;
    }

	function emergencyWithdrawETH(uint256 amount, address addr) public onlyOwner{
		require(addr != address(0));
		payable(addr).transfer(amount);
	}

	function emergencyWithdrawERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }

    function getStrategy(address vault) public view returns(address){
        return vaults[vault];
    }

    function strategyBalance(address stra) public view returns(uint256){
        return strategyBalances[stra];
    }

}