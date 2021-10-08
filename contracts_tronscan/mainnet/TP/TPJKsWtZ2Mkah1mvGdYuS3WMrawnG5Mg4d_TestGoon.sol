//SourceUnit: Migrations.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}


//SourceUnit: NFTVibravid.sol

// contracts/NFTVibravid.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./TRC721.sol";
import "./TRC165.sol";
import "./TRC721Enumerable.sol";
import "./TRC721Metadata.sol";
import "./Registry.sol";
import "./SafeMath.sol";
import "./TRC20.sol";

contract NFTVibravid is
    TRC721Enumerable,
    TRC721Metadata
{
    using SafeMath for uint256;
    using CommissionRegistry for CommissionRegistry.Registry;

    struct CommissionConfig {
        uint256 percentage;
        uint256 minPurchaseCount;
    }

    event TokenPaymentOption(address addr, uint256 fee);

    /**
     * Event emitted when minting a new NFT.
     */
    event Mint(uint256 indexed tokenId, address indexed minter);
    /**
     * Event emitted when minting a new NFT.
     */
    event Purchase(uint256 indexed tokenId, address indexed buyer);

    event CommissionUpdate(address indexed addr, uint256 amount);

    event TransferFeeCollected(uint256 amount);

    event Withdraw(uint256 amount);

    event WithdrawTokens(address tokenAddress, uint256 amount);

    CommissionRegistry.Registry private _purchaseRegistry;
    CommissionRegistry.Registry private _commonRegistry;
    CommissionRegistry.Registry private _vipRegistry;
    CommissionConfig _commonCommission =
        CommissionConfig({percentage: 4, minPurchaseCount: 2});
    CommissionConfig _vipCommission =
        CommissionConfig({percentage: 10, minPurchaseCount: 4});

    uint256 private _salePrice;
    uint256 private _transferFee;
    uint256 private _maxTotalSupply;
    uint256 private _commissionPercentage = 3;
    uint256 private _vipCommissionPercentage = 10;
    uint256 private _withdrawableAmount = 0;

    uint256 public purchaseCount = 0;
    uint256 public transferFeeCollected = 0;

    mapping(address => bool) private tokenPaymentSupported;
    mapping(address => uint256) private tokenPaymentPrice;
    mapping(address => uint256) private _tokenWithdrawableAmount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxTotalSupply,
        uint256 salePrice,
        uint256 transferFee
    ) public TRC721Metadata(name, symbol) {
        _maxTotalSupply = maxTotalSupply;
        _salePrice = salePrice;
        _transferFee = transferFee;
    }

    function transferChecks() internal {
        require(msg.value >= _transferFee, "Insufficient transfer fee");
    }

    function postTransfer() internal {
        transferFeeCollected += msg.value;
    }

    function setTransferFee(uint256 transferFee) public onlyOwner {
        _transferFee = transferFee;
    }

    function getTransferFee() public view returns (uint256) {
        return _transferFee;
    }

    function collectTransferFee() public payable onlyOwner returns (uint256) {
        uint256 totalCollected = transferFeeCollected;
        msg.sender.transfer(transferFeeCollected);
        transferFeeCollected = 0;

        emit TransferFeeCollected(totalCollected);
        return totalCollected;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function updateSalePrice(uint256 salePrice) external onlyOwner {
        require(salePrice > 0, "Sale price must be more than zero");
        _salePrice = salePrice;
    }

    function mint(uint256 _tokenId, string memory _tokenUri) public onlyOwner {
        require(
            this.totalSupply() < _maxTotalSupply,
            "Max total supply reached"
        );
        require(!_tokenExists(_tokenId), "Token already exists");

        tokenMap[_tokenId] = TokenInfo({
            _id: _tokenId,
            _owner: msg.sender,
            _uri: _tokenUri,
            _purchased: false
        });

        _registerToken(_tokenId, msg.sender);

        _allTokens.push(_tokenId);

        emit Mint(_tokenId, msg.sender);
        emit Transfer(address(0), msg.sender, _tokenId);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenUri)
        public
        onlyOwner
    {
        require(
            _tokenExists(_tokenId),
            "TRC721Metadata: URI query for nonexistent token"
        );
        tokenMap[_tokenId]._uri = _tokenUri;
    }

    function getTokenPaymentPrice(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return tokenPaymentPrice[tokenAddress];
    }

    function setTokenPaymentOption(address tokenAddress, uint256 nftPrice)
        public
        onlyOwner
    {
        tokenPaymentSupported[tokenAddress] = true;
        tokenPaymentPrice[tokenAddress] = nftPrice;
        emit TokenPaymentOption(tokenAddress, nftPrice);
    }

    function purchaseByToken(address tokenAddress, uint256 quantity) public {
        require(
            tokenPaymentSupported[tokenAddress],
            "Unregistered Payment Option"
        );
        require(msg.sender != owner(), "Sender is owner");
        require(
            (quantity + purchaseCount) <= _allTokens.length,
            "Exceeds total supply"
        );
        TRC20 tokenContract = TRC20(tokenAddress);
        uint256 amount = tokenPaymentPrice[tokenAddress] * quantity;
        tokenContract.transferFrom(msg.sender, address(this), amount);

        _purchase(quantity, msg.sender);

        _distributeCommussion(amount, tokenAddress);
    }

    function purchase(uint256 quantity) public payable {
        require(msg.sender != owner(), "Sender is owner");
        require(
            (quantity + purchaseCount) <= _allTokens.length,
            "Exceeds total supply"
        );
        uint256 totalPrice = _salePrice * quantity;
        require(msg.value >= totalPrice, "Insufficient Amount");

        _purchase(quantity, msg.sender);

        _distributeCommussion(_salePrice * quantity, address(0));
    }

    function _distributeCommussion(uint256 amount, address tokenAddress)
        internal
    {
        uint256 revenue = amount;
        if (_vipCommissionPercentage > 0) {
            uint256 commissionAmount = ((amount * _vipCommissionPercentage) /
                100);

            revenue -= _creditCommissionRegistry(
                _vipRegistry,
                commissionAmount,
                tokenAddress
            );
        }
        if (_commissionPercentage > 0) {
            uint256 commissionAmount = ((amount * _commissionPercentage) / 100);
            revenue -= _creditCommissionRegistry(
                _commonRegistry,
                commissionAmount,
                tokenAddress
            );
        }

        _checkAddressValidityForCommission(msg.sender);

        if (tokenAddress == address(0)) {
            _withdrawableAmount += revenue;
        } else {
            _tokenWithdrawableAmount[tokenAddress] += revenue;
        }
    }

    function getTokens() public view returns (uint256[] memory) {
        return ownedTokens[msg.sender];
    }

    function getWithdrawableAmount() public view onlyOwner returns (uint256) {
        return _withdrawableAmount;
    }

    function withdraw() public payable onlyOwner returns (uint256) {
        msg.sender.transfer(_withdrawableAmount);
        emit Withdraw(_withdrawableAmount);
        return _withdrawableAmount;
    }

    function getTokenWithdrawableAmount(address tokenAddress)
        public
        view
        onlyOwner
        returns (uint256)
    {
        require(
            tokenPaymentSupported[tokenAddress],
            "Unregistered Payment Option"
        );
        return _tokenWithdrawableAmount[tokenAddress];
    }

    function withdrawTokens(address tokenAddress)
        public
        onlyOwner
        returns (uint256)
    {
        require(
            tokenPaymentSupported[tokenAddress],
            "Unregistered Payment Option"
        );
        uint256 amount = _tokenWithdrawableAmount[tokenAddress];
        TRC20 token = TRC20(tokenAddress);
        token.transfer(msg.sender, amount);
        emit WithdrawTokens(tokenAddress, amount);
        return amount;
    }

    function getCommissionAmount() public view returns (uint256) {
        bool isVip = _vipRegistry.isRegistered(msg.sender);
        bool isCommon = _commonRegistry.isRegistered(msg.sender);
        require(isVip || isCommon, "Not eligible for commission");
        if (isVip) {
            return _vipRegistry.getAmount(msg.sender);
        }
        return _commonRegistry.getAmount(msg.sender);
    }

    function claimCommission() public payable returns (uint256) {
        bool isVip = _vipRegistry.isRegistered(msg.sender);
        bool isCommon = _commonRegistry.isRegistered(msg.sender);
        require(isVip || isCommon, "Not eligible for commission");
        uint256 amount = 0;
        if (isVip) {
            amount = _vipRegistry.getAmount(msg.sender);
            _vipRegistry.setAmount(msg.sender, 0);
        } else {
            amount = _commonRegistry.getAmount(msg.sender);
            _commonRegistry.setAmount(msg.sender, 0);
        }
        emit CommissionUpdate(msg.sender, 0);
        msg.sender.transfer(amount);
        return amount;
    }

    function getTokenCommissionAmount(address tokenAddress)
        public
        view
        returns (uint256)
    {
        require(
            tokenPaymentSupported[tokenAddress],
            "Unregistered Payment Option"
        );
        bool isVip = _vipRegistry.isRegistered(msg.sender);
        bool isCommon = _commonRegistry.isRegistered(msg.sender);
        require(isVip || isCommon, "Not eligible for commission");
        if (isVip) {
            return _vipRegistry.getTokenAmount(msg.sender, tokenAddress);
        }
        return _commonRegistry.getTokenAmount(msg.sender, tokenAddress);
    }

    function claimTokenCommission(address tokenAddress)
        public
        returns (uint256)
    {
        require(
            tokenPaymentSupported[tokenAddress],
            "Unregistered Payment Option"
        );
        bool isVip = _vipRegistry.isRegistered(msg.sender);
        bool isCommon = _commonRegistry.isRegistered(msg.sender);
        require(isVip || isCommon, "Not eligible for commission");
        uint256 amount = 0;
        if (isVip) {
            amount = _vipRegistry.getTokenAmount(msg.sender, tokenAddress);
            _vipRegistry.setAmount(msg.sender, 0);
        } else {
            amount = _commonRegistry.getTokenAmount(msg.sender, tokenAddress);
            _commonRegistry.setAmount(msg.sender, 0);
        }
        emit CommissionUpdate(msg.sender, 0);
        TRC20 token = TRC20(tokenAddress);
        token.transfer(msg.sender, amount);
        return amount;
    }

    function getCommissionLevel(address addr)
        public
        view
        returns (string memory)
    {
        if (_vipRegistry.isRegistered(addr)) {
            return "VIP";
        }
        if (_commonRegistry.isRegistered(addr)) {
            return "COMMON";
        }
        return "NOT ELIGIBLE";
    }

    function _purchase(uint256 quantity, address buyer) internal {
        for (uint256 i = purchaseCount; i < purchaseCount + quantity; i++) {
            uint256 tokenId = _allTokens[i];
            address previousOwner = tokenMap[tokenId]._owner;
            _transferFrom(previousOwner, buyer, tokenId);
            tokenMap[tokenId]._purchased = true;
            emit Transfer(previousOwner, buyer, tokenId);
            emit Purchase(tokenId, buyer);
        }

        if (!_purchaseRegistry.isRegistered(buyer)) {
            _purchaseRegistry.register(buyer);
        }

        uint256 newPurchaseCount = _purchaseRegistry.getAmount(buyer) +
            quantity;
        _purchaseRegistry.setAmount(buyer, newPurchaseCount);
        purchaseCount += quantity;
    }

    function _checkAddressValidityForCommission(address payable addr)
        internal
        returns (bool)
    {
        require(_userExists(addr), "Address does not exists");
        require(
            _purchaseRegistry.isRegistered(addr),
            "User is not registered to purchase registry"
        );

        uint256 purchasedTokenCount = _purchaseRegistry.getAmount(addr);

        bool isEligibleForVipCommission = purchasedTokenCount >=
            _vipCommission.minPurchaseCount;

        bool isEligbleForCommission = purchasedTokenCount >=
            _commonCommission.minPurchaseCount;

        uint256 amount = 0;

        // VIP
        if (isEligibleForVipCommission && !_vipRegistry.isRegistered(addr)) {
            if (_commonRegistry.isRegistered(addr)) {
                amount = _commonRegistry.getAmount(addr);
                _commonRegistry.unregister(addr);
            }
            _vipRegistry.register(addr);
            _vipRegistry.setAmount(addr, amount);
            return true;
        }

        // Common
        if (isEligbleForCommission && !_commonRegistry.isRegistered(addr)) {
            _commonRegistry.register(addr);
            _commonRegistry.setAmount(addr, amount);
            return true;
        }

        return false;
    }

    function _creditCommissionRegistry(
        CommissionRegistry.Registry storage registry,
        uint256 amount,
        address tokenAddress
    ) internal returns (uint256) {
        if (amount == 0 || registry.total() == 0) {
            return 0;
        }
        uint256 amountPerUser = amount / registry.total();
        uint256 total = registry.total();
        for (uint256 i = 0; i < total; i++) {
            address addr = registry.addressAtIndex(i);
            uint256 newAmount = registry.getAmount(addr) + amountPerUser;
            if (tokenAddress == address(0)) {
                registry.setAmount(addr, newAmount);
            } else {
                registry.setTokenAmount(addr, tokenAddress, amount);
            }
            emit CommissionUpdate(addr, newAmount);
        }
        return amount;
    }
    

}


