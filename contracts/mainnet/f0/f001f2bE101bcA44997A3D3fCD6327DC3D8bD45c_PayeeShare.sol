pragma solidity > 0.4.99 <0.6.0;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool);
    function decimals() external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
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

contract PayeeShare is Ownable{
    
    struct Payee {
        address payable payee;
        uint payeePercentage;
    }
    
    Payee[] public payees;
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    IERC20Token public tokenContract;
    
    bool processingPayout = false;
    
    uint256 public payeePartsLeft = 100;
    uint256 public payeePartsToSell = 0;
    uint256 public payeePricePerPart = 0;
    
    uint256 public lockedToken;
    uint256 public lockedTokenTime;
    uint256 minTokenTransfer = 1;
    
    using SafeMath for uint256;
    
    event TokenPayout(address receiver, uint256 value, string memberOf);
    event EtherPayout(address receiver, uint256 value, string memberOf);
    event PayeeAdded(address payee, uint256 partsPerFull);
    event LockedTokensUnlocked();
    
    constructor(address _tokenContract, uint256 _lockedToken, uint256 _lockedTokenTime) public {
        tokenContract = IERC20Token(_tokenContract);
        lockedToken = _lockedToken;
        lockedTokenTime = _lockedTokenTime;
    }
    
    function changePayee(uint256 _payeeId, address payable _payee, uint256 _percentage) public onlyOwner {
      require(payees.length >= _payeeId);
      Payee storage myPayee = payees[_payeeId];
      myPayee.payee = _payee;
      myPayee.payeePercentage = _percentage;
    }
  
    function getPayeeLenght() public view returns (uint256) {
        return payees.length;
    }
    
     function getLockedToken() public view returns (uint256) {
        return lockedToken;
    }
    
    function addPayee(address payable _address, uint _payeePercentage) public payable {
        if (msg.sender == _owner) {
        require(payeePartsLeft >= _payeePercentage);
        payeePartsLeft = payeePartsLeft.sub(_payeePercentage);
        payees.push(Payee(_address, _payeePercentage));
        emit PayeeAdded(_address, _payeePercentage);
        }
        else if (msg.value == _payeePercentage.mul(payeePricePerPart)) {
        if (address(this).balance > 0) {
          etherPayout();
        }
        if (tokenContract.balanceOf(address(this)).sub(lockedToken) > 1) {
          tokenPayout();
        }
            require(payeePartsLeft >= _payeePercentage);
            require(payeePartsToSell >= _payeePercentage);
            require(tx.origin == msg.sender);
            payeePartsToSell = payeePartsToSell.sub(_payeePercentage);
            payeePartsLeft = payeePartsLeft.sub(_payeePercentage);
            payees.push(Payee(tx.origin, _payeePercentage));
            emit PayeeAdded(tx.origin, _payeePercentage);
        } else revert();
    } 
    
    function setPartsToSell(uint256 _parts, uint256 _price) public onlyOwner {
        require(payeePartsLeft >= _parts);
        payeePartsToSell = _parts;
        payeePricePerPart = _price;
    }
    
    function etherPayout() public {
        require(processingPayout == false);
        processingPayout = true;
        uint256 receivedValue = address(this).balance;
        uint counter = 0;
        for (uint i = 0; i < payees.length; i++) {
           Payee memory myPayee = payees[i];
           myPayee.payee.transfer((receivedValue.mul(myPayee.payeePercentage).div(100)));
           emit EtherPayout(myPayee.payee, receivedValue.mul(myPayee.payeePercentage).div(100), "Shareholder");
            counter++;
          }
        if(address(this).balance > 0) {
            _owner.transfer(address(this).balance);
            emit EtherPayout(_owner, address(this).balance, "Owner");
        }
        processingPayout = false;
    }
    
     function tokenPayout() public payable {
        require(processingPayout == false);
        require(tokenContract.balanceOf(address(this)) >= lockedToken.add((minTokenTransfer.mul(10 ** tokenContract.decimals()))));
        processingPayout = true;
        uint256 receivedValue = tokenContract.balanceOf(address(this)).sub(lockedToken);
        uint counter = 0;
        for (uint i = 0; i < payees.length; i++) {
           Payee memory myPayee = payees[i];
           tokenContract.transfer(myPayee.payee, receivedValue.mul(myPayee.payeePercentage).div(100));
           emit TokenPayout(myPayee.payee, receivedValue.mul(myPayee.payeePercentage).div(100), "Shareholder");
            counter++;
          } 
        if (tokenContract.balanceOf(address(this)).sub(lockedToken) > 0) {
            tokenContract.transfer(_owner, tokenContract.balanceOf(address(this)).sub(lockedToken));
            emit TokenPayout(_owner, tokenContract.balanceOf(address(this)).sub(lockedToken), "Owner");
        }
        processingPayout = false;
    }
    
    function payoutLockedToken() public payable onlyOwner {
        require(processingPayout == false);
        require(now > lockedTokenTime);
        require(tokenContract.balanceOf(address(this)) >= lockedToken);
        lockedToken = 0;
        if (address(this).balance > 0) {
          etherPayout();
        }
        if (tokenContract.balanceOf(address(this)).sub(lockedToken) > 1) {
          tokenPayout();
        }
        processingPayout = true;
        emit LockedTokensUnlocked();
        tokenContract.transfer(_owner, tokenContract.balanceOf(address(this)));
        processingPayout = false;
    }
    
    function() external payable {
    }
}

