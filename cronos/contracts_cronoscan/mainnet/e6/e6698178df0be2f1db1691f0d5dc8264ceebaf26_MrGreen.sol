/**
 *Submitted for verification at cronoscan.com on 2022-05-27
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None
// Optimized with Runs: 1000000

pragma solidity 0.8.14;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexRouter {
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract MrGreen is IBEP20{

	string constant _name = "MrGreen";
    string constant _symbol = "MG";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);

	mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _addressWithTax;
    
    mapping (address => uint256) _presaleContributions;
    mapping (uint256 => address) _contributorByID;
    uint256 public totalContributors;
    uint256 public totalContributionAmount;

    uint256 public tax = 10;
    uint256 public taxDivisor = 1000;
    uint256 public taxDistributionRatio;

    address public constant CEO = 0x00000EfD750657468eDB69285C6CCe026B259536;
    address public taxDistributor = 0x8c3D412eD5B671a6F98B36bD4D0A11241fe00000;
    address public pair;
    address public router;
    address private WETH;
    bool public launched;

    modifier onlyOwner() {
		if(msg.sender != CEO) return;
		_;
	}

	constructor(address _router, address _WETH) {
        router = _router;
        WETH = _WETH;
        pair = IDexFactory(IDexRouter(router).factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	receive() external payable {
        if(!launched) contributeToPresale();
        else payable(CEO).transfer(address(this).balance);
    }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
			require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function takeTax(address sender, uint256 amount) internal returns (uint256){
        uint256 taxAmount = amount * tax / taxDivisor;
        if(taxDistributionRatio == 0) _basicTransfer(sender, CEO, taxAmount);
        else if(taxDistributionRatio == 100) _basicTransfer(sender, taxDistributor, taxAmount);
        else{
            _basicTransfer(sender, taxDistributor, taxAmount * taxDistributionRatio / 100);
            _basicTransfer(sender, CEO, taxAmount * (100 - taxDistributionRatio) / 100);            
        }
        return amount - taxAmount;
    } 

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if
        (
            tax == 0 || 
            _addressWithTax[sender] == false &&
            _addressWithTax[recipient] == false ||
            sender != CEO ||
            recipient != CEO
        )
        return _basicTransfer(sender, recipient, amount);

        amount = takeTax(sender, amount);
        return _basicTransfer(sender, recipient, amount);
    }

	function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setTaxDistributor(address taxAddress) external onlyOwner{
        taxDistributor = taxAddress;
    }

    function setTax(uint256 newTax, uint256 newTaxDivisor, uint256 newTaxDistributionRatio) external onlyOwner{
        tax = newTax;
        taxDivisor = newTaxDivisor;
        taxDistributionRatio = newTaxDistributionRatio;
        require(taxDistributionRatio <= 100, "Maximum taxDistributionRatio is 100");
        require(tax <= taxDivisor / 50, "Maximum tax is 2%");
    }

    function setAddressWithTax(address taxedAddress, bool status) external onlyOwner{
        _addressWithTax[taxedAddress] = status;
    }
    
    function contributeToPresale() public payable{
        if(_presaleContributions[msg.sender] == 0) _contributorByID[totalContributors] = msg.sender;
        _presaleContributions[msg.sender] += msg.value;
        totalContributionAmount += msg.value;
        totalContributors++;
    }

    function launch(uint256 tokensToContributors, uint256 tokensToLiquidity, address bridge) external onlyOwner{
        uint256 taxBefore = tax;
        tax = 0;
        uint256 tokensToSendToContributor;
        
        // sending tokens to contributors
        for(uint256 i = 0; i < totalContributors; i++){
            tokensToSendToContributor = tokensToContributors * _presaleContributions[_contributorByID[i]] / totalContributionAmount;
            _basicTransfer(address(this), _contributorByID[i], tokensToSendToContributor);
        }

        // adding liquidity
        IDexRouter(router).addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensToLiquidity,
            0,
            0,
            CEO,
            block.timestamp
        );
        
        // sending remaining tokens to bridge
        _basicTransfer(address(this), bridge, balanceOf(address(this)));

        // reset tax to normal
        tax = taxBefore;

        // close the presale
        launched = true;
    }
}