//SourceUnit: Ownable.sol

// contracts/Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ownable {

    event TransferOwnership(address from, address to);

    address private _owner;

    constructor() public {
        _owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Only accessible by owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        _owner = newOwner;
        emit TransferOwnership(msg.sender, newOwner);
    }
}


//SourceUnit: Registry.sol

// contracts/Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library CommissionRegistry {
    struct Entry {
        bool exists;
        address addr;
        uint256 amount;
        mapping(address => uint256) tokenAmount;
    }

    struct Registry {
        mapping(address => Entry) entryMap;
        mapping(address => uint256) addressIndex;
        address[] registeredAddress;
    }

    function isRegistered(Registry storage registry, address addr)
        internal
        view
        returns (bool)
    {
        return registry.entryMap[addr].exists;
    }

    function getAmount(Registry storage registry, address addr)
        internal
        view
        returns (uint256)
    {
        return registry.entryMap[addr].amount;
    }

    function setAmount(
        Registry storage registry,
        address addr,
        uint256 amount
    ) internal {
        registry.entryMap[addr].amount = amount;
    }

    function getTokenAmount(
        Registry storage registry,
        address addr,
        address tokenAddress
    ) internal view returns (uint256) {
        return registry.entryMap[addr].tokenAmount[tokenAddress];
    }

    function setTokenAmount(
        Registry storage registry,
        address addr,
        address tokenAddress,
        uint256 amount
    ) internal {
        registry.entryMap[addr].tokenAmount[tokenAddress] = amount;
    }

    function register(Registry storage registry, address addr) internal {
        registry.entryMap[addr] = Entry({exists: true, addr: addr, amount: 0});
        uint256 index = registry.registeredAddress.length;
        registry.addressIndex[addr] = index;
        registry.registeredAddress.push(addr);
    }

    function addressAtIndex(Registry storage registry, uint256 index)
        internal
        view
        returns (address)
    {
        require(index < registry.registeredAddress.length, "Invalid index");
        return registry.registeredAddress[index];
    }

    function total(Registry storage registry) internal view returns (uint256) {
        return registry.registeredAddress.length;
    }

    function unregister(Registry storage registry, address addr) internal {
        uint256 lastAddressIndex = registry.registeredAddress.length - 1;
        address lastAddress = registry.registeredAddress[lastAddressIndex];

        if (lastAddress != addr) {
            uint256 currentIndex = registry.addressIndex[addr];
            registry.registeredAddress[currentIndex] = lastAddress;
            registry.addressIndex[lastAddress] = currentIndex;
        }
        delete registry.addressIndex[addr];
        delete registry.entryMap[addr];
        registry.registeredAddress.length--;
    }
}


