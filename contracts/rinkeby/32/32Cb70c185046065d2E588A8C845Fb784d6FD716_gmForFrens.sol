//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GMSVG.sol";

//gm fren, this is my very first solidity contract. i have no idea what i am doing. dyor wagmi !vibe
//v22
contract gmForFrens is ERC721Enumerable, ReentrancyGuard, Ownable, IERC2981  { 

    using Strings for uint256;  

	uint256 public constant MAX_GMDOT_COUNT = 900;
    uint256 public constant MAX_INFOT_COUNT = 90;
    uint256 public constant MAX_PFP_COUNT = 500;
    uint256 public constant MAX_COUNT = 6900;
	bytes32 private constant GM = keccak256(abi.encodePacked("gm"));

    uint256 public GMDOT_COUNT = 0;
    uint256 public PFP_COUNT = 0;
    uint256 public INFOT_COUNT = 0;
    uint256 public COUNT = 0;

	uint256 public OFFSET_INDEX = 0;

	uint256 public BURN_COUNT = 0;
	uint256 public BURN_SALDO = 0;
	uint256 public BURN_INDEX = 10000;

    bool public MINT_STARTED;
    string private BASE_SEED = "gmBetaTest2";

	GMSVG private 	SVG_RENDER = new GMSVG();
    //OwnerInterface private PFP_CONTRACT = OwnerInterface(0x75c3B1035B1898dc96C22481f886A80aDFd69c7a);
    //OwnerInterface private PFP_CONTRACT = OwnerInterface(0x1932FE0E67bA08BD5ca05AB2C1daBB5964B1da90);
    IERC721 private PFP_CONTRACT = IERC721(0x1932FE0E67bA08BD5ca05AB2C1daBB5964B1da90);
    //BalanceInterface private RARIBLE_CONTRACT = BalanceInterface(0xd07dc4262BCDbf85190C01c996b4C06a461d2430);
    IERC1155 private RARIBLE_CONTRACT = IERC1155(0xeE45B41D1aC24E9a620169994DEb22739F64f231);

    mapping (address => uint256) private INFOT_CLAIMS;
    mapping (address => uint256) private MNT_CLAIMS;
    mapping (address => uint256) private GMDOT_CLAIMS;
    mapping (uint256 => uint256) private PFP_CLAIMS;
    
    mapping (uint256 => uint256) private GMFF_REROLLS;
    mapping (uint256 => uint256) private GMFF_SALT;
    
    constructor() ERC721("gm (for frens)", "gmFF") Ownable() {}
      
    /****************** CLAIMS *********************/
    function claim(uint256 tokenId, string calldata gm) external nonReentrant {
        _claim(tokenId, gm);
    }
    
    /*unction claimMultiple(uint256[] memory tokenIds) external payable nonReentrant {
        require(msg.value >= 10000000 gwei, 'fee');
        require(tokenIds.length <= 5, 'nah');
        require(MNT_CLAIMS[_msgSender()]+tokenIds.length <= 20, "greed is bad"); //TESTING CONST
        require(COUNT+tokenIds.length < MAX_COUNT, "gn!");
        
        MNT_CLAIMS[_msgSender()]=MNT_CLAIMS[_msgSender()]+tokenIds.length;
        COUNT=COUNT+tokenIds.length;
        
        for(uint i=0; i<tokenIds.length; i++)
        {
            _safeMint(_msgSender(), tokenIds[i]);
            setGMSalt(tokenIds[i]);
        }
    }*/
 
    // be kind do good
    function claimWithPostcard(uint256 pfpTokenId, string calldata gm) external nonReentrant {
        //require(PFP_CONTRACT.ownerOf(pfpTokenId) == msg.sender, "not kind");
        require(PFP_CLAIMS[pfpTokenId] <= 20, "greed is bad"); //TESTING CONST
        require(PFP_COUNT < MAX_PFP_COUNT, "too late, gn");

        mintGM((MAX_COUNT - MAX_PFP_COUNT) + PFP_COUNT, gm);
        PFP_CLAIMS[pfpTokenId] = 1;
        PFP_COUNT++;
    }

    // play fair please
    function claimWithInfo(string calldata gm) external nonReentrant {
        //require(RARIBLE_CONTRACT.balanceOf(_msgSender(), 747508) > 0 || RARIBLE_CONTRACT.balanceOf(_msgSender(), 752414) > 0, "no alpha.");
        require(INFOT_CLAIMS[_msgSender()] <= 20, "greed is bad"); //TESTING CONST
        require(INFOT_COUNT <= MAX_INFOT_COUNT, "too late, gn");

        mintGM(1 + INFOT_COUNT, gm);
        INFOT_CLAIMS[_msgSender()]++;
        INFOT_COUNT++;
    }

    // play fair please
    function claimWithGM(string calldata gm) external nonReentrant {
        //require(RARIBLE_CONTRACT.balanceOf(_msgSender(), 706480) > 0, "no gm.");
        require(GMDOT_CLAIMS[_msgSender()] <= 20, "greed is bad");//TESTING CONST
        require(GMDOT_COUNT <= MAX_GMDOT_COUNT, "too late, gn");

        mintGM(1 + MAX_INFOT_COUNT + GMDOT_COUNT, gm);
        GMDOT_CLAIMS[_msgSender()]++;
        GMDOT_COUNT++;
    }
    
     /****************** REROLL/RUG *********************/
    function rugroll(string calldata prompt) external nonReentrant {
        require(balanceOf(msg.sender) >=21, "no steak here");
        require(OFFSET_INDEX == 0, "already rugrolled");
        require(COUNT >= MAX_COUNT, "can not rug untill all minted");

        OFFSET_INDEX = random(prompt) % (MAX_COUNT);
    }
    
    function unrugroll() external nonReentrant {
        require(ownerOf(0) == msg.sender && msg.sender != owner(), 'noo');
        require(OFFSET_INDEX != 0, "not yet rugrolled");

        _burn(0);
        _safeMint(ownerOf(OFFSET_INDEX), 0);
        setGMSalt(0);
        OFFSET_INDEX = 0;
    }
    
    function reroll(uint256 gmIdToBurn, uint256 gmIdToReroll) external nonReentrant {
		require(ownerOf(gmIdToReroll) == msg.sender, "noo");
		require(ownerOf(gmIdToBurn) == msg.sender, "noo");
		require(gmIdToReroll <= MAX_COUNT);
		
		BURN_SALDO++;
		_burn(gmIdToBurn);
		_reroll(gmIdToReroll);
	}

	function unburn() external payable nonReentrant {
		require(BURN_SALDO > 0);
		BURN_SALDO--;
		BURN_INDEX++;

		_safeMint(msg.sender, BURN_INDEX);
		setGMSalt(BURN_INDEX);
	}
    
    /****************** OWNER *********************/
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);                
    }
    
    function selfdestructContractTestNet(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }
    
	function startMinting() external onlyOwner {
		require(MINT_STARTED == false);

		MINT_STARTED = true;
		BASE_SEED = random(block.difficulty.toString()).toString();
		_safeMint(_msgSender(), 0);
		setGMSalt(0);
	}
    
    /****************** TOKEN *********************/
    function tokenURI(uint256 tokenId) 
	override public view returns (string memory) {

        uint256 trueId = uint256(keccak256(abi.encodePacked((tokenId + OFFSET_INDEX) % (MAX_COUNT), BASE_SEED, GMFF_SALT[tokenId], GMFF_REROLLS[tokenId])));
        
        return SVG_RENDER.renderSVG(trueId, SVG_RENDER.getGMType(tokenId, MAX_INFOT_COUNT, MAX_GMDOT_COUNT, MAX_PFP_COUNT, MAX_COUNT));
    }
    
	// solhint-disable-next-line
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) { // solhint-disable-line

        return (0xDf5B0E3887Ec6cb55C261d4bc051de8dbF7d8650,_salePrice/10);
    }
    
    function _reroll(uint256 gmIdToReroll) private {
        GMFF_REROLLS[gmIdToReroll]++;
        setGMSalt(gmIdToReroll*(GMFF_REROLLS[gmIdToReroll] + gmIdToReroll));
    }
    
    function _claim(uint256 tokenId, string memory gm) private{
        require(tokenId > 1 + MAX_INFOT_COUNT + MAX_GMDOT_COUNT && tokenId < (MAX_COUNT - MAX_PFP_COUNT), "nope");
        require(MNT_CLAIMS[_msgSender()] <= 20, "greed is bad"); //TESTING CONST

        mintGM(tokenId, gm);
        MNT_CLAIMS[_msgSender()]++;
    }
    
    function mintGM(uint256 tokenId, string memory gm) private {
        require(COUNT < MAX_COUNT, "gn!");
        require(keccak256(abi.encodePacked(gm)) == GM, ":(");

        _safeMint(_msgSender(), tokenId);
        setGMSalt(tokenId);
        COUNT++;
    }

    function setGMSalt(uint256 gmId) private {
        GMFF_SALT[gmId] = random(string(abi.encodePacked(msg.sender, gmId)));
    }
    
    function random(string memory input) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, input, block.difficulty)));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/HSLColor.sol";
