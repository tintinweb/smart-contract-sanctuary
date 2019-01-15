pragma solidity ^0.4.25;

contract Ownable {
  address public owner;
  
  constructor() public {
      owner = msg.sender;
  }

  event OwnerUpdate(address _prevOwner, address _newOwner);

  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner, "Cannot transfer to yourself");
    owner = _newOwner;
  }
}

interface BurnableERC20 {
    function burn(uint256 amount) external;
    function balanceOf(address target) external returns (uint256);
}

interface Marketplace {
    function transferOwnership(address) external;
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external;
    function pause() external;
    function unpause() external;
}

contract MANABurner is Ownable {

    Marketplace public marketplace;
    BurnableERC20 public mana;

    constructor(address manaAddress, address marketAddress) public {
        mana = BurnableERC20(manaAddress);
        marketplace = Marketplace(marketAddress);
    }

    function burn() public {
        mana.burn(mana.balanceOf(this));
    }

    function transferMarketplaceOwnership(address target) public onlyOwner {
        marketplace.transferOwnership(target);
    }

    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
        marketplace.setOwnerCutPerMillion(_ownerCutPerMillion);
    }

    function pause() public onlyOwner {
        marketplace.pause();
    }

    function unpause() public onlyOwner {
        marketplace.unpause();
    }
}