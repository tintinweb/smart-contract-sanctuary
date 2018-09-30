pragma solidity ^0.4.24;

// File: contracts/zeppelin/ownership/Ownable.sol

/**
* @title Ownable
* @dev The ownable contract has owner address, and provide basic athorization control functions,
*       this is simplifies implementation of "user permission" 
*/
contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

/**
* @dev The ownable constructor sets the original `owner` of the contact to the sender account
*/
    constructor() public{
        _owner = msg.sender;
    }

/**
* @return the address of the owner 
*/
    function owner() public view returns(address){
        return _owner;
    }

/**
* @dev Throws if called by any account other than owner */
    modifier onlyOwner(){
        require(isOwner(), "msg.sender is not the onwer of this contract");
        _;
    }

/**
* @return true if `msg.sender` is the owner of the contract */
    function isOwner() public view returns(bool){
        return msg.sender == _owner;
    }

/**
* @dev Allow current owner relinquish control of the contract
* @notice Renouncing to ownership will leave the contract without an onwer
* It will not possible to call the functions with the `onlyOwner` modifier anymore
*/
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

/**
* @dev Allow current owner transfer control of the contract to newOnwer 
*/
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

/**
* @param newOwner The address to transfer ownership to.
*/
    function _transferOwnership(address newOwner) internal{
        require(newOwner != address(0), "Address incorrect");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

// File: contracts/zeppelin/math/SafeMath.sol

/**
* @title SafeMath
* @dev Math operations that security checkd that throw on error 
*/
library SafeMath {

/**
* @dev Multiplies two numbers, throw overflow 
*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0){
            return a;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    } 
/**
* @dev Integer devision of two number truncating the quotient, reverts division by zero
*/

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "b must be larger than zero");
        uint256 c = a / b;
        return c;
    }
/**
* @dev Subtracts two numbers, reverts on overflow 
*/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "b must be lower than a");
        uint256 c = a - b;
        return c;
    }
/**
* @dev Adds two number reverts on overflow
*/
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a, "c must be larger than a");
        return c;
    }

/**
* @dev Divides two numbers and returns the remainder (unsign integer modulo),
* reverts when dividing by zero */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b!=0,"b can not equal to zero");
        return a % b;
    }

}

// File: contracts/ContributorList.sol

contract ContributorList is Ownable {

    using SafeMath for uint256;

    
    mapping(address => bool) _whiteListAddresses;
    mapping(address => uint256) _contributors;

    uint256 private _minContribution; // ETH
    uint256 private _maxContribution; // ETH
    address private _adminAddress;

    modifier onlyAdmin(){
        require(msg.sender == _adminAddress, "Permision denied");
        _;
    }

    constructor(uint256 minContribution, uint256 maxContribution, address adminAddress) public {
        require(minContribution > 0, "Invalid MinContribution");
        require(maxContribution > 0, "Invalid MaxContribution");
        _minContribution = minContribution;
        _maxContribution = maxContribution;
        _adminAddress = adminAddress;
    }

    event UpdateWhiteList(address user, bool isAllowed, uint256 time );

/**
* @dev Update contributor address in whitelist
* @param user Address of contributor
* @param isAllowed is allowed status
*/
    function updateWhiteList(address user, bool isAllowed) 
    public
    onlyAdmin{
        _whiteListAddresses[user] = isAllowed;
        emit UpdateWhiteList(user,isAllowed, block.timestamp);
    }

/**
* @dev Update list of contributors in whitelist
* @param users Array of whitelist address
* @param isAlloweds Array of is allowed status
*/
    function updateWhiteLists(address[] users, bool[] isAlloweds)
    public
    onlyAdmin{
        for (uint i = 0 ; i < users.length ; i++) {
            address _user = users[i];
            bool _allow = isAlloweds[i];
            _whiteListAddresses[_user] = _allow;
            emit UpdateWhiteList(_user, _allow, block.timestamp);
        }
    }

/**
* @dev Get Eligible Cap Amount 
* @param contributor Address of contributor
* @param amount  Intended contribution ETH amount
* @return Eligible Cap Amount 
*/
    function getEligibleAmount(address contributor, uint256 amount) public view returns(uint256){
        
        if(amount < _minContribution){
            return 0;
        }

        uint256 contributorMaxContribution = _maxContribution;
        uint256 remainingCap = contributorMaxContribution.sub(_contributors[contributor]);

        return (remainingCap > amount) ? amount : remainingCap;
    }

/**
*@dev Allowed contributor to increase contribution amount
*@param contributor Address of contributor
*@param amount Intened contribution ETH amount to increase
*/
    function increaseContribution(address contributor, uint256 amount)
    internal
    returns(uint256)
    {
        if(!_whiteListAddresses[contributor]){
            return 0;
        }
        uint256 result = getEligibleAmount(contributor,amount);
        _contributors[contributor] = _contributors[contributor].add(result);
        return result;
    }


}

// File: contracts/CrowdSaleTest.sol

contract CrowdSaleTest  {
    ContributorList public _contributorList;

    constructor (ContributorList contributorList) public{
        _contributorList = contributorList;
    }
}