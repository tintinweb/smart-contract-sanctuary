// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./2_Owner.sol";

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract TECHTokenContract is Owner { // 0x9ED475D418c222f6cd9cb1163C1976AFbceaEd6c
    using SafeMath for uint256;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    mapping(address => Unlock[]) public frozenAddress;
    mapping(address => uint256) public unlock_amount_transfered;
    struct Unlock {
        uint256 unlock_time;
        uint256 amount;
    }

    uint public totalSupply = 20000000 * 10**18;
    string public constant name = "ROBOTECH WAR";
    string public constant symbol = "TECH";
    uint public constant decimals = 18;

    // tokenomics supply
    uint public constant rewards_supply = 10400000 * 10**18;
    uint public constant liquidityPool_supply = 1200000 * 10**18;
    uint public constant privateSale_supply = 400000 * 10**18;
    uint public constant publicSale_supply = 1600000 * 10**18;
    uint public constant devs_supply = 2400000 * 10**18;
    uint public constant marketing_supply = 3000000 * 10**18;
    uint public constant reserves_supply = 1000000 * 10**18;

    // tokenomics wallets
    address public constant rewards_wallet = 0x2D680E06120d0Bf2651EF6f9D0030F6117CeeFEB;
    address public constant liquidityPool_wallet = 0x3a309415E30580E511F6d61bc762B0A1b602Cec9;
    address public constant privateSale_wallet = 0x6351d8a7bb1E70D3afF8AFDD655423E8B4860200;
    address public constant publicSale_wallet = 0x0b89553F4Ded5B6eA7258C0dD63F2bd4A5aea408;
    address public constant devs_wallet = 0xbC86060b3eE4EA0cE299AfeC7BF045B5d052f06f;
    address public constant marketing_wallet = 0x6e7A06c412E07e41E814e48C9C3b547843992a7b;
    address public constant reserves_wallet = 0x6c79D3C2199AcE5a7938E43b76C11243A8626836;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        //set tokenomics balances
        balances[rewards_wallet] = rewards_supply;
        balances[liquidityPool_wallet] = liquidityPool_supply;
        balances[privateSale_wallet] = privateSale_supply;
        balances[publicSale_wallet] = publicSale_supply;
        balances[devs_wallet] = devs_supply;
        balances[marketing_wallet] = marketing_supply;
        balances[reserves_wallet] = reserves_supply;

        //lock tokenomics balances
        // 2592000 = 30 days
        uint256 month_time = 2592000;

        // LIQUIDITY
        frozenAddress[liquidityPool_wallet].push(Unlock(block.timestamp + (month_time * 12), liquidityPool_supply));
        // PRIVATE SALE
        frozenAddress[privateSale_wallet].push(Unlock(block.timestamp + (month_time * 3), 133320 * 10**18));
        frozenAddress[privateSale_wallet].push(Unlock(block.timestamp + (month_time * 4), 133320 * 10**18));
        frozenAddress[privateSale_wallet].push(Unlock(block.timestamp + (month_time * 5), 133320 * 10**18));
        // PUBLIC SALE
        frozenAddress[publicSale_wallet].push(Unlock(block.timestamp + (month_time), publicSale_supply));
        // DEVS
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 4), 600000 * 10**18));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 5), 600000 * 10**18));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 6), 600000 * 10**18));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 7), 600000 * 10**18));
        // MARKETING
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 4), 750000 * 10**18));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 5), 750000 * 10**18));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 6), 750000 * 10**18));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 7), 750000 * 10**18));
    }

    function checkFrozenAddress(address _account, uint256 _amount) private returns(bool){
        bool allowed_operation = false;
        uint256 amount_unlocked = 0;
        bool last_unlock_completed = false;
        if(frozenAddress[_account].length > 0){

            for(uint256 i=0; i<frozenAddress[_account].length; i++){
                if(block.timestamp >= frozenAddress[_account][i].unlock_time){
                    amount_unlocked = amount_unlocked.add(frozenAddress[_account][i].amount);
                }
                if(i == (frozenAddress[_account].length-1) && block.timestamp >= frozenAddress[_account][i].unlock_time){
                    last_unlock_completed = true;
                }
            }

            if(last_unlock_completed == false){
                if(amount_unlocked.sub(unlock_amount_transfered[_account]) >= _amount){
                    allowed_operation = true;
                }else{
                    allowed_operation = false;
                }
            }else{
                allowed_operation = true;
            }

            if(allowed_operation == true){
                unlock_amount_transfered[_account] = unlock_amount_transfered[_account].add(_amount);
            }
        }else{
            allowed_operation = true;
        }

        return allowed_operation;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) external returns(bool) {
        require(checkFrozenAddress(msg.sender, value) == true, "the amount is greater than the amount available unlocked");
        require(balanceOf(msg.sender) >= value, 'balance too low');

        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns(bool) {
        require(checkFrozenAddress(from, value) == true, "the amount is greater than the amount available unlocked");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value); // PROBAR PENDIENTE
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) private { // pendiente internal verificar
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance.sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        require(allowance[account][msg.sender] >= amount, "ERC20: burn amount exceeds allowance");
        allowance[account][msg.sender] = allowance[account][msg.sender].sub(amount); // PROBAR PENDIENTE
        _burn(account, amount);
    }
}