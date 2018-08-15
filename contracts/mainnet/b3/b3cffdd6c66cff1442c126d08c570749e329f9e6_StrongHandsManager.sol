pragma solidity ^0.4.24;

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
}

contract StrongHandsManager {
    
    event CreateStrongHand(address indexed owner, address indexed strongHand);
    
    mapping (address => address) public strongHands;
    
    function getStrong(address _referrer)
        public
        payable
    {
        require(strongHands[msg.sender] == address(0), "you already became a Stronghand");
        
        strongHands[msg.sender] = (new StrongHand).value(msg.value)(msg.sender, _referrer);
        
        emit CreateStrongHand(msg.sender, strongHands[msg.sender]);
    }
}

contract StrongHand {

    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    
    address public owner;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner, address _referrer)
        public
        payable
    {
        owner = _owner;
        
        purchase(msg.value, _referrer);
    }
    
    function() public payable {}
   
    function buy(address _referrer)
        public
        payable
        onlyOwner
    {
        purchase(msg.value, _referrer);
    }
    
    function purchase(uint256 amount, address _referrer)
        private
    {
        p3dContract.buy.value(amount)(_referrer);
    }

    function withdraw()
        external
        onlyOwner
    {
        p3dContract.withdraw();
        owner.transfer(address(this).balance);
    }
}