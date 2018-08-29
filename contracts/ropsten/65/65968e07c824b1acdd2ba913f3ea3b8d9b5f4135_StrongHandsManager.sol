pragma solidity ^0.4.24;

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function balanceOf(address _customerAddress) view external returns(uint256);
}

interface StrongHandsManagerInterface {
    function mint(address _owner, uint256 _amount) external;
}

contract StrongHandsManager {
    
    event CreateStrongHand(address indexed owner, address indexed strongHand);
    
    mapping (address => address) public strongHands;
    mapping (address => uint256) public ownerToBalance;
    
    //ERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    string public constant name = "Stronghands3D";
    string public constant symbol = "S3D";
    uint8 public constant decimals = 18;
    
    uint256 internal tokenSupply = 0;

    function getStrong()
        public
    {
        require(strongHands[msg.sender] == address(0), "you already became a Stronghand");
        
        strongHands[msg.sender] = new StrongHand(msg.sender);
        
        emit CreateStrongHand(msg.sender, strongHands[msg.sender]);
    }
    
    function mint(address _owner, uint256 _amount)
        external
    {
        require(strongHands[_owner] == msg.sender);
        
        tokenSupply+= _amount;
        ownerToBalance[_owner]+= _amount;
        
        emit Transfer(address(0), _owner, _amount);
    }
    
    //ERC20
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokenSupply;
    }
    
    function balanceOf(address _owner)
        public
        view
        returns (uint256)
    {
        return ownerToBalance[_owner];
    }
}

contract StrongHand {

    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    StrongHandsManagerInterface strongHandManager;
    
    address public owner;
    uint256 private p3dBalance = 0;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner)
        public
    {
        owner = _owner;
        strongHandManager = StrongHandsManagerInterface(msg.sender);
    }
    
    function() public payable {}
   
    function buy(address _referrer)
        external
        payable
        onlyOwner
    {
        purchase(msg.value, _referrer);
    }
    
    function purchase(uint256 _amount, address _referrer)
        private
    {
        p3dContract.buy.value(_amount)(_referrer);
        uint256 balance = p3dContract.balanceOf(address(this));
        
        uint256 diff = balance - p3dBalance;
        p3dBalance = balance;
        
        strongHandManager.mint(owner, diff);
    }

    function withdraw()
        external
        onlyOwner
    {
        p3dContract.withdraw();
        owner.transfer(address(this).balance);
    }
}