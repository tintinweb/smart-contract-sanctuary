// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISaleLauncher.sol";
import "../interfaces/IMesaFactory.sol";

contract FixedPriceSaleTemplate {
    string public constant templateName = "FixedPriceSaleTemplate";
    ISaleLauncher public saleLauncher;
    IMesaFactory public mesaFactory;
    uint256 public auctionTemplateId;
    bool initialized = false;
    address tokenSupplier;
    address tokenOut;
    uint256 tokenOutSupply;
    bytes encodedInitData;

    event TemplateInitialized(
        address tokenOut,
        address tokenIn,
        uint256 tokenPrice,
        uint256 tokensForSale,
        uint256 startDate,
        uint256 endDate,
        uint256 allocationMin,
        uint256 allocationMax,
        uint256 minimumRaise,
        address owner
    );

    constructor() public {}

    /// @dev internal setup function to initialize the template, called by init()
    /// @param _saleLauncher TBD
    /// @param _auctionTemplateId TBD
    /// @param _tokenSupplier address that deposits the selling tokens
    /// @param _tokenOut token to be sold
    /// @param _tokenIn token to buy tokens with
    /// @param _tokenPrice price of one tokenOut
    /// @param _tokensForSale amount of tokens to be sold
    /// @param _startDate unix timestamp when the sale starts
    /// @param _endDate unix timestamp when the sale ends
    /// @param _allocationMin minimum amount of tokens an investor needs to purchase
    /// @param _allocationMax maximum amount of tokens an investor can purchase
    /// @param _minimumRaise sale goal – if not reached investors can claim back tokens
    /// @param _owner address for privileged functions
    function initTemplate(
        address _saleLauncher,
        uint256 _auctionTemplateId,
        address _tokenSupplier,
        address _tokenOut,
        address _tokenIn,
        uint256 _tokenPrice,
        uint256 _tokensForSale,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _allocationMin,
        uint256 _allocationMax,
        uint256 _minimumRaise,
        address _owner
    ) internal {
        require(!initialized, "FixedPriceSaleTemplate: ALEADY_INITIALIZED");

        saleLauncher = ISaleLauncher(_saleLauncher);
        mesaFactory = IMesaFactory(ISaleLauncher(_saleLauncher).factory());
        auctionTemplateId = _auctionTemplateId;
        tokenOutSupply = _tokensForSale;
        tokenOut = _tokenOut;
        tokenSupplier = _tokenSupplier;

        encodedInitData = abi.encode(
            IERC20(_tokenIn),
            IERC20(_tokenOut),
            _tokenPrice,
            _tokensForSale,
            _startDate,
            _endDate,
            _allocationMin,
            _allocationMax,
            _minimumRaise,
            _owner
        );

        initialized = true;

        emit TemplateInitialized(
            _tokenOut,
            _tokenIn,
            _tokenPrice,
            _tokensForSale,
            _startDate,
            _endDate,
            _allocationMin,
            _allocationMax,
            _minimumRaise,
            _owner
        );
    }

    function createSale() public payable returns (address newSale) {
        require(
            msg.sender == tokenSupplier,
            "FixedPriceSaleTemplate: FORBIDDEN"
        );
        newSale = saleLauncher.createSale.value(msg.value)(
            auctionTemplateId,
            tokenOut,
            tokenOutSupply,
            tokenSupplier,
            encodedInitData
        );
    }

    /// @dev setup function expexted to be called by templateLauncher to init the template
    /// @param _data encoded template params
    function init(bytes calldata _data) public {
        (
            address _saleLauncher,
            uint256 _auctionTemplateId,
            address _tokenOutSupplier,
            address _tokenOut,
            address _tokenIn,
            uint256 _tokenPrice,
            uint256 _tokensForSale,
            uint256 _startDate,
            uint256 _endDate,
            uint256 _allocationMin,
            uint256 _allocationMax,
            uint256 _minimumRaise,
            address _owner
        ) =
            abi.decode(
                _data,
                (
                    address,
                    uint256,
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address
                )
            );

        initTemplate(
            _saleLauncher,
            _auctionTemplateId,
            _tokenOutSupplier,
            _tokenOut,
            _tokenIn,
            _tokenPrice,
            _tokensForSale,
            _startDate,
            _endDate,
            _allocationMin,
            _allocationMax,
            _minimumRaise,
            _owner
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface ISaleLauncher {
    function factory() external view returns (address);

    function createSale(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address _tokenSupplier,
        bytes calldata _data
    ) external payable returns (address);

    function getDepositAmountWithFees(uint256 _tokenSupply)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface IMesaFactory {
    function allSales() external view returns (address[] calldata);

    function numberOfSales() external view returns (uint256);

    function templateManager() external view returns (address);

    function templateFee() external view returns (uint256);

    function saleFee() external view returns (uint256);

    function feeDenominator() external view returns (uint256);

    function feeNumerator() external view returns (uint256);

    function feeTo() external view returns (address);

    function addTemplate(address _template) external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}