pragma solidity 0.8.10;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import "./utils/Deployer.sol";
import "./interfaces/IERC721Template.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20Template.sol";
import "./interfaces/IERC20.sol";
import "./utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @title DTFactory contract
 * @author Ocean Protocol Team
 *
 * @dev Implementation of Ocean DataTokens Factory
 *
 *      DTFactory deploys DataToken proxy contracts.
 *      New DataToken proxy contracts are links to the template contract's bytecode.
 *      Proxy contract functionality is based on Ocean Protocol custom implementation of ERC1167 standard.
 */
contract ERC721Factory is Deployer, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address private communityFeeCollector;
    uint256 private currentNFTCount;
    address private erc20Factory;
    uint256 private nftTemplateCount;

    struct Template {
        address templateAddress;
        bool isActive;
    }

    mapping(uint256 => Template) public nftTemplateList;

    mapping(uint256 => Template) public templateList;

    mapping(address => address) public erc721List;

    mapping(address => bool) public erc20List;

    event NFTCreated(
        address indexed newTokenAddress,
        address indexed templateAddress,
        string tokenName,
        address admin,
        string symbol,
        string tokenURI
    );

       uint256 private currentTokenCount = 0;
    uint256 public templateCount;
    address public router;

    event Template721Added(address indexed _templateAddress, uint256 indexed nftTemplateCount);
    event Template20Added(address indexed _templateAddress, uint256 indexed nftTemplateCount);
  //stored here only for ABI reasons
    event TokenCreated(
        address indexed newTokenAddress,
        address indexed templateAddress,
        string name,
        string symbol,
        uint256 cap,
        address creator
    );  
    
    event NewPool(
        address poolAddress,
        address ssContract,
        address basetokenAddress
    );


    event NewFixedRate(bytes32 exchangeId, address owner);
    event DispenserCreated(  // emited when a dispenser is created
        address indexed datatokenAddress,
        address indexed owner,
        uint256 maxTokens,
        uint256 maxBalance,
        address allowedSwapper
    );
    

    /**
     * @dev constructor
     *      Called on contract deployment. Could not be called with zero address parameters.
     * @param _template refers to the address of a deployed DataToken contract.
     * @param _collector refers to the community fee collector address
     * @param _router router contract address
     */
    constructor(
        address _template721,
        address _template,
        address _collector,
        address _router
    ) {
        require(
            _template != address(0) &&
                _collector != address(0) &&
                _template721 != address(0),
            "ERC721DTFactory: Invalid template token/community fee collector address"
        );
        require(_router != address(0), "ERC721DTFactory: Invalid router address");
        add721TokenTemplate(_template721);
        addTokenTemplate(_template);
        router = _router;
        communityFeeCollector = _collector;
    }


    /**
     * @dev deployERC721Contract
     *      
     * @param name NFT name
     * @param symbol NFT Symbol
     * @param _templateIndex template index we want to use
     * @param additionalERC20Deployer if != address(0), we will add it with ERC20Deployer role
     */

    function deployERC721Contract(
        string memory name,
        string memory symbol,
        uint256 _templateIndex,
        address additionalERC20Deployer,
        string memory tokenURI
    ) public returns (address token) {
        require(
            _templateIndex <= nftTemplateCount && _templateIndex != 0,
            "ERC721DTFactory: Template index doesnt exist"
        );
        Template memory tokenTemplate = nftTemplateList[_templateIndex];

        require(
            tokenTemplate.isActive,
            "ERC721DTFactory: ERC721Token Template disabled"
        );

        token = deploy(tokenTemplate.templateAddress);

        require(
            token != address(0),
            "ERC721DTFactory: Failed to perform minimal deploy of a new token"
        );
       
        erc721List[token] = token;

        IERC721Template tokenInstance = IERC721Template(token);
        require(
            tokenInstance.initialize(
                msg.sender,
                name,
                symbol,
                address(this),
                additionalERC20Deployer,
                tokenURI
            ),
            "ERC721DTFactory: Unable to initialize token instance"
        );

        emit NFTCreated(token, tokenTemplate.templateAddress, name, msg.sender, symbol, tokenURI);
        currentNFTCount += 1;
    }
    
    /**
     * @dev get the current token count.
     * @return the current token count
     */
    function getCurrentNFTCount() external view returns (uint256) {
        return currentNFTCount;
    }

    /**
     * @dev get the token template Object
     * @param _index template Index
     * @return the template struct
     */
    function getNFTTemplate(uint256 _index)
        external
        view
        returns (Template memory)
    {
        Template memory template = nftTemplateList[_index];
        return template;
    }

      /**
     * @dev add a new NFT Template.
      Only Factory Owner can call it
     * @param _templateAddress new template address
     * @return the actual template count
     */
    
    function add721TokenTemplate(address _templateAddress)
        public
        onlyOwner
        returns (uint256)
    {
        require(
            _templateAddress != address(0),
            "ERC721DTFactory: ERC721 template address(0) NOT ALLOWED"
        );
        require(isContract(_templateAddress), "ERC721Factory: NOT CONTRACT");
        nftTemplateCount += 1;
        Template memory template = Template(_templateAddress, true);
        nftTemplateList[nftTemplateCount] = template;
        emit Template721Added(_templateAddress,nftTemplateCount);
        return nftTemplateCount;
    }
      /**
     * @dev reactivate a disabled NFT Template.
            Only Factory Owner can call it
     * @param _index index we want to reactivate
     */
    
    // function to activate a disabled token.
    function reactivate721TokenTemplate(uint256 _index) external onlyOwner {
        require(
            _index <= nftTemplateCount && _index != 0,
            "ERC721DTFactory: Template index doesnt exist"
        );
        Template storage template = nftTemplateList[_index];
        template.isActive = true;
    }

      /**
     * @dev disable an NFT Template.
      Only Factory Owner can call it
     * @param _index index we want to disable
     */
    function disable721TokenTemplate(uint256 _index) external onlyOwner {
        require(
            _index <= nftTemplateCount && _index != 0,
            "ERC721DTFactory: Template index doesnt exist"
        );
        Template storage template = nftTemplateList[_index];
        template.isActive = false;
    }

    function getCurrentNFTTemplateCount() external view returns (uint256) {
        return nftTemplateCount;
    }

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
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

 
    struct tokenStruct{
        string[] strings;
        address[] addresses;
        uint256[] uints;
        bytes[] bytess;
        address owner;
    }
    /**
     * @dev Deploys new DataToken proxy contract.
     *      This function is not called directly from here. It's called from the NFT contract.
            An NFT contract can deploy multiple ERC20 tokens.
     * @param _templateIndex ERC20Template index 
     * @param strings refers to an array of strings
     *                      [0] = name
     *                      [1] = symbol
     * @param addresses refers to an array of addresses
     *                     [0]  = minter account who can mint datatokens (can have multiple minters)
     *                     [1]  = feeManager initial feeManager for this DT
     *                     [2]  = publishing Market Address
     *                     [3]  = publishing Market Fee Token
     * @param uints  refers to an array of uints
     *                     [0] = cap_ the total ERC20 cap
     *                     [1] = publishing Market Fee Amount
     * @param bytess  refers to an array of bytes, not in use now, left for future templates
     * @return token address of a new proxy DataToken contract
     */
    function createToken(
        uint256 _templateIndex,
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory uints,
        bytes[] memory bytess
    ) external returns (address token) {
        require(
            erc721List[msg.sender] == msg.sender,
            "ERC721Factory: ONLY ERC721 INSTANCE FROM ERC721FACTORY"
        );
        token = _createToken(_templateIndex, strings, addresses, uints, bytess, msg.sender);
        
    }
    function _createToken(
        uint256 _templateIndex,
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory uints,
        bytes[] memory bytess,
        address owner
    ) internal returns (address token) {
        require(uints[0] != 0, "ERC20Factory: zero cap is not allowed");
        require(
            _templateIndex <= templateCount && _templateIndex != 0,
            "ERC20Factory: Template index doesnt exist"
        );
        Template memory tokenTemplate = templateList[_templateIndex];

        require(
            tokenTemplate.isActive,
            "ERC20Factory: ERC721Token Template disabled"
        );
        token = deploy(tokenTemplate.templateAddress);
        erc20List[token] = true;

        require(
            token != address(0),
            "ERC721Factory: Failed to perform minimal deploy of a new token"
        );
        emit TokenCreated(token, tokenTemplate.templateAddress, strings[0], strings[1], uints[0], owner);
        currentTokenCount += 1;
        tokenStruct memory tokenData; 
        tokenData.strings = strings;
        tokenData.addresses = addresses;
        tokenData.uints = uints;
        tokenData.owner = owner;
        tokenData.bytess = bytess;
        _createTokenStep2(token, tokenData);
    }

    function _createTokenStep2(address token, tokenStruct memory tokenData) internal {
        
        IERC20Template tokenInstance = IERC20Template(token);
        address[] memory factoryAddresses = new address[](3);
        factoryAddresses[0] = tokenData.owner;
        
        factoryAddresses[1] = communityFeeCollector;
        
        factoryAddresses[2] = router;
        
        require(
            tokenInstance.initialize(
                tokenData.strings,
                tokenData.addresses,
                factoryAddresses,
                tokenData.uints,
                tokenData.bytess
            ),
            "ERC20Factory: Unable to initialize token instance"
        );
        
    }

    /**
     * @dev get the current ERC20token deployed count.
     * @return the current token count
     */
    function getCurrentTokenCount() external view returns (uint256) {
        return currentTokenCount;
    }

    /**
     * @dev get the current ERC20token template.
      @param _index template Index
     * @return the token Template Object
     */

    function getTokenTemplate(uint256 _index)
        external
        view
        returns (Template memory)
    {
        Template memory template = templateList[_index];
        require(
            _index <= templateCount && _index != 0,
            "ERC20Factory: Template index doesnt exist"
        );
        return template;
    }

    /**
     * @dev add a new ERC20Template.
      Only Factory Owner can call it
     * @param _templateAddress new template address
     * @return the actual template count
     */

    
    function addTokenTemplate(address _templateAddress)
        public
        onlyOwner
        returns (uint256)
    {
        require(
            _templateAddress != address(0),
            "ERC20Factory: ERC721 template address(0) NOT ALLOWED"
        );
        require(isContract(_templateAddress), "ERC20Factory: NOT CONTRACT");
        templateCount += 1;
        Template memory template = Template(_templateAddress, true);
        templateList[templateCount] = template;
        emit Template20Added(_templateAddress, templateCount);
        return templateCount;
    }

     /**
     * @dev disable an ERC20Template.
      Only Factory Owner can call it
     * @param _index index we want to disable
     */

    function disableTokenTemplate(uint256 _index) external onlyOwner {
        Template storage template = templateList[_index];
        template.isActive = false;
    }


     /**
     * @dev reactivate a disabled ERC20Template.
      Only Factory Owner can call it
     * @param _index index we want to reactivate
     */

    // function to activate a disabled token.
    function reactivateTokenTemplate(uint256 _index) external onlyOwner {
        require(
            _index <= templateCount && _index != 0,
            "ERC20DTFactory: Template index doesnt exist"
        );
        Template storage template = templateList[_index];
        template.isActive = true;
    }

    // if templateCount is public we could remove it, or set templateCount to private
    function getCurrentTemplateCount() external view returns (uint256) {
        return templateCount;
    }

    struct tokenOrder {
        address tokenAddress;
        address consumer;
        uint256 amount;
        uint256 serviceIndex;
        address providerFeeAddress;
        address providerFeeToken; // address of the token marketplace wants to add fee on top
        uint256 providerFeeAmount;
    }

    /**
     * @dev startMultipleTokenOrder
     *      Used as a proxy to order multiple services
     *      Users can have inifinite approvals for fees for factory instead of having one approval/ erc20 contract
     *      Requires previous approval of all :
     *          - consumeFeeTokens
     *          - publishMarketFeeTokens
     *          - erc20 datatokens
     * @param orders an array of struct tokenOrder
     */
    function startMultipleTokenOrder(
        tokenOrder[] memory orders
    ) external nonReentrant {
        // TODO: to avoid DOS attack, we set a limit to maximum order (50 ?)
        require(orders.length <= 50, 'ERC721Factory: Too Many Orders');
        uint256 ids = orders.length;
        // TO DO.  We can do better here , by groupping publishMarketFeeTokens and consumeFeeTokens and have a single 
        // transfer for each one, instead of doing it per dt..
        for (uint256 i = 0; i < ids; i++) {
            (address publishMarketFeeAddress, address publishMarketFeeToken, uint256 publishMarketFeeAmount) 
                = IERC20Template(orders[i].tokenAddress).getPublishingMarketFee();
            
            // check if we have publishFees, if so transfer them to us and approve dttemplate to take them
            if (publishMarketFeeAmount > 0 && publishMarketFeeToken!=address(0) 
            && publishMarketFeeAddress!=address(0)) {
                IERC20(publishMarketFeeToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    publishMarketFeeAmount
                );
                IERC20(publishMarketFeeToken).safeIncreaseAllowance(orders[i].tokenAddress, publishMarketFeeAmount);
            }
            // handle provider fees
            if (orders[i].providerFeeAmount > 0 && orders[i].providerFeeToken!=address(0) 
            && orders[i].providerFeeAddress!=address(0)) {
                IERC20(orders[i].providerFeeToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    orders[i].providerFeeAmount
                );
                IERC20(orders[i].providerFeeToken)
                .safeIncreaseAllowance(orders[i].tokenAddress, orders[i].providerFeeAmount);
            }
            // transfer erc20 datatoken from consumer to us
            IERC20(orders[i].tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                orders[i].amount
            );
        
            IERC20Template(orders[i].tokenAddress).startOrder(
                orders[i].consumer,
                orders[i].amount,
                orders[i].serviceIndex,
                orders[i].providerFeeAddress,
                orders[i].providerFeeToken,
                orders[i].providerFeeAmount
            );
        }
    }

    // helper functions to save number of transactions
    struct NftCreateData{
        string name;
        string symbol;
        uint256 templateIndex;
        string tokenURI;
    }
    struct ErcCreateData{
        uint256 templateIndex;
        string[] strings;
        address[] addresses;
        uint256[] uints;
        bytes[] bytess;
    }
    
    

    
  
    /**
     * @dev createNftWithErc
     *      Creates a new NFT, then a ERC20,all in one call
     * @param _NftCreateData input data for nft creation
     * @param _ErcCreateData input data for erc20 creation
     
     */
    function createNftWithErc(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData
    ) external nonReentrant returns (address erc721Address, address erc20Address){
        erc721Address = deployERC721Contract(
            _NftCreateData.name,
            _NftCreateData.symbol,
            _NftCreateData.templateIndex,
            address(0),
            _NftCreateData.tokenURI);
        erc20Address = _createToken(
            _ErcCreateData.templateIndex,
            _ErcCreateData.strings,
            _ErcCreateData.addresses,
            _ErcCreateData.uints,
            _ErcCreateData.bytess,
            erc721Address);
    }

    struct PoolData{
        address[] addresses;
        uint256[] ssParams;
        uint256[] swapFees;
    }

    /**
     * @dev createNftErcWithPool
     *      Creates a new NFT, then a ERC20, then a Pool, all in one call
     *      Use this carefully, because if Pool creation fails, you are still going to pay a lot of gas
     * @param _NftCreateData input data for NFT Creation
     * @param _ErcCreateData input data for ERC20 Creation
     * @param _PoolData input data for Pool Creation
     */
    function createNftErcWithPool(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        PoolData calldata _PoolData
    ) external nonReentrant returns (address erc721Address, address erc20Address, address poolAddress){
        IERC20(_PoolData.addresses[1]).safeTransferFrom(
                msg.sender,
                address(this),
                _PoolData.ssParams[4]
        );
        //we are adding ourselfs as a ERC20 Deployer, because we need it in order to deploy the pool
        erc721Address = deployERC721Contract(
            _NftCreateData.name,
            _NftCreateData.symbol,
            _NftCreateData.templateIndex,
            address(this),
             _NftCreateData.tokenURI);
        erc20Address = _createToken(
            _ErcCreateData.templateIndex,
            _ErcCreateData.strings,
            _ErcCreateData.addresses,
            _ErcCreateData.uints,
            _ErcCreateData.bytess,
            erc721Address);
        // allow router to take the liquidity
        IERC20(_PoolData.addresses[1]).safeIncreaseAllowance(router,_PoolData.ssParams[4]);
      
        poolAddress = IERC20Template(erc20Address).deployPool(
            _PoolData.ssParams,
            _PoolData.swapFees,
           _PoolData.addresses
        );
    
    }

    struct FixedData{
        address fixedPriceAddress;
        address[] addresses;
        uint256[] uints;
    }
    /**
     * @dev createNftErcWithFixedRate
     *      Creates a new NFT, then a ERC20, then a FixedRateExchange, all in one call
     *      Use this carefully, because if Fixed Rate creation fails, you are still going to pay a lot of gas
     * @param _NftCreateData input data for NFT Creation
     * @param _ErcCreateData input data for ERC20 Creation
     * @param _FixedData input data for FixedRate Creation
     */
    function createNftErcWithFixedRate(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        FixedData calldata _FixedData
    ) external nonReentrant returns (address erc721Address, address erc20Address, bytes32 exchangeId){
        //we are adding ourselfs as a ERC20 Deployer, because we need it in order to deploy the fixedrate
        erc721Address = deployERC721Contract(
            _NftCreateData.name,
            _NftCreateData.symbol,
            _NftCreateData.templateIndex,
            address(this),
             _NftCreateData.tokenURI);
        erc20Address = _createToken(
            _ErcCreateData.templateIndex,
            _ErcCreateData.strings,
            _ErcCreateData.addresses,
            _ErcCreateData.uints,
            _ErcCreateData.bytess,
            erc721Address);
        exchangeId = IERC20Template(erc20Address).createFixedRate(
            _FixedData.fixedPriceAddress,
            _FixedData.addresses,
            _FixedData.uints
            );
    }

    struct DispenserData{
        address dispenserAddress;
        uint256 maxTokens;
        uint256 maxBalance;
        bool withMint;
        address allowedSwapper;
    }
    /**
     * @dev createNftErcWithDispenser
     *      Creates a new NFT, then a ERC20, then a Dispenser, all in one call
     *      Use this carefully
     * @param _NftCreateData input data for NFT Creation
     * @param _ErcCreateData input data for ERC20 Creation
     * @param _DispenserData input data for Dispenser Creation
     */
    function createNftErcWithDispenser(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        DispenserData calldata _DispenserData
    ) external nonReentrant returns (address erc721Address, address erc20Address){
        //we are adding ourselfs as a ERC20 Deployer, because we need it in order to deploy the fixedrate
        erc721Address = deployERC721Contract(
            _NftCreateData.name,
            _NftCreateData.symbol,
            _NftCreateData.templateIndex,
            address(this),
             _NftCreateData.tokenURI);
        erc20Address = _createToken(
            _ErcCreateData.templateIndex,
            _ErcCreateData.strings,
            _ErcCreateData.addresses,
            _ErcCreateData.uints,
            _ErcCreateData.bytess,
            erc721Address);
        IERC20Template(erc20Address).createDispenser(
            _DispenserData.dispenserAddress,
            _DispenserData.maxTokens,
            _DispenserData.maxBalance,
            _DispenserData.withMint,
            _DispenserData.allowedSwapper
            );
    }




}

