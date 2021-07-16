//SourceUnit: did.sol

pragma solidity ^0.5.10;

//Interface
interface IDID {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed _from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Freeze(address indexed target);
    event UnFreeze(address indexed target);
    event Burn(address _address, uint256 _amount);
    event buytoken(address buyer,uint256 amount);
    event selltoken(address seller, uint256 amount);
    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract DID is IDID {
     using SafeMath for uint256;
     address payable public  _owner;
     address payable public  newOwner;
     uint256 public totalSupply = 75000000e6;
     string public name="DIDCOIN";
     string public symbol="DID";
     uint256 public decimals=6;
     constructor(address payable _ownerAddress) public{
         _owner=_ownerAddress;
         Balance[_owner]=totalSupply;
         newOwner=address(0);
    }
        mapping (address => uint256) public Balance;
        mapping (address => mapping (address => uint256)) public allowed;
        mapping (address=>bool) public frozen;
        //events
        event freeze(address indexed target);
        event unfreeze(address indexed target);
        event Burns(address _address,uint256 _amount);
         //all modifiers
        modifier notFrozen(address _holder){
        require(!frozen[_holder]);
        _;
       }
        modifier onlyOwner(){
        require(msg.sender==_owner);
        _;
    }
    modifier onlyNewowner(){
        require(msg.sender!=address(0));
        require(msg.sender==_owner);
        _;
    }
    function changeTokenName(string memory _tokenName) public onlyOwner returns(bool){
           name=_tokenName;
           return true;
    }
    function changeTokenSymbol(string memory _tokenSymbol) public onlyOwner returns(bool){
           symbol=_tokenSymbol;
           return true;
    }
    function changeOwner(address payable _newowner) public returns(bool){
        require(_newowner!=address(0));
        newOwner=_newowner;
        _owner=newOwner;
        return true;
    }
    function balanceOf(address userAddress) public view returns (uint256) {
        return Balance[userAddress];
    }
    function allowance(address owner,address spender)public view returns (uint256)
    {
        return allowed[owner][spender];
    }
    function transfer(address to, uint256 value) public  notFrozen(msg.sender)  returns (bool) {
        require(to!=address(0));
        require(value<=Balance[msg.sender]);
        Balance[msg.sender]=Balance[msg.sender].sub(value);
        Balance[to]=Balance[to].add(value);
        emit Transfer(msg.sender,to,value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from,address to,uint256 value) public notFrozen(msg.sender)  returns (bool) {
        require(to!=address(0));
        require(value<=Balance[from]);
        require(value<=allowed[from][msg.sender]);
        Balance[from]=Balance[from].sub(value);
        Balance[to]=Balance[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from,to,value);
        return true;
    }
    function increaseAllowance(address spender,uint256 addedValue) public returns (bool){
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender,uint256 subtractedValue) public returns (bool){
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    function UnFreezeAcc(address _target) public onlyOwner returns(bool){
        require(frozen[_target]);
        frozen[_target]=false;
        emit freeze(_target);
        return true;
        
    }
    function _mint(address account, uint256 value) public onlyOwner returns(bool) {
        require(account != address(0));
        totalSupply = totalSupply.add(value);
        Balance[account] = Balance[account].add(value);
        emit Transfer(address(0), account, value);
        return true;
    }
    function _burn(address account, uint256 value) public onlyOwner returns(bool)  {
        require(account != address(0));
        totalSupply = totalSupply.sub(value);
        Balance[account] = Balance[account].sub(value);
        emit Transfer(account, address(0), value);
        return true;
    }
    function() payable external{
        require(msg.value>0);
        _owner.transfer(msg.value);
        
    }
    function isContract(address addr) internal  view returns (bool) {
      uint size;
     assembly { size := extcodesize(addr) }
     return size > 0;
   }

}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}