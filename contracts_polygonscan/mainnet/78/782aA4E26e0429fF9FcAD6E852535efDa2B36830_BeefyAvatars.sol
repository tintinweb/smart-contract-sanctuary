// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IPegSwap.sol";
import "./Art.sol";

contract BeefyAvatars is ERC721Pausable, Ownable, ReentrancyGuard, VRFConsumerBase, Art {
    using Counters
    for Counters.Counter;
    using Strings
    for uint256;

    Counters.Counter private _tokenIds;

    IUniswapV2Router02 public unirouter;
    IPegSwap public pegswap;
    AggregatorV3Interface public maticLinkPriceFeed;

    address public coordinator;
    address public linkToken;
    address public wLinkToken;
    uint256 public linkFee;
    bytes32 public keyHash;
    uint256 public mintPrice;
    address[] public wnativeToLinkRoute;
    uint256 public splippagePercentage = 20;

    constructor(
        address _unirouter,
        address _pegswap,
        address _coordinator,
        address _linkToken,
        address _wLinkToken,
        uint256 _linkFee,
        bytes32 _keyHash,
        address _maticLinkPriceFeed,
        uint256 _mintPrice
    )
    ERC721("Beefy Avatars", "Moo")
    VRFConsumerBase(_coordinator, _linkToken) {
        unirouter = IUniswapV2Router02(_unirouter);
        pegswap = IPegSwap(_pegswap);
        coordinator = _coordinator;
        linkToken = _linkToken;
        wLinkToken = _wLinkToken;
        linkFee = _linkFee;
        maticLinkPriceFeed = AggregatorV3Interface(_maticLinkPriceFeed);
        keyHash = _keyHash;

        mintPrice = _mintPrice;

        wnativeToLinkRoute = new address[](2);
        wnativeToLinkRoute[0] = unirouter.WETH();
        wnativeToLinkRoute[1] = linkToken;

        IERC20(wnativeToLinkRoute[0]).approve(address(_pegswap), type(uint256).max);
        IERC20(linkToken).approve(address(_pegswap), type(uint256).max);

    }

    struct Cow {
        uint256 dna;
    }

    struct VRFRequest {
        uint256 id;
    }

    mapping(uint256 => Cow) public cows;
    mapping(bytes32 => VRFRequest) public VRFRequests;

    event GenerateCow(
        uint256 indexed id,
        uint256 dna
    );

    function generateCow() external payable nonReentrant whenNotPaused {
        require(_tokenIds.current() < 10000, "maximum cows reached");
        require(msg.value >= mintPrice, "!price");

        swapNativeToLINK();

        bytes32 requestId = requestRandomness(keyHash, linkFee);

        _tokenIds.increment();

        VRFRequests[requestId] = VRFRequest({
            id: _tokenIds.current()
        });

        _safeMint(msg.sender, _tokenIds.current());
    }


    function swapNativeToLINK() public payable {

        uint256 amount = ((getNativePrice() * linkFee) / 1 ether) * (100 + splippagePercentage) / 100;

        unirouter.swapETHForExactTokens {
            value: msg.value
        }(amount, wnativeToLinkRoute, address(this), block.timestamp);

        pegswap.swap(linkFee, address(linkToken), address(wLinkToken));
    }

    function getNativePrice() public view returns(uint) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) =  maticLinkPriceFeed.latestRoundData();
        roundID;
        startedAt;
        timeStamp;
        answeredInRound;
        return uint(price);
    }


    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
        cows[VRFRequests[_requestId].id].dna = _randomNumber;
        emit GenerateCow(VRFRequests[_requestId].id, _randomNumber);
    }

    function imageData(uint256 _tokenId) public view returns(string memory) {
        require(_exists(_tokenId), "imageData: nonexistent token");
        require(cows[_tokenId].dna != 0, "imageData: dna not yet generated");

        uint8[14] memory dna = splitNumber(cows[_tokenId].dna);

        return string(abi.encodePacked(
            "<svg id='cow", _tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>",
            getSVGContent(dna),
            "</svg>"
        ));
    }

    function backgroundIpfs(uint8 randomNum) internal view returns(string memory) {
        if (randomNum < 64) {
            return art.background[0].ipfs;
        } else if (randomNum < 128) {
            return art.background[1].ipfs;
        } else if (randomNum < 64) {
            return art.background[2].ipfs;
        } else {
            return art.background[3].ipfs;
        }
    }

    function imageData(uint256 _tokenId, string memory _gateway) public view returns(string memory) {
        require(_exists(_tokenId), "imageData: nonexistent token");
        require(cows[_tokenId].dna != 0, "imageData: dna not yet generated");

        uint8[14] memory dna = splitNumber(cows[_tokenId].dna);

        if (keccak256(abi.encodePacked(_gateway)) == keccak256(abi.encodePacked("ipfs"))) {
            return string(abi.encodePacked(
                "<svg id='cow", _tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>",
                getSVGContentWithIPFS(dna),
                "</svg>"));
        }

        return string(abi.encodePacked(
            "<svg id='cow", _tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>",
            getSVGContent(dna, _gateway),
            "</svg>"));
    }

    function getSVGContent(uint8[14] memory _dna, string memory _gateway) internal view returns(string memory) {
        return string(abi.encodePacked(getSVGContentPart1(_dna, _gateway), getSVGContentPart2(_dna, _gateway)));
    }

    function getSVGContentPart1(uint8[14] memory _dna, string memory _gateway) internal view returns(string memory) {
        return string(abi.encodePacked(
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.background[_dna[0]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.body[_dna[1]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.hair[_dna[2]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.eyes[_dna[3]].ipfs, "' />"
        ));
    }

    function getSVGContentPart2(uint8[14] memory _dna, string memory _gateway) internal view returns(string memory) {
        return string(abi.encodePacked(
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.accsBody[_dna[4]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.accsFace[_dna[5]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://", _gateway, "/ipfs/", art.hat[_dna[6]].ipfs, "' />"
        ));
    }

    function getSVGContentWithIPFS(uint8[14] memory _dna) internal view returns(string memory) {
        return string(abi.encodePacked(
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.background[_dna[0]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.body[_dna[1]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.hair[_dna[2]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.eyes[_dna[3]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.accsBody[_dna[4]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.accsFace[_dna[5]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='ipfs://", art.hat[_dna[6]].ipfs, "' />"
        ));
    }

    function getSVGContent(uint8[14] memory _dna) internal view returns(string memory) {
        return string(abi.encodePacked(
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.background[_dna[0]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.body[_dna[1]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.hair[_dna[2]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.eyes[_dna[3]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.accsBody[_dna[4]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.accsFace[_dna[5]].ipfs, "' />",
            "<image x='0' y='0' width='100' height='100' href='https://ipfs.io/ipfs/", art.hat[_dna[6]].ipfs, "' />"
        ));
    }

    function metadata(uint256 _tokenId) public view returns(string memory) {
        require(_exists(_tokenId), "metadata: nonexistent token");
        require(cows[_tokenId].dna != 0, "metadata: dna not yet generated");

        uint8[14] memory dna = splitNumber(cows[_tokenId].dna);

        Item[7] memory artItems = [
            art.background[dna[0]],
            art.body[dna[1]],
            art.hair[dna[2]],
            art.eyes[dna[3]],
            art.accsBody[dna[4]],
            art.accsFace[dna[5]],
            art.hat[dna[6]]
        ];

        string memory attributes;

        string[3] memory traitType = ["Background", "Body", "Accesories"];

        for (uint256 i = 0; i < artItems.length; i++) {
            if (keccak256(abi.encodePacked(artItems[i].name)) == keccak256(abi.encodePacked(""))) continue;
            attributes = string(abi.encodePacked(attributes,
                bytes(attributes).length == 0 ? "{" : ", {"
                '"trait_type": "', traitType[i], '", ',
                '"value": "', artItems[i].name, '"',
                '}'
            ));
        }

        return string(abi.encodePacked(
            '{',
            '"name": "Cow #', _tokenId.toString(), '",',
            '"description": "Cows are randomly generated using Chainlink VRF. Only 8000 will ever exist!",',
            '"image_data": "', imageData(_tokenId), '",',
            '"external_url" "https://nfts.beefy.finance/cows/"', _tokenId.toString(), '",',
            '',
            '}'
        ));
    }

    function splitNumber(uint256 _number) internal pure returns(uint8[14] memory) {
        uint8[14] memory numbers;

        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint8(_number % 10);
            _number /= 10;
        }

        return numbers;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call {
            value: address(this).balance
        }('');
        require(success, "Withdrawal failed");
    }

    receive() external payable {}

    // Contract management.

    function pauseSale() external onlyOwner {
        _pause();
    }

    function unpauseSale() external onlyOwner {
        _unpause();
    }

    function setLinkFee(uint256 _linkFee) external onlyOwner {
        linkFee = _linkFee;
    }

    // Emergency functions.

    /**
     * @dev Rescues random funds stuck that the contract can't handle.
     * @param _token address oof the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;

interface IPegSwap {
    /**
     * @notice exchanges the source token for target token
     * @param amount count of tokens being swapped
     * @param source the token that is being given
     * @param target the token that is being taken
     */
    function swap(
        uint256 amount,
        address source,
        address target
    )
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Art {
    struct Item {
        string name;
        string ipfs;
    }

    struct ArtStore {
        mapping(uint256 => Item) background;
        mapping(uint256 => Item) body;
        mapping(uint256 => Item) hair;
        mapping(uint256 => Item) eyes;
        mapping(uint256 => Item) accsBody;
        mapping(uint256 => Item) accsFace;
        mapping(uint256 => Item) hat;
    }

    ArtStore internal art;

    constructor () {
        art.background[0] = Item("Arbitrum", "QmS61BXRdY5C3MZeHr6YfWcANBaisz6d3CARdvmvkqYHev");
        art.background[1] = Item("Avalanche", "QmSKjkrcMJeZx6c9yjWZz3tHNqfwiQwgkvMP5ae7m6BjRa");
        art.background[2] = Item("BSC", "QmS9aJutAiuonqHpgemFq4KSHvMS7R3D7KYNFJ2ZuayXuK");
        art.background[3] = Item("Celo", "QmeE8j2VFizW6paXF5bYdsXHiLFRkoWM7x1iMXUYfnBerU");
        art.background[4] = Item("Ethereum", "QmebRDUCERUdUGD2TCquXji8k4n9XiB9KW8E3y7bnaih4R");
        art.background[5] = Item("Fantom", "QmQd5mNttnPA2USEGKaNdukyo2rqwsG4NFXtEx3N1TjXnh");
        art.background[6] = Item("Moonriver", "QmNh8pmaccg9nUXBPAvyghGdgW82ptMwMbUnJy2LVbXjhA");
        art.background[7] = Item("Polygon", "QmPHWNKi4WRuE7U5xamvbNknUtXmDRBymeyWYzWLBoz4tW");
        art.background[8] = Item("Harmony", "QmYYU4pCnZEcQ7s5n6Rwt8oyYzX1QNiJHkPAzU3oC7ghjb");
        art.background[9] = Item("Heco", "QmSU96uhmqWajyhYvoytSH6T1mtNsCQxqQN6bbwr3geYx8");
        art.background[10] = Item("Multichain", "QmYnjkZgM5NFTsS3uubt46vZq3pkWWUSZuDWxE2ufcpMxC");
        art.background[11] = Item("Beach", "QmamWxMQ85YQHhohNQonRdhN7jaYyj1L644Ug8Kq2SLvea");
        art.background[12] = Item("Moon", "QmPMPYM8dbHbmhz1HhMxjqhyYjFoyL4AV9vGiuBSMWfng6");
        art.background[13] = Item("Pastures", "QmWNTT1pn1kYCKWC7fFNPzNa6dc6rq3zAMngU4ZPNVrxEC");
        art.background[14] = Item("Psychedelic", "QmXf7znngpixoQ2ZuRnmidtcqwJPs7Pu5zToKo7yZoWFtj");
        art.background[15] = Item("Snow", "Qmcr57vWi2hxMRtgCbAGodyQosK4phbpKsUb34aL6cdgjo");
        art.background[16] = Item("Green", "QmQzTmoinbrqqnDWb14YP3U6UHQxR4AEkPke8Kkw4GRZhr");
        art.background[17] = Item("Yellow", "Qmd1V9i2noHuMU1VBSrHW1dKCPfwLf7NrVLcRqMYDhM9EM");
        art.background[18] = Item("Red", "QmVy3kejLwDS5vyRaJL9CZEZTesWJJidJDeCB1y6LmUEJ9");
        art.background[19] = Item("Purple", "QmYKBwRJew6rgLXQibwzatBsnYji4NAx1oQNim6nBhoN66");
        art.background[20] = Item("Blue", "QmSaLTDRguvE8n1HEjD31yEaeXGYJJYLN9MNXmPSu9oG9h");

        art.body[0] = Item("Arbitrum", "QmUxmTN5FZQqGm4yUdxXf1eU24Wqq8kfimvrQ1WZLrKXzD");
        art.body[1] = Item("Avax", "QmXi6ZP5EkwXT4kVzVWmAwNQRRw8HARV691WvURZv5cWNr");
        art.body[2] = Item("BSC", "QmU6MfyYkoC3XfBAxNkWtLPs9NgHdt7uFvCZQBEbz53DKh");
        art.body[3] = Item("Celo", "QmZj6U4ESUSU1PfEJmG7QG8CWEKRkwtAkhX48cdguGDhue");
        art.body[4] = Item("Ethereum", "QmVxwWZKRhoXYfHD6ZSFt2m5d8xkuBzxQ15saHbJ2aPyC6");
        art.body[5] = Item("Fantom", "QmeyCehW4JnxtPvWbHknoGb84ZS5ojUgFr1aQwHvGek2fS");
        art.body[6] = Item("Harmony", "QmRCi8kF4d68demLvxvNkXseRG5MrhpP8W5bsJSPgo4Zj6");
        art.body[7] = Item("Heco", "QmT34Qwb9KR9MP1vJENzUyCGYTjk5FhQd8VxfWirfavmmK");
        art.body[8] = Item("Moonriver", "QmWW1XpnQ8pbvFQAURtKsbnq8szFr71dr2LDMmWiouspsq");
        art.body[9] = Item("Polygon", "QmdGZwekGVimg7a44Mw1g8FFVQ2YLSwZeDj6kTxvMa6Z8R");
        art.body[10] = Item("Ape suit", "QmeWBQv8LfYAhTDp1khF6EL55rcesvZMBazpuuByxdYK5V");
        art.body[11] = Item("Armored cow", "QmYcJuxSaYXEv1fVP2Yr2MQucFrTZoCeTqaFazRgo5secU");
        art.body[12] = Item("BDSM", "QmcXKShGh77Pxb5tofqC3qptzNDbqcMDb6AKPveX76pCPp");
        art.body[13] = Item("Black suit", "QmYXH9sg6vp7B8fCUw3PJAUqvJKXdVGBsMskKV9Tp4GQ1W");
        art.body[14] = Item("Blue jacket", "QmS6d9WCyzhZrX9Chq6ZHQGEt8Lnkxh5e3LTH2VeF9qQdV");
        art.body[15] = Item("Blue sweater", "QmUmacVtnUAwzQ9ds9ZaJdsQD6EDYP6FxPYgLnjHpkGkbJ");
        art.body[16] = Item("Chicken suit", "QmfRN7i9Cb3WYmYBDwwYBvFm5p6ZZorjqnroqXMxsgqwyp");
        art.body[17] = Item("Cowboy suit", "QmdkBmw1dfPKqBdmWBzCEV777LXYKMDU4wT2YsqYL8AKHA");
        art.body[18] = Item("Cyborg skin", "QmR3Tkb8tzSPhpweRQBbtXSkt9ovWjkHCDm9W3UvmnKHjz");
        art.body[19] = Item("Farmer suit", "QmNSpmFCHaS8NBwrV6daec4ozMXE86pTcAeChS34D1Ln3k");
        art.body[20] = Item("Hawai shirt", "QmaH4Ra2szcAnHTK5RGkN1Ft7G5oQeFNnAB72odsrhQWjK");
        art.body[21] = Item("Alien", "QmNeM6WeLmdQV2XdeBhpfkpYeQT7SKXChDKGiX7nDoPHdQ");
        art.body[22] = Item("Moonpot", "QmVdvTDozaBDwYXJySN2PL7G1mcjJzqfDAfUg1WdMe95kJ");
        art.body[23] = Item("Zombie", "QmaJeoZf5bJTETr4qXLXErviUiK8CQP1RYwAHrQwCsn2ra");

        art.eyes[0] = Item("Normal eyes", "QmQ8y27FUUS4PjtyMWpLwFq3YRJougLV7LFXsZNdWah2Fa");
        art.eyes[1] = Item("Anime eyes", "QmXqDs8yYTr8Lpg4shJrJH8hFjjX7kVVT3jGpE1V6q22Hm");
        art.eyes[2] = Item("Pleading eyes", "QmUBfyUNipDg8wij5xSDbctueQB3CpzQGWw1oH8kw2sg7v");
        art.eyes[3] = Item("Tired eyes", "QmTJHVcYCbMYTNzKsiQyNfx6uCKB3GgtFocNTxwvVpJjxG");

        art.accsFace[0] = Item("Left ear one ring gold", "Qmab754zAgfa7iYzpQjLDCa7ZVSouVobUffAvtYc44JzXK");
        art.accsFace[1] = Item("Left ear one ring", "QmQKdYGckm33DrYyHWe1X7iEe2nP2mC39yonSNSpUvQpr5");
        art.accsFace[2] = Item("Left ear two rings gold","QmUH8cyi9qqWGrk1gYUKzMzrkLTSmJN8mBrBwLH4PEdH4f");
        art.accsFace[3] = Item("Left ear two rings", "QmaMa1LUx7uxwGfRiRKENrg6jkDfjmz7eha5msU9iShQWc");
        art.accsFace[4] = Item("Pirate eye patch gold", "QmXR5xWYpKB4kkXeCP2Hm3P9Y3Ygh5Eo1cYsPrHc8DKJws");
        art.accsFace[5] = Item("Aviator blue sunglasses", "QmT9G2MZYetbvttkdQ2w69ygcKR3VrPhxqixc2Vr5W58Q3");
        art.accsFace[6] = Item("Aviator sunglasses gold", "QmWVM9ksMdYaKrss88dTHmNEFuHhtrZPqD3qbgMwyKqP43");
        art.accsFace[7] = Item("Cigare", "QmZ9GfYw1coDtaDViTUXZDZb836RrGH2mnLrGexFi2vnHN");
        art.accsFace[8] = Item("Cigare gold", "QmPRg5UrTWUuADposUqUtUdJwKVfm7ee1EakKr28vWZgAn");
        art.accsFace[9] = Item("Earrings each ear", "Qme8p43CSjunYBVtGLnWD3V8JLj9HomQiVak7eC73Nu5zu");
        art.accsFace[10] = Item("Earrings each ear gold", "QmerJ992cLzRxN1AQzV1EzEy7AeqZMzbYRnMtGYGqvQatM");
        art.accsFace[11] = Item("Laser eyes", "QmcsXcVuJCp5JRw7eragpuw5WrzTbySpUVZvaJxfQd6GhD");
        art.accsFace[12] = Item("Laser eyes gold", "QmT13V1XGzusK7RZDZWB1TtKibX9j624ht3dVkFGA4paVJ");
        art.accsFace[13] = Item("Monocle", "QmYpFgDKQet4ewLEq7n6PGzUH8ZH4VFb8nE2bYj3rbyBai");
        art.accsFace[14] = Item("Monocle gold", "QmXqHKSqJj3qBVZ1aN8pfhBnwm8JmqLvTpzidpLPGnB1cg");
        art.accsFace[15] = Item("Multichain earring", "QmU94afJao9FnT2jMNPTh6y2zyhfKzJAiKn1s7wsBLekYT");
        art.accsFace[16] = Item("Multichain earring gold", "Qmf3fgwUmGkXtMfi85SPnAeywdNmMyjbRUDMt8Ksch579z");
        art.accsFace[17] = Item("Pipe", "QmezF7KzACTnnHRXAA39dn1A8vAS9A6ap2fqYD9ETW88Nd");
        art.accsFace[18] = Item("Pipe gold", "QmdZW284ozSxnxpLLDhCFxN55Pqa3VYnSXkFX4abbf7TrL");
        art.accsFace[19] = Item("Pirate eye patch", "QmU88fXziJWNpj4t9UFHVs9Vcvu32zyzoJB7wfyqE1Jbno");
        art.accsFace[20] = Item("Rayban sunglasses", "QmXNwbCLH2JR4gYM4EVRjGyEkPWKQQWDKTjdYRXbEPSP7U");
        art.accsFace[21] = Item("Rayban sunglasses gold", "QmetexU9n555iV3HVwqxtfKLTVNJXGQdjj52DvQ5vafHrX");
        art.accsFace[22] = Item("Spliff", "QmR7rAAC5g3WYE89bkTVjFi3wf3KA9goPrZRynGSxGMhM5");
        art.accsFace[23] = Item("Spliff gold", "QmeyayjdHzZFFUaKFKzcrFxSTiHqNfX33Q8NEgHS6pAxu8");

        art.accsBody[0] = Item("'This is fine' necklace", "QmTa2nygb2mvgtrcY4skLeACVQQhGgT51rL1tRzyRo4jJ6");
        art.accsBody[1] = Item("'This is fine' necklace gold", "QmWUCcrE11QaJ5fjg5UbZTWkNXwwPVbb5xCRmBEwAno4RM");
        art.accsBody[2] = Item("BIFI maxi necklace", "QmWb1RSRGtf1NFWE6P9nx8xG7LintsMvz6fXdTkqqnTbeA");
        art.accsBody[3] = Item("BIFI maxi necklace gold", "QmRf3PUk3Suyg6pKs2BwRzs8FtsusvBVu1J173UsqKygWo");
        art.accsBody[4] = Item("Farmer pitchfork", "QmTCiRjQNYHF4x7zsELEKV51RZfx8SJyGtFr7dVDFTDGUu");
        art.accsBody[5] = Item("Farmer pitchfork gold", "QmcS7aUkP53eQmPAidvvVwXWQa8ic3wH4Bzf3ayuT8yyAN");
        art.accsBody[6] = Item("Moo necklace", "QmSRHG5wq8rTnfAaWHui9A5Qyb8tXmZ6aGoA32DjCAmAr7");
        art.accsBody[7] = Item("Moo necklace gold", "QmeUjuy5rodvqW54AoaW8ypvzuesSkqMhoXFkLQiZBWpnZ");
        art.accsBody[8] = Item("Presidential sash", "QmV7imP7VuehSN7W1yghNHkYK9LYPopff6MA8k1iff5rEW");
        art.accsBody[9] = Item("Presidential sash gold", "QmZ3Ag3ty71RZQcXJrNE5ZXBJnki7yydBTkJ1Li56CpkdY");
        art.accsBody[10] = Item("SAFU necklace", "QmZ5DKK6GGisqL3KvvinaUTiJFzeNzpdrLpoKXUbDMrgaL");
        art.accsBody[11] = Item("SAFU necklace gold", "QmRGSw4m9tjU8iJ1mWnyE8WGvgVRcSqehfimFiSknHR1EG");
        art.accsBody[0] = Item("Vault key", "QmNp9ZR3jVjPvKhkw3zSCzdTDSHgRBMzoaVquC34X65SVb");
        art.accsBody[0] = Item("Vault key gold", "Qmf4bxovQxgFdYXxkLroSnJW1pRnT6qpiWfqcZW2eW1P5w");

        art.hair[0] = Item("Mr. T hair", "Qmaj4VPh3rLzraAgZwGJbANkJTsqodFtna65YN1y8LJcm7");
        art.hair[1] = Item("Cow wig", "QmNuMUfiTYNnJ3oD9h7FWJNr9mpZeoP8mV7tU6s3G1myXV");
        art.hair[2] = Item("Mohawk hair", "QmWxn9aTmpghw8y8umg3QTdtqwyHgg3mMhefVmGmTnCmit");
        art.hair[3] = Item("Rasta hair", "QmZ8Sjf4qaR3gSLiSUkAu67edNhZvba2xh8yXz626qP2BJ");
        art.hair[4] = Item("Short hair", "QmQ4vQw72w3yRzwFWft9icnVtkujJNAWCRCkSeQByxVBM3");

        art.hat[0] = Item("Cowboy hat", "QmVYBqmNeSm1YGEEwFjS3gfciQ8izPwuNDjHifsiT7nfm1");
        art.hat[1] = Item("Cowboy golden hat", "QmPRuoKdNaa5Qa3pGGpZtojsoFUEtXEVCj5URxe73qrZ84");
        art.hat[2] = Item("Arbitrum hat", "QmaAdsJBDP6iajTwskypGvA5HPfReV2zZm8cw8624mw1YR");
        art.hat[3] = Item("Arbitrum golden hat", "QmWXAcJuqbgXXASycNYEg3TFK77G8h4zdE4rChsA7uyJQj");
        art.hat[4] = Item("Avalanche hat", "QmPgsFZ6NfCdQeUgJY3uMmKuTA1NGohqMHkWi7R6tT5un1");
        art.hat[5] = Item("Avalanche golden hat", "QmXEkPsKc9wAqsyTikv3FF3wN9vznNJexwTvztb2ygpwzd");
        art.hat[6] = Item("BSC hat", "QmbQvqSiTgfpjAhqendTkomaVECBh8uaKTRUq9NL75ubKe");
        art.hat[7] = Item("BSC golden hat", "QmPxGYW8VemNXLbRGBifirnutthtEqRSJNeZsB2fBWfGHy");
        art.hat[8] = Item("Celo hat", "QmSNAS5rqTFowKQfm1z6hq5B5fq5pv4ZZ6CK3j8yPz5b8s");
        art.hat[9] = Item("Celo golden hat", "QmZSaUYd9iM34cSbjXcXkrZzQFj2C2ZRahhHEPwnWEi8ZY");
        art.hat[10] = Item("Ethereum hat ", "QmQe9nPzUXYTHMmAJpjGje1D6bJW1xPDF11jXgQJKkYWzP");
        art.hat[11] = Item("Ethereum golden hat", "QmPydos5pHersHgpHMtfxWTzAJRQxUEUD8bTyu5TVZDA8B");
        art.hat[12] = Item("Ethereum rainbow hat", "QmephVnLvAr6gXxKkjMCwmnPJ7C33urdVr18ENXxSFEvTP");
        art.hat[13] = Item("Ethereum rainbow golden hat", "QmTJJxeCs5axSNDwtkvzLKcNVKerV14ARuv32BahpJXDJH");
        art.hat[14] = Item("Fantom hat", "QmbpxcnfAPAivEhRqbQLk5Nz5PZXvQb1cvsuRaJTc4hMLP");
        art.hat[15] = Item("Fantom golden hat", "QmPfmUBbVfFJ8gYKXtQJAUQe2kysEjn5Cs69yaqNHx66t1");
        art.hat[16] = Item("Harmony hat", "QmZKgEBXo7XZqAUWmbpp9JY4hr7PGFVdjXEhDgMs5Z6CyY");
        art.hat[17] = Item("Harmony golden hat", "QmcysPSdYcMzhzTvyY5bCT2uT3H5JXUREvthfHE9p9CTXF");
        art.hat[18] = Item("Heco hat", "QmRuY5HXTjWe8ruw8PMX7w7DV7G9nDa2cpSXNHHTYY7XZf");
        art.hat[19] = Item("Heco golden hat", "QmbCkpLDVUjm4QhUEB6t5KJtz6dGALoUxq4PKVHL3AiFnK");
        art.hat[20] = Item("Moonriver hat", "QmYqRiQWYxYeNagqZH3g3rdDJG34zpgCCJKW7FRvxMMPjr");
        art.hat[21] = Item("Moonriver golden hat", "QmZFg5xBaSqHWsBW92qiv8epkPSExzBzKJzsRdrVk6XXW3");
        art.hat[22] = Item("Polygon hat", "QmevhxAHEZDSus22zqsKPna16mcGdFQfmr8evQZmLh1uTM");
        art.hat[23] = Item("Polygon golden hat", "QmdYnLvUk18xsSnwGJ5oty4LTeM8djZ9bfrptEHyfGbpEz");
        art.hat[24] = Item("Straw hat", "QmR8B1oy6X5vPPHbF5hhqQCXe3meSupQ7mNiFm8cDsMvoG");
        art.hat[25] = Item("Straw golden hat", "QmS4MgKgLGJMsnPyZAed9f1C53FwcTB3zQo5nrxoVMip1i");
        art.hat[26] = Item("Top hat", "Qmf2VfEB4bHMHhwWBhxx6HjLAMA7t8LtMbmkpMnuZ173dH");
        art.hat[27] = Item("Top hat golden hat", "QmaSAdvSQL6HjmZgtbaWdajcy3R4sMg2VGBj4nCuXEfoDR");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}