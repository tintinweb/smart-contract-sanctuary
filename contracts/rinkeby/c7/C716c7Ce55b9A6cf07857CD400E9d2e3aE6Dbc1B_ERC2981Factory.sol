// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC2981.sol";
import "./util/Clones.sol";

interface IRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

contract ERC2981Factory {

    address immutable public _registry;

    address immutable public _addressERC2981;

    mapping(address => address) public tokenAddressToProxy;

    event ERC2981Created(address newERC2981Address);

    modifier onlyValidSender() {
        require(IRegistry(_registry).isValidNiftySender(msg.sender), "ERC2981: Invalid msg.sender");
        _;
    }

    constructor(address registry_) {
        _registry = registry_;
        _addressERC2981 = address(new ERC2981());
    }

    function initializeRoyaltyInfo(address tokenAddress) public onlyValidSender returns (address) {
        address clone = Clones.clone(_addressERC2981);
        ERC2981(clone).initialize(_registry, tokenAddress);
        emit ERC2981Created(clone);

        tokenAddressToProxy[tokenAddress] = clone;

        return clone;
    }

    function getTokenAddressToProxy(address tokenAddress) public view returns (address) {
        return tokenAddressToProxy[tokenAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./util/Clones.sol";
import "./standard/ERC165.sol";
import "./interface/IERC2981.sol";
import "./interface/ICloneablePaymentSplitter.sol";

interface INiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

contract ERC2981 is ERC165, IERC2981 {

    bool public _initialized;

    address public _registry;
    
    address public _tokenAddress;

    mapping (uint256 => RoyaltyInfo) public _tokenRoyaltyInfo;

    event NewRoyaltySplitter(uint256 indexed niftyType, address previousSplitter, address newSplitter);

    struct RoyaltyInfo {
        address beneficiary;
        uint256 bips;
    }

    modifier onlyValidSender() {
        require(INiftyRegistry(_registry).isValidNiftySender(msg.sender), "ERC2981: Invalid msg.sender");
        _;
    }

    constructor() {}

    function initialize(address registry_, address tokenAddress_) public {
        require(!_initialized, "ERC2981: Contract instance has already been initialized");
        _initialized = true;
        _registry = registry_;
        _tokenAddress = tokenAddress_;
    }

    /**
     * @param splitter business logic implementation
     * @param niftyType uint256 that corresponds to tokenId in reads on royaltyInfo
     * @param bips uint256 value for percentage (using 2 decimals - 10000 = 100, 0 = 0)
     * @param payees address of who should be sent the royalty payment(s)
     * @param shares percentage breakdown by beneficiary
     */
    function createRoyaltySplitter(address splitter, uint256 niftyType, uint256 bips, address[] calldata payees, uint256[] calldata shares) external onlyValidSender {
        require(IERC165(splitter).supportsInterface(type(ICloneablePaymentSplitter).interfaceId), "ERC2981: Invalid splitter");

        address payable paymentSplitter = payable (Clones.clone(splitter));
        ICloneablePaymentSplitter(paymentSplitter).initialize(payees, shares);
        emit NewRoyaltySplitter(niftyType, _tokenRoyaltyInfo[niftyType].beneficiary, paymentSplitter);
        
        _tokenRoyaltyInfo[niftyType] = RoyaltyInfo(paymentSplitter, bips);       
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        uint256 niftyType = _getNiftyType(tokenId);
        require(_tokenRoyaltyInfo[niftyType].beneficiary != address(0), "ERC2981: Royalty Payment Receiver Not Set");

        RoyaltyInfo memory info = _tokenRoyaltyInfo[niftyType];

        uint256 royaltyAmount = (salePrice * info.bips) / 10000;
        return (info.beneficiary, royaltyAmount);
    }

    /**
     * @dev determine corresponding niftyType of tokenId
     */
    function _getNiftyType(uint256 tokenId) private pure returns (uint256) {
        uint256 contractId  = tokenId / 100000000;
        uint256 topLevelMultiplier = contractId * 100000000;
        return (tokenId - topLevelMultiplier) / 10000;
    }

    function getRoyaltySplitterByTokenId(uint256 tokenId) public view returns (address) {
        uint256 niftyType = _getNiftyType(tokenId);
        return _tokenRoyaltyInfo[niftyType].beneficiary;
    }

    function getRoyaltySplitterByNiftyType(uint256 niftyType) public view returns (address) {
        return _tokenRoyaltyInfo[niftyType].beneficiary;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        bytes4 _ERC2981_ = 0x2a55205a;
        return interfaceId == _ERC2981_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interface/IERC165.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC165.sol";

interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IERC165.sol";

interface ICloneablePaymentSplitter is IERC165 {
    
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    
    function initialize(address[] calldata payees, uint256[] calldata shares_) external;        
    function totalShares() external view returns (uint256);    
    function totalReleased() external view returns (uint256);
    function totalReleased(IERC20 token) external view returns (uint256);
    function shares(address account) external view returns (uint256);    
    function released(address account) external view returns (uint256);
    function released(IERC20 token, address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);    
    function release(address payable account) external;
    function release(IERC20 token, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}