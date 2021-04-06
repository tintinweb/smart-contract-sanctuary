/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.5.0;


interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.5.0;



contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    function balanceOf(address owner) public view returns (uint256 balance);


    function ownerOf(uint256 tokenId) public view returns (address owner);


    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;


contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}


pragma solidity ^0.5.0;


contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.5.0;


contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
    
}


pragma solidity ^0.5.0;


interface IERC20 {
 
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


pragma solidity ^0.5.0;

contract SoccerIndustryColors {
    using SafeMath for uint256;

    IERC721Full internal soccerindustry;

    address public createControl;

    address public tokenAssignmentControl;

    enum Colors {
        White,
        Black,
        Yellow,
        Cyan,
        Magenta
    }

    uint256 public constant packFactor = 85;
    uint256 public constant packBits = 3;
    uint256[] public packedColors;

    event SavedColors(uint256 firstId, uint256 lastId);

    constructor(address _createControl, address _tokenAssignmentControl)
    public
    {
        createControl = _createControl;
        tokenAssignmentControl = _tokenAssignmentControl;
    }

    modifier onlyCreateControl()
    {
        require(msg.sender == createControl, "createControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier requireSoccerIndustry() {
        require(address(soccerindustry) != address(0x0), "You need to provide an actual SoccerIndustry contract.");
        _;
    }

   

    function setSoccerIndustry(IERC721Full _newSoccerIndustry)
    public
    onlyCreateControl
    {
        require(address(_newSoccerIndustry) != address(0x0), "You need to provide an actual SoccerIndustry contract.");
        soccerindustry = _newSoccerIndustry;
    }



    function calcPackedColors(Colors[] memory _values)
    public pure
    returns (uint256)
    {
        uint256 valcount = _values.length;
        require(valcount <= packFactor, "Can only pack values up to a maximum of the packFactor.");
        uint256 packedVal = 0;
        for (uint256 i = 0; i < valcount; i++) {
            packedVal += uint256(_values[i]) * (2 ** (i * packBits));
        }
        return packedVal;
    }

    function setColorsPacked(uint256 _tokenIdStart, uint256[] memory _packedValues)
    public
    onlyCreateControl
    requireSoccerIndustry
    {
        require(_tokenIdStart == packedColors.length * packFactor, "Values can can only be appended at the end.");
        require(_tokenIdStart % packFactor == 0, "The starting token ID needs to be aligned with the packing factor.");
        uint256 valcount = _packedValues.length;
        for (uint256 i = 0; i < valcount; i++) {
            packedColors.push(_packedValues[i]);
        }
        emit SavedColors(_tokenIdStart, totalSupply() - 1);
    }


    function getColor(uint256 tokenId)
    public view
    requireSoccerIndustry
    returns (Colors)
    {
        require(tokenId < totalSupply(), "The token ID has no color stored.");
        require(tokenId < soccerindustry.totalSupply(), "The token ID is not valid.");
        uint256 packElement = tokenId / packFactor;
        uint256 packItem = tokenId % packFactor;
        uint256 packValue = (packedColors[packElement] >> (packBits * packItem)) % (2 ** packBits);
        require(packValue < 5, "Error in packed Value.");
        return Colors(packValue);
    }

    function totalSupply()
    public view
    requireSoccerIndustry
    returns (uint256)
    {
        uint256 maxSupply = packedColors.length * packFactor;
        uint256 csSupply = soccerindustry.totalSupply();
        if (csSupply < maxSupply) {
            return csSupply;
        }
        return maxSupply;
    }

    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }
 
    function()
    external payable
    {
        revert("The contract cannot receive ETH payments.");
    }
}