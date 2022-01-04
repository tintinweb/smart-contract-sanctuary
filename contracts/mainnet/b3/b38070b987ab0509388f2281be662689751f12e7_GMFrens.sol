// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./NativeMetaTransaction.sol";

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract GMFrens is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    string public baseTokenURI;
    uint256 private _currentTokenId = 0;
    uint256 MAX_SUPPLY = 6900;
    uint256 public totalReserved;

    uint256 public presaleTime = 1641567000;
    uint256 public publicSaleTime = 1641653400;
    uint256 public presalePrice = .03 ether;
    uint256 public publicSalePrice = .04 ether;
    uint256 withdrawn;

    mapping(address => uint8) public reservedAmount;
    mapping(address => uint8) public userClaimed;

    event Reserved(address user, uint8 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        _initializeEIP712(_name);
    }

    function mintByOwner(address[] memory recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(recipients[i], newTokenId);
            _incrementTokenId();
        }
        totalReserved += recipients.length;
    }

    function presaleReserve(uint8 num) external payable {
        require(
            block.timestamp >= presaleTime && block.timestamp < publicSaleTime,
            "GM Frens: Presale has not yet started."
        );
        require(totalReserved + uint256(num) <= MAX_SUPPLY);
        require(
            (num + reservedAmount[msg.sender]) <= 10,
            "GM Frens: Up to 10 GM Frens can be purchased."
        );
        require(
            msg.value == uint256(num) * presalePrice,
            "GM Frens: You need to pay the exact price."
        );
        reservedAmount[msg.sender] += num;
        totalReserved += uint256(num);
        emit Reserved(msg.sender, num);
    }

    function publicSaleReserve(uint8 num) external payable {
        require(
            block.timestamp >= publicSaleTime,
            "GM Frens: Public sale has not yet started."
        );
        require(totalReserved + uint256(num) <= MAX_SUPPLY);
        require(
            (num + reservedAmount[msg.sender]) <= 30,
            "GM Frens: Up to 30 GM Frens can be purchased."
        );
        require(
            msg.value == uint256(num) * publicSalePrice,
            "GM Frens: You need to pay the exact price."
        );
        reservedAmount[msg.sender] += num;
        totalReserved += uint256(num);
        emit Reserved(msg.sender, num);
    }

    function mintForFriends(address[] memory addrs) external {
        require(
            block.timestamp >= publicSaleTime,
            "GM Frens: Public sale has not yet started."
        );
        for (uint256 i = 0; i < addrs.length; i++) {
            uint8 amount = reservedAmount[addrs[i]] - userClaimed[addrs[i]];
            require(amount > 0);
            userClaimed[addrs[i]] += amount;
            _mintAmount(addrs[i], amount);
        }
    }

    function _mintAmount(address _user, uint8 _num) private {
        for (uint8 i = 0; i < _num; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(_user, newTokenId);
            _incrementTokenId();
        }
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);
        _currentTokenId++;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function setAllTime(uint256 _preSaleTime, uint256 _publicSaleTime)
        external
        onlyOwner
    {
        presaleTime = _preSaleTime;
        publicSaleTime = _publicSaleTime;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function withdraw() external onlyOwner {
        uint256 canWithdraw = totalSupply() * publicSalePrice - withdrawn;
        if (canWithdraw > address(this).balance)
            canWithdraw = address(this).balance;
        payable(owner()).transfer(canWithdraw);
        withdrawn += canWithdraw;
    }
}