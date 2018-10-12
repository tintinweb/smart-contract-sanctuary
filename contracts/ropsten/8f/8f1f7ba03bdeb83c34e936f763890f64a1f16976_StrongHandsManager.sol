pragma solidity ^0.4.25;

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function balanceOf(address _customerAddress) view external returns(uint256);
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

contract StrongHandsManager {
    
    event CreatedStrongHand(address indexed owner, address indexed strongHand);
    
    mapping (address => address) public strongHands;
    
    function myStrongHand()
        external
        view
        returns (address)
    {
        address owner = msg.sender;
          
        require(strongHands[owner] != address(0), "You are not a Stronghand");
        
        return strongHands[owner];
    }
    
    function isStrongHand()
        external
        view
        returns (bool)
    {
        address owner = msg.sender;
        
        return strongHands[owner] != address(0);
    }
    
    function create(uint256 _unlockAfterNDays)
        public
    {
        address owner = msg.sender;
        
        require(strongHands[owner] == address(0), "You already became a Stronghand");
        
        strongHands[owner] = new StrongHand(owner, _unlockAfterNDays);
        
        emit CreatedStrongHand(owner, strongHands[owner]);
    }
}

contract StrongHand {

    HourglassInterface constant p3dContract = HourglassInterface(0x0E62d6a4E8354EFC62b1eA7fDFfff2eff0FE5712);
    
    address public owner;
    
    uint256 public creationDate;
    
    uint256 public unlockAfterNDays;
    
    modifier timeLocked()
    {
        require(now >= creationDate + unlockAfterNDays * 1 days);
        _;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner, uint256 _unlockAfterNDays)
        public
    {
        owner = _owner;
        unlockAfterNDays =_unlockAfterNDays;
        
        creationDate = now;
    }
    
    function() public payable {}
    
    function isLocked()
        public
        view
        returns(bool)
    {
        return now < creationDate + unlockAfterNDays * 1 days;
    }
    
    function lockTimeLeft()
        external
        view
        returns(uint256)
    {
        if(isLocked()) {
            return creationDate + unlockAfterNDays * 1 days - now;
        }
        
        return 0;
    }
    
    function extendLock(uint256 _howManyDays)
        external
        onlyOwner
    {
        uint256 newLockTime = unlockAfterNDays + _howManyDays;
        
        require(newLockTime > unlockAfterNDays);
        
        unlockAfterNDays = newLockTime;
    }
    
    //P3D functions
    
    function balanceOf()
        external
        view
        returns(uint256)
    {
        return p3dContract.balanceOf(address(this));
    }
    
    function dividendsOf()
        external
        view
        returns(uint256)
    {
        return p3dContract.myDividends(true);
    }
    
    function buy()
        external
        payable
        onlyOwner
    {
        p3dContract.buy.value(msg.value)(0x1EB2acB92624DA2e601EEb77e2508b32E49012ef);
    }
    
    function reinvest()
        external
        onlyOwner
    {
        p3dContract.reinvest();
    }

    function withdraw()
        external
        onlyOwner
    {
        p3dContract.withdraw();
        
        owner.transfer(address(this).balance);
    }
    
    function sell(uint256 _amount)
        external
        timeLocked
        onlyOwner
    {
        p3dContract.sell(_amount);
        
        owner.transfer(address(this).balance);
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens)
        external
        timeLocked
        onlyOwner
        returns(bool)
    {
        return p3dContract.transfer(_toAddress, _amountOfTokens);
    }
}