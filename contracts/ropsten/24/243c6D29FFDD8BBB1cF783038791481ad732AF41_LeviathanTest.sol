/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0+

pragma solidity >0.7.4;

/**
 * (Originally from OpenZeppelin)
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * (Originally from OpenZeppelin)
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}





contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
















/**
 * (Originally from OpenZeppelin)
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * (Originally from OpenZeppelin)
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    // MODIFIED:
    // bool private _allowTransfers;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        // MODIFIED:
        // require(_allowTransfers);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}


/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * (Originally from OpenZeppelin)
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}




/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}

/**
 * @title UpgradeabilityOwnerStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract UpgradeabilityOwnerStorage {
  // Owner of the contract
    address private _upgradeabilityOwner;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
  // Version name of the current implementation
    string internal _version;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() public view returns (string memory) {
        return _version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is EternalStorage, Ownable {
    function pendingOwner() public view returns (address) {
        return addressStorage[keccak256("pendingOwner")];
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner());
        _;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        OwnershipTransferred(owner(), pendingOwner());
        addressStorage[keccak256("owner")] = addressStorage[keccak256("pendingOwner")];
        addressStorage[keccak256("pendingOwner")] = address(0);
    }
}

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This is the storage necessary to perform upgradeable contracts.
 * This means, required state variables for upgradeability purpose and eternal storage per se.
 */
contract OwnedUpgradeabilityStorage is UpgradeabilityOwnerStorage, UpgradeabilityStorage, EternalStorage {}





/**
 * @title LeviathanTest
 */
