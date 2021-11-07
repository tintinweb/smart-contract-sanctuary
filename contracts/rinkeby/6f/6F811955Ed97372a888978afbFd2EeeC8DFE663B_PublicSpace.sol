// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PUBL/ERC20.sol";
import "./PUBL/INonFungibleToken.sol";

/**
 * @title PublicSpace contract
 *
 * @dev Extends ERC20 standard
 */
contract PublicSpace is ERC20 {
    receive() external payable {}
    fallback() external payable {}

    mapping (address => uint256) private withdrawLimit;

    uint256 _deposit;
    uint256 counter = 0;

    INonFungibleToken nft;

    /**
     * @dev Sets the value for {_contractAddress}
     */
    constructor(address _contractAddress) ERC20("Public Space", "PUBL") {
        nft = INonFungibleToken(_contractAddress);
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    /**
     * @dev Returns PUBL contract balance
     */
    function treasury() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns PUBL contract balance as a percent
     */
    function percent() public view returns (uint256) {
        if (_deposit != 0) {
            uint256 _percent = (treasury() / _deposit) * 100;
            return _percent;
        }
        else {
            return 0;
        }
    }

    /**
     * @dev Returns NonFungibleToken contract balance
     */
    function revenue() public view returns (uint256) {
        return nft.balance();
    }

    /**
     * @dev Deposits NonFungibleToken balance into the PublicSpace contract
     *
     * Emits a {Deposit} event
     */
    function deposit() public {
        if (percent() < 51) {
            address account = msg.sender;
            nft.withdraw();
            _deposit = address(this).balance;
            counter += 1;

            emit Deposit(account, _deposit);
        }
    }

    event Deposit(address account, uint256 _deposit);

    /**
     * @dev Returns available dividend funds for `account`
     */
    function dividendBalance(address account) public view returns (uint256) {
        if (withdrawLimit[account] != counter) {
            uint256 funds = (balanceOf(account) * _deposit) / totalSupply();
            return funds;
        }
        else {
            return 0;
        }
    }

    /**
     * @dev Withdraws dividend for token holder
     *
     * Emits a {Withdrawal} event
     */
    function dividendPayout() public {
        if (withdrawLimit[msg.sender] != counter) {
            withdrawLimit[msg.sender] = counter;
            address account = msg.sender;
            uint256 funds = (balanceOf(msg.sender) * _deposit) / totalSupply();
            (bool success, ) = payable(msg.sender).call{value: funds}("");
            require(success, "Ether transfer failed.");

            emit Withdrawal(account, funds);
        }
    }

    event Withdrawal(address account, uint256 funds);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface
 */
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;

    uint256 private _totalSupply;

    /**
     * @dev Sets the values for {name} and {symbol}
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals places of the token
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the amount of tokens in existence
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {_transfer}
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, msg.sender, currentAllowance - amount);}

        return true;
    }

    /**
     * @dev See {_approve}
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through `transferFrom`
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);

        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(msg.sender, spender, currentAllowance - subtractedValue);}

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`
     *
     * Emits a {Transfer} event
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account` and increases the total supply
     *
     * Emits a {Transfer} event with `from` set to the zero address
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account` and reduces the total supply
     *
     * Emits a {Transfer} event with `to` set to the zero address
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[account] = accountBalance - amount;}
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` tokens
     *
     * Emits an {Approval} event
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the NonFungibleToken contract for PublicSpace
 */
interface INonFungibleToken {
    /**
     * @dev NonFungibleToken contract functions
     */
    function balance() external view returns (uint256);

    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP
 */
interface IERC20 {
    /**
     * @dev ERC20 standard functions
     */
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev ERC20 standard events
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}