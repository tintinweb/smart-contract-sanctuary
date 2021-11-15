//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

import "./utils/Context.sol";
import "./security/ReentrancyGuard.sol";
import "./interface/IOracle.sol";
import "./interface/IERC20.sol";

contract INRT is Context, ReentrancyGuard {
    address public DAI;
    address public Oracle;

    string public name = "Stable INR";
    string public symbol = "INRT";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;

    /**
     * DAI Testing for Kovan :
     * 0x9cd539ac8dca5757efac30cd32da20cd955e0f8b
     *
     * INR-DAI Price Oracle:
     * 0x2275Bad4e366eE3AE0bA4daABE31c014cCD39bd9
     */
    constructor() public {
        DAI = 0x9CD539Ac8Dca5757efAc30Cd32da20CD955e0f8B;
        Oracle = 0x2275Bad4e366eE3AE0bA4daABE31c014cCD39bd9;
    }

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _deposits;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    function mint(uint256 _dai) public virtual nonReentrant returns (uint256) {
        uint256 balance = IERC20(DAI).balanceOf(_msgSender());
        require(balance >= _dai, "Error: insufficient dai balance");

        uint256 allowance = IERC20(DAI).allowance(_msgSender(), address(this));
        require(allowance >= _dai, "Error: insufficient allowance");

        uint256 price = IOracle(Oracle).rupeePrice();
        uint256 amount = (_dai * price) / 10**2;

        _balances[_msgSender()] += amount;
        _deposits[_msgSender()] += _dai;

        totalSupply += amount;
        IERC20(DAI).transferFrom(_msgSender(), address(this), _dai);

        emit Transfer(address(0), _msgSender(), amount);
        return amount;
    }

    function redeem(uint256 _inrt)
        public
        virtual
        nonReentrant
        returns (uint256)
    {
        uint256 allowance = _allowances[_msgSender()][address(this)];
        uint256 balance = _balances[_msgSender()];
        require(balance >= _inrt, "Error: insufficient inrt balance");
        require(allowance >= _inrt, "Error: insufficient allowance");

        uint256 _dai = (_deposits[_msgSender()] * _inrt) / balance;

        _deposits[_msgSender()] -= _dai;
        totalSupply -= _inrt;

        transferFrom(_msgSender(), address(this), _inrt);
        transfer(address(0), _inrt);
        IERC20(DAI).transfer(_msgSender(), _dai);

        return _dai;
    }

    function balanceOf(address user) public view virtual returns (uint256) {
        return _balances[user];
    }

    function depositOf(address user) public view virtual returns (uint256) {
        return _deposits[user];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        require(
            _balances[_msgSender()] >= amount,
            "Error: insufficient balance"
        );

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowance = _allowances[_from][_msgSender()];
        uint256 balance = _balances[_from];
        require(balance >= amount, "Error: insufficient inrt balance");
        require(allowance >= amount, "Error: insufficient allowance");

        _balances[_from] -= amount;
        _balances[_to] += amount;

        _allowances[_from][_msgSender()] -= amount;

        emit Transfer(_from, _to, amount);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _allowances[_msgSender()][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[_owner][_spender];
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.6.0;

/**
 * @dev provides information about the current execution context.
 *
 * This includes the sender of the transaction & it's data.
 * Useful for meta-transaction as the message sender & gas payer can be different.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.6.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.6.0;

interface IOracle {
    function rupeePrice() external view returns (uint256);

    function requestRupeePrice() external returns (bytes32 requestId);

    function requestAll() external;

    function fulfillRupee(bytes32 _requestId, uint256 _price) external;
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.6.0;

/**
 * Interface of ZNFT Shares ERC20 Token As in EIP
 */

interface IERC20 {
    /**
     * @dev returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

