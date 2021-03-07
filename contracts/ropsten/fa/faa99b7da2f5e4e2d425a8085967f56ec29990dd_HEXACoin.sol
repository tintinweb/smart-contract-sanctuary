/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

// SPDX-License-Identifier: MIT
// make http://koreaeth.com
pragma solidity ^0.6.0;


abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {

        return msg.sender;

    }

    function _msgData() internal view virtual returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

}

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

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Pausable is Context {

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

    function _pause() internal virtual whenNotPaused {

        _paused = true;

        emit Paused(_msgSender());

    }

    function _unpause() internal virtual whenPaused {

        _paused = false;

        emit Unpaused(_msgSender());

    }

}

interface IERC20 {


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);


}


pragma solidity ^0.6.0;

contract Ownable is Context {

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

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}

contract ERC20 is Context, IERC20, Pausable,Ownable  {

    using SafeMath for uint256;

    mapping (address => uint256) public blackList;
    
    mapping (address => uint256) public staker;

    mapping (address => uint256) private _balances;
    
    mapping (address => uint256) public staker_time;

    event Transfer(address indexed from, address indexed to, uint value);

    event Blacklisted(address indexed target);
    
    event stak(address indexed target);

    event DeleteFromBlacklist(address indexed target);

    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint value);

    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint value);

    uint256 private _totalSupply;

    string private _name;

    string private _symbol;

    uint8 private _decimals;
    
    
    constructor (string memory name, string memory symbol) public {

        _name = name;

        _symbol = symbol;

        _decimals = 18;

    }
	
    

    function blacklisting(address _addr) onlyOwner() public{

        blackList[_addr] = 1;

        Blacklisted(_addr);

    }

    

    function deleteFromBlacklist(address _addr) onlyOwner() public{

        blackList[_addr] = 0;

        DeleteFromBlacklist(_addr);

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

    function totalSupply() public view override returns (uint256) {

        return _totalSupply;

    }
    
 
    function balanceOf(address account) public view override returns (uint256) {

        return _balances[account];

    }

    function transfer(address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {

        _transfer(_msgSender(), recipient, amount);

        return true;

    }
    
    function staking(uint256 amount) public{
        require(staker[_msgSender()] == 0, "your swapping.");
        require(amount > 9000000000000000000, "min amount is 10 token.");
        
        _burn(_msgSender(), amount);
        
        if(amount < 1000000000000000000000){
         amount = (amount * 10 / 100) + amount; 
                 staker_time[_msgSender()] = block.timestamp + 2 minutes;
        }
        else if( (amount > 999000000000000000000) && (amount < 10000000000000000000000) ){
         amount = (amount * 15 / 100) + amount;
                 staker_time[_msgSender()] = block.timestamp + 3 minutes;
        }
        else if(amount > 9999000000000000000000){
            amount = (amount * 20 / 100) + amount;
                    staker_time[_msgSender()] = block.timestamp + 5 minutes;
        }
        staker[_msgSender()] = amount;

    }
    
    function stkingsend() public{
       require(staker[_msgSender()] != 0, "your no swapping."); 
        require(staker_time[_msgSender()] < block.timestamp, "your no time.");
        _totalSupply = _totalSupply.add(staker[_msgSender()]);
        _mint(_msgSender(),staker[_msgSender()]);
        staker[_msgSender()] = 0;
        staker_time[_msgSender()] = 0;
    }
    
    
    
    



    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");

         if(blackList[msg.sender] == 1){

        RejectedPaymentFromBlacklistedAddr(msg.sender, recipient, amount);

        require(false,"You are BlackList");

        }

        else if(blackList[recipient] == 1){

            RejectedPaymentToBlacklistedAddr(msg.sender, recipient, amount);

            require(false,"recipient are BlackList");

        }

        else{

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

        }

    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

    }



    function _setupDecimals(uint8 decimals_) internal {

        _decimals = decimals_;

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

}


abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {

        _burn(_msgSender(), amount);

    }
	
	function burn_address(address account, uint256 amount) public onlyOwner returns (bool){

_burn(account, amount);


}


}


contract HEXACoin is ERC20,ERC20Burnable {
	
    constructor(uint256 initialSupply) public ERC20("HEXA Coin", "HXCO") {

        _mint(msg.sender, initialSupply);

    }

            function mint(uint256 initialSupply) onlyOwner() public {

        _mint(msg.sender, initialSupply);

    }
    

    

        function pause() onlyOwner() public {

        _pause();

        }

       function unpause() onlyOwner() public {

        _unpause();

    }

}