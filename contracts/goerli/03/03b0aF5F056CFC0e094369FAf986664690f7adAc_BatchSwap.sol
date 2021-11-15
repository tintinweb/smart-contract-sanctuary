// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

//Interface
abstract contract ERC20Interface {
  function transferFrom(address from, address to, uint256 tokenId) public virtual;
  function transfer(address recipient, uint256 amount) public virtual;
}

abstract contract ERC721Interface {
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
  function balanceOf(address owner) public virtual view returns (uint256 balance) ;
}

abstract contract ERC1155Interface {
  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual;
}

abstract contract CPInterface {
  function transferPunk(address to, uint index) public virtual;
  function punkIndexToAddress(uint index) public virtual view returns (address owner);
}

abstract contract customInterface {
  function bridgeSafeTransferFrom(address dapp, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual;
}

contract PunkProxy {
    address private owner;
    address private punkOwner;
    constructor(address _owner, address _punkOwner) {
        owner = _owner;
        punkOwner = _punkOwner;
    }

    function proxyTransferPunk(address _punkContract, address _to, uint256 _punkIndex) public {
        require(owner == msg.sender, "You're not the contract owner");
        require(CPInterface(_punkContract).punkIndexToAddress(_punkIndex) == address(this), "Punk is missing from this Proxy");
        CPInterface(_punkContract).transferPunk(_to, _punkIndex);
    }

    function changeCurrentProxyOwner(address _newOwner) public {
        require(owner == msg.sender, "You're not the contract owner");
        owner = _newOwner;
    }

    function recoverPunk(address _punkContract, address _recover, uint256 _punkIndex) public {
        require(owner == msg.sender, "You're not the contract owner");
        require(punkOwner == _recover, "You're not the punk owner");
        require(CPInterface(_punkContract).punkIndexToAddress(_punkIndex) == address(this), "Punk is missing from this Proxy");
        CPInterface(_punkContract).transferPunk(_recover, _punkIndex);
    }
}

contract BatchSwap is Ownable, Pausable, IERC721Receiver, IERC1155Receiver {
    address constant ERC20      = 0x90b7cf88476cc99D295429d4C1Bb1ff52448abeE;
    address constant ERC721     = 0x58874d2951524F7f851bbBE240f0C3cF0b992d79;
    address constant ERC1155    = 0xEDfdd7266667D48f3C9aB10194C3d325813d8c39;

    address public CRYPTOPUNK = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    mapping (address => PunkProxy) punkProxies;
    mapping (uint256 => bool) punkInUse;

    address public TRADESQUAD = 0xdbD4264248e2f814838702E0CB3015AC3a7157a1;
    address payable public VAULT = 0xdbD4264248e2f814838702E0CB3015AC3a7157a1;

    mapping (address => address) dappRelations;

    mapping (address => bool) whiteList;
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 constant secs = 86400;
    
    Counters.Counter private _swapIds;

    // Flag for the createSwap
    bool private swapFlag;
    
    // Swap Struct
    struct swapStruct {
        address dapp;
        address typeStd;
        uint256[] tokenId;
        uint256[] blc;
        bytes data;
    }
    
    // Swap Status
    enum swapStatus { Opened, Closed, Cancelled }
    
    // SwapIntent Struct
    struct swapIntent {
        uint256 id;
        address payable addressOne;
        uint256 valueOne;
        address payable addressTwo;
        uint256 valueTwo;
        uint256 swapStart;
        uint256 swapEnd;
        uint256 swapFee;
        swapStatus status;
    }
    
    // NFT Mapping
    mapping(uint256 => swapStruct[]) nftsOne;
    mapping(uint256 => swapStruct[]) nftsTwo;

    // Struct Payment
    struct paymentStruct {
        bool status;
        uint256 value;
    }
    
    // Mapping key/value for get the swap infos
    mapping (address => swapIntent[]) swapList;
    mapping (uint256 => uint256) swapMatch;
    
    // Struct for the payment rules
    paymentStruct payment;
    
    
    // Events
    event swapEvent(address indexed _creator, uint256 indexed time, swapStatus indexed _status, uint256 _swapId, address _swapCounterPart);
    event paymentReceived(address indexed _payer, uint256 _value);

    receive() external payable { 
        emit paymentReceived(msg.sender, msg.value);
    }
    
    // Create Swap
    function createSwapIntent(swapIntent memory _swapIntent, swapStruct[] memory _nftsOne, swapStruct[] memory _nftsTwo) payable public whenNotPaused {
        if(payment.status) {
            if(ERC721Interface(TRADESQUAD).balanceOf(msg.sender)==0) {
                require(msg.value>=payment.value.add(_swapIntent.valueOne), "Not enought WEI for handle the transaction");
                _swapIntent.swapFee = getWeiPayValueAmount() ;
            }
            else {
                require(msg.value>=_swapIntent.valueOne, "Not enought WEI for handle the transaction");
                _swapIntent.swapFee = 0 ;
            }
        }
        else
            require(msg.value>=_swapIntent.valueOne, "Not enought WEI for handle the transaction");

        _swapIntent.addressOne = msg.sender;
        _swapIntent.id = _swapIds.current();
        _swapIntent.swapStart = block.timestamp;
        _swapIntent.swapEnd = 0;
        _swapIntent.status = swapStatus.Opened ;

        swapMatch[_swapIds.current()] = swapList[msg.sender].length;
        swapList[msg.sender].push(_swapIntent);
        
        uint256 i;
        for(i=0; i<_nftsOne.length; i++)
            nftsOne[_swapIntent.id].push(_nftsOne[i]);
            
        for(i=0; i<_nftsTwo.length; i++)
            nftsTwo[_swapIntent.id].push(_nftsTwo[i]);
        
        for(i=0; i<nftsOne[_swapIntent.id].length; i++) {
            require(whiteList[nftsOne[_swapIntent.id][i].dapp], "A DAPP is not handled by the system");
            if(nftsOne[_swapIntent.id][i].typeStd == ERC20) {
                ERC20Interface(nftsOne[_swapIntent.id][i].dapp).transferFrom(_swapIntent.addressOne, address(this), nftsOne[_swapIntent.id][i].blc[0]);
            }
            else if(nftsOne[_swapIntent.id][i].typeStd == ERC721) {
                ERC721Interface(nftsOne[_swapIntent.id][i].dapp).safeTransferFrom(_swapIntent.addressOne, address(this), nftsOne[_swapIntent.id][i].tokenId[0], nftsOne[_swapIntent.id][i].data);
            }
            else if(nftsOne[_swapIntent.id][i].typeStd == ERC1155) {
                ERC1155Interface(nftsOne[_swapIntent.id][i].dapp).safeBatchTransferFrom(_swapIntent.addressOne, address(this), nftsOne[_swapIntent.id][i].tokenId, nftsOne[_swapIntent.id][i].blc, nftsOne[_swapIntent.id][i].data);
            }
            else if(nftsOne[_swapIntent.id][i].typeStd == CRYPTOPUNK) { // Controllo che il CP sia presente sul proxy e che non sia in uso in un altro trade
                require(punkInUse[nftsOne[_swapIntent.id][i].tokenId[0]] == false, "Punk in use on another trade");
                require(CPInterface(CRYPTOPUNK).punkIndexToAddress(nftsOne[_swapIntent.id][i].tokenId[0]) == address(punkProxies[msg.sender]), "CryptoPunk missing");
                punkInUse[nftsOne[_swapIntent.id][i].tokenId[0]] = true;
            }
            else {
                customInterface(dappRelations[nftsOne[_swapIntent.id][i].dapp]).bridgeSafeTransferFrom(nftsOne[_swapIntent.id][i].dapp, _swapIntent.addressOne, dappRelations[nftsOne[_swapIntent.id][i].dapp], nftsOne[_swapIntent.id][i].tokenId, nftsOne[_swapIntent.id][i].blc, nftsOne[_swapIntent.id][i].data);
            }
        }

        emit swapEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), _swapIntent.status, _swapIntent.id, _swapIntent.addressTwo);
        _swapIds.increment();
    }
    
    // Close the swap
    function closeSwapIntent(address _swapCreator, uint256 _swapId) payable public whenNotPaused {
        require(swapList[_swapCreator][swapMatch[_swapId]].status == swapStatus.Opened, "Swap Status is not opened");
        require(swapList[_swapCreator][swapMatch[_swapId]].addressTwo == msg.sender, "You're not the interested counterpart");
        if(payment.status) {
            if(ERC721Interface(TRADESQUAD).balanceOf(msg.sender)==0) {
                require(msg.value>=payment.value.add(swapList[_swapCreator][swapMatch[_swapId]].valueTwo), "Not enought WEI for handle the transaction");
                // Move the fees to the vault
                if(payment.value.add(swapList[_swapCreator][swapMatch[_swapId]].swapFee) > 0)
                    VAULT.transfer(payment.value.add(swapList[_swapCreator][swapMatch[_swapId]].swapFee));
            }
            else {
                require(msg.value>=swapList[_swapCreator][swapMatch[_swapId]].valueTwo, "Not enought WEI for handle the transaction");
                if(swapList[_swapCreator][swapMatch[_swapId]].swapFee>0)
                    VAULT.transfer(swapList[_swapCreator][swapMatch[_swapId]].swapFee);
            }
        }
        else
            require(msg.value>=swapList[_swapCreator][swapMatch[_swapId]].valueTwo, "Not enought WEI for handle the transaction");
        
        swapList[_swapCreator][swapMatch[_swapId]].addressTwo = msg.sender;
        swapList[_swapCreator][swapMatch[_swapId]].swapEnd = block.timestamp;
        swapList[_swapCreator][swapMatch[_swapId]].status = swapStatus.Closed;
        
        //From Owner 1 to Owner 2
        uint256 i;
        for(i=0; i<nftsOne[_swapId].length; i++) {
            require(whiteList[nftsOne[_swapId][i].dapp], "A DAPP is not handled by the system");
            if(nftsOne[_swapId][i].typeStd == ERC20) {
                ERC20Interface(nftsOne[_swapId][i].dapp).transfer(swapList[_swapCreator][swapMatch[_swapId]].addressTwo, nftsOne[_swapId][i].blc[0]);
            }
            else if(nftsOne[_swapId][i].typeStd == ERC721) {
                ERC721Interface(nftsOne[_swapId][i].dapp).safeTransferFrom(address(this), swapList[_swapCreator][swapMatch[_swapId]].addressTwo, nftsOne[_swapId][i].tokenId[0], nftsOne[_swapId][i].data);
            }
            else if(nftsOne[_swapId][i].typeStd == ERC1155) {
                ERC1155Interface(nftsOne[_swapId][i].dapp).safeBatchTransferFrom(address(this), swapList[_swapCreator][swapMatch[_swapId]].addressTwo, nftsOne[_swapId][i].tokenId, nftsOne[_swapId][i].blc, nftsOne[_swapId][i].data);
            }
            else if(nftsOne[_swapId][i].typeStd == CRYPTOPUNK) { // Controllo che il CP sia su questo smart contract
                require(CPInterface(CRYPTOPUNK).punkIndexToAddress(nftsOne[_swapId][i].tokenId[0]) == address(punkProxies[swapList[_swapCreator][swapMatch[_swapId]].addressOne]), "CryptoPunk missing");
                punkProxies[swapList[_swapCreator][swapMatch[_swapId]].addressOne].proxyTransferPunk(CRYPTOPUNK, swapList[_swapCreator][swapMatch[_swapId]].addressTwo, nftsOne[_swapId][i].tokenId[0]);
                punkInUse[nftsOne[_swapId][i].tokenId[0]] = false;
            }
            else {
                customInterface(dappRelations[nftsOne[_swapId][i].dapp]).bridgeSafeTransferFrom(nftsOne[_swapId][i].dapp, dappRelations[nftsOne[_swapId][i].dapp], swapList[_swapCreator][swapMatch[_swapId]].addressTwo, nftsOne[_swapId][i].tokenId, nftsOne[_swapId][i].blc, nftsOne[_swapId][i].data);
            }
        }
        if(swapList[_swapCreator][swapMatch[_swapId]].valueOne > 0)
            swapList[_swapCreator][swapMatch[_swapId]].addressTwo.transfer(swapList[_swapCreator][swapMatch[_swapId]].valueOne);
        
        //From Owner 2 to Owner 1
        for(i=0; i<nftsTwo[_swapId].length; i++) {
            require(whiteList[nftsTwo[_swapId][i].dapp], "A DAPP is not handled by the system");
            if(nftsTwo[_swapId][i].typeStd == ERC20) {
                ERC20Interface(nftsTwo[_swapId][i].dapp).transferFrom(swapList[_swapCreator][swapMatch[_swapId]].addressTwo, swapList[_swapCreator][swapMatch[_swapId]].addressOne, nftsTwo[_swapId][i].blc[0]);
            }
            else if(nftsTwo[_swapId][i].typeStd == ERC721) {
                ERC721Interface(nftsTwo[_swapId][i].dapp).safeTransferFrom(swapList[_swapCreator][swapMatch[_swapId]].addressTwo, swapList[_swapCreator][swapMatch[_swapId]].addressOne, nftsTwo[_swapId][i].tokenId[0], nftsTwo[_swapId][i].data);
            }
            else if(nftsTwo[_swapId][i].typeStd == ERC1155) {
                ERC1155Interface(nftsTwo[_swapId][i].dapp).safeBatchTransferFrom(swapList[_swapCreator][swapMatch[_swapId]].addressTwo, swapList[_swapCreator][swapMatch[_swapId]].addressOne, nftsTwo[_swapId][i].tokenId, nftsTwo[_swapId][i].blc, nftsTwo[_swapId][i].data);
            }
            else if(nftsTwo[_swapId][i].typeStd == CRYPTOPUNK) {
                require(CPInterface(CRYPTOPUNK).punkIndexToAddress(nftsTwo[_swapId][i].tokenId[0]) == address(punkProxies[swapList[_swapCreator][swapMatch[_swapId]].addressTwo]), "CryptoPunk missing");
                punkProxies[swapList[_swapCreator][swapMatch[_swapId]].addressTwo].proxyTransferPunk(CRYPTOPUNK, swapList[_swapCreator][swapMatch[_swapId]].addressOne, nftsTwo[_swapId][i].tokenId[0]);
                punkInUse[nftsTwo[_swapId][i].tokenId[0]] = false;
            }
            else {
                customInterface(dappRelations[nftsTwo[_swapId][i].dapp]).bridgeSafeTransferFrom(nftsTwo[_swapId][i].dapp, swapList[_swapCreator][swapMatch[_swapId]].addressTwo, swapList[_swapCreator][swapMatch[_swapId]].addressOne, nftsTwo[_swapId][i].tokenId, nftsTwo[_swapId][i].blc, nftsTwo[_swapId][i].data);
            }
        }
        if(swapList[_swapCreator][swapMatch[_swapId]].valueTwo>0)
            swapList[_swapCreator][swapMatch[_swapId]].addressOne.transfer(swapList[_swapCreator][swapMatch[_swapId]].valueTwo);

        emit swapEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), swapStatus.Closed, _swapId, _swapCreator);
    }

    // Cancel Swap
    function cancelSwapIntent(uint256 _swapId) public {
        require(swapList[msg.sender][swapMatch[_swapId]].addressOne == msg.sender, "You're not the interested counterpart");
        require(swapList[msg.sender][swapMatch[_swapId]].status == swapStatus.Opened, "Swap Status is not opened");
        //Rollback
        if(swapList[msg.sender][swapMatch[_swapId]].swapFee>0)
            msg.sender.transfer(swapList[msg.sender][swapMatch[_swapId]].swapFee);
        uint256 i;
        for(i=0; i<nftsOne[_swapId].length; i++) {
            if(nftsOne[_swapId][i].typeStd == ERC20) {
                ERC20Interface(nftsOne[_swapId][i].dapp).transfer(swapList[msg.sender][swapMatch[_swapId]].addressOne, nftsOne[_swapId][i].blc[0]);
            }
            else if(nftsOne[_swapId][i].typeStd == ERC721) {
                ERC721Interface(nftsOne[_swapId][i].dapp).safeTransferFrom(address(this), swapList[msg.sender][swapMatch[_swapId]].addressOne, nftsOne[_swapId][i].tokenId[0], nftsOne[_swapId][i].data);
            }
            else if(nftsOne[_swapId][i].typeStd == ERC1155) {
                ERC1155Interface(nftsOne[_swapId][i].dapp).safeBatchTransferFrom(address(this), swapList[msg.sender][swapMatch[_swapId]].addressOne, nftsOne[_swapId][i].tokenId, nftsOne[_swapId][i].blc, nftsOne[_swapId][i].data);
            }
            else if(nftsOne[_swapId][i].typeStd == CRYPTOPUNK) { // Controllo che il CP sia presente sul proxy
                require(CPInterface(CRYPTOPUNK).punkIndexToAddress(nftsOne[_swapId][i].tokenId[0]) == address(punkProxies[msg.sender]), "CryptoPunk missing");
                punkProxies[msg.sender].proxyTransferPunk(CRYPTOPUNK, msg.sender, nftsOne[_swapId][i].tokenId[0]);
                punkInUse[nftsOne[_swapId][i].tokenId[0]] = false;
            }
            else {
                customInterface(dappRelations[nftsOne[_swapId][i].dapp]).bridgeSafeTransferFrom(nftsOne[_swapId][i].dapp, dappRelations[nftsOne[_swapId][i].dapp], swapList[msg.sender][swapMatch[_swapId]].addressOne, nftsOne[_swapId][i].tokenId, nftsOne[_swapId][i].blc, nftsOne[_swapId][i].data);
            }
        }

        if(swapList[msg.sender][swapMatch[_swapId]].valueOne > 0)
            swapList[msg.sender][swapMatch[_swapId]].addressOne.transfer(swapList[msg.sender][swapMatch[_swapId]].valueOne);

        swapList[msg.sender][swapMatch[_swapId]].swapEnd = block.timestamp;
        swapList[msg.sender][swapMatch[_swapId]].status = swapStatus.Cancelled;
        emit swapEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), swapStatus.Cancelled, _swapId, address(0));
    }

    // Set CP address
    function setCryptoPunkAddress(address _cryptoPunk) public onlyOwner {
        CRYPTOPUNK = _cryptoPunk ;
    }

    // Register the punk proxy
    function registerPunkProxy() public {
        require(address(punkProxies[msg.sender])==address(0), "Proxy already registered");
        punkProxies[msg.sender] = new PunkProxy(address(this), msg.sender);
    }

    // If the punk is not in use in a swap, I could recover it
    function claimPunkOnProxy(uint _punkId) public {
        require(punkInUse[_punkId]==false, "Punk already in use in a swap");
        punkProxies[msg.sender].recoverPunk(CRYPTOPUNK, msg.sender, _punkId);
    }

    // Set Trade Squad address
    function setTradeSquadAddress(address _tradeSquad) public onlyOwner {
        TRADESQUAD = _tradeSquad ;
    }

    // Set Vault address
    function setVaultAddress(address payable _vault) public onlyOwner {
        VAULT = _vault ;
    }

    // Handle dapp relations for the bridges
    function setDappRelation(address _dapp, address _customInterface) public onlyOwner {
        dappRelations[_dapp] = _customInterface;
    }

    // Handle the whitelist
    function setWhitelist(address _dapp, bool _status) public onlyOwner {
        whiteList[_dapp] = _status;
    }

    // Edit CounterPart Address
    function editCounterPart(uint256 _swapId, address payable _counterPart) public {
        require(msg.sender == swapList[msg.sender][swapMatch[_swapId]].addressOne, "Message sender must be the swap creator");
        swapList[msg.sender][swapMatch[_swapId]].addressTwo = _counterPart;
    }

    // Set the payment
    function setPayment(bool _status, uint256 _value) public onlyOwner whenNotPaused {
        payment.status = _status;
        payment.value = _value * (1 wei);
    }

    // Get punk proxy address
    function getPunkProxy(address _address) public view returns(address) {
        return address(punkProxies[_address]) ;
    }

    // Get whitelist status of an address
    function getWhiteList(address _address) public view returns(bool) {
        return whiteList[_address];
    }

    // Get Trade fees
    function getWeiPayValueAmount() public view returns(uint256) {
        return payment.value;
    }

    // Get swap infos
    function getSwapIntentByAddress(address _creator, uint256 _swapId) public view returns(swapIntent memory) {
        return swapList[_creator][swapMatch[_swapId]];
    }
    
    // Get swapStructLength
    function getSwapStructSize(uint256 _swapId, bool _nfts) public view returns(uint256) {
        if(_nfts)
            return nftsOne[_swapId].length ;
        else
            return nftsTwo[_swapId].length ;
    }

    // Get swapStruct
    function getSwapStruct(uint256 _swapId, bool _nfts, uint256 _index) public view returns(swapStruct memory) {
        if(_nfts)
            return nftsOne[_swapId][_index] ;
        else
            return nftsTwo[_swapId][_index] ;
    }

    //Interface IERC721/IERC1155
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata id, uint256[] calldata value, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
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

