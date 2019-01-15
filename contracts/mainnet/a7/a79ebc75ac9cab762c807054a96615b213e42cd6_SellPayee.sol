pragma solidity > 0.4.99 <0.6.0;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool);
    function decimals() external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IAssetSplitContracts {
 function addContract(address payable _contractAddress, address payable _creatorAddress, uint256 _contractType) external returns (bool success);
}

interface IShareManager {
    function getSharesByShareOwner(address _shareOwner) external view returns (uint[] memory);
    function shares(uint _id) external view returns (address shareholder, uint256 sharePercentage);
    function sharesToManager(uint _id) external view returns (address shareowner);
}

interface IPayeeShare {
    function owner() external view returns (address payable shareowner);
    function payeePartsToSell() external view returns (uint256);
    function payeePricePerPart() external view returns (uint256);
}

contract Ownable {
  address payable public _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SellPayee is Ownable{

    IERC20Token public tokenContract;
    IAssetSplitContracts public assetSplitContract;
    IShareManager public shareManagerContract;
    
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    uint256 priceInEther = 500 finney;
    uint256 priceInToken = 1;
    
    using SafeMath for uint256;
    
    constructor(address _tokenContract, address _AssetSplitContracts, address _shareManager) public {
        tokenContract = IERC20Token(_tokenContract);
        assetSplitContract = IAssetSplitContracts(_AssetSplitContracts);
        shareManagerContract = IShareManager(_shareManager);
    }
    
    function getShareAddressFromId(uint _id) internal view returns (address) {
        address shareAddress;
        (shareAddress,) = shareManagerContract.shares(_id);
        return shareAddress;
    }
    
    
    function isAllowed(address payable _contractAddress) public view returns (bool) {
        uint[] memory result = shareManagerContract.getSharesByShareOwner(msg.sender);
        uint counter = 0;
        for (uint i = 0; i < result.length; i++) {
          if (getShareAddressFromId(result[i]) == _contractAddress) {
            counter++;
            return true;
          }
        }
        return false;
    }
 
    
    function addASC(address payable _contractAddress) public payable returns (bool success) {
        if (msg.value >= priceInEther) {
           IPayeeShare shareContract;
           shareContract = IPayeeShare(_contractAddress);
           require(shareContract.owner() == msg.sender);
           require(isAllowed(_contractAddress) == true);
           require(shareContract.payeePartsToSell() > 0);
           require(shareContract.payeePricePerPart() > 0);
           _owner.transfer(address(this).balance);
           assetSplitContract.addContract(_contractAddress, msg.sender, 1);
           return true;
        } else {
            IPayeeShare shareContract;
            shareContract = IPayeeShare(_contractAddress);
            require(tokenContract.balanceOf(msg.sender) >= priceInToken.mul(shareContract.payeePartsToSell()).mul(10 ** tokenContract.decimals()));
            require(tokenContract.transferFrom(msg.sender, _owner, priceInToken.mul(shareContract.payeePartsToSell()).mul(10 ** tokenContract.decimals())));
            require(shareContract.owner() == msg.sender);
            require(isAllowed(_contractAddress) == true);
            require(shareContract.payeePartsToSell() > 0);
            require(shareContract.payeePricePerPart() > 0);
            assetSplitContract.addContract(_contractAddress, msg.sender, 1);
            return true;
        }
        
    }
}