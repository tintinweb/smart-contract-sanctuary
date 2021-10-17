// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./owned.sol";
import "./StopTheWarOnDrugs.sol";
import "./context.sol";
import "./address-utils.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract SWDMarketPlace is 
Owned, 
Context, 
Initializable{

    using AddressUtils for address;

    string constant INVALID_ADDRESS = "0501";
    string constant CONTRACT_ADDRESS_NOT_SETUP = "0502";
    string constant NOT_APPROVED= "0503";
    string constant NOT_VALID_NFT = "0504";
    string constant NOT_FOR_SALE = "0505";
    string constant NOT_EHOUGH_ETHER = "0506";
    string constant NEGATIVE_VALUE = "0507";
    string constant NO_CHANGES_INTENDED = "0508";
    string constant NOT_NFT_OWNER = "0509";
    string constant INSUFICIENT_BALANCE = "0510";
    string constant STILL_OWN_NFT_CONTRACT = "0511";
    string constant NFT_ALREADY_MINTED = "0512";
    string constant PRICE_NOT_SET = "0513";
    string constant MINTING_LOCKED = "0514";
    

    event Sent(address indexed payee, uint amount);
    event RoyaltyPaid(address indexed payee, uint amount);
    event SecurityWithdrawal(address indexed payee, uint amount);

    StopTheWarOnDrugs public TokenContract;

    /**
    * @dev Mapping from token ID to its pirce.
    */
    mapping(uint => uint256) internal price;

    /**
    * @dev Mapping from token ID to royalty address.
    */
    mapping(uint => address) internal royaltyAddress;

    /**
    * @dev Mapping from NFT ID to boolean representing
    * if it is for sale or not.
    */
    mapping(uint => bool) internal forSale;

    /**
    * @dev contract balance
    */
    uint internal contractBalance;

    /**
    * @dev reentrancy safe and control for minting method
    */
    bool internal mintLock;


    /**
    * @dev Contract Constructor/Initializer
    */
    function initialize() public initializer { 
        isOwned();
    }

    /**
    * @dev update the address of the NFTs
    * @param nmwdAddress address of NoMoreWarOnDrugs tokens 
    */
    function updateNMWDcontract(address nmwdAddress) external onlyOwner{
        require(nmwdAddress != address(0) && nmwdAddress != address(this),INVALID_ADDRESS);
        require(address(TokenContract) != nmwdAddress,NO_CHANGES_INTENDED);
        TokenContract = StopTheWarOnDrugs(nmwdAddress);
    }

    /**
    * @dev transfers ownership of the NFT contract to the owner of 
    * the marketplace contract. Only if the marketplace owns the NFT
    */
    function getBackOwnership() external onlyOwner{
        require(address(TokenContract) != address(0),CONTRACT_ADDRESS_NOT_SETUP);
        TokenContract.transferOwnership(address(owner));
    }


    /**
    * @dev Purchase _tokenId
    * @param _tokenId uint token ID (painting number)
    */
    function purchaseToken(uint _tokenId) external payable  {
        require(forSale[_tokenId], NOT_FOR_SALE);
        require(_msgSender() != address(0) && _msgSender() != address(this));
        require(price[_tokenId] > 0,PRICE_NOT_SET);
        require(msg.value >= price[_tokenId]);
        require(TokenContract.ownerOf(_tokenId) != address(0), NOT_VALID_NFT);

        address tokenSeller = TokenContract.ownerOf(_tokenId);
        require(TokenContract.getApproved(_tokenId) == address(this) || 
                TokenContract.isApprovedForAll(tokenSeller, address(this)), 
                NOT_APPROVED);

        forSale[_tokenId] = false;


        // this is the fee of the contract per transaction: 0.8%
        uint256 saleFee = (msg.value / 1000) * 8;
        contractBalance += saleFee;

        //calculating the net amount of the sale
        uint netAmount = msg.value - saleFee;

        (address royaltyReceiver, uint256 royaltyAmount) = TokenContract.royaltyInfo( _tokenId, netAmount);

        //calculating the amount to pay the seller 
        uint256 toPaySeller = netAmount - royaltyAmount;

        //paying the seller and the royalty recepient
        (bool successSeller, ) =tokenSeller.call{value: toPaySeller, gas: 120000}("");
        require( successSeller, "Paying seller failed");
        (bool successRoyalties, ) =royaltyReceiver.call{value: royaltyAmount, gas: 120000}("");
        require( successRoyalties, "Paying Royalties failed");

        //transfer the NFT to the buyer
        TokenContract.safeTransferFrom(tokenSeller, _msgSender(), _tokenId);

        //notifying the blockchain
        emit Sent(tokenSeller, toPaySeller);
        emit RoyaltyPaid(royaltyReceiver, royaltyAmount);
        
    }

    /**
    * @dev mint an NFT through the market place
    * @param _to the address that will receive the freshly minted NFT
    * @param _tokenId uint token ID (painting number)
    */
    function mintThroughPurchase(address _to, uint _tokenId) external payable {
        require(price[_tokenId] > 0, PRICE_NOT_SET);
        require(msg.value >= price[_tokenId],NOT_EHOUGH_ETHER);
        require(_msgSender() != address(0) && _msgSender() != address(this));
        //avoid reentrancy. Also mintLocked before launch time.
        require(!mintLock,MINTING_LOCKED);
        mintLock=true;

        //we extract the royalty address from the mapping
        address royaltyRecipient = royaltyAddress[_tokenId];
        //this is hardcoded 6.0% for all NFTs
        uint royaltyValue = 600;

        contractBalance += msg.value;

        TokenContract.mint(_to, _tokenId, royaltyRecipient, royaltyValue);
        
        mintLock=false;
    }

    /**
    * @dev send / withdraw _amount to _payee
    * @param _payee the address where the funds are going to go
    * @param _amount the amount of Ether that will be sent
    */
    function withdrawFromContract(address _payee, uint _amount) external onlyOwner {
        require(_payee != address(0) && _payee != address(this));
        require(contractBalance >= _amount, INSUFICIENT_BALANCE);
        require(_amount > 0 && _amount <= address(this).balance, NOT_EHOUGH_ETHER);

        //we check if somebody has hacked the contract, in which case we send all the funds to 
        //the owner of the contract
        if(contractBalance != address(this).balance){
            contractBalance = 0;
            payable(owner).transfer(address(this).balance);
            emit SecurityWithdrawal(owner, _amount);
        }else{
            contractBalance -= _amount;
            payable(_payee).transfer(_amount);
            emit Sent(_payee, _amount);
        }
    }   

    /**
    * @dev Updates price for the _tokenId NFT
    * @dev Throws if updating price to the same current price, or to negative
    * value, or is not the owner of the NFT.
    * @param _price the price in wei for the NFT
    * @param _tokenId uint token ID (painting number)
    */
    function setPrice(uint _price, uint _tokenId) external {
        require(_price > 0, NEGATIVE_VALUE);
        require(_price != price[_tokenId], NO_CHANGES_INTENDED);
        //Only owner of NFT can set a price
        address _address = TokenContract.ownerOf(_tokenId);
        require(_address == _msgSender());
        
        //finally, we do what we came here for.
        price[_tokenId] = _price;
    } 

    /**
    * @dev Updates price for the _tokenId NFT before minting
    * @dev Throws if updating price to the same current price, or to negative
    * value, or if sender is not the owner of the marketplace.
    * @param _price the price in wei for the NFT
    * @param _tokenId uint token ID (painting number)
    * @param _royaltyAddress the address that will receive the royalties.
    */
    function setPriceForMinting(uint _price, uint _tokenId, address _royaltyAddress) external onlyOwner{
        require(_price > 0, NEGATIVE_VALUE);
        require(_price != price[_tokenId], NO_CHANGES_INTENDED);
        require(_royaltyAddress != address(0) && _royaltyAddress != address(this),INVALID_ADDRESS);
        //this makes sure this is only set before minting. It is impossible to change the
        //royalty address once it's been minted. The price can then be only reset by the NFT owner.
        require( !TokenContract.exists(_tokenId),NFT_ALREADY_MINTED);
        
        //finally, we do what we came here for.
        price[_tokenId] = _price;
        royaltyAddress[_tokenId] = _royaltyAddress;
    } 

    /**
    * @dev get _tokenId price in wei
    * @param _tokenId uint token ID 
    */
    function getPrice(uint _tokenId) external view returns (uint256){
        return price[_tokenId];
    }    

    /**
    * @dev get marketplace's balance (weis)
    */
    function getMarketPlaceBalance() external view returns (uint256){
        return contractBalance;
    }   

    /**
    * @dev sets the token with _tokenId a boolean representing if it's for sale or not.
    * @param _tokenId uint token ID 
    * @param _forSale is it or not for sale? (true/false)
    */
    function setForSale(uint _tokenId, bool _forSale) external returns (bool){
        
        try TokenContract.ownerOf(_tokenId) returns (address _address) {
            require(_address == _msgSender(),NOT_NFT_OWNER);
        }catch {
           return false;
        }
        require(_forSale != forSale[_tokenId],NO_CHANGES_INTENDED);
        forSale[_tokenId] = _forSale;
        return true;
    } 

    /**
    * @dev gets the token with _tokenId forSale variable.
    * @param _tokenId uint token ID 
    */
    function getForSale(uint _tokenId) external view returns (bool){
        return forSale[_tokenId];
    } 

    /**
   * @dev Burns an NFT.
   * @param _tokenId of the NFT to burn.
   */
    function burn(uint256 _tokenId ) external onlyOwner {
        TokenContract.burn( _tokenId);
  }
    /**
   * @dev the receive method to avoid balance incongruence
   */
  receive() external payable{
        contractBalance += msg.value;
    }

  /**
   * @dev locks/unlocks the mint method.
   * @param _locked bool value to set.
   */
    function setMintLock(bool _locked) external onlyOwner {
        mintLock=_locked;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract Owned {
    
    /**
    * @dev Error constants.
    */
    string public constant NOT_CURRENT_OWNER = "0101";
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "0102";

    /**
    * @dev Current owner address.
    */
    address public owner;

    /**
    * @dev An event which is triggered when the owner is changed.
    * @param previousOwner The address of the previous owner.
    * @param newOwner The address of the new owner.
    */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event _msg(address deliveredTo, string msg);

    function isOwned() internal {
        owner = msg.sender;
        emit _msg(owner, "set owner" );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        emit _msg(owner, "passed ownership requirement" );
        _;
    }

    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {

    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function getOwner() public view returns (address){
    return owner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


import "./nf-token-enumerable.sol";
import "./nf-token-metadata.sol";
import "./owned.sol";
import "./erc2981-per-token-royalties.sol";

contract StopTheWarOnDrugs is NFTokenEnumerable, NFTokenMetadata, 
///Owned, 
ERC2981PerTokenRoyalties {

    /** 
    * @dev error when an NFT is attempted to be minted after the max
    * supply of NFTs has been already reached.
    */
    string constant MAX_TOKENS_MINTED = "0401";

    /** 
    * @dev error when the message for an NFT is trying to be set afet
    * it has been already set.
    */
    string constant MESSAGE_ALREADY_SET = "0402";

    /** 
    * @dev The message doesn't comply with the size restrictions
    */
    string constant NOT_VALID_MSG = "0403";

    /** 
    * @dev Can't pass 0 as value for the argument
    */
    string constant ZERO_VALUE = "0404";

    /** 
    * @dev The maximum amount of NFTs that can be minted in this collection
    */
    uint16 constant MAX_TOKENS = 904;

    /** 
    * @dev Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    * which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /**
    * @dev Mapping from NFT ID to message.
    */
    mapping (uint256 => string) private idToMsg;


    constructor(string memory _name, string memory _symbol){
        isOwned();
        nftName = _name;
        nftSymbol = _symbol;
    }

    /**
    * @dev Mints a new NFT.
    * @notice an approveForAll is given to the owner of the contract.
    * This is due to the fact that the marketplae of this project will 
    * own this contract. Therefore, the NFTs will be transactable in 
    * the marketplace by default without any extra step from the user.
    * @param _to The address that will own the minted NFT.
    * @param _tokenId of the NFT to be minted by the msg.sender.
    * @param royaltyRecipient the address that will be entitled for the royalties.
    * @param royaltyValue the percentage (from 0 - 10000) of the royalties
    * @notice royaltyValue is amplified 100 times to be able to write a percentage
    * with 2 decimals of precision. Therefore, 1 => 0.01%; 100 => 1%; 10000 => 100%
    * @notice the URI is build from the tokenId since it is the SHA2-256 of the
    * URI content in IPFS.
    */
    function mint(address _to, uint256 _tokenId, 
                  address royaltyRecipient, uint256 royaltyValue) 
      external onlyOwner 
      {
        _mint(_to, _tokenId);
        //uri setup
        string memory _uri = getURI(_tokenId);
        idToUri[_tokenId] = _uri;
        //royalties setup
         if (royaltyValue > 0) {
            _setTokenRoyalty(_tokenId, royaltyRecipient, royaltyValue);
        }
        //approve marketplace
        if(!ownerToOperators[_to][owner]){
           ownerToOperators[_to][owner] = true;
         }
    }

    /**
    * @dev Mints a new NFT.
    * @param _to The address that will own the minted NFT.
    * @param _tokenId of the NFT to be minted by the msg.sender.
    */
    function _mint( address _to, uint256 _tokenId ) internal override (NFTokenEnumerable, NFToken){
        require( tokens.length < MAX_TOKENS, MAX_TOKENS_MINTED );
        super._mint(_to, _tokenId);
        
    }


    /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(  address _to, uint256 _tokenId ) internal override  (NFTokenEnumerable, NFToken){
    super._addNFToken(_to, _tokenId);
  }

  function addNFToken(address _to, uint256 _tokenId) internal {
        _addNFToken(_to, _tokenId);
    }

    /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn( uint256 _tokenId ) internal override (NFTokenEnumerable, NFTokenMetadata) {
    super._burn(_tokenId);
  }

  function burn(uint256 _tokenId ) public onlyOwner {
      //clearing the uri
      idToUri[_tokenId] = "";
      //clearing the royalties
      _setTokenRoyalty(_tokenId, address(0), 0);
      //burning the token for good
      _burn( _tokenId);
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(  address _owner  ) internal override(NFTokenEnumerable, NFToken) view returns (uint256) {
    return super._getOwnerNFTCount(_owner);
  }

  function getOwnerNFTCount(  address _owner  ) public view returns (uint256) {
    return _getOwnerNFTCount(_owner);
  }

/**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override (NFTokenEnumerable, NFToken) 
  {
      super._removeNFToken(_from, _tokenId);
  }

  function removeNFToken(address _from, uint256 _tokenId) internal {
      _removeNFToken(_from, _tokenId);
  }


  /**
   * @dev A custom message given for the first NFT buyer.
   * @param _tokenId Id for which we want the message.
   * @return Message of _tokenId.
   */
  function tokenMessage(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToMsg[_tokenId];
  }

  /**
   * @dev Sets a custom message for the NFT with _tokenId.
   * @notice only the owner of the NFT can do this. Not even approved or 
   * operators can execute this function.
   * @param _tokenId Id for which we want the message.
   * @param _msg the custom message.
   */
  function setTokenMessage(
    uint256 _tokenId,
    string memory _msg
  )
    external
    validNFToken(_tokenId)
  { 
    address tokenOwner = idToOwner[_tokenId];
    require(_msgSender() == tokenOwner, NOT_OWNER);
    require(bytes(idToMsg[_tokenId]).length == 0, MESSAGE_ALREADY_SET);
    bool valid_msg = validateMsg(_msg);
    require(valid_msg, NOT_VALID_MSG);
    idToMsg[_tokenId] = _msg;
  }

  /**
     * @dev Check if the message string has a valid length
     * @param _msg the custom message.
     */
    function validateMsg(string memory _msg) public pure returns (bool){
        bytes memory b = bytes(_msg);
        if(b.length < 1) return false;
        if(b.length > 300) return false; // Cannot be longer than 300 characters
        return true;
    }

 /**
   * @dev returns the list of NFTs owned by certain address.
   * @param _address Id for which we want the message.
   */
  function getNFTsByAddress(
    address _address
  )
    view external returns (uint256[] memory)
  { 
    return ownerToIds[_address];
  }

  /**
    * @dev Builds and return the URL string from the tokenId.
    * @notice the tokenId is the SHA2-256 of the URI content in IPFS.
    * This ensures the complete authenticity of the token minted. The URL is
    * therefore an IPFS URL which follows the pattern: 
    * ipfs://<CID>
    * And the CID can be constructed as follows:
    * CID = F01701220<ID>  
    * F signals that the CID is in hexadecimal format. 01 means CIDv1. 70 signals   
    * dag-pg link-data coding used. 12 references the hashing algorith SHA2-256.
    * 20 is the length in bytes of the hash. In decimal, 32 bytes as specified
    * in the SHA2-256 protocol. Finally, <ID> is the tokenId (the hash).
    * @param _tokenId of the NFT (the SHA2-256 of the URI content).
    */
  function getURI(uint _tokenId) internal pure returns(string memory){
        string memory _hex = uintToHexStr(_tokenId);
        string memory prefix = "ipfs://F01701220";
        string memory result = string(abi.encodePacked(prefix,_hex ));
        return result;
    }

    /**
    * @dev Converts a uint into a hex string of 64 characters. Throws if 0 is passed.
    * @notice that the returned string doesn't prepend the usual "0x".
    * @param _uint number to convert to string.
    */
  function uintToHexStr(uint _uint) internal pure returns (string memory) {
        require(_uint != 0, ZERO_VALUE);
        bytes memory byteStr = new bytes(64);
        for (uint j = 0; j < 64 ;j++){
            uint curr = (_uint & 15); //mask that allows us to filter only the last 4 bits (last character)
            byteStr[63-j] = curr > 9 ? bytes1( uint8(55) + uint8(curr) ) :
                                        bytes1( uint8(48) + uint8(curr) ); // 55 = 65 - 10
            _uint = _uint >> 4;   
        }
        return string(byteStr);
      }

    /**
    * @dev Destroys the contract
    * @notice that, due to the danger that the call of this contract poses, it is required
    * to pass a specific integer value to effectively call this method.
    * @param security_value number to pass security restriction (192837).
    */
      function seflDestruct(uint security_value) external onlyOwner { 
        require(security_value == 192837); //this is just to make sure that this method was not called by accident
        selfdestruct(payable(owner)); 
      }

    /**
    * @dev returns boolean representing the existance of an NFT
    * @param _tokenId of the NFT to look up.
    */
      function exists(uint _tokenId) external view returns (bool) { 
        if( idToOwner[_tokenId] == address(0)){
          return false;
        }else{
          return true;
        }
      }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./nf-token.sol";
import "./erc721-enumerable.sol";

/**
 * @dev Optional enumeration implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenEnumerable is NFToken, ERC721Enumerable {

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant INVALID_INDEX = "0201";
  

  /**
   * @dev Array of all NFT IDs.
   */
  uint256[] internal tokens;

  /**
   * @dev Mapping from token ID to its index in global tokens array.
   */
  mapping(uint256 => uint256) internal idToIndex;

  /**
   * @dev Mapping from owner to list of owned NFT IDs.
   */
  mapping(address => uint256[]) internal ownerToIds;

  /**
   * @dev Mapping from NFT ID to its index in the owner tokens list.
   */
  mapping(uint256 => uint256) internal idToOwnerIndex;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
  }

  /**
   * @dev Returns the count of all existing NFTokens.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    override
    view
    returns (uint256)
  {
    return tokens.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }

  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _owner Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].pop();
  }

  /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    idToOwner[_tokenId] = _to;

    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override
    virtual
    view
    returns (uint256)
  {
    return ownerToIds[_owner].length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./nf-token.sol";
import "./erc721-metadata.sol";

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  /**
   * @dev A descriptive name for a collection of NFTs.
   */
  string internal nftName;

  /**
   * @dev An abbreviated name for NFTokens.
   */
  string internal nftSymbol;

  /**
   * @dev Mapping from NFT ID to metadata uri.
   */
  mapping (uint256 => string) internal idToUri;

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don't forget to set nftName and nftSymbol.
   */
  constructor()
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   * @return _name Representing name.
   */
  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }

  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
   * @notice This is an internal function which should be called from user-implemented external
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _tokenId Id for which we want URI.
   * @param _uri String representing RFC 3986 URI.
   */
  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ierc2981-royalties.sol';
import "./supports-interface.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
contract ERC2981PerTokenRoyalties is IERC2981Royalties, SupportsInterface {

    /**
    * @dev This is where the info about the royalty resides
    * @dev recipient is the address where the royalties should be sent to.
    * @dev value is the percentage of the sale value that will be sent as royalty.
    * @notice "value" will be expressed as an unsigned integer between 0 and 1000. 
    * This means that 10000 = 100%, and 1 = 0.01%
    */
    struct Royalty {
        address recipient;
        uint256 value;
    }

    /**
    * @dev the data structure where the NFT id points to the Royalty struct with the
    * corresponding royalty info.
    */
    mapping(uint256 => Royalty) internal idToRoyalties;

    constructor(){
        supportedInterfaces[0x2a55205a] = true; // ERC2981
    }

    /** 
    * @dev Sets token royalties
    * @param id the token id fir which we register the royalties
    * @param recipient recipient of the royalties
    * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    */
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        idToRoyalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = idToRoyalties[_tokenId];
        return (royalty.recipient, (_salePrice * royalty.value) / 10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./erc721.sol";
import "./erc721-token-receiver.sol";
import "./supports-interface.sol";
import "./address-utils.sol";
import "./context.sol";
import "./owned.sol";

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is
  ERC721,
  Context,
  SupportsInterface,
  Owned
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "0301";
  string constant NOT_VALID_NFT = "0302";
  string constant NOT_OWNER_OR_OPERATOR = "0303";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "0304";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "0305";
  string constant NFT_ALREADY_EXISTS = "0306";
  string constant NOT_OWNER = "0307";
  string constant IS_OWNER = "0308";

  /**
   * @dev Magic value of a smart contract that can recieve NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of his tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the_msgSender() is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner ==_msgSender() || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the_msgSender() is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner ==_msgSender()
      || idToApproval[_tokenId] ==_msgSender()
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they maybe be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn't own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @dev Actually preforms the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    //Native marketplace (owner) will always be an authorized operator.
        if(!ownerToOperators[_to][owner]){
           ownerToOperators[_to][owner] = true;
         }

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the_msgSender().
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, "");
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

  /**
   * @dev Assignes a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to] + 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }
  }

  

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Enumerable
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./erc165.sol";

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev A standard for detecting smart contract interfaces. 
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface ERC165
{

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Metadata
{

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   * @return _name Representing name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * @return URI of _tokenId.
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}