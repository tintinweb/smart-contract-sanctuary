// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../shared/interfaces/ISaleLauncher.sol";
import "../shared/interfaces/IAquaFactory.sol";
import "../shared/interfaces/ITemplateLauncher.sol";
import "../shared/utils/AquaTemplate.sol";
import "../shared/interfaces/IParticipantListLauncher.sol";
import "../shared/interfaces/IParticipantList.sol";

contract FixedPriceSaleTemplate is AquaTemplate {
    ISaleLauncher public saleLauncher;
    IAquaFactory public aquaFactory;
    address public templateManager;
    uint256 public saleTemplateId;
    address public tokenSupplier;
    address public tokenOut;
    uint256 public tokensForSale;
    bytes public encodedInitData;
    bool public isInitialized;
    bool public isSaleCreated;
    address public templateLauncher;

    event TemplateInitialized(
        address tokenIn,
        address tokenOut,
        uint256 tokenPrice,
        uint256 tokensForSale,
        uint256 startDate,
        uint256 endDate,
        uint256 minCommitment,
        uint256 maxCommitment,
        uint256 minRaise,
        bool participantList
    );
    event SaleCreated();

    constructor() public {
        templateName = "FixedPriceSaleTemplate";
        metaDataContentHash = "0x"; // ToDo
    }

    /// @dev internal setup function to initialize the template, called by init()
    /// @param _saleLauncher address of Aqua SaleLauncher
    /// @param _saleTemplateId Aqua Sale TemplateId
    /// @param _tokenSupplier address that deposits the selling tokens
    /// @param _tokenIn token to buy tokens with
    /// @param _tokenOut token to be sold
    /// @param _tokenPrice price of one tokenOut
    /// @param _tokensForSale amount of tokens to be sold
    /// @param _startDate unix timestamp when the sale starts
    /// @param _endDate unix timestamp when the sale ends
    /// @param _minCommitment minimum tokenIn to buy
    /// @param _maxCommitment maximum tokenIn to buy
    /// @param _minRaise sale goal,if not reached investors can claim back their committed tokens
    /// @param _participantList defines if a participantList should be launched
    function initTemplate(
        address _saleLauncher,
        uint256 _saleTemplateId,
        address _tokenSupplier,
        address _tokenIn,
        address _tokenOut,
        uint256 _tokenPrice,
        uint256 _tokensForSale,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _minCommitment,
        uint256 _maxCommitment,
        uint256 _minRaise,
        bool _participantList
    ) internal {
        require(!isInitialized, "FixedPriceSaleTemplate: ALEADY_INITIALIZED");

        saleLauncher = ISaleLauncher(_saleLauncher);
        aquaFactory = IAquaFactory(ISaleLauncher(_saleLauncher).factory());
        templateManager = aquaFactory.templateManager();
        templateLauncher = aquaFactory.templateLauncher();
        saleTemplateId = _saleTemplateId;
        tokensForSale = _tokensForSale;
        tokenOut = _tokenOut;
        tokenSupplier = _tokenSupplier;
        isInitialized = true;
        address participantList;

        if (_participantList) {
            address participantListLauncher = ITemplateLauncher(
                templateLauncher
            ).participantListLaucher();

            address[] memory listManagers = new address[](1);
            listManagers[0] = address(_tokenSupplier);
            participantList = IParticipantListLauncher(participantListLauncher)
                .launchParticipantList(listManagers);
        }

        encodedInitData = abi.encode(
            IERC20(_tokenIn),
            IERC20(_tokenOut),
            _tokenPrice,
            _tokensForSale,
            _startDate,
            _endDate,
            _minCommitment,
            _maxCommitment,
            _minRaise,
            tokenSupplier,
            participantList
        );

        emit TemplateInitialized(
            _tokenIn,
            _tokenOut,
            _tokenPrice,
            _tokensForSale,
            _startDate,
            _endDate,
            _minCommitment,
            _maxCommitment,
            _minRaise,
            _participantList
        );
    }

    function createSale() public payable returns (address newSale) {
        require(!isSaleCreated, "FixedPriceSaleTemplate: Sale already created");
        require(
            msg.sender == tokenSupplier,
            "FixedPriceSaleTemplate: FORBIDDEN"
        );

        newSale = saleLauncher.createSale{value: msg.value}(
            saleTemplateId,
            tokenOut,
            tokensForSale,
            tokenSupplier,
            encodedInitData
        );
        isSaleCreated = true;
        emit SaleCreated();
    }

    /// @dev setup function expected to be called by templateLauncher to init the template
    /// @param _data encoded template params
    function init(bytes calldata _data) public override {
        (
            address _saleLauncher,
            uint256 _saleTemplateId,
            address _tokenSupplier,
            address _tokenIn,
            address _tokenOut,
            uint256 _tokenPrice,
            uint256 _tokensForSale,
            uint256 _startDate,
            uint256 _endDate,
            uint256 _minCommitment,
            uint256 _maxCommitment,
            uint256 _minRaise,
            bool _participantList
        ) = abi.decode(
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
                    bool
                )
            );

        initTemplate(
            _saleLauncher,
            _saleTemplateId,
            _tokenSupplier,
            _tokenIn,
            _tokenOut,
            _tokenPrice,
            _tokensForSale,
            _startDate,
            _endDate,
            _minCommitment,
            _maxCommitment,
            _minRaise,
            _participantList
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

// SPDX-License-Identifier: LGPL-3.0
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

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;

interface IAquaFactory {
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

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;

interface ITemplateLauncher {
    function launchTemplate(
        uint256 _templateId,
        bytes calldata _data,
        string calldata _metaDataContentHash,
        address _templateDeployer
    ) external payable returns (address newSale);

    function participantListLaucher() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "./AquaTemplateId.sol";

abstract contract AquaTemplate is ERC165, AquaTemplateId {
    string public templateName;
    string public metaDataContentHash;

    function init(bytes calldata data) external virtual;

    constructor() public {
        _registerInterface(_INTERFACE_ID_TEMPLATE);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;

interface IParticipantListLauncher {
    function launchParticipantList(address[] memory managers)
        external
        returns (address newList);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;

interface IParticipantList {
    function isInList(address account) external view returns (bool);

    function setParticipantAmounts(
        address[] memory accounts,
        uint256[] memory amounts
    ) external;

    function initialized() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;

contract AquaTemplateId {
    // ITemplate.init.selector ^ ITemplate.templateName.selector
    bytes4 internal constant _INTERFACE_ID_TEMPLATE = 0x242c4805;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

