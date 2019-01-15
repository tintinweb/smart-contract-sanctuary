pragma solidity ^0.5.0;

interface TeamInterface {

    function isOwner() external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function isDev(address _sender) external view returns (bool);

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

}

/**
 * @title Platform Contract
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3a4c4953484342577a0b0c0914595557">[email&#160;protected]</a>>
 */
contract Platform {

    using SafeMath for *;
    uint256 allTurnover; 
    mapping(bytes32 => uint256) turnover; 
    
    address payable private foundAddress; 
    TeamInterface private team; 

    constructor(address payable _foundAddress, address _teamAddress) public {
        require(
            _foundAddress != address(0) &&
            _teamAddress != address(0)
        );
        foundAddress = _foundAddress;
        team = TeamInterface(_teamAddress);
    }

    function() external payable {
        revert();
    }

    event OnUpgrade(address indexed _teamAddress);
    event OnDeposit(bytes32 _worksID, address indexed _address, uint256 _amount); 
    event OnUpdateTurnover(bytes32 _worksID, uint256 _amount);
    event OnUpdateAllTurnover(uint256 _amount);
    event OnUpdateFoundAddress(address indexed _sender, address indexed _address);
    event OnTransferTo(address indexed _receiver, uint256 _amount);

    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }
    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    function upgrade(address _teamAddress) external onlyAdmin() {
        require(_teamAddress != address(0));
        team = TeamInterface(_teamAddress);
        emit OnUpgrade(_teamAddress);
    }



    function getAllTurnover() external view returns (uint256) {
        return allTurnover;
    }

    function getTurnover(bytes32 _worksID) external view returns (uint256) {
        return turnover[_worksID];
    }

    function updateAllTurnover(uint256 _amount) external onlyDev() {
        allTurnover = allTurnover.add(_amount); 
        emit OnUpdateAllTurnover(_amount);
    }   

    function updateTurnover(bytes32 _worksID, uint256 _amount) external onlyDev() {
        turnover[_worksID] = turnover[_worksID].add(_amount); 
        emit OnUpdateTurnover(_worksID, _amount);
    }

    function updateFoundAddress(address payable _foundAddress) external onlyAdmin() {
        foundAddress = _foundAddress;
        emit OnUpdateFoundAddress(msg.sender, _foundAddress);
    }

    function deposit(bytes32 _worksID) external payable {
        require(_worksID != bytes32(0)); 
        emit OnDeposit(_worksID, msg.sender, msg.value);
    }

    function transferTo(address payable _receiver, uint256 _amount) external onlyDev() {
        require(_amount <= address(this).balance);
        _receiver.transfer(_amount);
        emit OnTransferTo(_receiver, _amount);
    }

    function getFoundAddress() external view returns (address payable) {
        return foundAddress;
    }

    function balances() external view onlyDev() returns (uint256) {
        return address(this).balance;
    }

}