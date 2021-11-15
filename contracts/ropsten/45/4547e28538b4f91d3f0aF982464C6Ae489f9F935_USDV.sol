// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iERC677.sol"; 
import "./interfaces/iGovernorAlpha.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iROUTER.sol";

contract USDV is iERC20 {
    // ERC-20 Parameters
    string public constant override name = "VADER STABLE DOLLAR";
    string public constant override symbol = "USDV";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;

    // ERC-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Parameters
    uint256 public blockDelay;

    address public immutable VADER;

    // Only TIMELOCK can execute
    modifier onlyTIMELOCK() {
        require(msg.sender == TIMELOCK(), "!TIMELOCK");
        _;
    }

    //=====================================CREATION=========================================//

    constructor(address _vader) {
        VADER = _vader;
    }

    //========================================iERC20=========================================//
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // iERC20 Transfer function
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // iERC20 Approve, change allowance functions
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        if (_allowances[owner][spender] < type(uint256).max) { // No need to re-approve if already max
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }

    // iERC20 TransferFrom function
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        // Unlimited approval (saves an SSTORE)
        if (_allowances[sender][msg.sender] < type(uint256).max) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "allowance err");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    //iERC677 approveAndCall
    function approveAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
      _approve(msg.sender, recipient, amount);
      iERC677(recipient).onTokenApproval(address(this), amount, msg.sender, data); // Amount is passed thru to recipient
      return true;
     }

      //iERC677 transferAndCall
    function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
      _transfer(msg.sender, recipient, amount);
      iERC677(recipient).onTokenTransfer(address(this), amount, msg.sender, data); // Amount is passed thru to recipient 
      return true;
     }

    // Internal transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (amount > 0) {
            // Due to design, this function may be called with 0
            require(sender != address(0), "sender");
            require(recipient != address(this), "recipient");
            require(_balances[sender] >= amount, "balance err");
            _balances[sender] -= amount;
            _balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    // Internal mint (upgrading and daily emissions)
    function _mint(address account, uint256 amount) internal virtual {
        if (amount > 0) {
            // Due to design, this function may be called with 0
            require(account != address(0), "recipient");
            totalSupply += amount;
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    // Burn supply
    function burn(uint256 amount) external virtual override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external virtual override {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        if (amount > 0) {
            // Due to design, this function may be called with 0
            require(account != address(0), "address err");
            require(_balances[account] >= amount, "balance err");
            _balances[account] -= amount;
            totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    //======================================== TIMELOCK =========================================//
    // Can set params
    function setParams(uint256 newDelay) external onlyTIMELOCK {
        blockDelay = newDelay;
    }

    //======================================ASSET MINTING========================================//

    // Convert to USDV
    function convertToUSDV(uint256 amount) external returns (uint256) {
        return convertToUSDVForMember(msg.sender, amount);
    }

    // Convert to USDV for Member
    function convertToUSDVForMember(address member, uint256 amount) public returns (uint256) {
        require(iERC20(VADER).transferFrom(msg.sender, address(this), amount)); // Get VADER Funds
        return convertToUSDVForMemberDirectly(member);
    }

    // Convert to USDV (must have sent VADER first)
    function convertToUSDVDirectly() external returns (uint256) {
        return convertToUSDVForMemberDirectly(msg.sender);
    }

    // Convert for members (must have sent VADER first)
    function convertToUSDVForMemberDirectly(address member) public returns (uint256 convertAmount) {
        require(iVADER(VADER).minting(), "not minting");
        uint256 _amount = iERC20(VADER).balanceOf(address(this));
        iERC20(VADER).burn(_amount);
        convertAmount = iROUTER(ROUTER()).getUSDVAmount(_amount); // Critical pricing functionality
        _mint(member, convertAmount);
    }

    //============================== HELPERS ================================//

    function GovernorAlpha() internal view returns(address){
        return iVADER(VADER).GovernorAlpha();
    }
    function ROUTER() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).ROUTER();
    }
    function TIMELOCK() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).TIMELOCK();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC677 {
 function onTokenApproval(address token, uint amount, address member, bytes calldata data) external;
 function onTokenTransfer(address token, uint amount, address member, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iGovernorAlpha {
    function VETHER() external view returns(address);
    function VADER() external view returns(address);
    function USDV() external view returns(address);
    function RESERVE() external view returns(address);
    function VAULT() external view returns(address);
    function ROUTER() external view returns(address);
    function LENDER() external view returns(address);
    function POOLS() external view returns(address);
    function FACTORY() external view returns(address);
    function UTILS() external view returns(address);
    function TIMELOCK() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {

    function GovernorAlpha() external view returns (address);

    function Admin() external view returns (address);

    function UTILS() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newEra, uint256 newCurve) external;

    function setReserve(address newReserve) external;

    function changeUTILS(address newUTILS) external;

    function changeGovernorAlpha(address newGovernorAlpha) external;

    function purgeGovernorAlpha() external;

    function upgrade(uint256 amount) external;

    function convertToUSDV(uint256 amount) external returns (uint256);

    function convertToUSDVForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeemToVADER(uint256 amount) external returns (uint256);

    function redeemToVADERForMember(address member, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit,
        uint256 newInterval
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 units, uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function curatePool(address token) external;

    function listAnchor(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function isBase(address token) external view returns (bool base);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

