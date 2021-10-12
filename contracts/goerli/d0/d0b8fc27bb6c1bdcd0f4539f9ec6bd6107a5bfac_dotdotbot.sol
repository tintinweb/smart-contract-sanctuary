/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.7;

interface ERC721Stripped {
    function setApprovalForAll(address op, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

interface dotdotdot is ERC721Stripped {
    function mint(uint256 numberOfTokensMax5) external payable;
}

contract dotdotbot is ERC721TokenReceiver {
    // the address of the dotdotdot contract implementation
    address private _dotdotdotContract;
    address private _owner;
    mapping(address => bool) private whitelisted;

    // the tokens owned by the contract
    mapping(address => uint256[]) private ownedTokens;

    uint256 public constant PRICE = 50000000000000000; // 0.05 eth

    constructor() {
        _owner = msg.sender;
        whitelisted[msg.sender] = true; // deployer of the contract gets whitelisted
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        ownedTokens[_operator].push(_tokenId); // add our owned token id
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "you must be an owner to execute this function"
        );
        _;
    }

    modifier onlyWhitelist() {
        require(
            whitelisted[msg.sender],
            "you must be whitelisted to perform this action"
        );
        _;
    }

    function setWhitelisted(address addr, bool status) public onlyOwner {
        whitelisted[addr] = status;
    }

    // sets the implementation of the dotdotdot interface
    function setImplementation(address addr) public onlyOwner {
        _dotdotdotContract = addr;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    // be able to
    function deposit() public payable onlyWhitelist {}

    function withdraw() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function tryMint(uint256 count) public onlyWhitelist {
        dotdotdot(_dotdotdotContract).mint{value: PRICE * count}(count);
    }

    function transferToOwner() public onlyOwner {
        ERC721Stripped(_dotdotdotContract).setApprovalForAll(_owner, true);
        for (uint256 i = 0; i < ownedTokens[_dotdotdotContract].length; i++) {
            uint256 token = ownedTokens[_dotdotdotContract][i];
            ERC721Stripped(_dotdotdotContract).safeTransferFrom(
                address(this),
                _owner,
                token
            );
        }

        delete ownedTokens[_dotdotdotContract];
    }
}