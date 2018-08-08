pragma solidity 0.4.24;
contract Owned {
    /* Variables */
    address public owner = msg.sender;
    /* Constructor */
    constructor(address _owner) public {
        if ( _owner == 0x00 ) {
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
contract TokenDB is Owned {
    /* Externals */
    function transfer(address _from, address _to, uint256 _amount) external returns(bool _success) {}
    function bulkTransfer(address _from, address[] _to, uint256[] _amount) external returns(bool _success) {}
    function setAllowance(address _owner, address _spender, uint256 _amount) external returns(bool _success) {}
    /* Constants */
    function getAllowance(address _owner, address _spender) public view returns(bool _success, uint256 _remaining) {}
    function balanceOf(address _owner) public view returns(bool _success, uint256 _balance) {}
}
contract Ico {
    /* Constants */
    function allowTransfer(address _owner) public view returns (bool _success, bool _allow) {}
}
contract Token is Owned {
    /* Declarations */
    using SafeMath for uint256;
    /* Variables */
    string  public name = "Inlock token";
    string  public symbol = "ILK";
    uint8   public decimals = 8;
    uint256 public totalSupply = 44e16;
    address public libAddress;
    TokenDB public db;
    Ico public ico;
    /* Constructor */
    constructor(address _owner, address _libAddress, address _dbAddress, address _icoAddress) Owned(_owner) public {
        libAddress = _libAddress;
        db = TokenDB(_dbAddress);
        ico = Ico(_icoAddress);
        emit Mint(_icoAddress, totalSupply);
    }
    /* Fallback */
    function () public { revert(); }
    /* Externals */
    function changeLibAddress(address _libAddress) external forOwner {
        libAddress = _libAddress;
    }
    function changeDBAddress(address _dbAddress) external forOwner {
        db = TokenDB(_dbAddress);
    }
    function changeIcoAddress(address _icoAddress) external forOwner {
        ico = Ico(_icoAddress);
    }
    function approve(address _spender, uint256 _value) external returns (bool _success) {
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
    function transfer(address _to, uint256 _amount) external returns (bool _success) {
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
    function bulkTransfer(address[] _to, uint256[] _amount) external returns (bool _success) {
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
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success) {
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
    /* Constants */
    function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {
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
    function balanceOf(address _owner) public view returns (uint256 _balance) {
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
}
contract TokenLib is Token {
    /* Constructor */
    constructor(address _owner, address _libAddress, address _dbAddress, address _icoAddress) Token(_owner, _libAddress, _dbAddress, _icoAddress) public {}
    /* Externals */
    function approve(address _spender, uint256 _amount) external returns (bool _success) {
        _approve(_spender, _amount);
        return true;
    }
    function transfer(address _to, uint256 _amount) external returns (bool _success) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }
    function bulkTransfer(address[] _to, uint256[] _amount) external returns (bool _success) {
        uint256 i;
        bool    _subResult;
        bool    _allowed;
        require( _to.length == _amount.length );
        ( _subResult, _allowed ) = ico.allowTransfer(msg.sender);
        require( _subResult && _allowed );
        require( db.bulkTransfer(msg.sender, _to, _amount) );
        for ( i=0 ; i<_to.length ; i++ ) {
            require( _amount[i] > 0 );
            require( _to[i] != 0x00 );
            require( msg.sender != _to[i] );
            emit Transfer(msg.sender, _to[i], _amount[i]);
        }
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success) {
        bool    _subResult;
        uint256 _reamining;
        if ( _from != msg.sender ) {
            (_subResult, _reamining) = db.getAllowance(_from, msg.sender);
            require( _subResult );
            _reamining = _reamining.sub(_amount);
            require( db.setAllowance(_from, msg.sender, _reamining) );
            emit AllowanceUsed(msg.sender, _from, _amount);
        }
        _transfer(_from, _to, _amount);
        return true;
    }
    /* Constants */
    function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {
        bool _subResult;
        (_subResult, _remaining) = db.getAllowance(_owner, _spender);
        require( _subResult );
    }
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        bool _subResult;
        (_subResult, _balance) = db.balanceOf(_owner);
        require( _subResult );
    }
    /* Internals */
    function _transfer(address _from, address _to, uint256 _amount) internal {
        bool _subResult;
        bool _allowed;
        require( _amount > 0 );
        require( _from != 0x00 && _to != 0x00 );
        ( _subResult, _allowed ) = ico.allowTransfer(_from);
        require( _subResult && _allowed );
        require( db.transfer(_from, _to, _amount) );
        emit Transfer(_from, _to, _amount);
    }
    function _approve(address _spender, uint256 _amount) internal {
        require( msg.sender != _spender );
        require( db.setAllowance(msg.sender, _spender, _amount) );
        emit Approval(msg.sender, _spender, _amount);
    }
}