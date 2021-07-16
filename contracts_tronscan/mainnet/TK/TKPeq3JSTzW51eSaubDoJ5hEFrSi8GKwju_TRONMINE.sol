//SourceUnit: TRONMINE.sol

pragma solidity >=0.5.10;

/**
 * TRONMINE SMART CONTRACT
 * Register in TRONMINE global smart contract with 100 TRX 
 * using DAP browser and get started with TRONMINE
 * WEBSITE: https://tronmine.net 
 */
contract TRONMINE {
    
    address public contract_owner;

    event Registeration(address indexed member, uint256 amount);
    event MultiTransferred(uint256 amount, address indexed recipient);
    event Airdropped(address indexed recipient, uint256 amount);
    event Transfered(uint256 amount, address indexed recipient);

    using SafeMath for uint256;

    
    constructor() public {
        contract_owner = msg.sender;
    }
    
    
    modifier onlyowner {
        require(contract_owner == msg.sender);
        _;
    }


    function register(uint256 amount) public payable{
        require(msg.value == amount);
        emit Registeration(msg.sender, msg.value);
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

    
    
    function multiTransferTRX(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) public payable onlyowner {

        uint256 totalBalance = address(this).balance;
        uint256 i = 0;
        for (i; i < recipients.length; i++) {

            require(totalBalance >= amounts[i]);
            totalBalance = totalBalance.sub(amounts[i]);

            recipients[i].transfer(amounts[i]);
            emit MultiTransferred(amounts[i], recipients[i]);
        }
    }

    
    
    function airDropTRX(
        address payable[] memory recipients,
        uint256 amount
    ) public payable {
        
        require(msg.value == recipients.length.mul((amount)));

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amount);
            emit Airdropped(recipients[i], amount);
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