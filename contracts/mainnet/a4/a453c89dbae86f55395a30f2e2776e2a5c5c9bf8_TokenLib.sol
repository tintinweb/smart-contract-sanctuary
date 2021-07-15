/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

/*
    safeMath.sol v1.0.1
    Safe mathematical operations
    
    This file is part of Screenist [NIS] token project.
    
    Author: Andor 'iFA' Rajci, Fusion Solutions KFT @ [email protected]
*/
pragma solidity 0.4.26;

library SafeMath {
    /* Internals */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert( c >= a );
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a - b;
        assert( c <= a );
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a * b;
        assert( c == 0 || c / a == b );
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }
    function pow(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a ** b;
        assert( c % a == 0 );
        return a ** b;
    }
}

/*
    owner.sol v1.0.0
    Owner
    
    This file is part of Screenist [NIS] token project.
    
    Author: Andor 'iFA' Rajci, Fusion Solutions KFT @ [email protected]
*/
pragma solidity 0.4.26;

contract Owned {
    /* Variables */
    address public owner = msg.sender;
    /* Constructor */
    constructor(address _owner) public {
        if ( _owner == address(0x00000000000000000000000000000000000000) ) {
            _owner = msg.sender;
        }
        owner = _owner;
    }
    /* Externals */
    function replaceOwner(address _owner) external returns(bool) {
        require( isOwner() );
        owner = _owner;
        return true;
    }
    /* Internals */
    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }
    /* Modifiers */
    modifier forOwner {
        require( isOwner() );
        _;
    }
}

/*
    tokenDB.sol v1.0.0
    Token Database - ABSTRACT
    
    This file is part of Screenist [NIS] token project.
    
    Author: Andor 'iFA' Rajci, Fusion Solutions KFT @ [email protected]
*/
pragma solidity 0.4.26;

contract TokenDB is Owned {
    /* Declarations */
    using SafeMath for uint256;
    /* Structures */
    struct balances_s {
        uint256 amount;
        bool valid;
    }
    struct vesting_s {
        uint256 amount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 claimedAmount;
        bool    valid;
    }
    /* Variables */
    mapping(address => mapping(address => uint256)) private allowance;
    mapping(address => balances_s) private balances;
    mapping(address => vesting_s) public vesting;
    uint256 public totalSupply;
    address public tokenAddress;
    address public oldDBAddress;
    uint256 public totalVesting;
    /* Constructor */
    constructor(address _owner, address _tokenAddress, address _oldDBAddress) Owned(_owner) public {}
    /* Externals */
    function changeTokenAddress(address _tokenAddress) external forOwner {}
    function mint(address _to, uint256 _amount) external returns(bool _success) {}
    function transfer(address _from, address _to, uint256 _amount) external returns(bool _success) {}
    function bulkTransfer(address _from, address[] memory _to, uint256[] memory _amount) public returns(bool _success) {}
    function setAllowance(address _owner, address _spender, uint256 _amount) external returns(bool _success) {}
    function setVesting(address _owner, uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) external returns(bool _success) {}
    /* Constants */
    function getAllowance(address _owner, address _spender) public view returns(bool _success, uint256 _remaining) {}
    function getBalance(address _owner) public view returns(bool _success, uint256 _balance) {}
    function getTotalSupply() public view returns(bool _success, uint256 _totalSupply) {}
    function getTotalVesting() public view returns(bool _success, uint256 _totalVesting) {}
    function getVesting(address _owner) public view returns(bool _success, uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount, bool _valid) {}
    /* Internals */
    function _getBalance(address _owner) internal view returns(uint256 _balance) {}
    function _getTotalSupply() internal view returns(uint256 _totalSupply) {}
    function _getTotalVesting() internal view returns(uint256 _totalVesting) {}
}

/*
    token.sol v1.0.0
    Token Proxy
    
    This file is part of Screenist [NIS] token project.
    
    Author: Andor 'iFA' Rajci, Fusion Solutions KFT @ [email protected]
*/
pragma solidity 0.4.26;

