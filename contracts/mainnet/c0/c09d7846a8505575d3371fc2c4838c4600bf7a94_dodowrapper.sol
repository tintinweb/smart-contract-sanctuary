/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface dodo {
    function depositBase(uint) external returns (uint);
    function depositQuote(uint) external returns (uint);
    function withdrawBaseTo(address, uint) external returns (uint);
    function withdrawQuoteTo(address, uint) external returns (uint);
}

interface erc20 { 
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract dodowrapper {
    string public constant name = "DODO ibEUR/USDT";
    string public constant symbol = "ibEUR+USDT DLP";
    uint8 public constant decimals = 18;
    
    address constant ibEUR = 0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    address constant DODO = 0xd48c86156D53c0F775f40883391a113fC0D690d0;
    address constant USDT_DODO_LP = 0x59B407318E82a7dB2a815303aEa5d07da392EA82;
    address constant ibEUR_DODO_LP = 0xF7D07DD095577bf5Acd7eC4a1D8B0dC93b5233A6;
    
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;
    
    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    function mint(uint amount) external returns (uint) {
        uint _usdt = amount * 1e6 / 1e18;
        require(_usdt > 0);
        _safeTransferFrom(ibEUR, msg.sender, address(this), amount);
        _safeTransferFrom(USDT, msg.sender, address(this), _usdt);
        _safeApprove(ibEUR, DODO, amount);
        _safeApprove(USDT, DODO, _usdt);
        dodo(DODO).depositBase(amount);
        dodo(DODO).depositQuote(_usdt);
        _mint(msg.sender, amount);
        return amount;
    }
    
    function burn(uint amount) external {
        uint _supply = totalSupply;
        uint _usdt_share = erc20(USDT_DODO_LP).balanceOf(address(this)) * amount / _supply;
        uint _ibeur_share = erc20(ibEUR_DODO_LP).balanceOf(address(this)) * amount / _supply;
        dodo(DODO).withdrawBaseTo(msg.sender, _ibeur_share);
        dodo(DODO).withdrawQuoteTo(msg.sender, _usdt_share);
        _burn(msg.sender, amount);
    }
    
    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
        
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount to the recipient
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
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
    
        function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}