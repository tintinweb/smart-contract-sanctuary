pragma solidity ^0.4.24;

// File: contracts/OracleRequest.sol

/*
Interface for requests to the rate oracle (for EUR/ETH)
Copy this to projects that need to access the oracle.
See rate-oracle project for implementation.
*/
pragma solidity ^0.4.24;


contract OracleRequest {

    uint256 public EUR_WEI; //number of wei per EUR

    uint256 public lastUpdate; //timestamp of when the last update occurred

    function ETH_EUR() public view returns (uint256); //number of EUR per ETH (rounded down!)

    function ETH_EURCENT() public view returns (uint256); //number of EUR cent per ETH (rounded down!)

}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol

contract ERC721Holder is ERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes
  )
    public
    returns(bytes4)
  {
    return ERC721_RECEIVED;
  }
}

// File: contracts/OnChainShop.sol

/*
Implements an on-chain shop for cryptostamp
*/
pragma solidity ^0.4.24;






contract OnChainShop is ERC721Receiver {
    using SafeMath for uint256;

    ERC721 internal cryptostamp;
    OracleRequest internal oracle;

    address public beneficiary;
    address public shippingControl;
    address public tokenAssignmentControl;

    uint256 public priceEurCent;

    bool public isOpen = true;

    enum Status{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    event AssetSold(address indexed buyer, uint256 indexed tokenId, uint256 priceWei);
    event ShippingSubmitted(address indexed owner, uint256 indexed tokenId, string deliveryInfo);
    event ShippingFailed(address indexed owner, uint256 indexed tokenId, string reason);
    event ShippingConfirmed(address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => Status) public deliveryStatus;

    constructor(ERC721 _cryptostamp,
        OracleRequest _oracle,
        uint256 _priceEurCent,
        address _beneficiary,
        address _shippingControl,
        address _tokenAssignmentControl)
    public
    {
        cryptostamp = _cryptostamp;
        require(address(cryptostamp) != 0x0, "You need to provide an actual Cryptostamp contract.");
        oracle = _oracle;
        require(address(oracle) != 0x0, "You need to provide an actual Oracle contract.");
        beneficiary = _beneficiary;
        require(address(beneficiary) != 0x0, "You need to provide an actual beneficiary address.");
        tokenAssignmentControl = _tokenAssignmentControl;
        require(address(tokenAssignmentControl) != 0x0, "You need to provide an actual tokenAssignmentControl address.");
        shippingControl = _shippingControl;
        require(address(shippingControl) != 0x0, "You need to provide an actual shippingControl address.");
        priceEurCent = _priceEurCent;
        require(priceEurCent > 0, "You need to provide a non-zero price.");
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the current benefinicary can call this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyShippingControl() {
        require(msg.sender == shippingControl, "shippingControl key required for this function.");
        _;
    }

    modifier requireOpen() {
        require(isOpen == true, "This call only works when the shop is open.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function newPrice(uint256 _newPriceEurCent)
    public
    onlyBeneficiary
    {
        require(_newPriceEurCent > 0, "You need to provide a non-zero price.");
        priceEurCent = _newPriceEurCent;
    }

    function newBeneficiary(address _newBeneficiary)
    public
    onlyBeneficiary
    {
        beneficiary = _newBeneficiary;
    }

    function newOracle(OracleRequest _newOracle)
    public
    onlyBeneficiary
    {
        require(address(_newOracle) != 0x0, "You need to provide an actual Oracle contract.");
        oracle = _newOracle;
    }

    function openShop()
    public
    onlyBeneficiary
    {
        isOpen = true;
    }

    function closeShop()
    public
    onlyBeneficiary
    {
        isOpen = false;
    }

    /*** Actual shopping functionality ***/

    // Calculate current asset price in wei.
    // Note: Price in EUR cent is available from public var getter priceEurCent().
    function priceWei()
    public view
    returns (uint256)
    {
        return priceEurCent.mul(oracle.EUR_WEI()).div(100);
    }

    // For buying a single asset, just send enough ether to this contract.
    function()
    public payable
    requireOpen
    {
        // Transfer the actual price to the beneficiary, return the "change".
        uint256 curPriceWei = priceWei();
        require(msg.value >= curPriceWei, "You need to send enough currency to actually pay the item.");
        beneficiary.transfer(curPriceWei);
        if (msg.value > curPriceWei) {
            msg.sender.transfer(msg.value.sub(curPriceWei));
        }
        // Find the next stamp and transfer it.
        uint256 tokenId = cryptostamp.tokenOfOwnerByIndex(this, 0);
        cryptostamp.safeTransferFrom(this, msg.sender, tokenId);
        emit AssetSold(msg.sender, tokenId, curPriceWei);
        deliveryStatus[tokenId] = Status.Sold;
    }

    /*** Handle physical shipping ***/

    // For token owner (after successful purchase): Request shipping.
    // _deliveryInfo is a postal address encrypted with a public key on the client side.
    function shipToMe(string _deliveryInfo, uint256 _tokenId)
    public
    requireOpen
    {
        require(cryptostamp.ownerOf(_tokenId) == msg.sender, "You can only request shipping for your own tokens.");
        require(deliveryStatus[_tokenId] == Status.Sold, "Shipping was already requested for this token or it was not sold by this shop.");
        emit ShippingSubmitted(msg.sender, _tokenId, _deliveryInfo);
        deliveryStatus[_tokenId] = Status.ShippingSubmitted;
    }

    // For shipping service: Mark shipping as completed/confirmed.
    function confirmShipping(uint256 _tokenId)
    public
    onlyShippingControl
    {
        deliveryStatus[_tokenId] = Status.ShippingConfirmed;
        emit ShippingConfirmed(cryptostamp.ownerOf(_tokenId), _tokenId);
    }

    // For shipping service: Mark shipping as failed/rejected (due to invalid address).
    function rejectShipping(uint256 _tokenId, string _reason)
    public
    onlyShippingControl
    {
        deliveryStatus[_tokenId] = Status.Sold;
        emit ShippingFailed(cryptostamp.ownerOf(_tokenId), _tokenId, _reason);
    }

    /*** Make sure currency or NFT doesn&#39;t get stranded in this contract ***/

    // Override ERC721Receiver to special-case receiving ERC721 tokens:
    // We will prevent accepting a cryptostamp from others,
    // so we can make sure that we only sell physically shippable items.
    // We make an exception for "beneficiary", in case we decide to increase its stock in the future.
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data)
    public
    returns (bytes4)
    {
        require(_from == beneficiary, "Only the current benefinicary can send assets to the shop.");
        return ERC721_RECEIVED;
    }

    // If this contract gets a balance in some ERC20 contract after it&#39;s finished, then we can rescue it.
    function rescueToken(ERC20Basic _foreignToken, address _to)
    public
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(this));
    }
}