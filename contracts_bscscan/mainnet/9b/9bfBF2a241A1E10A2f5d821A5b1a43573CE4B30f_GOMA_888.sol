/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

/** 

         888888888          888888888          888888888     
       88:::::::::88      88:::::::::88      88:::::::::88   
     88:::::::::::::88  88:::::::::::::88  88:::::::::::::88 
    8::::::88888::::::88::::::88888::::::88::::::88888::::::8
    8:::::8     8:::::88:::::8     8:::::88:::::8     8:::::8
    8:::::8     8:::::88:::::8     8:::::88:::::8     8:::::8
     8:::::88888:::::8  8:::::88888:::::8  8:::::88888:::::8 
      8:::::::::::::8    8:::::::::::::8    8:::::::::::::8  
     8:::::88888:::::8  8:::::88888:::::8  8:::::88888:::::8 
    8:::::8     8:::::88:::::8     8:::::88:::::8     8:::::8
    8:::::8     8:::::88:::::8     8:::::88:::::8     8:::::8
    8:::::8     8:::::88:::::8     8:::::88:::::8     8:::::8
    8::::::88888::::::88::::::88888::::::88::::::88888::::::8
     88:::::::::::::88  88:::::::::::::88  88:::::::::::::88 
       88:::::::::88      88:::::::::88      88:::::::::88   
         888888888          888888888          888888888     
         
                                                               
                  *****************************
                                                        
                             GOMA 888 
     
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Ownable {
	event Pause();
	event Unpause();
	bool public paused = false;  
	modifier whenNotPaused() {
		require(!paused);
		_;
	}  
	modifier whenPaused() {
		require(paused);
		_;
	}  
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}	
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }
    function sub( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

abstract contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

    string _name;
    string _symbol;
    uint8 _decimals;
    
    function getOwner() external override view returns (address) {
        return owner();
    }
   
    function name() public override view returns (string memory) {
        return _name;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }
   
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
}

interface PriceOracle {
    function getPriceUsdc(address tokenAddress) external pure returns (uint256);
}

contract GOMA_888 is BEP20, Pausable { 
	using SafeMath for uint256; 

    uint256 public constant MAX_SYPPLY = 88888888 * 1e18; 
	IBEP20 public immutable goma;   
    uint256 public immutable gomaDecimals; 
    address public wallet;  
	PriceOracle public priceOracle;
	uint256 public rate;            
    mapping (address => bool) public whiteList;
    bool public whiteListOnly;
    	
	constructor(){
	    _name = '888';
        _symbol = '888';
        _decimals = 18;

        goma = IBEP20(0xAb14952d2902343fde7c65D7dC095e5c8bE86920); // GOMA
        gomaDecimals = 1e9;
        wallet = 0x21eFFbef01c8f269D9BAA6e0151A54D793113b45;
		priceOracle = PriceOracle(0x26EAb094e543C8FF49980FA2CD02B34644a71478);
		
		rate = 888000000000000000;    
         
        whiteListOnly = true;
        
		_owner = 0xea78a160665Da2754f867F43A19639E49473B2B5;
        emit OwnershipTransferred(address(0), _owner);
   	}
	 
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), '888: transfer from the zero address');
        require(recipient != address(0), '888: transfer to the zero address');

		if (whiteListOnly) {
			require(whiteList[sender] || whiteList[recipient], '888: you can transfer just to/from white listed addresses');			
		} 

        _balances[sender] = _balances[sender].sub(amount, '888: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, '888: transfer amount exceeds allowance') );
        return true;
    }
   	
   	function toggleWhiteListOnly() public onlyOwner {			
		whiteListOnly = !whiteListOnly;
    }

	function addWhiteList (address addressToAdd) public onlyOwner {
		require(!whiteList[addressToAdd], '888: address already in white list');		
        whiteList[addressToAdd] = true;
    }

    function removeWhiteList (address addressToRemove) public onlyOwner {
        require(whiteList[addressToRemove], '888: address already exclused from list');	
        whiteList[addressToRemove] = false;
    }
    
    function setRate(uint256 rateAmount) public onlyOwner {
		require(rateAmount != 0, '888: you can`t set 0');	
		rate = rateAmount;   
	}

	function setPriceOracle(address priceOracleAddress) public onlyOwner {
		priceOracle = PriceOracle(priceOracleAddress);    
		uint256 price = priceOracle.getPriceUsdc(address(goma));
		require(price != 0, '888: price oracle error'); 
	}

	function setWallet(address walletAddress) public onlyOwner {
		wallet = walletAddress;     
	}
   	
   	function drop(address[] memory recipients, uint256[] memory amounts) public onlyOwner returns (uint256 amountTotal) {
        uint8 cnt = uint8(recipients.length);
        require(cnt > 0 && cnt <= 255, '888: number or recipients must be more then 0 and not much than 255');
        require(amounts.length == recipients.length, '888: number or recipients must be equal to number of amounts');
        for (uint i=0; i<cnt; i++){
			require(amounts[i] != 0, '888: you can`t drop 0');
            amountTotal = amountTotal.add(amounts[i]);
        }
        require(_totalSupply.add(amountTotal) <= MAX_SYPPLY, '888: total drop amount exceed max supply');        
        for (uint i=0; i<cnt; i++){
            _mint(recipients[i], amounts[i]);
        }
        return amountTotal;
    }

	function dropEqual(address[] memory recipients, uint256 amount) public onlyOwner returns (uint256 amountTotal) {
        uint8 cnt = uint8(recipients.length);
        require(cnt > 0 && cnt <= 255, '888: number or recipients must be more then 0 and not much than 255');
		require(amount != 0, '888: you can`t drop 0');	
		amountTotal = amountTotal.add(amount * cnt);    
        require(_totalSupply.add(amountTotal) <= MAX_SYPPLY, '888: total drop amount exceed max supply');        
        for (uint i=0; i<cnt; i++){
            _mint(recipients[i], amount);
        }
        return amountTotal;
    }

	function gomaPerToken() public view returns (uint256) {
		uint256 price = priceOracle.getPriceUsdc(address(goma));
		require(price != 0, '888: price oracle error');
		require(price <= rate, '888: price higher than rate');		
		return rate.div(price);
	}
	
	function buyCalculate(uint256 amountOfToken) public view returns (uint256) {
   	    require(amountOfToken != 0, '888: amount can`t be 0');	
        uint256 a = amountOfToken.mul(gomaPerToken());
        require(a >= gomaDecimals, '888: amount of tokens too low');
		return a.div(gomaDecimals);        
    }

	function availableTokens() public view returns (uint256) {
   	    return MAX_SYPPLY.sub(_totalSupply); 
    }
   	
   	function buyTokens(uint256 amountOfToken) public whenNotPaused {
   	    require(amountOfToken != 0, '888: amount can`t be 0');
		require(_totalSupply.add(amountOfToken) <= MAX_SYPPLY, '888: exceed max supply');		
		uint256 amountOfGoma = buyCalculate(amountOfToken);		
		require(goma.balanceOf(_msgSender()) >= amountOfGoma, '888: Not enough GOMA for buy');
		goma.transferFrom(_msgSender(), wallet, amountOfGoma);         
		_mint(_msgSender(), amountOfToken);        
	}   	
   	
   	function mint(uint256 amount) public onlyOwner {
		require(_totalSupply.add(amount) <= MAX_SYPPLY, '888: exceed max supply');
        _mint(_msgSender(), amount);        
    }
    
    function mintTo(uint256 amount, address recipient) public onlyOwner {
        require(_totalSupply.add(amount) <= MAX_SYPPLY, '888: exceed max supply');
        _mint(recipient, amount);        
    }
    
    function burn(uint256 amount) public returns (bool){		
		if (whiteListOnly) {
			require(whiteList[_msgSender()] || _msgSender() == _owner, '888: caller not in list or not the owner');			
		} else {
			require(_msgSender() == _owner, '888: caller is not the owner');	
		}
        _burn(_msgSender(), amount);   
		return true;     
    }
   	
}