// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./Render.sol";

contract ClassyApe is ERC721Enumerable, Ownable {
    constructor() ERC721("Ape Club", "CAC") {}

    uint16 public constant MAX_APES = 10000;

    mapping(uint256=>string) private apeTraits;
    mapping(string=>bool) private apeUnique;

    mapping(uint256=>string[]) private allTraits;
    mapping(uint256=>string[]) private traitsName;

    function checkApeExist(string memory traits) public view returns (bool exist){
        return apeUnique[traits];
    }

    function getApeTraits(uint256 id) public view returns (string memory traits){
        return apeTraits[id];
    }

    function getTraitCount(uint256 index) public view returns (uint count){
        return allTraits[index].length;
    }

    function mint(address[] memory holders, string[] memory classyApe) external onlyOwner{
        require( holders.length == classyApe.length, "Length of both arrays should be same" );
        require(totalSupply()+holders.length <= MAX_APES, "It would exceed max supply of Apes");
        for (uint256 i; i < holders.length; i++) {
            uint mintIndex = totalSupply()+1;
            if (totalSupply() <= MAX_APES) {
                apeTraits[mintIndex]=classyApe[i];
                apeUnique[classyApe[i]]=true;
                _safeMint(holders[i], mintIndex);
            }
        }
    }

    function addTrait(uint256 index, string memory name, string memory value)  external onlyOwner {
        allTraits[index].push(value);
        traitsName[index].push(name);
    }


    function getTraits(uint256 id) private view returns (string[2] memory traits, string[2] memory names){
        string[2] memory traitsInternal;
        string[2] memory namesInternal;
        string memory str=getApeTraits(id);
        for (uint256 i; i < 2; i++) {
          (uint256 index,bool ok)=Render.strToUint(Strings.getSlice(i*2, (i*2)+2, str));
          if(ok){
              traitsInternal[i]=allTraits[i][index];
              namesInternal[i]=traitsName[i][index];
          }
        }
        return (traitsInternal, namesInternal);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId > 0 && tokenId<= totalSupply(), "Classy Ape ID not valid.");
        (string[2] memory traits, string[2] memory names) = getTraits(tokenId);

        bytes memory imageSvg = abi.encodePacked(
            Render.getHeader(),
            traits[0],
            traits[1],
            // traits[2],
            // traits[3],
            // traits[4],
            // traits[5],
            // traits[6],
            Render.getFooter());
        bytes memory traitsArray=abi.encodePacked('[{"trait_type":"Hand","value":"',names[0],'"},{"trait_type":"The Blind","value":"',names[1],'"}]');
        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(imageSvg))
        );
    
        return string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"Classy Ape #',Render.toString(tokenId),
                '","external_url":"https://classyape.com","image":"',image,
                '","description":"Classy Ape description","attributes":',traitsArray,'}'
            )))));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable owner = payable(msg.sender);
        owner.transfer(balance);
    }
}