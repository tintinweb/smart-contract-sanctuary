/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity >=0.6.2;

//
//
//   100 tokens Total ever minted
//   50 tokens + 3eth to pool ( 20 tokens available for presale .1 eth each)
//   37 tokens to the Vesting Contract - every 3 months, (3,5,7,9) tokens (split) sent to Hodlers greater than x (tbd) and weighted
//   // LQ Hodlers will recieve double what standard Hodlers will
//   // 13 of Vesting unlocked to devs after 3 months split over 4 months
//   3 tokens sent to 2k random address for listing via vesting Contract
//   10 tokens to owner for Vested LQ
//
//

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value );
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public _totalSupply;  // capped 100 with 27 to vesting and 3 sent to random addresses

    string public _name;
    string public _symbol;
    uint8 public _decimals;
    
    uint256 public SaleTokens = 20;
    
    address public vesting;
    
    bool public liquid = false;
    
    
    address weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable ContractOwner; // used for token recovery and Pool creation Only...

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        ContractOwner = msg.sender;
        _mint(msg.sender, 10*(10**18));
        _mint(address(this),50*(10**18));
        
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply <= 100*(10**18));
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    
    function vestingContract(address _vesting) public {
        require(vesting == address(0));
        vesting = _vesting;
        _mint(vesting,40*(10**18));
    }
    
    function presale() public payable {
        uint256 tokens = msg.value.mul(10);
        require(tokens <= SaleTokens, "running out, try to buy less");
        SaleTokens = SaleTokens.sub(tokens);
        _transfer(address(this),msg.sender, tokens);
    }
    
    
    function Liquify(address factory) public payable {
        require(tx.origin == ContractOwner);
        require(liquid == false);
        (bool success, bytes memory pair) = factory.call(abi.encodeWithSignature("createPair(address,address)", address(this), weth));
        require(success,"Create Pair");
        (address Pair) = abi.decode(pair,(address));
        address token = address(this);
        uint256 Bal = address(this).balance;
        weth.call{value:Bal}(abi.encode("deposit()"));
        weth.call(abi.encodeWithSignature("transfer(address,uint256)",Pair,3 ether));
        token.call(abi.encodeWithSignature("transfer(address,uint256)",Pair,_balances[address(this)]));
        (bool suces,) = Pair.call(abi.encodeWithSignature("mint(address)",ContractOwner));
        require(suces);
        liquid = true;
    }
    
     //recover functions for mistaken tokens or eth, find Crypto_Rachel on uni discord
    function withdraw() public payable {
        require(tx.origin==ContractOwner);
        require(liquid == true);
        ContractOwner.transfer( address( this ).balance );
    }
    function toke(address _toke, uint amt) public payable {
        require(tx.origin==ContractOwner);
        if(_toke == weth){
            uint256 Wbal = IERC20(weth).balanceOf(address(this));
            weth.call(abi.encodeWithSignature("withdraw(uint256)",Wbal));
            ContractOwner.transfer(address(this).balance);
        }else{
            IERC20(_toke).transfer(ContractOwner,amt);
        }
    }

    receive () external payable {}
    fallback () external payable {}
    
    
}