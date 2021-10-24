pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract PolkaWar is ERC20, ERC20Detailed, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20Detailed("PolkaWar", "PWAR", 18)
    {
        _mint(msg.sender, initialSupply);
    }
}

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PolkaWar.sol";

contract TokenRelease {
    using SafeMath for uint256;
    PolkaWar private _polkawar;
    event TokensReleased(address beneficiary, uint256 amount);
    address payable private owner;
    // beneficiary of tokens after they are released
    string public name = "PolkaWar: Token Vesting";

    struct Vesting {
        string Name;
        address Beneficiary;
        uint256 Cliff;
        uint256 Start;
        uint256 AmountReleaseInOne;
        uint256 MaxRelease;
        bool IsExist;
    }
    mapping(address => Vesting) private _vestingList;

    constructor(
        PolkaWar polkaWar,
        address team,
        address marketing,
        address eco,
        address privateFund
    ) public {
        _polkawar = polkaWar;
        _vestingList[team].Name = "Team Fund";
        _vestingList[team].Beneficiary = team;
        _vestingList[team].Cliff = 15778458;//6 month
        _vestingList[team].Start = 1625097600; //1/7/2021
        _vestingList[team].AmountReleaseInOne = 5000000*1e18;
        _vestingList[team].MaxRelease = 20000000*1e18;
        _vestingList[team].IsExist = true;

        _vestingList[marketing].Name = "Marketing Fund";
        _vestingList[marketing].Beneficiary = marketing;
        _vestingList[marketing].Cliff = 2629743;//1 month
        _vestingList[marketing].Start = 1535724800; //1/11/2021
        _vestingList[marketing]
            .AmountReleaseInOne = 1000000*1e18;
        _vestingList[marketing].MaxRelease = 20000000*1e18;
        _vestingList[marketing].IsExist = true;

        _vestingList[eco].Name = "Ecosystem Fund";
        _vestingList[eco].Beneficiary = eco;
        _vestingList[eco].Cliff =  2629743;//1 month
        _vestingList[eco].Start = 1635724800; //1/11/2021
        _vestingList[eco].AmountReleaseInOne = 1000000*1e18;
        _vestingList[eco].MaxRelease =  35000000*1e18;
        _vestingList[eco].IsExist = true;

        _vestingList[privateFund].Name = "Private Fund";
        _vestingList[privateFund].Beneficiary = privateFund;
        _vestingList[privateFund].Cliff =  2629743;//1 month
        _vestingList[privateFund].Start = 1640995200; //1/1/2022
        _vestingList[privateFund].AmountReleaseInOne = 1000000*1e18;
        _vestingList[privateFund].MaxRelease =  20000000*1e18;
        _vestingList[privateFund].IsExist = true;

        owner = msg.sender;
    }

    function depositETHtoContract() public payable {}

    function addLockingFund(
        string memory name,
        address beneficiary,
        uint256 cliff,
        uint256 start,
        uint256 amountReleaseInOne,
        uint256 maxRelease
    ) public {
        require(msg.sender == owner, "only owner can addLockingFund");
        _vestingList[beneficiary].Name = name;
        _vestingList[beneficiary].Beneficiary = beneficiary;
        _vestingList[beneficiary].Cliff = cliff;
        _vestingList[beneficiary].Start = start;
        _vestingList[beneficiary].AmountReleaseInOne = amountReleaseInOne;
        _vestingList[beneficiary].MaxRelease = maxRelease;
        _vestingList[beneficiary].IsExist = true;
    }

    function beneficiary(address acc) public view returns (address) {
        return _vestingList[acc].Beneficiary;
    }

    function cliff(address acc) public view returns (uint256) {
        return _vestingList[acc].Cliff;
    }

    function start(address acc) public view returns (uint256) {
        return _vestingList[acc].Start;
    }

    function amountReleaseInOne(address acc) public view returns (uint256) {
        return _vestingList[acc].AmountReleaseInOne;
    }

    function getNumberCycle(address acc) public view returns (uint256) {
        return
            (block.timestamp.sub(_vestingList[acc].Start)).div(
                _vestingList[acc].Cliff
            );
    }

    function getRemainBalance() public view returns (uint256) {
        return _polkawar.balanceOf(address(this));
    }

    function getRemainUnlockAmount(address acc) public view returns (uint256) {
        return _vestingList[acc].MaxRelease;
    }

    function isValidBeneficiary(address _wallet) public view returns (bool) {
        return _vestingList[_wallet].IsExist;
    }

    function release(address acc) public {
        require(acc != address(0), "TokenRelease: address 0 not allow");
        require(
            isValidBeneficiary(acc),
            "TokenRelease: invalid release address"
        );

        require(
            _vestingList[acc].MaxRelease > 0,
            "TokenRelease: no more token to release"
        );

        uint256 unreleased = _releasableAmount(acc);

        require(unreleased > 0, "TokenRelease: no tokens are due");

        _polkawar.transfer(_vestingList[acc].Beneficiary, unreleased);
        _vestingList[acc].MaxRelease -= unreleased;

        emit TokensReleased(_vestingList[acc].Beneficiary, unreleased);
    }

    function _releasableAmount(address acc) private returns (uint256) {
        uint256 currentBalance = _polkawar.balanceOf(address(this));
        if (currentBalance <= 0) return 0;
        uint256 amountRelease = 0;
        //require(_start.add(_cliff) < block.timestamp, "not that time");
        if (
            _vestingList[acc].Start.add(_vestingList[acc].Cliff) >
            block.timestamp
        ) {
            //not on time

            amountRelease = 0;
        } else {
            uint256 numberCycle = getNumberCycle(acc);
            if (numberCycle > 0) {
                amountRelease =
                    numberCycle *
                    _vestingList[acc].AmountReleaseInOne;
            } else {
                amountRelease = 0;
            }

            _vestingList[acc].Start = block.timestamp; //update start
        }
        return amountRelease;
    }

    function withdrawEtherFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }
}

pragma solidity ^0.6.0;


contract Context {
  
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";


contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

  
    function burnFrom(address account, uint256 amount) public virtual {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.6.0;

import "./IERC20.sol";


abstract contract ERC20Detailed is IERC20 {
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
}

pragma solidity ^0.6.0;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);

  
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}