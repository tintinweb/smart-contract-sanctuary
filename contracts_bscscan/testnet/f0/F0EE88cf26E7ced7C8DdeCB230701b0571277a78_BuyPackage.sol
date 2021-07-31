/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity ^0.5.0;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IBEP20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        // uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: ERC20 operation did not succeed");
        }
    }
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

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
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
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
pragma solidity ^0.5.0;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
pragma solidity ^0.5.0;
library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
pragma solidity ^0.5.0;
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}
pragma solidity ^0.5.0;
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].length--;
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}
pragma solidity ^0.5.0;
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
pragma solidity ^0.5.0;
contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
pragma solidity ^0.5.0;
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

contract NftLegendCard is ERC721Full {
    address public ownerNftLegendCard;
    constructor() ERC721Full("NFTLegendCard", "NFLC") public {
        ownerNftLegendCard = msg.sender;
    }
    mapping(address => bool) public miner;
    function createOrEditMiner(address _address) public {
        require(msg.sender == ownerNftLegendCard, 'You are not a owner');
        bool oldMiner = miner[_address];
        miner[_address] = !oldMiner;
    }
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) public returns(bool) {
        require(miner[msg.sender] == true, 'you are not a miner');
       _mint(_to, _tokenId);
       _setTokenURI(_tokenId, _tokenURI);
        return true;
    }
}

