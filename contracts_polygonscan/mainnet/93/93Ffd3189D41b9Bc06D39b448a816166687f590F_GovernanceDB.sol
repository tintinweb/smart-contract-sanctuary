/**
 *Submitted for verification at polygonscan.com on 2021-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/utils/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IGovernanceDB.sol

interface IGovernanceDB
{
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------

    function userIndexLength() external returns(uint256);
    
    //-------------------------------------------------------------------------
    // USER FUNCTIONS
    //-------------------------------------------------------------------------

    function getUserValue(address _user, uint256 _category) external view returns(uint256);
    
    function setUserValue(address _user, uint256 _category, uint256 _value) external;
    
    function setUserValueIfZero(address _user, uint256 _category, uint256 _value) external;
    
    function modifyUserValue(address _user, uint256 _category, uint256 _value, bool _add) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/GovernanceDB.sol

contract GovernanceDB is IGovernanceDB, Ownable
{
    //-------------------------------------------------------------------------
    // STRUCTS
    //-------------------------------------------------------------------------

    struct UserData
    {
        uint256 value;
    }
    
    struct CategoryData
    {
        uint256 id;
        string name;
    }

    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
	
	string public constant VERSION = "0.1.0";
	
	//-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------
    
    CategoryData[] public categoryInfo;
    mapping(uint256 => CategoryData) public categoryMap;
    
    mapping(address => mapping(uint256 => UserData)) userMap;

    address[] public dataProviders;
    
    mapping(uint256 => address) public userIndex; //will be indexed at 1
    mapping(address => uint256) public indexedUser;
    uint256 public override userIndexLength;
    
    address public legacyDB;
	uint256 public legacyOffset = 1;
    
    //-------------------------------------------------------------------------
    // CREATE
    //-------------------------------------------------------------------------
    
    constructor()
    {
        //base
        addCategory(1, "joined");
        addCategory(2, "compound");
        
        //events
        addCategory(1000, "event_beta");
        addCategory(1001, "event_test");
        
        //special
        addCategory(10000, "special_team");
        
        //SYSTEM
        addCategory(999999, "legacyCopied");
    }
    
    //-------------------------------------------------------------------------
    // CATEGORY FUNCTIONS
    //-------------------------------------------------------------------------
    
    function addCategory(uint256 _id, string memory _name) public onlyOwner
    {
        require(_id != 0, "id 0 not allowed");
        require(!hasCategory(_id), "already exists");
        
        //add
        CategoryData storage category = categoryMap[_id];
        category.id = _id;
        category.name = _name;
        categoryInfo.push
        (
            CategoryData(
            {
                id: _id,
                name : _name
            })
        );
    }
    
    function hasCategory(uint256 _id) internal view returns(bool)
    {
        CategoryData storage category = categoryMap[_id];
        return (category.id != 0);
    }
    
    function categoryLength() external view returns(uint256)
    {
        return categoryInfo.length;
    }
    
    //-------------------------------------------------------------------------
    // USER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getUserValue(address _user, uint256 _category) public override view returns(uint256)
    {
        UserData storage userValue = userMap[_user][_category];
        return userValue.value;
    }
    
    function setUserValue(address _user, uint256 _category, uint256 _value) public override onlyOwnerOrDataProvider
    {
        UserData storage userValue = userMap[_user][_category];
        if (hasCategory(_category))
        {
            userValue.value = _value;
        }
    }
    
    function setUserValueIfZero(address _user, uint256 _category, uint256 _value) public override onlyOwnerOrDataProvider
    {
        if (getUserValue(_user, _category) == 0)
        {
            setUserValue(_user, _category, _value);
        }
    }
    
    function modifyUserValue(address _user, uint256 _category, uint256 _value, bool _add) public override onlyOwnerOrDataProvider
    {
        if (!hasCategory(_category))
        {
            return;
        }
        
        uint256 val = getUserValue(_user, _category);
        if (_add)
        {
            val += _value;
        }
        else
        {
            if (_value > val)
            {
                _value = val;
            }
            val -= _value;
        }
        setUserValue(_user, _category, val);
    }
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function tryDownloadFromLegacyDB(address _user) internal
    {
        copyFromLegacy(_user, 1);
        copyFromLegacy(_user, 2);
        copyFromLegacy(_user, 1000);
        copyFromLegacy(_user, 1001);
        copyFromLegacy(_user, 10000);
        
        //set legacy flag
        setUserValue(_user, 999999, 1);
    }
    
    function copyFromLegacy(address _user, uint256 _category) internal
    {
        setUserValue(_user, _category, IGovernanceDB(legacyDB).getUserValue(_user, _category));
    }
    
    function checkUserIndex(address _user) internal
	{
		uint256 user = indexedUser[_user];
		if (user != 0)
		{
			//user is already in index map
			return;
		}
		
		//set user data
		userIndexLength += 1;
		indexedUser[_user] = userIndexLength; //0 is never used
		
		//create user index
		userIndex[user] = _user;
	}
	
	function resetLegacyOffset() public onlyOwner
	{
		legacyOffset = 1;
	}
	
	function downloadFromLegacyDB(uint256 _count) public onlyOwner
	{
        if (legacyDB == address(0))
        {
            return;
        }
	    
	    uint256 to = legacyOffset + _count;
	    if (to > IGovernanceDB(legacyDB).userIndexLength())
	    {
	        to = IGovernanceDB(legacyDB).userIndexLength();
	    }
		for (uint256 n = legacyOffset; n <= to; n++)
		{
			address user = userIndex[n];
			
			//get user data
			if (IGovernanceDB(legacyDB).getUserValue(user, 999999) == 0)
			{
			    tryDownloadFromLegacyDB(user);
			}
			
			//next refund
			legacyOffset += 1;			
		}	
	}
    
    //-------------------------------------------------------------------------
    // SECURITY FUNCTIONS
    //-------------------------------------------------------------------------
    
    modifier onlyOwnerOrDataProvider()
    {
        _onlyOwnerOrDataProvider();
        _;
    }
    
    function _onlyOwnerOrDataProvider() internal view
    {
        if (msg.sender == owner())
        {
            return;
        }
        
        bool found = false;
        for (uint256 n = 0; n < dataProviders.length; n++)
        {
            if (dataProviders[n] == msg.sender)
            {
                found = true;
                break;
            }
        }
        
        require(found, "not owner or provider");
    }
    
    function setLegacyDB(address _db) internal onlyOwner
    {
        legacyDB = _db;
    }
    
    function dataProviderLength() external view returns(uint256)
    {
        return dataProviders.length;
    }
    
    function addDataProvider(address _provider) external onlyOwner
    {
        dataProviders.push(_provider);
    }
    
    function removeDataProvider(address _provider) external onlyOwner
    {
        for (uint256 n = 0; n < dataProviders.length; n++)
        {
            if (dataProviders[n] == _provider)
            {
                //override current value with last in array
                dataProviders[n] = dataProviders[dataProviders.length - 1];
                
                //remove last
                dataProviders.pop();
                return;
            }
        }
    }
}