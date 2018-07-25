pragma solidity ^0.4.24;

interface FoMo3DlongInterface {
      function getBuyPrice()
        public
        view
        returns(uint256)
    ;
  function getTimeLeft()
        public
        view
        returns(uint256)
    ;
  function withdraw() external;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PwnFoMo3D is Owned {
    FoMo3DlongInterface fomo3d;
  constructor() public payable {
     fomo3d  = FoMo3DlongInterface(0x0aD3227eB47597b566EC138b3AfD78cFEA752de5);
  }
  
  function gotake() public  {
    // Link up the fomo3d contract and ensure this whole thing is worth it
    
    if (fomo3d.getTimeLeft() > 50) {
      revert();
    }

    address(fomo3d).call.value( fomo3d.getBuyPrice() *2 )();
    
    fomo3d.withdraw();
  }
  
    function withdrawOwner(uint256 a)  public onlyOwner {
        msg.sender.transfer(a);    
    }
}