import "./libs/Base64.sol";
import "./libs/SeedRandom.sol";

//v15

library Metadata {
    enum META { RANKING, PROPERTY, BOOSTP, BOOSTN, STATS }
    
    function generateOSMetaTag(META mtype, string memory metaName, string memory value) 
	internal pure returns (string memory) {

        if(mtype == META.STATS)
            return string(abi.encodePacked('{"display_type": "number", "trait_type": "',metaName,'", "value": ',value,' }'));
        else if(mtype == META.BOOSTP)
            return string(abi.encodePacked('{"display_type": "boost_percentage", "trait_type": "',metaName,'", "value": ',value,' }'));
        else if(mtype == META.BOOSTN)
            return string(abi.encodePacked('{"display_type": "boost_number", "trait_type": "',metaName,'", "value": ',value,' }'));
        else if(mtype == META.PROPERTY)
            return string(abi.encodePacked('{"trait_type": "',metaName,'", "value": "',value,'" }'));
        //else if(mtype == META.RANKING)
        return string(abi.encodePacked('{"trait_type": "',metaName,'", "value": ',value,' }'));
    }

	function combineOSMetaTags(string memory a1, string memory a2)
	internal pure returns (string memory) {

		return string(abi.encodePacked(a1,', ', a2));
	}

	function combineOSMetaTags_Relay(string memory added, string memory attributes)
	internal pure returns (string memory) {
		
		attributes = combineOSMetaTags(attributes, added);
		return added;
	}
}

