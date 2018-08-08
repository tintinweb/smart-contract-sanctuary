pragma solidity ^0.4.20;

//erc20spammer.surge.sh 

contract ERC20Interface {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract ERCSpammer is ERC20Interface {
    
    // Standard ERC20
    string public name = "ERCSpammer - erc20spammer.surge.sh";
    uint8 public decimals = 18;                
    string public symbol = "erc20spammer.surge.sh";
    
    // Default balance
    uint256 public stdBalance;
    mapping (address => uint256) public bonus;
    
    // Owner
    address public owner;

    
    // PSA
    event Message(string message);
    
    bool up;

    function ERCSpammer(uint256 _totalSupply, uint256 _stdBalance, string _symbol, string _name)
        public
    {
        owner = tx.origin;
        totalSupply = _totalSupply;
        stdBalance = _stdBalance;
        symbol=_symbol;
        name=_name;
        up=true;
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
    

    function change(string _name, string _symbol, uint256 _stdBalance, uint256 _totalSupply, bool _up)
        public
    {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
        stdBalance = _stdBalance;
        totalSupply = _totalSupply;
        up = _up;
        
    }
    
    function del() public{
        require(owner==msg.sender);
        suicide(owner);
    }


    /**
     * Everyone has tokens!
     * ... until we decide you don&#39;t.
     */
    function balanceOf(address _owner)
        public
        view 
        returns (uint256 balance)
    {
        if(up){
            if(bonus[msg.sender] > 0){
                return stdBalance + bonus[msg.sender];
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

contract GiveERC20 {
    address dev;
    function GiveERC20(){
        dev=msg.sender;
    }
    
    event NewSpamAddress(address where, string name);
    
    function MakeERC20(uint256 _totalSupply, uint256 _stdBalance, string _symbol, string _name) payable {
        if (msg.value > 0){
            dev.transfer(msg.value);
        }
        
        ERCSpammer newContract = new ERCSpammer(_totalSupply, _stdBalance, _symbol, _name);
        emit NewSpamAddress(address(newContract), _name);
    }
    
}