pragma solidity ^0.4.22;

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }
}
/** @author OVCode Switzerland AG */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    /**
    * @dev constructor
    */
    function SafeMath() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/** @author OVCode Switzerland AG */

contract TokenERC20 is SafeMath {
    // Public variables of the token
    string public name;
    string public symbol;
    
    // 18 decimals is the strongly suggested default, avoid changing it
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ReceiveApproval(address _from, uint256 _value, address _token);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
    * For the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    /**
    * @dev constructor
    */
    function TokenERC20() public {
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(safeAdd(balanceOf[_to],_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = safeAdd(balanceOf[_from],balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = safeSub(balanceOf[_from],_value);
        // Add the same to the recipient
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
        _transfer(msg.sender, _to, _value);
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
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(32 * 3) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);
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
    function approve(address _spender, uint256 _value) onlyPayloadSize(32 * 2) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit ReceiveApproval(msg.sender, _value, this);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);  // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
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
    function burnFrom(address _from, uint256 _value) onlyPayloadSize(32 * 2) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = safeSub(balanceOf[_from],_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);             // Subtract from the sender&#39;s allowance
        totalSupply = safeSub(totalSupply,_value);                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/** @author OVCode Switzerland AG */


contract OVC is Ownable, TokenERC20 {

    uint256 public ovcPerEther = 0;
    uint256 public minOVC;
    uint256 public constant ICO_START_TIME = 1526891400; // 05.21.2018 08:30:00 UTC
    uint256 public constant ICO_END_TIME = 1532131199; // 07.20.2018 11:59:59 UTC

    uint256 public totalOVCSold = 0;
    
    OVCLockAllocation public lockedAllocation;
    mapping (address => bool) public frozenAccount;
  
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event ChangeOvcEtherConversion(address owner, uint256 amount);
    /* Initializes contract, Total Supply (83,875,000 OVC), name (OVCODE) and symbol (OVC), Min OVC Per Wallet
    // Assign the 30,000,000 of the total supply to the presale account
    // Assign the 10,500,000 of the total supply to the First ICO account
    // Assign the 11,000,000 of the total supply to the Second ICO account
    // Assign the 1,075,000 of the total supply to the bonus account
    // Assign the 2,450,000 of the total supply to the bounty account
    // Assign the 14,850,000 of the total supply to the first investor account
    // Assign the 4,000,000 of the total supply to the second investor account
    // Lock-in the 10,000,000 of the total supply to `OVCLockAllocation` contract within 36 months(unlock 1/3 every 12 months)
    */
    function OVC() public {

        totalSupply = safeMul(83875000,(10 ** uint256(decimals) ));  // Update total supply(83,875,000) with the decimal amount
        name = "OVCODE";  // Set the name for display purposes
        symbol = "OVC";   // Set the symbol for display purposes
        
        // 30,000,000 tokens for Presale 
        balanceOf[msg.sender] = safeMul(30000000,(10 ** uint256(decimals))); 

        // 11,000,000 ICO tokens for direct buy on the smart contract
        /* @notice Transfer this token to OVC Smart Contract Address 
          to enable the puchaser to buy directly on the contract */
        address icoAccount1 = 0xe5aB5D1Da8817bFB4b0Af44eFDcCC850a47E477a;
        balanceOf[icoAccount1] = safeMul(11000000,(10 ** uint256(decimals))); 

        // 10,500,000 ICO tokens for cash and btc purchaser
        /* @notice This account will be used to send token 
            to the purchaser that used BTC or CASH */
        address icoAccount2 = 0xfD382a7478ce3ddCd6a03F6c1848F31659753388;
        balanceOf[icoAccount2] = safeMul(10500000,(10 ** uint256(decimals))); 

        // 1,075,000 tokens for bonus, referrals and discounts
        address bonusAccount = 0xAde1Cf49c41919658132FF003C409fBcb2909472;
        balanceOf[bonusAccount] = safeMul(1075000,(10 ** uint256(decimals)));
        
        // 2,450,000 tokens for bounty
        address bountyAccount = 0xb690acb524BFBD968A91D614654aEEC5041597E0;
        balanceOf[bountyAccount] = safeMul(2450000,(10 ** uint256(decimals)));

        // 14,850,000 & 4,000,000 for our investors
        address investor1 = 0x17dC8dD84bD8DbAC168209360EDc1E8539D965DA;
        balanceOf[investor1] = safeMul(14850000,(10 ** uint256(decimals)));
        address investor2 = 0x5B2213eeFc9b7939D863085f7F2D9D1f3a771D5f;
        balanceOf[investor2] = safeMul(4000000,(10 ** uint256(decimals)));
        
        // Founder and Developer 10,000,000 of the total Supply / Lock-in within 36 months(unlock 1/3 every 12 months)
        uint256 totalAllocation = safeMul(10000000,(10 ** uint256(decimals)));
        
        // Initilize the `OVCLockAllocation` contract with the totalAllocation and 3 allocated wallets
        address firstAllocatedWallet = 0xD0427222388145a1A14F5FC4a376e8412C39c6a4;
        address secondAllocatedWallet = 0xe141c480274376A4eB499ACEeD84c47b5FDF4B39;
        address thirdAllocatedWallet = 0xD46811aBe15a53dd76b309E3e1f8f9C4550D3918;
        lockedAllocation = new OVCLockAllocation(totalAllocation,firstAllocatedWallet,secondAllocatedWallet,thirdAllocatedWallet);
        // Assign the 10,000,000 lock token to the `OVCLockAllocation` contract address
        balanceOf[lockedAllocation] = totalAllocation;

        // @notice Minimum token per wallet 10 OVC
        minOVC = safeMul(10,(10 ** uint256(decimals)));
    }
    
    /* @notice Allow user to send ether directly to the contract address */
    function () public payable {
        buyTokens();
    }
    
    /* @notice private function for buy token, enable the purchaser to 
    // send Ether directly to the contract address */
    function buyTokens() private {
        require(now > ICO_START_TIME );
        require(now < ICO_END_TIME );

        uint256 _value = safeMul(msg.value,ovcPerEther);
        uint256 futureBalance = safeAdd(balanceOf[msg.sender],_value);

        require(futureBalance >= minOVC);
        owner.transfer(address(this).balance);

        _transfer(this, msg.sender, _value);
        totalOVCSold = safeAdd(totalOVCSold,_value);
    }
    
     /* @notice Change the current amount of OVC token per Ether */
    function changeOVCPerEther(uint256 amount) onlyPayloadSize(1 * 32) onlyOwner public {
        require(amount >= 0);
        ovcPerEther = amount;
        emit ChangeOvcEtherConversion(msg.sender, amount);
    }

    /* @notice Transfer all unsold token to the contract owner */
    function transferUnsoldToken() onlyOwner public {
        require(now > ICO_END_TIME );
        require (balanceOf[this] > 0); 
        uint256 unsoldToken = balanceOf[this]; 
        _transfer(this, msg.sender, unsoldToken);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough balance
        require (safeAdd(balanceOf[_to],_value) > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = safeSub(balanceOf[_from],_value);// Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);// Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyPayloadSize(32 * 2) onlyOwner public {
        balanceOf[target] = safeAdd(balanceOf[target],mintedAmount);
        totalSupply = safeAdd(totalSupply,mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

/** @author OVCode Switzerland AG */


contract OVCLockAllocation is SafeMath {

    uint256 public totalLockAllocated;
    OVC public ovc;
    /**
    * For the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    struct Allocations {
        uint256 allocated;
        uint256 unlockedAt;
        bool released;
    }

    mapping (address => Allocations) public allocations;

    /* Initialize the total allocated OVC token */
    // Initialize the 3 wallet address, allocated amount and date unlock
    // @param `totalAllocated` Total allocated token from  `OVC` contract
    // @param `firstAllocatedWallet` wallet address that allowed to unlock the first 1/3 allocated token
    // @param `secondAllocatedWallet` wallet address that allowed to unlock the second 1/3 allocated token
    // @param `thirdAllocatedWallet` wallet address that allowed to unlock the third 1/3 allocated token
    function OVCLockAllocation(uint256 totalAllocated, address firstAllocatedWallet, address secondAllocatedWallet, address thirdAllocatedWallet) public {
        ovc = OVC(msg.sender);
        totalLockAllocated = totalAllocated;
        Allocations memory allocation;

        // Initialize the first allocation wallet address and date unlockedAt
        // Unlock 1/3 or 33% of the token allocated after 12 months
        allocation.allocated = safeDiv(safeMul(totalLockAllocated, 33),100);
        allocation.unlockedAt = safeAdd(now,(safeMul(12,30 days)));
        allocation.released = false;
        allocations[firstAllocatedWallet] = allocation;
        

        // Initialize the second allocation wallet address and date unlockedAt
        // Unlock 1/3 or 33% of the token allocated after 24 months
        allocation.allocated = safeDiv(safeMul(totalLockAllocated, 33),100);
        allocation.unlockedAt = safeAdd(now,(safeMul(24,30 days)));
        allocation.released = false;
        allocations[secondAllocatedWallet] = allocation;

        // Initialize the third allocation wallet address and date unlockedAt
        // Unlock last or 34% of the token allocated after 36 months
        allocation.allocated = safeDiv(safeMul(totalLockAllocated, 34),100);
        allocation.unlockedAt = safeAdd(now,(safeMul(36,30 days))); 
        allocation.released = false;
        allocations[thirdAllocatedWallet] = allocation;
    }
    
        /**
    * @notice called by allocated address to release the token
    */
    function releaseTokens() public {
        Allocations memory allocation;
        allocation = allocations[msg.sender];
        require(allocation.released == false);
        require(allocation.allocated > 0);
        require(allocation.unlockedAt > 0);
        require(now >= allocation.unlockedAt);
            
        uint256 allocated = allocation.allocated;
        ovc.transfer(msg.sender, allocated);

        allocation.allocated = 0;
        allocation.unlockedAt = 0;
        allocation.released = true;
        allocations[msg.sender] = allocation;
    }
} 

/** @author OVCode Switzerland AG */