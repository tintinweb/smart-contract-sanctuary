//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/ERC20.sol";
import "./interfaces/IERC2917.sol";
import "../../libraries/Upgradable.sol";
import "../../libraries/SafeMath.sol";
import "../../libraries/ReentrancyGuard.sol";

contract ERC2917 is
    IERC2917,
    ERC20,
    UpgradableProduct,
    UpgradableGovernance,
    ReentrancyGuard
{
    using SafeMath for uint256;

    uint256 public mintCumulation;
    uint256 public usdPerBlock;
    uint256 public lastRewardBlock;
    uint256 public totalProductivity;
    uint256 public accAmountPerShare;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => UserInfo) public users;

    // creation of the interests token.
    constructor(
        string memory name,
        string memory symbol,
        uint256 _interestsRate
    ) ERC20(name, symbol) UpgradableProduct() UpgradableGovernance() {
        usdPerBlock = _interestsRate;
    }

    // function initialize(
    //     uint256 _interestsRate,
    //     string memory _name,
    //     string memory _symbol,
    //     uint8 _decimals,
    //     address _impl,
    //     address _governor
    // ) external {
    //     impl = _impl;
    //     governor = _governor;
    //     name = _name;
    //     symbol = _symbol;
    //     decimals = _decimals;
    //     usdPerBlock = _interestsRate;
    // }

    function increment() public {
        usdPerBlock++;
    }

    function changeInterestRatePerBlock(uint256 value)
        external
        override
        requireGovernor
        returns (bool)
    {
        uint256 old = usdPerBlock;
        require(value != old, "AMOUNT_PER_BLOCK_NO_CHANGE");

        usdPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    function enter(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(this.deposit(account, amount), "INVALID DEPOSIT");
        return increaseProductivity(account, amount);
    }

    function exit(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(this.withdrawal(account, amount), "INVALID WITHDRAWAL");
        return decreaseProductivity(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(decreaseProductivity(from, amount), "INVALID DEC PROD");
        require(increaseProductivity(to, amount), "INVALID INC PROD");
    }

    function update() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(lastRewardBlock);

        uint256 reward = multiplier.mul(usdPerBlock);

        _balances[address(this)] = _balances[address(this)].add(reward);

        _totalSupply = _totalSupply.add(reward);

        accAmountPerShare = accAmountPerShare.add(
            reward.mul(1e12).div(totalProductivity)
        );
        lastRewardBlock = block.number;
    }

    function increaseProductivity(address user, uint256 value)
        internal
        returns (bool)
    {
        require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");

        UserInfo storage userInfo = users[user];
        update();
        if (userInfo.amount > 0) {
            uint256 pending = userInfo
                .amount
                .mul(accAmountPerShare)
                .div(1e12)
                .sub(userInfo.rewardDebt);
            _transfer(address(this), user, pending);
            mintCumulation = mintCumulation.add(pending);
        }

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return true;
    }

    function decreaseProductivity(address user, uint256 value)
        internal
        returns (bool)
    {
        require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

        UserInfo storage userInfo = users[user];
        require(userInfo.amount >= value, "Decrease : FORBIDDEN");
        update();
        uint256 pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(
            userInfo.rewardDebt
        );
        _transfer(address(this), user, pending);
        mintCumulation = mintCumulation.add(pending);
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return true;
    }

    function take() external view override returns (uint256) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 _accAmountPerShare = accAmountPerShare;

        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    function takeWithAddress(address user) external view returns (uint256) {
        UserInfo storage userInfo = users[user];
        uint256 _accAmountPerShare = accAmountPerShare;

        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    function takeWithBlock() external view override returns (uint256, uint256) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return (
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            ),
            block.number
        );
    }

    function mint() external override nonReentrant returns (uint256) {
        return 0;
    }

    function getProductivity(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (users[user].amount, totalProductivity);
    }

    function interestsPerBlock() external view override returns (uint256) {
        return accAmountPerShare;
    }

    function getStatus()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            lastRewardBlock,
            totalProductivity,
            accAmountPerShare,
            mintCumulation
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "../../libraries/Context.sol";
import "../../libraries/SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply = 10000;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function deposit(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        return true;
    }

    function withdrawal(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = accountBalance - amount;

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../ERC20/interfaces/IERC20.sol";

interface IERC2917 is IERC20 {
    event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);
    event ProductivityIncreased(address indexed user, uint256 value);
    event ProductivityDecreased(address indexed user, uint256 value);

    function interestsPerBlock() external view returns (uint256);

    function changeInterestRatePerBlock(uint256 value) external returns (bool);

    function getProductivity(address user)
        external
        view
        returns (uint256, uint256);

    function take() external view returns (uint256);

    function takeWithBlock() external view returns (uint256, uint256);

    function mint() external returns (uint256);

    function enter(address account, uint256 amount) external returns (bool);

    function exit(address account, uint256 amount) external returns (bool);

    function getStatus()
        external
        view
        returns (
            uint256 lastRewardBlock,
            uint256 totalProductivity,
            uint256 accAmountPerShare,
            uint256 mintCumulation
        );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() {
        impl = msg.sender;
    }

    function initializeUpgradableProduct() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, "FORBIDDEN");
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), "INVALID_ADDRESS");
        require(_newImpl != impl, "NO_CHANGE");
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(
        address indexed _oldGovernor,
        address indexed _newGovernor
    );

    constructor() {
        governor = msg.sender;
    }

    function initializeUpgradableGovernance() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, "FORBIDDEN");
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), "INVALID_ADDRESS");
        require(_newGovernor != governor, "NO_CHANGE");
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

    function deposit(address account, uint256 amount) external returns (bool);

    function withdrawal(address account, uint256 amount)
        external
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}