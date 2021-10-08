/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

contract VRFRequestIDBase {
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce))
            );
    }

    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            _seed,
            address(this),
            nonces[_keyHash]
        );
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}
pragma solidity ^0.8.4;

interface IRandomNumberGenerator {
    function getRandomNumber(uint256 _seed) external returns (bytes32);

    function viewRandomResult() external view returns (uint32);
}

contract RandomNumberConsumer is VRFConsumerBase, IRandomNumberGenerator {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    uint256 public randomIndex;

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.5 * 10**18;
    }

    uint256 rangeNumber;

    function getRandomNumber(uint256 _seed)
        public
        override
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        // rangeNumber = num;
        requestRandomness(keyHash, fee, _seed);
    }

    function getDraw(uint256 userProvidedSeed)
        public
        returns (uint256[] memory)
    {
        uint256[] memory draw = new uint256[](5);
        randomIndex = 0;
        for (uint256 i = 0; i < 5; i++) {
            draw[i] = uint256(getRandomNumber(userProvidedSeed));
        }
        return draw;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256[] memory randomArray = new uint256[](5);
        uint256 tempRandomResult = (randomness % 10) + 1;
        randomArray[randomIndex] = tempRandomResult;
        randomIndex = randomIndex + 1;
    }

    function viewRandomResult() external view override returns (uint32) {
        return uint32(randomResult);
    }
}
pragma solidity ^0.8.4;

interface ItestContract {
    function viewtest() external returns (string memory);
}

