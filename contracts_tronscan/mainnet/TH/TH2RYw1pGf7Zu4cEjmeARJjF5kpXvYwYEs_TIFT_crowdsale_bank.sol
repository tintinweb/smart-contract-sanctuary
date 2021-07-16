//SourceUnit: crowdsale_v3.sol

////////////////////////////////////////////////////////
///                                                  ///
/// 			TIFT CROWDSALE CONTRACT v.3          ///
///													 ///
////////////////////////////////////////////////////////

pragma solidity 0.5.8;

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract TIFT_crowdsale_bank {
    using Roles for Roles.Role;
	using SafeMath for uint256;

	address private tift_token_contract;					//TIFT token contract address
	address private usdt_contract;						    //USDT token contract address
	address private owner;									//Owner address
	
	uint256 private token_price_trx;							//Price of token TRX -> TIFT
	uint256 private token_price_usdt;							//Price of token USDT -> TIFT
	
	uint256 private total_tokens;							//Total tokens in contract
	uint256 private total_tokens_sold;						//Total sold tokens
	bool Contract_paused;
		
	ERC20 private ERC20Interface;
    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);	

    Roles.Role private _managers;	                    //List of managers of bank	
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//										 																		    //
//                                         MANAGERS,OWNERS,CONTRACTS   												//
//                                     																			    //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
	
	constructor()	
    public {
        owner                  = msg.sender;								//setting current user as owner of contract
		_managers.add(msg.sender);											//setting to owner role - manager
		token_price_trx        = 2000000;									//initialize token price 30 000 000 (2 TRX)
		token_price_usdt       = 50000;									//initialize token price 30 000 000 (0,05 USDT)
		Contract_paused        = false;										//turning pause off, by default
    }

    function Is_Manager(address account) public view returns (bool) {
		require(account!=address(0), "TRC20: from the zero address");		//Zero-address-protection
        return _managers.has(account);										//Searching for user
    }	
	
    function Add_Manager(address new_manager) public {
		require(new_manager!=address(0), "TRC20: from the zero address");	//Zero-address-protection
        if(Is_Manager(msg.sender)==true) { 									//Checking sender rights
			if(Is_Manager(new_manager)==false) {							//Checking new_manager are not exists in list
				_managers.add(new_manager);									//Adding new user
				emit ManagerAdded(new_manager);								//Calling event
			}	
        }		
    }
	
    function Remove_Manager(address fired_manager) external {
		require(fired_manager!=address(0), "TRC20: from the zero address");	//Zero-address-protection
        if(Is_Manager(msg.sender)==true) { 									//Checking sender rights			
			if(Is_Manager(fired_manager)==true) {							//Checking fired_manager exists in list		
				_managers.remove(fired_manager);							//Removing new user
				emit ManagerRemoved(fired_manager);							//Calling event
			}
        }		
    }
	
	function Get_Token_Contract()view external returns (address) {
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			return tift_token_contract;										//Return contract address
		}
	}	
	
	function Get_Tokens_Sold()view external returns (uint256) {
		return total_tokens_sold;							
	}	
	
	function Get_Tokens_Balance()view external returns (uint256) {
		return total_tokens;							
	}		
	
	function Get_Price_TRX() view external returns (uint256) {
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			return token_price_trx;												//Return current price
		}
	}		
	
	function Get_Price_USDT() view external returns (uint256) {
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			return token_price_usdt;										//Return current price
		}
	}		
	
	function Get_USDT_Contract()view external returns (address) {
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			return usdt_contract;										//Return contract address
		}
	}		
	
	function Set_Token_Contract(address new_contract) external {
		require(new_contract!=address(0), "TRC20: from the zero address");	//Zero-address-protection
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			tift_token_contract = new_contract;								//Changing contract address
		}
	}	

	function Set_USDT_Contract(address new_contract) external {
		require(new_contract!=address(0), "TRC20: from the zero address");	//Zero-address-protection
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			usdt_contract = new_contract;								//Changing contract address
		}
	}		
	
	function Set_Price_TRX(uint _token_price) external {
		require(_token_price!=0, "TRC20: zero price");
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			token_price_trx = _token_price;								    	//Changing token price
		}
	}		
	
	function Set_Price_USDT(uint _token_price) external {
		require(_token_price!=0, "TRC20: zero price");
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			token_price_usdt = _token_price;								    	//Changing token price
		}
	}		
	
	function Is_Paused() view public returns (bool) {
		return Contract_paused;												//Returns is token paused or not
	}	
	
	function Turn_On_Pause() external {
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			Contract_paused = true;											//Turning pause on
		}			
	}		
	
	function Turn_Off_Pause() external {
		if(Is_Manager(msg.sender)==true) {									//Checking sender rights
			Contract_paused = false;										//Turning pause off
		}			
	}		
			
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//										 																		    //
//                                         CROWDSALE				   												//
//                                     																			    //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	

	function buy_tift_trx(uint256 _amount) external payable {
		if(Is_Paused()==false){
			require(token_price_trx!=0,"Price error!");			
			uint256 _decimals = 10**6;
			uint256 _amount_with_decimals = SafeMath.mul(_amount,_decimals);//Getting decimals precision
			uint256 _msgvalue_with_decimals = SafeMath.mul(msg.value,_decimals);
			ERC20Interface = ERC20(tift_token_contract);													//Connecting to token contract
			
			//#1 check - balance of tokens in contract is bigger or equals amount to buy
			require(ERC20Interface.balanceOf(address(this))>=_amount_with_decimals, "Bank balance error!");	
			//#2 check - price of crowdsale not zero			
			//#3 check - balance of TRX of sender is enough to buy specified amount of TIFT
			//	formula: TRX amount / Token Price = TIFT amount (precision 6 digits both), e.g. 500 000 000 / 40 000 000 = 12 500 000 TIFT 
			require(SafeMath.div(_msgvalue_with_decimals,token_price_trx)>=_amount_with_decimals,"Not enough to buy,balance error!");
			//Approving transaction
			require(ERC20(tift_token_contract).approve(msg.sender, _amount_with_decimals));
			//Transfering tokens to buyer
			require(ERC20(tift_token_contract).transfer(msg.sender, _amount_with_decimals));
			total_tokens_sold += _amount_with_decimals;
			total_tokens -= _amount;
		}			
	}
	

	function buy_tift_usdt(uint256 _amount) external {
		if(Is_Paused()==false){			
		    require(token_price_usdt!=0,"Price error!");
			ERC20 ERC20InterfaceUSDT;
			ERC20 ERC20InterfaceTIFT;
			uint256 _decimals = 10**6;
			uint256 _amount_with_decimals = SafeMath.mul(_amount,_decimals);
			uint256 _amount_to_buy = SafeMath.div(_amount_with_decimals,token_price_usdt);
			ERC20InterfaceUSDT = ERC20(usdt_contract);													
			ERC20InterfaceTIFT = ERC20(tift_token_contract);													
			require(ERC20InterfaceTIFT.balanceOf(address(this))>=_amount_to_buy, "Bank balance error!");						

			require(ERC20InterfaceUSDT.transferFrom(msg.sender, address(this), _amount), "Sale failed");	
			
			require(ERC20InterfaceTIFT.approve(msg.sender, _amount_to_buy));
			require(ERC20InterfaceTIFT.transfer(msg.sender, _amount_to_buy));
			total_tokens_sold += _amount_to_buy;
			total_tokens -= _amount_to_buy;
		}			
	}	
	
	function TopUp_Deposit(uint256 _amount) external {
		if(Is_Manager(msg.sender)==true) { 
			ERC20Interface = ERC20(tift_token_contract);  		
			require(ERC20Interface.approve(address(this), _amount),"Approve failed");
			require(ERC20Interface.transferFrom(msg.sender, address(this), _amount), "Deposit failed");		
			total_tokens += _amount;
		}	
	}
	
	function RemoveUSDT() external {
		if(Is_Manager(msg.sender)==true) { 
			uint256 _amount;
			_amount = ERC20(usdt_contract).balanceOf(address(this));
			require(_amount!=0,"Zero balance!");
			require(ERC20(usdt_contract).approve(msg.sender, _amount));
			require(ERC20(usdt_contract).transfer(msg.sender, _amount));
		}
    }	
	
	function RemoveTIFT() external {
		if(Is_Manager(msg.sender)==true) { 
			uint256 _amount;
			_amount = ERC20(tift_token_contract).balanceOf(address(this));
			require(_amount!=0,"Zero balance!");
			require(ERC20(tift_token_contract).approve(msg.sender, _amount));
			require(ERC20(tift_token_contract).transfer(msg.sender, _amount));
			total_tokens = 0;
		}
    }
	
	function RemoveTRX() external{
		if(Is_Manager(msg.sender)==true) {
			uint256 _amount;
			_amount = address(this).balance;
			require(_amount!=0,"Zero balance!");
			msg.sender.transfer(_amount);
		}
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	

	
}