//SourceUnit: SafeMath.sol

// contracts/SafeMath.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TRC165.sol

// contracts/TRC721.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITRC165 {
    //Query whether the interface ‘interfaceID’  is supported
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * @dev Implementation of the {ITRC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract TRC165 is ITRC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() public {
        // Derived contracts need only register support for their own interfaces,
        // we register support for TRC165 itself here
        _registerInterface(_INTERFACE_ID_TRC165);
    }

    /**
     * @dev See {ITRC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual TRC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {ITRC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the TRC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "TRC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


//SourceUnit: TRC20.sol

// contracts/NFTVibravid.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface TRC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//SourceUnit: TRC721.sol

// contracts/TRC721.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";
import "./TRC165.sol";
import "./TRC721Helpers.sol";
import "./TRC721Receiver.sol";

interface ITRC721 {
    // Returns the number of NFTs owned by the given account
    function balanceOf(address _owner) external view returns (uint256);

    //Returns the owner of the given NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    //Transfer ownership of NFT
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    //Transfer ownership of NFT
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    //Transfer ownership of NFT
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    //Grants address ‘_approved’ the authorization of the NFT ‘_tokenId’
    function approve(address _approved, uint256 _tokenId) external payable;

    //Grant/recover all NFTs’ authorization of the ‘_operator’
    function setApprovalForAll(address _operator, bool _approved) external;

    //Query the authorized address of NFT
    function getApproved(uint256 _tokenId) external view returns (address);

    //Query whether the ‘_operator’ is the authorized address of the ‘_owner’
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    //The successful ‘transferFrom’ and ‘safeTransferFrom’ will trigger the ‘Transfer’ Event
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    //The successful ‘Approval’ will trigger the ‘Approval’ event
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    //The successful ‘setApprovalForAll’ will trigger the ‘ApprovalForAll’ event
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

contract TRC721 is TRC165, ITRC721, TRC721Helpers {
    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

    mapping(address => uint256[]) internal ownedTokens;
    mapping(address => mapping(uint256 => uint256)) internal ownedTokenIndex;

    constructor() internal {
        _registerInterface(_INTERFACE_ID_TRC721);
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(
            owner != address(0),
            "TRC721: balance query for the zero address"
        );
        return ownedTokens[owner].length;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_tokenExists(_tokenId), "Non Existing Token");
        return _ownerOf(_tokenId);
    }

    function transferChecks() internal;
    function postTransfer() internal;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable {
        require(_from != address(0), "Invalid from address");
        require(_to != address(0), "Invalid to address");
        require(_tokenExists(_tokenId), "Token does not exist");
        require(
            _isApproveOrOwner(msg.sender, _tokenId),
            "Not approved for transfer"
        );
        require(_to != address(0), "Invalid to: Zero Address");
        transferChecks();
        _transferFrom(_from, _to, _tokenId);
        postTransfer();
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external payable {
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(
            _isApproveOrOwner(msg.sender, tokenId),
            "TRC721: transfer caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        require(_approved != address(0), "Invalid address");
        require(_tokenExists(_tokenId), "Token does not exist");
        require(
            _isTokenOwner(_tokenId, msg.sender) ||
                _getOperatorApproved(_ownerOf(_tokenId), msg.sender),
            "Only owners can grant approval access"
        );

        _setApprovedAddress(_approved, _tokenId);
    }


    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenExists(_tokenId), "Token does not exist");
        return getApprovedAddress(_tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0), "Invalid address");
        require(
            msg.sender != _operator,
            "Operator address should not be the caller"
        );
        require(_userExists(msg.sender), "User does not exist");

        _setOperator(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        require(_userExists(msg.sender), "User does not exist");
        return _getOperatorApproved(_owner, _operator);
    }

    function _setOperator(
        address owner,
        address operator,
        bool approved
    ) internal {
        operatorMap[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _userExists(address addr) internal view returns (bool) {
        return ownedTokens[addr].length > 0;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transferFrom(from, to, tokenId);
        require(
            _checkOnTRC721Received(from, to, tokenId, _data),
            "TRC721: transfer to non TRC721Receiver implementer"
        );
    }

    function _checkOnTRC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_isContract(to)) {
            return true;
        }
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                ITRC721Receiver(to).onTRC721Received.selector,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("TRC721: transfer to non TRC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == 0x5175f878);
        }
    }

    function _isContract(address _addr)
        internal
        view
        returns (bool addressCheck)
    {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        addressCheck = size > 0;
    }


    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _clearApprovals(tokenId);
        _unregisterToken(tokenId, from);
        _registerToken(tokenId, to);
        emit Transfer(from, to, tokenId);
    }

    function _registerToken(uint256 tokenId, address addr) internal {
        ownedTokenIndex[addr][tokenId] = ownedTokens[addr].length;
        ownedTokens[addr].push(tokenId);
        tokenMap[tokenId]._owner = addr;
    }

    function _unregisterToken(uint256 tokenId, address addr) internal {
        uint256 lastTokenIndex = ownedTokens[addr].length - 1;
        uint256 lastToken = ownedTokens[addr][lastTokenIndex];

        if (lastToken != tokenId) {
            uint256 currentIndex = ownedTokenIndex[addr][tokenId];
            ownedTokens[addr][currentIndex] = lastToken;
            ownedTokenIndex[addr][lastToken] = currentIndex;
        }
        delete ownedTokenIndex[addr][tokenId];
        ownedTokens[addr].length--;
        tokenMap[tokenId]._owner = address(0);
    }

    function _clearApprovals(uint256 tokenId) internal {
        if (approvalMap[tokenId] != address(0)) {
            approvalMap[tokenId] = address(0);
        }
    }

    function _setApprovedAddress(address approvedAddress, uint256 tokenId)
        internal
    {
        address owner = _ownerOf(tokenId);
        approvalMap[tokenId] = approvedAddress;
        emit Approval(owner, approvedAddress, tokenId);
    }

    function getApprovedAddress(uint256 tokenId)
        internal
        view
        returns (address)
    {
        return approvalMap[tokenId];
    }
}


//SourceUnit: TRC721Enumerable.sol

// contracts/TRC721Enumerable.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./TRC165.sol";
import "./TRC721.sol";

interface ITRC721Enumerable {
    //Return the total supply of NFT
    function totalSupply() external view returns (uint256);

    //Return the corresponding ‘tokenId’ through ‘_index’
    function tokenByIndex(uint256 _index) external view returns (uint256);

    //Return the ‘tokenId’ corresponding to the index in the NFT list owned by the ‘_owner'
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);
}

contract TRC721Enumerable is ITRC721Enumerable, TRC721 {
    bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;
    mapping(address => mapping(uint256 => uint256)) private ownedTokenIndex;

    uint256[] internal _allTokens;

    constructor() public {
        _registerInterface(_INTERFACE_ID_TRC721_ENUMERABLE);
    }

    //Return the total supply of NFT
    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

    //Return the corresponding ‘tokenId’ through ‘_index’
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        return _allTokens[_index];
    }

    //Return the ‘tokenId’ corresponding to the index in the NFT list owned by the ‘_owner'
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256)
    {
        return ownedTokens[_owner][_index];
    }
}


//SourceUnit: TRC721Helpers.sol

// contracts/TRC721Helpers.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TRC721Helpers {

    struct TokenInfo {
        uint256 _id;
        address _owner;
        string _uri;
        bool _purchased;
    }


    mapping(uint256 => address) internal approvalMap;
    mapping(address => mapping(address => bool)) internal  operatorMap;
    mapping(uint256 => TokenInfo) internal tokenMap;

    function _getOperatorApproved(address owner, address operator)
        internal
        view
        returns (bool)
    {
        return operatorMap[owner][operator];
    }

    function _isTokenApproval(uint256 tokenId, address addr)
        internal
        view
        returns (bool)
    {
        require(_tokenExists(tokenId), "Token does not exist");
        return
            approvalMap[tokenId] == addr ||
            _getOperatorApproved(_ownerOf(tokenId), addr);
    }

    function _isTokenOwner(uint256 tokenId, address addr)
        internal
        view
        returns (bool)
    {
        require(_tokenExists(tokenId), "Token does not exist");
        return _ownerOf(tokenId) == addr;
    }

    function _isApproveOrOwner(address addr, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return _isTokenOwner(tokenId, addr) || _isTokenApproval(tokenId, addr);
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return tokenMap[tokenId]._owner;
    }
}

//SourceUnit: TRC721Metadata.sol

// contracts/TRC721Metadata.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./TRC165.sol";
import "./TRC721Helpers.sol";
import "./Ownable.sol";

interface ITRC721Metadata {
    //Return the token name
    function name() external view returns (string memory _name);

    //Return the token symbol
    function symbol() external view returns (string memory _symbol);

    //Returns the URI of the external file corresponding to ‘_tokenId’. External resource files need to include names, descriptions and pictures.
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


contract TRC721Metadata is ITRC721Metadata, TRC165, TRC721Helpers, Ownable {
    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;
    string private _name;
    string private _symbol;

    constructor(string memory name, string memory symbol) internal {
        _registerInterface(_INTERFACE_ID_TRC721_METADATA);
        _name = name;
        _symbol = symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(
            _tokenExists(_tokenId),
            "TRC721Metadata: URI query for nonexistent token"
        );

        TokenInfo storage info = tokenMap[_tokenId];

        if (msg.sender != owner()) {
            require(info._purchased, "Token not yet purchased");
        }

        return info._uri;
    }
}

//SourceUnit: TRC721Receiver.sol

// contracts/TRC721Receiver.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title TRC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from TRC721 asset contracts.
 */
interface ITRC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The TRC721 smart contract calls this function on the recipient
     * after a {ITRC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onTRC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the TRC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
     */
    function onTRC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


//SourceUnit: TestGoon.sol

// contracts/TestGoon.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./NFTVibravid.sol";

contract TestGoon is NFTVibravid {

    event NickNameUpdate(uint256 tokenId, string nickName);
    event BioUpdate(uint256 tokenId, string bio);

    mapping(string => bool) private _nickNameExists;
    mapping(string => uint256) private _nickNameTokenIdRegistry;
    mapping(uint256 => string) private _tokenNickName;
    mapping(uint256 => string) private _tokenBio;

    constructor() public NFTVibravid("Test Homies", "TH", 7500, 750, 75) {}

    function setNickName(uint256 tokenId, string memory nickName) public {
        require(_tokenExists(tokenId), "Token does not exist");
        require(
            _isApproveOrOwner(msg.sender, tokenId),
            "Not approved for transfer"
        );
        require(_nickNameExists[nickName] == false, "Nickname already registered" );

        _nickNameExists[nickName] = bytes(nickName).length > 0;
        _nickNameTokenIdRegistry[nickName] = tokenId;
        _tokenNickName[tokenId] = nickName;
    
        emit NickNameUpdate(tokenId, nickName);
    }

    function getNickName(uint256 tokenId) public view returns (string memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        return _tokenNickName[tokenId];
    }

    function getTokenIdByNickname(string memory nickName) public view returns(uint256) {
        require(_nickNameExists[nickName], "Nickname is not registered" );
        return _nickNameTokenIdRegistry[nickName];
    }

    function setBio(uint256 tokenId, string memory bio) public {
        require(_tokenExists(tokenId), "Token does not exist");
        require(
            _isApproveOrOwner(msg.sender, tokenId),
            "Not approved for transfer"
        );
        
        _tokenBio[tokenId] = bio;

    
        emit BioUpdate(tokenId, bio );
    }

    function getBio(uint256 tokenId) public view returns (string memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        return _tokenBio[tokenId];
    }

}