// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./USDSatMetadata.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

///                                            ``..                                                    
///                                    `.` `````.``.-````-``  `.`                                      
///                            ` ``````.`..///.-..----. --..--`.-....`..-.```` ```                     
///                        `` `.`..--...`:::/::-``..``..:-.://///---..-....-----                       
///                   ``-:::/+++:::/-.-///://oso+::++/--:--../+:/:..:-....-://:/:-``                   
///                   `-+/++/+o+://+::-:soo+oosss+s+//o:/:--`--:://://:ooso/-.--.-:-.`                 
///                 ``.+ooso++o+:+:+sosyhsyshhddyo+:/sds/yoo++/+:--/--.--:..--..``.````                
///                ``:++/---:+/::::///oyhhyy+++:hddhhNNho///ohosyhs+/-:/+/---.....-.. `                
///               ``-:-...-/+///++///+o+:-:o+o/oydmNmNNdddhsoyo/oyyyho///:-.--.-.``. ``                
///              ```--`..-:+/:--:::-.-///++++ydsdNNMNdmMNMmNysddyoooosso+//-.-`....````` ..`           
///                .```:-:::/-.-+o++/+:/+/o/hNNNNhmdNMMNNMMdyydNNmdyys+++oo++-`--.:.-.`````...         
///               ..--.`-..`.-`-hh++-/:+shho+hsysyyhhhmNNmmNMMmNNNdmmy+:+sh/o+y/+-`+./::.```` `        
///              -/` ``.-``.//o++y+//ssyh+hhdmmdmmddmhdmNdmdsh+oNNMmmddoodh/s:yss.--+.//+`.` `.        
///             `.`-.` -`..+h+yo++ooyyyyyoyhy+shmNNmmdhhdhyyhymdyyhdmshoohs+y:oy+/+o/:/++.`-   .`      
///             ``.`.``-.-++syyyhhhhhhhhmhysosyyoooosssdhhhdmmdhdmdsy+ss+/+ho/hody-s+-:+::--``  `      
///            .``  ``-//s+:ohmdmddNmNmhhshhddNNNhyyhhhdNNhmNNmNNmmyso+yhhso++hhdy.:/ ::-:--``.`       
///           .```.-`.//shdmNNmddyysohmMmdmNNmmNshdmNhso+-/ohNoyhmmsysosd++hy/osss/.:-o/-.:/--.        
///          ``..:++-+hhy/syhhhdhdNNddNMmNsNMNyyso+//:-.`-/..+hmdsmdy+ossos:+o/h/+..//-s.`.:::o/       
///          `.-.oy//hm+o:-..-+/shdNNNNNNhsNdo/oyoyyhoh+/so//+/mNmyhh+/s+dy/+s::+:`-`-:s--:-.::+`-`    
///           .`:h-`+y+./oyhhdddhyohMMNmmNmdhoo/oyyhddhmNNNmhsoodmdhs+///++:+-:.:/--/-/o/--+//...:`    
///           ``+o``yoodNNNNNMhdyyo+ymhsymyshhyys+sssssNmdmmdmy+oso/++:://+/-`::-:--:/::+.//o:-.--:    
///           `:-:-`oNhyhdNNNmyys+/:://oohy++/+hmmmmNNNNhohydmmyhy++////ooy./----.-:---/::-o+:...-/    
///          ``-.-` yms+mmNmMMmNho/:o++++hhh++:mMmNmmmNMNdhdms+ysyy//:-+o:.-.`.``.-:/::-:-+/y/.- -`    
///            ..:` hh+oNNmMNNNmss/:-+oyhs+o+.-yhdNmdhmmydmms+o///:///+/+--/`-``.o::/:-o//-/y::/.-     
///            `.-``hh+yNdmdohdy:++/./myhds/./shNhhyy++o:oyos/s+:s//+////.:- ...`--`..`-.:--o:+::`     
///              `-/+yyho.`.-+oso///+/Nmddh//y+:s:.../soy+:o+.:sdyo++++o:.-. `.:.:-```:.`:``/o:`:`     
///            ./.`..sMN+:::yh+s+ysyhhddh+ymdsd/:/+o+ysydhohoh/o+/so++o+/o.--..`-:::``:-`+-`:+--.`     
///           ``:``..-NNy++/yyysohmo+NNmy/+:+hMNmy+yydmNMNddhs:yyydmmmso:o///..-.-+-:o:/.o/-/+-``      
///           ``+.`..-mMhsyo+++oo+yoshyyo+/`+hNmhyy+sdmdssssho-MMMNMNh//+/oo+/+:-....`.s+/`..-`        
///             .+  `oNMmdhhsohhmmydmNms/yy.oNmmdy+++/+ss+odNm+mNmdddo-s+:+/++/-:--//`/o+s/.-``        
///             `/`  dNNNhooddNmNymMNNdsoo+y+shhhmyymhss+hddms+hdhmdo+/+-/oo+/.///+sh:-/-s/`           
///              `::`hdNmh+ooNmdohNNMMmsooohh+oysydhdooo/syysodmNmys+/o+//+y/:.+/hmso.-//s-            
///                -+ohdmmhyhdysysyyhmysoyddhhoo+shdhdyddmddmNmmhssds/::/oo/..:/+Nmo+`-:so             
///                 .oyhdmmNNdm+s:/:os/+/ssyyds+/ssdNNyhdmmhdmmdymymy///o:/``/+-dmdoo++:o`             
///                 `ysyMNhhmoo+h-:/+o/+:.:/:/+doo+dNdhddmhmmmy++yhds/+-+::..o/+Nmosyhs+-              
///                  s+dNNyNhsdhNhsy:+:oo/soo+dNmmooyosohMhsymmhyy+++:+:/+/-/o+yNh+hMNs.               
///                  +yhNNMd+dmydmdy/+/sshydmhdNNmNooyhhhhshohmNh+:+oso++ssy+/odyhhNmh`                
///                 `yyhdms+dMh+oyshhyhysdmNd+ohyNN+++mNddmNy+yo//+o/hddddymmyhosNmms`                 
///                  oydos:oMmhoyyhysssysdmMmNmhNmNNh/+mmNmddh+/+o+::+s+hmhmdyNNNNy:                   
///                 `/dNm/+Ndhy+oshdhhdyo::ohmdyhhNysy:smshmdo/o:so//:s++ymhyohdy-`                    
///                 `sNNN/hNm/:do+o:+/++++s:/+shyymmddy/ydmmh/s/+oss//oysy++o+o+`                      
///                  oNNMNmm:/hyy/:/o/+hhsosysoo-ohhhss/hmmhd/dyh++/soyooy++o+:.                       
///                  :/dMNh/smhh+//+s+--:+/so+ohhy/:sydmmmmm+/mdddhy++/ohs//-o/`                       
///                  `/odmhyhsyh++/-:+:::/:/o/:ooddy/+yodNNh+ydhmmmy++/hhyo+://`                       
///                   `:os/+o//oshss/yhs+//:+/-/:soooo/+sso+dddydss+:+sy///+:++                        
///                     ./o/s//hhNho+shyyyoyyso+/ys+/+-:y+:/soooyyh++sNyo++/:/+                        
///                      -/:osmmhyo:++++/+/osshdssooo/:/h//://++oyhsshmdo+//s/-                        
///                       .osmhydh::/+++/o+ohhysddyoo++os+-+++///yhhhmNs+o/://                         
///                        -.++yss//////+/+/+soo++shyhsyy+::/:+y+yhdmdoo//:/:-                         
///                         ``.oss/:////++://+o//:://+oo-:o++/shhhmmh+o+++///-`                        
///                           ..:+++oo/+///ys:///://+::-sy+osh+osdyo+o/::/s:/y-`                       
///                           `odoyhds+/yysyydss+///+/:+oshdmNo+:+/oo/+++++:hy//`                      
///                         `://hyoyy/o/++shhy:+y:/:o/+omNmhsoohhsso+++:+o+sy:/++                      
///                        -/---oddooss+oosy+ohNdo+++oyNhsdo/++shhhoo:s+oydmyo//o+                     
///                       :y.`.``yyd++shoyydhhyymdhyyhyhhs+////+/+s/+:odmmyso.:ohy.                    
///                      .yy/o-..+h/+o/+//++ssoohhhssso+++:/:/yy+//sydmNddo+/./ohy+.                   
///                      .dmmhs+osdoos///o//++/+shdsoshoys+ssss++shmNNNyyds+:-s-//:+.                  
///                      -shmNmyhddsyss++/+ysddhyyydhdmyssNddyydyhNmdNmddso/::s:--`.-.`                
///                     `+dmNhhdmddsooyyooossysshdhmoss+/+mNdyymydMdyMdyoo+/--/:/:`...-.`              
///                    .:smNNMmsMNNmdhyyo/yymmdmdyo+ooooshysyysNNNmmmNyss/+o-`-:-/:```.`` ```          
///                 `.-+o/sdNNNmhdddNmmdsso/sdshyyyyhsdddyohymdmNdmmmmmyoo+/.... -os.`.``-.``          
///               `/-:-/+.hymmmmdhmyNdMNmmhhs+sosoyhddyddmmho/ooymhddhdhyos-.oy..-:o+:..``  ````    `  
///             ..::``--.-hoymmdNNNNNNMmhyNh+oo+soyNdmNmmmysooooymhy+so++yo..:+.--`..:.`.` `-- ``.` `  
///          ```-.-.``..`:ddymmmNNdmNNNNmhN: -/oys/sdmmNdydsydmhhsmdso+/yo:/-..`.``.`  ``:.`.````-.   `
///        ````-:/.```:::syyydmddNhNNdsdMMs`./oddmd./odNdy+yssss++ooo/o+//-`:/:..:`-.```/-:.`.```..`` `
///   ```..-`` --.`.--o+sNhoyMmho+omhmo+Ns::dhdmmdy:.oNoyhhs+/o+o++s+hhoo+.`-:....``.-:-`..-````.-``.``


