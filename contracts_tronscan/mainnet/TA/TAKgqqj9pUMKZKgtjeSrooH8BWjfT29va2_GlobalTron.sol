//SourceUnit: GlobalTron.sol

pragma solidity >=0.5.10;

/**
 * GLOBAL TRON SMART CONTRACT 
 * WEBSITE: HTTPS://GLOBALTRON.ORG 
 */
contract GlobalTron {
    
    address public contract_owner;

    event Multisended(uint256 value, address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    event Transfered(uint256 value, address indexed recipient);
    using SafeMath for uint256;

    
    constructor() public {
        contract_owner = msg.sender;
    }
    
    
    modifier onlyowner {
        require(contract_owner == msg.sender);
        _;
    }

    
    function transferTRX(address payable recipient, uint256 amount)
        public
        payable
        onlyowner
    {
        require(amount <= address(this).balance);
        recipient.transfer(amount);
        emit Transfered(amount, recipient);
    }

    
    
    function investTRX(
        uint256 _amount
    ) public payable {
        uint256 total = msg.value;
        emit Multisended(msg.value, msg.sender);
    }

    
    
    function airDropTRX(
        address payable[] memory _userAddresses,
        uint256 _amount
    ) public payable {
        
        require(msg.value == _userAddresses.length.mul((_amount)));
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }
}



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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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