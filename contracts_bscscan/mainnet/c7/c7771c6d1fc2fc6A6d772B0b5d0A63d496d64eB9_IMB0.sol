/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity 0.5.16;

    interface IBEP20 {
      
      function totalSupply() external view returns (uint256);

      function decimals() external view returns (uint256);

      function symbol() external view returns (string memory);

      function name() external view returns (string memory);

      function getOwner() external view returns (address);

      function balanceOf(address account) external view returns (uint256);

      function transfer(address recipient, uint256 amount) external returns (bool);

      function allowance(address _owner, address spender) external view returns (uint256);

      function approve(address spender, uint256 amount) external returns (bool);

      function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

      event Transfer(address indexed from, address indexed to, uint256 value);

      event Approval(address indexed owner, address indexed spender, uint256 value);
    }

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
        // Solidity only automatically asserts when dividing by 0
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

    contract Ownable is Context {
      address private _owner;

      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

      /**
      * @dev Initializes the contract setting the deployer as the initial owner.
      */
      constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
      }

      /**
      * @dev Returns the address of the current owner.
      */
      function owner() public view returns (address) {
        return _owner;
      }

      
      modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
      }

      function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
      }

      function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
      }

      function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
      }
    }

    contract IMB0 is Context, IBEP20, Ownable {
      using SafeMath for uint256;

      mapping (address => uint256) private _balances;

      mapping (address => mapping (address => uint256)) private _allowances;

      uint256 private _totalSupply;
      uint8 public _decimals;
      string public _symbol;
      string public _name;

      constructor() public {
        _name = "BRICKTO IMOB 00";
        _symbol = "IMB0";
        _decimals = 9;
        _totalSupply = 500000000000000;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
      }

      function getOwner() external view returns (address) {
        return owner();
      }

      function decimals() external view returns (uint256) {
        return _decimals;
      }

      function symbol() external view returns (string memory) {
        return _symbol;
      }

      function name() external view returns (string memory) {
        return _name;
      }

      /**
      * @dev See {BEP20-totalSupply}.
      */
      function totalSupply() external view returns (uint256) {
        return _totalSupply;
      }

      function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
      }
      
      function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
      }

      function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
      }

      function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
      }

      function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
      }

      function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
      }

      function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
      }

      function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
      }

      function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
      }
    }