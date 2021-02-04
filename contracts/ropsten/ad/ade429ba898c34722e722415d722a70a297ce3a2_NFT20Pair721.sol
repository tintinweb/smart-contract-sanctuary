pragma solidity ^0.6.0;

// ERC1155
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ERC20.sol";

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IFactory {
    function fee() external view returns (uint256);
}

contract NFT20Pair1155 is ERC20, ERC1155Receiver {
    address public factory;
    address public nftAddress;
    uint256 public nftType;
    uint256 public nftValue;

    mapping(uint256 => uint256) public track1155;

    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet lockedNfts;

    event Withdraw(uint256[] indexed _tokenIds, uint256[] indexed amounts);

    // create new token
    constructor() public {}

    function initialize(
        string memory name,
        string memory symbol,
        address _nftAddress,
        uint256 _nftType
    ) public {
        factory = msg.sender;
        super.init(name, symbol);
        nftAddress = _nftAddress;
        nftType = _nftType;
        nftValue = 100 * 10**18;
    }

    function getInfos()
        public
        view
        returns (
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _type = nftType;
        _name = name();
        _symbol = symbol();
        _supply = totalSupply() / 100 ether;
    }

    // withdraw nft and burn tokens
    function withdraw(uint256[] calldata _tokenIds, uint256[] calldata amounts)
        external
    {
        if (_tokenIds.length == 1) {
            burn(nftValue.mul(amounts[0]));
            _withdraw1155(address(this), msg.sender, _tokenIds[0], amounts[0]);
        } else {
            _batchWithdraw1155(address(this), msg.sender, _tokenIds, amounts);
        }

        emit Withdraw(_tokenIds, amounts);
    }

    function _withdraw1155(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 value
    ) internal {
        track1155[_tokenId] = track1155[_tokenId].sub(value);
        if (track1155[_tokenId] == 0) {
            lockedNfts.remove(_tokenId);
        }
        IERC1155(nftAddress).safeTransferFrom(_from, _to, _tokenId, value, "");
    }

    function _batchWithdraw1155(
        address _from,
        address _to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 qty = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            track1155[ids[i]] = track1155[ids[i]].sub(amounts[i]);
            if (track1155[ids[i]] == 0) {
                lockedNfts.remove(ids[i]);
            }
            qty = qty + amounts[i];
        }
        // burn tokens
        burn(nftValue.mul(qty));

        IERC1155(nftAddress).safeBatchTransferFrom(
            _from,
            _to,
            ids,
            amounts,
            "0x0"
        );
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256 value,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(nftAddress == msg.sender, "forbidden");

        if (!lockedNfts.contains(id)) {
            lockedNfts.add(id);
        }

        track1155[id] = track1155[id].add(value);
        uint256 fee = IFactory(factory).fee();
        _mint(factory, (nftValue.mul(value)).mul(fee).div(100));
        _mint(
            operator,
            (nftValue.mul(value)).mul(uint256(100).sub(fee)).div(100)
        );
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(nftType == 1155, "forbidden");
        require(nftAddress == msg.sender, "forbidden");

        uint256 qty = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            if (!lockedNfts.contains(ids[i])) {
                lockedNfts.add(ids[i]);
            }

            qty = qty + values[i];

            track1155[ids[i]] = track1155[ids[i]].add(values[i]);
        }
        uint256 fee = IFactory(factory).fee();
        _mint(
            operator,
            (nftValue.mul(qty)).mul(uint256(100).sub(fee)).div(100)
        );

        _mint(factory, (nftValue.mul(qty)).mul(fee).div(100));

        return this.onERC1155BatchReceived.selector;
    }

    // set new price
    function setParams(
        uint256 _nftType,
        string calldata name,
        string calldata symbol
    ) external {
        require(msg.sender == factory, "!authorized");
        nftType = _nftType;
        _name = name;
        _symbol = symbol;
    }
}