/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface cy {
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
}

interface curve {
    function add_liquidity(uint[2] memory, uint) external returns (uint);
    function remove_liquidity_imbalance(uint[2] memory, uint) external returns (uint);
    function calc_token_amount(uint[2] memory, bool) external view returns (uint);
    function calc_withdraw_one_coin(uint, int128) external view returns (uint);
}

interface erc20 { 
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
}

contract stabilizer {
    
    address constant public pool = 0x19b080FE1ffA0553469D20Ca36219F17Fcf03859;
    address constant public ib = 0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27;
    address constant public coin = 0xD71eCFF9342A5Ced620049e616c5035F1dB98620;
    address constant public cyib = 0x00e5c0774A5F065c285068170b20393925C84BF3;
    
    address immutable public owner;
    
    constructor(/*address _pool, address _ib, address _coin*/) {
        /*pool = _pool;
        ib = _ib;
        coin = _coin;*/
        owner = msg.sender;
    }
    
    function add_liquidity() external {
        uint _ib = erc20(ib).balanceOf(pool);
        uint _coin = erc20(coin).balanceOf(pool);
        uint _deposit = _coin - _ib;
        require(cy(cyib).borrow(_deposit) == 0, 'borrow failed');
        uint _min = curve(pool).calc_token_amount([_deposit, 0],true);
        _safeApprove(ib, pool, _deposit);
        curve(pool).add_liquidity([_deposit, 0], _min*9996/10000);
    }
    
    function remove_liquidity_forced(uint _withdraw) external {
        require(msg.sender == owner);
        uint _max = curve(pool).calc_token_amount([_withdraw,0], false);
        uint _balance = erc20(pool).balanceOf(address(this));
        if (_max > _balance) {
            uint _maxWithdraw = curve(pool).calc_withdraw_one_coin(_balance, 0);
            curve(pool).remove_liquidity_imbalance([_maxWithdraw, 0], _balance);
        } else {
            curve(pool).remove_liquidity_imbalance([_withdraw, 0], _max*10004/10000);
        }
    }
    
    function remove_liquidity() external {
        uint _ib = erc20(ib).balanceOf(pool);
        uint _coin = erc20(coin).balanceOf(pool);
        uint _withdraw = _ib - _coin;
        uint _max = curve(pool).calc_token_amount([_withdraw,0], false);
        uint _balance = erc20(pool).balanceOf(address(this));
        if (_max > _balance) {
            uint _maxWithdraw = curve(pool).calc_withdraw_one_coin(_balance, 0);
            curve(pool).remove_liquidity_imbalance([_maxWithdraw, 0], _balance);
        } else {
            curve(pool).remove_liquidity_imbalance([_withdraw, 0], _max*10004/10000);
        }
        repay();
    }
    
    function repay() public {
        uint _balance = erc20(ib).balanceOf(address(this));
        _safeApprove(ib, cyib, _balance);
        cy(cyib).repayBorrow(_balance);
    }
    
    function withdraw(address token) external {
        require(msg.sender == owner);
        _safeTransfer(token, owner, erc20(token).balanceOf(address(this)));
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}