contract Token is Owned {
    /* Declarations */
    using SafeMath for uint256;
    /* Variables */
    string  public name = "Screenist Token";
    string  public symbol = "NIS";
    uint8   public decimals = 8;
    address public libAddress;
    address public freezeAdmin;
    address public vestingAdmin;
    TokenDB public db;
    bool    public underFreeze;
    /* Constructor */
    constructor(address _owner, address _freezeAdmin, address _vestingAdmin, address _libAddress, address _dbAddress, bool _isLib) Owned(_owner) public {
        if ( ! _isLib ) {
            db = TokenDB(_dbAddress);
            libAddress = _libAddress;
            vestingAdmin = _vestingAdmin;
            freezeAdmin = _freezeAdmin;
            require( db.setAllowance(address(this), _owner, uint256(0)-1) );
            require( db.mint(address(this), 1.55e16) );
            emit Mint(address(this), 1.55e16);
        }
    }
    /* Fallback */
    function () external payable {
        owner.transfer(msg.value);
    }
    /* Externals */
    function changeLibAddress(address _libAddress) public forOwner {
        libAddress = _libAddress;
    }
    function changeDBAddress(address _dbAddress) public forOwner {
        db = TokenDB(_dbAddress);
    }
    function setFreezeStatus(bool _newStatus) public forFreezeAdmin {
        underFreeze = _newStatus;
    }
    function approve(address _spender, uint256 _value) public returns (bool _success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function transfer(address _to, uint256 _amount) public isNotFrozen returns(bool _success)  {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function bulkTransfer(address[] memory _to, uint256[] memory _amount) public isNotFrozen returns(bool _success)  {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function transferFrom(address _from, address _to, uint256 _amount) public isNotFrozen returns (bool _success)  {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function setVesting(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock) public forVestingAdmin {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function claimVesting() public isNotFrozen {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    /* Constants */
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function balanceOf(address _owner) public constant returns (uint256 _balance) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function totalSupply() public constant returns (uint256 _totalSupply) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function getVesting(address _owner) public constant returns(uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x80)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x80)
            }
        }
    }
    function totalVesting() public constant returns(uint256 _amount) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function calcVesting(address _owner) public constant returns(uint256 _reward) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    /* Events */
    event AllowanceUsed(address indexed _spender, address indexed _owner, uint256 indexed _value);
    event Mint(address indexed _addr, uint256 indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event VestingDefined(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock);
    event VestingClaimed(address _beneficiary, uint256 _amount);
    /* Modifiers */
    modifier isNotFrozen {
        require( ! underFreeze );
        _;
    }
    modifier forOwner {
        require( isOwner() );
        _;
    }
    modifier forVestingAdmin {
        require( msg.sender == vestingAdmin );
        _;
    }
    modifier forFreezeAdmin {
        require( msg.sender == freezeAdmin );
        _;
    }
}

/*
    tokenLib.sol v1.0.1
    Token Library
    
    This file is part of Screenist [NIS] token project.
    
    Author: Andor 'iFA' Rajci, Fusion Solutions KFT @ [email protected]
*/
pragma solidity 0.4.26;

contract TokenLib is Token {
    /* Constructor */
    constructor(address _owner, address _freezeAdmin, address _vestingAdmin, address _libAddress, address _dbAddress) Token(_owner, _freezeAdmin, _vestingAdmin, _libAddress, _dbAddress, true) public {}
    /* Externals */
    function approve(address _spender, uint256 _amount) public returns (bool _success) {
        _approve(_spender, _amount);
        return true;
    }
    function transfer(address _to, uint256 _amount) public returns (bool _success) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }
    function bulkTransfer(address[] memory _to, uint256[] memory _amount) public returns (bool _success) {
        uint256 i;
        require( _to.length == _amount.length );
        require( db.bulkTransfer(msg.sender, _to, _amount) );
        for ( i=0 ; i<_to.length ; i++ ) {
            require( _amount[i] > 0 && _to[i] != 0x00 && msg.sender != _to[i] );
            emit Transfer(msg.sender, _to[i], _amount[i]);
        }
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success) {
        bool    _subResult;
        uint256 _remaining;
        if ( _from != msg.sender ) {
            (_subResult, _remaining) = db.getAllowance(_from, msg.sender);
            require( _subResult );
            _remaining = _remaining.sub(_amount);
            require( db.setAllowance(_from, msg.sender, _remaining) );
            emit AllowanceUsed(msg.sender, _from, _amount);
        }
        _transfer(_from, _to, _amount);
        return true;
    }
    function setVesting(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock) {
        require( _beneficiary != 0x00 );
        if ( _amount == 0 ) {
            _startBlock = 0;
            _endBlock = 0;
        } else {
            require( _endBlock > _startBlock );
        }
        require( db.setVesting(_beneficiary, _amount, _startBlock, _endBlock, 0) );
        emit VestingDefined(_beneficiary, _amount, _startBlock, _endBlock);
    }
    function claimVesting() public {
        uint256 _amount;
        uint256 _startBlock;
        uint256 _endBlock;
        uint256 _claimedAmount;
        uint256 _reward;
        ( _amount, _startBlock, _endBlock, _claimedAmount ) = _getVesting(msg.sender);
        _reward = _calcVesting(_amount, _startBlock, _endBlock, _claimedAmount);
        require( _reward > 0 );
        _claimedAmount = _claimedAmount.add(_reward);
        if ( _claimedAmount == _amount ) {
            require( db.setVesting(msg.sender, 0, 0, 0, 0) );
            emit VestingDefined(msg.sender, 0, 0, 0);
        } else {
            require( db.setVesting(msg.sender, _amount, _startBlock, _endBlock, _claimedAmount) );
            emit VestingDefined(msg.sender, _amount, _startBlock, _endBlock);
        }
        _transfer(address(this), msg.sender, _reward);
        emit VestingClaimed(msg.sender, _reward);
    }
    /* Constants */
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining) {
        bool _subResult;
        (_subResult, _remaining) = db.getAllowance(_owner, _spender);
        require( _subResult );
    }
    function balanceOf(address _owner) public constant returns (uint256 _balance) {
        bool _subResult;
        (_subResult, _balance) = db.getBalance(_owner);
        require( _subResult );
    }
    function totalSupply() public constant returns (uint256 _totalSupply) {
        bool _subResult;
        (_subResult, _totalSupply) = db.getTotalSupply();
        require( _subResult );
    }
    function totalVesting() public constant returns (uint256 _totalVesting) {
        bool _subResult;
        (_subResult, _totalVesting) = db.getTotalVesting();
        require( _subResult );
    }
    function getVesting(address _owner) public constant returns(uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) {
        return _getVesting(_owner);
    }
    function calcVesting(address _owner) public constant returns(uint256 _reward) {
        uint256 _amount;
        uint256 _startBlock;
        uint256 _endBlock;
        uint256 _claimedAmount;
        ( _amount, _startBlock, _endBlock, _claimedAmount ) = _getVesting(_owner);
        return _calcVesting(_amount, _startBlock, _endBlock, _claimedAmount);
    }
    /* Internals */
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require( _amount > 0 && _from != 0x00 && _to != 0x00 && _from != _to );
        require( db.transfer(_from, _to, _amount) );
        emit Transfer(_from, _to, _amount);
    }
    function _approve(address _spender, uint256 _amount) internal {
        require( msg.sender != _spender );
        require( db.setAllowance(msg.sender, _spender, _amount) );
        emit Approval(msg.sender, _spender, _amount);
    }
    function _getVesting(address _owner) internal constant returns(uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) {
        bool _subResult;
        bool _valid;
        ( _subResult, _amount, _startBlock, _endBlock, _claimedAmount, _valid ) = db.getVesting(_owner);
        require( _subResult );
    }
    function _calcVesting(uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) internal constant returns(uint256 _reward) {
        if ( _amount > 0 && block.number > _startBlock ) {
            _reward = _amount.mul( block.number.sub(_startBlock) ).div( _endBlock.sub(_startBlock) );
            if ( _reward > _amount ) {
                _reward = _amount;
            }
            if ( _reward <= _claimedAmount ) {
                _reward = 0;
            } else {
                _reward = _reward.sub(_claimedAmount);
            }
        }
    }
}