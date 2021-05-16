/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma experimental ABIEncoderV2;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDevWallet {
	
	function transferFunds(address recipient, uint wethAmount) external;
	function acceptPayment() external payable;
	
	function setStakeHolderSalary(address stakeHolder, uint newSalary) external;
	function payDay() external;
	function getMySalary() external returns (uint);

	function changeTieBreaker(address newTieBreaker) external;
	function changeAccountant(address newAccountant) external;
	function changeSuperAdmin(address newSuperAdmin) external;
	function getBuilder() external view returns (address);
	function getSuperAdmin() external view returns (address);
	function getTieBreaker() external view returns (address);

	function getCompetitionWalletAddress() external returns(address);
	function getIntemediaryWalletAddress() external returns(address);
	function getRepresentativeQuorumAddress() external returns(address);
	function changeCompetitionWalletAddress(address newAddress) external;
	function changeIntemediaryWalletAddress(address newAddress) external;
	function changeRepresentativeQuorumAddress(address newAddress) external;

	function getMyRole() external view returns (string [7] memory);

	function setAcceptableCurrencies(address [] memory acceptedCurrencies) external;
	function getAcceptableCurrencies() external returns (address [] memory);

	function setTieBreakerWinner(address winningContract) external;
	function getTieBreakerWinner() external view returns(address);
}

