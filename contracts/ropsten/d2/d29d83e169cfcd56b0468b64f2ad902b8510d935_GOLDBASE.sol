/* 
   SPDX-License-Identifier: MIT
   Copyright 2021
*/

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Rebaser.sol";
import "./Address.sol";

contract GOLDBASE is Ownable, Rebasable
{
    using SafeMath for uint256;
	using Address for address;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    event Rebase(uint256 indexed epoch, uint256 scalingFactor);

    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);

    string public name     = "GOLDBASE";
    string public symbol   = "GOLDBASE";
    uint8  public decimals = 9;

    uint256 public constant internalDecimals = 10**9;
    uint256 public constant BASE = 10**9;
    uint256 public GOLDBASEScalingFactor  = BASE;

	mapping (address => uint256) private _gOwned;
	mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) internal _allowedFragments;
	
	mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;

    uint256 initSupply = 10**9 * 10**9;
    uint256 _totalSupply = 10**9 * 10**9;
	uint256 private _tFeeTotal;
	uint256 private constant MAX = ~uint256(0);
    uint256 private _gTotal = (MAX - (MAX % _totalSupply));
	uint16 public FYFee = 100;
	uint256 public _maxTxAmount = 10000 * 10**9;
	
	event MaxTxAmountUpdated(uint256 maxTxAmount);
   
    constructor()
    public
    Ownable()
    Rebasable()
    {
		 _gOwned[_msgSender()] = reflectionFromToken(_totalSupply);
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    function _isWhitelisted(address _from, address _to) internal view returns (bool)
    {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner
    {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }
	
	function setFYFee(uint16 fee) external onlyOwner
    {
        FYFee = fee;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner
    {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function maxScalingFactor() external view returns (uint256)
    {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint256)
    {
        return uint256(-1) / initSupply;
    }

   function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		_transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowedFragments[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

	function balanceOf(address account) public view returns (uint256) {
	  
        if (_isExcluded[account]) return _tOwned[account].mul(GOLDBASEScalingFactor).div(internalDecimals);
        uint256 tOwned = tokenFromReflection(_gOwned[account]);
		return _scaling(tOwned);
	}

    function balanceOfUnderlying(address account) external view returns (uint256)
    {
        return tokenFromReflection(_gOwned[account]);
    }

    
    function allowance(address owner_, address spender) external view returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue)
        {
            _allowedFragments[msg.sender][spender] = 0;
        }
        else
        {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
	
	function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "GOLDBASE: approve from the zero address");
        require(spender != address(0), "GOLDBASE: approve to the zero address");

        _allowedFragments[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function isExcluded(address account) public view returns (bool) 
	{
        return _isExcluded[account];
    }
	
	function totalFees() public view returns (uint256) 
	{
        return _tFeeTotal;
    }
	
	function reflect(uint256 tAmount) public 
	{
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        uint256 currentRate = _getRate();
        uint256 TAmount = tAmount.mul(internalDecimals).div(GOLDBASEScalingFactor);
		uint256 gAmount = TAmount.mul(currentRate);
        _gOwned[sender] = _gOwned[sender].sub(gAmount);
        _gTotal = _gTotal.sub(gAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
	
	function reflectionFromToken(uint256 tAmount) public view returns(uint256) 
	{
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        uint256 TAmount = tAmount.mul(internalDecimals).div(GOLDBASEScalingFactor);
		uint256 gAmount = TAmount.mul(currentRate);
		return gAmount;
    
    }
	
	function tokenFromReflection(uint256 gAmount) public view returns(uint256) 
	{
        require(gAmount <= _gTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return gAmount.div(currentRate);
    }
	
	function excludeAccount(address account) external onlyOwner() 
	{
        require(!_isExcluded[account], "Account is already excluded");
        if(_gOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_gOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
	
	function includeAccount(address account) external onlyOwner() 
	{
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _gOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
	
	function _transfer(address sender, address recipient, uint256 amount) private 
	{
        
		require(sender != address(0), "GOLDBASE: cannot transfer from the zero address");
        require(recipient != address(0), "GOLDBASE: cannot transfer to the zero address");
        require(amount > 0, "GOLDBASE: Transfer amount must be greater than zero");
		
		if(sender != owner() && recipient != owner()) {
            require(amount <= _maxTxAmount, "GOLDBASE: Transfer amount exceeds the maxTxAmount.");
        }
		
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }
	
	receive() external payable {}
	
	function _transferStandard(address sender, address recipient, uint256 tAmount) private 
	{
	    uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(GOLDBASEScalingFactor);
		uint256 gAmount = TAmount.mul(currentRate);
		_gOwned[sender] = _gOwned[sender].sub(gAmount);
		
		 if(!_isWhitelisted(sender, recipient))
		    {
			 (uint256 gTransferAmount, uint256 gFYFee) = _getGValues(gAmount);
		     (uint256 tTransferAmount, uint256 tFYFee) = _getTValues(TAmount); 
			 _goldFee(gFYFee, tFYFee);  
             _gOwned[recipient] = _gOwned[recipient].add(gTransferAmount);
             emit Transfer(sender, recipient, _scaling(tTransferAmount));
            }
         else
            {
              _gOwned[recipient] = _gOwned[recipient].add(gAmount);
              emit Transfer(sender, recipient, tAmount);
             }
     }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private 
	{
		uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(GOLDBASEScalingFactor);
		uint256 gAmount = TAmount.mul(currentRate);
		_gOwned[sender] = _gOwned[sender].sub(gAmount);

          if(!_isWhitelisted(sender, recipient))
            {
			 (uint256 gTransferAmount, uint256 gFYFee) = _getGValues(gAmount);
		     (uint256 tTransferAmount, uint256 tFYFee) = _getTValues(TAmount); 
			 _goldFee(gFYFee, tFYFee);
			 _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
			 emit Transfer(sender, recipient, _scaling(tTransferAmount));
            }
            else
            {
                _tOwned[recipient] = _tOwned[recipient].add(TAmount);
                emit Transfer(sender, recipient, tAmount);
             }
        }
    
         
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private 
	{
		uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(GOLDBASEScalingFactor);
		uint256 gAmount = TAmount.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
		_gOwned[sender] = _gOwned[sender].sub(gAmount);
		
		if(!_isWhitelisted(sender, recipient))
            {
			 (uint256 gTransferAmount, uint256 gFYFee) = _getGValues(gAmount);
		     (uint256 tTransferAmount, uint256 tFYFee) = _getTValues(TAmount); 
			 _goldFee(gFYFee, tFYFee);
			 _gOwned[recipient] = _gOwned[recipient].add(gTransferAmount);
			 emit Transfer(sender, recipient, _scaling(tTransferAmount));
            }
            else
            {
                 _gOwned[recipient] = _gOwned[recipient].add(gAmount);
                 emit Transfer(sender, recipient, tAmount);
             }
		
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private 
	{
	    uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(GOLDBASEScalingFactor);
		uint256 gAmount = TAmount.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
		_gOwned[sender] = _gOwned[sender].sub(gAmount);
		
		if(!_isWhitelisted(sender, recipient))
            {
			 (uint256 gTransferAmount, uint256 gFYFee) = _getGValues(gAmount);
		     (uint256 tTransferAmount, uint256 tFYFee) = _getTValues(TAmount); 
			 _goldFee(gFYFee, tFYFee);
			 _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
			 _gOwned[recipient] = _gOwned[recipient].add(gTransferAmount);
			 emit Transfer(sender, recipient, _scaling(tTransferAmount));
            }
            else
            {
				_tOwned[recipient] = _tOwned[recipient].add(TAmount);
                _gOwned[recipient] = _gOwned[recipient].add(gAmount);
                emit Transfer(sender, recipient, tAmount);
             }
    }
	 
	function _scaling(uint256 amount) private view returns (uint256)
	
	{
		uint256 scaledAmount = amount.mul(GOLDBASEScalingFactor).div(internalDecimals);
		return(scaledAmount);
	}

    function _goldFee(uint256 gFee, uint256 tFee) private 
	{
        _gTotal = _gTotal.sub(gFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 TAmount) private view returns (uint256, uint256) 
	{
        uint256 tFYFee = TAmount.div(FYFee);
        uint256 tTransferAmount = TAmount.sub(tFYFee);
        return (tTransferAmount, tFYFee);
    }
	
    function _getGValues(uint256 gAmount) private view returns (uint256, uint256) 
	{
        uint256 gFYFee = gAmount.div(FYFee);
		uint256 gTransferAmount = gAmount.sub(gFYFee);
        return (gTransferAmount, gFYFee);
    }

    function _getRate() private view returns(uint256) 
	{
        (uint256 gSupply, uint256 tSupply) = _getCurrentSupply();
        return gSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) 
	{
        uint256 gSupply = _gTotal;
        uint256 tSupply = initSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_gOwned[_excluded[i]] > gSupply || _tOwned[_excluded[i]] > tSupply) return (_gTotal, initSupply);
            gSupply = gSupply.sub(_gOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (gSupply < _gTotal.div(initSupply)) return (_gTotal, initSupply);
        return (gSupply, tSupply);
    }

    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external onlyRebaser returns (uint256)
    {
        if (!positive)
        {
		uint256 newScalingFactor = GOLDBASEScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
		GOLDBASEScalingFactor = newScalingFactor;
        _totalSupply = (initSupply.mul(GOLDBASEScalingFactor).div(internalDecimals));
        emit Rebase(epoch, GOLDBASEScalingFactor);
        return _totalSupply;
        }
		
        else 
		{
        uint256 newScalingFactor = GOLDBASEScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
        if (newScalingFactor < _maxScalingFactor())
        {
            GOLDBASEScalingFactor = newScalingFactor;
        }
        else
        {
            GOLDBASEScalingFactor = _maxScalingFactor();
        }

        _totalSupply = ((initSupply.mul(GOLDBASEScalingFactor).div(internalDecimals)));
        emit Rebase(epoch, GOLDBASEScalingFactor);
        return _totalSupply;
		}
	}
	
	function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount >= 10**9 , 'GOLDBASE: maxTxAmount should be greater than 1 GOLDBASE');
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(maxTxAmount);
    }
}