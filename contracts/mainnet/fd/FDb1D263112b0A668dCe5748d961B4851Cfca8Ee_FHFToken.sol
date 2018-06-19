pragma solidity 0.4.18;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    *  Constructor
    *
    *  Sets contract owner to address of constructor caller
    */
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    *  Change Owner
    *
    *  Changes ownership of this contract. Only owner can call this method.
    *
    * @param newOwner - new owner&#39;s address
    */
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract FHFTokenInterface {
    /* Public parameters of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name = &#39;Forever Has Fallen&#39;;
    string public symbol = &#39;FC&#39;;
    uint8 public decimals = 18;

    function approveCrowdsale(address _crowdsaleAddress) external;
    function balanceOf(address _address) public constant returns (uint256 balance);
    function vestedBalanceOf(address _address) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract CrowdsaleParameters {
    ///////////////////////////////////////////////////////////////////////////
    // Configuration Independent Parameters
    ///////////////////////////////////////////////////////////////////////////

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
    }

    uint256 public maximumICOCap = 350e6;

    // ICO period timestamps:
    // 1525777200 = May 8, 2018. 11am GMT
    // 1529406000 = June 19, 2018. 11am GMT
    uint256 public generalSaleStartDate = 1525777200;
    uint256 public generalSaleEndDate = 1529406000;

    // Vesting
    // 1592564400 = June 19, 2020. 11am GMT
    uint32 internal vestingTeam = 1592564400;
    // 1529406000 = Bounty to ico end date - June 19, 2018. 11am GMT
    uint32 internal vestingBounty = 1529406000;

    ///////////////////////////////////////////////////////////////////////////
    // Production Config
    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // QA Config
    ///////////////////////////////////////////////////////////////////////////

    AddressTokenAllocation internal generalSaleWallet = AddressTokenAllocation(0x265Fb686cdd2f9a853c519592078cC4d1718C15a, 350e6);
    AddressTokenAllocation internal communityReserve =  AddressTokenAllocation(0x76d472C73681E3DF8a7fB3ca79E5f8915f9C5bA5, 450e6);
    AddressTokenAllocation internal team =              AddressTokenAllocation(0x05d46150ceDF59ED60a86d5623baf522E0EB46a2, 170e6);
    AddressTokenAllocation internal advisors =          AddressTokenAllocation(0x3d5fa25a3C0EB68690075eD810A10170e441413e, 48e5);
    AddressTokenAllocation internal bounty =            AddressTokenAllocation(0xAc2099D2705434f75adA370420A8Dd397Bf7CCA1, 176e5);
    AddressTokenAllocation internal administrative =    AddressTokenAllocation(0x438aB07D5EC30Dd9B0F370e0FE0455F93C95002e, 76e5);

    address internal playersReserve = 0x8A40B0Cf87DaF12C689ADB5C74a1B2f23B3a33e1;
}

contract FHFToken is Owned, CrowdsaleParameters, FHFTokenInterface {
    /* Arrays of all balances, vesting, approvals, and approval uses */
    mapping (address => uint256) private balances;              // Total token balances
    mapping (address => uint256) private balancesEndIcoFreeze;  // Balances frozen for ICO end by address
    mapping (address => uint256) private balances2yearFreeze;  // Balances frozen for 2 years after ICO end by address
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => mapping (address => bool)) private allowanceUsed;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event VestingTransfer(address indexed from, address indexed to, uint256 value, uint256 vestingTime);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Issuance(uint256 _amount); // triggered when the total supply is increased
    event Destruction(uint256 _amount); // triggered when the total supply is decreased
    event NewFHFToken(address _token);

    /* Miscellaneous */
    uint256 public totalSupply = 0; // 1 000 000 000 when minted

    /**
    *  Constructor
    *
    *  Initializes contract with initial supply tokens to the creator of the contract
    */
    function FHFToken() public {
        owner = msg.sender;

        mintToken(generalSaleWallet);
        mintToken(communityReserve);
        mintToken(team);
        mintToken(advisors);
        mintToken(bounty);
        mintToken(administrative);

        NewFHFToken(address(this));
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    /**
    *  1. Associate crowdsale contract address with this Token
    *  2. Allocate general sale amount
    *
    * @param _crowdsaleAddress - crowdsale contract address
    */
    function approveCrowdsale(address _crowdsaleAddress) external onlyOwner {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint amount = generalSaleWallet.amount * exponent;

        allowed[generalSaleWallet.addr][_crowdsaleAddress] = amount;
        Approval(generalSaleWallet.addr, _crowdsaleAddress, amount);
    }

    /**
    *  Get token balance of an address
    *
    * @param _address - address to query
    * @return Token balance of _address
    */
    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

    /**
    *  Get vested token balance of an address
    *
    * @param _address - address to query
    * @return balance that has vested
    */
    function vestedBalanceOf(address _address) public constant returns (uint256 balance) {
        if (now < vestingBounty) {
            return balances[_address] - balances2yearFreeze[_address] - balancesEndIcoFreeze[_address];
        }
        if (now < vestingTeam) {
            return balances[_address] - balances2yearFreeze[_address];
        } else {
            return balances[_address];
        }
    }

    /**
    *  Get token amount allocated for a transaction from _owner to _spender addresses
    *
    * @param _owner - owner address, i.e. address to transfer from
    * @param _spender - spender address, i.e. address to transfer to
    * @return Remaining amount allowed to be transferred
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    *  Create token and credit it to target address
    *  Created tokens need to vest
    *
    */
    function mintToken(AddressTokenAllocation tokenAllocation) internal {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint mintedAmount = tokenAllocation.amount * exponent;

        // Mint happens right here: Balance becomes non-zero from zero
        balances[tokenAllocation.addr] += mintedAmount;
        totalSupply += mintedAmount;

        // Emit Issue and Transfer events
        Issuance(mintedAmount);
        Transfer(address(this), tokenAllocation.addr, mintedAmount);
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        require(_value == 0 || allowanceUsed[msg.sender][_spender] == false);

        allowed[msg.sender][_spender] = _value;
        allowanceUsed[msg.sender][_spender] = false;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _currentValue - current number of tokens approved for allocation
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _currentValue, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
        require(allowed[msg.sender][_spender] == _currentValue);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    *  Send coins from sender&#39;s address to address specified in parameters
    *
    * @param _to - address to send to
    * @param _value - amount to send in Wei
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        // Check if the sender has enough
        require(vestedBalanceOf(msg.sender) >= _value);

        // Subtract from the sender
        // _value is never greater than balance of input validation above
        balances[msg.sender] -= _value;

        // Overflow is never possible due to input validation above
        balances[_to] += _value;

        // If tokens issued from this address need to vest (i.e. this address is a team pool), freeze them here
        if ((msg.sender == bounty.addr) && (now < vestingBounty)) {
            balancesEndIcoFreeze[_to] += _value;
        }
        if ((msg.sender == team.addr) && (now < vestingTeam)) {
            balances2yearFreeze[_to] += _value;
        }

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    *  A contract attempts to get the coins. Tokens should be previously allocated
    *
    * @param _to - address to transfer tokens to
    * @param _from - address to transfer tokens from
    * @param _value - number of tokens to transfer
    * @return True in case of success, otherwise false
    */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
        // Check if the sender has enough
        require(vestedBalanceOf(_from) >= _value);

        // Check allowed
        require(_value <= allowed[_from][msg.sender]);

        // Subtract from the sender
        // _value is never greater than balance because of input validation above
        balances[_from] -= _value;
        // Add the same to the recipient
        // Overflow is not possible because of input validation above
        balances[_to] += _value;

        // Deduct allocation
        // _value is never greater than allowed amount because of input validation above
        allowed[_from][msg.sender] -= _value;

        // If tokens issued from this address need to vest (i.e. this address is a team pool), freeze them here
        if ((_from == bounty.addr) && (now < vestingBounty)) {
            balancesEndIcoFreeze[_to] += _value;
        }
        if ((_from == team.addr) && (now < vestingTeam)) {
            balances2yearFreeze[_to] += _value;
        }

        Transfer(_from, _to, _value);
        allowanceUsed[_from][msg.sender] = true;

        return true;
    }

    /**
    *  Default method
    *
    *  This unnamed function is called whenever someone tries to send ether to
    *  it. Just revert transaction because there is nothing that Token can do
    *  with incoming ether.
    *
    *  Missing payable modifier prevents accidental sending of ether
    */
    function() public {
    }
}