library GMSVGUtils {
	    
	enum TTYPE {GMDOT, INFOT, PFP, MNT}

	function pickColor(uint256 baseSeed, uint256 it, uint256[4] memory schemeRange)
	internal pure returns (uint256){
		return HSLColor.getColorValue(baseSeed, it, schemeRange[SeedRandom.makeSeedChoice(baseSeed, string(abi.encodePacked('colrangesche2', it)), 4)], 12);
	}

	function makeEncoding(string[20] memory parts) internal pure returns (string memory) {
        string memory result = "";
        
        for(uint i=0; i<parts.length; i++)
            result = string(abi.encodePacked(result, parts[i]));
        
        return result;
    }

    function encapsuleSVG(string[5] memory parts) internal pure returns (string memory){
        return Base64.encode(bytes(string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1000 1000">',parts[0], parts[1], parts[2], parts[3], parts[4],'</svg>'))));
    }
    
    function buildToken(string memory base64SVG, string memory metadata) internal pure returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{',metadata,', "image": "data:image/svg+xml;base64,',base64SVG,'"}'))))));
    }
    
	function getGMType(uint256 tokenId, 
		uint256 MAX_INFOT_COUNT, uint256 MAX_GMDOT_COUNT, uint256 MAX_PFP_COUNT, uint256 MAX_COUNT) 
	internal pure returns (TTYPE) {
        
		if(tokenId <= MAX_INFOT_COUNT)
			return TTYPE.INFOT; 
        else if(tokenId <= MAX_INFOT_COUNT + MAX_GMDOT_COUNT)
			return TTYPE.GMDOT; 
        else if( tokenId >= MAX_COUNT - MAX_PFP_COUNT)
            return TTYPE.PFP;
		return TTYPE.MNT;
	}

	function getGMWord(uint256 trueId, TTYPE gmt) 
	internal pure returns (string memory) {

		return gmt == TTYPE.GMDOT ? 'gm.' : [
            'gm',
            'gmi',
            'frens',
            'wagmi',
            '6529',
            'ser'
        ][SeedRandom.makeSeedChoice(trueId, 'saypls', 0, 6, 79)];
	}

	function getBorderMode(uint256 trueId) 
	internal pure returns (string memory){

        return [
            'normal',
            'color-burn',
            'difference',
            'lighten',
            'luminosity',
            'multiply',
            'soft-light'
        ][SeedRandom.makeSeedChoice(trueId, 'border', 0, 7, 2)];	 
	}
}

contract GMSVG {
    using Strings for uint256;  

    function renderSVGBorder(uint256 baseSeed) private pure returns (string memory) {
        return string(abi.encodePacked('<rect id="bd" xmlns="http://www.w3.org/2000/svg" width="1020" height="1020" x="-10" y="-10" ry="50" rx="50" fill="',HSLColor.generateColorHSL(baseSeed, 69, 0, 10, 90, 98),'" style="stroke-width:',SeedRandom.makeSeedChoiceAsString(baseSeed,'bordw', 45, 65, 0),'; stroke:',HSLColor.generateColorHSL(baseSeed, 42, 0, 5, 5, 20),'"/>'));
    }
    
    function renderSVGFilter(uint256 baseSeed) private pure returns (string memory) {
        return string(abi.encodePacked('<filter color-interpolation-filters="sRGB" x="-1000px" y="-1000px" width="2000px" height="2000px" id="col"><feGaussianBlur stdDeviation="', (175 + SeedRandom.makeSeedChoice(baseSeed,'gausstd',0,6,0) * 25).toString(),'"></feGaussianBlur><feColorMatrix type="matrix" values="0.95 0 0 0 0.05 0 0.925 0 0 0.075 0 0 0.9 0 0.1 0 0 0 0.95 0"></feColorMatrix></filter>'));
    }
    
    function renderSVGSubAnimValues(uint256 values, uint256 ver) private pure returns (string memory) {
        return ver%2 == 0 ? string(abi.encodePacked('0;',values.toString(),';0;-',(values/2).toString(),';0')) : string(abi.encodePacked('0;-',(values/2).toString(),';0;',values.toString(),';0'));
    }
    
    function renderSubSVGGroup(string memory id, string memory cl, string memory input) private pure returns (string memory){
        return string(abi.encodePacked('<g id="',id,'" class="',cl,'">', input, '</g>'));
    }
    
    function renderSVGAnimations(uint256 baseSeed, uint256 count, string[2] memory animAttribute) 
	private pure returns (string memory) {
        string[20] memory sparts;
        uint8[2][3] memory speeds = [[25, 75], [5, 15], [60, 180]];
        uint256 speedPick = SeedRandom.makeSeedChoice(baseSeed,'anims',3);

        for(uint256 it = 0; it < count; it++){
            sparts[it] = string(abi.encodePacked('<animate href="#r',(it+1).toString(),'" attributeName="',animAttribute[SeedRandom.makeSeedChoice(baseSeed+it,'anima',2)],'" values="',renderSVGSubAnimValues(SeedRandom.makeSeedChoice(baseSeed+it, 'animv', 1005, 2010, 0), it),'" dur="', SeedRandom.makeSeedChoiceAsString(baseSeed+it, 'animd', speeds[speedPick][0], speeds[speedPick][1], 0) ,'s" repeatCount="indefinite"></animate>'));
        }
        
        return GMSVGUtils.makeEncoding(sparts);
    } 
    


    function renderSubSVGCirc(uint256 baseSeed, uint256 count, GMSVGUtils.TTYPE gmt, HSLColor.CTYPE scheme, string memory attributes) 
	private pure returns (string memory, string memory){

        string[20] memory sparts;
		attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Color Scheme", HSLColor.getSchemeName(scheme)));
		uint256 centerpick = SeedRandom.makeSeedChoice(baseSeed, 'colrangesche', 12);
		attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Root Color", HSLColor.getColorName(centerpick)));
        uint256[4] memory schemeRange = HSLColor.getColorValueRange(scheme, centerpick);
        
        for(uint256 it = 0; it < count; it++)
        {
            uint256 colorhsl = GMSVGUtils.pickColor(baseSeed, it, schemeRange);
            string memory hsl = gmt == GMSVGUtils.TTYPE.INFOT || SeedRandom.makeSeedChoice(baseSeed, 'colspecial', 28) == 0?  it%2 == 0 ? HSLColor.generateColorHSL(baseSeed, it, 99, 100, 38, 60, colorhsl):HSLColor.generateColorHSL(baseSeed, it-1, 99, 100, 70, 95, colorhsl) : it%2 == 0 ? HSLColor.generateColorHSL(baseSeed, it, 99, 100, 60, 75, colorhsl):HSLColor.generateColorHSL(baseSeed, it-1, 99, 100, 80, 90, colorhsl);
            sparts[it] = generateForm(FORM.CIRCLE, baseSeed, it, hsl);
        }
        
        return (GMSVGUtils.makeEncoding(sparts), attributes);
    }

	enum FORM {CIRCLE, RECT, BLOB }
	
	function generateForm(FORM form, uint256 baseSeed, uint it, string memory hsl) 
	private pure returns (string memory) {
		if(form == FORM.CIRCLE) {
		return string(abi.encodePacked(
			'<circle id="r',(it+1).toString(),
			'" cy="', SeedRandom.makeSeedChoiceAsString(baseSeed+it,'circy', 250, 752, 0) ,
			'" cx="', SeedRandom.makeSeedChoiceAsString(baseSeed+it,'circx', 250, 753, 0) ,
			'" r="', SeedRandom.makeSeedChoiceAsString(baseSeed+it,'circr', 375, 750, 0) ,
			'" fill="',hsl,
			'" filter="url(#col)"></circle>'));
		}
		return "";
	}
    
    function renderSubSVGText(uint256 baseSeed, uint256 count, string memory insert) private pure returns (string memory){
        uint256[6] memory pPosition = [uint256(200), uint256(100), uint256(150), uint256(900), uint256(800), uint256(1000)];
        string[3] memory pClasses = ["b", "m", "s"];
        string[20] memory sparts;
        uint256 txtClassIndex = 0;
		string memory classBlend;
        
        for(uint256 it = 0; it < count; it++)
        {
            txtClassIndex = SeedRandom.makeSeedChoice(baseSeed+it,'txtc', 0, 3, 0);
			classBlend = ['overlay','soft-light'][SeedRandom.makeSeedChoice(baseSeed+it,'blendgm', 0, 2, 0)];
            sparts[it] = string(abi.encodePacked('<text id="t',(it+1).toString(),'" x="', SeedRandom.makeSeedChoiceAsString(baseSeed+it,'txtx', pPosition[txtClassIndex]-100, pPosition[txtClassIndex+3]-100, 0) ,'" y="', SeedRandom.makeSeedChoiceAsString(baseSeed+it,'txty', pPosition[txtClassIndex], pPosition[txtClassIndex+3], 0) ,'" class="', pClasses[txtClassIndex],'" style="mix-blend-mode:', classBlend , '">',insert,'</text>'));
        }
        
        return GMSVGUtils.makeEncoding(sparts);
    }

	function generateSVGClass(uint256 baseSeed, uint256 it, string memory attributes, bool setAttribute) 
	private pure returns (string memory, string memory){

		string memory fonts = ['cursive', 'serif', 'sans-serif', 'monospace', 'fantasy' ][SeedRandom.makeSeedChoice(baseSeed, 'clsfont', 0, 4,3)];
		string memory fStyle = ['normal', 'italic'][SeedRandom.makeSeedChoice(baseSeed,'fstyle', 0, 2, 2)];
		string memory fWeight = ['normal', 'bold'][SeedRandom.makeSeedChoice(baseSeed,'fweight', 0, 2, 2)];
        string memory fSize = [[ '175', '300', '350', '425', '485', '550', '700'  ], [  '50',  '125',  '250',  '300', '400', '450', '900' ], [  '10',  '20', '30',  '45', '60',  '75', '150' ]][it][SeedRandom.makeSeedChoice(baseSeed+it, 'clsfsize', 0, 7, 0)];

		if(setAttribute == true) {
			attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Font Family", fonts));
			attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Font Style", fStyle));
			attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Font Weight", fWeight));
		}

		return (string(abi.encodePacked(
			'{font-size:', fSize, 'px',
			';opacity:0.', SeedRandom.makeSeedChoiceAsString(baseSeed+it,'clsopac', 35, 75, 0),
			';fill:black',
			';font-family:', fonts,
			';font-style:', fStyle,
			';font-weight:', fWeight,
			';}')),
			attributes);
	}
    
    function renderSubSVGClasses(uint256 baseSeed, string memory attributes) private pure returns (string memory, string memory){
        string[3] memory pClasses = ["b", "m", "s"];
        string[4] memory sparts;
        
        string memory blendMode = ['normal', 'hard-light', 'multiply', 'lighten', 'color', 'overlay', 'exclusion', 'difference' ][SeedRandom.makeSeedChoice(baseSeed,'clscmix', 0, 8, 4)];
        string memory filter = ['none','invert(100%)'][SeedRandom.makeSeedChoice(baseSeed,'invall', 0, 2, 139)];

		attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Circle Blend", blendMode));
		if(keccak256(abi.encodePacked(filter)) != keccak256(abi.encodePacked('none')) )
			attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Inversion", "True"));

		string memory svgClass = "";
        for(uint256 it = 0; it < 3; it++) {
            (svgClass, attributes) = generateSVGClass(baseSeed, it, attributes, it==0? true: false);
			sparts[it] = string(abi.encodePacked('.',pClasses[it], svgClass));
		}

        sparts[3] = string(abi.encodePacked('circle{mix-blend-mode:',blendMode,';}.in{filter:',filter,';}'));
        
        return (string(abi.encodePacked('<style>',sparts[0], sparts[1], sparts[2], sparts[3],'</style>')), attributes);
    }

	function getGMType(uint256 tokenId, 
		uint256 MAX_INFOT_COUNT, uint256 MAX_GMDOT_COUNT, uint256 MAX_PFP_COUNT, uint256 MAX_COUNT) 
	external pure returns (GMSVGUtils.TTYPE) {
        
		return GMSVGUtils.getGMType(tokenId, MAX_INFOT_COUNT, MAX_GMDOT_COUNT, MAX_PFP_COUNT, MAX_COUNT); 
	}

	//solhint-disable line
	function renderSVG(uint256 trueId, GMSVGUtils.TTYPE gmt) 
	external pure returns (string memory) {
		string[5] memory parts;
        //HSLColor.CTYPE mainScheme = HSLColor.getColorScheme(trueId, "mainScheme");
		string memory word = GMSVGUtils.getGMWord(trueId, gmt);
        string memory attributes = Metadata.generateOSMetaTag(Metadata.META.PROPERTY, "Glyphs", word);
        parts[4] = string(abi.encodePacked('<use href="#bd" fill-opacity="0" style="mix-blend-mode:', GMSVGUtils.getBorderMode(trueId),'"/>'));// filter="url(#col)"/>';
        parts[3] = renderSubSVGGroup('tex','in',renderSubSVGText(trueId, SeedRandom.makeSeedChoice(trueId, 'txtN', 3, gmt == GMSVGUtils.TTYPE.GMDOT ? 10 : 8, 0), word));
        (parts[1], attributes) = renderSubSVGClasses(trueId, attributes);
        
        uint256 countC = SeedRandom.makeSeedChoice(trueId, 'circN', 4, 9, 0);
        attributes = Metadata.combineOSMetaTags(attributes, Metadata.generateOSMetaTag(Metadata.META.STATS, "word count", countC.toString()));
        parts[0] = string(abi.encodePacked(renderSVGBorder(trueId), '<defs>', renderSVGFilter(trueId), renderSVGAnimations(trueId, countC, ['cx','cy']), '</defs>'));
        (parts[2], attributes) = renderSubSVGCirc(trueId, countC, gmt, HSLColor.getColorScheme(trueId, "mainScheme"), attributes);
        
        //attributes = string(abi.encodePacked(attributes, GMSVG.generateOSMetaTag(META.PROPERTY, "Word",words[SeedRandom.makeSeedChoice(trueId, 'saypls', 0, 6, 79))));
        //attributes = string(abi.encodePacked(attributes, ));

        return GMSVGUtils.buildToken(GMSVGUtils.encapsuleSVG(parts), string(abi.encodePacked('"name": "',word,'.jpg", "description": "gm, ',word,'",  "license":"CC0", "creator":"@eskalexia", "attributes":[',attributes,'], "seller_fee_basis_points": 1000, "fee_recipient": "0xDf5B0E3887Ec6cb55C261d4bc051de8dbF7d8650"'))); 
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";


library SeedRandom {
    function makeSeedChoice(uint256 baseSeed, string memory salt, uint256 min, uint256 max, uint256 offChance) internal pure returns (uint256) {
        uint256 diff = max - min;
        uint256 assetSeed = uint256(keccak256(abi.encodePacked(baseSeed, salt, 'gm')));
        if(offChance<2)
            return assetSeed % diff + min;
        else
            return (assetSeed % offChance == 0 ? assetSeed % diff : 0) + min;
    }
    
    function makeSeedChoiceAsString(uint256 baseSeed, string memory salt, uint256 min, uint256 max, uint256 offChance) internal pure returns (string memory) {
        return Strings.toString(makeSeedChoice(baseSeed, salt, min, max, offChance));
    }
    
    function makeSeedChoice(uint256 baseSeed, string memory salt, uint256 variants) internal pure returns (uint256) {
        return makeSeedChoice(baseSeed, salt, 0, variants, 0);
    }
    
    function makeSeedChoiceAsString(uint256 baseSeed, string memory salt, uint256 variants) internal pure returns (string memory) {
        return Strings.toString(makeSeedChoice(baseSeed, salt, 0, variants, 0));
    }
    /*
    function pick(string[] calldata source, uint256 baseSeed, string calldata salt) external pure returns (string memory) {
        return source[makeSeedChoice(baseSeed, salt, 0, source.length, 0)];
    }
    
    function pick(string[] calldata source, uint256 baseSeed, string calldata salt, uint256 offChance) external pure returns (string memory) {
        return source[makeSeedChoice(baseSeed, salt, 0, source.length, offChance)];
    }*/
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SeedRandom.sol";

library HSLColor {
    //one color, 
    //one center + two adjacent, 
    //one center + two adjacent with a space inbetween, 
    //one + one opposing, 
    //one + two opposing, adjacent the inverse, 
    //one opposing EXTENDED_ANALOGUE
    //three color with 120 inbetween (triangle)
    //two one+one opposing (two COMPLEMENTARY)
    //random
    enum CTYPE {MONO, ANALOGUE, EXTENDED_ANALOGUE, COMPLEMENTARY, SPLIT_COMPLEMENTARY, EXTENDED_COMPLEMENTARY, TRIADIC, TETRADIC, RANDOM}
    
    function getColorValueCenter(uint256 centerPick) internal pure returns (uint256) {
        return centerPick%12 * 30 + 30;
    }
    
    function getColorValue(uint256 baseSeed, uint256 salt, uint256 centerPick, uint256 range) internal pure returns (uint256) {
        if(centerPick == 2222)
            centerPick = SeedRandom.makeSeedChoice(baseSeed, string(abi.encodePacked('colvalhrand',salt)), 12);
        return getColorValueCenter(centerPick) - range + SeedRandom.makeSeedChoice(baseSeed, string(abi.encodePacked('colvalh',salt)), 2*range)%361;
    }

	function getSchemeName(CTYPE scheme) 
	internal pure returns (string memory) {

		if(scheme == CTYPE.MONO)
            return "Monochromes";
        else if(scheme == CTYPE.ANALOGUE)
            return "Analogues";
        else if(scheme == CTYPE.EXTENDED_ANALOGUE)
            return "Extended Analogues";
        else if(scheme == CTYPE.COMPLEMENTARY)
            return "Complementaries";
        else if(scheme == CTYPE.SPLIT_COMPLEMENTARY)
            return "Split Complementaries";
        else if(scheme == CTYPE.EXTENDED_COMPLEMENTARY)
            return "Extended Complementaries";
        else if(scheme == CTYPE.TRIADIC)
            return "Triadics"; //maybe find a way to have 3 colors insterad of double main
        else if(scheme == CTYPE.TETRADIC)
            return "Tetradics";
		
		return "Random";
	}

	function getColorName(uint256 centerPick) 
	internal pure returns (string memory) {

		if(centerPick%12 == 0) 
			return "Crimson";
		else if(centerPick%12 == 1) 
			return "Honey";
		else if(centerPick%12 == 2) 
			return "Lemon";
		else if(centerPick%12 == 3) 
			return "Lime";
		else if(centerPick%12 == 4) 
			return "Green";
		else if(centerPick%12 == 5) 
			return "Mint";
		else if(centerPick%12 == 6) 
			return "Ice";
		else if(centerPick%12 == 7) 
			return "Day";
		else if(centerPick%12 == 8) 
			return "Night";
		else if(centerPick%12 == 9) 
			return "Royal";
		else if(centerPick%12 == 10) 
			return "Bubblegum";
		//else if(centerPick%12 == 11) 
		return "Heart";
	}

    function getColorValueRange(CTYPE scheme, uint256 centerPick) 
	internal pure returns (uint256[4] memory) {

        if(scheme == CTYPE.MONO)
            return [centerPick%12,centerPick%12,centerPick%12,centerPick%12];
        else if(scheme == CTYPE.ANALOGUE)
            return [addmod(centerPick,11,12), (centerPick)%12, addmod(centerPick,1,12), (centerPick)%12];
        else if(scheme == CTYPE.EXTENDED_ANALOGUE)
            return [addmod(centerPick,10,12), (centerPick)%12, addmod(centerPick,2,12), (centerPick)%12];
        else if(scheme == CTYPE.COMPLEMENTARY)
            return [(centerPick)%12, addmod(centerPick,6,12), (centerPick)%12, addmod(centerPick,6,12)];
        else if(scheme == CTYPE.SPLIT_COMPLEMENTARY)
            return [(centerPick)%12, addmod(centerPick,5,12), addmod(centerPick,7,12), (centerPick)%12];
        else if(scheme == CTYPE.EXTENDED_COMPLEMENTARY)
            return [addmod(centerPick,10,12), (centerPick)%12, addmod(centerPick,2,12), addmod(centerPick,6,12)];
        else if(scheme == CTYPE.TRIADIC)
            return [addmod(centerPick,8,12), (centerPick)%12, addmod(centerPick,4,12), (centerPick)%12]; //maybe find a way to have 3 colors insterad of double main
        else if(scheme == CTYPE.TETRADIC)
            return [addmod(centerPick,9,12), (centerPick)%12, addmod(centerPick,3,12), addmod(centerPick,6,12)];

        return [uint256(2222), uint256(2222), uint256(2222), uint256(2222)];
    }
    
    function getColorScheme(uint256 baseSeed, string memory salt) internal pure returns (CTYPE) {
        uint256 n = SeedRandom.makeSeedChoice(baseSeed, string(abi.encodePacked('colscheh',salt)), 0, 9, 0);
        return CTYPE(n);
    }
    
    function generateColorHSL(uint256 baseSeed, uint256 salt, uint256 lumMin, uint256 lumMax) internal pure returns (string memory) {
        return generateColorHSL(baseSeed, salt, 99, 100, lumMin, lumMax, SeedRandom.makeSeedChoice(baseSeed, string(abi.encodePacked('cocol',salt)),0, 361, 0));
    } 
    
    function generateColorHSL(uint256 baseSeed, uint256 salt, uint256 satMin, uint256 satMax, uint256 lumMin, uint256 lumMax) internal pure returns (string memory) {
        return generateColorHSL(baseSeed, salt, satMin, satMax, lumMin, lumMax, SeedRandom.makeSeedChoice(baseSeed, string(abi.encodePacked('cocol',salt)),0, 361, 0));
    } 
    
    function generateColorHSL(uint256 baseSeed, uint256 salt, uint256 satMin, uint256 satMax, uint256 lumMin, uint256 lumMax, uint256 colorPick) internal pure returns (string memory) {
        return string(abi.encodePacked("hsl(",Strings.toString(colorPick),",",SeedRandom.makeSeedChoiceAsString(baseSeed, string(abi.encodePacked('cosat',salt)),satMin, satMax+1, 0),"%,",SeedRandom.makeSeedChoiceAsString(baseSeed, string(abi.encodePacked('colum',salt)),lumMin, lumMax+1, 0),"%)"));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";