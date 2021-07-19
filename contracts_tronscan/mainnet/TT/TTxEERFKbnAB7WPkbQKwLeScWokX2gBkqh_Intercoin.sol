//SourceUnit: Cogitare.sol

pragma solidity 0.5.8;
library SafeMath{function add(uint256 a,uint256 b)internal pure returns(uint256){uint256 c=a+b;require(c>=a);return c;}
function sub(uint256 a,uint256 b)internal pure returns(uint256){require(b<=a);uint256 c=a-b;return c;}
function mul(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}
uint256 c=a*b;require(c/a==b);return c;}
function div(uint256 a,uint256 b)internal pure returns(uint256){require(b>0);uint256 c=a/b;return c;}}

//SourceUnit: Communia.sol

pragma solidity 0.5.8;
import"./Silentum.sol";
import"./Cogitare.sol";contract TRC20Basic{uint public totalSupply;
function balanceOf(address who)public view returns(uint256);
function transfer(address to,uint256 value)public returns(bool);event Transfer(address indexed from,address indexed to,uint256 value);}
contract BasicToken is TRC20Basic,Pauseable{using SafeMath for uint256;mapping(address=>uint256)internal Frozen;mapping(address=>uint256)internal _balances;
function transfer(address to,uint256 value)public stoppable validRecipient(to)returns(bool){_transfer(msg.sender,to,value);return true;}
function _transfer(address from,address to,uint256 value)internal{require(from!=address(0));require(value>0);require(_balances[from].sub(Frozen[from])>=value);_balances[from]=_balances[from].sub(value);_balances[to]=_balances[to].add(value);emit Transfer(from,to,value);}
function balanceOf(address _owner)public view returns(uint256){return _balances[_owner];}
function availableBalance(address _owner)public view returns(uint256){return _balances[_owner].sub(Frozen[_owner]);}
function frozenOf(address _owner)public view returns(uint256){return Frozen[_owner];}
modifier validRecipient(address _recipient){require(_recipient!=address(0)&&_recipient!=address(this));_;}}

//SourceUnit: Dominium.sol

pragma solidity 0.5.8;
contract Ownable{address private _owner;event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);event OwnershipRenounced(address indexed previousOwner);constructor()internal{_owner=msg.sender;emit OwnershipTransferred(address(0),_owner);}
modifier onlyOwner(){require(msg.sender==_owner);_;}
function transferOwnership(address _newOwner)public onlyOwner{require(_newOwner!=address(0));emit OwnershipTransferred(_owner,_newOwner);_owner=_newOwner;}
function renounceOwnership()public onlyOwner{emit OwnershipRenounced(_owner);_owner=address(0);}
function owner()public view returns(address){return _owner;}}

//SourceUnit: Intelligentes.sol

pragma solidity 0.5.8;
import"./Normalen.sol";
contract ITRC677 is ITRC20{
function transferAndCall(address receiver,uint value,bytes memory data)public returns(bool success);event Transfer(address indexed from,address indexed to,uint256 value,bytes data);}
contract TRC677Receiver{
function onTokenTransfer(address _sender,uint _value,bytes memory _data)public;}
contract SmartToken is ITRC677,StandardToken{
function transferAndCall(address _to,uint256 _value,bytes memory _data)public validRecipient(_to)returns(bool success){_transfer(msg.sender,_to,_value);emit Transfer(msg.sender,_to,_value,_data);if(isContract(_to)){contractFallback(_to,_value,_data);}
return true;}
function contractFallback(address _to,uint _value,bytes memory _data)private{TRC677Receiver receiver=TRC677Receiver(_to);receiver.onTokenTransfer(msg.sender,_value,_data);}
function isContract(address _addr)private view returns(bool hasCode){uint length;assembly{length:=extcodesize(_addr)}
return length>0;}}

//SourceUnit: Normalen.sol

