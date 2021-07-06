/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// File: contracts/WhiteList/WhiteListHelper.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24 <0.7.0;

contract WhiteListHelper{
    event NewWhiteList(uint _WhiteListCount, address _creator, address _contract, uint _changeUntil);

    modifier OnlyCreator(uint256 _Id) {
        require(
            WhitelistSettings[_Id].Creator == msg.sender,
            "Only creator can access"
        );
        _;
    }

    modifier TimeRemaining(uint256 _Id){
        require(
            now < WhitelistSettings[_Id].ChangeUntil,
            "Time for edit is finished"
        );
        _;
    }

    modifier ValidateId(uint256 _Id){
        require(_Id < WhiteListCount, "Wrong ID");
        _;
    }

    struct WhiteListItem {
        // uint256 Limit;
        address Creator;
        uint256 ChangeUntil;
        //uint256 DrawLimit;
        //uint256 SignUpPrice;
        address Contract;
        // mapping(address => uint256) WhiteListDB;
        bool isReady; // defualt false | true after first address is added
    }

    mapping(uint256 => mapping(address => uint256)) public WhitelistDB;
    mapping(uint256 => WhiteListItem) public WhitelistSettings;
    uint256 public WhiteListCost;
    uint256 public WhiteListCount;

    function _AddAddress(uint256 _Id, address user, uint amount) internal {
        WhitelistDB[_Id][user] = amount;
    }

    function _RemoveAddress(uint256 _Id, address user) internal {
        WhitelistDB[_Id][user] = 0;
    }

    function isWhiteListReady(uint256 _Id) external view returns(bool){
        return WhitelistSettings[_Id].isReady;
    }

    //View function to Check if address is whitelisted
    function Check(address _user, uint256 _id) external view returns(uint){
        if (_id == 0) return uint256(-1);
        return WhitelistDB[_id][_user];
    }
}

// File: openzeppelin-solidity/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/WhiteList/WhiteList.sol


pragma solidity >=0.4.24 <0.7.0;



contract WhiteList is WhiteListHelper, Ownable{
    constructor() public {
        WhiteListCount = 1; //0 is off
        MaxUsersLimit = 500;
    }

    //uint256 public SignUpCost;
    uint256 public MaxUsersLimit;

    modifier isBelowUserLimit(uint256 _limit) {
        require(_limit <= MaxUsersLimit, "Maximum User Limit exceeded");
        _;
    }

    function setMaxUsersLimit(uint256 _limit) external onlyOwner {
        MaxUsersLimit = _limit;
    }
    
    function WithdrawETHFee(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance); 
    }

    function setWhiteListCost(uint256 _newCost) external onlyOwner {
        WhiteListCost = _newCost;
    }

    function CreateManualWhiteList(
        uint256 _ChangeUntil,
        address _Contract
    ) public payable returns (uint256 Id) {
        require(msg.value >= WhiteListCost, "ether not enough");
        WhitelistSettings[WhiteListCount] =  WhiteListItem(
            /*_Limit == 0 ? uint256(-1) :*/
            // _Limit,
            msg.sender,
            _ChangeUntil,
            _Contract,
            false
        );
        uint256 temp = WhiteListCount;
        WhiteListCount++;
        emit NewWhiteList(temp, msg.sender, _Contract, _ChangeUntil);
        return temp;
    }

    function ChangeCreator(uint256 _Id, address _NewCreator)
        external
        ValidateId(_Id)
        OnlyCreator(_Id)
        TimeRemaining(_Id)
    {
        WhitelistSettings[_Id].Creator = _NewCreator;
    }

    function ChangeContract(uint256 _Id, address _NewContract)
        external
        ValidateId(_Id)
        OnlyCreator(_Id)
        TimeRemaining(_Id)
    {
        WhitelistSettings[_Id].Contract = _NewContract;
    }

    function AddAddress(uint256 _Id, address[] calldata _Users, uint256[] calldata _Amount)
        public
        ValidateId(_Id)
        OnlyCreator(_Id)
        TimeRemaining(_Id)
        isBelowUserLimit(_Users.length)
    {
        require(_Users.length == _Amount.length, "Number of users should be same as the amount length");
        require(_Users.length > 0,"Need something...");
        if(!WhitelistSettings[_Id].isReady){
            WhitelistSettings[_Id].isReady = true;
        }
        for (uint256 index = 0; index < _Users.length; index++) {
            _AddAddress(_Id, _Users[index], _Amount[index]);
        }
    }

    function RemoveAddress(uint256 _Id, address[] calldata _Users)
        public
        OnlyCreator(_Id)
        TimeRemaining(_Id)
        ValidateId(_Id)
        isBelowUserLimit(_Users.length)
    {
        for (uint256 index = 0; index < _Users.length; index++) {
            _RemoveAddress(_Id, _Users[index]);
        }
    }

    function Register(
        address _Subject,
        uint256 _Id,
        uint256 _Amount
    ) external {
        if (_Id == 0) return;
        require(
            msg.sender == WhitelistSettings[_Id].Contract,
            "Only the Contract can call this"
        );
        require(
            WhitelistDB[_Id][_Subject] >= _Amount,
            "Sorry, no alocation for Subject"
        );
        uint256 temp = WhitelistDB[_Id][_Subject] - _Amount;
        WhitelistDB[_Id][_Subject] = temp;
        assert(WhitelistDB[_Id][_Subject] == temp);
    }

    function LastRoundRegister(
        address _Subject,
        uint256 _Id
    ) external {
        if (_Id == 0) return;
        require(
            msg.sender == WhitelistSettings[_Id].Contract,
            "Only the Contract can call this"
        );
        require(
            WhitelistDB[_Id][_Subject] != uint256(-1),
            "Sorry, no alocation for Subject"
        );
        uint256 temp = uint256(-1);
        WhitelistDB[_Id][_Subject] = temp;
        assert(WhitelistDB[_Id][_Subject] == temp);
    }
}