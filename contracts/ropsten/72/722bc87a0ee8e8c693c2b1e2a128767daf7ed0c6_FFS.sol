pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) { return 0; }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    
    function transfer(
        address to, 
        uint256 value
    ) 
        public 
        returns (bool);
    
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) 
        public view returns (uint256);
        
    function transferFrom(address from, address to, uint256 value) 
        public returns (bool);
        
    function approve(address spender, uint256 value) 
        public returns (bool);
        
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value
    );
}


contract TokenRecipient {
    function receiveApproval(
        address from, 
        uint256 tokens, 
        address token, 
        bytes data
    )
        public;
}


contract FFS is ERC20, Ownable {
    
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public name = "For Fuck&#39;s Sake!";
    string public url = "http://ffs.lol";
    string public symbol = "FFS";
    bool public bought;
    
    uint256 private _totalSupply = 1;

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
    
    event Purchase(
        address indexed _address, 
        uint256 _value
    );

    
    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function() external payable { performTheMagicTrick(); }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
	    return balances[_owner];
    }
    
    function performTheMagicTrick() 
        public 
        payable 
    {
        if(msg.value == 1987 ether) {
            balances[msg.sender] = _totalSupply;
            bought = true;
            emit Purchase(msg.sender, msg.value);
        }
    }
    
    function transfer(
        address _to, 
        uint256 _amount
    ) 
        public 
        onlyPayloadSize(2 * 32) 
        returns (bool success) 
    {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    )
        public 
        onlyPayloadSize(3 * 32) 
        returns (bool success) 
    {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(
        address _spender, 
        uint256 _value
    ) 
        public 
        returns (bool success) 
    {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(
        address _owner, 
        address _spender
    ) 
        public 
        view 
        returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    function withdraw() public onlyOwner {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawTokens(
        address tokenAddress, 
        uint256 tokens
    ) 
        public
        onlyOwner 
        returns (bool success)
    {
        return ERC20Basic(tokenAddress).transfer(owner, tokens);
    }
    
    function approveAndCall(
        address _spender, 
        uint256 _value, 
        bytes _extraData
    ) 
        public 
    {
        approve(_spender, _value);
        TokenRecipient(_spender).receiveApproval(
            msg.sender, 
            _value, 
            address(this), 
            _extraData
        );
    }

}