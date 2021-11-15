// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;

abstract contract IERC165 {
    function supportsInterface(bytes4 interfaceID)
        external
        view
        virtual
        returns (bool);
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;

/// @title 不可分割代币标准
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// Note: ERC165标识符为0x80ac58cd

interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;


abstract contract IERC721TokenReceiver {
    bytes4 internal constant ERC721_RECEIVER_RETURN = 0x150b7a02;
    bytes4 internal constant ERC721_BATCH_RECEIVER_RETURN = 0x0f7b88e3;

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external virtual returns (bytes4);

    // bytes4(keccak256("onERC721ExReceived(address,address,uint256[],bytes)")) = 0x0f7b88e3
    function onERC721ExReceived(
        address operator,
        address from,
        uint256[] memory tokenIds,
        bytes memory data
    ) external virtual returns (bytes4);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


library Address {
    // 该方法目的是为了防止合约调用方法.但合约构造时codesize为0,所以不能总是符合预期
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));

        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;

library UintLibrary {
    function toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}

library String {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);

        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory babc = new bytes(_ba.length + _bb.length + _bc.length);

        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babc[k++] = _bc[i];

        return string(babc);
    }

    function equals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);

        uint256 la = ba.length;
        uint256 lb = bb.length;

        for (uint256 i = 0; i != la && i != lb; ++i) {
            if (ba[i] != bb[i]) {
                return false;
            }
        }

        return la == lb;
    }

    function toSigHash(string memory message) internal pure returns (bytes32) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
        );
        return keccak256(fullMessage);
    }

    function concat(
        bytes memory _ba,
        bytes memory _bb,
        bytes memory _bc,
        bytes memory _bd,
        bytes memory _be,
        bytes memory _bf,
        bytes memory _bg
    ) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(
            _ba.length +
                _bb.length +
                _bc.length +
                _bd.length +
                _be.length +
                _bf.length +
                _bg.length
        );

        uint256 k = 0;

        for (uint256 i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint256 i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint256 i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];

        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../role/Ownable.sol";

