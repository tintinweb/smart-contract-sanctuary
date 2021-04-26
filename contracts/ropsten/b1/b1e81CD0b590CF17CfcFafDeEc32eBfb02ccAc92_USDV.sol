// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iROUTER.sol";

contract USDV is iERC20 {
    // ERC-20 Parameters
    string public override name;
    string public override symbol;
    uint256 public override decimals;
    uint256 public override totalSupply;

    // ERC-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Parameters
    bool private inited;
    uint256 public nextEraTime;
    uint256 public blockDelay;

    address public VADER;
    address public VAULT;
    address public ROUTER;

    mapping(address => uint256) public lastBlock;

    // Only DAO can execute
    modifier onlyDAO() {
        require(msg.sender == DAO(), "Not DAO");
        _;
    }
    // Stop flash attacks
    modifier flashProof() {
        require(isMature(), "No flash");
        _;
    }

    function isMature() public view returns (bool isMatured) {
        if (lastBlock[tx.origin] + blockDelay <= block.number) {
            // Stops an EOA doing a flash attack in same block
            return true;
        }
    }

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {
        name = "VADER STABLE DOLLAR";
        symbol = "USDV";
        decimals = 18;
        totalSupply = 0;
    }

    function init(
        address _vader,
        address _vault,
        address _router
    ) external {
        require(inited == false);
        inited = true;
        VADER = _vader;
        VAULT = _vault;
        ROUTER = _router;
        nextEraTime = block.timestamp + iVADER(VADER).secondsPerEra();
    }

    //========================================iERC20=========================================//
    function balanceOf(address account) public view override returns (uint256) {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // iERC20 TransferFrom function
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // TransferTo function
    // Risks: User can be phished, or tx.origin may be deprecated, optionality should exist in the system.
    function transferTo(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(tx.origin, recipient, amount);
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
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            _checkIncentives();
        }
    }

    // Internal mint (upgrading and daily emissions)
    function _mint(address account, uint256 amount) internal virtual {
        if (amount > 0) {
            // Due to design, this function may be called with 0
            require(account != address(0), "recipient");
            totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }
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
            _balances[account] -= amount;
            totalSupply -= amount;
            emit Transfer(account, address(0), amount);
        }
    }

    //=========================================DAO=========================================//
    // Can set params
    function setParams(uint256 newDelay) external onlyDAO {
        blockDelay = newDelay;
    }

    //======================================INCENTIVES========================================//
    // Internal - Update incentives function
    function _checkIncentives() private {
        if (block.timestamp >= nextEraTime && emitting()) {
            // If new Era
            nextEraTime = block.timestamp + iVADER(VADER).secondsPerEra();
            uint256 _balance = iERC20(VADER).balanceOf(address(this)); // Get spare VADER
            if (_balance > 4) {
                uint256 _USDVShare = _balance / 2; // Get 50%
                _convert(address(this), _USDVShare); // Convert it
                if (balanceOf(address(this)) > 2) {
                    _transfer(address(this), ROUTER, balanceOf(address(this)) / 2); // Send half USDV to ROUTER
                    _transfer(address(this), VAULT, balanceOf(address(this))); // Send rest to VAULT
                }
                iERC20(VADER).transfer(ROUTER, iERC20(VADER).balanceOf(address(this)) / 2); // Send half VADER to ROUTER
                iERC20(VADER).transfer(VAULT, iERC20(VADER).balanceOf(address(this))); // Send rest to VAULT
            }
        }
    }

    //======================================ASSET MINTING========================================//
    // Convert to USDV
    function convert(uint256 amount) external returns (uint256) {
        return convertForMember(msg.sender, amount);
    }

    // Convert for members
    function convertForMember(address member, uint256 amount) public returns (uint256) {
        getFunds(VADER, amount);
        return _convert(member, amount);
    }

    // Internal convert
    function _convert(address _member, uint256 amount) internal flashProof returns (uint256 _convertAmount) {
        if (minting()) {
            lastBlock[tx.origin] = block.number; // Record first
            iERC20(VADER).burn(amount);
            _convertAmount = iROUTER(ROUTER).getUSDVAmount(amount); // Critical pricing functionality
            _mint(_member, _convertAmount);
        }
    }

    // Redeem to VADER
    function redeem(uint256 amount) external returns (uint256) {
        return redeemForMember(msg.sender, amount);
    }

    // Contracts to redeem for members
    function redeemForMember(address member, uint256 amount) public returns (uint256 redeemAmount) {
        _transfer(msg.sender, VADER, amount); // Move funds
        redeemAmount = iVADER(VADER).redeemToMember(member); // Ask VADER to redeem
        lastBlock[tx.origin] = block.number; // Must record block AFTER the tx
    }

    //============================== ASSETS ================================//

    function getFunds(address token, uint256 amount) internal {
        if (token == address(this)) {
            _transfer(msg.sender, address(this), amount);
        } else {
            if (tx.origin == msg.sender) {
                require(iERC20(token).transferTo(address(this), amount));
            } else {
                require(iERC20(token).transferFrom(msg.sender, address(this), amount));
            }
        }
    }

    //============================== HELPERS ================================//

    function DAO() public view returns (address) {
        return iVADER(VADER).DAO();
    }

    function emitting() public view returns (bool) {
        return iVADER(VADER).emitting();
    }

    function minting() public view returns (bool) {
        return iVADER(VADER).minting();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

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

    function transferTo(address, uint256) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit
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
    ) external returns (uint256 amountBase, uint256 amountToken);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {
    function UTILS() external view returns (address);

    function DAO() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newEra, uint256 newCurve) external;

    function setRewardAddress(address newAddress) external;

    function changeUTILS(address newUTILS) external;

    function changeDAO(address newDAO) external;

    function purgeDAO() external;

    function upgrade(uint256 amount) external;

    function redeem() external returns (uint256);

    function redeemToMember(address member) external returns (uint256);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}