pragma solidity ^0.4.20;

library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract Owned {
    address public owner;
    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract SmartConvas is Owned{
    
    using SafeMath for uint256;
    
    event paintEvent(address sender, uint x, uint y, uint r, uint g, uint b);
    
    struct Pixel {
        address currentOwner;
        uint r;
        uint g;
        uint b;
        uint currentPrice;
    }
    
    //переменная стоимости пикселя
    uint defaultPrice = 1069120000000000; //1 $ по курсу 937p/eth  in wei
    uint priceInOneEther = 1000000000000000000;
    
    Pixel [1000][1000] pixels;
    
    function getAddress(uint x, uint y) constant returns (address) {
        Pixel memory p = pixels[x][y];
        return p.currentOwner;
    }
    
    function getColor(uint x, uint y) constant returns(uint[3])
    {
        return ([pixels[x][y].r, pixels[x][y].g, pixels[x][y].b]);
    }
    
    function getCurrentPrice(uint x, uint y) constant returns (uint)
    {
        Pixel memory p = pixels[x][y];
        return p.currentPrice;
    }
    
    function addPixelPayable(uint x, uint y, uint r, uint g, uint b) payable  {

        Pixel memory px = pixels[x][y];
        
        if(msg.value<px.currentPrice)
        {
            revert();
        }
        

       
        px.r = r;
        px.g = g;
        px.b = b;
        
        if(px.currentOwner>0)
        {
            px.currentOwner.transfer(msg.value.mul(75).div(100));
        }
        
        px.currentOwner = msg.sender;
        if(px.currentPrice ==0)
        {
            px.currentPrice = defaultPrice;
        }
        else
        {
            px.currentPrice = px.currentPrice.mul(2);
        }
        
        pixels[x][y] = px;
        
        emit paintEvent(msg.sender,x,y,r,g,b);
  
    }
    function GetBalance() constant returns (uint)
    {
        return address(this).balance;
    }
    function GetOwner() constant returns (address)
    {
        return owner;
    }
    
    function withdraw() onlyOwner returns(bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }
}