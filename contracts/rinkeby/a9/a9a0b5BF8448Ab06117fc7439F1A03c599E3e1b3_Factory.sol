// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Child.sol";
import "./CloneFactory.sol";

contract Factory is CloneFactory {
    Child[] public children;
    address masterContract;

    constructor(address _masterContract) {
        masterContract = _masterContract;
    }

    function createChild(uint256 _data, string memory _name, string memory _symbol, uint8 _decimals) external {
        Child child = Child(createClone(masterContract));
        child.init(_name, _symbol, _decimals, _data);
        // child.name();
        children.push(child);
       
    }

    function getChildren() external view returns (Child[] memory) {
        return children;
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/SafeMath.sol";
import "./ERC20.sol";


contract Child is ERC20 {
    using SafeMath for uint;
         constructor() ERC20()  {
       _mint(msg.sender, 10000 * (10 ** 18));
    }
    //  constructor(
    //     string memory name,
    //     string memory symbol,
    //     address mintTo,
    //     uint256 supply
    // ) ERC20(name, symbol) {
    //     _mint(mintTo, supply);
    // }
    //     constructor() ERC20("MinhToken", "MTK")  {
    //    _mint(msg.sender, 10000 * (10 ** 18));
    // }
    uint256 public data;

    // use this function instead of the constructor
    // since creation will be done using createClone() function
    function init(string memory _name, string memory _symbol, uint8 _decimals, uint256 _data) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        data = _data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }
    /**
        * @dev Returns the subtraction of two unsigned integers, reverting on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    string public override name;
    string public override symbol;
    uint8 public override decimals = 18;
    uint256 public  _totalSupply;

    mapping(address => uint256) public override balanceOf;

    // mapping(address => mapping(address => uint)) override public allowance;

    // constructor() {

    // }

    function initializeERC20() public {

    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // function _transfer(address from, address to, uint value) internal {
    //     require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
    //     balanceOf[from] = balanceOf[from].sub(value);
    //     balanceOf[to] = balanceOf[to].add(value);
    //     if (to == address(0)) {
    //         // burn
    //         totalSupply = totalSupply.sub(value);
    //     }
    //     emit Transfer(from, to, value);
    // }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
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

        uint256 senderBalance = balanceOf[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // function approve(address spender, uint value) external override returns (bool) {
    //     allowance[msg.sender][spender] = value;
    //     emit Approval(msg.sender, spender, value);
    //     return true;
    // }

    // function transferFrom(address from, address to, uint value) external override returns (bool) {
    //     require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
    //     allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    //     _transfer(from, to, value);
    //     return true;
    // }

    // function transfer(address to, uint value) external override returns (bool) {
    //     _transfer(msg.sender, to, value);
    //     return true;
    // }

    // function deposit(address account, uint256 amount)
    //     external
    //     override
    //     returns (bool)
    // {
    //     require(account != address(0), "ERC20: mint to the zero address");

    //     balanceOf[account] += amount;
    //     _totalSupply = totalSupply.add(amount);

    //     emit Transfer(address(0), account, amount);
    //     return true;
    // }

    // function withdrawal(address account, uint256 amount)
    //     external
    //     override
    //     returns (bool)
    // {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     uint256 accountBalance = balanceOf[account];
    //     require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

    //     balanceOf[account] = accountBalance - amount;

    //     totalSupply = totalSupply.sub(amount);

    //     emit Transfer(account, address(0), amount);
    //     return true;
    // }

   

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
     /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    // function allowance(address owner, address spender) external view returns (uint);

    /**
        * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    // function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    // function deposit(address account, uint256 amount) external returns (bool);
    // function withdrawal(address account, uint256 amount) external returns (bool);
}

