/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity >=0.4.23 <0.6.0;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract YFNFTPayout {
    address public owner;
    address public owner1;
    
    event WithToken(address indexed user,uint256 payment,uint256  withid); 

    constructor(address ownerAddress,address ownerAddress1) public {
        owner = ownerAddress;
        owner1= ownerAddress1;   
    }
   
    function Smartchain(address userAddress,uint256 amnt) public payable {   
        if(owner1==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    }
      
    function Levelsmartchain(address userAddress,uint256 amnt) public payable {   
        if(owner==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    }

    function Execution(address _sponsorAddress,uint256 price) private returns (uint256 distributeAmount) {        
         distributeAmount = price;        
         if (!address(uint160(_sponsorAddress)).send(price)) {
             address(uint160(_sponsorAddress)).transfer(address(this).balance);
         }
         return distributeAmount;
    }
   
    function Paytoken(address[] memory _address,uint256[] memory _amount,uint256[] memory _withId,address _tokenAddress) public payable {
         if(owner==msg.sender)
         {
          for (uint8 i = 0; i < _address.length; i++) {      
              emit WithToken(_address[i],_amount[i],_withId[i]);
              IBEP20(_tokenAddress).transfer(_address[i], _amount[i]);
            }
        }
    } 
}