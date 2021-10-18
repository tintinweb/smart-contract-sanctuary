// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import './SafeMath.sol';
import './Address.sol';
import './Ownable.sol';
import './IUniswap.sol';

// 0x3A72fCf12c7eEa27C4B0ae289bAb050E9d2F334E TestNet
/**
 * dev: https://cainuriel.github.io/
 * 
 * 
 * 
	*	  /$$$$$$$$                   /$$$$$$   /$$                                  
	*	 |__  $$__/                  /$$__  $$ | $$                                  
	*		| $$  /$$$$$$   /$$$$$$ | $$  \__//$$$$$$    /$$$$$$   /$$$$$$   /$$$$$$$
	*		| $$ /$$__  $$ /$$__  $$|  $$$$$$|_  $$_/   |____  $$ /$$__  $$ /$$_____/
	*		| $$| $$  \ $$| $$  \ $$ \____  $$ | $$      /$$$$$$$| $$  \__/|  $$$$$$ 
	*		| $$| $$  | $$| $$  | $$ /$$  \ $$ | $$ /$$ /$$__  $$| $$       \____  $$
	*		| $$|  $$$$$$/| $$$$$$$/|  $$$$$$/ |  $$$$/|  $$$$$$$| $$       /$$$$$$$/
	*		|__/ \______/ | $$____/  \______/   \___/   \_______/|__/      |_______/ 
	*					  | $$                                                       
	*					  | $$                                                       
*					  |__/           
 *     
 *    
 *    
 *     
 *     
 *    
 * 
 * 
 * 
 * 
 **/

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TopStars is Context, IERC20, Ownable {
    
	using SafeMath for uint256;
	using Address for address;

	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _isExcludedFromFee;

	address public _projectAddress;
	address public _bandsAddress;
	address public _stakingAddress;

	uint256 private _tTotal = 100000000 * 10**18;

	string private _name = "TopStars";
	string private _symbol = "TOPS";
	uint8 private _decimals = 18;
	
	uint256 public _bandsFee = 1;
	uint256 private _previousBandsFee = _bandsFee;
	
	uint256 public _stakingFee = 1;
	uint256 private _previousStakingFee = _stakingFee;
	
	uint256 public _projectFee = 1; // marketing included
	uint256 private _previousProjectFee = _projectFee;
	

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	uint256 public _maxTxAmount = 1000000 * 10**18;

	constructor ( address initialProjectAddress, address initialBandsAddress, address initialStakingAddress ) {
	      require(
            initialProjectAddress != address(0),
            "Address should not be 0x00"
        );
           require(
            initialBandsAddress != address(0),
            "Address should not be 0x00"
        );
           require(
            initialStakingAddress != address(0),
            "Address should not be 0x00"
        );
        
        _tOwned[_msgSender()] = _tTotal;
        
		
		_projectAddress = initialProjectAddress;
		_bandsAddress = initialBandsAddress;
		_stakingAddress = initialStakingAddress;
		
	
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);		// binance PANCAKE V2
		//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);		// Ethereum mainnet, Ropsten, Rinkeby, Görli, and Kovan		 
	    	
	    // IUniswapV2Router02 _uniswapV2Router =
        //    IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //TestNet BSC Pancake

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;

		
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_bandsAddress] = true;
		_isExcludedFromFee[_projectAddress] = true;
		_isExcludedFromFee[_stakingAddress] = true;


		emit Transfer(address(0), _msgSender(), _tTotal);
	}

	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function decimals() public view returns (uint8) {return _decimals;}
	function totalSupply() public view override returns (uint256) {return _tTotal;}

	function balanceOf(address account) public view override returns (uint256) {
		return _tOwned[account];

	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

		function totalProject() public view returns (uint256) {
		return balanceOf(_projectAddress);
	}
	
		function totalStaking() public view returns (uint256) {
		return balanceOf(_stakingAddress);
	}
	
		function totalBands() public view returns (uint256) {
		return balanceOf(_bandsAddress);
	}


	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}
	
	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}
	

	function setBandsFeePercent(uint256 bandsFee) external onlyOwner {
		_bandsFee = bandsFee;
	}
	
		function setProjectFeePercent(uint256 projectFee) external onlyOwner {
		_projectFee = projectFee;
	}
	
	
		function setStakingFeePercent(uint256 stakingFee) external onlyOwner {
		_stakingFee = stakingFee;
	}
	
	
	function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
		_maxTxAmount = _tTotal.mul(maxTxPercent).div(
			10**2
		);
	}
	
	function setMaxTx(uint256 _maxTx) external onlyOwner {
		_maxTxAmount = _maxTx * 10**18;
	}

		function setBandsAddress(address newBandAddress) external onlyOwner 
	{
		_bandsAddress = newBandAddress;
		_isExcludedFromFee[_bandsAddress] = true;
	}
	
		function setProjectAddress(address newProjectAddress) external onlyOwner 
	{
		_projectAddress = newProjectAddress;
		_isExcludedFromFee[_projectAddress] = true;
	}
	
		function setStakingAddress(address newStakingAddress) external onlyOwner 
	{
		_stakingAddress = newStakingAddress;
		_isExcludedFromFee[_stakingAddress] = true;
	}

	function _getValues(uint256 tAmount) 
	private view returns (

	    uint256 tTransferAmount, 
	    uint256 tProject, 
	    uint256 tBands, 
	    uint256 tStaking
	    
	    ) 
	{
		( tTransferAmount, tProject, tBands, tStaking
		) = _getTValues(tAmount, tTransferAmount,  tProject, tBands, tStaking);
		
		
		return (
		tTransferAmount, 
		tProject,
		tBands,
		tStaking);
	}

	function _getTValues(
	uint256 tAmount, 
	uint256 tTransferAmount,
	uint256	tProject,
	uint256	tBands,
	uint256	tStaking
	) private view returns (
	    uint256, uint256, uint256, uint256) {
	    
	    tTransferAmount = tAmount;
		tProject = _getTaxProject(tAmount);
		tBands = calculateBandsFee(tAmount);
		tStaking = calculateStakingFee(tAmount);
		tTransferAmount = tTransferAmount.sub(tBands);
		tTransferAmount = tTransferAmount.sub(tStaking);
		tTransferAmount = tTransferAmount.sub(tProject);
		
		return (tTransferAmount, tProject, tStaking, tBands);
	}
	
		function calculateBandsFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_bandsFee).div(
			10**2
		);
	}
	
		function calculateStakingFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_stakingFee).div(
			10**2
		);
	}

    function _getTaxProject(uint tAmount) private view returns (uint256) {

    uint256 projectFee = tAmount.mul(_projectFee).div(10 ** 2);

    return (projectFee);
    
  }
	
	function removeAllFee() private {
		if(_bandsFee == 0 && _projectFee == 0 && _stakingFee == 0) return;		
		_previousBandsFee = _bandsFee;
		_previousProjectFee = _projectFee;
		_previousStakingFee = _stakingFee;
		_bandsFee = 0;
		_projectFee = 0;
		_stakingFee = 0;
	}
	
	function restoreAllFee() private {
		_bandsFee = _previousBandsFee;
		_projectFee = _previousProjectFee;
		_stakingFee = _previousStakingFee;
	}
	
	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if(from != owner() && to != owner())
			require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		bool takeFee = true;
		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		_tokenTransfer(from,to,amount,takeFee);
	}
	function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private 
	{
		if(!takeFee)
			removeAllFee();	
		
		_transferStandard(sender, recipient, amount);
		
		if(!takeFee)
			restoreAllFee();
	}
	
		function _transferProject(address sender, uint256 tProject) private {
			_tOwned[_projectAddress] = _tOwned[_projectAddress].add(tProject);
		
		emit Transfer(sender, _projectAddress, tProject);
	}
	
		function _transferBands(address sender, uint256 tBands) private {
			_tOwned[_bandsAddress] = _tOwned[_bandsAddress].add(tBands);
		
		emit Transfer(sender, _bandsAddress, tBands);
	}
	
		function _transferStaking(address sender, uint256 tStaking) private {
			_tOwned[_stakingAddress] = _tOwned[_stakingAddress].add(tStaking);
		
		emit Transfer(sender, _stakingAddress, tStaking);
	}

	
	function _transferStandard(address sender, address recipient, uint256 tAmount) 
	private 
	{
		(
			uint256 tTransferAmount,
			uint256 tProject,
			uint256 tBands,
			uint256 tStaking) = _getValues(tAmount);
			
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        
		_transferBands(sender, tBands);
        _transferProject(sender, tProject);
        _transferStaking(sender, tStaking);
		emit Transfer(sender, recipient, tTransferAmount);
	}


}