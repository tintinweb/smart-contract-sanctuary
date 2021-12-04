/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

struct GeneralDetails {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
}

interface AFTS {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function multiTransfer(address[] memory to, uint256[] memory amount) external returns (bool);  
    
    function multiTransferFrom(address sender, address[] memory to, uint256[] memory amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);    
    
    event Transfer(address indexed sender, address indexed recipient, uint256 value);

    event Approval(address indexed approver, address indexed spender, uint256 value);
    
}

contract BLITZ is Context, AFTS {
    
    GeneralDetails public _general;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor () {
        _general.name = "BLITZ";
        _general.symbol = "BLITZ";
        _general.decimals = 18;
        _general.totalSupply = 50000000000000*1e18;
        _transfer(address(0), _msgSender(), _general.totalSupply, 0, address(0));
    }

    function name() public view virtual returns (string memory) {
        return _general.name;
    }

    function symbol() public view virtual returns (string memory) {
        return _general.symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _general.decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _general.totalSupply;
    }

    function _transfer(address sender, address recipient, uint256 amount, uint8 method, address spender) internal virtual {
        
        if(method > 0){
            require(sender != address(0), "from zero address");
            require(recipient != address(0), "to zero address");
        }

        if(method == 2){
            require(allowance[sender][spender] >= amount, "amount exceeds allowance");
        } 
            
        if(sender != address(0)){
            require(balanceOf[sender] >= amount, "amount exceeds balance");
            balanceOf[sender] -= amount;
            if(method == 2){
                _approve(sender, spender, allowance[sender][spender] - amount);
            }
        }
        
        if(recipient != address(0)){
            balanceOf[recipient] += amount;
        }
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _transferMulti(address sender, address[] memory to, uint256[] memory amount, uint8 method, address spender) internal virtual {
		require(200 >= to.length, "exceeds max limit");        
		require(to.length == amount.length, "array length not equal");
		uint256 sum_;
		
        for (uint8 g; g < to.length; g++) {
            require(to[g] != address(0), "to zero address");
            sum_ += amount[g];            
        }
        
        require(balanceOf[sender] >= sum_, "amount exceeds balance");
        
        if(method == 2){
            require(allowance[sender][spender] >= sum_, "amount exceeds allowance");           
        }
        
		for (uint8 i; i < to.length; i++) {
		    _transfer(sender, to[i], amount[i], method, address(0));
		}        
    }   
    
    function _approve(address sender, address spender, uint256 amount) internal virtual {
        allowance[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {  
        _transfer(_msgSender(), recipient, amount, 1, address(0));
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, 2, _msgSender());
        return true;
    }

	function multiTransfer(address[] memory to, uint256[] memory amount) public virtual override returns (bool) {
		_transferMulti(_msgSender(), to, amount, 1, address(0));
        return true;
	}
	
	function multiTransferFrom(address sender, address[] memory to, uint256[] memory amount) public virtual override returns (bool) {
		_transferMulti(sender, to, amount, 2, _msgSender());
        return true;
	} 

    function burn(uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), address(0), amount, 0, address(0));
        _general.totalSupply -= amount;
        return true;
    }

}