pragma solidity 0.5.8;
import"./Communia.sol";
contract ITRC20 is TRC20Basic{
function allowance(address owner,address spender)public view returns(uint256);
function approve(address spender,uint256 value)public returns(bool);
function transferFrom(address from,address to,uint256 value)public returns(bool);event Approval(address indexed owner,address indexed spender,uint256 value);}
contract StandardToken is ITRC20,BasicToken{mapping(address=>mapping(address=>uint256))private _allowed;
function approve(address spender,uint256 value)public stoppable validRecipient(spender)returns(bool){_approve(msg.sender,spender,value);return true;}
function _approve(address _owner,address spender,uint256 value)private{_allowed[_owner][spender]=value;emit Approval(_owner,spender,value);}
function transferFrom(address from,address to,uint256 value)public stoppable validRecipient(to)returns(bool){require(_allowed[from][msg.sender]>=value);_transfer(from,to,value);_approve(from,msg.sender,_allowed[from][msg.sender].sub(value));return true;}
function allowance(address _owner,address _spender)public view returns(uint256){return _allowed[_owner][_spender];}
function increaseAllowance(address spender,uint256 addedValue)public stoppable validRecipient(spender)returns(bool){_approve(msg.sender,spender,_allowed[msg.sender][spender].add(addedValue));return true;}
function decreaseAllowance(address spender,uint256 subtractValue)public stoppable validRecipient(spender)returns(bool){uint256 oldValue=_allowed[msg.sender][spender];if(subtractValue>oldValue){_approve(msg.sender,spender,0);}
else{_approve(msg.sender,spender,oldValue.sub(subtractValue));}
return true;}
function mint(address account,uint256 amount)public onlyOwner stoppable validRecipient(account)returns(bool){totalSupply=totalSupply.add(amount);_balances[account]=_balances[account].add(amount);emit Transfer(address(0),account,amount);return true;}
function burn(uint256 amount)public stoppable onlyOwner returns(bool){require(amount>0&&_balances[msg.sender]>=amount);totalSupply=totalSupply.sub(amount);_balances[msg.sender]=_balances[msg.sender].sub(amount);emit Transfer(msg.sender,address(0),amount);return true;}}

//SourceUnit: Nummum.sol

pragma solidity 0.5.8;
import"./Intelligentes.sol";
contract Intercoin is SmartToken{string private _name;string private _symbol;uint8 private _decimals;constructor()public{_name="Intercoin";_symbol="ITC";_decimals=6;mint(msg.sender,888888888e6);}
function name()public view returns(string memory){return _name;}
function symbol()public view returns(string memory){return _symbol;}
function decimals()public view returns(uint8){return _decimals;}
event Freeze(address indexed from,address indexed to,uint256 value);event Melt(address indexed from,address indexed to,uint256 value);
function freeze(address to,uint256 value)public onlyOwner stoppable returns(bool){_freeze(msg.sender,to,value);return true;}
function _freeze(address _from,address to,uint256 value)private{Frozen[to]=Frozen[to].add(value);_transfer(_from,to,value);emit Freeze(_from,to,value);}
function melt(address to,uint256 value)public onlyOwner stoppable returns(bool){_melt(msg.sender,to,value);return true;}
function _melt(address _onBehalfOf,address to,uint256 value)private{require(Frozen[to]>=value);Frozen[to]=Frozen[to].sub(value);emit Melt(_onBehalfOf,to,value);}
function transferAnyTRC20(address _tokenAddress,address _to,uint256 _amount)public onlyOwner{ITRC20(_tokenAddress).transfer(_to,_amount);}
function transferTRC10Token(address toAddress,uint256 tokenValue,trcToken id)public onlyOwner{address(uint160(toAddress)).transferToken(tokenValue,id);}
function withdrawTRX()public onlyOwner returns(bool){msg.sender.transfer(address(this).balance);return true;}}

//SourceUnit: Silentum.sol

pragma solidity 0.5.8;
import"./Dominium.sol";
contract Pauseable is Ownable{event Stopped(address _owner);event Started(address _owner);bool private stopped;constructor()internal{stopped=false;}
modifier stoppable{require(!stopped);_;}
function paused()public view returns(bool){return stopped;}
function halt()public onlyOwner{stopped=true;emit Stopped(msg.sender);}
function start()public onlyOwner{stopped=false;emit Started(msg.sender);}}