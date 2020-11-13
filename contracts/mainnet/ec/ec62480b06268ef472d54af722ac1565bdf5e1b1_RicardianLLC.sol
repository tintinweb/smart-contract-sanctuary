/*
██████╗ ██╗ ██████╗ █████╗ ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗
██╔══██╗██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗████╗  ██║
██████╔╝██║██║     ███████║██████╔╝██║  ██║██║███████║██╔██╗ ██║
██╔══██╗██║██║     ██╔══██║██╔══██╗██║  ██║██║██╔══██║██║╚██╗██║
██║  ██║██║╚██████╗██║  ██║██║  ██║██████╔╝██║██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
██╗     ██╗      ██████╗                                        
██║     ██║     ██╔════╝                                        
██║     ██║     ██║                                             
██║     ██║     ██║                                             
███████╗███████╗╚██████╗   
DEAR MSG.SENDER(S):
/ Ricardian LLC is a project in beta.
// Please audit and use at your own risk.
/// Entry into Ricardian LLC shall not create an attorney/client relationship.
//// Likewise, Ricardian LLC should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W
~presented by Open, ESQ || LexDAO LLC
*/

pragma solidity 0.5.17;

contract RicardianLLC { // based on GAMMA nft - 0xeF0ff94B152C00ED4620b149eE934f2F4A526387
    address payable public ricardianLLCdao;
    uint256 public mintFee;
    uint256 public totalSupply;
    uint256 public constant totalSupplyCap = uint256(-1);
    uint256 public version;
    string public masterOperatingAgreement;
    string public name = "Ricardian LLC, Series";
    string public symbol = "LLC";
    bool public mintOpen;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed holder, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateMasterOperatingAgreement(uint256 indexed version, string indexed masterOperatingAgreement);
    event UpdateMintFee(uint256 indexed mintFee);
    event UpdateMintStatus(bool indexed mintOpen);
    event UpdateRicardianLLCdao(address indexed ricardianLLCdao);

    constructor (string memory _masterOperatingAgreement) public {
        ricardianLLCdao = msg.sender;
        masterOperatingAgreement = _masterOperatingAgreement;
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
    }
    
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    
    function mint() payable external { 
        if (!mintOpen) {require(msg.sender == ricardianLLCdao);}
        require(msg.value == mintFee);
        totalSupply++;
        require(totalSupply <= totalSupplyCap, "capped");
        uint256 tokenId = totalSupply;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenByIndex[tokenId - 1] = tokenId;
        tokenURI[tokenId] = "https://ipfs.globalupload.io/QmWnD9Tv6YGyMFCytGvoGTvnaGU8B6GPWWt1FwKfkuKD4V";
        tokenOfOwnerByIndex[msg.sender][tokenId - 1] = tokenId;
        (bool success, ) = ricardianLLCdao.call.value(msg.value)("");
        require(success, "!transfer");
        emit Transfer(address(0), msg.sender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        tokenOfOwnerByIndex[from][tokenId - 1] = 0;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(from, to, tokenId); 
    }
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        _transfer(msg.sender, to, tokenId);
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata tokenId) external {
        require(to.length == tokenId.length, "!to/tokenId");
        for (uint256 i = 0; i < to.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            _transfer(msg.sender, to[i], tokenId[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        _transfer(from, to, tokenId);
    }
    
    /************
    DAO FUNCTIONS
    ************/
    modifier onlyRicardianLLCdao() {
        require(msg.sender == ricardianLLCdao, "!ricardianLLCdao");
        _;
    }

    function updateMasterOperatingAgreement(string calldata _masterOperatingAgreement) external onlyRicardianLLCdao {
        version++;
        masterOperatingAgreement = _masterOperatingAgreement;
        emit UpdateMasterOperatingAgreement(version, masterOperatingAgreement);
    }

    function updateMintFee(uint256 _mintFee) external onlyRicardianLLCdao {
        mintFee = _mintFee;
        emit UpdateMintFee(mintFee);
    }
    
    function updateMintStatus(bool _mintOpen) external onlyRicardianLLCdao {
        mintOpen = _mintOpen;
        emit UpdateMintStatus(mintOpen);
    }

    function updateRicardianLLCdao(address payable _ricardianLLCdao) external onlyRicardianLLCdao {
        ricardianLLCdao = _ricardianLLCdao;
        emit UpdateRicardianLLCdao(ricardianLLCdao);
    }
}