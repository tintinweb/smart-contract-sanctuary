// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;
import "./iBEP20.sol";
import "./iDAO.sol";
import "./iUTILS.sol";
import "./iBEP677.sol"; 

    //======================================BIDDER=========================================//
contract Bidder is iBEP20 {

    // BEP-20 Parameters
    string public constant override name = 'Bidder Protocol Token';
    string public constant override symbol = 'BID';
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;

    // BEP-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Parameters
    bool public emitting;
    bool public minting;
    bool private savedSpartans;
    uint256 public feeOnTransfer;
    
    uint256 public emissionCurve;
    uint256 private _100m;
    uint256 public maxSupply;

    uint256 public secondsPerEra;
    uint256 public nextEraTime;

    address public DAO;
    address public DEPLOYER;
    address public BASEv1;

    event NewEra(uint256 nextEraTime, uint256 emission);

    // Only DAO can execute
    modifier onlyDAO() {
        require(msg.sender == DAO || msg.sender == DEPLOYER, "!DAO");
        _;
    }

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {
        _100m = 100 * 10**6 * 10**decimals; // 100m
        maxSupply = 300 * 10**6 * 10**decimals; // 300m
        emissionCurve = 2048;
        secondsPerEra =  86400; // 1 day
        nextEraTime = block.timestamp + secondsPerEra;
        DEPLOYER = msg.sender;
        _balances[msg.sender] = 1 * 10**7 * 10**decimals;
        totalSupply = 1 * 10**6 * 10**decimals;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    //========================================iBEP20=========================================//
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    // iBEP20 Transfer function
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    // iBEP20 Approve, change allowance functions
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]+(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "allowance err");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

     function _approve( address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        if (_allowances[owner][spender] < type(uint256).max) { // No need to re-approve if already max
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }
    
    // iBEP20 TransferFrom function
     function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        // Unlimited approval (saves an SSTORE)
        if (_allowances[sender][msg.sender] < type(uint256).max) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "allowance err");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    //iBEP677 approveAndCall
    function approveAndCall(address recipient, uint amount, bytes calldata data) external returns (bool) {
      _approve(msg.sender, recipient, type(uint256).max); // Give recipient max approval
      iBEP677(recipient).onTokenApproval(address(this), amount, msg.sender, data); // Amount is passed thru to recipient
      return true;
     }

      //iBEP677 transferAndCall
    function transferAndCall(address recipient, uint amount, bytes calldata data) external returns (bool) {
      _transfer(msg.sender, recipient, amount);
      iBEP677(recipient).onTokenTransfer(address(this), amount, msg.sender, data); // Amount is passed thru to recipient 
      return true;
     }


    // Internal transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer err");
        require(recipient != address(this), "recipient"); // Don't allow transfers here
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "balance err");
        uint _fee = iUTILS(UTILS()).calcPart(feeOnTransfer, amount);   // Critical functionality                                                      
        if(_fee <= amount){                // Stops reverts if UTILS corrupted           
            amount -= _fee;
            _burn(sender, _fee);
        }
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _checkEmission();
    }

    // Internal mint (upgrading and daily emissions)
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "address err");
        totalSupply += amount;
        require(totalSupply <= maxSupply, "Maxxed");
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    // Burn supply
    function burn(uint256 amount) public virtual override {
        _burn(msg.sender, amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {  
        uint256 decreasedAllowance = allowance(account, msg.sender) - (amount);
        _approve(account, msg.sender, decreasedAllowance); 
        _burn(account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "address err");
        require(_balances[account] >= amount, "balance err");
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }


    //=========================================DAO=========================================//
    // Can start
    function flipEmissions() external onlyDAO {
        emitting = !emitting;
    }
     // Can stop
    function flipMinting() external onlyDAO {
        minting = !minting;
    }
    // Can set params
    function setParams(uint256 newTime, uint256 newCurve) external onlyDAO {
        secondsPerEra = newTime;
        emissionCurve = newCurve;
    }
    function saveFallenSpartans(address _savedSpartans, uint256 _saveAmount) external onlyDAO{
        require(!savedSpartans, 'spartans saved'); // only one time
        savedSpartans = true;
        _mint(_savedSpartans, _saveAmount);
    }
    // Can change DAO
    function changeDAO(address newDAO) external onlyDAO {
        require(newDAO != address(0), "address err");
        DAO = newDAO;
    }
    // Can purge DAO
    function purgeDAO() external onlyDAO {
        DAO = address(0);
    }
    // Can purge DEPLOYER
    function purgeDeployer() public onlyDAO {
        DEPLOYER = address(0);
    }

   //======================================EMISSION========================================//
    // Internal - Update emission function
    function _checkEmission() private {
        if ((block.timestamp >= nextEraTime) && emitting) {    // If new Era and allowed to emit                      
            nextEraTime = block.timestamp + secondsPerEra; // Set next Era time
            uint256 _emission = getDailyEmission(); // Get Daily Dmission
            _mint(RESERVE(), _emission); // Mint to the RESERVE Address
            feeOnTransfer = iUTILS(UTILS()).getFeeOnTransfer(totalSupply, maxSupply); 
            if (feeOnTransfer > 500) { // Ensure utils isn't ever rogue
                feeOnTransfer = 500; // Max 5% FoT
            } 
            emit NewEra(nextEraTime, _emission); // Emit Event
        }
    }
    // Calculate Daily Emission
    function getDailyEmission() public view returns (uint256) {
        uint _adjustedCap;
        if(totalSupply <= _100m){ // If less than 100m, then adjust cap down
            _adjustedCap = (maxSupply * totalSupply)/(_100m); // 300m * 50m / 100m = 300m * 50% = 150m
        } else {
            _adjustedCap = maxSupply;  // 300m
        }
        return (_adjustedCap - totalSupply) / (emissionCurve); // outstanding / 2048 
    }

    //==========================================Minting============================================//
    function mintFromDAO(uint256 amount, address recipient) external onlyDAO {
        require(amount <= 5 * 10**6 * 10**decimals, '!5m'); //5m at a time
        if(minting && (totalSupply <=  150 * 10**6 * 10**decimals)){ // Only can mint up to 150m
             _mint(recipient, amount); 
        }
    }

    //======================================HELPERS========================================//
    // Helper Functions
    function UTILS() internal view returns(address){
        return iDAO(DAO).UTILS();
    }
    function RESERVE() internal view returns(address){
        return iDAO(DAO).RESERVE(); 
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;
interface iUTILS {
    function calcShare(uint, uint, uint) external pure returns (uint);
    function getFeeOnTransfer(uint256, uint256) external view returns(uint);
    function getPoolShareWeight(address, uint)external view returns(uint);
    function calcLiquidityUnits(uint, uint, uint, uint, uint) external pure returns (uint);
    function calcLiquidityHoldings(uint, address, address) external pure returns (uint);
    function calcSwapOutput(uint, uint, uint) external pure returns (uint);
    function calcSwapFee(uint, uint, uint) external pure returns (uint);
    function calcSwapValueInBase(address, uint) external view returns (uint);
    function calcSwapValueInToken(address, uint) external view returns (uint);
    function calcSpotValueInBaseWithSynth(address, uint) external view returns (uint);
    function calcSpotValueInBase(address, uint) external view returns (uint);
    function calcPart(uint, uint) external pure returns (uint);
    function calcLiquidityUnitsAsym(uint, address)external pure returns (uint);
    function calcActualSynthUnits(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;
interface iDAO {
    function ROUTER() external view returns(address);
    function DAOVAULT() external view returns(address);
    function BASE() external view returns(address);
    function LEND() external view returns(address);
    function UTILS() external view returns(address);
    function DAO() external view returns (address);
    function RESERVE() external view returns(address);
    function SYNTHVAULT() external view returns(address);
    function BONDVAULT() external view returns(address);
    function SYNTHFACTORY() external view returns(address);
    function POOLFACTORY() external view returns(address);
    function depositForMember(address pool, uint256 amount, address member) external;
    function currentProposal() external view returns (uint);
    function mapPID_open(uint) external view returns (bool);
    function isListed(address) external view returns (bool);
    function arrayMembers(uint) external view returns (address);
    function mapMember_lastTime(address) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iBEP677 {
 function onTokenApproval(address token, uint amount, address member,bytes calldata data) external;
 function onTokenTransfer(address token, uint amount, address member,bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;
interface iBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function burn(uint) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}