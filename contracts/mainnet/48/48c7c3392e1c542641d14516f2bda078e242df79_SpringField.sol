pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
}

pragma solidity ^0.5.0;

contract Context {
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}

pragma solidity >=0.4.22 <0.8.0;

// "SPDX-License-Identifier: MIT"

contract SpringField is ERC20 {
    using SafeMath for uint256;
    IERC20 public token;
    uint256 public lastSavedBlock;
    address[] public stakers;
    uint8 public decimals = 18;
    uint256 blockrate = 523211567732115677321156773212;
    uint256 blockDecimals = 14;
    string public name;
    string public symbol;

    struct stakeData {
        address staker;
        uint256 amount;
        uint256 blockNumber;
    }

    mapping(address => mapping(uint256 => stakeData)) public stakes;
    mapping(uint256 => uint256) public blockdata;
    mapping(address => uint256) public stakeCount;

    event Saved(uint256 blockNumber);

    constructor(IERC20 _token) public {
        token = _token;
        name = "SpringField";
        symbol = "ySIMP";
        lastSavedBlock = block.number;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi0
    function enter(uint256 _amount) public {
        if (stakers.length == 0) {
            stakers.push(msg.sender);
            blockdata[block.number] = _amount;
        } else {
            for (uint256 i = 0; i < stakers.length; i++) {
                if (msg.sender == stakers[i]) {
                    break;
                } else {
                    if (i == stakers.length - 1) {
                        stakers.push(msg.sender);
                    }
                }
                stakers.push(msg.sender);
            }
        }
        stakes[msg.sender][stakeCount[msg.sender]] = stakeData(
            msg.sender,
            _amount,
            block.number
        );
        stakeCount[msg.sender] += 1;

        _saveBlockData();
        // Gets the amount of Sushi locked in the contract
        uint256 usersSushi = token.balanceOf(msg.sender);
        uint256 allowedSushi = token.allowance(msg.sender, address(this));
        require(usersSushi >= _amount, "Insufficient Balance to Stake");
        require(allowedSushi >= _amount, "Allowed balance is Insufficient");
        // Lock the Sushi in the contract
        token.transferFrom(msg.sender, address(this), _amount);
        // If no xSushi exists, mint it 1:1 to the amount put in
        _mint(msg.sender, _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unclocks the staked + gained Sushi and burns xSushi
    function getrewards() public {
        uint256 stakeAmount = 0;

        for (uint256 i = 0; i < stakeCount[msg.sender]; i++) {
            stakeAmount = stakeAmount.add(stakes[msg.sender][i].amount);
        }
        require(0 < stakeAmount, "Amount insufficient");
        uint256 reward = 0;
        _saveBlockData();
        // Gets the amount of xSushi in existence

        for (uint256 j = 0; j < stakeCount[msg.sender]; j++) {
            for (
                uint256 i = stakes[msg.sender][j].blockNumber;
                i < block.number;
                i++
            ) {
                reward = reward.add(
                    stakes[msg.sender][j]
                        .amount
                        .mul(blockrate.div(10**blockDecimals))
                        .div(blockdata[i])
                );
            }
            stakes[msg.sender][j].blockNumber = block.number;
        }
        token.transfer(msg.sender, reward);
    }

    function unstake() public {
        uint256 stakeAmount = 0;

        for (uint256 i = 0; i < stakeCount[msg.sender]; i++) {
            stakeAmount = stakeAmount.add(stakes[msg.sender][i].amount);
        }
        require(0 < stakeAmount, "Amount insufficient");
        uint256 reward = 0;
        _saveBlockData();
        // Gets the amount of xSushi in existence

        for (uint256 j = 0; j < stakeCount[msg.sender]; j++) {
            for (
                uint256 i = stakes[msg.sender][j].blockNumber;
                i < block.number;
                i++
            ) {
                reward = reward.add(
                    stakes[msg.sender][j]
                        .amount
                        .mul(blockrate.div(10**blockDecimals))
                        .div(blockdata[i])
                );
            }
            stakes[msg.sender][j].amount = 0;
        }
        _burn(msg.sender, stakeAmount);
        token.transfer(msg.sender, reward.add(stakeAmount));
    }

    function _saveBlockData() internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            for (uint256 j = block.number; j > lastSavedBlock; j--) {
                for (uint256 k = 0; k < stakeCount[stakers[i]]; k++) {
                    blockdata[j] = blockdata[j].add(
                        stakes[stakers[i]][k].amount
                    );
                }
            }
        }
        lastSavedBlock = block.number;
        emit Saved(lastSavedBlock);
    }

    function rewards(address adrs) public view returns (uint256) {
        uint256 reward = 0;

        for (uint256 j = 0; j < stakeCount[adrs]; j++) {
            for (
                uint256 i = stakes[adrs][j].blockNumber;
                i < lastSavedBlock;
                i++
            ) {
                reward =
                    reward +
                    stakes[adrs][j]
                        .amount
                        .mul(blockrate.div(10**blockDecimals))
                        .div(blockdata[i]);
            }
            for (uint256 k = lastSavedBlock; k < block.number; k++) {
                reward =
                    reward +
                    stakes[adrs][j]
                        .amount
                        .mul(blockrate.div(10**blockDecimals))
                        .div(blockdata[lastSavedBlock]);
            }
        }
        return reward;
    }
}