contract testContract is ItestContract {
    function viewtest() external view override returns (string memory) {
        return "ALI nawaz";
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
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

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract pizzaNFT is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _randomPizzaId;
    Counters.Counter private _IngredientItemIds;
    Counters.Counter private _buyPizzaIds;
    uint256 private _randomNumerRange;
    // IRandomNumberGenerator public randomGenerator;
    ItestContract public itestContract;

    struct _randomPizzaDetail {
        //only Owner() radom pizza detail
        uint256 _randomId;
        string _pizzaname;
        string _buybase;
        string _buysauce;
        string _buyCheese;
        string _buymeats;
        string _buytoppings;
    }

    struct Ingredients {
        uint256 _ingredientId;
        string name;
        uint256 qty;
        uint256 price;
    }

    struct pizzabuying {
        uint256 buyingID;
        address owner;
        string _buybase;
        string _buysauce;
        string _buyCheese;
        string _buymeats;
        string _buytoppings;
        uint256 totalprice;
        bool isConformed;
        bool isRandom;
        bool _isDisassembles;
    }

    mapping(uint256 => Ingredients) public idToPizzaIngredients;
    mapping(uint256 => pizzabuying) public idToBuyingPizza;
    mapping(uint256 => _randomPizzaDetail) public idToRandomPizza;

    constructor(address _testContractAddress) ERC721("Pizza Bake", "PNFT") {
        // randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        itestContract = ItestContract(_testContractAddress);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /*Only Owner() use this function.*/
    function randomPizzaDetail(
        string memory name,
        string memory base,
        string memory sauce,
        string memory cheese,
        string memory meats,
        string memory toppings,
        uint256 price
    ) public onlyOwner returns (uint256) {
        _randomPizzaId.increment();
        uint256 _randomId = _randomPizzaId.current();
        require(!_exists(_randomId));
        _randomPizzaDetail memory randomPizzaDetail = _randomPizzaDetail(
            _randomId,
            name,
            base,
            sauce,
            cheese,
            meats,
            toppings
        );
        idToRandomPizza[_randomId] = randomPizzaDetail;
        return _randomId;
    }

    function _mintPizzaIngretients(
        string memory ingredientTokenURI,
        string memory name,
        uint256 qty,
        uint256 price
    ) public returns (uint256) {
        _IngredientItemIds.increment();
        uint256 _ingredientId = _IngredientItemIds.current();
        require(!_exists(_ingredientId));
        _mint(owner(), _ingredientId);
        _setTokenURI(_ingredientId, ingredientTokenURI);
        Ingredients memory ingredientDetail = Ingredients(
            _ingredientId,
            name,
            qty,
            price
        );
        idToPizzaIngredients[_ingredientId] = ingredientDetail;
        return _ingredientId;
    }

    function _mintBakedPizza(
        string memory _bakedPizzaTokenURI,
        string memory base,
        string memory sauce,
        string memory cheese,
        string memory meats,
        string memory toppings,
        uint256 price
    ) public returns (uint256) {
        _IngredientItemIds.increment();
        uint256 _ingredientId = _IngredientItemIds.current();
        require(!_exists(_ingredientId));
        _mint(owner(), _ingredientId);
        _setTokenURI(_ingredientId, _bakedPizzaTokenURI);
        pizzabuying memory newbuyingPizza = pizzabuying(
            _ingredientId,
            msg.sender,
            base,
            sauce,
            cheese,
            meats,
            toppings,
            price,
            false,
            false,
            false
        );
        idToBuyingPizza[_ingredientId] = newbuyingPizza;
        return _ingredientId;
    }

    function buyPizzaConformed(uint256 _tokenId) public payable {
        require(msg.sender != address(0));
        require(_exists(_tokenId));
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0));
        require(tokenOwner != msg.sender);
        pizzabuying memory _pizzaID = idToBuyingPizza[_tokenId];
        // require(_pizzaID.totalprice == msg.value);
        // require(_pizzaID.isConformed == false);
        _transfer(tokenOwner, msg.sender, _tokenId);
        payable(tokenOwner).transfer(msg.value);
        _pizzaID.isConformed = true;
        idToBuyingPizza[_tokenId] = _pizzaID;
    }

    function buyBake(
        string[] memory ingredientTokenURI,
        string[] memory name,
        uint256[] memory qty,
        uint256[] memory price,
        string memory _bakedPizzaTokenURI,
        string memory base,
        string memory sauce,
        string memory cheese,
        string memory meats,
        string memory toppings,
        uint256 totalprice
    ) public {
        for (uint256 i = 0; ingredientTokenURI.length > i; i++) {
            _IngredientItemIds.increment();
            uint256 _ingredientId = _IngredientItemIds.current();
            require(!_exists(_ingredientId));
            _mint(owner(), _ingredientId);
            _setTokenURI(_ingredientId, ingredientTokenURI[i]);
            Ingredients memory ingredientDetail = Ingredients(
                _ingredientId,
                name[i],
                qty[i],
                price[i]
            );
            idToPizzaIngredients[_ingredientId] = ingredientDetail;
        }

        uint256 minteID = _mintBakedPizza(
            _bakedPizzaTokenURI,
            base,
            sauce,
            cheese,
            meats,
            toppings,
            totalprice
        );
        buyPizzaConformed(minteID);
    }

    function reBake(
        uint256 tokenId,
        string memory base,
        string memory sauce,
        string memory cheese,
        string memory meats,
        string memory toppings,
        uint256[] memory burnTokenId
    ) public {
        //Please check Will Work on Remove ingredient
        require(msg.sender != address(0));
        pizzabuying memory _buyingPizzaItem = idToBuyingPizza[tokenId];
        require(_buyingPizzaItem.isConformed == false);
        require(_buyingPizzaItem._isDisassembles == false);
        _buyingPizzaItem._buybase = base;
        _buyingPizzaItem._buysauce = sauce;
        _buyingPizzaItem._buyCheese = cheese;
        _buyingPizzaItem._buymeats = meats;
        _buyingPizzaItem._buytoppings = toppings;
        idToBuyingPizza[tokenId] = _buyingPizzaItem;
        for (uint256 i = 0; burnTokenId.length > i; i++) {
            _burn(burnTokenId[i]);
        }
        // recomended checker burn build function used
    }

    function unBake(uint256 tokenId) public payable {
        require(msg.sender != address(0));
        pizzabuying memory _buyingPizzaItem = idToBuyingPizza[tokenId];
        require(_buyingPizzaItem.isConformed == false);
        _buyingPizzaItem._isDisassembles = true;
        idToBuyingPizza[tokenId] = _buyingPizzaItem;
        //Requiedment Full NFT Burn 0.05ETH transfer to owner.must be equal to ETH msg.value
        payable(owner()).transfer(msg.value);
    }

    uint32 public randomPizzaId;

    // Random function wait max 1 mintus the use index to get the 5 array random values.
    function generatedRandomPizzaId(uint256 _val) public {
        // randomGenerator.getRandomNumber(_val);
    }

    // function BakedRandomPizza(
    // string  memory _buybase,
    // string  memory _buysauce,
    // string  memory _buyCheese,
    // string  memory _buymeats,
    // string  memory _buytoppings,
    // string memory _bakedPizzaTokenURI,
    // uint256 totalprice) public {
    //     // uint32 _randomId = randomGenerator.viewRandomResult();
    //     _randomPizzaDetail memory _randomPizza = idToRandomPizza[_randomId];
    //     uint256 minteID = _mintBakedPizza(
    //         _bakedPizzaTokenURI,
    //         _randomPizza._buybase,
    //         _randomPizza._buysauce,
    //         _randomPizza._buyCheese,
    //         _randomPizza._buymeats,
    //         _randomPizza._buytoppings,
    //         totalprice
    //     );
    //     buyPizzaConformed(minteID);
    // }
    function testInterface() public returns (string memory) {
        return itestContract.viewtest();
    }
}
/*
    Final link
    Deploy and verify Smart Contract Link
    https://rinkeby.etherscan.io/address/0x7e4D0841534B135298df2cf9C2cD391B2D34678F#writeContract
 */