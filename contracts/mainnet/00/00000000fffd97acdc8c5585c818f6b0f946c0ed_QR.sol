/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC721 is Context, IERC721 {

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

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
}

contract QR is ERC721 {
    uint8 internal _count;
    bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    uint16 constant prefixInt = 4640;
    bytes32[] internal ipfsLinks;

    constructor() ERC721("Rare QRs", "Q") {
        _count = 0;
        ipfsLinks = [bytes32(0x2c7658c7f3dbb9bbc22ffe8e4bf4915f6503618c28dd0a7425b4844045aa77e3), bytes32(0x2621bf62f881ad2ca8e9154d5faf9c6f7b1337eb14ecea940beb6081fe43810a), bytes32(0x1ea0e7276f08079ba3eb5d5db626f7c6b2af43ea9fe2057396668fec721d728d), bytes32(0x3e6bb3d82181874259ef855b8178d125585a55fc72eb97e2c956eebef8cf5d44), bytes32(0x5d9698497e3c3ac1656c9a456bcfb02989c68b949307c46a78417c35b022d8c8), bytes32(0xa100261e8c7cb02d89ede8d3c48936d5d6d8c0bbc077c1061f8e00d36bee1c37), bytes32(0xf24b70fc7f3eec510150d22ef59d5821f2558a79c8fd6c523e2ce73fe26ffd66), bytes32(0x53eaf88c59664c0340a469345bce47cff8e98d4590e5359fd8f93d4aa280eb8b), bytes32(0x0bbb5d6ff3ef1844721a5f921ce8f97f243d8d278d3f459fd63b53cba3c2baea), bytes32(0x355f7c89e84decf365dc040d26dc00a2fb3ba4093ec07aa3937e3c6232f67c3f), bytes32(0x4b57af095c7fec01a95ff38d05f8b0739ca8db64b843830e112001fc0d4fd6ab), bytes32(0x1c84fb565b67938f05257c529c7f0641ad7a22d2427300953f7364b5024621c6), bytes32(0x950f021b3d3a5e05f75c96bd49a2d29965195c87f12ef2fafea31a2073443b13), bytes32(0x6868be09fbe323a4108bf0e93393109afa10ed13d2d73bfb5cacfbc1e0980a22), bytes32(0xb185c4c7013bf4548f35021019f0121b8452df5908f3609796700a8dee6fb76e), bytes32(0xe76496d2608722b66a5c338d7a9a74cae43c4b8cc968d780e3807c9c713a31f6), bytes32(0x018ff9bb328b8bb77dbdcfdfb6ecf5288d9b0d327782670b52766c6659aed5f1), bytes32(0x9431493cbf1206e05a65bef446838c0e4d8ead54d4c53f5c2e9dc17ada6f33ec), bytes32(0xbbf649801868986c3d7e2239172019a06800239707e28486cb16205f8fb66cc2), bytes32(0xe07df2a33893f4e2856d27c4081e3db80eea5da388f76c46edd6a3eea859c8e6), bytes32(0x8d5430a315404995757726d3a1fc4c1c44e18b2c1ce5aa2039741c3ce1957cb8), bytes32(0xc7dbb8b4ee6efe93359fba0b44c0adae94a549bf0780ab0d9b2bdb2af19c119f), bytes32(0xf0640598d6a95be564cd446f101750dace146453f9a3b3b38acd4972e132321a), bytes32(0x9187aac4dbae96893cc8934e9cf551359621bec93b9f9a6efbb38fee5ddb6fc1), bytes32(0xb311fa354fd381c07419278d4acefe5d71632d82b9dd71e832f0f26f14821b20), bytes32(0xcf381b71f64873b80593fb946ca58c81c980add8f18d7f73b561be043dbf3c30), bytes32(0xdafed8de98266f26526e69086f66840dab4c59c6883b3b85fef09125c3cd42ae), bytes32(0xe05e86591ada0f8377f7b305903520765a7b5ae7bbb7d1537be6fe5b8331ea3c), bytes32(0xcde869ae256171675972b4c0a1f21112afc921c3392d4a788788f82a21c7c7cb), bytes32(0xe0ab35655ca79b797ead9fa74c15bf792931f29442d77937fb9c97af89b7767b), bytes32(0xa4b56fabf0f631b62efe6375d9cecc2e971dafd07cce5f249fc2828e08b272b6), bytes32(0x442adf7bbc35d3e98c3695ee854589308c9db6412db96a5a0437f4b9c74e9257), bytes32(0x483051633c23942951746d798133a5fdd716cd1c268e0d6a5dc6d4e1bf8d5785), bytes32(0xdc1ba9d01b8ad990231c7892d94daee65a77793b62998e381a2b90e5e8f07528), bytes32(0x9abf39bc2dfbcf55e3f1c8e9ee5c6525fbdeba9ada56f986ad2913d5155361ce), bytes32(0x86c34b4e82c7caa40fbfa9cf2654065b17253db3d26f526f6be2a9274927725a), bytes32(0x3f4dbb444fed66b4e63ed71f901bed95bb221eed8e6d173fc4593b0e9946f653), bytes32(0x1feac35e4d48b9310cf9f746416d02962c6b1b2a0281c3242e97eb60ef56cc70), bytes32(0xdd88804a09f78c5874ea857ca4cfa3eac170ce2ce4571fa03a7802273617b99c), bytes32(0x0aa16b240c51fc4753bb33dd351320d788f3e3a2cdd0dac313a3e91493381c17), bytes32(0x967a5ccafa3888f4c1e02b579b40d14e677079b277d972bdf13f21f2af6bcc26), bytes32(0x4fab6e2e41c2cd209edd48533d4f152d1e3dfb3a3dfe110e4dcb3a5e59cdcaf7), bytes32(0x56eeaccb4ba87be0d1c7d955a3edb2bc8b904d249528d0ad9bbfe5efd43d3103), bytes32(0x82bed8ad500005cdf74e4e578e2c67e4d65350314bd39776cc0317dfff91a5c9), bytes32(0x50488a45b1a9cf2e0af21966390fa7a50d3d92e59cfbfb682215e7df54c35d64), bytes32(0xa27dd030789df429ad167d15671fdfc3837ca0e5c9bf9c92aa3a632a383c1a5f), bytes32(0xdbb24870e5b6673abefd8ec25798d3c9f8736fdd7b2ce5ae924ee9e5e8621df5), bytes32(0x45e7e5b44c7424b9707710d0274b21be774a88947977938dbf19436dc6bdf792), bytes32(0x703a1f32399a6a399e7a8ce3d48c3d58f8707601a7d96ae4a600a12dd0704b12), bytes32(0x59595fbefa285356baa98d2d5bdacb74b06d0210aa534f95be7bfd0872c975ed), bytes32(0x31ade3079ee02d939ef4c5cd9047949c5487f7a07b65e6fabf96ee57dbb1caec), bytes32(0x935e4d9faddb9336d85258e8d3d438a971be27d6b774ba9659699fee0650e800), bytes32(0x654c0fc766612eb603eb3fb71ec436ce3d84b43264ba5a57ec6eefedbdcb81bc), bytes32(0xb2810575eb6e25fbdcb2f483787e1878ba2303b1f05ea7ed74d46c80164c4700), bytes32(0x1f052f9a7a8932e4eee8dc33814b30caf5846a56729be7001e10f37e93ba5bf5), bytes32(0x216048b1949a094f78bef00691562f24707d0425c6ca8c131c1635cb141636fa), bytes32(0x6f327ef5354373e09f696bc6a3e28aadcf80eb67680ec0f038db74e29f619e49), bytes32(0x1e25716383d28ea49ef071e65cf6f17ab1f491f7723034f3b798ded719daf5e5), bytes32(0xa54cb8d91f8bfc7f5e5dce92cbfc235c34191bf6ac9e0c3080f8661548c13555), bytes32(0x56c75993a14b53f4483165770a968a326bb71e6b59fa341aff82a00e0811aabe), bytes32(0x5bbb8db06e273c8d895e7e558ec5df325a734a830827615fea6a45c61f2ca90d), bytes32(0xf81ef5ec60296718437b3055d7c6b9b6e8a3932afe4de37dbf992d5e6c1aab87), bytes32(0x6281ef6a355fa30eda2d225a511db8bcc48b43f7b39c58497efc143707e8db68), bytes32(0x1ae74ebb38e831cab0977df718db515b2946205a032a28b5810a3bb11a1fcd43)];
    }

    event PermanentURI(string _value, uint256 indexed _id);
    
    function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i<length; i++) {
            output[i] = array[i];
        }
        return output;
    }
  
    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i<input.length; i++) {
            output[i] = input[input.length-1-i];
        }
        return output;
    }
  
    function toAlphabet(uint8[] memory indices) internal pure returns (bytes memory) {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i<indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }
      
    function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
        bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
        uint i = 0;
        for (i; i < byteArray.length; i++) {
          returnArray[i] = byteArray[i];
        }
        for (i; i < (byteArray.length + byteArray2.length); i++) {
          returnArray[i] = byteArray2[i - byteArray.length];
        }
        return returnArray;
    }

    // From https://github.com/MrChico/verifyIPFS/blob/master/contracts/verifyIPFS.sol#L28
    function toBase58(bytes memory source) public pure returns (bytes memory) {
        bytes memory prefix = abi.encodePacked(prefixInt);
        source = concat(prefix, source);
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i<source.length; ++i) {
            uint carry = uint8(source[i]);
            for (uint256 j = 0; j<digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function mintQr() public {
        require(_count < ipfsLinks.length, "Capped!");
        _mint(msg.sender, _count);
        emit PermanentURI(string(abi.encodePacked("ipfs://", toBase58(abi.encodePacked(ipfsLinks[_count])))), _count); // Putting this in the mint function artificially pumps the gas cost, burning more eth!
        _count++;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require (_count > tokenId, "Not yet minted!");
        return string(abi.encodePacked("ipfs://", toBase58(abi.encodePacked(ipfsLinks[tokenId]))));
    }
    
    function totalSupply() public view returns (uint256) {
        return _count;
    }
}