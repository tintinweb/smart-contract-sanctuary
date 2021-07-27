/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ibToken {
    function mint(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}

contract FixedForex {
    string public constant name = "Iron Bank KRW";
    string public constant symbol = "ibKRW";
    uint8 public constant decimals = 18;
    
    ibToken public immutable ib;
    address public gov;
    address public nextgov;
    uint public commitgov;
    uint public constant delay = 1 days;
    
    uint public liquidity;
    
    constructor(ibToken _ib) {
        ib = _ib;
        gov = msg.sender;
    }
    
    modifier g() {
        require(msg.sender == gov);
        _;
    }
    
    function setGov(address _gov) external g {
        nextgov = _gov;
        commitgov = block.timestamp + delay;
    }
    
    function acceptGov() external {
        require(msg.sender == nextgov && commitgov < block.timestamp);
        gov = nextgov;
    }
    
    function balanceIB() public view returns (uint) {
        return ib.balanceOf(address(this));
    }
    
    function balanceUnderlying() public view returns (uint) {
        uint256 _b = balanceIB();
        if (_b > 0) {
            return _b * ib.exchangeRateStored() / 1e18;
        }
        return 0;
    }
    
    function _redeem(uint amount) internal {
        require(ib.redeemUnderlying(amount) == 0, "ib: withdraw failed");
    }
    
    function profit() external {
        uint _profit = balanceUnderlying() - liquidity;
        _redeem(_profit);
        _transferTokens(address(this), gov, _profit);
    }
    
    function withdraw(uint amount) external g {
        liquidity -= amount;
        _redeem(amount);
        _burn(amount);
    }
    
    function deposit() external {
        uint _amount = balances[address(this)];
        allowances[address(this)][address(ib)] = _amount;
        liquidity += _amount;
        require(ib.mint(_amount) == 0, "ib: supply failed");
    }
    
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;
    
    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    function mint(uint amount) external g {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[address(this)] += amount;
        emit Transfer(address(0), address(this), amount);
    }
    
    function burn(uint amount) external g {
        _burn(amount);
    }
    
    function _burn(uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[address(this)] -= amount;
        emit Transfer(address(this), address(0), amount);
    }
    
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
    }
}