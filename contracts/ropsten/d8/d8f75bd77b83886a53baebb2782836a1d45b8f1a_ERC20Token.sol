/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

/**
 *SPDX-License-Identifier: GPL-2.0-only
 *Submitted for verification at Etherscan.io on 2021-02-08
 * Authoror: Barry
*/

pragma solidity ^0.7.5;

/**
 * Math operations with safety checks
*/
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        assert(b >=0);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

library SafeERC20 {
    function isContract(address addr) internal view {
        assembly {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function safeTransfer(address _tokenAddr, address _to, uint256 _value) internal returns (bool result) {
        // Must be a contract addr first!
        isContract(_tokenAddr);
        // call return false when something wrong
        (bool success, bytes memory data) = _tokenAddr.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        // handle returndata
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address _tokenAddr, address _from, address _to, uint256 _value) internal returns (bool result) {
        // Must be a contract addr first!
        isContract(_tokenAddr);
        // call return false when something wrong
        (bool success, bytes memory data) = _tokenAddr.call(abi.encodeWithSelector(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));
        // handle returndata
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeApprove(address _tokenAddr, address _spender, uint256 _value) internal returns (bool result) {
        // Must be a contract addr first!
        isContract(_tokenAddr);
        // call return false when something wrong
        (bool success, bytes memory data) = _tokenAddr.call(abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), _spender, _value));
        // handle returndata
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}


/* ERC20 standard abstract */
abstract contract StdERC20 {
    function totalSupply() public virtual returns (uint256);
    function balanceOf(address _owner) public virtual returns (uint256);
    function allowance(address _owner, address _spender) public virtual returns (uint256);
    // function approve(address _spender, uint256 _value) public virtual returns (bool);
    // function transfer(address _to, uint256 _value) public virtual returns (bool);
    // function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
1000000000000, "BarryCoin", "BBC"
*/
contract ERC20Token is StdERC20 {
    using SafeMath for uint256;
    using SafeERC20 for address;
    /* token name, symbol, decimals,total,owner */
    string  public  name ;
    string  public symbol;
    uint8   public decimals;
    address payable public owner;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => uint256) public freezeOf;
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    /* Initializes contract */
    constructor(
        uint256 _initialSupply,
        string  memory _tokenName,
    //uint8 _decimalUnits,      // 1ether = 10** 18wei
        string memory _tokenSymbol
    ) {
        decimals = 18; //_decimalUnits;                     // Amount of decimals for display purposes
        _balanceOf[msg.sender] = _initialSupply * 10 ** 18; // Give the creator all initial tokens
        _totalSupply = _initialSupply * 10 ** 18;           // Update total supply
        name = _tokenName;                                  // Set the name for display purposes
        symbol = _tokenSymbol;                              // Set the symbol for display purposes
        owner = msg.sender;
    }

    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this) );
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowance[_owner][_spender];
    }
    /* Allow another contract to spend some tokens in your behalf */
    // function approve(address _spender, uint256 _value) validDestination(_spender) public override returns (bool) {
    //     require (_value > 0);
    //     _allowance[msg.sender][_spender] = _value;
    //     emit Approval(msg.sender, _spender, _value);
    //     return true;
    // }
    /* approve many */
    // function approveMany(address[] memory _spenderes, uint256 _value) public {
    //     require(_spenderes.length > 0);
    //     require (_value >= 0);
    //     for (uint32 i = 0; i < _spenderes.length; i++) {
    //         approve(_spenderes[i], _value);
    //     }
    // }
    
    function safeApprove (address _tokenAddr, address _spender, uint256 _value) validDestination(_spender) public returns (bool) {
        require (_value > 0);
        require(address(_tokenAddr).safeApprove(_spender, _value));
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /*send tokens */
    // function transfer(address _to, uint256 _value) validDestination(_to) public override returns (bool){
    //     require (_value > 0);
    //     require (_balanceOf[msg.sender] > _value);
    //     require (_balanceOf[_to] + _value > _balanceOf[_to]);

    //     _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value);
    //     _balanceOf[_to] = _balanceOf[_to].safeAdd(_value);
    //     emit Transfer(msg.sender, _to, _value);
    //     return true;
    // }
    
    function safeTransfer(address _tokenAddr, address _to, uint256 _value) validDestination(_to) public returns (bool){
        require (_value > 0);
        require (_balanceOf[msg.sender] > _value);
        require (_balanceOf[_to] + _value > _balanceOf[_to]);
        require(address(_tokenAddr).safeTransfer(_to, _value), "transfer failed");
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value);
        _balanceOf[_to] = _balanceOf[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /* Approval somebody send tokens */
    // function transferFrom(address _from, address _to, uint256 _value) validDestination(_from) validDestination(_to)
    // public override returns (bool) {
    //     require (_value > 0);
    //     require (_balanceOf[_from] > _value);                  // Check if the sender has enough
    //     require (_balanceOf[_to] + _value > _balanceOf[_to]);  // Check for overflows
    //     require (_value < _allowance[_from][msg.sender]);      // Check allowance
    //     _balanceOf[_from] = _balanceOf[_from].safeSub(_value); // Subtract from the sender
    //     _balanceOf[_to]   = _balanceOf[_to].safeAdd(_value);   // Add the same to the recipient
    //     _allowance[_from][msg.sender] = _allowance[_from][msg.sender].safeSub(_value);
    //     emit Transfer(_from, _to, _value);
    //     return true;
    // }
    
    function safeTransferFrom(address _tokenAddr, address _from, address _to, uint256 _value) validDestination(_from) validDestination(_to)
    public returns (bool) {
        require (_value > 0);
        require (_balanceOf[_from] > _value);                 // Check if the sender has enough
        require (_balanceOf[_to] + _value > _balanceOf[_to]); // Check for overflows
        require (_value < _allowance[_from][msg.sender]);     // Check allowance
        //safeTransferFrom
        require (address(_tokenAddr).safeTransferFrom(_from, _to, _value));
        _balanceOf[_from] = _balanceOf[_from].safeSub(_value); // Subtract from the sender
        _balanceOf[_to]   = _balanceOf[_to].safeAdd(_value);   // Add the same to the recipient
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].safeSub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function freeze(uint256 _value) public returns (bool) {
        require (_balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require (_value > 0);

        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value); // Subtract from the sender
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(_value);   // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    function unfreeze(uint256 _value) public returns (bool) {
        require (freezeOf[msg.sender] >= _value); // Check if the sender has enough
        require (_value > 0);

        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(_value);   // Subtract from the sender
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeAdd(_value); // Updates totalSupply
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    function burn(uint256 _value) public returns (bool) {
        require (_balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require (_value > 0);

        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value);
        _totalSupply = _totalSupply.safeSub(_value); // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    /* transfer balance to owner */
    function withdrawEther(uint256 amount) public {
        require (msg.sender == owner);
        owner.transfer(amount);
    }
    /* can accept ether */
    fallback() external {}
    receive() payable external {}
}