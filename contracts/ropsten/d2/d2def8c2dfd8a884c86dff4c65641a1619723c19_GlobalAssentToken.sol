pragma solidity ^0.4.19;

library SafeMath {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract NonZero {
    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {
        require(msg.value > 0);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
}

contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC223 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

/**
 * @title Implementation of the Global assent token.
 */
contract GlobalAssentToken is ERC20, ERC223, Ownable, Pausable, NonZero {
    using SafeMath for uint;

    string public constant name = "Travelnation";
    string public constant symbol = "TLN";
    uint8 public decimals = 9;

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    // Initial block value. Can be set when block started.
    uint256 public TLNstartingBlock = block.number;
    // Have to set block starting time. Only once can be set.
    uint256 public TLNblockStartingTimestamp = block.timestamp;
    // Last block value used for disbursement calculation. Will be set every time the calculation triggered.
    uint256 public TLNlastDisbursementBlock = block.number;
    // Timestamp used when disbursement calculation. Will be set every time the calculation triggered.
    uint256 public TLNlastDisbursementTimestamp = block.timestamp;

    // Allocation for internal staking
    uint256 public internalStakingSupply;
    // Allocation for tangible asset
    uint256 public tangibleAssetSupply;

    // Internal staking supply address
    address public internalStakingAddress;
    // Tangible asset supply address
    address public tangibleAssetAddress;

    // Ensure only internal staking fund can call the function
    modifier onlyInternalStakingFund() {
        require(msg.sender == internalStakingAddress);
        _;
    }

    // Ensure only tangible asset fund can call the function
    modifier onlyTangibleAssetFund() {
        require(msg.sender == tangibleAssetAddress);
        _;
    }

    // Allocation for pre-TGE
    uint256 public pretgeSupply;
    // Allocation for TGE
    uint256 public tgeSupply;
    // Allocation for post-TGE
    uint256 public posttgeSupply;

    // pre-TGE supply address
    address public pretgeAddress;
    // TGE supply address
    address public tgeAddress;
    // post-TGE supply address
    address public posttgeAddress;

    // Flag keeping track of pre-TGE status. Ensures functions can only be called once
    bool public pretgeFinalized = false;
    // Flag keeping track of TGE status. Ensures functions can only be called once
    bool public tgeFinalized = false;
    // Flag keeping track of post-TGE status. Ensures functions can only be called once
    bool public posttgeFinalized = false;

    // Event for disbursements
    event DisbursementProcessed(uint256 _startBlockNumber, uint256 _endBlockNumber, uint256 _startTimeStamp, uint256 _endTimeStamp, uint256 _disbursalAmount);
    // Event called when pre-TGE is done
    event PretgeFinalized(uint256 tokensRemaining);
    // Event called when TGE is done
    event TgeFinalized(uint256 tokensRemaining);
    // Event called when post-TGE sale is done
    event PosttgeFinalized(uint256 tokensRemaining);

    // Ensure only pre-TGE fund can call the function
    modifier onlyPreTgeFund() {
        require(msg.sender == pretgeAddress);
        _;
    }

    // Ensure only TGE fund can call the function
    modifier onlyTgeFund() {
        require(msg.sender == tgeAddress);
        _;
    }

    // Ensure only post-TGE fund can call the function
    modifier onlyPostTgeFund() {
        require(msg.sender == posttgeAddress);
        _;
    }

    // Allocation for stake holder disbursement
    uint256 public disbursementStakeSupply;
    // Allocation for non-profit disbursement
    uint256 public disbursementNonprofitSupply;
    // Allocation for internal tangible asset disbursement
    uint256 public disbursementTangibleSupply;
    // Allocation for internal staff disbursement
    uint256 public disbursementStaffSupply;
    // Allocation for hyper staking disbursement
    uint256 public disbursementHyperSupply;

    // Stake disbursement address
    address public disbursementStakeAddress;
    // Non-profit disbursement address
    address public disbursementNonprofitAddress;
    // Tangible asset disbursement address
    address public disbursementTangibleAddress;
    // Internal staff disbursement address
    address public disbursementStaffAddress;
    // Hyper staking disbursement address
    address public disbursementHyperAddress;

    // Ensure only stake disbursement can call the function
    modifier onlyStakeDisbursementfund() {
        require(msg.sender == disbursementStakeAddress);
        _;
    }

    // Ensure only non-profit disbursement can call the function
    modifier onlyNonprofitDisbursementfund() {
        require(msg.sender == disbursementNonprofitAddress);
        _;
    }

    // Ensure only tangible asset disbursement can call the function
    modifier onlyTangibleDisbursementfund() {
        require(msg.sender == disbursementTangibleAddress);
        _;
    }

    // Ensure only internal staff disbursement can call the function
    modifier onlyStaffDisbursementfund() {
        require(msg.sender == disbursementStaffAddress);
        _;
    }

    // Ensure only hyper staking disbursement can call the function
    modifier onlyHyperDisbursementfund() {
        require(msg.sender == disbursementHyperAddress);
        _;
    }

    function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_to)
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        uint codeLength;
        bytes memory empty;

        assembly {
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value, empty);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(balances[_from] >= _value && allowance(_from, msg.sender) >= _value && _value > 0);
        bytes memory empty;
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value, empty);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function GlobalAssentToken() public {
        totalSupply = 1000000000 * 10**9;                                   // 100% - 1 billion TLN tokens with 9 decimals

        internalStakingSupply = 200000000 * 10**9;                          // 20% - 200 million TLN tokens
        tangibleAssetSupply = 200000000 * 10**9;                            // 20% - 200 million TLN tokens

        pretgeSupply = 100000000 * 10**9;                                   // 10% - 100 million TLN tokens
        tgeSupply = 100000000 * 10**9;                                      // 10% - 100 million TLN tokens
        posttgeSupply = 400000000 * 10**9;                                  // 40% - 400 million TLN tokens
    }

    // Sets the internal staking address, can only be done once by owner
    function setInternalStakingAddress(address _internalStakingAddress) external onlyOwner nonZeroAddress(_internalStakingAddress) {
        require(internalStakingAddress == 0x0);
        internalStakingAddress = _internalStakingAddress;
        addToBalance(internalStakingAddress, internalStakingSupply);
    }

    // Sets the tangible asset address, can only be done once by owner
    function setTangibleAssetAddress(address _tangibleAssetAddress) external onlyOwner nonZeroAddress(_tangibleAssetAddress) {
        require(tangibleAssetAddress == 0x0);
        tangibleAssetAddress = _tangibleAssetAddress;
        addToBalance(tangibleAssetAddress, tangibleAssetSupply);
    }

    // Sets the pre-TGE address, can only be done once by owner
    function setPretgeAddress(address _pretgeAddress) external onlyOwner nonZeroAddress(_pretgeAddress) {
        require(pretgeAddress == 0x0);
        pretgeAddress = _pretgeAddress;
        addToBalance(pretgeAddress, pretgeSupply);
    }

    // Sets the TGE address, can only be done once by owner
    function setTgeAddress(address _tgeAddress) external onlyOwner nonZeroAddress(_tgeAddress) {
        require(tgeAddress == 0x0);
        tgeAddress = _tgeAddress;
        addToBalance(tgeAddress, tgeSupply);
    }

    // Sets the post-TGE address, can only be done once by owner
    function setPosttgeAddress(address _posttgeAddress) external onlyOwner nonZeroAddress(_posttgeAddress) {
        require(posttgeAddress == 0x0);
        posttgeAddress = _posttgeAddress;
        addToBalance(posttgeAddress, posttgeSupply);
    }

    // Sets the Stake disbursement address, can only be done once by owner
    function setStakeDisbursementAddress(address _disbursementStakeAddress) external onlyOwner nonZeroAddress(_disbursementStakeAddress) {
        require(disbursementStakeAddress == 0x0);
        disbursementStakeAddress = _disbursementStakeAddress;
    }

    // Sets the Non-profit disbursement address, can only be done once by owner
    function setNonprofitDisbursementAddress(address _disbursementNonprofitAddress) external onlyOwner nonZeroAddress(_disbursementNonprofitAddress) {
        require(disbursementNonprofitAddress == 0x0);
        disbursementNonprofitAddress = _disbursementNonprofitAddress;
    }

    // Sets the Tangible asset disbursement address, can only be done once by owner
    function setTangibleAssetDisbursementAddress(address _disbursementTangibleAddress) external onlyOwner nonZeroAddress(_disbursementTangibleAddress) {
        require(disbursementTangibleAddress == 0x0);
        disbursementTangibleAddress = _disbursementTangibleAddress;
    }

    // Sets the internal staff disbursement address, can only be done once by owner
    function setStaffDisbursementAddress(address _disbursementStaffAddress) external onlyOwner nonZeroAddress(_disbursementStaffAddress) {
        require(disbursementStaffAddress == 0x0);
        disbursementStaffAddress = _disbursementStaffAddress;
    }

    // Sets the hyper staking disbursement address, can only be done once by owner
    function setHyperDisbursementAddress(address _disbursementHyperAddress) external onlyOwner nonZeroAddress(_disbursementHyperAddress) {
        require(disbursementHyperAddress == 0x0);
        disbursementHyperAddress = _disbursementHyperAddress;
    }

    // Function for the internal staking fund to transfer tokens
    function transferFromInternalStakingfund(address _to, uint256 _value) public whenNotPaused onlyInternalStakingFund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(internalStakingAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(internalStakingAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the tangible asset fund to transfer tokens
    function transferFromTangibleAssetfund(address _to, uint256 _value) public whenNotPaused onlyTangibleAssetFund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(tangibleAssetAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(tangibleAssetAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the pre-TGE fund to transfer tokens
    function transferFromPretgefund(address _to, uint256 _value) public whenNotPaused onlyPreTgeFund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(pretgeAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(pretgeAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the TGE fund to transfer tokens
    function transferFromTgefund(address _to, uint256 _value) public whenNotPaused onlyTgeFund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(tgeAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(tgeAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the post-TGE fund to transfer tokens
    function transferFromPosttgefund(address _to, uint256 _value) public whenNotPaused onlyPostTgeFund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(posttgeAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(posttgeAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the stake disbursement fund to transfer tokens
    function transferFromStakedisbursementfund(address _to, uint256 _value) public whenNotPaused onlyStakeDisbursementfund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(disbursementStakeAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(disbursementStakeAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the non-profit disbursement fund to transfer tokens
    function transferFromNonprofitdisbursementfund(address _to, uint256 _value) public whenNotPaused onlyNonprofitDisbursementfund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(disbursementNonprofitAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(disbursementNonprofitAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the tangible asset disbursement fund to transfer tokens
    function transferFromTangibleassetdisbursementfund(address _to, uint256 _value) public whenNotPaused onlyTangibleDisbursementfund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(disbursementTangibleAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(disbursementTangibleAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the internal staff disbursement fund to transfer tokens
    function transferFromInternalstaffdisbursementfund(address _to, uint256 _value) public whenNotPaused onlyStaffDisbursementfund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(disbursementStaffAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(disbursementStaffAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Function for the hyper staking disbursement fund to transfer tokens
    function transferFromHyperstakingdisbursementfund(address _to, uint256 _value) public whenNotPaused onlyHyperDisbursementfund nonZeroAddress(_to) nonZeroAmount(_value) returns (bool success) {
        require(balanceOf(disbursementHyperAddress) >= _value);
        bytes memory empty;
        addToBalance(_to, _value);
        decrementBalance(disbursementHyperAddress, _value);
        Transfer(0x0, _to, _value, empty);
        return true;
    }

    // Finalize pre-TGE. If there are leftover TLN, move remaining tokens to GTE
    function finalizePretge() external onlyOwner returns (bool success) {
        require(pretgeFinalized == false && tgeAddress != 0x0);
        uint256 amount = balanceOf(pretgeAddress);
        if (amount != 0) {
            balances[pretgeAddress] = 0;
            addToBalance(tgeAddress, amount);
        }
        pretgeFinalized = true;
        PretgeFinalized(amount);
        return true;
    }

    // Finalize TGE. If there are leftover TLN, move remaining tokens to post-TGE
    function finalizeTge() external onlyOwner returns (bool success) {
        require(pretgeFinalized == true && posttgeAddress != 0x0);
        uint256 amount = balanceOf(tgeAddress);
        if (amount != 0) {
            balances[tgeAddress] = 0;
            addToBalance(posttgeAddress, amount);
        }
        tgeFinalized = true;
        TgeFinalized(amount);
        return true;
    }

    // Disbursement will start when calling this function. Min. requirement set as 7 days time duration. According to no. of blocks created when calling this function no. of TLN tokens will be released to disbursement treasury accounts.
    function startDisbursement() external onlyOwner whenNotPaused returns (bool success) {
        uint256 currentTimeStamp = block.timestamp;
        require(disbursementStakeAddress != 0x0 && disbursementNonprofitAddress != 0x0 && disbursementTangibleAddress != 0x0 && disbursementStaffAddress != 0x0 && disbursementHyperAddress != 0x0 && posttgeAddress != 0x0);
        uint256 currentBlock = block.number;
        uint256 noOfBlocksCreated = currentBlock - TLNlastDisbursementBlock;
        require(noOfBlocksCreated != 0 && balances[posttgeAddress] >= noOfBlocksCreated);
        uint256 eachTreasuryAccountReward = noOfBlocksCreated.div(5);
        decrementBalance(posttgeAddress, noOfBlocksCreated);
        addToBalance(disbursementStakeAddress, eachTreasuryAccountReward);
        addToBalance(disbursementNonprofitAddress, eachTreasuryAccountReward);
        addToBalance(disbursementTangibleAddress, eachTreasuryAccountReward);
        addToBalance(disbursementStaffAddress, eachTreasuryAccountReward);
        addToBalance(disbursementHyperAddress, eachTreasuryAccountReward);
        DisbursementProcessed(currentBlock, TLNlastDisbursementBlock, TLNlastDisbursementTimestamp, currentTimeStamp, noOfBlocksCreated);
        TLNlastDisbursementTimestamp = currentTimeStamp;
        TLNlastDisbursementBlock = currentBlock;
        return true;
    }

    // Add to balance
    function addToBalance(address _address, uint _value) internal {
        balances[_address] = balances[_address].add(_value);
    }

    // Remove from balance
    function decrementBalance(address _address, uint _value) internal {
        balances[_address] = balances[_address].sub(_value);
    }
 function ERC20Token() public
   {
       owner = msg.sender;
       //totalSupply = initialSupply;
       balances[owner] = totalSupply;
   }   
}