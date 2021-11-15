pragma solidity ^0.8.4;   
// SPDX-License-Identifier: MIT

// import './IERC20.sol';
// import './Ownable.sol';
// import './SafeMath.sol';

contract bep20Token{
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address public _creator;
    uint256 private _totalSupply;
    bool public mintingFinishedPermanent = false;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
   
    constructor (address creator_,string memory name_, string memory symbol_,uint8 decimals_, uint256 tokenSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _creator = creator_;
        
        _mint(_creator,tokenSupply_);
        mintingFinishedPermanent = true;
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(!mintingFinishedPermanent,"cant be minted anymore!");
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    } 
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import './TokenContract.sol';

contract HODLTokenDeployer {

    using SafeMath for uint256;
    address payable public admin;
    // IERC20 public hodlToken;
    uint256 public adminFee;
    bep20Token public token;

    mapping(address => address[]) public getToken;
    address[] public allTokens;

    modifier onlyAdmin(){
        require(msg.sender == admin,"BEP20: Not an admin");
        _;
    }

    event newTokenCreated(address indexed _token, uint256 indexed _length);

    constructor() {
        admin = payable(msg.sender);
        // hodlToken = IERC20(0x9EBb8eDa4Afa430801484d03ae26DDDe204E8cdE);
        adminFee = 10000e18;
    }

    receive() payable external{}

    function createToken(
        address _tokenOwner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply

    ) external {

        require(tx.origin == msg.sender, "humans only");
        
        // bytes memory bytecode = type(bep20Token).creationCode;
        // bytes32 salt = keccak256(abi.encodePacked(_tokenOwner, allTokens.length));

        // assembly {
        //     tokenContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        // }

        // IERC20(tokenContract).initialize(
        //     _tokenOwner,
        //     _name,
        //     _symbol,
        //     _decimals,
        //     _totalSupply
        // );

        token = new bep20Token(
            _tokenOwner,
            _name,
            _symbol,
            _decimals,
            _totalSupply
        );
    
        allTokens.push(address(token));
        getToken[msg.sender].push(address(token));
        emit newTokenCreated(address(token) , allTokens.length);
    }

}

