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

    /// @notice Address used to sign NFT on mint
    address public ADDRESS_SIGN = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;

    /// @notice Ether shareholder address
    address public ADDRESS_PBOY = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;
    /// @notice Ether shareholder address
    address public ADDRESS_JOLAN = 0x51BdFa2Cbb25591AF58b202aCdcdB33325a325c2;
    
    /// @notice Equity per shareholder in %
    uint256 public SHARE_PBOY = 90;
    /// @notice Equity per shareholder in %
    uint256 public SHARE_JOLAN = 10;

    /// @notice Mapping used to represent allowed addresses to call { mintGenesis }
    mapping (address => bool) public _allowList;

    /// @notice Represent the current epoch
    uint256 public epoch = 0;

    /// @notice Represent the maximum epoch possible
    uint256 public epochMax = 10; // 10
    
    /// @notice Represent the block length of an epoch
    uint256 public epochLen = 1; // 40320

    /// @notice Index of the NFT
    /// @dev    Start at 1 because var++
    uint256 public tokenId = 1;

    /// @notice Index of the Genesis NFT
    /// @dev    Start at 0 because ++var
    uint256 public genesisId = 0;

    /// @notice Index of the Generation NFT
    /// @dev    Start at 0 because ++var
    uint256 public generationId = 0;

    /// @notice Maximum total supply
    uint256 public maxTokenSupply = 50; // 2100

    /// @notice Maximum Genesis supply
    uint256 public maxGenesisSupply = 5; // 210

    /// @notice Maximum supply per generation
    uint256 public maxGenerationSupply = 5; // 210

    /// @notice Price of the Genesis NFT (Generations NFT are free)
    uint256 public genesisPrice = 0.01 ether; // 0.5 ether

    /// @notice Define the ending block
    uint256 public blockOmega;

    /// @notice Define the starting block
    uint256 public blockGenesis;

    /// @notice Define in which block the Meta must occur
    uint256 public blockMeta;

    /// @notice Used to inflate blockMeta each epoch incrementation
    uint256 public inflateRatio = 2;

    /// @notice Open Genesis mint when true
    bool public genesisMintAllowed = false;

    /// @notice Open Generation mint when true
    bool public generationMintAllowed = false;

    /// @notice Multi dimensionnal mapping to keep a track of the minting reentrancy over epoch
    mapping(uint256 => mapping(uint256 => bool)) public epochMintingRegistry;

    event Omega(uint256 _blockNumber);
    event Genesis(uint256 indexed _epoch, uint256 _blockNumber);
    event Meta(uint256 indexed _epoch, uint256 _blockNumber);
    
    event Withdraw(uint256 indexed _share, address _shareholder);
    event Shareholder(uint256 indexed _sharePercent, address _shareholder);
    
    event Securized(uint256 indexed _epoch, uint256 _epochLen, uint256 _blockMeta, uint256 _inflateRatio);

    event PermanentURI(string _value, uint256 indexed _id);
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

    /// @notice Used to withdraw ETH balance of the contract, this function is dedicated
    ///         to contract owner according to { onlyOwner } modifier.
    function withdrawEquity()
    public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        address[2] memory shareholders = [
            ADDRESS_PBOY,
            ADDRESS_JOLAN
        ];

        uint256[2] memory _shares = [
            SHARE_PBOY * balance / 100,
            SHARE_JOLAN * balance / 100
        ];

        uint i = 0;
        while (i < 2) {
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
        ///      { blockMeta } is set to { blockGenesis } because epoch=0
        ///      Then it is computed into the function epochRegulator()
        ///
        ///      Once the epoch is regulated, the new generation start
        ///      straight away, { generationMintAllowed } is set to true
        if (genesisId == maxGenesisSupply) {
            blockGenesis = block.number;
            blockMeta = blockGenesis;
            
            emit Genesis(epoch, blockGenesis);
            epochRegulator();
        }
    }

    /// @notice Used to manage authorization and reentrancy of the Generation NFT mint
    /// @param  _genesisId Used to write { epochMintingRegistry } and verify minting allowance
    function generationController(uint256 _genesisId)
    private {
        /// @dev If { block.number } > { blockMeta } the function
        ///      will compute the data to increment the epoch according
        ///
        ///      Once the epoch is regulated, the new generation start
        ///      straight away, { generationMintAllowed } is set to true
        ///
        ///      { generationId } is reset to 1
        if (block.number >= blockMeta) {
            epochRegulator();
            generationId = 1;
        }

        /// @dev Be sure the mint is open if condition are favorable
        if (block.number <= blockMeta && generationId <= maxGenerationSupply) {
            generationMintAllowed = true;
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
        ///      { generationId } is reset to 0
        ///
        ///      This condition will not block the function because as long as
        ///      { block.number } > { blockMeta } minting will reopen
        ///      according and this condition will become obsolete until
        ///      the condition is reached again
        if (generationId == maxGenerationSupply) {
            generationMintAllowed = false;
            generationId = 0;
        }
    }

    /// @notice Used to protect epoch block length from difficulty bomb of the
    ///         Ethereum network. A difficulty bomb heavily increases the difficulty
    ///         on the network, likely also causing an increase in block time.
    ///         If the block time increases too much, the epoch generation could become
    ///         exponentially higher than what is desired, ending with an undesired Ice-Age.
    ///         To protect against this, the emergencySecure() function is allowed to
    ///         manually reconfigure the epoch block length and the block Meta
    ///         to match the network conditions if necessary.
    ///
    ///         It can also be useful if the block time decreases for some reason with consensus change.
    ///
    ///         This function is dedicated to contract owner according to { onlyOwner } modifier
    function emergencySecure(uint256 _epoch, uint256 _epochLen, uint256 _blockMeta, uint256 _inflateRatio)
    public onlyOwner {
        require(epoch > 0, "error epoch");
        require(_epoch > 0, "error _epoch");
        require(maxTokenSupply >= tokenId, "error maxTokenSupply");

        epoch = _epoch;
        epochLen = _epochLen;
        blockMeta = _blockMeta;
        inflateRatio = _inflateRatio;

        computeBlockOmega();
        emit Securized(epoch, epochLen, blockMeta, inflateRatio);
    }

    /// @notice Used to compute blockOmega() function, { blockOmega } represents
    ///         the block when it won't ever be possible to mint another Dollars Nakamoto NFT.
    ///         It is possible to be computed because of the deterministic state of the current protocol
    ///         The following algorithm simulate the 10 epochs of the protocol block computation to result blockOmega
    function computeBlockOmega()
    private {
        uint256 i = 0;
        uint256 _blockMeta = 0;
        uint256 _epochLen = epochLen;

        while (i < epochMax) {
            if (i > 0) _epochLen *= inflateRatio;
            if (i == 9) {
                blockOmega = blockGenesis + _blockMeta;
                emit Omega(blockOmega);
                break;
            }
            _blockMeta += _epochLen;
            i++;
        }
    }

    /// @notice Used to regulate the epoch incrementation and block computation, known as Metas
    /// @dev When epoch=0, the { blockOmega } will be computed
    ///      When epoch!=0 the block length { epochLen } will be multiplied
    ///      by { inflateRatio } thus making the block length required for each
    ///      epoch longer according
    ///
    ///      { blockMeta } += { epochLen } result the exact block of the next Meta
    ///      Allow generation mint after incrementing the epoch
    function epochRegulator()
    private {
        if (epoch == 0) computeBlockOmega();
        if (epoch > 0) epochLen *= inflateRatio;
        
        blockMeta += epochLen;
        emit Meta(epoch, blockMeta);

        epoch++;

        if (block.number > blockMeta && epoch < epochMax) {
            epochRegulator();
        }
        
        generationMintAllowed = true;
    }

    // Mint functions *****************************************************

    /// @notice Used to add/remove address from { _allowList }
    function setBatchGenesisAllowance(address[] memory batch)
    public onlyOwner {
        uint len = batch.length;
        require(len > 0, "error len");
        
        uint i = 0;
        while (i < len) {
            _allowList[batch[i]] = _allowList[batch[i]] ?
            false : true;
            i++;
        }
    }

    /// @notice Used to transfer { _allowList } slot to another address
    function transferListSlot(address to)
    public {
        require(epoch == 0, "error epoch");
        require(_allowList[msg.sender], "error msg.sender");
        require(!_allowList[to], "error to");
        _allowList[msg.sender] = false;
        _allowList[to] = true;
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

    /// @notice Token is minted on { ADDRESS_SIGN } and instantly transferred to { msg.sender } as { to },
    ///         this is to ensure the token creation is signed with { ADDRESS_SIGN }
    ///         This function is private and can be only called by the contract
    function mintUSDSat(address to, uint256 _tokenId)
    private {
        emit PermanentURI(_compileMetadata(_tokenId), _tokenId);
        _safeMint(ADDRESS_SIGN, _tokenId);
        emit Signed(epoch, _tokenId, block.number);
        _safeTransfer(ADDRESS_SIGN, to, _tokenId, "");
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
    public view returns (bool[] memory result) {
        uint i = 1;
        while (i <= maxGenesisSupply) {
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