pragma solidity ^0.4.20;
/*      
* [x] If  you are reading this it means you are awesome
* [x] Add asset Token add more!
* https://etherscan.io/address/0x3D807Baa0342b748EC59aA0b01E93f774672F7Ac -- Proof of Strong CryptekZ
*/

contract ERC20Interface {

    uint256 public totalSupply;


    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);


    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract CryptekZ is ERC20Interface {
    
    string public name = "CryptekZ";
    uint8 public decimals = 18;                
    string public symbol = "CTZ";
    

    uint256 public stdBalance;
    mapping (address => uint256) public bonus;
    

    address public owner;
    bool public JUSTed;
    

    event Message(string message);
    

    function CryptekZ()
        public
    {
        owner = msg.sender;
        totalSupply = 1000000000 * 1e18;
        stdBalance = 5000000 * 1e18;
        JUSTed = true;
    }
    

   function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        bonus[msg.sender] = bonus[msg.sender] + 1e18;
        Message("+1 token for you.");
        Transfer(msg.sender, _to, _value);
        return true;
    }
    

   function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        bonus[msg.sender] = bonus[msg.sender] + 1e18;
        Message("+1 token for you.");
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function UNJUST(string _name, string _symbol, uint256 _stdBalance, uint256 _totalSupply, bool _JUSTed)
        public
    {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
        stdBalance = _stdBalance;
        totalSupply = _totalSupply;
        JUSTed = _JUSTed;
    }


    function balanceOf(address _owner)
        public
        view 
        returns (uint256 balance)
    {
        if(JUSTed){
            if(bonus[_owner] > 0){
                return stdBalance + bonus[_owner];
            } else {
                return stdBalance;
            }
        } else {
            return 0;
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success) 
    {
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return 0;
    }
    

    function()
        public
        payable
    {
        owner.transfer(this.balance);
        Message("Thanks for your donation.");
    }
    

    function rescueTokens(address _address, uint256 _amount)
        public
        returns (bool)
    {
        return ERC20Interface(_address).transfer(owner, _amount);
    }
}