//SourceUnit: BaseTRC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./ITRC20.sol";
import "./SafeMath.sol";

/**
Contract function to receive approval and execute function in one call
*/
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}


abstract contract TRC20 is ITRC20{
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    address internal _mainWallet;
    
    // ------------------------------------------------------------------------
    // Constructor
    // initSupply = 10TTS
    // ------------------------------------------------------------------------
    constructor() internal {
        symbol = "TTS";
        name = "Trusted Team Smart";
        decimals = 6;
        _totalSupply = 10 * 10**6;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender, 
            _allowances[msg.sender][spender].sub(subtractedValue,
            "TRC20: decreased allowance below zero")
        );
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address recipent, uint256 amount) internal {
        uint256 fee = amount.div(100);
            
        _balances[_mainWallet] = _balances[_mainWallet].add(fee);
        _balances[recipent] = _balances[recipent].add(amount);
        _totalSupply = _totalSupply.add(amount.add(fee));
        emit Transfer(address(0), _mainWallet, fee);
        emit Transfer(address(0), recipent, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _burn(address sender, uint256 amount) internal {
        require(sender != address(0), "TRC20: burn from the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(sender, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}




//SourceUnit: ITRC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
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

}



//SourceUnit: TTS.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./ITRC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./BaseTRC20.sol";

contract TTSToken is TRC20, Ownable {
    using SafeMath for uint256;
    
    ITRC20 public USDC_contract;

    uint256 public currentCoef = 100000; // /10000000


    event Sell(address indexed seller, uint256 TTSAmount, uint256 USDCAmount, uint256 price);
    event Buy(address indexed buyer, uint256 TTSAmount, uint256 USDCAmount, uint256 price);

    constructor(address mainWallet, address USDC) public {
        _mainWallet = mainWallet;
        USDC_contract = ITRC20(USDC);
    }
    
    //pays USDC gets TTS
    function buyToken(address _to, uint256 USDCAmount) public returns(uint256 TTSAmount,  uint256 price) {
        price = getSellPrice();
        if (currentCoef > 0)
            price = price.mul(10000000 + currentCoef).div(10000000);
        USDC_contract.transferFrom(msg.sender, address(this), USDCAmount);
        
        TTSAmount = USDCAmount.mul(1e24).div(price);

        if (TTSAmount > 0) {
            _mint(_to, TTSAmount);   
            emit Buy(_to, TTSAmount, USDCAmount, price);
        }
        return (TTSAmount, price);
    }

    function changeMainWallet(address mainWallet) public onlyOwner {
        require(mainWallet != address(0), "new mainWallet is the zero address");
        _mainWallet = mainWallet;
    }

    function setCoef(uint256 coef) public onlyOwner {
        require(coef <= 1000000);
        currentCoef = coef;
    }
    
    //pays TTS gets USDC
    function sellToken(address _to, uint256 amount) public returns(uint256 USDCAmount,  uint256 price) {
        price = getSellPrice();
        _burn(msg.sender, amount);
        USDCAmount = amount.mul(price).div(1e24);
        USDC_contract.transfer(_to, USDCAmount);

        emit Sell(_to, amount, USDCAmount, price);

        return (USDCAmount, price);
    }
    
    // decimals : 24
    function getSellPrice() public view returns(uint256 price) {
        uint256 balance = getUSDCBalance().mul(1e24);
        return balance.div(_totalSupply.sub(balanceOf(address(this))));
    }
 
    function getUSDCBalance() public view returns (uint256) {
        return USDC_contract.balanceOf(address(this));
    }

    
    function getBuyPrice() public view returns (uint256 price) {
        return getSellPrice().mul(10000000 + currentCoef).div(10000000);
    }
}