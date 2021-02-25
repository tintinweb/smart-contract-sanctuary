/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity >=0.7.0 <0.8.0;



 
 
 
contract Token {
    //Ledger part
    mapping(address => uint256) public balances;
    
    function getBalance(address addr) public view returns (uint256 balance) {
        return balances[addr];
    }
    
    
    //approval part
    mapping(address => mapping(address => uint256)) public permissions;
    
    function grantApproval(address addr, uint256 amount) public {
        permissions[msg.sender][addr] = amount;
    }
    
    function withdrawPermission(address addr) public {
         permissions[msg.sender][addr] = 0;
    }
    
    function getAllowance(address owner, address to) public view returns (uint256 allowed) {
        return permissions[owner][to];
    }
    
    
    
    //Spec part
    function name() public view returns (string memory) {
        return 'AwesomeToken';
    }
    
    function symbol() public view returns (string memory) {
        return "AT";
    }
    
    function decimals() public view returns (uint8) {
        // lets treat it like real money with 2 decimals
        return 2;
    }
    
    function totalSupply() public view returns (uint256) {
        // a small coinbase of a million AT's
        return 1_000_000;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_to != address(0));
        require(_from != address(0));
        require(allowance(_from, msg.sender) >= _value);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        permissions[_from][msg.sender] = permissions[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        grantApproval(_spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)  {
        return getAllowance(_owner, _spender);
    }
    
    
    function mint(uint256 amount) public {
        // - "I AM the bank". *spots bug* "not. yet."
        balances[0x2689Dd60757D86a3f8Bbf707A839Ffe44E8A4105] = balances[0x2689Dd60757D86a3f8Bbf707A839Ffe44E8A4105] + amount;
        emit Transfer(address(0), 0x2689Dd60757D86a3f8Bbf707A839Ffe44E8A4105, amount);
    }
    
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
}