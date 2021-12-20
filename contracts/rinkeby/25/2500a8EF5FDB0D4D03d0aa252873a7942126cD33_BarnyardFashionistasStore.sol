// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//import "./SignedMinting.sol";

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