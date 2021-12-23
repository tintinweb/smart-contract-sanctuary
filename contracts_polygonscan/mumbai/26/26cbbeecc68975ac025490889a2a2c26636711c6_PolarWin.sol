// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import './IERC20.sol';
import './IERCMetaData.sol';

contract PolarWin is IERC20,IERC20MetaData{
    // Owner Account of PWIN Token
    address public owner;
    // Mapping to Check Balances
    mapping(address => uint256) public _balances;
    // Mapping to Check Allowances
    mapping(address => mapping(address => uint256)) public allowances;
    // Total Supply
    uint256 public _totalSupply;
    string private _name= 'Polar Win';
    string private _symbol = 'PWIN';
    // Game Contract Address 
    address private gameContract;

    
    constructor(address _gameContract){
        owner = msg.sender;
        gameContract = _gameContract;
        _mint(owner,1*10**9*10**18);
        transfer(gameContract,1*10**6*10**18);
        
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18 ;
    }
    
    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }  
    function balanceOf(address account) external override view returns (uint256){
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool){
        _transfer(msg.sender,recipient,amount);
        return true;
    }
    function _transfer(address _sender,address _receiver,uint256 amount) internal virtual{
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_receiver != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[_sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
         unchecked {
            _balances[_sender] = senderBalance - amount;
        }
        _balances[_receiver] += amount;
        emit Transfer(_sender, _receiver, amount);
        
    }
    function allowance(address _owner, address spender) external virtual override view returns (uint256){
        return allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) external override virtual returns (bool){
        _approve(msg.sender,spender,amount);
        return true;
    }
    function _approve(address _owner, address _spender,uint256 amount)internal virtual{
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[_owner][_spender] = amount;
        emit Approval(_owner, _spender, amount);
    }   
    function transferFrom(address _sender,address _receiver,uint256 amount) external virtual override returns (bool){
       uint256 currentAllowance = allowances[_sender][msg.sender];
       if(msg.sender != gameContract) // Whitelist Game contract
       {
           require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
           unchecked {
            _approve(_sender, msg.sender, currentAllowance - amount);
        }
       }
        
       _transfer(_sender, _receiver, amount);
        return true;
    }  
    function _mint(address account, uint256 amount) public {
        require(owner == msg.sender,"ERC20: only owner can mint");
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) public{
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

     
}