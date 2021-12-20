// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./SignedMinting.sol";

interface NftContract {
    function mint(address) external;
    function balanceOf(address) external view returns (uint256);
}

contract BarnyardFashionistasStore is ReentrancyGuard, Ownable {
//contract BarnyardFashionistasStore is EIP712, SignedMinting, Ownable {
    NftContract public bfNft =
        NftContract(0xBAB7dF6D042F4b83b62070b670Da929b62eD22d8);
    
    address private constant core1Address =
        0x3002E0E7Db1FB99072516033b8dc2BE9897178bA;
    uint256 private constant core1Shares = 84650;

    address private constant core2Address =
        0x452d40db156034223e8865F93d6a532aE62c4A99; 
    uint256 private constant core2Shares = 5000;

    address private constant core3Address =
        0xEbCEe6204eeEEf21e406C0A75734E70f342914e0; 
    uint256 private constant core3Shares = 5000;

    address private constant core4Address =
        0xCa93378a4d2c9217A1f6C2D9aB50B791a4043A87; 
    uint256 private constant core4Shares = 3000;

    address private constant core5Address =
        0xa808208Bb50e2395c63ce3fd41990d2E009E3053; 
    uint256 private constant core5Shares = 750;

    address private constant core6Address =
        0x1996FabEC51878e3Ff99cd07c6CaC9Ac668A22fD; 
    uint256 private constant core6Shares = 600;

    address private constant core7Address =
        0x30734A0adeCa7e07c3C960587d6502fC5EA0f8df; 
    uint256 private constant core7Shares = 500;
    
    address private constant core8Address =
        0x74E101B1E67Cd303A3ec896421ceCf894891ac25; 
    uint256 private constant core8Shares = 500;

    

    uint256 private constant baseMod = 100000;

    /**
        Numbers for Barnyard Fashionistas NftContract
     */
    // uint256 public constant maxFashionistas = 9999;
    uint256 public maxFashionistas = 9999;

    //whitelist and mints
    mapping(address => uint256) private whitelist;
    mapping(address => uint256) private oglist;
    mapping(address => uint256) public mintedFashionistasOf;

    /**
        Team allocated Fashionistas
     */
    // Fashionistas which is minted by the owner
    uint256 public preMintedFashionistas = 0;
    // MAX Fashionistas which owner can mint
    uint256 public constant maxPreMintFashionistas = 300;


    //    Mint counts during presale
    uint256 public newlyMintedFashionistasPresale = 0;
    
    //Tracking Sales After Presale
    uint256 public mintedFashionistasAfterPresale = 0;

    uint256 public mintedFashionistasBonus = 0;
    uint256 public mintedOgClaim = 0;

    /**
        Pricing & sales
     */
    uint256 public price = 0.044 ether;
    uint256 public maxMintPerTx = 6;

    uint256 public whitelistMints = 4;

    uint256 public maxMintBonusTx = 2;
    uint256 public bonusMintsTotal = 500;
    uint256 public bonusMintsPresale = 200;

    
    //    Security

  


    uint256 public mintedFashionistas = 0;


    event SetFashionistasNftContract(address bfNft);

    event MintWithWhitelist(address account, uint256 amount, uint256 changes);
    event SetRemainingFashionistas(uint256 remainingFashionistas);

    event mintFashionistas(address account, uint256 amount);
    event Withdraw(address to);


    bool public presaleOn = false;
    bool public mainSaleOn = false;
    bool public bonusSaleOn = false;

    // constructor(
    //     address signer
    // ) 
    // SignedMinting(signer)
    // ReentrancyGuard() 
    // {
    // }

    constructor(
        address signer
    ) 
    ReentrancyGuard() 
    {
    }

    modifier mainSaleOpened() {
        require( mainSaleOn, "Store is not opened" );

        _;
    }

    modifier presaleOpened() {
        require(presaleOn, "Store is not opened for Presale");

        _;
    }

    modifier bonussaleOpened() {
        require(bonusSaleOn, "Store is not opened for Presale");

        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            core1Address == msg.sender || core2Address == msg.sender || core4Address == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function togglePresale() external onlyOwner {
        presaleOn = !presaleOn;
    }

    function toggleMainSale() external onlyOwner {
        mainSaleOn = !mainSaleOn;
    }
    
    function toggleBonusSale() external onlyOwner {
        bonusSaleOn = !bonusSaleOn;
    }
    // function presaleBalance() public view returns(uint256) {
    //     return whitelist[msg.sender];
    // }

    // function setMintingSigner(address _signer)
    //     public
    //     onlyOwner
    // {
    //     _setMintingSigner(_signer);
    // }


    function setFashionistasNftContract(NftContract _bfNft) external onlyOwner {
        bfNft = _bfNft;
        emit SetFashionistasNftContract(address(_bfNft));
    }


    // Do not update newlyMintedFashionistas to prevent withdrawal
    // This needs to become the owner Free mint function. Ditch the time restrictions?
    function preMintFashionistas(address[] memory recipients) external onlyOwner {

        uint256 totalRecipients = recipients.length;

        require(
            totalRecipients > 0,
            "Number of recipients must be greater than 0"
        );
        require(
            preMintedFashionistas + totalRecipients <= maxPreMintFashionistas,
            "Exceeds max pre-mint Fashionistas"
        );

        require(
            mintedFashionistas + totalRecipients < maxFashionistas,
            "Exceeds max Fashionistas"
        );

        for (uint256 i = 0; i < totalRecipients; i++) {
            address to = recipients[i];
            require(to != address(0), "receiver can not be empty address");
            bfNft.mint(to);
        }

        preMintedFashionistas += totalRecipients;
        mintedFashionistas += totalRecipients;
    }




    // adds to whitelist with specified amounts
    function addToOGlistAmounts(address[] memory _listToAdd, uint256[] memory _amountPerAddress) public onlyOwner {
        uint256 totalAddresses = _listToAdd.length;
        uint256 totalAmounts = _amountPerAddress.length;

        require(totalAddresses == totalAmounts, "Item amounts differ");

        for (uint256 i = 0; i < totalAddresses; i++) {
          oglist[_listToAdd[i]] = _amountPerAddress[i];
        }
    }


    function ogClaim() public payable presaleOpened
        nonReentrant
    {
        
        uint256 _count = oglist[msg.sender];
        require(mintedFashionistas + _count <= maxFashionistas, "Max limit");

        uint256 _balance = bfNft.balanceOf(msg.sender);
        
        if ( _balance < _count){
            _count = _balance;
        }

        for (uint256 i = 0; i < _count; i++) {
          bfNft.mint(msg.sender);
        }

        mintedOgClaim += _count;
        mintedFashionistas += _count;

        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }


    // adds to claim list with specified amounts
    function addToWhitelist(address[] memory _listToAdd) public onlyOwner {
        uint256 totalAddresses = _listToAdd.length;
    
        for (uint256 i = 0; i < totalAddresses; i++) {
          whitelist[_listToAdd[i]] = whitelistMints;
        }
    }


    function mintPresale( uint256 _count) public payable presaleOpened
        nonReentrant
    {
        require(_count <= whitelist[msg.sender], "Over Max whitelist"  );
        
        require(mintedFashionistas + _count <= maxFashionistas, "Max limit");
        require(msg.value >= (_count * price ), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
          bfNft.mint(msg.sender);
        }

        newlyMintedFashionistasPresale += _count;
        mintedFashionistas += _count;

        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }

    
    // function mintPresale(bytes memory signature, uint256 _count) public payable presaleOpened
    //     nonReentrant
    //     isValidSignature(signature)
    // {
    //     require(_count + mintedFashionistasOf[msg.sender] <= whitelistMints, "Over Max whitelist"  );
        
    //     require(mintedFashionistas + _count <= maxFashionistas, "Max limit");
    //     require(msg.value >= (_count * price ), "Value below price");

    //     for (uint256 i = 0; i < _count; i++) {
    //       bfNft.mint(msg.sender);
    //     }

    //     newlyMintedFashionistasPresale += _count;
    //     mintedFashionistas += _count;

    //     mintedFashionistasOf[msg.sender] = mintedFashionistasOf[msg.sender] - _count;
    // }



    // //Presale function - remove pass, add whitelist functions from pass
    // function mintWithWhitelist(
    //     uint256 _amount,
    //     uint256 _whitelistAmount,
    //     uint8 vSig,
    //     bytes32 rSig,
    //     bytes32 sSig
    // ) external payable presaleOpened{
        
    //     uint256 walletMintedFashionistas = mintedFashionistasOf[msg.sender];

    //     require(walletMintedFashionistas < _whitelistAmount, "Used All Presales");

    //     require( (walletMintedFashionistas + _amount - 1) < _whitelistAmount, "try less" );

    //     require(mintedFashionistas + _amount < maxFashionistas, "exceeds max mint");

    //     uint256 totalPrice = price * _amount;
    //     require(totalPrice <= msg.value, "Not enough money");

    //     bytes32 digest = _hashTypedDataV4(
    //         keccak256(abi.encode(TYPEHASH, msg.sender, _whitelistAmount))
    //     );

    //     address signer = ecrecover(digest, vSig, rSig, sSig);
    //     require(signer == owner(), "Signature is not from the owner");


    //     for (uint256 i = 0; i < _amount; i += 1) {
    //         bfNft.mint(msg.sender);
    //     }

    //     mintedFashionistasOf[msg.sender] = walletMintedFashionistas + _amount;

    //     newlyMintedFashionistasPresale += _amount;
    //     mintedFashionistas += _amount;

    //     // Do I really need the following function? Would this spike more gas than it's worth for a fractional amount?

    //     uint256 changes = msg.value - totalPrice;       
    //     emit MintWithWhitelist(msg.sender, _amount, changes);

    //     if (changes > 0) {
    //         payable(msg.sender).transfer(changes);
    //     }
    // }



    // function mintPresale(bytes memory signature, uint256 _count) public payable presaleOpened
    //     nonReentrant
    //     isValidSignature(signature)
    // {
    //     require(_count <= whitelist[msg.sender]);
        
    //     require(mintedFashionistas + _count <= maxFashionistas, "Max limit");
    //     require(msg.value >= (_count * price ), "Value below price");

    //     for (uint256 i = 0; i < _count; i++) {
    //       bfNft.mint(msg.sender);
    //     }

    //     newlyMintedFashionistasPresale += _count;
    //     mintedFashionistas += _count;

    //     whitelist[msg.sender] = whitelist[msg.sender] - _count;
    // }


    function bonusMint( uint256 _count) public payable bonussaleOpened
        nonReentrant
    {
        require(presaleOn || mainSaleOn, "a sale must be on");
        require(_count <= maxMintBonusTx, "Over MaxTx bonus"  );
        require(mintedFashionistasBonus + _count < bonusMintsTotal, "less bonus remaining");
                        
        if (presaleOn) {
            require(mintedFashionistasBonus <= bonusMintsPresale, "bonus presale done");

            uint256 fashionistaAmount = bfNft.balanceOf(msg.sender);
            require(fashionistaAmount > 0, "Fashionista Required");    
        }

        require(mintedFashionistas + _count <= maxFashionistas, "Max limit");
        
 
        for (uint256 i = 0; i < _count; i++) {
          bfNft.mint(msg.sender);
        }

        mintedFashionistasBonus += _count;
        mintedFashionistas += _count;

    }



    // MAIN MINTING FUNCTION

    function mintMainSale(uint256 _amount) external payable mainSaleOpened {
   
        require(mintedFashionistas + _amount -1 < maxFashionistas, "exceeds max mint");

        uint256 totalPrice = price * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        require(_amount - 1 < maxMintPerTx, "exceed max transaction");

        for (uint256 i = 0; i < _amount; i += 1) {
            bfNft.mint(msg.sender);
        }

        mintedFashionistasAfterPresale += _amount;
        mintedFashionistas += _amount;

        emit mintFashionistas(msg.sender, _amount);
    }



    function withdrawCore() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _splitAll(balance);
    }

    //  **** ASK HOW MANY CAN DO SAFE
    function _splitAll(uint256 _amount) private {
        uint256 singleShare = _amount / baseMod;
        _withdraw(core1Address, singleShare * core1Shares);
        _withdraw(core2Address, singleShare * core2Shares);
        _withdraw(core3Address, singleShare * core3Shares);
        _withdraw(core4Address, singleShare * core4Shares);
        _withdraw(core5Address, singleShare * core5Shares);
        _withdraw(core6Address, singleShare * core6Shares);
        _withdraw(core7Address, singleShare * core7Shares);
        _withdraw(core8Address, singleShare * core8Shares);
    }

    function withdrawBU() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(core1Address, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//🎩🐭 fancyrats.eth

contract SignedMinting {
    using ECDSA for bytes32;
    using Address for address;

    address public signer;

    constructor(address _signer) {
        signer = _signer;
    }

    function _setMintingSigner(address _signer) internal {
        signer = _signer;
    }

    // Assumes the signed message was human-readable msg.sender address (lowercase, without the '0x')
    function validateSignature(bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 messageHash = toEthSignedMessageHash(asciiSender());
        address _signer = messageHash.recover(signature);
        return signer == _signer;
    }

    modifier isValidSignature(bytes memory signature) {
        require(validateSignature(signature), "Invalid whitelist signature");
        _;
    }

    function recoveredAddress(bytes memory signature)
        public
        view
        returns (bytes memory)
    {
        address recoveredSigner = recover(signature);
        return abi.encodePacked(recoveredSigner);
    }

    function recover(bytes memory signature) public view returns (address) {
        bytes32 messageHash = toEthSignedMessageHash(asciiSender());
        address recoveredSigner = messageHash.recover(signature);
        return recoveredSigner;
    }

    function generateSenderHash() public view returns (bytes32) {
        return toEthSignedMessageHash(asciiSender());
    }

    // Because at time of writing, 5b28259dacf47fc208e03611eb3ba8eeaed63cc0 hasn't made it into
    // OpenZepplin ECDSA release yet.
    // https://github.com/OpenZeppelin/openzeppelin-contracts/commit/5b28259dacf47fc208e03611eb3ba8eeaed63cc0#diff-ff09871806bcccfd38e43de481f3e7e2fb92134c58e1a1f97b054e2d0d727458R209
    function toEthSignedMessageHash(string memory s)
        public
        pure
        returns (bytes32)
    {
        bytes memory b = bytes(s);
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(b.length),
                    b
                )
            );
    }

    function asciiSender() public view returns (string memory) {
        return toAsciiString(msg.sender);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}