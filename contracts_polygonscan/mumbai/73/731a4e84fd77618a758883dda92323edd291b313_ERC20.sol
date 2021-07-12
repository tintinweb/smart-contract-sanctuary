/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.5.0;


//Slightly modified SafeMath library - includes a min and max function, removes useless div function
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a + b;
            assert(c >= a);
        } else {
            c = a + b;
            assert(c <= a);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (uint256) {
        return a > b ? uint256(a) : uint256(b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a - b;
            assert(c <= a);
        } else {
            c = a - b;
            assert(c >= a);
        }

    }
}


/**
 * @dev Implementation of the ERC20 contract.
 */
contract ERC20 {
    using SafeMath for uint256;

    mapping (address => Checkpoint[]) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    uint256 private _totalSupply;

    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }

    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //ERC20 Transfer Event
    
    /**
    * returns total supply.
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * Gets a users balance
    */
    function balanceOf(address account) public view returns (uint256) {
        return balanceOfAt(account, block.number);
    }

    /**
    * transfers an amount.
    * Requirements:
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        doTransfer(msg.sender, recipient, amount);
        return true;
    }

    /**
    * @dev See `IERC20.allowance`.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
    * @dev See `IERC20.approve`.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
    * Emits an `Approval` event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of `ERC20`;
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `value`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Allowance is wrong");
        _allowances[sender][msg.sender] -= amount;
        doTransfer(sender, recipient, amount);
        return true;
    }


    /**
    * @dev Completes POWO transfers by updating the balances on the current block number
    * @param sender address to transfer from
    * @param recipient addres to transfer to
    * @param amount to transfer
    */
    function doTransfer(address sender, address recipient, uint256 amount) internal {
        require(amount > 0, "Tried to send non-positive amount");
        uint256 previousBalance;
        if(recipient != address(this)){
            require(balanceOf(sender).sub(amount) >= 0, "Stake amount was not removed from balance");        
            previousBalance = balanceOfAt(sender, block.number);
            updateBalanceAtNow(sender, previousBalance - amount);
        }
        previousBalance = balanceOfAt(recipient, block.number);
        require(previousBalance + amount >= previousBalance, "Overflow happened"); // Check for overflow
        updateBalanceAtNow(recipient, previousBalance + amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    * Emits a `Transfer` event with `from` set to the zero address.
    * Requirements
    * - `to` cannot be the zero address.
    */
    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");     

        uint256 previousBalance = balanceOfAt(account, block.number);
        require(previousBalance + amount >= previousBalance, "Overflow happened"); // Check for overflow
        updateBalanceAtNow(account, previousBalance + amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destoys `amount` tokens from `account`, reducing the
    * total supply.
    * Emits a `Transfer` event with `to` set to the zero address.
    * Requirements
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function burn(address account, uint256 amount) public {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 previousBalance = balanceOfAt(account, block.number);
        require(previousBalance - amount <= previousBalance, "Underflow happened"); // Check for overflow
        updateBalanceAtNow(account, previousBalance - amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    * Emits an `Approval` event.
    * Requirements:
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    /**
    * @dev Queries the balance of _user at a specific _blockNumber
    * @param account The address from which the balance will be retrieved
    * @param blockNumber The block number when the balance is queried
    * @return The balance at _blockNumber specified
    */
    function balanceOfAt(address account, uint256 blockNumber) public view returns (uint256) {
        if ((_balances[account].length == 0) || (_balances[account][0].fromBlock > blockNumber)) {
            return 0;
        } else {
            return getBalanceAt(account, blockNumber);
        }
    }

    /**
    * @dev Getter for balance for owner on the specified _block number
    * @param account gets the mapping for the balances[owner]
    * @param _block is the block number to search the balance on
    * @return the balance at the checkpoint
    */
    function getBalanceAt(address account, uint256 _block) public view returns (uint256) {
        Checkpoint[] storage checkpoints = _balances[account];
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock) return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint256 _min = 0;
        uint256 _max = checkpoints.length - 1;
        while (_max > _min) {
            uint256 _mid = (_max + _min + 1) / 2;
            if (checkpoints[_mid].fromBlock <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return checkpoints[_min].value;
    }

    /**
    * @dev Updates balance for from and to on the current block number via doTransfer
    * @param account gets the mapping for the balances[owner]
    * @param value is the new balance
    */
    function updateBalanceAtNow(address account, uint256 value) public {
        Checkpoint[] storage checkpoints = _balances[account];
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(value);
        }
    }
}