pragma solidity ^0.6.6;

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

interface ERC20 {
    function balanceOf(address target) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (uint256);
}
interface AragonFinance {
    function deposit(address _token, uint256 _amount, string calldata _reference) external;
}

interface Marketplace {
    function transferOwnership(address) external;
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external;
    function pause() external;
    function unpause() external;
}

contract MANACollect is Ownable {

    Marketplace public marketplace;
    Marketplace public bidMarketplace;
    AragonFinance public aragonFinance;
    ERC20 public mana;

    constructor(address manaAddress,
        address _marketAddress,
        address _bidAddress,
        address _aragonFinance
    ) public {
        mana = ERC20(manaAddress);
        marketplace = Marketplace(_marketAddress);
        bidMarketplace = Marketplace(_bidAddress);
        aragonFinance = AragonFinance(_aragonFinance);
    }

    function claimTokens() public {
        uint256 balance = mana.balanceOf(address(this));
        mana.approve(address(aragonFinance), balance);
        aragonFinance.deposit(address(mana), balance, "Fees collected from Marketplace");
    }

    function transferMarketplaceOwnership(address target) public onlyOwner {
        marketplace.transferOwnership(target);
    }

    function transferBidMarketplaceOwnership(address target) public onlyOwner {
        bidMarketplace.transferOwnership(target);
    }

    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
        marketplace.setOwnerCutPerMillion(_ownerCutPerMillion);
    }

    function setBidOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
        bidMarketplace.setOwnerCutPerMillion(_ownerCutPerMillion);
    }

    function pause() public onlyOwner {
        marketplace.pause();
    }

    function unpause() public onlyOwner {
        marketplace.unpause();
    }

    function pauseBid() public onlyOwner {
        bidMarketplace.pause();
    }

    function unpauseBid() public onlyOwner {
        bidMarketplace.unpause();
    }
}