contract BuyPackage is Ownable , NftLegendCard{
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IBEP20 public tokennfl;
	NftLegendCard public tokenerc721;
    uint256 nflDecimal;
    uint256 amountBuyPackage = 400000000;
	uint256 public package = 10;
    address burnAddress = 0xF3177c2822a33457BDf7e2944c3F986D51a7bf81;
    uint256 public maxBuy = 534;
    uint256 public numberOfPurchases = 0;
    uint256 public maxC = 100;
    uint256 public maxR = 50;
    uint256 public maxSR = 25;
    uint256 public maxSSR = 10;

    mapping(uint256 => uint256) public numberC; // numberC[number] = currentNumberCardC;
    mapping(uint256 => uint256) public numberR; // numberR[number] = currentNumberCardD;
    //Random 
    string[83] stringuri = [string('1'), '2', '3', '4', '5', '6', '7','8', '9','10', '11', '12', '13', '14', '15', '16','17', '18','19', '20', '21', '22', '23', '24', '25','26', '27','28', '29', '30', '31', '32', '33', '34','35', '36','37', '38', '39', '40', '41', '42', '43','44', '45','46', '47', '48', '49', '50', '51', '52','53', '54','55', '56', '57', '58', '59', '60', '61','62', '63','64', '65', '66', '67','78', '69','70', '71', '72', '73', '74', '75', '76','77', '78','79', '80', '81','82','83'];
	// string[49] stringuri1to49 = [string('1'), '2', '3', '4', '5', '6', '7','8', '9','10', '11', '12', '13', '14', '15', '16','17', '18','19', '20', '21', '22', '23', '24', '25','26', '27','28', '29', '30', '31', '32', '33', '34','35', '36','37', '38', '39', '40', '41', '42', '43','44', '45','46', '47', '48', '49'];
    event historyBuyCard(
		address buyer,
		uint256 timeBuy,
		uint256 blockBuy,
		uint256 tokenId,
		string tokenUri
	);

    constructor( address _tokenerc721 ,address _tokennfl) public {
		tokennfl = IBEP20(_tokennfl); // Token NFL
		tokenerc721 = NftLegendCard(_tokenerc721); // Token NFTLegendCard
	}

    function changeMaxC(uint256 _maxc) public onlyOwner {
		require(_maxc > 0, 'need maxc > 0');
		maxC = _maxc;
	}

    function changeMaxR(uint256 _maxr) public onlyOwner {
		require(_maxr > 0, 'need maxr > 0');
		maxR = _maxr;
	}
 
	function changeAmountBuyPackage(uint256 _amount) public onlyOwner {
		require(_amount > 0, 'need amount > 0');
		amountBuyPackage = _amount;
	}

    function changeMaxBuy(uint256 _maxBuy) public onlyOwner {
        require(_maxBuy > 0, 'need maxBuy > 0');
		maxBuy = _maxBuy;
    }

    function buyCard(uint256 _amount , uint256[10] memory uint_tokenId) public {
        //, uint256[package] memory uint_tokenId
        // Random 9C and 1R
        // C --> [1 - 48] R --> [49 - 82] SR --> [83 - 102] SSR --> [103 104 105] 
        require(numberOfPurchases < maxBuy, 'Out of cards');
        require(_amount == amountBuyPackage, 'Invalid quantity');       
        tokennfl.safeTransferFrom(msg.sender, burnAddress , _amount);
        // uint256[10] memory uint_tokenId = [uint256(32), 343 , 656, 763, 323, 554, 787, 986, 5344, 4254];
        // string[10] memory stringuri = [string('defefrfr'), 'duheuhe', 'dedeehu', 'deideji', 'deijdeij', 'duhudwa', 'dwddw','tgtgtgt', 'ffrewe','erteerer'];
        for(uint256 i =0; i < package; i ++){
            uint256 numberCard;
            if(i == 9) {
                uint256 numberMath2 = numberOfPurchases + 9;
                uint256 numberIdR = changeNumberR(numberMath2);
                numberCard = numberR[numberIdR] >= maxR ? changeNumberCardR() : numberIdR;
                numberR[numberCard] = numberR[numberCard].add(1);
            }else{
                uint256 numberMath1 = numberOfPurchases + i;
                uint256 numberIdC = changeNumberC(numberMath1);
                numberCard = numberC[numberIdC] >= maxC ? changeNumberCardC() : numberIdC;
                numberC[numberCard] = numberC[numberCard].add(1);
            }
            tokenerc721.mint(msg.sender, uint_tokenId[i] , stringuri[numberCard - 1]);
            emit historyBuyCard(
			msg.sender,
			block.timestamp,
			block.number,
            uint_tokenId[i],
			stringuri[i]
		);
        }
        numberOfPurchases = numberOfPurchases.add(1);
		
    }

    function changeNumberCardC() private view returns(uint256) {
        for(uint256 i = 1; i < 49 ; i ++) {
            if(numberC[i] < maxC){
                return i;
            }
        }
    }

    function changeNumberCardR() private view returns(uint256) {
        for(uint256 i = 49; i < 82 ; i ++) {
            if(numberR[i] < maxR){
                return i;
            }
        }
    }
    

    function changeNumberR(uint256 _randNonce) public view returns(uint256){ 
        uint256 numberRandom;     
        uint256 random = getRandomNumber(_randNonce) ;
        uint256 randomEdit = random.mod(34);
        if(randomEdit == 0) {
            //random ==35        
            numberRandom = 34;
        }else if(random == 0) {
            //random ==31
            numberRandom = 33;
        }else{
            numberRandom = randomEdit;
            // numberC[randomEdit] = numberC[randomEdit].add(1);              
        }       
        return (numberRandom + 48);
    }

    function changeNumberC(uint256 _randNonce) public view returns(uint256){ 
        uint256 numberRandom;     
        uint256 random = getRandomNumber(_randNonce) ;
        uint256 randomEdit = random.mod(48);
        if(randomEdit == 0) {
            //random ==48        
            numberRandom = 48;
        }else if(random == 0) {
            //random ==5
            numberRandom = 5;
        }else{
            numberRandom = randomEdit;
            // numberC[randomEdit] = numberC[randomEdit].add(1);              
        }       
        return numberRandom;
    }

    function getRandomNumber(uint256 _randNonce) public view returns(uint256 ){     
        uint256 random = uint256(keccak256(abi.encodePacked(now, msg.sender, _randNonce))) % 100;
        return random;
    }
}