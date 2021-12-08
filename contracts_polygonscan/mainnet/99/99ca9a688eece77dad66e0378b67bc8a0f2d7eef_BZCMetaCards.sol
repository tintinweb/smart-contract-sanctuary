// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import './IERC721Enumerable.sol';
import './ERC721Enumerable.sol';
import './IERC20.sol';
import './SafeERC20.sol';
import './Strings.sol';
import './Address.sol';
import './Context.sol';
import './Ownable.sol';
import './Pausable.sol';

import './IERC721Burnable.sol';
import './console.sol';


contract BZCMetaCards is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    string baseURI;
    string _contractURI;
    mapping(uint => string) private _tokenURI;  // optional per token uri

    IERC721Burnable public crystalsContract;
    IERC20 public token;                // bzc erc20 token
    address payable treasury;           // receiver of the mint tokens

    uint public price = 100 * 1e7;        // in token
    uint public MAXMINT = 10;           // per user mint call
    bool useCrystals = true;
    bool useTypeURI = true;

    string private DEFAULT_TYPE = "default";
    mapping(uint => string) private _tokenTypes;  // tokenid to type name

    uint256 public maxSupply = 10000;
    event Minted(uint id, address wallet, string kind);

    address private _minter;
    MintQueue private mintQueue;
    event MintQueued(address user, uint count);

    struct TypeEntry {
        string name;
        uint share;
    }
    uint private _totalShares;
    TypeEntry[] public types;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initContractURI,
        IERC721Burnable _crystalsContract,
        IERC20 _token,
        address payable _treasury
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setContractURI(_initContractURI);
        crystalsContract = _crystalsContract;
        token = _token;
        treasury = _treasury;

        mintQueue = new MintQueue();
    }

    function setTypes(string[] memory names, uint[] memory shares) public onlyOwner {
        require(names.length > 0, "empty list");
        require(names.length == shares.length, "array lengths");
        _totalShares = 0;
        delete types;
        for(uint i=0; i < names.length; i++) {
            types.push(TypeEntry({name: names[i], share:shares[i]}));
            _totalShares += types[i].share;
//            console.log('t', names[i], shares[i], _totalShares);
        }

//        for(uint i=0; i < types.length; i++) {
//            console.log('t', names[i], shares[i], _totalShares);
//        }
    }
    function getRandomType(uint salt) internal view returns (string memory) {
        uint r = _getRandomNumber(_totalShares, salt);
        uint s = 0;
        for(uint i=0; i < types.length; i++) {
            s += types[i].share;
            if (r < s) return types[i].name;
        }
        require(true, "run over!");
        return DEFAULT_TYPE;
    }

    mapping(string => uint) private typesTest;
    uint private testNum;
    function testRandomTypes(uint num) public onlyOwner {
        for(uint i=0; i < num; i++) {
            string memory t = getRandomType(i);
            typesTest[t] += 1;
        }
        testNum += num;
        console.log('*', testNum);
        for(uint i=0; i < types.length; i++) {
            console.log( types[i].name, types[i].share, typesTest[types[i].name], typesTest[types[i].name] * 10000 / testNum);
        }
    }

    // not sure if we need this at all
    function mintNum(address wallet, uint256 num) public onlyOwner {
        require(num <= MAXMINT, "max mint per call");
        if (maxSupply > 0) require(totalTokens() + num <= maxSupply, "max supply");

        // also use the queue here to keep it fair!
        // _mintNum(_msgSender(), _mintAmount);
        mintQueue.push(block.number, wallet, num);
        emit MintQueued(wallet, num);
    }

    function mint(uint num) public whenNotPaused {
        address wallet = _msgSender();

        require(num <= MAXMINT, "max mint per call");
        if (maxSupply > 0) require(totalTokens() + num <= maxSupply, "max supply");

        if (useCrystals) {
            uint bal = IERC721Burnable(crystalsContract).balanceOf(wallet);
//            console.log('mc balance', bal, num);
            require(num <= bal, "more than owned");

            // easier in two steps as index changes while burning.
            uint[] memory ids = new uint[](num);
            for(uint i=0; i < num; i++) {
                ids[i] = IERC721Burnable(crystalsContract).tokenOfOwnerByIndex(wallet, i);
            }
            for (uint i=0; i < ids.length; i++) {
                IERC721Burnable(crystalsContract).burn(ids[i]);  // boom.
            }
        }
        if (price > 0) {
            uint256 allowance = token.allowance(wallet, address(this));
            console.log('allowance', allowance, num * price);
            require(allowance >= num * price, "please approve token");
            token.safeTransferFrom(wallet, address(treasury), num * price);
        }

        mintQueue.push( block.number, wallet, num);
        emit MintQueued(wallet, num);
    }

    function _mintOne(address wallet) private {
        uint id = totalSupply() + 1;
        string memory t = getRandomType(id);
        _mint(wallet, id);
        _tokenTypes[id] = t;

        emit Minted(id, wallet, t);
    }

    function _mintNum(address wallet, uint num) private {
        for(uint i=0; i < num; i++) {
            _mintOne(wallet);
        }
    }
    function mintQueued(uint max) public onlyMinter {
        require(types.length > 0, "need to setTypes() first");
        console.log('mintQueue', mintQueue.size());
        uint i=0;
        address user;
        uint c;
        while(mintQueue.size() > 0) {
            (user, c) = mintQueue.next();
            _mintNum(user, c);
            i += c;
            if (i >= max) return;
        }
    }
    function mintQueueSize() public view returns (uint) {
        return mintQueue.size();
    }

    modifier onlyMinter {
        require(_msgSender() == owner() || _msgSender() == _minter, "no access");
        _;
    }
    function setMinter(address minter) public onlyOwner {
        _minter = minter;
    }
    function setTreasury(address payable _treasury) public onlyOwner {
        treasury = _treasury;
    }

    // controls minting only.
    function pause() public onlyOwner {
        _pause() ;
    }
    function unpause() public onlyOwner {
        _unpause() ;
    }

    // set to 0 to ignore.
    function setMaxSupply(uint _max) public onlyOwner {
        if (_max > 0) require(_max > totalTokens(), "already minted");
        maxSupply = _max;
    }

    function totalTokens() public view returns (uint) {
        return totalSupply() + mintQueue.num();
    }

    function _getRandomNumber(uint _upper, uint _salt) private view returns (uint)
    {
        uint random = uint(uint256(keccak256(abi.encodePacked(
                        _salt,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        _msgSender()
                    ))));

        return random % _upper;
    }

    function getType(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "token not found");
        return _tokenTypes[tokenId];
    }

    // send batch to multiple users - here to avoid needing multisend contract
    //  purposely not doing any batch optimizations here
    function batchTransfer(address from, address[] memory recipients, uint256[] memory tokenIds)
    external {
        require(recipients.length == tokenIds.length, "invalid data");
        for (uint256 i; i < recipients.length; i++) {
            safeTransferFrom(from, recipients[i], tokenIds[i]);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function walletOfOwnerTypes(address _owner) public view returns (uint256[] memory, string[] memory, uint)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        string[] memory _types = new string[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            uint t = tokenOfOwnerByIndex(_owner, i);
            tokenIds[i] = t;
            _types[i] = _tokenTypes[t];
        }
        uint pending = mintQueue.ownerNum(_owner);
        return (tokenIds, _types, pending);
    }


    function setTokenURI(uint tokenId, string memory _uri) public onlyOwner {
        require(_exists(tokenId), "URI query for nonexistent token");
        _tokenURI[tokenId] = _uri;
    }
    function setUseTypeURI(bool use) public onlyOwner {
        useTypeURI = use;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        // optional individual url
        if (bytes(_tokenURI[tokenId]).length > 0) return _tokenURI[tokenId];

        string memory currentBaseURI = _baseURI();
        string memory t = useTypeURI ? _tokenTypes[tokenId] : tokenId.toString();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, t, '.json'))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }
    function setUseCrystals(bool _use, address _contract) public onlyOwner {
        useCrystals = _use;
        if (useCrystals) require(_contract != address(0), "zero address");
        crystalsContract = IERC721Burnable(_contract);
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
    function withdrawTokens(address payable to, IERC20 _token) public onlyOwner {
        uint bal = IERC20(_token).balanceOf(address(this));
        require(bal > 0, "no token balance");
        IERC20(_token).safeTransfer(address(to), bal);
    }
    function withdrawERC721(address payable to, IERC721 _token, uint id) public onlyOwner {
        require(IERC721(_token).ownerOf(id) == address(this), "token not owned");
        IERC721(_token).safeTransferFrom(address(this), address(to), id);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }


    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
}

// simple queue
contract MintQueue {
    struct MintRequest {
        uint block;
        address user;
        uint count;
    }
    mapping(uint => MintRequest) private mintQueue;
    uint private front;
    uint private back;
    uint public num;

    constructor () {
        front = 1;
        back = 0;
    }
    function push(uint _block, address user, uint count) public {
        back++;
        mintQueue[back] = MintRequest({block : _block, user : user, count :count});
        num += count;
    }
    function nextBlock() public view returns (uint) {
        if (size() > 0) {
            return mintQueue[front].block;
        }
        return 0;
    }
    function next() public returns (address, uint) {
        address a = mintQueue[front].user;
        uint c = mintQueue[front].count;
        delete mintQueue[front];
        front++;
        num -= c;
        return (a, c);
    }
    function size() public view returns (uint) {
        return back + 1 - front;
    }
    function ownerNum(address _owner) public view returns (uint) {
        uint n=0;
        for (uint i = front; i <= back; i++) {
            if (mintQueue[i].user == _owner)
                n += mintQueue[i].count;
        }
        return n;
    }
}