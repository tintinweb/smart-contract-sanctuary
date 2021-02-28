// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./interfaces/IDeFiatPoints.sol";
import "./lib/@openzeppelin/token/ERC20/ERC20.sol";
import "./utils/DeFiatGovernedUtils.sol";

contract DeFiatPoints is ERC20("DeFiat Points v2", "DFTPv2"), IDeFiatPoints, DeFiatGovernedUtils {
    using SafeMath for uint256;

    event DiscountUpdated(address indexed user, uint256 discount);
    event TrancheUpdated(address indexed user, uint256 tranche, uint256 pointsNeeded);
    event AllTranchesUpdated(address indexed user);
    event TokenUpdated(address indexed user, address token);
    event PointsUpdated(address indexed user, address indexed subject, uint256 amount);
    event WhitelistedUpdated(address indexed user, address indexed subject, bool whitelist);
    event RedirectionUpdated(address indexed user, address indexed subject, bool redirect);

    address public token; // DFT ERC20 Token 
    
    mapping (uint256 => uint256) public discountTranches; // mapping of DFTP needed for each discount tranche
    mapping (address => uint256) private _discounts; // mapping of users to current discount, 100 = 100%
    mapping (address => uint256) private _lastTx; // mapping of users last txn
    mapping (address => bool) private _whitelisted; // mapping of addresses who are allowed to call addPoints
    mapping (address => bool) private _redirection; // addresses where points should be redirected to tx.origin, i.e. uniswap
    
    constructor(address _governance) public {
        _setGovernance(_governance);
        _mint(msg.sender, 150000 * 1e18);
    }

    // Views

    // Discounts - View the current % discount of the _address
    function viewDiscountOf(address _address) public override view returns (uint256) {
        return _discounts[_address];
    }

    // Discounts - View the discount level the _address is eligibile for
    function viewEligibilityOf(address _address) public override view returns (uint256 tranche) {
        uint256 balance = balanceOf(_address);
        for (uint256 i = 0; i <= 9; i++) {
            if (balance >= discountTranches[i]) { 
                tranche = i;
            } else {
                return tranche;
            } 
        }
    }

    // Discounts - Check amount of points needed for _tranche
    function discountPointsNeeded(uint256 _tranche) public override view returns (uint256 pointsNeeded) {
        return (discountTranches[_tranche]);
    }

    // Points - Min amount 
    function viewTxThreshold() public override view returns (uint256) {
        return IDeFiatGov(governance).viewTxThreshold();
    }

    // Points - view whitelisted address
    function viewWhitelisted(address _address) public override view returns (bool) {
        return _whitelisted[_address];
    }

    // Points - view redirection address
    function viewRedirection(address _address) public override view returns (bool) {
        return _redirection[_address];
    }

    // State-Changing Functions

    // Discount - Update Discount internal function to control event on every update
    function _updateDiscount(address user, uint256 discount) internal {
        _discounts[user] = discount;
        emit DiscountUpdated(user, discount);
    }

    // Discount - Update your discount if balance of DFTP is high enough
    // Otherwise, throw to prevent unnecessary calls
    function updateMyDiscount() public returns (bool) {
        uint256 tranche = viewEligibilityOf(msg.sender);
        uint256 discount = tranche * 10;
        require(discount != _discounts[msg.sender], "UpdateDiscount: No discount change");

        _updateDiscount(msg.sender, discount);
    }

    // Discount - Update the user discount directly, Governance-Only
    function overrideDiscount(address user, uint256 discount) external onlyGovernor {
        require(discount <= 100, "OverrideDiscount: Must be in-bounds");
        require(_discounts[user] != discount, "OverrideDiscount: No discount change");

        _updateDiscount(user, discount);
    }
    
    // Tranches - Set an individual discount tranche
    function setDiscountTranches(uint256 tranche, uint256 pointsNeeded) external onlyGovernor {
        require(tranche < 10, "SetTranche: Maximum tranche level exceeded");
        require(discountTranches[tranche] != pointsNeeded, "SetTranche: No change detected");

        discountTranches[tranche] = pointsNeeded;
        emit TrancheUpdated(msg.sender, tranche, pointsNeeded);
    }
    
    // Tranches - Set all 10 discount tranches
    function setAll10DiscountTranches(
        uint256 _pointsNeeded1, uint256 _pointsNeeded2, uint256 _pointsNeeded3, uint256 _pointsNeeded4, 
        uint256 _pointsNeeded5, uint256 _pointsNeeded6, uint256 _pointsNeeded7, uint256 _pointsNeeded8, 
        uint256 _pointsNeeded9
    ) external onlyGovernor {
        discountTranches[0] = 0;
        discountTranches[1] = _pointsNeeded1; // 10%
        discountTranches[2] = _pointsNeeded2; // 20%
        discountTranches[3] = _pointsNeeded3; // 30%
        discountTranches[4] = _pointsNeeded4; // 40%
        discountTranches[5] = _pointsNeeded5; // 50%
        discountTranches[6] = _pointsNeeded6; // 60%
        discountTranches[7] = _pointsNeeded7; // 70%
        discountTranches[8] = _pointsNeeded8; // 80%
        discountTranches[9] = _pointsNeeded9; // 90%

        emit AllTranchesUpdated(msg.sender);
    }

    // Points - Update the user DFTP balance, Governance-Only
    function overrideLoyaltyPoints(address _address, uint256 _points) external override onlyGovernor {
        uint256 balance = balanceOf(_address);
        if (balance == _points) {
            return;
        }

        _burn(_address, balance);

        if (_points > 0) {
            _mint(_address, _points);
        }
        emit PointsUpdated(msg.sender, _address, _points);
    }
    
    // Points - Add points to the _address when the _txSize is greater than txThreshold
    // Only callable by governors
    function addPoints(address _address, uint256 _txSize, uint256 _points) external onlyGovernor {
        if (!_whitelisted[msg.sender]) {
            return;
        }
        
        if(_txSize >= viewTxThreshold() && _lastTx[tx.origin] < block.number){
            if (_redirection[_address]) {
                _mint(tx.origin, _points);
            } else {
                _mint(_address, _points);
            }
            _lastTx[tx.origin] = block.number;
        }
    }
    
    // Points - Override to force update user discount on every transfer
    // Note: minting/burning does not constitute as a transfer, so we must have the update function
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        ERC20._transfer(sender, recipient, amount);

        // force update discount if not governance
        if (IDeFiatGov(governance).viewActorLevelOf(sender) == 0) {
            uint256 tranche = viewEligibilityOf(sender);
            _discounts[sender] = tranche * 10;
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

     // Gov - Set whitelist address
    function setWhitelisted(address _address, bool _whitelist) external override onlyGovernor {
        require(_whitelisted[_address] != _whitelist, "SetWhitelisted: No whitelist change");

        _whitelisted[_address] = _whitelist;
        emit WhitelistedUpdated(msg.sender, _address, _whitelist);
    }

    // Gov - Set redirection address
    function setRedirection(address _address, bool _redirect) external override onlyGovernor {
        require(_redirection[_address] != _redirect, "SetRedirection: No redirection change");

        _redirection[_address] = _redirect;
        emit RedirectionUpdated(msg.sender, _address, _redirect);
    }

    // Gov - Update the DeFiat Token address
    function setToken(address _token) external onlyGovernor {
        require(_token != token, "SetToken: No token change");

        token = _token;
        emit TokenUpdated(msg.sender, token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IDeFiatGov {
    function mastermind() external view returns (address);
    function viewActorLevelOf(address _address) external view returns (uint256);
    function viewFeeDestination() external view returns (address);
    function viewTxThreshold() external view returns (uint256);
    function viewBurnRate() external view returns (uint256);
    function viewFeeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IDeFiatPoints {
    function viewDiscountOf(address _address) external view returns (uint256);
    function viewEligibilityOf(address _address) external view returns (uint256 tranche);
    function discountPointsNeeded(uint256 _tranche) external view returns (uint256 pointsNeeded);
    function viewTxThreshold() external view returns (uint256);
    function viewWhitelisted(address _address) external view returns (bool);
    function viewRedirection(address _address) external view returns (bool);
    function setWhitelisted(address _address, bool _whitelist) external;
    function setRedirection(address _address, bool _redirect) external;
    function overrideLoyaltyPoints(address _address, uint256 _points) external;
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT





pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

// Standard ERC20
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT



pragma solidity ^0.6.0;

import "./DeFiatUtils.sol";
import "../interfaces/IDeFiatGov.sol";

abstract contract DeFiatGovernedUtils is DeFiatUtils {
    event GovernanceUpdated(address indexed user, address governance);

    address public governance;

    modifier onlyMastermind {
        require(
            msg.sender == IDeFiatGov(governance).mastermind() || msg.sender == owner(),
            "Gov: Only Mastermind"
        );
        _;
    }

    modifier onlyGovernor {
        require(
            IDeFiatGov(governance).viewActorLevelOf(msg.sender) >= 2 || msg.sender == owner(),
            "Gov: Only Governors"
        );
        _;
    }

    modifier onlyPartner {
        require(
            IDeFiatGov(governance).viewActorLevelOf(msg.sender) >= 1 || msg.sender == owner(),
            "Gov: Only Partners"
        );
        _;
    }

    function _setGovernance(address _governance) internal {
        require(_governance != governance, "SetGovernance: No governance change");

        governance = _governance;
        emit GovernanceUpdated(msg.sender, governance);
    }

    function setGovernance(address _governance) external onlyGovernor {
        _setGovernance(_governance);
    }
}

// SPDX-License-Identifier: MIT





pragma solidity ^0.6.0;

import "../lib/@openzeppelin/token/ERC20/IERC20.sol";
import "../lib/@openzeppelin/access/Ownable.sol";

abstract contract DeFiatUtils is Ownable {
    event TokenSweep(address indexed user, address indexed token, uint256 amount);

    // Sweep any tokens/ETH accidentally sent or airdropped to the contract
    function sweep(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Sweep: No token balance");

        IERC20(token).transfer(msg.sender, amount); // use of the ERC20 traditional transfer

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        emit TokenSweep(msg.sender, token, amount);
    }

    // Self-Destruct contract to free space on-chain, sweep any ETH to owner
    function kill() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}