pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); 
    return a - b; 
  } 
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) { 
    uint256 c = a + b; assert(c >= a);
    return c;
  }
 
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
    }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FiatContract {
  function USD(uint _id) constant returns (uint256);
}

contract Main is Ownable {
    using SafeMath for uint256;
    address public wallet = 0x849861cE5c88F355A286d973302cf84A5e33fa6b; 
    uint256 public bonus = 50;
    uint256 public price = 10;

    function setBonus(uint newBonus) onlyOwner public  {
        bonus = newBonus;
    }

    function setWallet(address _newWallet) onlyOwner public {
        require(_newWallet != address(0));
        wallet = _newWallet;
    }

    function setPrice(uint newPrice) onlyOwner public  {
        price = newPrice;
    }


}


contract Transaction is Main  {
    uint256 USDv;
    uint256 MIRAv;
    FiatContract public fiat;
    
    ERC20 MIRAtoken = ERC20(0x8BCD8DaFc917BFe3C82313e05fc9738aeB72d555);

     function Transaction() {
          fiat = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
     }
   

    function() external payable {
        address buyer = msg.sender;
        require(buyer != address(0));
        require(msg.value != 0);
        MIRAv = msg.value;
        uint256 cent = fiat.USD(0);
        uint256 dollar = cent*100;

        USDv = msg.value.div(dollar); //USD
        
        require(USDv != 0);
        
        MIRAv = USDv.mul(1000).div(price);              // without bonus
        MIRAv = MIRAv + MIRAv.div(100).mul(bonus);      // + bonus
        MIRAv = MIRAv.mul(100000000);
        
        address(wallet).send(msg.value); //send eth
        MIRAtoken.transfer(buyer,MIRAv); //send tokens
    }

    function getMIRABALANCE() public  constant returns (uint256) {  
        require(msg.sender == owner);
        return MIRAtoken.balanceOf(address(this)).div(100000000); 
        }
    function getADR() public constant returns (address) {   return address(this);  }

}



// Please, visit https://miramind.io/risks.pdf to know more about the risks