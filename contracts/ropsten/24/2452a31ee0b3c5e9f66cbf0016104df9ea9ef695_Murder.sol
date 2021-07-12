/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// contract deploy for partay token by Dr. Pramod Choudhary
pragma solidity 0.5.0;
    contract Context {
      constructor () internal { }
        function _msgSender() internal view returns (address payable) {
            return msg.sender;
        }
        function _msgData() internal view returns (bytes memory) {
            this; 
            return msg.data;
        }
    }
    
    interface IERC20{
        function totalSupply() external view returns (uint256);
        
        function balanceOf(address account) external view returns (uint256);
        
        function transfer(address recipient, uint256 amount) external returns (bool);
        
        function allowance(address owner, address spender) external view returns (uint256);
        
        function approve(address spender, uint256 amount) external returns (bool);
        
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        
        event Transfer(address indexed from, address indexed to, uint256 value);
        
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
    library SafeMath{
        function add(uint256 a, uint256 b) internal pure returns (uint256){
          uint256 c = a+b;
          require(c >= a, "SafeMath: addition overflow");
          return c;
        }
        
        function sub(uint256 a, uint256 b) internal pure returns (uint256){
          return sub(a, b, "SafeMath: subtraction overflow");
        }
        
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256){
          require(b <= a, errorMessage);
          uint256 c = a-b;
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
            
            address payable public owner = (msg.sender);
            uint256 public rate = 20000000;
            uint256 admin_fee=10;
            uint256 production_fee=20;
            uint256 market_fee=30;
            address payable public marketing = address(uint160(address(0x0e5Ad520c0fc85Ef31A4550A2D2972f26d8E8097)));
            address payable public production = address(uint160(address(0x0e5Ad520c0fc85Ef31A4550A2D2972f26d8E8097)));
            function _transfer(address sender, address recipient, uint256 amount) internal {
                require(sender != address(0), "ERC20: transfer from the zero address");
                require(recipient != address(0), "ERC20: transfer to the zero address");
                _balances[sender] = _balances[sender].sub(amount);
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
            function _approve(address _owner, address spender, uint256 amount) internal {
                require(_owner != address(0), "ERC20: approve from the zero address");
                require(spender != address(0), "ERC20: approve to the zero address");
                _allowances[_owner][spender] = amount;
                emit Approval(_owner, spender, amount);
            }
            function _burnFrom(address account, uint256 amount) internal {
                _burn(account, amount);
                _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
            }
            function setRate(uint256 _rate)public returns(bool){
                rate =_rate;
            }
            function commision(uint256 admin_fees, uint256 product_fees, uint256 marketing_fees) public returns(bool){
                admin_fee=admin_fees;
                production_fee=product_fees;
                market_fee=marketing_fees;
            }
            function BuyToken() public payable returns(bool){
                uint256 total=uint256(100).sub((admin_fee).add(market_fee).add(production_fee));
                owner.transfer(msg.value.mul(admin_fee).div(100));
                marketing.transfer(msg.value.mul(market_fee).div(100));
                production.transfer(msg.value.mul(production_fee).div(100));
                owner.transfer(msg.value.mul(total).div(100));
                uint tokens=(msg.value.mul(rate).div(10**18));
                _transfer(owner, msg.sender, tokens);
                return true;
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
        contract MinterRole is Context {
            using Roles for Roles.Role;
            event MinterAdded(address indexed account);
            event MinterRemoved(address indexed account);
            Roles.Role private _minters;
            constructor () internal {
                _addMinter(_msgSender());
            }
            modifier onlyMinter() {
                require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
                _;
            }
            function isMinter(address account) public view returns (bool) {
                return _minters.has(account);
            }
            function addMinter(address account) public onlyMinter {
                _addMinter(account);
            }
            function renounceMinter() public {
                _removeMinter(_msgSender());
            }
            function _addMinter(address account) internal {
                _minters.add(account);
                emit MinterAdded(account);
            }
            function _removeMinter(address account) internal {
                _minters.remove(account);
                emit MinterRemoved(account);
            }
        }
        contract ERC20Mintable is ERC20, MinterRole {
            function mint(address account, uint256 amount) public onlyMinter returns (bool) {
                _mint(account, amount);
                return true;
            }
        }
        contract ERC20Burnable is Context, ERC20 {
            function burn(uint256 amount) public {
                _burn(_msgSender(), amount);
            }
            function burnFrom(address account, uint256 amount) public {
                _burnFrom(account, amount);
            }
        }
        contract Murder is ERC20Mintable, ERC20Burnable {
            string public name="Murder Token";
            string public symbol="killer";
            uint8 public decimals=9;
            constructor () public{
              _mint(msg.sender, 50000000*(uint256(10)**decimals));
            }
    }