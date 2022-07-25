pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import "../interfaces/IERC721Template.sol";
import "../interfaces/IERC20Template.sol";
import "../interfaces/IFactoryRouter.sol";
import "../interfaces/IFixedRateExchange.sol";
import "../interfaces/IDispenser.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/ERC20Roles.sol";

/**
 * @title DatatokenTemplate
 *
 * @dev ERC20TemplateEnterprise is an ERC20 compliant token template
 *      Used by the factory contract as a bytecode reference to
 *      deploy new Datatokens.
 * IMPORTANT CHANGES:
 *  - buyFromFreAndOrder function:  one call to buy a DT from the minting capable FRE, startOrder and burn the DT
 *  - buyFromDispenserAndOrder function:  one call to fetch a DT from the Dispenser, startOrder and burn the DT
 *  - creation of pools is not allowed
 */
contract ERC20TemplateEnterprise is
    ERC20("test", "testSymbol"),
    ERC20Roles,
    ERC20Burnable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string private _name;
    string private _symbol;
    uint256 private _cap;
    uint8 private constant _decimals = 18;
    bool private initialized = false;
    address private _erc721Address;
    address private paymentCollector;
    address private publishMarketFeeAddress;
    address private publishMarketFeeToken;
    uint256 private publishMarketFeeAmount;
    
    uint256 public constant BASE = 1e18;
    

    // EIP 2612 SUPPORT
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;
    address public router;
    
    struct fixedRate{
        address contractAddress;
        bytes32 id;
    }
    fixedRate[] fixedRateExchanges;
    address[] dispensers;

    struct providerFee{
        address providerFeeAddress;
        address providerFeeToken; // address of the token 
        uint256 providerFeeAmount; // amount to be transfered to provider
        uint8 v; // v of provider signed message
        bytes32 r; // r of provider signed message
        bytes32 s; // s of provider signed message
        uint256 validUntil; //validity expresses in unix timestamp
        bytes providerData; //data encoded by provider   
    }

    struct consumeMarketFee{
        address consumeMarketFeeAddress;
        address consumeMarketFeeToken; // address of the token marketplace wants to add fee on top
        uint256 consumeMarketFeeAmount; // amount to be transfered to marketFeeCollector
    }

    event OrderStarted(
        address indexed consumer,
        address payer,
        uint256 amount,
        uint256 serviceIndex,
        uint256 timestamp,
        address indexed publishMarketAddress,
        uint256 blockNumber
    );

    event OrderReused(
            bytes32 orderTxId,
            address caller,
            uint256 timestamp,
            uint256 number
    );

    event OrderExecuted( 
        address indexed providerAddress,
        address indexed consumerAddress,
        bytes32 orderTxId,
        bytes providerData,
        bytes providerSignature,
        bytes consumerData,
        bytes consumerSignature,
        uint256 timestamp,
        uint256 blockNumber
    );
    
    // emited for every order
    event PublishMarketFee(
        address indexed PublishMarketFeeAddress,
        address indexed PublishMarketFeeToken,
        uint256 PublishMarketFeeAmount
    );

    // emited for every order
    event ConsumeMarketFee(
        address indexed consumeMarketFeeAddress,
        address indexed consumeMarketFeeToken,
        uint256 consumeMarketFeeAmount
    );

    event PublishMarketFeeChanged(
        address caller,
        address PublishMarketFeeAddress,
        address PublishMarketFeeToken,
        uint256 PublishMarketFeeAmount
    );

    event ProviderFee(
        address indexed providerFeeAddress,
        address indexed providerFeeToken, 
        uint256 providerFeeAmount,
        bytes providerData,
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        uint256 validUntil
    );

    event MinterProposed(address currentMinter, address newMinter);

    event MinterApproved(address currentMinter, address newMinter);

    event NewFixedRate(bytes32 exchangeId, address indexed owner, address exchangeContract, address indexed baseToken);
    event NewDispenser(address dispenserContract);
    
    event NewPaymentCollector(
        address indexed caller,
        address indexed _newPaymentCollector,
        uint256 timestamp,
        uint256 blockNumber
    );

    modifier onlyNotInitialized() {
        require(
            !initialized,
            "ERC20Template: token instance already initialized"
        );
        _;
    }
    modifier onlyNFTOwner() {
        require(
            msg.sender == IERC721Template(_erc721Address).ownerOf(1),
            "ERC20Template: not NFTOwner"
        );
        _;
    }

    modifier onlyPublishingMarketFeeAddress() {
        require(
            msg.sender == publishMarketFeeAddress,
            "ERC20Template: not publishMarketFeeAddress"
        );
        _;
    }

    modifier onlyERC20Deployer() {
        require(
            IERC721Template(_erc721Address)
                .getPermissions(msg.sender)
                .deployERC20 || IERC721Template(_erc721Address).ownerOf(1) == msg.sender,
            "ERC20Template: NOT DEPLOYER ROLE"
        );
        _;
    }

    /**
     * @dev initialize
     *      Called prior contract initialization (e.g creating new Datatoken instance)
     *      Calls private _initialize function. Only if contract is not initialized.
     * @param strings_ refers to an array of strings
     *                      [0] = name token
     *                      [1] = symbol
     * @param addresses_ refers to an array of addresses passed by user
     *                     [0]  = minter account who can mint datatokens (can have multiple minters)
     *                     [1]  = paymentCollector initial paymentCollector for this DT
     *                     [2]  = publishing Market Address
     *                     [3]  = publishing Market Fee Token
     * @param factoryAddresses_ refers to an array of addresses passed by the factory
     *                     [0]  = erc721Address
     *                     [1]  = router address
     *
     * @param uints_  refers to an array of uints
     *                     [0] = cap_ the total ERC20 cap
     *                     [1] = publishing Market Fee Amount
     * @param bytes_  refers to an array of bytes
     *                     Currently not used, usefull for future templates
     */
    function initialize(
        string[] calldata strings_,
        address[] calldata addresses_,
        address[] calldata factoryAddresses_,
        uint256[] calldata uints_,
        bytes[] calldata bytes_
    ) external onlyNotInitialized returns (bool) {
        return
            _initialize(
                strings_,
                addresses_,
                factoryAddresses_,
                uints_,
                bytes_
            );
    }

    /**
     * @dev _initialize
     *      Private function called on contract initialization.
     * @param strings_ refers to an array of strings
     *                      [0] = name token
     *                      [1] = symbol
     * @param addresses_ refers to an array of addresses passed by user
     *                     [0]  = minter account who can mint datatokens (can have multiple minters)
     *                     [1]  = paymentCollector initial paymentCollector for this DT
     *                     [2]  = publishing Market Address
     *                     [3]  = publishing Market Fee Token
     * @param factoryAddresses_ refers to an array of addresses passed by the factory
     *                     [0]  = erc721Address
     *                     [1]  = router address
     *
     * @param uints_  refers to an array of uints
     *                     [0] = cap_ the total ERC20 cap
     *                     [1] = publishing Market Fee Amount
     * param bytes_  refers to an array of bytes
     *                     Currently not used, usefull for future templates
     */
    function _initialize(
        string[] memory strings_,
        address[] memory addresses_,
        address[] memory factoryAddresses_,
        uint256[] memory uints_,
        bytes[] memory
    ) private returns (bool) {
        address erc721Address = factoryAddresses_[0];
        router = factoryAddresses_[1];
        require(
            erc721Address != address(0),
            "ERC20Template: Invalid minter,  zero address"
        );

        require(
            router != address(0),
            "ERC20Template: Invalid router, zero address"
        );

        require(uints_[0] != 0, "DatatokenTemplate: Invalid cap value");
        _cap = uints_[0];
        _name = strings_[0];
        _symbol = strings_[1];
        _erc721Address = erc721Address;
        
        initialized = true;
        // add a default minter, similar to what happens with manager in the 721 contract
        _addMinter(addresses_[0]);
        if (addresses_[1] != address(0)) {
            _setPaymentCollector(addresses_[1]);
            emit NewPaymentCollector(
                msg.sender,
                addresses_[1],
                block.timestamp,
                block.number
            );
        }
        publishMarketFeeAddress = addresses_[2];
        publishMarketFeeToken = addresses_[3];
        publishMarketFeeAmount = uints_[1];
        emit PublishMarketFeeChanged(
            msg.sender,
            publishMarketFeeAddress,
            publishMarketFeeToken,
            publishMarketFeeAmount
        );
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")), // version, could be any other value
                chainId,
                address(this)
            )
        );

        return initialized;
    }

    /**
     * @dev createFixedRate
     *      Creates a new FixedRateExchange setup.
     * @param fixedPriceAddress fixedPriceAddress
     * @param addresses array of addresses [baseToken,owner,marketFeeCollector]
     * @param uints array of uints [baseTokenDecimals,datatokenDecimals, fixedRate, marketFee, withMint]
     * @return exchangeId
     */
    function createFixedRate(
        address fixedPriceAddress,
        address[] memory addresses,
        uint256[] memory uints
    ) external onlyERC20Deployer nonReentrant returns (bytes32 exchangeId) {
        //force FRE allowedSwapper to this contract address. no one else can swap
        addresses[3] = address(this);
        if (uints[4] > 0) _addMinter(fixedPriceAddress);
        exchangeId = IFactoryRouter(router).deployFixedRate(
            fixedPriceAddress,
            addresses,
            uints
        );
        emit NewFixedRate(exchangeId, addresses[1], fixedPriceAddress, addresses[0]);
        fixedRateExchanges.push(fixedRate(fixedPriceAddress,exchangeId));
    }

    /**
     * @dev createDispenser
     *      Creates a new Dispenser
     * @param _dispenser dispenser contract address
     * @param maxTokens - max tokens to dispense
     * @param maxBalance - max balance of requester.
     * @param withMint - with MinterRole
     * param allowedSwapper have it here for compat reasons, will be overwritten
     */
    function createDispenser(
        address _dispenser,
        uint256 maxTokens,
        uint256 maxBalance,
        bool withMint,
        address
    ) external onlyERC20Deployer nonReentrant {
        // add dispenser contract as minter if withMint == true
        if (withMint) _addMinter(_dispenser);
        dispensers.push(_dispenser);
        emit NewDispenser(_dispenser);
        IFactoryRouter(router).deployDispenser(
            _dispenser,
            address(this),
            maxTokens,
            maxBalance,
            msg.sender,
            address(this)
        );
    }

    /**
     * @dev mint
     *      Only the minter address can call it.
     *      msg.value should be higher than zero and gt or eq minting fee
     * @param account refers to an address that token is going to be minted to.
     * @param value refers to amount of tokens that is going to be minted.
     */
    function mint(address account, uint256 value) external {
        require(permissions[msg.sender].minter, "ERC20Template: NOT MINTER");
        require(
            totalSupply().add(value) <= _cap,
            "DatatokenTemplate: cap exceeded"
        );
        _mint(account, value);
    }

    /**
     * @dev _checkProviderFee
     *      Checks if a providerFee structure is valid, signed and 
     *      transfers fee to providerAddress
     * @param _providerFee providerFee structure
     */
    function _checkProviderFee(providerFee calldata _providerFee) internal{
        // check if they are signed
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 message = keccak256(
            abi.encodePacked(prefix,
                keccak256(
                    abi.encodePacked(
                        _providerFee.providerData,
                        _providerFee.providerFeeAddress,
                        _providerFee.providerFeeToken,
                        _providerFee.providerFeeAmount,
                        _providerFee.validUntil
                    )
                )
            )
        );
        address signer = ecrecover(message, _providerFee.v, _providerFee.r, _providerFee.s);
        require(signer == _providerFee.providerFeeAddress, "Invalid provider fee");
        emit ProviderFee(
            _providerFee.providerFeeAddress,
            _providerFee.providerFeeToken,
            _providerFee.providerFeeAmount,
            _providerFee.providerData,
            _providerFee.v,
            _providerFee.r,
            _providerFee.s,
            _providerFee.validUntil
        );
        // skip fee if amount == 0 or feeToken == 0x0 address or feeAddress == 0x0 address
        // Requires approval for the providerFeeToken of providerFeeAmount
        if (
            _providerFee.providerFeeAmount > 0 &&
            _providerFee.providerFeeToken != address(0) &&
            _providerFee.providerFeeAddress != address(0)
        ) {
            uint256 OPCFee = IFactoryRouter(router).getOPCProviderFee();
            uint256 OPCcut = 0;
            if(OPCFee > 0)
                OPCcut = _providerFee.providerFeeAmount.mul(OPCFee).div(BASE);
            uint256 providerCut = _providerFee.providerFeeAmount.sub(OPCcut);
            _pullUnderlying(_providerFee.providerFeeToken,msg.sender,
                address(this),
                _providerFee.providerFeeAmount);
            IERC20(_providerFee.providerFeeToken).safeTransfer(
                _providerFee.providerFeeAddress,
                providerCut
            );
            if(OPCcut > 0){
              IERC20(_providerFee.providerFeeToken).safeTransfer(
                IFactoryRouter(router).getOPCCollector(),
                OPCcut
            );  
            }
        }
    }
    /**
     * @dev startOrder
     *      called by payer or consumer prior ordering a service consume on a marketplace.
     *      Requires previous approval of consumeFeeToken and publishMarketFeeToken
     * @param consumer is the consumer address (payer could be different address)
     * @param serviceIndex service index in the metadata
     * @param _providerFee provider fee
     * @param _consumeMarketFee consume market fee
     */
    function startOrder(
        address consumer,
        uint256 serviceIndex,
        providerFee calldata _providerFee,
        consumeMarketFee calldata _consumeMarketFee
    ) public {
        uint256 amount = 1e18; // we always pay 1 DT. No more, no less
        require(
            balanceOf(msg.sender) >= amount,
            "Not enough datatokens to start Order"
        );
        emit OrderStarted(
            consumer,
            msg.sender,
            amount,
            serviceIndex,
            block.timestamp,
            publishMarketFeeAddress,
            block.number
        );
        // publishMarketFee
        // Requires approval for the publishMarketFeeToken of publishMarketFeeAmount
        // skip fee if amount == 0 or feeToken == 0x0 address or feeAddress == 0x0 address
        if (
            publishMarketFeeAmount > 0 &&
            publishMarketFeeToken != address(0) &&
            publishMarketFeeAddress != address(0)
        ) {
            _pullUnderlying(publishMarketFeeToken,msg.sender,
                publishMarketFeeAddress,
                publishMarketFeeAmount);
            emit PublishMarketFee(
                publishMarketFeeAddress,
                publishMarketFeeToken,
                publishMarketFeeAmount
            );
        }

        // consumeMarketFee
        // Requires approval for the FeeToken 
        // skip fee if amount == 0 or feeToken == 0x0 address or feeAddress == 0x0 address
        if (
            _consumeMarketFee.consumeMarketFeeAmount > 0 &&
            _consumeMarketFee.consumeMarketFeeToken != address(0) &&
            _consumeMarketFee.consumeMarketFeeAddress != address(0)
        ) {
            _pullUnderlying(_consumeMarketFee.consumeMarketFeeToken,msg.sender,
                _consumeMarketFee.consumeMarketFeeAddress,
                _consumeMarketFee.consumeMarketFeeAmount);
            emit ConsumeMarketFee(
                _consumeMarketFee.consumeMarketFeeAddress,
                _consumeMarketFee.consumeMarketFeeToken,
                _consumeMarketFee.consumeMarketFeeAmount
            );
        }

        _checkProviderFee(_providerFee);
        
        burn(amount);
    }

    /**
     * @dev reuseOrder
     *      called by payer or consumer having a valid order, but with expired provider access
     *      Pays the provider fee again, but it will not require a new datatoken payment
     *      Requires previous approval of provider fee.
     * @param orderTxId previous valid order
     * @param _providerFee provider feee
     */
    function reuseOrder(
        bytes32 orderTxId,
        providerFee calldata _providerFee
    ) external {
        emit OrderReused(
            orderTxId,
            msg.sender,
            block.timestamp,
            block.number
        );
        _checkProviderFee(_providerFee);
    }

    /**
     * @dev addMinter
     *      Only ERC20Deployer (at 721 level) can update.
     *      There can be multiple minters
     * @param _minter new minter address
     */

    function addMinter(address _minter) external onlyERC20Deployer {
        _addMinter(_minter);
    }

    /**
     * @dev removeMinter
     *      Only ERC20Deployer (at 721 level) can update.
     *      There can be multiple minters
     * @param _minter minter address to remove
     */

    function removeMinter(address _minter) external onlyERC20Deployer {
        _removeMinter(_minter);
    }

    /**
     * @dev addPaymentManager (can set who's going to collect fee when consuming orders)
     *      Only ERC20Deployer (at 721 level) can update.
     *      There can be multiple paymentCollectors
     * @param _paymentManager new minter address
     */

    function addPaymentManager(address _paymentManager)
        external
        onlyERC20Deployer
    {
        _addPaymentManager(_paymentManager);
    }

    /**
     * @dev removePaymentManager
     *      Only ERC20Deployer (at 721 level) can update.
     *      There can be multiple paymentManagers
     * @param _paymentManager _paymentManager address to remove
     */

    function removePaymentManager(address _paymentManager)
        external
        onlyERC20Deployer
    {
        _removePaymentManager(_paymentManager);
    }

    /**
     * @dev setData
     *      Only ERC20Deployer (at 721 level) can call it.
     *      This function allows to store data with a preset key (keccak256(ERC20Address)) into NFT 725 Store
     * @param _value data to be set with this key
     */

    function setData(bytes calldata _value) external onlyERC20Deployer {
        bytes32 key = keccak256(abi.encodePacked(address(this)));
        IERC721Template(_erc721Address).setDataERC20(key, _value);
    }

    /**
     * @dev cleanPermissions()
     *      Only NFT Owner (at 721 level) can call it.
     *      This function allows to remove all minters, feeManagers and reset the paymentCollector
     *
     */

    function cleanPermissions() external onlyNFTOwner {
        _internalCleanPermissions();
    }

    /**
     * @dev cleanFrom721()
     *      OnlyNFT(721) Contract can call it.
     *      This function allows to remove all minters, feeManagers and reset the paymentCollector
     *       This function is used when transferring an NFT to a new owner,
     * so that permissions at ERC20level (minter,feeManager,paymentCollector) can be reset.
     *
     */
    function cleanFrom721() external {
        require(
            msg.sender == _erc721Address,
            "ERC20Template: NOT 721 Contract"
        );
        _internalCleanPermissions();
        
    }
    
    function _internalCleanPermissions() internal {
        uint256 totalLen = fixedRateExchanges.length + dispensers.length;
        uint256 curentLen = 0;
        address[] memory previousMinters=new address[](totalLen);
        // loop though fixedrates, empty and preserve the minter rols if exists
        uint256 i;
        for(i=0; i<fixedRateExchanges.length; i++) {
                IFixedRateExchange fre = IFixedRateExchange(fixedRateExchanges[i].contractAddress);
                (
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    uint256 dtBalance,
                    uint256 btBalance,
                    bool withMint
                ) = fre.getExchange(fixedRateExchanges[i].id);
                if(btBalance>0)
                    fre.collectBT(fixedRateExchanges[i].id, btBalance);
                if(dtBalance>0)
                    fre.collectDT(fixedRateExchanges[i].id, dtBalance);
                // add it to the list of minters
                if(isMinter(fixedRateExchanges[i].contractAddress) && withMint == true){
                    previousMinters[curentLen]=fixedRateExchanges[i].contractAddress;
                    curentLen++;
                }
        }
        // loop though dispenser and preserve the minter rols if exists
        for(i=0; i<dispensers.length; i++) {
                IDispenser(dispensers[i]).ownerWithdraw(address(this));
                if(isMinter(dispensers[i])){
                    previousMinters[curentLen]=dispensers[i];
                    curentLen++;
                }
        }
        // clear all permisions
         _cleanPermissions();
        // set collector to 0
        paymentCollector = address(0);
        // add existing minter roles for fixedrate & dispensers
        for(i=0; i<curentLen; i++) {
            _addMinter(previousMinters[i]);
        }
        
    }
    /**
     * @dev setPaymentCollector
     *      Only feeManager can call it
     *      This function allows to set a newPaymentCollector (receives DT when consuming)
            If not set the paymentCollector is the NFT Owner
     * @param _newPaymentCollector new fee collector 
     */

    function setPaymentCollector(address _newPaymentCollector) external {
        //we allow _newPaymentCollector = address(0), because it means that the collector is nft owner
        require(
            permissions[msg.sender].paymentManager ||
                IERC721Template(_erc721Address).getPermissions(msg.sender).deployERC20 || 
                IERC721Template(_erc721Address).ownerOf(1)==msg.sender,
            "ERC20Template: NOT PAYMENT MANAGER or OWNER"
        );
        _setPaymentCollector(_newPaymentCollector);
        emit NewPaymentCollector(
            msg.sender,
            _newPaymentCollector,
            block.timestamp,
            block.number
        );
    }

    /**
     * @dev _setPaymentCollector
     * @param _newPaymentCollector new fee collector
     */

    function _setPaymentCollector(address _newPaymentCollector) internal {
        paymentCollector = _newPaymentCollector;
    }

    /**
     * @dev getPublishingMarketFee
     *      Get publishingMarket Fee
     *      This function allows to get the current fee set by the publishing market
     */
    function getPublishingMarketFee()
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            publishMarketFeeAddress,
            publishMarketFeeToken,
            publishMarketFeeAmount
        );
    }

    /**
     * @dev setPublishingMarketFee
     *      Only publishMarketFeeAddress can call it
     *      This function allows to set the fee required by the publisherMarket
     * @param _publishMarketFeeAddress  new _publishMarketFeeAddress
     * @param _publishMarketFeeToken new _publishMarketFeeToken
     * @param _publishMarketFeeAmount new fee amount
     */
    function setPublishingMarketFee(
        address _publishMarketFeeAddress,
        address _publishMarketFeeToken,
        uint256 _publishMarketFeeAmount
    ) external onlyPublishingMarketFeeAddress {
        require(
            _publishMarketFeeAddress != address(0),
            "Invalid _publishMarketFeeAddress address"
        );
        require(
            _publishMarketFeeToken != address(0),
            "Invalid _publishMarketFeeToken address"
        );
        publishMarketFeeAddress = _publishMarketFeeAddress;
        publishMarketFeeToken = _publishMarketFeeToken;
        publishMarketFeeAmount = _publishMarketFeeAmount;
        emit PublishMarketFeeChanged(
            msg.sender,
            _publishMarketFeeAddress,
            _publishMarketFeeToken,
            _publishMarketFeeAmount
        );
    }

    /**
     * @dev getId
     *      Return template id in case we need different ABIs. 
     *      If you construct your own template, please make sure to change the hardcoded value
     */
    function getId() pure public returns (uint8) {
        return 2;
    }

    /**
     * @dev name
     *      It returns the token name.
     * @return Datatoken name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev symbol
     *      It returns the token symbol.
     * @return Datatoken symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev getERC721Address
     *      It returns the parent ERC721
     * @return ERC721 address.
     */
    function getERC721Address() public view returns (address) {
        return _erc721Address;
    }

    /**
     * @dev decimals
     *      It returns the token decimals.
     *      how many supported decimal points
     * @return Datatoken decimals.
     */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev cap
     *      it returns the capital.
     * @return Datatoken cap.
     */
    function cap() external view returns (uint256) {
        return _cap;
    }

    /**
     * @dev isInitialized
     *      It checks whether the contract is initialized.
     * @return true if the contract is initialized.
     */

    function isInitialized() external view returns (bool) {
        return initialized;
    }

    /**
     * @dev permit
     *      used for signed approvals, see ERC20Template test for more details
     * @param owner user who signed the message
     * @param spender spender
     * @param value token amount
     * @param deadline deadline after which signed message is no more valid
     * @param v parameters from signed message
     * @param r parameters from signed message
     * @param s parameters from signed message
     */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.number, "ERC20DT: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC20DT: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    /**
     * @dev getAddressLength
     *      It returns the array lentgh
            @param array address array we want to get length
     * @return length
     */

    function getAddressLength(address[] memory array)
        private
        pure
        returns (uint256)
    {
        return array.length;
    }

    /**
     * @dev getUintLength
     *      It returns the array lentgh
            @param array uint array we want to get length
     * @return length
     */

    function getUintLength(uint256[] memory array)
        private
        pure
        returns (uint256)
    {
        return array.length;
    }

    /**
     * @dev getBytesLength
     *      It returns the array lentgh
            @param array bytes32 array we want to get length
     * @return length
     */

    function getBytesLength(bytes32[] memory array)
        private
        pure
        returns (uint256)
    {
        return array.length;
    }

    /**
     * @dev getPaymentCollector
     *      It returns the current paymentCollector
     * @return paymentCollector address
     */

    function getPaymentCollector() public view returns (address) {
        if (paymentCollector == address(0)) {
            return IERC721Template(_erc721Address).ownerOf(1);
        } else {
            return paymentCollector;
        }
    }

    /**
     * @dev fallback function
     *      this is a default fallback function in which receives
     *      the collected ether.
     */
    fallback() external payable {}

    /**
     * @dev receive function
     *      this is a default receive function in which receives
     *      the collected ether.
     */
    receive() external payable {}
    
    /**
     * @dev withdrawETH
     *      transfers all the accumlated ether the collector account
     */
    function withdrawETH() external payable {
        payable(getPaymentCollector()).transfer(address(this).balance);
    }

    struct OrderParams {
        address consumer;
        uint256 serviceIndex;
        providerFee _providerFee;
        consumeMarketFee _consumeMarketFee;
    }
    struct FreParams {
        address exchangeContract;
        bytes32 exchangeId;
        uint256 maxBaseTokenAmount;
        uint256 swapMarketFee;
        address marketFeeAddress;
    }

    /**
     * @dev buyFromFreAndOrder
     *      Buys 1 DT from the FRE and then startsOrder, while burning that DT
     */
    function buyFromFreAndOrder(
        OrderParams calldata _orderParams,
        FreParams calldata _freParams
    ) external nonReentrant{
        // get exchange info
        IFixedRateExchange fre=IFixedRateExchange(_freParams.exchangeContract);
        (
            ,
            address datatoken,
            ,
            address baseToken,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = fre.getExchange(_freParams.exchangeId);
        require(
            datatoken == address(this),
            "This FixedRate is not providing this DT"
        );
        // get token amounts needed
        (
            uint256 baseTokenAmount
            ,
            ,
            ,

        ) = fre.calcBaseInGivenOutDT(
                    _freParams.exchangeId,
                    1e18,  // we always take 1 DT
                    _freParams.swapMarketFee
                );
        require(
            baseTokenAmount <= _freParams.maxBaseTokenAmount,
            "FixedRateExchange: Too many base tokens"
        );

        //transfer baseToken to us first
        _pullUnderlying(baseToken,msg.sender,
                address(this),
                baseTokenAmount);
        //approve FRE to spend baseTokens
        IERC20(baseToken).safeIncreaseAllowance(
            _freParams.exchangeContract,
            baseTokenAmount
        );
        //buy DT
        fre.buyDT(
            _freParams.exchangeId,
            1e18, // we always take 1 dt
            baseTokenAmount,
            _freParams.marketFeeAddress,
            _freParams.swapMarketFee
        );
        require(
            balanceOf(address(this)) >= 1e18,
            "Unable to buy DT from FixedRate"
        );
        //we need the following because startOrder expects msg.sender to have dt
        _transfer(address(this), msg.sender, 1e18);
        //startOrder and burn it
        startOrder(_orderParams.consumer, _orderParams.serviceIndex,
        _orderParams._providerFee, _orderParams._consumeMarketFee);
        // collect the basetoken from fixedrate and sent it
        (
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    uint256 btBalance,
        ) = fre.getExchange(_freParams.exchangeId);
        if(btBalance>0)
            fre.collectBT(_freParams.exchangeId, btBalance);
                
    }

    /**
     * @dev buyFromDispenserAndOrder
     *      Gets DT from dispenser and then startsOrder, while burning that DT
     */
    function buyFromDispenserAndOrder(
        OrderParams calldata _orderParams,
        address dispenserContract
    ) external nonReentrant {
        uint256 amount = 1e18;
        //get DT
        IDispenser(dispenserContract).dispense(
            address(this),
            amount,
            msg.sender
        );
        require(
            balanceOf(address(msg.sender)) >= amount,
            "Unable to get DT from Dispenser"
        );
        //startOrder and burn it
        startOrder(_orderParams.consumer, _orderParams.serviceIndex,
        _orderParams._providerFee, _orderParams._consumeMarketFee);
    }

    /**
    * @dev isERC20Deployer
    *      returns true if address has deployERC20 role
    */
    function isERC20Deployer(address user) public view returns(bool){
        return(IERC721Template(_erc721Address).getPermissions(user).deployERC20);
    }

    /**
     * @dev getFixedRates
     *      Returns the list of fixedRateExchanges created for this datatoken
     */
    function getFixedRates() public view returns(fixedRate[] memory) {
        return(fixedRateExchanges);
    }
    /**
     * @dev getDispensers
     *      Returns the list of dispensers created for this datatoken
     */
    function getDispensers() public view returns(address[] memory) {
        return(dispensers);
    }

     function _pullUnderlying(
        address erc20,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 balanceBefore = IERC20(erc20).balanceOf(to);
        IERC20(erc20).safeTransferFrom(from, to, amount);
        require(IERC20(erc20).balanceOf(to) >= balanceBefore.add(amount),
                    "Transfer amount is too low");
    }

    /**
     * @dev orderExecuted
     *      Providers should call this to prove order execution
     * @param orderTxId order tx
     * @param providerData provider data
     * @param providerSignature provider signature
     * @param consumerData consumer data
     * @param consumerSignature consumer signature
     * @param consumerAddress consumer address
     */
    function orderExecuted(
        bytes32 orderTxId,
        bytes calldata providerData,
        bytes calldata providerSignature,
        bytes calldata consumerData,
        bytes calldata consumerSignature,
        address consumerAddress
    ) external {
        require(msg.sender != consumerAddress, "Provider cannot be the consumer");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 providerHash = keccak256(
            abi.encodePacked(prefix,
                keccak256(
                    abi.encodePacked(
                        orderTxId,
                        providerData
                    )
                )
            )
        );
        require(_ecrecovery(providerHash, providerSignature) == msg.sender, "Provider signature check failed");
        bytes32 consumerHash = keccak256(
            abi.encodePacked(prefix,
                keccak256(
                    abi.encodePacked(
                        consumerData
                    )
                )
            )
        );
        require(_ecrecovery(consumerHash, consumerSignature) == consumerAddress, "Consumer signature check failed");
        emit OrderExecuted(msg.sender, consumerAddress ,orderTxId, providerData, providerSignature,
                consumerData, consumerSignature, block.timestamp, block.number);
    }



    function _ecrecovery(bytes32 hash, bytes memory sig) pure internal returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) {
          return address(0);
        }
        assembly {
          r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) {
          v += 27;
        }   
        if (v != 27 && v != 28) {
        return address(0);
        }
        return ecrecover(hash, v, r, s);
    }
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Template {
    
    enum RolesType {
        Manager,
        DeployERC20,
        UpdateMetadata,
        Store
    }
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event MetadataCreated(
        address indexed createdBy,
        uint8 state,
        string decryptorUrl,
        bytes flags,
        bytes data,
        string metaDataDecryptorAddress,
        uint256 timestamp,
        uint256 blockNumber
    );
    event MetadataUpdated(
        address indexed updatedBy,
        uint8 state,
        string decryptorUrl,
        bytes flags,
        bytes data,
        string metaDataDecryptorAddress,
        uint256 timestamp,
        uint256 blockNumber
    );
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isERC20Deployer(address acount) external view returns (bool);
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, 
     * it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, 
     * it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, 
     * it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external;
    function transferFrom(address from, address to) external;

    function initialize(
        address admin,
        string calldata name,
        string calldata symbol,
        address erc20Factory,
        address additionalERC20Deployer,
        address additionalMetaDataUpdater,
        string calldata tokenURI,
        bool transferable
    ) external returns (bool);

     struct Roles {
        bool manager;
        bool deployERC20;
        bool updateMetadata;
        bool store;
    }

    struct metaDataProof {
        address validatorAddress;
        uint8 v; // v of validator signed message
        bytes32 r; // r of validator signed message
        bytes32 s; // s of validator signed message
    }
    function getPermissions(address user) external view returns (Roles memory);

    function setDataERC20(bytes32 _key, bytes calldata _value) external;
    function setMetaData(uint8 _metaDataState, string calldata _metaDataDecryptorUrl
        , string calldata _metaDataDecryptorAddress, bytes calldata flags, 
        bytes calldata data,bytes32 _metaDataHash, metaDataProof[] memory _metadataProofs) external;
    function getMetaData() external view returns (string memory, string memory, uint8, bool);

    function createERC20(
        uint256 _templateIndex,
        string[] calldata strings,
        address[] calldata addresses,
        uint256[] calldata uints,
        bytes[] calldata bytess
    ) external returns (address);


    function removeFromCreateERC20List(address _allowedAddress) external;
    function addToCreateERC20List(address _allowedAddress) external;
    function addToMetadataList(address _allowedAddress) external;
    function removeFromMetadataList(address _allowedAddress) external;
    function getId() pure external returns (uint8);
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IERC20Template {
    struct RolesERC20 {
        bool minter;
        bool feeManager;
    }
    struct providerFee{
        address providerFeeAddress;
        address providerFeeToken; // address of the token marketplace wants to add fee on top
        uint256 providerFeeAmount; // amount to be transfered to marketFeeCollector
        uint8 v; // v of provider signed message
        bytes32 r; // r of provider signed message
        bytes32 s; // s of provider signed message
        uint256 validUntil; //validity expresses in unix timestamp
        bytes providerData; //data encoded by provider
    }
    struct consumeMarketFee{
        address consumeMarketFeeAddress;
        address consumeMarketFeeToken; // address of the token marketplace wants to add fee on top
        uint256 consumeMarketFeeAmount; // amount to be transfered to marketFeeCollector
    }
    function initialize(
        string[] calldata strings_,
        address[] calldata addresses_,
        address[] calldata factoryAddresses_,
        uint256[] calldata uints_,
        bytes[] calldata bytes_
    ) external returns (bool);
    
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address account, uint256 value) external;
    
    function isMinter(address account) external view returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permissions(address user)
        external
        view
        returns (RolesERC20 memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cleanFrom721() external;

    function deployPool(
        uint256[] memory ssParams,
        uint256[] memory swapFees,
        address[] memory addresses 
    ) external returns (address);

    function createFixedRate(
        address fixedPriceAddress,
        address[] memory addresses,
        uint[] memory uints
    ) external returns (bytes32);
    function createDispenser(
        address _dispenser,
        uint256 maxTokens,
        uint256 maxBalance,
        bool withMint,
        address allowedSwapper) external;
        
    function getPublishingMarketFee() external view returns (address , address, uint256);
    function setPublishingMarketFee(
        address _publishMarketFeeAddress, address _publishMarketFeeToken, uint256 _publishMarketFeeAmount
    ) external;

     function startOrder(
        address consumer,
        uint256 serviceIndex,
        providerFee calldata _providerFee,
        consumeMarketFee calldata _consumeMarketFee
     ) external;

     function reuseOrder(
        bytes32 orderTxId,
        providerFee calldata _providerFee
    ) external;
  
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function getERC721Address() external view returns (address);
    function isERC20Deployer(address user) external view returns(bool);
    function getPools() external view returns(address[] memory);
    struct fixedRate{
        address contractAddress;
        bytes32 id;
    }
    function getFixedRates() external view returns(fixedRate[] memory);
    function getDispensers() external view returns(address[] memory);
    function getId() pure external returns (uint8);
    function getPaymentCollector() external view returns (address);
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IFactoryRouter {
    function deployPool(
        address[2] calldata tokens, // [datatokenAddress, baseTokenAddress]
        uint256[] calldata ssParams,
        uint256[] calldata swapFees,
        address[] calldata addresses
    ) external returns (address);

    function deployFixedRate(
        address fixedPriceAddress,
        address[] calldata addresses,
        uint256[] calldata uints
    ) external returns (bytes32 exchangeId);

    function getOPCFee(address baseToken) external view returns (uint256);
    function getOPCFees() external view returns (uint256,uint256);
    function getOPCConsumeFee() external view returns (uint256);
    function getOPCProviderFee() external view returns (uint256);

    function getMinVestingPeriod() external view returns (uint256);
    function deployDispenser(
        address _dispenser,
        address datatoken,
        uint256 maxTokens,
        uint256 maxBalance,
        address owner,
        address allowedSwapper
    ) external;

    function isApprovedToken(address) external view returns(bool);
    function getApprovedTokens() external view returns(address[] memory);
    function isSSContract(address) external view returns(bool);
    function getSSContracts() external view returns(address[] memory);
    function isFixedRateContract(address) external view returns(bool);
    function getFixedRatesContracts() external view returns(address[] memory);
    function isDispenserContract(address) external view returns(bool);
    function getDispensersContracts() external view returns(address[] memory);
    function isPoolTemplate(address) external view returns(bool);
    function getPoolTemplates() external view returns(address[] memory);

    struct Stakes {
        address poolAddress;
        uint256 tokenAmountIn;
        uint256 minPoolAmountOut;
    }
    function stakeBatch(Stakes[] calldata) external;

    enum operationType {
        SwapExactIn,
        SwapExactOut,
        FixedRate,
        Dispenser
    }

    struct Operations {
        bytes32 exchangeIds; // used for fixedRate or dispenser
        address source; // pool, dispenser or fixed rate address
        operationType operation; // type of operation: enum operationType
        address tokenIn; // token in address, only for pools
        uint256 amountsIn; // ExactAmount In for swapExactIn operation, maxAmount In for swapExactOut
        address tokenOut; // token out address, only for pools
        uint256 amountsOut; // minAmountOut for swapExactIn or exactAmountOut for swapExactOut
        uint256 maxPrice; // maxPrice, only for pools
        uint256 swapMarketFee;
        address marketFeeAddress;
    }
    function buyDTBatch(Operations[] calldata) external;
    function updateOPCCollector(address _opcCollector) external;
    function getOPCCollector() view external returns (address);
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IFixedRateExchange {
    function createWithDecimals(
        address datatoken,
        address[] calldata addresses, // [baseToken,owner,marketFeeCollector]
        uint256[] calldata uints // [baseTokenDecimals,datatokenDecimals, fixedRate, marketFee]
    ) external returns (bytes32 exchangeId);

    function buyDT(bytes32 exchangeId, uint256 datatokenAmount,
        uint256 maxBaseTokenAmount, address consumeMarketAddress, uint256 consumeMarketSwapFeeAmount) external;
    function sellDT(bytes32 exchangeId, uint256 datatokenAmount,
        uint256 minBaseTokenAmount, address consumeMarketAddress, uint256 consumeMarketSwapFeeAmount) external;

    function getAllowedSwapper(bytes32 exchangeId) external view returns (address allowedSwapper);
    function getExchange(bytes32 exchangeId)
        external
        view
        returns (
            address exchangeOwner,
            address datatoken,
            uint256 dtDecimals,
            address baseToken,
            uint256 btDecimals,
            uint256 fixedRate,
            bool active,
            uint256 dtSupply,
            uint256 btSupply,
            uint256 dtBalance,
            uint256 btBalance,
            bool withMint
            //address allowedSwapper
        );

    function getFeesInfo(bytes32 exchangeId)
        external
        view
        returns (
            uint256 marketFee,
            address marketFeeCollector,
            uint256 opcFee,
            uint256 marketFeeAvailable,
            uint256 oceanFeeAvailable
        );

    function isActive(bytes32 exchangeId) external view returns (bool);

    function calcBaseInGivenOutDT(bytes32 exchangeId, uint256 datatokenAmount, uint256 consumeMarketSwapFeeAmount)
        external
        view
        returns (
            uint256 baseTokenAmount,
            uint256 oceanFeeAmount,
            uint256 publishMarketFeeAmount,
            uint256 consumeMarketFeeAmount
        );
    function calcBaseOutGivenInDT(bytes32 exchangeId, uint256 datatokenAmount, uint256 consumeMarketSwapFeeAmount)
        external
        view
        returns (
            uint256 baseTokenAmount,
            uint256 oceanFeeAmount,
            uint256 publishMarketFeeAmount,
            uint256 consumeMarketFeeAmount
        );
    function updateMarketFee(bytes32 exchangeId, uint256 _newMarketFee) external;
    function updateMarketFeeCollector(bytes32 exchangeId, address _newMarketCollector) external;
    function setAllowedSwapper(bytes32 exchangeId, address newAllowedSwapper) external;
    function getId() pure external returns (uint8);
    function collectBT(bytes32 exchangeId, uint256 amount) external;
    function collectDT(bytes32 exchangeId, uint256 amount) external;
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IDispenser {
    
    function status(address datatoken)
    external
    view
    returns (
        bool active,
        address owner,
        bool isMinter,
        uint256 maxTokens,
        uint256 maxBalance,
        uint256 balance,
        address allowedSwapper
    );
    
    function create(
        address datatoken,uint256 maxTokens, uint256 maxBalance, address owner, address allowedSwapper) external;
    function activate(address datatoken,uint256 maxTokens, uint256 maxBalance) external;
    
    function deactivate(address datatoken) external;
    
    function dispense(address datatoken, uint256 amount, address destination) external payable;
    
    function ownerWithdraw(address datatoken) external;
    function setAllowedSwapper(address datatoken, address newAllowedSwapper) external;
    function getId() pure external returns (uint8);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

contract ERC20Roles {
    
    
    mapping(address => RolesERC20) public permissions;

    address[] public authERC20;

    struct RolesERC20 {
        bool minter;
        bool paymentManager; 
    }

    event AddedMinter(
        address indexed user,
        address indexed signer,
        uint256 timestamp,
        uint256 blockNumber
    );
    event RemovedMinter(
        address indexed user,
        address indexed signer,
        uint256 timestamp,
        uint256 blockNumber
    );

    /**
    * @dev getPermissions
    *      Returns list of roles for an user
    * @param user user address
    */
    function getPermissions(address user) public view returns (RolesERC20 memory) {
        return permissions[user];
    }

    /**
     * @dev isMinter
     *      Check if an address has the minter role
     * @param account refers to an address that is checked
     */
    function isMinter(address account) public view returns (bool) {
        return (permissions[account].minter);
    }

    
    /**
    * @dev _addMinter
    *      Internal function to add minter role to an user.
    * @param _minter user address
    */
    function _addMinter(address _minter) internal {
        if(_minter != address(0)){
            RolesERC20 storage user = permissions[_minter];
            require(user.minter == false, "ERC20Roles:  ALREADY A MINTER");
            user.minter = true;
            _pushToAuthERC20(_minter);
            emit AddedMinter(_minter,msg.sender,block.timestamp,block.number);
        }
    }

    /**
    * @dev _removeMinter
    *      Internal function to remove minter role from an user.
    * @param _minter user address
    */
    function _removeMinter(address _minter) internal {
        RolesERC20 storage user = permissions[_minter];
        user.minter = false;
        emit RemovedMinter(_minter,msg.sender,block.timestamp,block.number);
        _SafeRemoveFromAuthERC20(_minter);
    }

    event AddedPaymentManager(
        address indexed user,
        address indexed signer,
        uint256 timestamp,
        uint256 blockNumber
    );
    event RemovedPaymentManager(
        address indexed user,
        address indexed signer,
        uint256 timestamp,
        uint256 blockNumber
    );

    /**
    * @dev _addPaymentManager
    *      Internal function to add paymentManager role to an user.
    * @param _paymentCollector user address
    */
    function _addPaymentManager(address _paymentCollector) internal {
        if(_paymentCollector != address(0)){
            RolesERC20 storage user = permissions[_paymentCollector];
            require(user.paymentManager == false, "ERC20Roles:  ALREADY A FEE MANAGER");
            user.paymentManager = true;
            _pushToAuthERC20(_paymentCollector);
            emit AddedPaymentManager(_paymentCollector,msg.sender,block.timestamp,block.number);
        }
    }

    /**
    * @dev _removePaymentManager
    *      Internal function to remove paymentManager role from an user.
    * @param _paymentCollector user address
    */
    function _removePaymentManager(address _paymentCollector) internal {
        RolesERC20 storage user = permissions[_paymentCollector];
        user.paymentManager = false;
        emit RemovedPaymentManager(_paymentCollector,msg.sender,block.timestamp,block.number);
        _SafeRemoveFromAuthERC20(_paymentCollector);
    }


    

   
    event CleanedPermissions(
        address indexed signer,
        uint256 timestamp,
        uint256 blockNumber
    );

    
    function _cleanPermissions() internal {
        
        for (uint256 i = 0; i < authERC20.length; i++) {
            RolesERC20 storage user = permissions[authERC20[i]];
            user.minter = false;
            user.paymentManager = false;

        }
        
        delete authERC20;
        emit CleanedPermissions(msg.sender,block.timestamp,block.number);
        
    }



        /**
    * @dev _pushToAuthERC20
    *      Checks authERC20 array and adds the user address if does not exists
    * @param user address to be checked
    */
    function _pushToAuthERC20(address user) internal {
        uint256 i;
        for (i = 0; i < authERC20.length; i++) {
            if(authERC20[i] == user) break;
        }
        if(i == authERC20.length){
            // element was not found
            authERC20.push(user);
        }
    }

    /**
    * @dev _SafeRemoveFromAuthERC20
    *      Checks if user has any roles left, and if not, it will remove it from auth array
    * @param user address to be checked and removed
    */
    function _SafeRemoveFromAuthERC20(address user) internal {
        RolesERC20 storage userRoles = permissions[user];
        if (userRoles.minter == false &&
            userRoles.paymentManager == false
        ){
            uint256 i;
            for (i = 0; i < authERC20.length; i++) {
                if(authERC20[i] == user) break;
            }
            if(i < authERC20.length){
                authERC20[i] = authERC20[authERC20.length -1];
                authERC20.pop();
            }
        }
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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