pragma solidity >=0.4.21 <0.7.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
//openzeppelin v2.5.0
//0.5.0
//functions:
//burn:burn token from current address
//burnFrom:burn other's token(they increaseAllowance first)
//increaseAllowance
//decreaseAllowance

//
contract ERC20WithBurnable is ERC20, ERC20Detailed, ERC20Burnable {
    constructor(
        string memory name, //
        string memory symbol, //
        uint8 decimals, //
        uint256 totalSupply, //
        address adminAddress
    ) public ERC20Detailed(name, symbol, decimals) {
        _mint(adminAddress, totalSupply * (10**uint256(decimals)));
    }
}

contract Generator{
uint256 public fee =1000000;
address  payable  public owner;
 
constructor() public{
     owner=msg.sender;
 }
 
modifier OnlyOwner{
require(msg.sender == owner,"not owner");
_;
}

     // logs
    event LogAddress (string item, address addr);
  
      function generate(string calldata _name, string calldata _symbol, uint8 _decimals, uint256 _supplyAmount) external payable{
        require(msg.value>=fee,"fee not enough");
        owner.transfer(msg.value);
        
        // create token
        ERC20WithBurnable token=    new ERC20WithBurnable(_name,_symbol,_decimals,_supplyAmount,msg.sender);
        // give tokens to user and dubiHolders

        // log new token address
       emit LogAddress("GenerateToken", address(token));
    
      }
      
      function setFee(uint256 _fee) public OnlyOwner{
          fee=_fee;
      }

}