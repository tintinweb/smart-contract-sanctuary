//SourceUnit: HTC.sol

pragma solidity ^0.5.10;

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Should be greater than zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "should be less than other");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Should be greater than c");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divide by 0");
        return a % b;
    }
}

//**************************************************************************//
//------------------------  HTC TYCOON CONTRACT    -------------------//

//-------------------------- Name - TYCOON HTC --------------------------------//
//-------------------------- Symbol - HTC --------------------------------//
//-------------------------- Total Supply - 12500000 -----------------//
//-------------------------- Decimal - 2 --------------------------------//
//***********************************************************************//  


contract HTC {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _initialSupply;
    address public owner;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        _name = "TYCOON HTC";
        _symbol = "HTC";
        _decimals = 2;
        _initialSupply = 12500000;
        _totalSupply = _initialSupply * 10**uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Owner Rights");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function decimals() public view returns (uint256) {
       return _decimals;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address spender) external view returns (uint256) {
        return _allowed[_owner][spender];
    }
    

    function transfer(address to, uint256 value) external returns (bool) {
        require(value <= _balances[msg.sender] && value > 0, "Insufficient Balance");
        _transfer(msg.sender, to, value);
        return true;
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Address zero");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
         require(value <= _balances[from], "Sender Balance Insufficient");
         require(value <= _allowed[from][msg.sender], "Token should be same as alloted");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function burn(address _from, uint256 _value) public onlyOwner returns (bool) {
        _burn(_from, _value);
        return true;
    }

    function mint(uint256 _value) public onlyOwner returns (bool){
        _mint(msg.sender, _value);
        return true;
    }

    function withdraw(address payable _adminAccount, uint256 _amount) public  onlyOwner returns (bool) {
        _adminAccount.transfer(_amount);
        return true;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function transferOwner(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "address zero");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }


    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "address zero");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}