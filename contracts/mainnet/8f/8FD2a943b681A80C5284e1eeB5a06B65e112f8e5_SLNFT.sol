// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract SLNFT is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    uint8 private _preMintSupply = 100;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    uint256 _mintFee = 50000000000000000;
    
    bool _saleActive = false;
    uint16 _maxSupply = 8888;

    uint8 _maxMintQuantity = 20;
    string _baseTokenURI = "https://api.sealifenft.co/meta/";
    
    uint8 _maxWhitelistQuantity = 10;
    
    struct Whitelist {
        bool isWhitelisted;
        uint8 mintCount;
    }

    mapping(address => Whitelist) public _whitelist;

    constructor() ERC721("SeaLife", "SEA") {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        _initializeEIP712("SeaLife");
        
        _preMint();
        
        _addWhiteList();
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    /**
     * @dev Returns max supply 
    */
    function getMaxSupply() public view returns (uint16) {
        return _maxSupply;
    }
    
    /**
     * @dev Returns if pre sale is active
    */
    function saleActive() public view returns (bool) {
        return _saleActive;
    }
    
    /**
     * @dev Returns pre sale max supply 
    */
    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }
    
    /**
     * @dev Adds new addresses to whitelist
     * @param addresses address array 
    */
    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add NULL_ADDRESS to whitelist");
            _whitelist[addresses[i]].isWhitelisted = true;
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, uint8 quantity) public payable {
        require(_saleActive || _whitelist[_to].isWhitelisted, "Sale is not active and address is not whitelisted!");
        require(quantity > 0 && quantity <= _maxMintQuantity, "Quantity exceeds mint quantity range!");
        
        uint256 newTokenId = _currentTokenId.add(quantity);
        
        require(newTokenId <= _maxSupply , "No tokens left");   
        require(msg.value >= (_mintFee.mul(quantity)) , "Minting price does not match");
        
        if(!_saleActive && _whitelist[_to].isWhitelisted) {
            require(_whitelist[_to].mintCount + quantity <= _maxWhitelistQuantity, "Minting would exceed whitelist spots");
        }
        
        for(uint8 i = 0; i < quantity; i++) {
            uint256 _mTokenID = _currentTokenId.add(1);
            _mint(_to, _mTokenID);
            _incrementTokenId();
            
            if(!_saleActive && _whitelist[_to].isWhitelisted) {
                _whitelist[_to].mintCount += 1;
            }
        }
        
        // Turns off sale since there is no token left
        if(_saleActive && _currentTokenId >= _maxSupply) {
            _saleActive = false;
        }
    }
    
    /**
     * @dev Premint <_preMintSupply> items for creator of contract 
    */
    function _preMint() private {
        for(uint8 i = 0; i < _preMintSupply; i++) {
            _mint(owner(), i);
            _incrementTokenId();   
        }
    }
    
    /**
     * @dev Returns mint fee  
    */
    function getMintFee() public view returns (uint256) {
        return _mintFee;
    }

    /**
     * @dev returns the current balance of the contract 
     */
    function balance() public view returns (uint256 _balance) {
        return address(this).balance;
    }
    
    /**
     * @dev Withdrawing Funds to Safe Address
     */
    function withdrawFunds(uint256 _amount) public onlyOwner {
        require(balance() >= _amount, "Not enough funds");
        
        address _safe = 0x1E964cEa87daC948AEC45c8649373163D0ae7260;
        
        (bool sent, ) = _safe.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    // base token uri for items
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Sets new Base Token URI
    */
    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Token URI
    */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal override view returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    function _addWhiteList() internal {
        address[235] memory _wlm = [
            0xB899e6E767495083F284582fc6882c2cED70a9E1,
            0xDA33ce2c8a50182d765230Aba7b7Fb3Fe5c0a684,
            0x2D84F8284C95398eff78e955Cf62dfb625681130,
            0x2A4B5Eb94Eec572C3E72f27087948ab05E2FA449,
            0xbAaBA861464F25f52c2eE10CC3AC024F4f77812a,
            0xb859d35631499dc8866C78459b0Fc72b7b5a023d,
            0x14e931667D12E37d027282Be122501E969512AA1,
            0x2206D4C30eB525Fd73c4303Db9aD92ba9151A798,
            0xeAA86BFA21d57DD2002565Bda2D6545605622d0C,
            0xC900BEdBeaFf5cF46461EEd0E4c25f33F5B88F45,
            0xBa43Dd090Eb4E6A15024956a14a88ad042A8E6D7,
            0x9Bb0e2D407137dce82A392ad5F570b55f4C023DC,
            0x84FEFD862D9Ed591A7c94F7C36f2c093DFAB565D,
            0xe2eCdF7bbf1f2e19389C75E38A708872D3790128,
            0x0970Ed73b176061124cc1E7f89f8E3CfD5A897F5,
            0xacA277Ba3E3CDF71dadA765e4DA9004E090f17Cf,
            0x620F28e81cCD57A4Cb71502bc9f04Afb00bd8c0d,
            0xFb47779fb0f59750fC714ba61a7859b059Bbd3e6,
            0xDe39B1eFB764eD50398492C6cEe3edeE772B4e31,
            0x4B8052d0eef390b80471a73f16D89eec10725a96,
            0xbC0Ad94C822bb179870cebD659858917d4463C89,
            0x3515C838Bf0e33fA99071Dde575E4Cf4F07adBe4,
            0xdE8fFFC35939eEDa2e1F453Ae7A2D8Ef716B4e20,
            0x932e1a187AaB69aE2f786F2877Be32d73D6CF31a,
            0xD61d13EfeAC71A3f6B99367dC6db4f2d10877810,
            0x26D9a47dBFcB856CD8275a192d2421e57b7b1085,
            0xa4983DB206988D1956e3DC3c9e184eF195009420,
            0x040958C5d47f3a562752c33D07EFC4167fB34475,
            0xD709330228365E80B8DFA90493b93CFf55bd0d71,
            0xDB5AD072c7Cb16863E843cd4cDAE2d52dF56B598,
            0xF6bBE989CD2357BaE7f18386399183034ab4ef48,
            0xbab64597e8d0eB511a356B56b8dc46C7b01097c5,
            0xBce60532fff5152e4be1567fCaE6f3D39AcB9e1B,
            0xd85b209776288e3D273b5edDc9E987416aCF5512,
            0x2124DE7fBa5efAdd2755341907cb1A3dF7c8D2D2,
            0x71084004F1D64B41A7cebc59c3aDe55BA9A0a3D9,
            0xb5265Dfd2f2462B85494b13a5FE6f0D1E8B734bc,
            0xE82c20f6911eF8A0Af094b2996A1C38F13D8A3A8,
            0xAe5Ed074a5727Ae41738C0482eD68719ad0baCe4,
            0x4aA9fcBD7A614Ef41c5BD71261B12540f350D332,
            0x724DaEbd22c0D403De40aa5ee6cD2e0E2d11Afb2,
            0x564118c9Ffa803841EE380d4BDfa2c0B76EdbC09,
            0x4fA4edB084CA15066d28AC21dA9461894EBE5603,
            0xEAA1119471C46209914b25Af0d1922E9543200D9,
            0x760FBDAdBC9715c6E746C98B79fa19EaD3B22A5f,
            0x5A548e4bbdaAcFe71AeA3E35C1D7F36568CB66eC,
            0xAe571C3BafF94f61d9a04b22cd728192cC16e0dF,
            0x45eE4e20A575499469C1a112A54099B28f4ad4d3,
            0x0F0981D4fe661839D69321D6Dbb8801bA4bcb348,
            0x4CB35Baaa6FE5dec74BfB02A82c653B60aa8042E,
            0xBCec43BBC3C9A4Cc2A133E92e8b200e0e92C221b,
            0xf1807602067392C095Ac189413491077361696be,
            0x65F70E9bD56F811ff7c0023aaEe90C5F751B1951,
            0xafd51AdE31AC30e3D68FEFFE12677ee63Cfb051B,
            0x8646A463DB4CAf0521189de2cACCaFce2Af99c50,
            0x3a9D877639E20Bf080d5dA6c149708dEe35fCFCb,
            0x56da86a2861606d2261875A2E03BC4B7B61F0abB,
            0x499E6fFafbBA5b876Fb0278A5c9CB09F1eeAF4EF,
            0x2A5e7ECC5Bd1e7cC5477977a22509eBCeC60De46,
            0xF956213f6adc751123944597191596D8af6822Da,
            0x7Be15abD41E108cC3adDd1203fBff72d56596FCD,
            0x56fF22798ab380616380eb5af6D055aC91f4b114,
            0xaF47Aa4bdCb30E84b3A3c756b234DDbE9Ee94147,
            0xf622Bc5Cd66d4162aF9892B929E8F932423c6116,
            0x5565535d89c28ed18c97E0243D403C818BEA8923,
            0x0955965Fda40D9e7c09CD3a2a5ae5fb0C9a8c1c3,
            0x3fcf7AE03C609bcdF7f1118940CbD13709a62527,
            0xB9a0a15736f8e9A758aBE5b6c0AD98F146763Cf1,
            0xc47264b0BBAe9380261633fF769F1455b4A3012E,
            0x49b753c09cb64dbDC53841AB13a04A038d4c9D20,
            0x52755642f947D3A7F36e66741B5EbF9039707393,
            0xdaF016e677821000D3C0798c5251715094B27704,
            0xb6cE0cADbF1c49E50DCF5cCC992b623b47A3814D,
            0x7e23DE388Eca3c0F6B89647442feaFA34714bD02,
            0x4D7AF06c4268bC8028b0603bc7561786f6346D59,
            0xA01C0735C7cA5f8efc1e63efa5F2D1C4fc1a4714,
            0xC02f8963aF9B45987A8a2A72443A9d9f845FF00d,
            0x24245e6c515187aB9b103BD278dAd0d5A08EdBaA,
            0x612eFb383672360bF76245ead6B17947bf7C4BEE,
            0x72CFfe3Aea6Ffa7C9e4E064e7F7859fbf8A468a9,
            0x28450d59EBb1ca046cAdCf097665aEa107903386,
            0xB164FE86156D029206A2a086efcd10eeaE3Da3CB,
            0x8Bf2a83F41a1A0334c25C9d5935E29bde982e4C9,
            0x4331f677496d1df8f55eacb38fcDE0276a1969eB,
            0x221Fa4183BdCC644a7B7Dfff87Ad0a1b66e5A410,
            0x19b7011415F65CE1F3f85E622D9791EcBEdf232f,
            0xeaa311D6F48EDb89dE070a60f157175D9afa6231,
            0xfD2204757Ab46355e60251386F823960AcCcEfe7,
            0x8788bE8B57f795C69b87138e29AF26400382833e,
            0x9C876254CBDa0F6CEdd553C40a2783d3fd9e5Db8,
            0x7EF29C8565f6f5C2B748fBA2d04cb127643551cd,
            0xe8f24f829fDCbAdcFe29b5C9fD5943F6e13e8e61,
            0x50EB1186023ab9d087e9a70935cB83f47a8DF492,
            0x746a3A6760f5e9442c748e6E811a2497dba52FAA,
            0xbEfADb182983789ffa50a901C9B7744B3C1E41Ad,
            0xf12229dfd4EcF132b33bdd12627EE66B81d4A126,
            0xAaf09630481D9fC358678d005eEd2dB6D27297e3,
            0xDdF47b9bB38e46873A5c7c75dF1ac6FFf6e0482a,
            0x2E196Fbc672d16fd489d8A3af37fe145d25E8b38,
            0x9f80DD812DB3695579994A987992C06312653150,
            0x8F6D42A451ce83dda302FE8B1709D96914413BB4,
            0x197754FCD35BeA3aa7D7242C684CbB397aBe35f5,
            0x1958697d54BC30D44b71B56E4c2E370dfeeea2ad,
            0xF777Cf5352A23D96f8742B57ce76701eBcd07005,
            0xf8F104a1FF0368957e062657F2bef112d8c7766C,
            0x1205F1D33610E5d09f4331ccae453D2A894e456A,
            0xf8E04f21CC9d5E6ADB83818214979aa0bf1561ca,
            0x8226180509B1dAC4F144D9BeFc43E1f979bcC032,
            0x7D741Bb3FEEfB0E0FBF89252D23d9A7571bd8b0D,
            0x538d15e97f76A870C233cBC48D4B6A6Ace134eF4,
            0x301B95c4E054DEA03a2D06c40270771A80908cd0,
            0x26ADcf5EB1FB4f87202Ac772c009f02D51c89e1b,
            0xd6508728221F6F4CaA8b2e097807A33118D36A2c,
            0x58d5b48Bdc6270F9eD3DBCe945960d390ea281eE,
            0xf3233b7712311365c02Ffd3881C61D69B169c49E,
            0x730Aba725664974eFB753ee72cA789541C733Db4,
            0xd3022599033430bF3fDFb6D9CE41D3CdA7E20245,
            0xE6086edc254335C00FC9129ED704EF936eB2D2B9,
            0xE3D9559f230d46d27844A71B367231b77511BdC4,
            0xE441Ec5004d8FE8bE2a7857E7465e5bbF0a30017,
            0x5fA60264f86003024943acec0d59C9cBaEfCf91d,
            0xc323A1FE663c0CFCe8616b07e6f72975A27a3296,
            0x34d8e6D688d43Ab5146c9A8d40f3d98Db1E2a51c,
            0x2EEf40759463Bb1c380915DEcc6580fB63dA9550,
            0xE6b514032b348130eDa9692AbD4edf7ED63c647c,
            0x38415D8e5946f941D01f9841cFb4572afEFA7658,
            0x134D90298135424ff54e0e6b71367E07f617296f,
            0xE7f64062e0638D3dc20a189d165B10d2f0CEE1C0,
            0x0C7C0A3E1EB781e270967f31D8FCf92D50a4F6f7,
            0x19dc9Ed3B7597740a6d1CA8B1F14326d9AD0BEFF,
            0xc1B8EcD7f78C7F2a5D14A879Be01d4bAe7a25Ccd,
            0x64bd7247207989Ca10d950555F6d24Defaf8291e,
            0x6524A4de1C6fA52F68D9Be4445646fDe8FDeCe2C,
            0xdB3872395cC6d82F9977B780ebB7C405FBa5cB5B,
            0x0c567689C3A54299743EfFDfE6E3673765577503,
            0x8DcC3e57B5254DE0765a8363023DCB3E167790d3,
            0x5804aF503c29B2373B84fEa821ccC60D7B46283a,
            0x253D8b18C1063198129dB62EF039D584B07CE1Db,
            0x1A01a24Ef3a6EAcf1adb4F371D9Ee090874CfE78,
            0x49340727aab3F748ddfe09CB8dee48470964f1f4,
            0x06E294cF22Dda0Bbea6213aFdB6D95c87E7631B8,
            0x19C644c1FE2a56057a8d6ca2710192F317e2be6f,
            0x788Cf49Ee89acC8c632a251d6ce8CC2baA966256,
            0x999BAf549d6807B2C713ca112d81a0818Eb09b80,
            0xBF4B7c584b7608a934d54CC9F847F479cf790F76,
            0xa9fE96D8A071856d096aE270720790A51c1a727C,
            0x635f3558A9ad3e8fd24715879C9C7D0664ae4781,
            0x70250577717a5E48661D12F29F1Bc3d9806D199c,
            0xaAF1515D684CBae66A746C1e4A25debCe1ded5a5,
            0xc68BeC073F9Ce13441346c54f102741423db8B15,
            0x29B6a810900C412D95F9511b5FdCE298CeD06064,
            0x7B2478e552F279A0264e0eB07faf3F2E501da9EF,
            0x60955A5497ba0FC4C335f4672C75375509871446,
            0xf27b83Be8672cb3b6b4095f73c724F2B88ED7208,
            0xF6b3b4f71c961514bDD55136d3EF9A8ed651CE67,
            0x74e8D326d609f5632Cec23BD68434CDc125DCEE4,
            0x408cB4F97893F45ad90887C002837B1ad2eC0A17,
            0x8E6e79A35f84A142694dF570C69b059f939B6337,
            0xeB2533f33050f49069bfBCe4E25f0040061d5860,
            0x299A0d1AA150ff00eC98bc6fD163d84f914ff147,
            0x8f1d43463571CB7386428E191D774dD9183A4901,
            0x460E3910d21d4137855aFa8c3706f88B356B01Ea,
            0x882Eb53C4531f2E9B904e266e253A1FCB85F78aD,
            0x9304201A8456285F15042ad7D93AD07684ade166,
            0x76dABB965845A1bd97D8F67E0428C027251Ae47C,
            0xeF377Af6C38c99bA903d6642B4f8e62e6630d4dC,
            0x9DfBF1524551c1799048E186205a446D055d581e,
            0x9B7D3Dcb12F7d22A47B45C26DC7a7530c766E8f4,
            0xF2CC21c364f41B5e9f3B1D29168E434D526315A6,
            0x6f87669BC6D3EA5D80e2178d23175B5b4A4CA90E,
            0x219da042CB2b48AebbEA234BE4Eb8C33cbd93963,
            0x72742c5E4477e94FfAA796AFd948bEb27bA278B9,
            0xdFeE0AdC69E38a95316796AbbEfBB8EaD6b091Bb,
            0xFda286692836C439DE9f9dbA796884fd9bbA70e4,
            0x1cEb2002d290A56883680aCBBb7c0457D7c88220,
            0x4d250Bc3693a5CF0096F645d0BA1bc13bd856524,
            0x3Cf1a91427C12F2bCe8C806368622E3fAB1F222d,
            0x8409c747cDf528038D8fb6c412398B1f4541f403,
            0x6A68DE599E8E0b1856E322CE5Bd11c5C3C79712B,
            0x89fD7847a53f63Cf6bB3E48B5838A6dFa395064a,
            0xDc6e6881424d7Fbbe5Ce7B46268D93Bec7a7A8bC,
            0x09D550Fb253b4c472A21a24FcB60503bEaCacbA6,
            0x007FA299AF920d7c514F98397169c260A7d91811,
            0x25885D7Ebb7027ff6A8f1f285312e4109AeD624e,
            0x2958ED0660042DaE3762333938cd3Eb309aC7c8D,
            0x256AeeeeA38E34dbd59Ea8B57F48D18ca114e251,
            0xF9e6999106E5C419FC0Fd5d39A9206A43E09d283,
            0x4ff73a15C6126AAce471BD06e104278Cb235d755,
            0xF9dDe76D0284Ea34bE86Da81399B4aAdD573050a,
            0xbAE3f0987476122e08E796f2f4DB605E4d4C2112,
            0xccDa40680efe5D5A9F71c4985722dEb302dEdE61,
            0x611B0a31C97771564BC13a4183835B83A153a30f,
            0x782B0B63058ec5ef60C9821f4761713CD40807Ce,
            0x3a323B6De48389940a4DD83bd628d29E23F2fb0C,
            0xDD4CB7B3f69907FbCBB57c43b81Fbe9067Ee4F97,
            0x22801922544feFc518e1c80FBA92f633fE58161b,
            0xE1ad3F9626Fb9d6322827d374CA1daF6CDAb22E4,
            0xbECfDD036B9d62F39a465fB73141C71bd23B2267,
            0x0494Da4bEf7FDA87C6A95d8295dd0E44C5e585a8,
            0x7D9D8f7BbEd86bF5b9CB58F63F0E88D943Bf9B63,
            0x2846C4f34531219e81F14AB6baD3729A815CC87A,
            0x7AAfCe74A2f61b9469366E8155Be965A316369B7,
            0x1cb68E1954bC56ab41E36A7140758cA13c23E0E8,
            0xe574a394e6BB6543e7726A7925f12bec531bdc7D,
            0xbA4F1acB8de6fB4038721c249C04B08fEeD3B258,
            0x6c3C3d41d0FAb727359a431D20d8bCa476D4F471,
            0x4BF853Ecb530Cc19c30E2D3ffEa80d6b42BCC7dF,
            0xf00C9CAe156084EF119ABb5822fc5f86f79d184e,
            0x52af399c2EF20fb356bf5ccb485DE63a5841eB3D,
            0x4291156c56f09d7E30B33CEA68BF745dFd475C24,
            0xF9cEeaf31368B870aD5762204E3D0937FB2257b8,
            0x857CA38B420a0deb9Bc0B9f898ddaf23699CcA13,
            0x24E0eAFC7c37f2d3E39A8aD0003b21C12E4A147E,
            0x1CFEEE9b366E103b89Fd082530aAE7Cbb1Ca725B,
            0x767Ad0ac0AEf89228eEA924A021D3f10A6efB62C,
            0xe14d8853cC2095F26CF0b517FBE7160B301d0dfA,
            0x0D49fA9014C0348D2d75dfdB0239Cf326afbFF38,
            0xE5bB7fba79489F61bBDae7e993579036f6f6e028,
            0x85026596042Cf8CAB1b521bCca86C56cf2D2ecAe,
            0x36FD4E29c9EB074091644b5850c4d268580F4913,
            0xE181348F432925161eabE888b459Bb4b95Fee63F,
            0x5b9bD76a56D14f276c1E56A01861283D12f77fB7,
            0x750E5D50C1429B8d4A345de9F8c1b0E6C6e3c607,
            0xCA40fFd5a6c934dE10a934e82e86afb0B0E4c063,
            0xb260352A845fbb74dE5AEe5B61C978a999138549,
            0x8e8E0997f94A9182FfC883034354FBc40B06F2A5,
            0x5bC5844F2E425E71890eFa281845Ae65E48Eb2A2,
            0xD62cE14c85aA994a11F9F42Bf5496D6075C7B5C2,
            0x7beba9B9C5735ffddadadD0BA468057a9617E57B,
            0xc3C822eCd5de2FDe0Cb1b7dA388B8108eF2f50A3,
            0xcF72F83783131bb37830201935e23CB9fAD2Db54,
            0xBae9Eb001eff1bE41e31B9318a257a855757cd55,
            0x9b1acD4336EBF7656f49224d14A892566fd48e68,
            0x1bA26aC478A131F2E339A7e203aBD97D2878fF19,
            0xAe226178c8A7E703A49144cf36B657F8046f4bB2
        ];
        
        for (uint i = 0; i < _wlm.length; i++) {
            require(_wlm[i] != address(0), "Can't add NULL_ADDRESS to whitelist");
            _whitelist[_wlm[i]].isWhitelisted = true;
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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