/// @title  Dollars Nakamoto by Pascal Boyart
/// @author jolan.eth
/// @notice This contract will allow you to yield farm Dollars Nakamoto NFT.
///     	During epoch 0 you will be able to mint a Genesis NFT,
///     	Over time, epoch will increment allowing you to mint more editions.
///     	Minting generations editions is allowed only 1 time per epoch and per Genesis NFT.
///  	    Generations editions do not allow you to mint other generations.
contract USDSat is USDSatMetadata, ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    string SYMBOL = "USDSat";
    string NAME = "Dollars Nakamoto";

    string ContractCID;

    /// @dev Ether shareholder addresses
    address public ADDRESS_PBOY = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;
    address public ADDRESS_JOLAN = 0x51BdFa2Cbb25591AF58b202aCdcdB33325a325c2;
    address public ADDRESS_CHARITY = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;
    
    /// @dev Equity per shareholder in %
    uint256 public SHARE_PBOY = 80;
    uint256 public SHARE_JOLAN = 10;
    uint256 public SHARE_CHARITY = 10;

    /// @dev Mapping used to represent allowed addresses to call { mintGenesis }
    mapping (address => bool) _allowList;

    /// @dev Epoch vars
    ///      epoch - Represent the current epoch
    ///      epochLen - Represent the block length of an epoch
    ///      epochMax - Represent the maximum epoch possible
    uint256 public epoch = 0;
    uint256 public epochMax = 10;
    uint256 public epochLen = 40320;

    /// @dev Index vars
    ///      tokenId - Index of the NFT start at 1 because var++
    ///      genesisId - Index of the Genesis NFT start at 0 because ++var
    ///      generationId - Index of the Generation NFT start at 0 because ++var
    uint256 public tokenId = 1;
    uint256 public genesisId = 0;
    uint256 public generationId = 0;

    /// @dev Supply vars
    ///      maxTokenSupply - Maximum supply allowed for the NFTs
    ///      maxGenesisSupply - Maximum supply allowed for the Genesis NFTs
    ///      maxGenerationSupply - Maximum supply allowed per epoch for Generation NFTs
    uint256 public maxTokenSupply = 2100;
    uint256 public maxGenesisSupply = 210;
    uint256 public maxGenerationSupply = 210;

    /// @dev Price vars
    ///      genesisPrice - Price of the Genesis NFT
    uint256 public genesisPrice = 0.5 ether;

    /// @dev Halving vars
    ///      blockOmega - Define the ending block
    ///      blockGenesis - Define the starting block
    ///      blockHalving - Define in which block the halving must occur
    ///      inflateRatio - Used to inflate blockHalving each epoch incrementation
    uint256 public blockOmega;
    uint256 public blockGenesis;
    uint256 public blockHalving;
    uint256 public inflateRatio = 2;

    /// @dev Mint vars
    ///      genesisMintAllowed - Open Genesis mint
    ///      generationMintAllowed - Open Generation mint
    bool public genesisMintAllowed = false;
    bool public generationMintAllowed = false;

    /// @dev Multi dimensionnal mapping to keep a track of the minting reentrancy over epoch
    mapping(uint256 => mapping(uint256 => bool)) public epochMintingRegistry;

    event PermanentURI();
    event URI(string _value);
    event Omega(uint256 _blockNumber);
    event Genesis(uint256 indexed _epoch, uint256 _blockNumber);
    event Halving(uint256 indexed _epoch, uint256 _blockNumber);
    event Withdraw(uint256 indexed _share, address _shareholder);
    event Shareholder(uint256 indexed _sharePercent, address _shareholder);
    event Securized(uint256 indexed _epoch, uint256 _epochLen, uint256 _blockHalving, uint256 _inflateRatio);
    event Minted(uint256 indexed _epoch, uint256 indexed _tokenId, address indexed _owner);
    event Signed(uint256 indexed _epoch, uint256 indexed _tokenId, uint256 indexed _blockNumber);

    constructor() ERC721(NAME, SYMBOL) {}

    // Withdraw functions *************************************************

    /// @notice Allow Pboy to modify ADDRESS_PBOY
    ///         This function is dedicated to the represented shareholder according to require().
    function setPboy(address PBOY)
    public {
        require(msg.sender == ADDRESS_PBOY, "error msg.sender");
        ADDRESS_PBOY = PBOY;
        emit Shareholder(SHARE_PBOY, ADDRESS_PBOY);
    }

    /// @notice Allow Jolan to modify ADDRESS_JOLAN
    ///         This function is dedicated to the represented shareholder according to require().
    function setJolan(address JOLAN)
    public {
        require(msg.sender == ADDRESS_JOLAN, "error msg.sender");
        ADDRESS_JOLAN = JOLAN;
        emit Shareholder(SHARE_JOLAN, ADDRESS_JOLAN);
    }

    /// @notice Allow Charity to modify ADDRESS_CHARITY
    ///         This function is dedicated to the represented shareholder according to require().
    function setCharity(address CHARITY)
    public {
        require(msg.sender == ADDRESS_CHARITY, "error msg.sender");
        ADDRESS_CHARITY = CHARITY;
        emit Shareholder(SHARE_CHARITY, ADDRESS_CHARITY);
    }

    /// @notice Used to withdraw ETH balance of the contract, this function is dedicated
    ///         to contract owner according to { onlyOwner } modifier.
    function withdrawEquity()
    public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        address[3] memory shareholders = [
            ADDRESS_PBOY,
            ADDRESS_JOLAN,
            ADDRESS_CHARITY
        ];

        uint256[3] memory _shares = [
            SHARE_PBOY * balance / 100,
            SHARE_JOLAN * balance / 100,
            SHARE_CHARITY * balance / 100
        ];

        uint i = 0;
        while (i < 3) {
            require(payable(shareholders[i]).send(_shares[i]));
            emit Withdraw(_shares[i], shareholders[i]);
            i++;
        }
    }

    // Epoch functions ****************************************************

    /// @notice Used to manage authorization and reentrancy of the genesis NFT mint
    /// @param  _genesisId Used to increment { genesisId } and write { epochMintingRegistry }
    function genesisController(uint256 _genesisId)
    private {
        require(epoch == 0, "error epoch");
        require(genesisId <= maxGenesisSupply, "error genesisId");
        require(!epochMintingRegistry[epoch][_genesisId], "error epochMintingRegistry");

        /// @dev Set { _genesisId } for { epoch } as true
        epochMintingRegistry[epoch][_genesisId] = true;

        /// @dev When { genesisId } reaches { maxGenesisSupply } the function
        ///      will compute the data to increment the epoch according
        ///
        ///      { blockGenesis } is set only once, at this time
        ///      { blockHalving } is set to { blockGenesis } because epoch=0
        ///      Then it is computed into the function epochRegulator()
        ///
        ///      Once the epoch is regulated, the new generation start
        ///      straight away, { generationMintAllowed } is set to true
        if (genesisId == maxGenesisSupply) {
            blockGenesis = block.number;
            blockHalving = blockGenesis;
            
            emit Genesis(epoch, blockGenesis);
            epochRegulator();
        }
    }

    /// @notice Used to manage authorization and reentrancy of the Generation NFT mint
    /// @param  _genesisId Used to write { epochMintingRegistry } and verify minting allowance
    function generationController(uint256 _genesisId)
    private {
        /// @dev If { block.number } > { blockHalving } the function
        ///      will compute the data to increment the epoch according
        ///
        ///      Once the epoch is regulated, the new generation start
        ///      straight away, { generationMintAllowed } is set to true
        ///
        ///      { generationId } is reset to 1
        if (block.number >= blockHalving) {
            epochRegulator();
            generationId = 1;
        }

        require(maxTokenSupply >= tokenId, "error maxTokenSupply");
        require(epoch > 0 && epoch < epochMax, "error epoch");
        require(ownerOf(_genesisId) == msg.sender, "error ownerOf");
        require(generationMintAllowed, "error generationMintAllowed");
        require(generationId <= maxGenerationSupply, "error generationId");
        require(epochMintingRegistry[0][_genesisId], "error epochMintingRegistry");
        require(!epochMintingRegistry[epoch][_genesisId], "error epochMintingRegistry");

        /// @dev Set { _genesisId } for { epoch } as true
        epochMintingRegistry[epoch][_genesisId] = true;

        /// @dev If { generationId } reaches { maxGenerationSupply } the modifier
        ///      will set { generationMintAllowed } to false to stop the mint
        ///      on this generation
        ///
        ///      { generationId } is reset to 1
        ///
        ///      This condition will not block the function because as long as
        ///      { block.number } > { blockHalving } minting will reopen
        ///      according and this condition will become obsolete until
        ///      the condition is reached again
        if (generationId == maxGenerationSupply) {
            generationMintAllowed = false;
            generationId = 1;
        }
    }

    /// @notice Used to protect epoch block length from difficulty bomb of the
    ///         Ethereum network. A difficulty bomb heavily increases the difficulty
    ///         on the network, likely also causing an increase in block time.
    ///         If the block time increases too much, the epoch generation could become
    ///         exponentially higher than what is desired, ending with an undesired Ice-Age.
    ///         To protect against this, the emergencySecure() function is allowed to
    ///         manually reconfigure the epoch block length and the block halving
    ///         to match the network conditions if necessary.
    ///
    ///         It can also be useful if the block time decreases for some reason with consensus change.
    ///
    ///         This function is dedicated to contract owner according to { onlyOwner } modifier
    function emergencySecure(uint256 _epoch, uint256 _epochLen, uint256 _blockHalving, uint256 _inflateRatio)
    public onlyOwner {
        require(_epoch > 0, "error _epoch");
        require(maxTokenSupply >= tokenId, "error maxTokenSupply");

        epoch = _epoch;
        epochLen = _epochLen;
        blockHalving = _blockHalving;
        inflateRatio = _inflateRatio;

        computeBlockOmega();
        emit Securized(epoch, epochLen, blockHalving, inflateRatio);
    }

    /// @notice Used to compute blockOmega() function, { blockOmega } represents
    ///         the block when it won't ever be possible to mint another Dollars Nakamoto NFT.
    ///         It is possible to be computed because of the deterministic state of the current protocol
    ///         The following algorithm simulate the 10 epochs of the protocol block computation to result blockOmega
    function computeBlockOmega()
    private {
        uint256 i = 0;
        uint256 _blockOmega = blockGenesis;
        uint256 _epochLen = epochLen;

        while (i < epochMax) {
            if (i > 0) _epochLen *= inflateRatio;
            _blockOmega += _epochLen;
            i++;
        }
        
        blockOmega = _blockOmega;
        emit Omega(blockOmega);
    }

    /// @notice Used to regulate the epoch incrementation and block computation, known as Halvings
    /// @dev When epoch=0, the { blockOmega } will be computed
    ///      When epoch!=0 the block length { epochLen } will be multiplied
    ///      by { inflateRatio } thus making the block length required for each
    ///      epoch longer according
    ///
    ///      { blockHalving } += { epochLen } result the exact block of the next halving
    ///      Allow generation mint after incrementing the epoch
    function epochRegulator()
    private {
        if (epoch == 0) computeBlockOmega();
        if (epoch > 0) epochLen *= inflateRatio;
        
        blockHalving += epochLen;
        emit Halving(epoch, blockHalving);

        epoch++;
        generationMintAllowed = true;
    }

    // Mint functions *****************************************************

    /// @notice Used to add/remove authorized address to use { mintGenesis }
    function setBatchGenesisAllowance(address[] memory batch)
    public onlyOwner {
        require(epoch == 0, "error epoch");
        require(!genesisMintAllowed, "error genesisMintAllowed");

        uint len = batch.length;
        require(len > 0, "error len");
        
        uint i = 0;
        while (i < len) {
            _allowList[batch[i]] = _allowList[batch[i]] ?
            false : true;
            i++;
        }
    }

    /// @notice Used to open the mint of Genesis NFT
    function setGenesisMint()
    public onlyOwner {
        genesisMintAllowed = true;
    }

    /// @notice Used to gift Genesis NFT, this function is dedicated
    ///         to contract owner according to { onlyOwner } modifier
    function giftGenesis(address to)
    public onlyOwner {
        genesisController(++genesisId);
        setMetadata(tokenId, genesisId, epoch);
        mintUSDSat(to, tokenId++);
    }

    /// @notice Used to mint Genesis NFT, this function is payable
    ///         the price of this function is equal to { genesisPrice },
    ///         require to be present on { _allowList } to call
    function mintGenesis() 
    public payable {
        genesisController(++genesisId);
        require(genesisMintAllowed, "error genesisMintAllowed");
        require(_allowList[msg.sender], "error allowList");
        require(genesisPrice == msg.value, "error genesisPrice");

        _allowList[msg.sender] = false;
        setMetadata(tokenId, genesisId, epoch);
        mintUSDSat(msg.sender, tokenId++);
    }

    /// @notice Used to gift Generation NFT, you need a Genesis NFT to call this function
    function giftGenerations(uint256 _genesisId, address to)
    public {
        ++generationId;
        generationController(_genesisId); 
        setMetadata(tokenId, generationId, epoch);
        mintUSDSat(to, tokenId++);
    }

    /// @notice Used to mint Generation NFT, you need a Genesis NFT to call this function
    function mintGenerations(uint256 _genesisId)
    public {
        ++generationId;
        generationController(_genesisId);
        setMetadata(tokenId, generationId, epoch);
        mintUSDSat(msg.sender, tokenId++);
    }

    /// @notice Used to set { TokenURIs } of the { _tokenId } and compute
    ///         the mint with _safeMint() function from ERC721 standard,
    ///         this function is private and can be only called by the
    ///         contract
    function mintUSDSat(address to, uint256 _tokenId)
    private {
        /// @notice Token is minted on { ADDRESS_PBOY } and instantly transferred to { msg.sender } as { to },
        ///         this is to ensure the token creation is signed with { ADDRESS_PBOY }
        _safeMint(ADDRESS_PBOY, _tokenId);
        emit Signed(epoch, _tokenId, block.number);
        _safeTransfer(ADDRESS_PBOY, to, _tokenId, "");
        emit Minted(epoch, _tokenId, to);
    }

    // Contract URI functions *********************************************

    /// @notice Used to set the { ContractCID } metadata from ipfs,
    ///         this function is dedicated to contract owner according
    ///         to { onlyOwner } modifier
    function setContractCID(string memory CID)
    public onlyOwner {
        ContractCID = string(abi.encodePacked("ipfs://", CID));
    }

    /// @notice Used to render { ContractCID } as { contractURI } according to
    ///         Opensea contract metadata standard
    function contractURI()
    public view virtual returns (string memory) {
        return ContractCID;
    }

    // Utilitaries functions **********************************************

    /// @notice Used to fetch all entry for { epoch } into { epochMintingRegistry } 
    function getMapRegisteryForEpoch(uint256 _epoch)
    public view returns (bool[210] memory result) {
        uint i = 0;
        while (i < 210) {
            result[i] = epochMintingRegistry[_epoch][i];
            i++;
        }
    }
    
    /// @notice Used to fetch all { tokenIds } from { owner }
    function exposeHeldIds(address owner)
    public view returns(uint[] memory) {
        uint tokenCount = balanceOf(owner);
        uint[] memory tokenIds = new uint[](tokenCount);

        uint i = 0;
        while (i < tokenCount) { 
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
            i++;
        }
        return tokenIds;
    }

    // ERC721 Spec functions **********************************************

    /// @notice Used to render metadata as { tokenURI } according to ERC721 standard
    function tokenURI(uint256 _tokenId)
    public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _compileMetadata(_tokenId);
    }

    /// @dev ERC721 required override
    function _beforeTokenTransfer(address from, address to, uint256 _tokenId)
    internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    /// @dev ERC721 required override
    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}