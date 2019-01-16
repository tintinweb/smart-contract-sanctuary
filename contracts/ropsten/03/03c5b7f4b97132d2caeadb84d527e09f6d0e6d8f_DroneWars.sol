pragma solidity ^0.4.25;

contract DroneWars {
    using SafeMath for *;
    
    
    /*=================================
    =             EVENTS              =
    =================================*/
    
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    
    
    /*=================================
    =         CONFIGURABLES           =
    ==================================*/
    uint256 internal hiveCost_ = 0.15 ether;
    uint256 internal droneCost_ = 0.01 ether;
    
    
    /*=================================
    =             DATASET             =
    =================================*/
    address internal administrator_;
    address internal fundAddress_;
    uint256 internal pot_;
    mapping (address => uint256) internal vaults_;
    
    address internal queen_;
    address[] internal hives_;
    address[][] internal drones_;
    
    
    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/
    constructor() 
        public 
    {
        queen_ = address(this);
        administrator_ = 0x28436C7453EbA01c6EcbC8a9cAa975f0ADE6Fff1;
        fundAddress_ = 0x1E2F082CB8fd71890777CA55Bd0Ce1299975B25f;
    }
    
    function createHive() public {
        address _player = msg.sender;
        
        require(hives_.length < 4);                                 // only 4 hives
        //require(!ownsHive(_player), "Player already owns a hive");  // does not own a hive
        
        hives_.push(_player);
    }
    
    function createDrone() {
        address _player = msg.sender;
        
        require(hives_.length == 4);    // all hives must be created
        
        _addDroneInternal(_player);
        //_figthQueen();
    }
    
    
    /* View Functions and Helpers */
    function amountHives() 
        public
        view
        returns(uint256)
    {
        hives_.length;
    }
    
    
    /*=================================
    =        PRIVATE FUNCTIONS        =
    =================================*/
    function _addDroneInternal(address _player) 
        internal
    {
        if (drones_.length >= 13)    // 32 cap gen
            return;
    }
    
    function ownsHive(address _player) 
        internal
        view
        returns(bool)
    {
        for (uint8 i = 0; i < hives_.length; i++) {
            if (hives_[i] == _player) {
                return true;
            }
        }
        
        return false;
    }
    
    
    /*=================================
    =            DATA TYPES           =
    =================================*/
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