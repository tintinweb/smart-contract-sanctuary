pragma solidity 0.5.11;
import "./SafeMath.sol";
contract MoonsDust   {
    using SafeMath for uint256;
   

  
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );


    
    string constant public name = "MoonsDust";
    string constant public symbol = "MOOND";
    uint256 constant public decimals = 18 ;
    uint256 private _totalSupply;
    uint256 public tokensForSale = 1650000 * (10 ** uint256(decimals));
    uint256 public tokensSold = 1 * (10 ** uint256(decimals));
    uint256 constant public tokensPerWei = 4224;
  	uint256 constant public Percent = 1000000000;
  	uint256  public saleStartTime ;

    uint256 internal _startSupply = 1650000 * (10 ** uint256(decimals));
    address payable public fundsWallet;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor ()  public {
        saleStartTime = now + 15 days;
        _totalSupply = _startSupply;
        fundsWallet = 0x44a95a8adF60d1f2f5a0757DECE2458E7944275b;
        _balances[msg.sender] = _startSupply;
        _balances[address(1)] = 0;
        emit Transfer(
            address(1),
            msg.sender,
            _startSupply
        );

    }
    function () external payable{
        require(tokensSold < tokensForSale, "All tokens are sold");
        require(msg.value > 0, "Value must be > 0");
        require(now < saleStartTime  , "Sale Ended");

        uint256 eth = msg.value;
        uint256 tokens = eth.mul(tokensPerWei);
        uint256 bounosTokens = getDiscountOnBuy(tokens);
		uint256 totalTokens = bounosTokens.add(tokens);
        require(totalTokens <= (tokensForSale).sub(tokensSold), "All tokens are sold");
        fundsWallet.transfer(msg.value);
        tokensSold = tokensSold.add((totalTokens));
        _totalSupply = _totalSupply.add((totalTokens));
        _balances[_msgSender()] = _balances[_msgSender()].add((totalTokens));
        emit Transfer(
            address(0),
            _msgSender(),
            totalTokens
        );
    }

    function getDiscountOnBuy(uint256 _tokensAmount) public view returns (uint256 discount) {
        uint256 tokensSoldADJ = tokensSold.mul(1000000000);
        uint256 discountPercentage = tokensSoldADJ.div(tokensForSale);
        uint256 adjustedDiscount = (Percent.sub(discountPercentage)).mul(2500);
        uint256 DiscountofTokens = (adjustedDiscount.mul(_tokensAmount));
        return((DiscountofTokens).div(10000000000000));
    }
  
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
  
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
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

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
	function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function getBalanceOf(address _user) external view returns (uint256 balance) {
        
        return _balances[_user];
    }
  
  
    
    function getBlockTimestamp () external view returns (uint blockTimestamp){
        return block.timestamp;
    }

 
}