contract Manager is Ownable {
    /// Oracle=>"Oracle"

    mapping(string => address) public members;

    mapping(address => mapping(string => bool)) public permits; //地址是否有某个权限

    function setMember(string memory name, address member) external onlyOwner {
        members[name] = member;
    }

    function setUserPermit(
        address user,
        string calldata permit,
        bool enable
    ) external onlyOwner {
        permits[user][permit] = enable;
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Manager.sol";

abstract contract Member is Ownable {
    //检查权限
    modifier CheckPermit(string memory permit) {
        require(manager.permits(msg.sender, permit), "no permit");
        _;
    }

    Manager public manager;

    function getMember(string memory _name) public view returns (address) {
        return manager.members(_name);
    }

    function setManager(address addr) external onlyOwner {
        manager = Manager(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "../role/Member.sol";

contract DiaoTotem is ERC721, Member {
    // race=>karma
    mapping(uint256 => uint256) internal karmaBase;
    // rarery=>karma buff
    mapping(uint256 => uint256) internal karmaBuff;

    // rarety=>supply
    mapping(uint256 => uint256) internal originalSupply;
    // tokenId=>warshipBuff(persent * 10000)
    mapping(uint256 => uint256) internal warshipBuff;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURIPrefix
    ) ERC721(_name, _symbol, _tokenURIPrefix) {}

    // ======================Assets=====================
    function mint(address owner, uint256 id) public CheckPermit("Mint") {
        _mint(owner, id);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function setKarmaBase(uint256 race, uint256 _base)
        public
        CheckPermit("Config")
    {
        karmaBase[race] = _base;
    }

    function getKarmaBase(uint256 race) public view returns (uint256) {
        return karmaBase[race];
    }

    function setWarshipBuff(uint256 tokenId, uint256 buff)
        external
        CheckPermit("Warship")
    {
        warshipBuff[tokenId] = buff;
    }

    function getWarshipBuff(uint256 tokenId) public view returns (uint256) {
        return warshipBuff[tokenId];
    }

    function setOriginalSupply(uint256 rarety, uint256 supply)
        public
        CheckPermit("Config")
    {
        originalSupply[rarety] = supply;
    }

    function getOriginalSupply(uint256 rarety) public view returns (uint256) {
        return originalSupply[rarety];
    }

    function setKarmaBuff(uint256 rarety, uint256 buff)
        public
        CheckPermit("Config")
    {
        karmaBuff[rarety] = buff;
    }

    function getKarmaBuff(uint256 rarety) public view returns (uint256) {
        return karmaBuff[rarety];
    }

    function parseTokenId(uint256 tokenId)
        public
        pure
        returns (
            uint256 race,
            uint256 design,
            uint256 rarety,
            uint256 index
        )
    {
        uint256 clipTokenId = tokenId % 10**10;
        race = clipTokenId / 10**7;
        design = (clipTokenId % 10**7) / 10**4;
        rarety = (clipTokenId % 10**4) / 10**3;
        index = clipTokenId % 10**3;
    }

    function buildNewTokenId(
        uint256 race,
        uint256 rarety,
        uint256 design,
        uint256 index
    ) public pure returns (uint256) {
        // build new tokenId
        uint256 sessionPart = 1 * 10**10;
        uint256 racePart = race * 10**7;
        uint256 designPart = design * 10**4;
        uint256 raretyPart = rarety * 10**3;
        uint256 indexPart = index;

        uint256 newTokenId = sessionPart +
            racePart +
            designPart +
            raretyPart +
            indexPart;
        return newTokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interface/IERC165.sol";
import "../interface/IERC721.sol";
import "../interface/IERC721Metadata.sol";
import "../interface/IERC721TokenReceiver.sol";
import "./ERC721TokenURI.sol";
import "../lib/Address.sol";
import "../role/Ownable.sol";

abstract contract ERC721 is
    IERC165,
    IERC721,
    IERC721Metadata,
    ERC721TokenURI,
    Ownable
{
    using Address for address;

    //* bytes4(keccak256("supportsInterface(bytes4)")) == 0x01ffc9a7
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /*
     *     bytes4(keccak256("balanceOf(address)")) == 0x70a08231
     *     bytes4(keccak256("ownerOf(uint256)")) == 0x6352211e
     *     bytes4(keccak256("approve(address,uint256)")) == 0x095ea7b3
     *     bytes4(keccak256("getApproved(uint256)")) == 0x081812fc
     *     bytes4(keccak256("setApprovalForAll(address,bool)")) == 0xa22cb465
     *     bytes4(keccak256("isApprovedForAll(address,address)")) == 0xe985e9c5
     *     bytes4(keccak256("transferFrom(address,address,uint256)")) == 0x23b872dd
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256)")) == 0x42842e0e
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 private constant INTERFACE_ID_ERC721Metadata = 0x5b5e139f;

    bytes4 private constant ERC721_RECEIVER_RETURN = 0x150b7a02;
    bytes4 internal constant ERC721_BATCH_RECEIVER_RETURN = 0x0f7b88e3;

    string public override name;
    string public override symbol;

    uint256 public totalSupply = 0;

    mapping(address => uint256[]) internal ownerTokens;
    mapping(uint256 => uint256) internal tokenIndexs;
    mapping(uint256 => address) internal tokenOwners;

    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal approvalForAlls;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURIPrefix
    ) ERC721TokenURI(_tokenURIPrefix) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "erc721:owner is zero address");
        return ownerTokens[owner].length;
    }

    function tokenOf(address owner) external view returns (uint256[] memory) {
        require(owner != address(0), "erc721:owner is zero address");

        uint256[] storage tokens = ownerTokens[owner];
        return tokens;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = tokenOwners[tokenId];
        return owner;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public payable override {
        _transferFrom(_from, _to, _tokenId);

        if (_to.isContract()) {
            require(
                IERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                ) == ERC721_RECEIVER_RETURN,
                "erc721:onERC721Received() return invalid"
            );
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        _transferFrom(_from, _to, _tokenId);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        require(_from != address(0), "erc721:from is zero address");
        require(_from == tokenOwners[_tokenId], "erc721:from must be owner");
        require(
            msg.sender == _from ||
                msg.sender == tokenApprovals[_tokenId] ||
                approvalForAlls[_from][msg.sender],
            "sender must be owner or approvaled"
        );

        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }

        _removeTokenFrom(_from, _tokenId);
        _addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external override {
        safeBatchTransferFrom(from, to, tokenIds, "");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        bytes memory data
    ) public override {
        batchTransferFrom(from, to, tokenIds);

        if (to.isContract()) {
            require(
                IERC721TokenReceiver(to).onERC721ExReceived(
                    msg.sender,
                    from,
                    tokenIds,
                    data
                ) == ERC721_BATCH_RECEIVER_RETURN,
                "onERC721ExReceived() return invalid"
            );
        }
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public override {
        require(from != address(0), "from is zero address");
        require(to != address(0), "to is zero address");

        uint256 length = tokenIds.length;
        address sender = msg.sender;

        bool approval = from == sender || approvalForAlls[from][sender];

        for (uint256 i = 0; i != length; ++i) {
            uint256 tokenId = tokenIds[i];

            require(from == tokenOwners[tokenId], "from must be owner");
            require(
                approval || sender == tokenApprovals[tokenId],
                "sender must be owner or approvaled"
            );

            if (tokenApprovals[tokenId] != address(0)) {
                delete tokenApprovals[tokenId];
            }

            _removeTokenFrom(from, tokenId);
            _addTokenTo(to, tokenId);

            emit Transfer(from, to, tokenId);
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        _addTokenTo(to, tokenId);
        ++totalSupply;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = tokenOwners[tokenId];
        _removeTokenFrom(owner, tokenId);

        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }

        emit Transfer(owner, address(0), tokenId);
    }

    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        uint256 index = tokenIndexs[_tokenId];

        uint256[] storage tokens = ownerTokens[_from];
        uint256 indexLast = tokens.length - 1;

        uint256 tokenIdLast = tokens[indexLast];
        tokens[index] = tokenIdLast;
        tokenIndexs[tokenIdLast] = index;

        tokens.pop();

        delete tokenOwners[_tokenId];
    }

    function _addTokenTo(address _to, uint256 _tokenId) internal {
        uint256[] storage tokens = ownerTokens[_to];
        tokenIndexs[_tokenId] = tokens.length;
        tokens.push(_tokenId);

        tokenOwners[_tokenId] = _to;
    }

    function approve(address _to, uint256 _tokenId) external payable override {
        address _owner = tokenOwners[_tokenId];
        require(
            msg.sender == _owner || approvalForAlls[_owner][msg.sender],
            "erc721:sender must be owner or approved for all"
        );

        tokenApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    function setApprovalForAll(address _to, bool _approved) external override {
        approvalForAlls[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        require(tokenOwners[_tokenId] != address(0), "nobody own then token");
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return approvalForAlls[_owner][_operator];
    }

    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            _interfaceId == INTERFACE_ID_ERC165 ||
            _interfaceId == INTERFACE_ID_ERC721 ||
            _interfaceId == INTERFACE_ID_ERC721Metadata;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _tokenURI(id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../lib/String.sol";

abstract contract ERC721TokenURI {
    using String for string;
    using UintLibrary for uint256;
    // Token URI prefix
    string public tokenURIPrefix;

    constructor(string memory _tokenURIPrefix) {
        tokenURIPrefix = _tokenURIPrefix;
    }

    // Returns an URI for a given token ID
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return tokenURIPrefix.append(tokenId.toString());
    }
}

