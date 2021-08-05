/**
 *Submitted for verification at Etherscan.io on 2020-04-29
*/

pragma solidity ^0.6.3;
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract GBPT {
    string public name;
    address public manager;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public isBlackListed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event QE(address indexed from, uint256 value);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        initialSupply = 20000000  * 10 ** uint256(decimals);
        tokenName = "GBPT";
        tokenSymbol = "GBPT";
        manager = msg.sender;
        balanceOf[msg.sender] = initialSupply;
        totalSupply =  initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!isBlackListed[msg.sender]);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    function QuantitaveEasing(uint256 _value) public returns (bool success) {
        require(msg.sender == manager);   // Check if the sender is manager
        balanceOf[msg.sender] += _value;        
        totalSupply += _value;                      // Updates totalSupply
        emit QE(msg.sender, _value);
        return true;
    }
    
    function transferOwnership(address newOwner) public{
        require(msg.sender == manager);   // Check if the sender is manager
        if (newOwner != address(0)) {
            manager = newOwner;
        }
    }
    
    
    function addBlackList (address _evilUser)  public{
         require(msg.sender == manager);
        isBlackListed[_evilUser] = true;
        AddedBlackList(_evilUser);
    }
    
    function removeBlackList (address _clearedUser) public {
        require(msg.sender == manager);
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }

  struct memoIncDetails {
       uint256 _receiveTime;
       uint256 _receiveAmount;
       address _senderAddr;
       string _senderMemo;
   }
  mapping(address => memoIncDetails[]) textPurchases;
  
  
  function sendtokenwithmemo(uint256 _amount, address _to, string memory _memo)  public returns(uint256) {
      textPurchases[_to].push(memoIncDetails(now, _amount, msg.sender, _memo));
      _transfer(msg.sender, _to, _amount);
      return 200;
  }


   function checkmemopurchases(address _addr, uint256 _index) view public returns(uint256,
   uint256,
   string memory,
   address) {
       uint256 rTime = textPurchases[_addr][_index]._receiveTime;
       uint256 rAmount = textPurchases[_addr][_index]._receiveAmount;
       string memory sMemo = textPurchases[_addr][_index]._senderMemo;
       address sAddr = textPurchases[_addr][_index]._senderAddr;
       if(textPurchases[_addr][_index]._receiveTime == 0){
            return (0, 0,"0", _addr);
       }else {
            return (rTime, rAmount,sMemo, sAddr);
       }
   }


   function getmemotextcountforaddr(address _addr) view public returns(uint256) {
       return  textPurchases[_addr].length;
   }
   
   
   
  
  
 }