contract ShareManager is Ownable{
    using SafeMath for uint256;

    IERC20Token public tokenContract;
    
    struct Share {
        address payable share;
        uint sharePercentage;
    }
    
    Share[] public shares;
    
    mapping (uint => address) public sharesToManager;
    mapping (address => uint) ownerShareCount;
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    bool processingPayout = false;
    bool processingShare = false;
    
    PayeeShare payeeShareContract;
    
    uint256 public sharesMaxLength;
    uint256 public sharesSold;
    uint256 public percentagePerShare;
    uint256 public tokenPerShare;
    uint256 public tokenLockDays;
    address payable ownerAddress;
    
    event TokenPayout(address receiver, uint256 value, string memberOf);
    event EtherPayout(address receiver, uint256 value, string memberOf);
    event ShareSigned(address shareOwner, address shareContract, uint256 lockTime);
    
    constructor(address _tokenContract, uint256 _tokenPerShare, address payable _contractOwner, uint _ownerPercentage, uint _percentagePerShare) public {
        tokenContract = IERC20Token(_tokenContract);
        shares.push(Share(_contractOwner, _ownerPercentage));
        sharesMaxLength = (uint256(100).sub(_ownerPercentage)).div(_percentagePerShare);
        percentagePerShare = _percentagePerShare;
        tokenPerShare = _tokenPerShare;
        ownerAddress = _owner;
        tokenLockDays = 100;
    }
    
    function tokenPayout() public payable {
        require(processingPayout == false);
        require(tokenContract.balanceOf(address(this)) >= uint256(1).mul(10 ** tokenContract.decimals()));
        processingPayout = true;
        uint256 receivedValue = tokenContract.balanceOf(address(this));
        uint counter = 0;
        for (uint i = 0; i < shares.length; i++) {
           Share memory myShare = shares[i];
           if (i > 0) {
               payeeShareContract = PayeeShare(myShare.share);
               if (payeeShareContract.getLockedToken() == tokenPerShare.mul(10 ** tokenContract.decimals())) {
                 tokenContract.transfer(myShare.share, receivedValue.mul(myShare.sharePercentage).div(100));
                 emit TokenPayout(myShare.share, receivedValue.mul(myShare.sharePercentage).div(100), "Shareholder");
               }
           } else {
               tokenContract.transfer(myShare.share, receivedValue.mul(myShare.sharePercentage).div(100));
               emit TokenPayout(myShare.share, receivedValue.mul(myShare.sharePercentage).div(100), "Owner");
           }
           
            counter++;
          } 
        if(tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(_owner, tokenContract.balanceOf(address(this)));
            emit TokenPayout(_owner, tokenContract.balanceOf(address(this)), "Owner - left from shares");
        }
        processingPayout = false;
    }
    
    function etherPayout() public payable {
        require(address(this).balance > uint256(1).mul(10 ** 18).div(100));
        require(processingPayout == false);
        processingPayout = true;
        uint256 receivedValue = address(this).balance;
        uint counter = 0;
        for (uint i = 0; i < shares.length; i++) {
           Share memory myShare = shares[i];
           if (i > 0) {
           payeeShareContract = PayeeShare(myShare.share);
               if (payeeShareContract.getLockedToken() == tokenPerShare.mul(10 ** tokenContract.decimals())) {
                 myShare.share.transfer((receivedValue.mul(myShare.sharePercentage).div(100)));
                 emit EtherPayout(myShare.share, receivedValue.mul(myShare.sharePercentage).div(100), "Shareholder");
               }
           } else {
               myShare.share.transfer((receivedValue.mul(myShare.sharePercentage).div(100)));
               emit EtherPayout(myShare.share, receivedValue.mul(myShare.sharePercentage).div(100), "Owner");
           }
            counter++;
          }
        if(address(this).balance > 0) {
            _owner.transfer(address(this).balance);
            emit EtherPayout(_owner, address(this).balance, "Owner - left from shares");
        }
        processingPayout = false;
    }
    function() external payable {
     
    }
    
    function newShare() public payable returns (address) {
        require(shares.length <= sharesMaxLength);
        require(tokenContract.balanceOf(msg.sender) >= tokenPerShare.mul((10 ** tokenContract.decimals())));
        if (address(this).balance > uint256(1).mul(10 ** 18).div(100)) {
            etherPayout();
        }
        if (tokenContract.balanceOf(address(this)) >= uint256(1).mul(10 ** tokenContract.decimals())) {
            tokenPayout();
        }
        require(processingShare == false);
        uint256 lockedUntil = now.add((tokenLockDays).mul(1 days));
        processingShare = true;
        PayeeShare c = (new PayeeShare)(address(tokenContract), tokenPerShare.mul(10 ** tokenContract.decimals()), lockedUntil); 
        require(tokenContract.transferFrom(msg.sender, address(c), tokenPerShare.mul(10 ** tokenContract.decimals())));
        uint id = shares.push(Share(address(c), percentagePerShare)).sub(1);
        sharesToManager[id] = msg.sender;
        ownerShareCount[msg.sender] = ownerShareCount[msg.sender].add(1);
        emit ShareSigned(msg.sender, address(c), lockedUntil);
        if (tokenLockDays > 0) {
        tokenLockDays = tokenLockDays.sub(1);
        }
        sharesSold = sharesSold.add(1);
        processingShare = false;
        return address(c);
    }
    
    function getSharesByShareOwner(address _shareOwner) external view returns (uint[] memory) {
    uint[] memory result = new uint[](ownerShareCount[_shareOwner]);
    uint counter = 0;
    for (uint i = 0; i < shares.length; i++) {
      if (sharesToManager[i] == _shareOwner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
}

contract AssetSplitShare is Ownable {
        struct AssetFactory {
        address contractAddress;
        address contractCreator;
        string contractType;
    }
    
    AssetFactory[] public contracts;
    
    mapping (uint => address) public contractToOwner;
    mapping (uint => address) public contractToContract;
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    IERC20Token public tokenContract;
    
    event ContractCreated(address contractAddress, address contractCreator, string contractType);
    
    uint256 priceInEther = 3 ether;
    uint256 shareManagerPrice = 15;

    using SafeMath for uint256;
    
    constructor(address _tokenContract) public {
        tokenContract = IERC20Token(_tokenContract);
    }
    
 /*
    function purchaseShareContract(address _tokenContractAddress) public payable returns (address) {
        if (msg.value >= priceInEther) {
            address c = newShare(_tokenContractAddress);
            _owner.transfer(address(this).balance);
            return c;
        } else {
            require(tokenContract.balanceOf(msg.sender) >= shareContractPrice.mul(10 ** tokenContract.decimals()));
            require(tokenContract.transferFrom(msg.sender, _owner, shareContractPrice.mul(10 ** tokenContract.decimals())));
            address c = newShare(_tokenContractAddress);
            return address(c);
        }
    }
    */
    function purchaseShareManager(address _tokenContract, uint256 _pricePerShare, address payable _contractOwner, uint _ownerPercentage, uint _percentagePerShare) public payable returns (address) {
        if (msg.value >= priceInEther) {
            address c = newShareManager(_tokenContract, _pricePerShare, _contractOwner, _ownerPercentage, _percentagePerShare);
            _owner.transfer(address(this).balance);
            return address(c);
        } else {
            require(tokenContract.balanceOf(msg.sender) >= shareManagerPrice.mul(10 ** tokenContract.decimals()));
            require(tokenContract.transferFrom(msg.sender, _owner, shareManagerPrice.mul(10 ** tokenContract.decimals())));
            address c = newShareManager(_tokenContract, _pricePerShare, _contractOwner, _ownerPercentage, _percentagePerShare);
            return address(c);
        }
        
    }

    function newShareManager(address _tokenContract, uint256 _pricePerShare, address payable _contractOwner, uint _ownerPercentage, uint _percentagePerShare) internal returns (address) {
        ShareManager c = (new ShareManager)(_tokenContract, _pricePerShare, _contractOwner, _ownerPercentage, _percentagePerShare);
        uint id = contracts.push(AssetFactory(address(c), tx.origin, "ShareManager")).sub(1);
        contractToOwner[id] = tx.origin;
        emit ContractCreated(address(c), tx.origin, "ShareManager");
        return address(c);
    }
   
    function newShare(address _tokenContractAddress) internal returns (address) {
        PayeeShare c = (new PayeeShare)(_tokenContractAddress, 0, 0);
        uint id = contracts.push(AssetFactory(address(c), tx.origin, "Share")).sub(1);
        contractToContract[id] = msg.sender;
        emit ContractCreated(address(c), tx.origin, "Share");
        return address(c);
    } 
    
    function() external payable {
        
    } 
}