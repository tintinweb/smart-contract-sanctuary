// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract DivineKeysOfLight is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;
    //whitelist mapping
    mapping(address => uint256) public onWhitelist;
	mapping(address => uint256) public allowList;
	mapping(address => uint256) private mintCount;
  	//settings
  	uint256 public maxSupply = 144;
    uint256 public maxMint = 1;

	//shares
	address[] private addressList = [
		0x0Aa1F3d61e7c325aE795737266c5FD6839819b86];
	uint[] private shareList = [100];

	//token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
		allowList[0x76ce7A233804C5f662897bBfc469212d28D11613] = 1;
		allowList[0xbA6597e654358F052Ee4e61D251Cc6A22AF08cae] = 1;
allowList[0x9E2383b6de12347608d597150b2aAe990398b643] = 1;
allowList[0xA442dDf27063320789B59A8fdcA5b849Cd2CDeAC] = 1;
allowList[0x671306a9F89353b2e96f1C0B8878A772dABB7e44] = 1;
allowList[0x1C612Fa9140E918071b5B4EE5E1A7E17c0257E22] = 1;
allowList[0x154c73BFd1b81A21054AFF2b9b31E2bE0965fBbe] = 1;
allowList[0x939c53F1fB850a711294b67c53466c73d069b943] = 1;
allowList[0x0C64D5DA9CBc8bbeE994166FF8dd47809DF0002b] = 1;
allowList[0x0cC58b2E44F42fC00Fc12D4a9B01fB95fe14891A] = 1;
allowList[0x9215df54fA4FA8402E95Db95B10156488747a28A] = 1;
allowList[0xB670768c72510493AC1Fd2B9AfF66DE1F669E05E] = 1;
allowList[0x0C71557b4aD81E07034DD9C04E232f17BB0B4Aa3] = 1;
allowList[0x84C038E5Cf3a041da907Bc2aE4FA973989888cD0] = 1;
allowList[0xd5cB64F886Da4BC8B7659bC8442DE9ADc823E75d] = 1;
allowList[0x6d58491c6F68426966DbD6a1682195aC17b95db4] = 1;
allowList[0x9E139C0Cba1538C72d8072E4b1fe090efeE6ccE0] = 1;
allowList[0x60CED65A51922C9560d72631F658Db0df85BFf1f] = 1;
allowList[0x8F1e1E8240c6CAaA69b33D7e7C433f9f06f326C1] = 1;
allowList[0x669Ac071Cf2F3a4E7e7991c0af074C1aB5E681B3] = 1;
allowList[0x1eF70a05965Bd2d6224FCa2FfF25B756bAEe78C6] = 1;
allowList[0x47c91629F6b71bfd70d68788C6a9E6769Ca8045b] = 1;
allowList[0x9584f87e7a90e2e94BC43508D6df449e2a015ce8] = 1;
allowList[0x318E4BA3FB1ca449868e48c060B0Fc11Da173B8b] = 1;
allowList[0x9467eE010629e5c25Add2773DAfB820528949ea8] = 1;
allowList[0xCc7357203C0D1C0D64eD7C5605a495C8FBEBAC8c] = 1;
allowList[0x056F154C822cB374508Cd318038C3d1e1230c377] = 1;
allowList[0xb81D12E9D9f9cB044046b6d5830DA536e3205049] = 1;
allowList[0x27c30763dcEf725E4cf55FF22a7294cF1E00cd9D] = 1;
allowList[0x2d067743739426972C145db877af49e25aea028a] = 1;
allowList[0xe837c11baa14E0B00131C72D67e853d89de46A91] = 1;
allowList[0xFe410c82a226fe37F34337C3AFFb9413D13BbDF5] = 1;
allowList[0x8E7755751F752e764e6857ffd93Ae105701b684e] = 1;
allowList[0x7Ef0818C96D5610BDb4Bf7A64B3F0F38C73D0F0e] = 1;
allowList[0x916b4145D4994601E8F37650bAe0e6F4a4D88980] = 1;
allowList[0x0EF7fc7B6730148Af0b35e0754a1420Bad088c4E] = 1;
allowList[0x2B0e995FF2285965eC97562c62db7d399043E33C] = 1;
allowList[0xf16F9aab7A0685C1846F6AD096d65D764e158E2C] = 1;
allowList[0x63C28927bFceA56d3f030A178543177ac5E7cf2A] = 1;
allowList[0x5589eDE3d99fd4fB116dB45e5eBaC886Df2582fb] = 1;
allowList[0x2ECAF6b220f6b1a09a79397592fa569fdA534637] = 1;
allowList[0x2b0D29fFA81fa6Bf35D31db7C3bc11a5913B45ef] = 1;
allowList[0x565E2a7608b2A21700207BFFf860063A6aD2D21b] = 1;
allowList[0x337839612dEF7463bf9d64C9887c8e1ffD4c3886] = 1;
allowList[0x1887ce150D8B503c2BcC4066d47B85A6978de272] = 1;
allowList[0x3F1A421b47c5a9ec1025475a3Fd3e99cE20616A2] = 1;
allowList[0x7B41DE511A3E42705935D2aDFE1885bA435D047c] = 1;
allowList[0x54E6E97FAAE412bba0a42a8CCE362d66882Ff529] = 1;
allowList[0xf3120515A489700a53A6f56178b153c61CaeC1Df] = 1;
allowList[0xb99426903d812A09b8DE7DF6708c70F97D3dD0aE] = 1;
allowList[0x602669Ef225F7D82Da5037Bee2717fEDF6ccb939] = 1;
allowList[0xaf3e4aD7cd7076642F5B24B07e655744634ad5Aa] = 1;
allowList[0xdC41EF1A9472aFa2DbDc181de54Ff7379BCEfB31] = 1;
allowList[0x25b78a1487AC08c513a9292D18e347139CFbd950] = 1;
allowList[0xB739A645fBBD86c57A6d34dAD49097930230Ed9A] = 1;
allowList[0xede5981A891F6BfFEaab13Cc6E1Ec3bbC452C97e] = 1;
allowList[0x3285C6e4f74A6891b900f36Dcd76a14Ee3e536db] = 1;
allowList[0xa4d80978BB057B6e1AfB0E47EB2b4879483C295D] = 1;
allowList[0x8ed39d927C2ad8e3A840B3b27335152a9521Fc76] = 1;
allowList[0xFca88F06Adc39D16641D18691E987C840749171d] = 1;
allowList[0xD7be5692548d971eB47dd7705dF2998A87a2C86D] = 1;
allowList[0x49b8C8ffbFE109380E893FF3C999ad7839F7f485] = 1;
allowList[0xa847870405b8abbD61d7D7765144bC9D9AB24BCd] = 1;
allowList[0x52CE87865E52cBE36156170531614C1a9aAD16cc] = 1;
allowList[0x1e122feB6967DC45639796c5579874fd98acF845] = 1;
allowList[0xB0445F16Bf00b9258CC56036e77521445D02c3D5] = 1;
allowList[0x6Be4cE49cCaB9B252b892597b9C568144C08714A] = 1;
allowList[0xE34bc5d8Ba9571E193D2C87fE95018B19a24FB41] = 1;
allowList[0x6ed611581F047BE8188c9EB085dF6022265885ec] = 1;
allowList[0x775aF9b7c214Fe8792aB5f5da61a8708591d517E] = 1;
allowList[0x31faB7A5c814B4DaC3E5B706501f059D8FDD2faB] = 1;
allowList[0x7cb9Fa642C76Ca3dadD901191965E150D12Efc18] = 1;
allowList[0x854f5fe9cbED298602c6d98ee9735d7fD9f82Cc6] = 1;
allowList[0x764cCC835d44A5F52AC5D6212ffcE7cB419c262b] = 1;
allowList[0x1a83DaFc03485703b1ea7c9E7f673A2732811594] = 1;
allowList[0xE7e84204B7e180454e5C40d0e04D346214a83f85] = 1;
allowList[0x0EC77aBCEbD34c1Ee4fE35bF4dF7E6ed0725719F] = 1;
allowList[0x48c8bd589E8b81cfE13403Ec4884f71e676961db] = 1;
allowList[0xa8C045e857c1c4550119B612F22c3B27ECE10340] = 1;
allowList[0x01b7baA7baA864fEF3CD1C7bc118Cc97cEdCB33f] = 1;
allowList[0x57Cbe501092E36E87692d89ce4E75f98aA45FeB2] = 1;
allowList[0x6eD65F1fa3c55fb7577129C15D9229d167B01dB1] = 1;
allowList[0x8a97E0c4F2f5C74C6e995649a0d5C3bE167eb394] = 1;
allowList[0x01889333e3Af322Cd64221c5c46902885cdC4303] = 1;
allowList[0xfE939BEA8DF67d56325923EE9d7cE5240b5e493e] = 1;
allowList[0x3aAC980cA632228b9920F64a1684E86620D54314] = 1;
allowList[0xf042025bcBBEF4561601A85c3fB692f43DfFc7B4] = 1;
allowList[0xeac3b644E61cD0D8B27b35d6dEDeEaa76eb46BA7] = 1;
allowList[0xf220aA9aE5bd7EAcEf1Fc9685f5Dee8367CeE562] = 1;
allowList[0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123] = 1;
allowList[0xda48bEF797d97729b067CCFC10B61b51F8532832] = 1;
allowList[0x5a32fb84aF55046EC2Fc3540e333b6C30D66ea41] = 1;
allowList[0x58C2742382ED5cd2CBf62f76c803c79B05489b5D] = 1;
allowList[0xd78F0E92C56C45Ff017B7116189eB5712518a7E9] = 1;
allowList[0x92178Cdcf11E9f77F378503D05415D8BEb9E7bcF] = 1;
allowList[0xfEcF6D43bdeDEBcd27f393fC033353Ca1D9594A3] = 1;
allowList[0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e] = 1;
	}

    	// whitelist minting
	function claim(uint256 _tokenAmount) public  {
	    uint256 s = totalSupply();
    	uint256 wl = onWhitelist[msg.sender] + allowedMintCount(msg.sender);
	    require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMint, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
  	    require(wl > 0);
	    delete wl;
	        for (uint256 i = 0; i < _tokenAmount; ++i) {
	            _safeMint(msg.sender, s + i, "");
	        }
	    delete s;
	}

	  function allowedMintCount(address minter) public view returns (uint256) {
    	return allowList[minter] - mintCount[minter];
  	}

   	function updateMintCount(address minter, uint256 count) private {
    	mintCount[minter] += count;
  	}

	// admin minting
	function gift(uint[] calldata gifts, address[] calldata recipient) external onlyOwner{
	    require(gifts.length == recipient.length);
	        uint g = 0;
	        uint256 s = totalSupply();
	    for(uint i = 0; i < gifts.length; ++i){
	        g += gifts[i];
	    }
	    require( s + g <= maxSupply, "Too many" );
	    delete g;
	    for(uint i = 0; i < recipient.length; ++i){
	    for(uint j = 0; j < gifts[i]; ++j){
	        _safeMint( recipient[i], s++, "" );
	     }
        }
	    delete s;	
	}

    // admin functionality
	function whitelistSet(address[] calldata _addresses) public onlyOwner {
	for(uint256 i; i < _addresses.length; i++){
	onWhitelist[_addresses[i]] = maxMint;
	}
	}

	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(tokenId <= maxSupply);
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}
	//max mint switch if necessary
	function setMaxMint(uint256 _newMax) public onlyOwner {
	maxMint = _newMax;
	}

	//withdraw
	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}