pragma solidity 0.8.10;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

/**
 * @title Deployer Contract
 * @author Ocean Protocol Team
 *
 * @dev Contract Deployer
 *      This contract allowes factory contract 
 *      to deploy new contract instances using
 *      the same library pattern in solidity.
 *      the logic it self is deployed only once, but
 *      executed in the context of the new storage 
 *      contract (new contract instance)
 */
contract Deployer {
    event InstanceDeployed(address instance);
    
    // /**
    //  * @dev deploy
    //  *      deploy new contract instance 
    //  * @param _logic the logic contract address
    //  * @return  address of the new instance
    //  */
    function deploy(
        address _logic
    ) 
      internal 
      returns (address instance) 
    {
        bytes20 targetBytes = bytes20(_logic);
        // solhint-disable-next-line max-line-length
        // Follows OpenZeppelin Implementation https://github.com/OpenZeppelin/openzeppelin-sdk/blob/71c9ad77e0326db079e6a643eca8568ab316d4a9/packages/lib/contracts/upgradeability/ProxyFactory.sol
        // solhint-disable-next-line max-line-length
        // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
          let clone := mload(0x40)
          mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
          mstore(add(clone, 0x14), targetBytes)
          mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
          instance := create(0, clone, 0x37)
        }
        emit InstanceDeployed(address(instance));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Template is IERC165 {
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
        string calldata tokenURI
    ) external returns (bool);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

     struct Roles {
        bool manager;
        bool deployERC20;
        bool updateMetadata;
        bool store;
    }


    function getPermissions(address user) external returns (Roles memory);

    function setDataERC20(bytes32 _key, bytes calldata _value) external;
    function setMetaData(uint8 _metaDataState, string calldata _metaDataDecryptorUrl
        , string calldata _metaDataDecryptorAddress, bytes calldata flags, 
        bytes calldata data) external;
    function getMetaData() external view returns (string memory, string memory, uint8, bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

pragma solidity 0.8.10;

interface IERC20Template {
    struct RolesERC20 {
        bool minter;
        bool feeManager;
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
        uint256 amount,
        uint256 serviceId,
        address providerFeeAddress,
        address providerFeeToken, 
        uint256 providerFeeAmount
     ) external;
  
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function getERC721Address() external view returns (address);
    function isERC20Deployer(address user) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./ERC721/Address.sol";

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

pragma solidity 0.8.10;
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts/utils/[email protected]