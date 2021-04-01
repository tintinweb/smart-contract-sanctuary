/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.6.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function mint(address _to, uint256 _amount) external;
    
   

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ethsend{
    IERC20  public token; 
     uint256 public tokenvalue = 1e18;
     uint256 public tokenReceived = 5e18;
     uint256 public Ethervalue=1e18;
     uint256 public Etherreceived=5e18;
    mapping (address=>uint)public balances;
    address public ownerAddress;
    
    constructor(address tokenAddress,address _owneraddress) public{
        token = IERC20(tokenAddress);
        ownerAddress=_owneraddress;
    }
    modifier onlyOwner {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
      
  
    function deposit() public payable{
     require(msg.value != 0,"invalid amount");
        uint tokenPrice =(msg.value * 1e18 / tokenvalue ) * tokenReceived / 1e18;
        token.transfer(msg.sender,tokenPrice);
                
    }
        function deposit(uint _token)public payable{
        uint Etherprice= (_token/Ethervalue*Etherreceived);
        require(address(uint160(msg.sender)).send(Etherprice), "insufficient balance");
    }
      function fallback() payable onlyOwner external{
    }
    
    
}