contract DevWallet is IDevWallet{
	

	address [] stakeholders;
	mapping (address => uint) stakeholderRelativeSalary;

	address [5] founders;
	mapping (address => uint) foundersInteraction;

	address superAdmin;
	address tieBreaker;
	address accountant;
	address builder;

	uint devAmount;
	uint salaryAmount;
	uint gasFeeSetAside;

	address [] acceptableCurrencies;

	address representativeQuorumAddress;
	address competitionWallet;
	address intemediaryWallet;

	address tieBreakerSignedForWinner;

	IUniswapV2Router02 uniswapRouter;


	constructor(address uniswapAddress){
		builder = msg.sender;
		superAdmin = msg.sender;
		uniswapRouter = IUniswapV2Router02(uniswapAddress);
	}
	function setFounders(address founder1, address founder2, address founder3, address founder4, address founder5 ) public onlyBuilder(){
		if (founders[0] == address(0)) {
			founders[0] = founder1;
			foundersInteraction[founder1] = block.timestamp;
		}
		if (founders[1] == address(0)){
			founders[1] = founder2;
			foundersInteraction[founder2] = block.timestamp;

		} 
		if (founders[2] == address(0)) {
			founders[2] = founder3;
			foundersInteraction[founder3] = block.timestamp;

		}
		if (founders[3] == address(0)){
			founders[3] = founder4;
			foundersInteraction[founder4] = block.timestamp;

		} 
		if (founders[4] == address(0)) {
			founders[4] = founder5;
			foundersInteraction[founder4] = block.timestamp;
		}

	}

	function updateFoundersTimestamp() private {
		if (foundersInteraction[msg.sender] != 0) foundersInteraction[msg.sender] = block.timestamp;
	}

	modifier onlyAccountant(){
		require(msg.sender == accountant, "Only the accountant can perform this action");
		updateFoundersTimestamp();
		_;
	}
	modifier onlySuperAdmin(){
		require(msg.sender == superAdmin, "Only the superAdmin can perform this action");
		updateFoundersTimestamp();
		_;
	}
	modifier onlyBuilder(){
		require(msg.sender == builder, "Only the builder can perform this action");
		updateFoundersTimestamp();
		_;
	}
	modifier onlyTieBreaker(){
		require(msg.sender == tieBreaker, "Only the tieBreaker can perform this action");
		updateFoundersTimestamp();
		_;
	}

	function transferFunds(address recipient, uint wethAmount) public onlyAccountant override{
		require(recipient != accountant, "The Accountant can only pay himself through a payday");
		payable(recipient).transfer(wethAmount);
	}
	function getMySalary() public override returns (uint) {
		return stakeholderRelativeSalary[msg.sender];
	}

	function changeRepresentativeQuorumAddress(address newAddress) public onlyBuilder override{
		representativeQuorumAddress = newAddress;
	}
	function changeIntemediaryWalletAddress(address newAddress) public onlyBuilder override{
		intemediaryWallet = newAddress;
	}
	function changeCompetitionWalletAddress(address newAddress) public override onlyBuilder {
		competitionWallet = newAddress;
	}
	function getRepresentativeQuorumAddress() public override returns(address) {
		return representativeQuorumAddress ;
	}
	function getIntemediaryWalletAddress() public override returns(address) {
		return intemediaryWallet;
	}
	function getCompetitionWalletAddress() public override returns(address) {
		return competitionWallet;
	}

	function changeAccountant(address newAccountant) public override onlySuperAdmin {
		accountant = newAccountant;
	}

	function changeSuperAdmin(address newSuperAdmin) public override onlySuperAdmin {
		superAdmin = newSuperAdmin;
		//TODO
	}
	function changeTieBreaker(address newTieBreaker) public override onlySuperAdmin {
		tieBreaker = newTieBreaker;
	}

	//TODO relook at this maths holy moly
	function payDay() public override onlyAccountant {
		//Add up the ratio totals x10d
		uint ratioTotal = 300;
		for (uint i=0; i < stakeholders.length; i++ ){
			ratioTotal += stakeholderRelativeSalary[stakeholders[i]] * 10 / 25;
		}
		for (uint i = 0; i < founders.length; i++){
			if (foundersInteraction[founders[i]] < block.timestamp - 15780000 ) ratioTotal += 25;
			else ratioTotal += 75;
		}
		uint particleSalary = salaryAmount / (ratioTotal);

		for (uint i=0; i < stakeholders.length; i++ ){
			payable(stakeholders[i]).send(particleSalary * stakeholderRelativeSalary[stakeholders[i]]);
		}

		payable(builder).send(particleSalary * 75 / 100);
		payable(superAdmin).send(particleSalary * 75 / 100);

		for (uint i = 0; i < founders.length; i++) {
			if (foundersInteraction[founders[i]] < block.timestamp - 15780000 ) payable(founders[i]).send(particleSalary * 75 / 100);
			else payable(founders[i]).transfer(particleSalary * 25 / 100);
		}

		payable(accountant).send(particleSalary * 100 / 100);
		
	}

	function setStakeHolderSalary(address stakeHolder, uint newSalary) public override onlyAccountant {
		require(newSalary != 25 && newSalary != 50 && newSalary != 75 && newSalary != 100, "Salary should be relativised, accepting 25,50,75,100");
		bool foundStakeholder =false;
		for (uint i = 0; i < stakeholders.length; i++){
			if (stakeHolder == stakeholders[i]) {
				foundStakeholder = true;
				break;
			}
		}
		require(foundStakeholder, "Doesn't seem to be a current Stakeholder");
		stakeholderRelativeSalary[stakeHolder] = newSalary;
	}

	function acceptPayment() public payable override{
		uint addedValue = msg.value;

		devAmount += addedValue * 70 / 100;
		salaryAmount += addedValue * 20 / 100;
		gasFeeSetAside += addedValue * 10 / 100;
	}

	function getBuilder() public view override returns (address) {
		return builder;
	}

	function getSuperAdmin() public view override returns (address) {
		return superAdmin;
	}

	function getTieBreaker() public view override returns (address) {
		return tieBreaker;
	}

	function getMyRole() public view  override returns (string [7] memory) {
		string [7] memory toReturn;

		if ( msg.sender == superAdmin) toReturn[0] = ("superadmin");
		if ( msg.sender == builder) toReturn[1] = ("builder");
		if ( msg.sender == tieBreaker) toReturn[2] = ("tiebreaker");
		if ( msg.sender == accountant) toReturn[3] = ("accountant");
		bool foundStakeholder =false;
		for (uint i = 0; i < stakeholders.length; i++){
			if (msg.sender == stakeholders[i]) {
				foundStakeholder = true;
				break;
			}
		}
		if ( foundStakeholder ) toReturn[4] = ("stakeholder");
		if ( foundersInteraction[msg.sender] != 0 ) toReturn[5] = ("founder");
		if ( toReturn.length == 0 ) toReturn[6] = ("normie");
		return toReturn;
	}

	function setAcceptableCurrencies(address [] memory acceptedCurrencies) public onlyBuilder override{
		acceptableCurrencies = acceptedCurrencies;
	}

	function getAcceptableCurrencies() public onlyBuilder override returns (address [] memory) {
		return acceptableCurrencies;
	}

	function setTieBreakerWinner(address winningContract) public override onlyTieBreaker {
		tieBreakerSignedForWinner = winningContract;
	}
	function getTieBreakerWinner() public view override returns(address) {
		return tieBreakerSignedForWinner;
	}
}