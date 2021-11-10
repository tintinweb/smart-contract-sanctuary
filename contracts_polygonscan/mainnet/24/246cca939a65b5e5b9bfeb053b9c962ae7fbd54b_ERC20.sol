/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

// SPDX-License-Identifier: DG

pragma solidity ^0.8.9;

contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private  _decimals;
    
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
    
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );

    constructor(
        string memory _entryname, 
        string memory _entrysymbol
    ) {
        
        _name = _entryname;
        _symbol = _entrysymbol;
        _decimals = 18;
    }

    function name() 
        public 
        view 
        returns (string memory) 
    {
        return _name;
    }

    function symbol() 
        public
        view 
        returns (string memory) 
    {
        return _symbol;
    }

    function decimals() 
        public 
        view 
        returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() 
        public 
        view 
        returns (uint256) 
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    ) 
        public 
        view
        returns (uint256) 
    {
        return _balances[_account];
    }

    function transfer(
        address _recipient, 
        uint256 _amount
    ) 
        external  
        returns (bool) 
    {
        _transfer(
            msg.sender, 
            _recipient, 
            _amount
        );
        
        return true;
    }

    function allowance(
        address _owner, 
        address _spender
    ) 
        external 
        view 
        returns (uint256) 
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender, 
        uint256 _amount
    ) 
        external 
        returns (bool) 
    {
        _approve(
            msg.sender, 
            _spender, 
            _amount
        );
        
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) 
        public 
        returns (bool) 
    {
        _approve(
            _sender, 
            msg.sender, 
            _allowances[_sender][msg.sender] - _amount
        );

        _transfer(
            _sender, 
            _recipient, 
            _amount
        );

        return true;
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _deadline >= block.timestamp,
            'ERC20: PERMIT_CALL_EXPIRED'
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner]++,
                        _deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(
            digest,
            _v,
            _r,
            _s
        );

        require(
            recoveredAddress != address(0x0) &&
            recoveredAddress == _owner,
            'INVALID_SIGNATURE'
        );

        _approve(
            _owner,
            _spender,
            _value
        );
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) 
        internal 
    {
        _balances[_sender] = 
        _balances[_sender] - _amount;
        
        _balances[_recipient] = 
        _balances[_recipient] + _amount;
        
        emit Transfer(
            _sender, 
            _recipient, 
            _amount
        );
    }

    function mint(
        address _account,
        uint256 _amount
    ) 
        public
    {
        _totalSupply = 
        _totalSupply + _amount;
        
        _balances[_account] = 
        _balances[_account] + _amount;
        
        emit Transfer(
            address(0x0), 
            _account, 
            _amount
        );
    }

    function _burn(
        address _account, 
        uint256 _amount
    ) 
        internal
    {
        _balances[_account] = 
        _balances[_account] - _amount;
        
        _totalSupply = 
        _totalSupply - _amount;
        
        emit Transfer(
            _account, 
            address(0x0), 
            _amount
        );
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) 
        internal 
    {
        _allowances[_owner][_spender] = _amount;
        
        emit Approval(
            _owner, 
            _spender, 
            _amount
        );
    }
}