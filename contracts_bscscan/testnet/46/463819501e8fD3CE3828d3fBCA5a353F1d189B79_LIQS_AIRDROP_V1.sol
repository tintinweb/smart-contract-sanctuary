/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface I_LIQS_AIRDROP_FACTORY_V1 {
     function addAirDrop(address airDrop_, address token_) external;
}

contract LIQS_AIRDROP_V1 {
    address private _owner;
    IERC20 private _token;
    uint private _quantity;
    uint private _balance = 0;
    uint private _tranche;
    uint private _counter = 0;

    mapping(address => uint) private _pickers;
    
    constructor(address factory_, address token_, uint quantity_, uint tranche_) {
        require(tranche_ < quantity_, 'LIQS AirDrop: Tranche cannot be smaller thas quantity');
        _owner = msg.sender;
        _token = IERC20(token_);
        _quantity = quantity_;
        _tranche = tranche_;
        I_LIQS_AIRDROP_FACTORY_V1(factory_).addAirDrop(address(this), token_);
    }

    function deposit() external {
        require(msg.sender == _owner, 'LIQS AirDrop: Only owner can deposit');
        require(_balance == 0, 'LIQS AirDrop: Deposit arleady has been made');
        _balance = _quantity;
        _token.transferFrom(msg.sender, address(this), _quantity);
    }

    function pick() external {
        require(_pickers[msg.sender] != 1, 'LIQS AirDrop: Sender arleady picked');
        require(_balance % _tranche == 0 , 'LIQS AirDrop: Balance modulo tranche must be 0');
        require(_tranche < _balance, 'LIQS AirDrop: Insuficient contract balance');
        _pickers[msg.sender] = 1;
        _counter += 1;
        _balance -= _tranche;
        _token.transfer(msg.sender, _tranche);
    }

    function picked() external view returns(uint) {
        return _pickers[msg.sender];
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

    function balance() external view returns(uint) {
        return _balance;
    }
}