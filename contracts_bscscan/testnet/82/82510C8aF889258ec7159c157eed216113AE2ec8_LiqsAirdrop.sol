/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract LiqsAirdrop {
    address private _owner;
    IERC20 private _token;
    uint private _quantity;
    uint private _balance;
    uint private _tranche;
    uint private _counter = 0;
    
    mapping(address => uint) private _pickers;
    
    constructor(address token_, uint quantity_, uint tranche_) {
        _owner = msg.sender;
        _token = IERC20(token_);
        _quantity = quantity_;
        _balance = quantity_;
        _tranche = tranche_;
    }

    function deposit() external {
        _token.transferFrom(msg.sender, address(this), _quantity);
    }

    function pick() external {
        require(_pickers[msg.sender] != 1, 'LIQS AirDrop: Sender arleady picked ');
        _pickers[msg.sender] = 1;
        _counter += 1;
        _balance -= _tranche;
        _token.approve(msg.sender, _tranche);
        _token.transferFrom(address(this), msg.sender, _tranche);
    }

    function quantity() external view returns(uint) {
        return _quantity;
    }

    function counter() external view returns(uint) {
        require(msg.sender == _owner, 'LIQS AirDrop: Only owner can get counter');
        return _counter;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function tranche() external view returns (uint) {
        return _tranche;
    }

    function token() external view returns (address) {
        return address(_token);
    }
    
    receive() external payable {}
    fallback() external payable {}
}