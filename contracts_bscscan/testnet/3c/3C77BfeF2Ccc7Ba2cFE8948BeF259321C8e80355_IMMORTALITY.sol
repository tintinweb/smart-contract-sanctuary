/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity >=0.4.22 <0.6.0;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply =  0;
    
    
    

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

   
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

   
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
 
 
   
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

   
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

   
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

   
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(value <= _balances[account]);
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

   
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

   
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

   
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

   
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    

}

contract Pausable is Ownable {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

   
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



contract IMMORTALITY is ERC20, Pausable, ERC20Detailed {
    
	    
    uint256 private totalCoins; 
    
    struct LockItem {
        uint256  releaseDate;
        uint256  amount;
    }
    
    mapping (address => LockItem[]) public lockList;
    mapping (uint => uint) public quarterMap;
    address [] private lockedAddressList; // list of addresses that have some fund currently or previously locked
    
    
	constructor() public ERC20Detailed("IMMORTALITY", "IMMO", 9) {  
	        
       
        totalCoins = 500000000 * 10 ** uint256(decimals());
        _mint(owner(), totalCoins); // total supply fixed at 500 Million coins
                
    }
	
	
    
     
	function transfer(address _receiver, uint256 _amount) public whenNotPaused returns (bool success) {
	    require(_receiver != address(0)); 
	    require(_amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(_receiver, _amount);
	}
	
	
    function transferFrom(address _from, address _receiver, uint256 _amount) public whenNotPaused returns (bool) {
        require(_from != address(0));
        require(_receiver != address(0));
        require(_amount <= allowance(_from, msg.sender));
        require(_amount <= getAvailableBalance(_from));
        return ERC20.transferFrom(_from, _receiver, _amount);
    }

  
	
	function transferAndLock(address _receiver, uint256 _amount, uint256 _releaseDate) public whenNotPaused returns (bool success) {
    	
    	if (lockList[_receiver].length==0) lockedAddressList.push(_receiver);
		
    	LockItem memory item = LockItem({amount:_amount, releaseDate:_releaseDate});
		lockList[_receiver].push(item);
		
        return true;
	}
	
	
   
	function getLockedAmount(address lockedAddress) public view returns(uint256 _amount) {
	    uint256 lockedAmount =0;
	    for(uint256 j = 0; j<lockList[lockedAddress].length; j++) {
	        if(now < lockList[lockedAddress][j].releaseDate) {
	            uint256 temp = lockList[lockedAddress][j].amount;
	            lockedAmount += temp;
	        }
	    }
	    return lockedAmount;
	}
	

	function getAvailableBalance(address lockedAddress) public view returns(uint256 _amount) {
	    uint256 bal = balanceOf(lockedAddress);
	    uint256 locked = getLockedAmount(lockedAddress);
	    return bal.sub(locked);
	}
	
	
    function burn(uint256 _amount) public whenNotPaused {
        _burn(msg.sender, _amount);
    }
    
    function () payable external {   
        revert();
    }
    
    
    // the following functions are useful for frontend dApps

	function getLockedAddresses() public view returns (address[] memory) {
	    return lockedAddressList;
	}
	

	function getNumberOfLockedAddresses() public view returns (uint256 _count) {
	    return lockedAddressList.length;
	}
	    
	    

	function getNumberOfLockedAddressesCurrently() public view returns (uint256 _count) {
	    uint256 count=0;
	    for(uint256 i = 0; i<lockedAddressList.length; i++) {
	        if (getLockedAmount(lockedAddressList[i])>0) count++;
	    }
	    return count;
	}
	    
	
	function getLockedAddressesCurrently() public view returns (address[] memory) {
	    address [] memory list = new address[](getNumberOfLockedAddressesCurrently());
	    uint256 j = 0;
	    for(uint256 i = 0; i<lockedAddressList.length; i++) {
	        if (getLockedAmount(lockedAddressList[i])>0) {
	            list[j] = lockedAddressList[i];
	            j++;
	        }
	    }
	    
        return list;
    }
    
    

	function getLockedAmountTotal() public view returns(uint256 _amount) {
	    uint256 sum =0;
	    for(uint256 i = 0; i<lockedAddressList.length; i++) {
	        uint256 lockedAmount = getLockedAmount(lockedAddressList[i]);
    	    sum = sum.add(lockedAmount);
	    }
	    return sum;
	}
	    
	    
	
	function getCirculatingSupplyTotal() public view returns(uint256 _amount) {
	    return totalSupply().sub(getLockedAmountTotal());
	}
    
    
	function getBurnedAmountTotal() public view returns(uint256 _amount) {
	    return totalCoins.sub(totalSupply());
	}
    
}