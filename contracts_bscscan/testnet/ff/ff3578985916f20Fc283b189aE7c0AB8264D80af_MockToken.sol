/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
interface IBEP20 {
        function mint(address account, uint256 amount) external;
        function burn(address account, uint256 amount) external;
        /**
        * @dev Returns the amount of tokens in existence.
        */
        function totalSupply() external view returns (uint256);

        /**
        * @dev Returns the amount of tokens owned by `account`.
        */
        function balanceOf(address account) external view returns (uint256);
        /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transfer(address recipient, uint256 amount) external returns (bool);
        /**
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve} or {transferFrom} are called.
        */
        function allowance(address owner, address spender) external view returns (uint256);

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
        function approve(address spender, uint256 amount) external returns (bool);

        /**
        * @dev Moves `amount` tokens from `sender` to `recipient` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        /**
        * @dev Emitted when `value` tokens are moved from one account (`from`) to
        * another (`to`).
        *
        * Note that `value` may be zero.
        */
        event Transfer(address indexed from, address indexed to, uint256 value);
        /**
        * @dev Emitted when the allowance of a `spender` for an `owner` is set by
        * a call to {approve}. `value` is the new allowance.
        */
        event Approval(
                address indexed owner,
                address indexed spender,
                uint256 value
        );
}

library SafeMath {
        /**
        * @dev Multiplies two numbers, throws on overflow.
        */
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
                if (a == 0) {
                        return 0;
                }
                uint256 c = a * b;
                require(c / a == b, 'INVALID_MUL');
                return c;
        }

        /**
        * @dev Integer division of two numbers, truncating the quotient.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
                require(b > 0, 'INVALID_DIV'); // Solidity automatically throws when dividing by 0
                uint256 c = a / b;
                // assert(a == b * c + a % b); // There is no case in which this doesn't hold
                return c;
        }

        /**
        * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
        */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                require(b <= a, 'INVALID_SUB');
                return a - b;
        }
        /**
        * @dev Adds two numbers, throws on overflow.
        */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a + b;
                require(c >= a, 'INVALID_ADD');
                return c;
        }
}

contract MockToken is IBEP20 {
	using SafeMath for uint256;
        address public owner;
	mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;
        uint256 private _totalSupply;
        string public name;
        string public symbol;
        uint8 public decimals = 18;

        constructor(string memory name_, string memory symbol_) public 
        {
                owner = msg.sender;
                name = name_;
                symbol = symbol_;
        }
        function totalSupply() public override view returns (uint256) 
        {
                return _totalSupply;
        }
        function balanceOf(address _addr) public override view returns (uint256) 
        {
                return _balances[_addr];
        }
        function allowance(address _owner, address _spender) public virtual override view returns (uint256)
        {
                return _allowances[_owner][_spender];
        }
        function mint(address account, uint256 amount) public virtual override 
        {
                require(account != address(0), 'BEP20: mint to the zero address');
                _totalSupply = _totalSupply.add(amount);
                _balances[account] = _balances[account].add(amount);
                emit Transfer(address(0), account, amount);
        }
        function burn(address account, uint256 amount) public virtual override  
        {
                _balances[account] = _balances[account].sub(amount);
                _totalSupply = _totalSupply.sub(amount);
                emit Transfer(account, address(0), amount);
        }

        function approve(address _spender, uint256 _amount) public virtual override returns (bool)
        {
                require(_spender != address(0), "INVALID_SPENDER");
                _allowances[msg.sender][_spender] = _amount;
                emit Approval(msg.sender, _spender, _amount);
                return true;
        }
        function transfer(address _to, uint256 _amount) public virtual override returns (bool)
        {
                require(_amount > 0, 'INVALID_AMOUNT');
                require(_balances[msg.sender] >= _amount, 'INVALID_BALANCE');
                _balances[msg.sender] = _balances[msg.sender].sub(_amount);
                _balances[_to]        = _balances[_to].add(_amount);
                /*------------------------ emit event ------------------------*/
                emit Transfer(msg.sender, _to, _amount);
                /*----------------------- response ---------------------------*/
                return true;
        }
        function transferFrom(
                address _from,
                address _to,
                uint256 _amount
        ) public virtual override returns (bool) {
                require(_amount > 0, 'INVALID_AMOUNT');
                require(_balances[_from] >= _amount, 'INVALID_BALANCE');
                require(_allowances[_from][msg.sender] >= _amount, 'INVALID_PERMISTION');
                _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_amount);
                _balances[_from]    = _balances[_from].sub(_amount);
                _balances[_to]      = _balances[_to].add( _amount);
                /*------------------------ emit event ------------------------*/
                emit Transfer(_from, _to, _amount);
                /*----------------------- response ---------------------------*/
                return true;
        }
}