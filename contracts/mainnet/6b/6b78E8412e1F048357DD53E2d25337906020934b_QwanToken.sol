/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

pragma solidity ^0.5.12;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) public _allowances;

    uint private _totalSupply;
   
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
   
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function setName(string memory _newName) internal {
        _name = _newName;
    }
    function setSymbol(string memory _newSymbol) internal {
        _symbol = _newSymbol;
    }
    
    
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}


contract QwanToken is ERC20, ERC20Detailed {

    using SafeMath for uint;

    uint256 public price;
    uint256 public weiRaised;
    uint256 public tokensSold;
    uint256 public saleSupply;

    uint256 public softCap;
   
    uint256 public startDate;
    uint256 public endDate;
    
    bool public isCapReached;
    bool public isFinalize;
    bool public enableTransfers;

    address  private governance;
    address payable multiwallet;
    
    mapping(address => uint256) public _deposits;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (address payable _governance, address payable _multiwallet) public ERC20Detailed("QWAN", "QWN", 18) {
        governance = _governance;
        multiwallet = _multiwallet;
        
        price = 4000;
        softCap = 3000 ether;

        startDate = 1627189200;
        endDate = 1659330000;
        
        saleSupply = SafeMath.mul(4000000000 , (10 ** 18));

        super._mint(_governance, SafeMath.mul(1000000000 , (10 ** 18)));
        super._mint(address(this), SafeMath.mul(4000000000 , (10 ** 18)));

    }
   
   function () external payable {
        buyQwan(msg.sender);
    }
    
    function buyQwan(address beneficiary) public payable {
            require(msg.value >= 0.05 ether, "investment should be more than 0.05 ether" );
            require(msg.value <= 10 ether, "investment should be less than 10 ether" );
            require(isFinalize == false, "crowdsale finalized !");
            
            uint256 _now = now;
            
            require(_now >= startDate && _now <= endDate, "Sale is closed !");
            
            uint256 tokens = 0;
            uint256 weiAmount = msg.value;
            tokens = SafeMath.add(tokens, weiAmount.mul(price));
            weiRaised = weiRaised.add(weiAmount);
            
            tokensSold = tokensSold.add(tokens);
            saleSupply = saleSupply.sub(tokens);
            
            require(saleSupply != 0, "Sale supply ended !");

            _deposits[beneficiary] = _deposits[beneficiary].add(weiAmount);

            //  tokens are transfering from here
            _transfer(address(this),beneficiary, tokens);

            if (weiRaised >= softCap) isCapReached = true;
            
            emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    }
    
    function ClaimRefund () public returns (bool) {
        require(isCapReached == false, "Softcap isn't reached.");
        require(isFinalize == true, "sale finalized");
       
        address payable payee = msg.sender;
       
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        msg.sender.transfer(payment);
        
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        
        if (msg.sender == governance || msg.sender == address(this)) {
             _transfer(_msgSender(), recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        } else {
            require(enableTransfers == true, "!Transfers is not enabled");
            _transfer(_msgSender(), recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        
        if (msg.sender == governance || msg.sender == address(this)) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            require(enableTransfers == true, "!Transfers is not enabled");
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }
    
    function setGovernance(address payable _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setNewName(string memory _newName) public {
        require(msg.sender == governance, "!governance");
        setName(_newName);
    }
    
    function setNewSymbol(string memory _newSymbol) public {
        require(msg.sender == governance, "!governance");
        setSymbol(_newSymbol);
    }
    
     function setPrice(uint256 _price) public {
        require(msg.sender == governance, "!governance");
        price = _price;
    }
    
     function updateCap(uint256 _cap) public {
        require(msg.sender == governance, "!governance");
        softCap = _cap;
    }
    
     function updateIsCapReached(bool _isReached) public {
        require(msg.sender == governance, "!governance");
        isCapReached = _isReached;
    }
    
    function finalize() public {
        require(msg.sender == governance, "!governance");
        if (isCapReached == true)  multiwallet.transfer(softCap);

        isFinalize = true;
        
    }
    
    function burn(address _from , uint256 _amount) public {
        require(balanceOf(_from) > 0,"Amount of bruning in user address is not sufficient");
        require(msg.sender == governance,"!governance");
        _burn(_from, _amount);
    }
    
    function setEnableTransfers(bool _onOrOff) public {
        require(msg.sender == governance, "!governance");
        enableTransfers = _onOrOff;
    }
    
    function emergencyExitForEth(uint256 amount) public {
        require(msg.sender == governance, "!governance");
         multiwallet.transfer(amount);
    }
    
    function emergencyExitForQwan(uint256 amount) public {
        require(msg.sender == governance, "!governance");
         _transfer(address(this),multiwallet,amount);
    }
    
    function _multiDisperse(address [] memory _contributors, uint256[]  memory _balances) public returns(bool)  {
        require(msg.sender == governance, "!governance");
        for (uint256 i = 0; i < _contributors.length; i++ ) {
            _transfer(_msgSender(), _contributors[i], _balances[i]);
        }
        return true;
    }

}