contract LeviathanTest is ERC20Mintable, OwnedUpgradeabilityStorage, Claimable {

    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address[] private _registry;
    uint256 private _voterid;
    mapping (address => address) private _votes; 

    address payable private _tokenOwnerAddress;
    address payable private _tokenCreatorAddress;

    mapping (address => uint256) private _results;
    mapping (address => address payable[]) private _votedFor; // project addresses => voters
    uint256[] private _amountsToSend;

    address private _first;
    address private _second;
    address private _third;

    uint256 private _inflationamount; // in percentages * 100
    uint256 private _inflationperiod; // in seconds

    IERC20 private _projectToken;
    uint256 private _projectGasMaximum;
    ProjectInfo private _currentProjectInfo;

    mapping (address => mapping (address => uint256)) private _allowedNative;

    // this should be cleared periodically or trimmed
    address[] private _projects;

    uint256 private _projectid;

    struct ProjectInfo {
      address holderAddress;
      address contractAddress;
      IERC20 projectToken;
      uint256 amountOffered;
      uint256 giveawayAmount;
      uint256 amountForSale;
      uint256 timeRegistered;
      uint256 projectID;
      uint256 salePrice;
      string description;
    }

    // this should be cleared periodically, or at least trimmed
    mapping (address => ProjectInfo) private _projectsData;


    constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply, address payable tokenOwnerAddress, address payable tokenCreatorAddress) payable {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;
      _voterid = 0;
      _projectid = 0;
      // _allowTransfers = true;
      _inflationamount = 50;
      _inflationperiod = 600;
      _tokenOwnerAddress = tokenOwnerAddress;
      _tokenCreatorAddress = tokenCreatorAddress;

      // set tokenOwnerAddress as owner of initial supply, more tokens can be minted later
      _mint(tokenCreatorAddress, initialSupply);

    }

    event Count(address vote, uint256 balance);
    event Multisended(uint256 total, address tokenAddress);
    event Test(string message);
    
    function isContract(address _addr) private view returns (bool){
      uint32 size;
      assembly {
        size := extcodesize(_addr)
      }
      return (size > 0);
    }

    function setVote(address choice) public {
      _setVote(msg.sender, choice);
    }

    function _setVote(address voter, address choice) internal {

      Test("setting vote");

      require(balanceOf(voter) > 0);

      Test("voter balance > 0");

      // require(isContract(choice));

      _registry[_voterid] = voter;
      _votes[voter] = choice;
      _voterid ++;
      Test("finished setting vote");
    }

    function checkMyVote() public view returns (address) {
      return _votes[msg.sender];
      // should return name of the token they're voting for, or none -- might be unnecessary
    }

    function checkTokenOwner() public view returns (address) {
      return _tokenOwnerAddress;
    }

    function _countVotes() internal onlyMinter {

      // this function is.. so inefficient, need to change even if not over gas limit

      Test("counting votes");

      // _allowTransfers = false;
      for (uint256 i=0; i<_registry.length; i++) {
        // may need to check if that _results locus is empty and adjust accordingly
        _results[_votes[_registry[i]]] += balanceOf(_registry[i]);
        _votedFor[_votes[_registry[i]]].push(payable(_registry[i]));
      }

      Test("counted votes");

      // _allowTransfers = true;

      for (uint256 i=0; i<_projects.length; i++) {
        // modify to account for tied votes? or just make clear that first project to register wins ties
        if (_results[_projects[i]] > _results[_first]) {
          _third = _second;
          _second = _first;
          _first = _projects[i];
        } else if (_results[_projects[i]] > _results[_second]) {
          _third = _second;
          _second = _projects[i];
        } else if (_results[_projects[i]] > _results[_third]) {
          _third = _projects[i];
        }  
      }

      Test("ranked winners");

      // this may go over gas limit, might have to remove elements one by one (like reduce length as we loop through _registry backwards)
      delete _registry;
      _voterid = 0;

      Test("deleted voter registry");

      Test("vote counter done");
    }

    function registerProject(address projectContractAddress, uint256 amountOffered, uint256 giveawayAmount, uint256 amountForSale, uint256 sellPrice, string calldata projectDescription) public payable {
      // have the person approve some amount of coins for the minter to control
      // they know the minter will pay them back automatically
      // this requires minter account be locked
      // it could be ok if there are shoddy deals bc we can curate the display site for the best ones

      // see this for dealing with different tokens:
      // https://forum.openzeppelin.com/t/is-it-possible-to-call-the-erc20-approve-function-from-another-contract/2758/2

      // we should make clear that the gas value is in wei
      // also we need to test if the token value ignores decimals or not, they prob have to adjust for decimals or we do

      Test("registering project");

      // require that project is offering token
      require(amountOffered > 0);

      Test("verified nonzero offer");

      // verify that projectContractAddress is a contract address
      require(isContract(projectContractAddress));

      Test("address verified");

      require(!isRegisteredToken(projectContractAddress));

      Test("verified unique token");

      _projectToken = IERC20(projectContractAddress);

      Test("defined project token");

      // verify that they have enough project tokens
      require(_projectToken.balanceOf(msg.sender) >= (amountOffered + amountForSale + giveawayAmount));

      Test("verified project token balance");
      
      // calculate gas cost (need to guarantee that it'll be enough)
      // set this to _projectGasMaximum
      // potentially the gas cost could be the same for all of them/there could be a flat gas cost
      // this should even include transaction fee of sending the gas to us
      // gas cost estimate might just come from manual testing??
      _projectGasMaximum = 0;

      Test("set project gas maximum");

      // verify that they have enough gas
      // if not the error should tell them how much they need
      // or some other way of informing them/giving them a flat amount to send
      // they also need more gas in their account to transfer if they win
      require(msg.sender.balance >= _projectGasMaximum);

      Test("verified that holder has enough gas money");
      
      // they pay our gas cost up front:
      _tokenOwnerAddress.transfer(_projectGasMaximum);

      Test("holder transferred gas max");

      // approve minter to spend their project tokens:
      // note: might have to change this to have them send us the tokens, less gas-efficient though
      //_projectToken.approve(_tokenOwnerAddress, amountOffered + amountForSale + giveawayAmount);

      // they send us the offered and giveaway tokens
      _projectToken.transfer(_tokenOwnerAddress, amountOffered + amountForSale + giveawayAmount);

      Test("holder transferred project tokens");

      // store all the project's info
      _projects[_projectid] = msg.sender;
      _projectsData[msg.sender] = ProjectInfo(msg.sender, projectContractAddress, IERC20(projectContractAddress), amountOffered, giveawayAmount, amountForSale, block.timestamp, _projectid, sellPrice, projectDescription);

      Test("add project data to mapping");

      _projectid ++;

      // inform them that they need to have the right amounts in their holder wallet during the election in order to win

      Test("done registering project");

    }

    // mint inflation and distribute top 3 tokens
    function _inflationDistribute() internal onlyMinter {

      // need to account for decimals -- all this math must be done in weird decimal way (for all math in the whole contract)

      Test("distribulting inflation");

      // eliminate redundancies in the following sections:

      delete _amountsToSend;

      Test("deleted _amountstosend");

      // generate proportional winnings amounts for voters
      uint8 i = 0;
      for (i; i < _votedFor[_first].length; i++) {
        _amountsToSend[i] = (balanceOf(_votedFor[_first][i])/_results[_first])*_projectsData[_first].amountOffered;
      }

      Test("generate proportional winnings for _first voters");

      // send winning tokens to voters, last input is proportional amount of winnings
      multisendToken(_projectsData[_first].contractAddress, _votedFor[_first], _amountsToSend);

      Test("distribute _first winnings to voters");

      // remove winning project
      _removeWinnerProject(_first);

      Test("remove _first project");
      
      i = 0;
      for (i; i < _votedFor[_second].length; i++) {
        _amountsToSend[i] = (balanceOf(_votedFor[_second][i])/_results[_second])*_projectsData[_second].amountOffered;
      }
      multisendToken(_projectsData[_second].contractAddress, _votedFor[_second], _amountsToSend);
      _removeWinnerProject(_second);
      i = 0;
      for (i; i < _votedFor[_third].length; i++) {
        _amountsToSend[i] = (balanceOf(_votedFor[_third][i])/_results[_third])*_projectsData[_third].amountOffered;
      }
      multisendToken(_projectsData[_third].contractAddress, _votedFor[_third], _amountsToSend);
      _removeWinnerProject(_third);

      Test("repeated for _second and _third");

      // calculate # of inflation tokens
      uint256 _newtokens = (totalSupply()*_inflationamount)/10000;

      Test("calculated new token amount");

      // mint tokens to winning projects
      _mint(_first, _newtokens/2);
      _mint(_second, _newtokens/3);
      _mint(_third, _newtokens/6);

      Test("minted tokens to winners");

      Test("finished distributing inflation");
    }

    // distribute giveaway project tokens during election
    function _giveawayDistribute() internal onlyMinter {

      Test("distributing giveaways");

      uint8 i = 0;
      delete _amountsToSend;
      for (i; i < _projects.length; i++) {
        if (_results[_projects[i]] > 0) {
          for (i; i < _votedFor[_projects[i]].length; i++) {
            _amountsToSend[i] = (balanceOf(_votedFor[_projects[i]][i])/_results[_projects[i]])*_projectsData[_projects[i]].giveawayAmount;
          }
          multisendToken(_projectsData[_projects[i]].contractAddress, _votedFor[_projects[i]], _amountsToSend);
        }
      }

      Test("finished distributing giveaways");
    }

    // add tokens to the giveaway pool of a certain project if you're the project's holder
    function _addToGiveawayAmount(uint256 amountToAdd) public payable {

      Test("adding to giveaway amount");

      // verify that the holder has a registered token
      require(_projectsData[msg.sender].amountOffered > 0);

      Test("verified holder token existence");

      // get that token's data
      _currentProjectInfo = _projectsData[msg.sender];

      Test("grabbed project info");

      // set that token's IERC20
      _projectToken = IERC20(_currentProjectInfo.contractAddress);

      Test("set token IERC20");
      
      // verify that holder has enough of their token to add amountToAdd
      require(_projectToken.balanceOf(msg.sender) >= amountToAdd);

      Test("verified holder token supply");

      // transferring tokens to add
      _projectToken.transfer(_tokenOwnerAddress, amountToAdd);

      Test("transferred additional tokens");

      Test("finished adding giveaway tokens");

      // potentially need to have them add more gas as well -- depends if gas is proportional to amount
      // it probably isn't proportional to amount of giveaway as much as to number of voters being transferred to
    }

    // check whether a token is registered
    function isRegisteredToken(address contractAddress) public view returns (bool) {
      uint8 i;
      for (i; i < _projects.length; i++) {
        if (_projectsData[_projects[i]].contractAddress == contractAddress){
          return true;
        }
      }
      return false;
    }

    // allow people to buy project tokens that are up for sale (separate from election system)
    // need to figure out how to control minter or set up allowance system properly (see dex examples?)
    function buyProjectToken(address holder, uint256 amountToBuy) public payable {

      // verify that token is registered there is enough sellable supply available
      require(_projectsData[holder].amountForSale >= amountToBuy);

      // set token IERC20

      // transfer payment (native) to holder

      // transfer tokens to buyer
    }

    // allow LVT holders to vote on inflation amount, inflation period, and anything else -- works like 1inch governance
    function _runGovernanceElection() internal onlyMinter {
    }

    // this is just a placeholder, need to create both bsc and eth contracts to build token bridge
    // also, plan to automate bridging for erc-20 project tokens -- we'll distribute as bep-20s
    function crossBridge() public payable {
    }

    // remove a winner project from the registy
    function _removeWinnerProject(address holderAddress) private onlyMinter {

      // delete from _projects array
      delete _projects[_projectsData[holderAddress].projectID];

      // delete from _projectsData mapping
      delete _projectsData[holderAddress];
    }

    // remove my project from the registry
    function removeMyProject() public payable {

      Test("removing my project");

      // only allow removal if it's been there for longer than 4 weeks
      require((block.timestamp-_projectsData[msg.sender].timeRegistered) >= (604800*4));

      Test("verified project age");

      // delete from _projects array
      delete _projects[_projectsData[msg.sender].projectID];

      // delete from _projectsData mapping
      delete _projectsData[msg.sender];

      Test("finished removing my project");
    }

    function _runElection() public onlyMinter {
      // add events to track progress, votes, results
      // need to make this automatically run every two weeks
      // should change so it uses memory less, like have _countVotes return winners instead of saving

      Test("running election");

      _countVotes();
      _inflationDistribute();
      _giveawayDistribute();
      _runGovernanceElection();

      _projectid = 0;

      Test("finished running election");
    }

    function multisendToken(address token, address payable[] memory _contributors, uint256[] memory _balances) public payable {
        if (token == 0x000000000000000000000000000000000000bEEF){
            multisendEther(_contributors, _balances);
        } else {
            uint256 total = 0;
            require(_contributors.length <= arrayLimit());
            IERC20 erc20token = IERC20(token);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
                total += _balances[i];
            }
            setTxCount(msg.sender, txCount(msg.sender).add(1));
            Multisended(total, token);
        }
    }

    function multisendEther(address payable[] memory _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        require(_contributors.length <= arrayLimit());
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function arrayLimit() public view returns(uint256) {
        return uintStorage[keccak256("arrayLimit")];
    }

    function setTxCount(address customer, uint256 _txCount) private {
        uintStorage[keccak256(abi.encodePacked("txCount", customer))] = _txCount;
    }

    function txCount(address customer) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("txCount", customer))];
    }


    // optional functions from ERC20 standard

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
      return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
      return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
      return _decimals;
    }
}