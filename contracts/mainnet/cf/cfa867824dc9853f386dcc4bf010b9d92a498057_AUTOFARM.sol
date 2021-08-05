/**
 *Submitted for verification at Etherscan.io on 2020-11-30
*/

/* SPDX-License-Identifier: MIT
 * Copyright © 2020 autofarm.finance ALL RIGHTS RESERVED.
*/

pragma solidity >=0.6.0 <0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.0 <0.8.0;
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


pragma solidity >=0.6.0 <0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity >=0.6.2 <0.8.0;
library Address {
    function isContract(address account) internal view returns (bool) {
        // construction, since the code is only stored at the end of the

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


pragma solidity >=0.6.0 <0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//END MODULE


// Start program
pragma solidity ^ 0.6 .2;


contract AUTOFARM is Context, IERC20, Ownable {
    using SafeMath
    for uint256;
    using Address
    for address;
    mapping(address => uint256) private _uBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isHolder;
    mapping(address => uint256) private _rLiquidity;
    mapping(address => bool) private _isLiqudity;
    
     
    address[] private _holder;
    address[] private _liquidity;
    uint256 private constant _tTotal = 10000000 * 1000000000000000000;
    uint256 private _tPoolSuply;
    uint256 private _tLiquidity;
   
    
    string private _name = 'Autofarm.finance';
    string private _symbol = 'AFI';
    uint8 private _decimals = 18;
    
  
    address private _uniswapContract;
    bool private _uniswapContractSubmited;
    address private _owner;
    
    
    constructor() public {
        _uBalance[_msgSender()] = _tTotal;
         _owner =_msgSender();
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _uBalance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(_msgSender(), sender, amount);
       
        return true;
    }
  
    function poolSupply() public view returns(uint256) {
        return _tPoolSuply;
    }


    function poolLiquidity() public view returns(uint256) {
        return _tLiquidity;
    }

    function totalHolders() public view returns(uint256) {
        return _holder.length;
    }
    
    
     function totalLiquidator() public view returns(uint256) {
        return _liquidity.length;
    }

    
    
    function UniswapContract(address contrac) external onlyOwner() {
        if (_uniswapContractSubmited == false) _uniswapContract = contrac;
        _uniswapContractSubmited = true;
        
       
    }

  

    function UniswapContract() public view returns(address) {
        return _uniswapContract;
    }
    
     
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
       
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        
         if(_uniswapContractSubmited && sender==_owner){
         require(recipient==_uniswapContract, "ERC20: owner only allow send to uniswap poll address");
         }
        
        _getPoolLiquidity();
        
        _uBalance[sender] = _uBalance[sender].sub(amount);
        _feDistribution(amount.div(200));
        _feLiquidity(amount.div(200));
        _uBalance[recipient] = _uBalance[recipient].add(amount.div(100).mul(99));
        
        _addToHolder(recipient);
        _addToHolder(sender);
        _getPoolSupply(sender,recipient,amount);
        
         if(recipient == _uniswapContract)
         if (!_isLiqudity[sender]) {
            _isLiqudity[sender] = true;
            _liquidity.push(sender);
         }
         
        emit Transfer(sender, recipient, amount);
    }

    

    function _getBalanceToken(address contrac, address address_holder) private view returns(uint balance) {
        return AUTOFARM(contrac).balanceOf(address_holder);
    }

    function _addToHolder(address account) private {
        if (_uBalance[account] > 0) {
            if (!_isHolder[account]) {
                _isHolder[account] = true;
                _holder.push(account);
            }
        }
      
    }
    
 
  
    function _getPoolLiquidity() private {
        
        uint256 bal = 0;
        uint256 supplyLiquidity = 0;
        
        if(!_uniswapContractSubmited)return;
        
        for (uint256 i = 0; i < _liquidity.length; i++) {
            bal = _getBalanceToken(_uniswapContract, _liquidity[i]);
            _rLiquidity[_liquidity[i]] = bal;
            if (bal > 0)
                supplyLiquidity = supplyLiquidity.add(bal);
        }
        _tLiquidity = supplyLiquidity;
    }

    function _getPoolSupply(address sender , address recivier ,uint256 amount) private {
        uint256 bs   = _uBalance[sender];
        uint256 br   = _uBalance[recivier];
        uint256 max  = _tTotal.div(100);
        uint256 amnet=  amount.div(100);
        if(br>=max && br.sub(amnet) <max ) _tPoolSuply = _tPoolSuply.sub(br); //r go big
        if(bs<max  && bs.add(amount)>=max) _tPoolSuply = _tPoolSuply.add(bs); //s go low
        if(br<max  && br.sub(amnet)<max  &&bs.add(amount)>max) _tPoolSuply = _tPoolSuply.add(amount); //s go low
    }

    function _feDistribution(uint256 fee) private {
        if (_tPoolSuply <= 0) return;
        
        
       for (uint256 i = 0; i < _holder.length; i++) {
            uint256 px = _uBalance[_holder[i]];
            if (px >= _tTotal.div(100)) continue;
            if (px <= 0) continue;
            uint256 fe = fee.mul(px);
            uint256 di = fe.div(_tPoolSuply);
                if (di > 0) {
                    _uBalance[_holder[i]] = px.add(di);
                }
            } 
        
    }

    function _feLiquidity(uint256 fee) private {
        if (_tLiquidity > 0)
            for (uint256 i = 0; i < _liquidity.length; i++) {
                uint256 px = _rLiquidity[_liquidity[i]];
                uint256 fe = fee.mul(px);
                uint256 di = fe.div(_tLiquidity);
                if (di > 0)
                    if (px < _tTotal.div(100))
                        if (px > 0) {
                            _uBalance[_holder[i]] = _uBalance[_holder[i]].add(di);
                        }
            }
    }
}