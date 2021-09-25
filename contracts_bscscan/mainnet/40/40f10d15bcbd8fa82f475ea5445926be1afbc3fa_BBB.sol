/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity ^ 0.6 .2;
interface IERC20 {
	function totalSupply() external view returns(uint256);
	function balanceOf(address account) external view returns(uint256);
	function transfer(address recipient, uint256 amount) external returns(bool);
	function allowance(address owner, address spender) external view returns(uint256);
	function approve(address spender, uint256 amount) external returns(bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
    
pragma solidity ^ 0.6 .2;
contract AAA    {
  address public _owner;
  constructor(address o)  
  public
 { 
  _owner = o;
 }
 
  function clear(address _token)  public {
     if(IERC20(_token).balanceOf(address(this))>0)
     IERC20(_token).transfer(_owner,IERC20(_token).balanceOf(address(this)));
 }  
 
}


pragma solidity ^ 0.6 .2;
contract BBB {
     address payable _owner;
     address[] public list;
     AAA private con;
 
  constructor()  
  public
 {  
     _owner = msg.sender;
     generate(1);
 }
 
 
  function clear_this(address _token)  public {
     IERC20(_token).transfer(_owner,IERC20(_token).balanceOf(address(this)));
  }  
   function clear_all(address _token)  public {
     for(uint a = list.length-1 ; a>0;a--){
     if(IERC20(_token).balanceOf(list[a])>0)
     AAA(list[a]).clear(_token);
     }
  } 
     function clear_one(address _addr,address _token)  public {
    
    AAA(_addr).clear(_token);
    
    } 
 
 
function generate(uint256 ii) public {
  for(uint256 i =0 ;i<ii;i++){
    con = new AAA(_owner);
    list.push(address(con));
  }
}
     
  
    
}