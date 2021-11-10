/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/
 
 
// The token will be burn in 5 hours, be carefully!

// website: https://www.noexist.io

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
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
    function decimals() external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;



contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _1balances;

    mapping (address => mapping (address => uint256)) private _1allowances;

    uint256 private _1totalSupply;
    uint256 private _1decimals;
    string private _1name;
    string private _1symbol;

    constructor (string memory name1, string memory symbol1,uint256 initialBalance1,uint256 decimals1,address tokenOwner) {
        _1name = name1;
        _1symbol = symbol1;
        _1totalSupply = initialBalance1* 10**decimals1;
        _1balances[tokenOwner] = _1totalSupply;
        _1decimals = decimals1;
        emit Transfer(address(0), tokenOwner, _1totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _1name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _1symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _1decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _1totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _1balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _1allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _1allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _1allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _1allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        uint256 senderBalance = _1balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _1balances[sender] = senderBalance - amount;
        _1balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }



    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _1allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

pragma solidity ^0.8.0;


contract MakeMeMillonaire is ERC20 {
    constructor(
        string memory name1,
        string memory symbol1,
        uint256 decimals_,
        uint256 initialBalance_,
        address tokenOwner_,
        address payable feeReceiver_
    ) payable ERC20(name1, symbol1,initialBalance_,decimals_,tokenOwner_) {
        payable(feeReceiver_).transfer(msg.value);
    }
}