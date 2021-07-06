/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity 0.5.17;

contract Ashib {
    mapping(address=> uint) public balances;
    //
   //
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalsupply = 100000000 * 10 ** 18;

    string public symbol = "Shibuae";
    string public name = "Ashib";
    uint public decimals = 18;
    
    function burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    
     totalsupply = totalsupply-_value;
      balances[ _who] = balances[ _who]-_value;
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  
}

       function mint(
    address _to,
    uint256 _amount
  )
   // hasMintPermission
   // canMint
    public
    returns (bool)
  { 
   // totalsupply= totalsupply.add(_amount);
  ///  balances[_to] = balances[_to].add(_amount);
    totalsupply = totalsupply+_amount;
      balances[_to] = balances[_to]+_amount;
     
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
     
    event Burn (address indexed from, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Mint(address indexed to, uint value);
    constructor() public {
    balances[msg.sender] = totalsupply;}
   
  //  function mint(address _to, uint256 _amount) public  {
    ///    _mint(_to, _amount);
     ////  _moveDelegates(address(0), _delegates[_to], _amount);
  // }
    
    ///function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
       // if (srcRep != dstRep && amount > 0) {
         //   if (srcRep != address(0)) {
                // decrease old representative
            //    uint32 srcRepNum = numCheckpoints[srcRep];
            //    uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
            //    uint256 srcRepNew = srcRepOld.sub(amount);
              //  _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
          //      }
    
  //  function _mint(address account, uint256 amount) internal {
     //   require(account != address(0), 'BEP20: mint to the zero address');
//totalsupply = totalsupply+amount;
     //  balances[account] = balances[account]+amount;
     
       
       // emit Transfer(address(0), account, amount);
 //   }
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >=value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}