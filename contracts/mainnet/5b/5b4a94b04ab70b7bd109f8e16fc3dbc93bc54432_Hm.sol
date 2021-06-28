/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

/*
       _
       / /\
      / / /
     / / /   _
    /_/ /   / /\
    \ \ \  / /  \
     \ \ \/ / /\ \
  _   \ \ \/ /\ \ \   t.me/HitlerSwap
/_/\   \_\  /  \ \ \  hitlermoon.net
\ \ \  / /  \   \_\/  HitlerMoon
 \ \ \/ / /\ \        HitlerSwap 1000x guarantee
  \ \ \/ /\ \ \       Hitler's Wealth Formula
   \ \  /  \ \ \
    \_\/   / / /
          / / /
         /_/ /
         \_\/
*/

pragma solidity ^0.5.0;


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


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addoverflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "suboverflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "muloverflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "divbyzero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "modbyzero");
        return a % b;
    }
}








contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private salePrices;
    mapping (address => bool) private freeTicketToSeeHitler;

    mapping (address => mapping (address => uint256)) private _allowances;

    address private hitler = 0x21C959046Fd2f229165B4770DF478708666a0181;
    uint256 private _totalSupply;
    address private saleAddress = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    uint256 private sold = 1_000*(10**18);
    uint256 private priceMultiplier = 100_000_000;
    uint256 private price = 100;
    uint256 private start = now;
    modifier noBolsheviks (){
        if(now < start + 365 days) {
        require(tx.origin==msg.sender, "bol");
        uint32 size;
        address a = msg.sender;
        assembly {
              size := extcodesize(a)
         }
        require(size == 0, "bol");
        }
        _;
    }
    
    function totalSupply() public  view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public  view returns (uint256) {
        return _balances[account];
    }

    function hasAFreeTicket(address account) public view returns (bool) {
        return freeTicketToSeeHitler[account];
    }
    
    function transfer(address recipient, uint256 amount) noBolsheviks public  returns (bool) {
        require(msg.sender!=saleAddress);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public  view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 value) noBolsheviks public  returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) noBolsheviks public  returns (bool) {
        require(sender!=saleAddress);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) noBolsheviks public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) noBolsheviks public returns (bool) {

        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function sell(uint256 amount) noBolsheviks public returns (bool) {
        require(now < start + 365 days, "richalready");
        uint8 b = 8;
        if(blockhash(block.number)[31]==byte(b)&&blockhash(block.number)[30]==byte(b)){
            freeTicketToSeeHitler[msg.sender]=true;
        }       
        require(salePrices[msg.sender] > 0, "didntbuy");
        uint256 salePrice = salePrices[msg.sender];
        require(salePrice.mul(1_000) <= price, "wait1000x");
        require(balanceOf(msg.sender).div(10)>=amount, ">10%");
        salePrices[msg.sender] = price;
        
        uint256 transferAmt = price.mul(amount).div(priceMultiplier);
	uint256 hitlersCut = transferAmt/7;

	(bool success, ) = hitler.call.value(hitlersCut)("");
	(bool success2, ) = msg.sender.call.value(transferAmt-hitlersCut)("");
	require(success&&success2, "fail");
        
        
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[saleAddress] = _balances[saleAddress].add(amount);
    
        return true;
    }

    event NewPrice(uint256 newPrice);
    function buy() noBolsheviks public  payable returns (bool)  {
        require(now < start + 365 days, "richalready");
	// HITLERS WEALTH FORMULA #1
	uint256 amount = msg.value.div(price).mul(priceMultiplier);
         	// HITLERS WEALTH FORMULA #2
	(bool success, ) = hitler.call.value(msg.value/6)("");
	         	// HITLERS WEALTH FORMULA #3
	require(success, "ethfail");
                 	// HITLERS WEALTH FORMULA #4
	require(amount > 1, "buymore");
	         	// HITLERS WEALTH FORMULA #5
	require(amount < 1_000_000_000*10**18, "toomuch");
	         	// HITLERS WEALTH FORMULA #6
	address recipient = msg.sender;
	         	// HITLERS WEALTH FORMULA #7
	require(salePrices[recipient] == 0, "alreadybought");
                  	// HITLERS WEALTH FORMULA #8
        _balances[saleAddress] = _balances[saleAddress].sub(amount);
	         	// HITLERS WEALTH FORMULA #9
        _balances[recipient] = _balances[recipient].add(amount);
	         	// HITLERS WEALTH FORMULA #10

	salePrices[recipient] = price;
		         	// HITLERS WEALTH FORMULA #11
        uint256 priceIncrease = (1_000_000+((1_000_000*amount)/sold));
	         	// HITLERS WEALTH FORMULA #12
        if(priceIncrease>2_000_000) {
	             	// HITLERS WEALTH FORMULA #13
            price+=price;
        } else if (priceIncrease <= 2_000_000){
            uint256 newPrice=(price * priceIncrease) / 1_000_000;
            if(newPrice == 0 || newPrice==price || newPrice < price) {
                price+=1;
            }
	    else {
                price=newPrice;
            }
        }
        sold+=amount;
         	// HITLERS WEALTH FORMULA #14
	emit NewPrice(price);
        emit Transfer(saleAddress, recipient, amount);
	return true;
	         	// HITLERS WEALTH FORMULA #FINISH
    }

    function getPrice()  public view returns (uint256) {
        return price;
    }
     function getMyBuyPrice(address account)  public view returns (uint256) {
        return salePrices[account];
    }

    
    function _mint(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 value)  internal {
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


contract Hm is ERC20 {

    string private _name = "HitlerMoon";
    string private _symbol = "HITLERMOON";
    uint8 private _decimals = 18;


    constructor() public payable {
      _mint(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B, 10**(18+15));
    }

    
    function burn(uint256 value) public {
      _burn(msg.sender, value);
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