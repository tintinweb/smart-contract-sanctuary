/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/**
 *SPDX-License-Identifier: GPL-2.0-only
 *Submitted for verification at Etherscan.io on 2021-02-08
 * Authoror: Barry
*/

pragma solidity ^0.7.4;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    //乘法
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        //assert断言函数，需要保证函数参数返回值是true，否则抛异常
        assert(a == 0 || c / a == b);
        return c;
    }
    //除法
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    //减法
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        assert(b >=0);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract MyCoin is SafeMath {

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    address payable public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    //key:授权人                key:被授权人  value: 配额
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => uint256) public freezeOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
    /**/
   
    /* Initializes contract with initial supply tokens to the creator of the contract */

    // 1000000000000, "BarryCoin", "BYC"
    constructor(
        uint256 _initialSupply, //发行数量
        string  memory _tokenName, //token的名字 SDCoin
    //uint8 _decimalUnits, //最小分割，小数点后面的尾数 1ether = 10** 18wei
        string memory _tokenSymbol //SDC
    ) {
        decimals = 18;//_decimalUnits;                         // Amount of decimals for display purposes
        balanceOf[msg.sender] = _initialSupply * 10 ** 18;     // Give the creator all initial tokens
        totalSupply = _initialSupply * 10 ** 18;               // Update total supply
        name = _tokenName;                                     // Set the name for display purposes
        symbol = _tokenSymbol;                                 // Set the symbol for display purposes

        owner = msg.sender;
    }

    /* Send coins */
    //某个人花费自己的币
    function transfer(address _to, uint256 _value) public {
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require (_value >= 0);
        require (balanceOf[msg.sender] > _value);           // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);             // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                           // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from /*管理员*/, address _to, uint256 _value) public
    returns (bool success) {
        require (_to != address(0x0));                       // Prevent transfer to 0x0 address. Use burn() instead
        require (_value >= 0);
        require (balanceOf[_from] > _value);                 // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows

        require (_value < allowance[_from][msg.sender]);     // Check allowance
        // mapping (address => mapping (address => uint256)) public allowance;

        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);      // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);           // Add the same to the recipient

        //allowance[管理员][A] = 1万-五千 = 五千
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    //the custom start
    //one transfer to many other accounts
    function transferOneToMany(address[] memory _tos, uint256[] memory _values) public {    
        require (_tos.length > 0);
        require (_values.length > 0);
        for(uint32 i = 0; i < _tos.length; i++) {
            transfer(_tos[i], _values[i]);
        }
    }
    
    //approve one transfer to many other accounts
    function transferFromOneToMany(address _from /*管理员*/, address[] memory _tos, uint256[] memory _values) public
    returns (bool success) {
        require (_tos.length > 0);
        require (_values.length > 0);
        for(uint32 i = 0; i < _tos.length; i++) {
            transferFrom(_from, _tos[i], _values[i]);
        }
        return true;
    }
    
    //many transfer to one
    function transferFromManyToOne(address[] memory _woner /*授权人*/, address[] memory _froms, address _to, uint256[]  memory _values) public
    returns (bool success) {
        require (_froms.length > 0);
        require (_values.length > 0);
        require (_to != address(0x0));
        
        for(uint32 i = 0; i < _froms.length; i++) {
            require (_values[i] >= 0);
            require (_froms[i] != address(0x0));                            // Prevent transfer to 0x0 address. Use burn() instead
            require (balanceOf[_woner[i]] > _values[i]);                   // Check if the sender has enough
            require (balanceOf[_to] + _values[i] > balanceOf[_to]);         // Check for overflows
            require (_values[i] < allowance[_woner[i]][_froms[i]]);        // Check allowance
            
            balanceOf[_woner[i]] = SafeMath.safeSub(balanceOf[_woner[i]], _values[i]);    // Subtract from the sender
            balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _values[i]);                  // Add the same to the recipient
            
            allowance[_woner[i]][_froms[i]] = SafeMath.safeSub(allowance[_woner[i]][_froms[i]], _values[i]);
            
            emit Transfer(_woner[i], _to, _values[i]);
        }
        return true;
    }
    //TODO
    //many transfer to many
    function transferFromManyToMany(address[] memory _woner /*授权人*/, address[] memory _froms, address[] memory _tos, uint256[]  memory _values) public
    returns (bool success) {
        require (_froms.length > 0);
        require (_tos.length > 0);
        require (_values.length > 0);
        
        for(uint32 i = 0; i < _froms.length; i++) {
            require (_values[i] >= 0);
            require (_froms[i] != address(0x0));                            // Prevent transfer to 0x0 address. Use burn() instead
            require (_tos[i] != address(0x0));                            // Prevent transfer to 0x0 address. Use burn() instead
            require (balanceOf[_woner[i]] > _values[i]);                   // Check if the sender has enough
            require (balanceOf[_tos[i]] + _values[i] > balanceOf[_tos[i]]);         // Check for overflows
            require (_values[i] < allowance[_woner[i]][_froms[i]]);        // Check allowance
            
            balanceOf[_woner[i]] = SafeMath.safeSub(balanceOf[_woner[i]], _values[i]);    // Subtract from the sender
            balanceOf[_tos[i]] = SafeMath.safeAdd(balanceOf[_tos[i]], _values[i]);                  // Add the same to the recipient
            
            allowance[_woner[i]][_froms[i]] = SafeMath.safeSub(allowance[_woner[i]][_froms[i]], _values[i]);
            
            emit Transfer(_woner[i], _tos[i], _values[i]);
        }
        return true;
    }
    
    
    //approve many
    function approveMany(address[] memory _spenderes, uint256 _value) public {
        require(_spenderes.length > 0);
        require (_value >= 0);
        for (uint32 i = 0; i < _spenderes.length; i++) {
            approve(_spenderes[i], _value);
        }
    }
    //the custom end
    
    /* Allow another contract to spend some tokens in your behalf */
    //找一个人A帮你花费token，这部分钱并不打A的账户，只是对A进行花费的授权
    //A： 1万
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require (_value > 0);
        //allowance[管理员][A] = 1万
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] > _value);            // Check if the sender has enough
        require (_value >= 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] > _value);            // Check if the sender has enough
        require (_value >= 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);        // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);          // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require (freezeOf[msg.sender] > _value);            // Check if the sender has enough
        require (_value >= 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    // transfer balance to owner
    function withdrawEther(uint256 amount) public {
        require (msg.sender == owner);
        owner.transfer(amount);
    }

    // can accept ether
    fallback() external {}
    receive() payable external {}
}