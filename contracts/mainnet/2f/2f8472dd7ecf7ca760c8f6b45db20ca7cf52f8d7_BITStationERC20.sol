pragma solidity ^0.4.16;

contract ERC20Token{
    //ERC20 base standard
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned{
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still need to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() {
    }

       // Check if it is safe to add two numbers
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // Check if it is safe to subtract two numbers
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        uint c = a - b;
        assert(b <= a && c <= a);
        return c;
    }

    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint c = a * b;
        assert(a == 0 || (c / a) == b);
        return c;
    }

}

contract BITStationERC20 is SafeMath, ERC20Token, Owned {
    string public constant name = &#39;BitStation&#39;;                              // Set the token name for display
    string public constant symbol = &#39;BSTN&#39;;                                  // Set the token symbol for display
    uint8 public constant decimals = 18;                                     // Set the number of decimals for display
    uint256 public constant INITIAL_SUPPLY = 12000000000 * 10 ** uint256(decimals);
    uint256 public totalSupply;
    string public version = &#39;1&#39;;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    modifier rejectTokensToContract(address _to) {
        require(_to != address(this));
        _;
    }
    
    function BITStationERC20() public {
        totalSupply = INITIAL_SUPPLY;                              // Set the total supply
        balances[msg.sender] = INITIAL_SUPPLY;                     // Creator address is assigned all
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    function transfer(address _to, uint256 _value) rejectTokensToContract(_to) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) rejectTokensToContract(_to) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }


}