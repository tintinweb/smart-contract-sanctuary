// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../shared/interfaces/ISaleLauncher.sol";
import "../shared/interfaces/IMesaFactory.sol";
import "../shared/utils/MesaTemplate.sol";

contract FairSaleTemplate is MesaTemplate {
    ISaleLauncher public saleLauncher;
    IMesaFactory public mesaFactory;
    uint256 public saleTemplateId;
    address public tokenSupplier;
    address public tokenOut;
    uint256 public tokensForSale;
    bytes public encodedInitData;
    bool public isInitialized;
    bool public isSaleCreated;

    event TemplateInitialized(
        address tokenIn,
        address tokenOut,
        uint256 duration,
        uint256 tokensForSale,
        uint96 minPrice,
        uint96 minBuyAmount,
        uint256 minRaise,
        uint256 orderCancelationPeriodDuration,
        uint256 minimumBiddingAmountPerOrder
    );

    constructor() public {
        templateName = "FairSaleTemplate";
        metaDataContentHash = "0x"; // ToDo
    }

    /// @dev internal setup function to initialize the template, called by init()
    /// @param _saleLauncher address of Mesa SaleLauncher
    /// @param _saleTemplateId Mesa Auction TemplateId
    /// @param _tokenIn token to bid on auction
    /// @param _tokenOut token to be auctioned
    /// @param _duration auction duration in seconds
    /// @param _tokensForSale amount of tokens to be auctioned
    /// @param _minPrice minimum Price that token should be auctioned for
    /// @param _minBuyAmount minimum amount of tokens an investor has to buy
    /// @param _minRaise minimum amount an project is expected to raise
    /// @param _tokenSupplier address that deposits the tokens
    function initTemplate(
        address _saleLauncher,
        uint256 _saleTemplateId,
        address _tokenIn,
        address _tokenOut,
        uint256 _duration,
        uint256 _tokensForSale,
        uint96 _minPrice,
        uint96 _minBuyAmount,
        uint256 _minRaise,
        uint256 _orderCancelationPeriodDuration,
        uint256 _minimumBiddingAmountPerOrder,
        address _tokenSupplier
    ) internal {
        require(!isInitialized, "FairSaleTemplate: ALEADY_INITIALIZED");

        saleLauncher = ISaleLauncher(_saleLauncher);
        mesaFactory = IMesaFactory(ISaleLauncher(_saleLauncher).factory());
        saleTemplateId = _saleTemplateId;

        bool isAtomicClosureAllowed = false;
        tokenSupplier = _tokenSupplier;
        tokenOut = _tokenOut;
        tokensForSale = _tokensForSale;

        encodedInitData = abi.encode(
            IERC20(_tokenIn),
            IERC20(_tokenOut),
            _orderCancelationPeriodDuration,
            _duration,
            uint96(_tokensForSale),
            _minBuyAmount,
            _minimumBiddingAmountPerOrder,
            _minRaise,
            isAtomicClosureAllowed
        );

        emit TemplateInitialized(
            _tokenIn,
            _tokenOut,
            _duration,
            _tokensForSale,
            _minPrice,
            _minBuyAmount,
            _minRaise,
            _orderCancelationPeriodDuration,
            _minimumBiddingAmountPerOrder
        );
    }

    function createSale() public payable returns (address newSale) {
        require(!isSaleCreated, "FairSaleTemplate: Sale already created");
        require(msg.sender == tokenSupplier, "FairSaleTemplate: FORBIDDEN");
        newSale = saleLauncher.createSale{value: msg.value}(
            saleTemplateId,
            tokenOut,
            tokensForSale,
            tokenSupplier,
            encodedInitData
        );
    }

    /// @dev setup function expexted to be called by templateLauncher to init the template
    /// @param _data encoded template params
    function init(bytes calldata _data) public {
        (
            address _saleLauncher,
            uint256 _saleTemplateId,
            address _tokenIn,
            address _tokenOut,
            uint256 _duration,
            uint256 _tokensForSale,
            uint96 _minPrice,
            uint96 _minBuyAmount,
            uint256 _minRaise,
            uint256 _orderCancelationPeriodDuration,
            uint256 _minimumBiddingAmountPerOrder,
            address _tokenSupplier
        ) = abi.decode(
            _data,
            (
                address,
                uint256,
                address,
                address,
                uint256,
                uint256,
                uint96,
                uint96,
                uint256,
                uint256,
                uint256,
                address
            )
        );

        return
            initTemplate(
                _saleLauncher,
                _saleTemplateId,
                _tokenIn,
                _tokenOut,
                _duration,
                _tokensForSale,
                _minPrice,
                _minBuyAmount,
                _minRaise,
                _orderCancelationPeriodDuration,
                _minimumBiddingAmountPerOrder,
                _tokenSupplier
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

    function templateLauncher() external view returns (address);

    function templateFee() external view returns (uint256);

    function saleFee() external view returns (uint256);

    function feeDenominator() external view returns (uint256);

    function feeNumerator() external view returns (uint256);

    function feeTo() external view returns (address);

    function addTemplate(address _template) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

contract MesaTemplate {
    string public templateName;
    string public metaDataContentHash;
}

