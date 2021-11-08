// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

/**
 * @title 0xHunter
 */
contract Hunter is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    string public baseTokenURI;
    uint256 private _currentTokenId = 0;
    uint256 MAX_SUPPLY = 8888;
    uint256 public totalMint = 0;
    uint256 public totalPledge;

    uint256 public presaleTime = 1635346800;
    uint256 public pledgeTime = 1635519600;

    mapping(address => uint8) public whitelist;
    mapping(address => uint8) public pledgeNumOfPlayer;
    mapping(address => uint8) public claimed;
    mapping(address => uint8) public airdropNum;

    event Rider(uint256 indexed tokenId, address indexed luckyDog);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(
            whitelist[msg.sender] > 0,
            "0xHunter: You're not on the whitelist."
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        _initializeEIP712(_name);
    }

    /**
     * @dev Mint to msg.sender. Only whitelisted users can participate
     */
    function presale() external payable onlyWhitelisted {
        require(
            block.timestamp >= presaleTime &&
                block.timestamp < presaleTime + 1 days,
            "0xHunter: Presale has not yet started."
        );
        require(
            msg.value == uint256(whitelist[msg.sender]) * 6e16,
            "0xHunter: You need to pay the exact price."
        );
        _mintList(whitelist[msg.sender]);
        totalMint += uint256(whitelist[msg.sender]);
        whitelist[msg.sender] = 0;
    }

    /**
     * @dev Pledge for the purchase. Each address can only purchase up to 5 0xHunters.
     * @param _num Quantity to purchase
     */
    function summon(uint8 _num) external payable {
        require(
            block.timestamp >= pledgeTime && block.timestamp <= pledgeTime + 7 days,
            "0xHunter: Pledge has not yet started."
        );
        require(
            (_num + pledgeNumOfPlayer[msg.sender] + claimed[msg.sender]) <= 5,
            "0xHunter: Each address can only purchase up to 5 0xHunters."
        );
        require(
            totalMint + uint256(_num) <= MAX_SUPPLY - totalPledge - 1650,
            "0xHunter: Sorry, all 0xHunters are sold out."
        );
        require(
            msg.value == uint256(_num) * 6e16,
            "0xHunter: You need to pay the exact price."
        );
        pledgeNumOfPlayer[msg.sender] = pledgeNumOfPlayer[msg.sender] + _num;
        totalPledge += uint256(_num);
    }

    /**
     * @dev Your 0xHunters can only be claimed at the end of the sale.
     */
    function claim() external {
        require(
            block.timestamp >= pledgeTime && block.timestamp <= pledgeTime + 7 days,
            "0xHunter: You don't satisfy the claiming conditions."
        );
        _mintList(pledgeNumOfPlayer[msg.sender]);
        claimed[msg.sender] += pledgeNumOfPlayer[msg.sender];
        pledgeNumOfPlayer[msg.sender] = 0;
    }

    /**
     * @dev Airdrop hunters directly to several addresses.
     * @param _recipients addresss of the future owner of the token
     */
    function mintTo(address[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(_recipients[i], newTokenId);
            _incrementTokenId();
        }
        totalMint += _recipients.length;
    }

    /**
     * @dev Airdrop hunters to several addresses.
     * @param _recipients addresss of the future owner of the token
     */
    function airdrop(address[] memory _recipients, uint8[] memory _amounts)
        external
        onlyOwner
    {
        require(
            block.timestamp >= pledgeTime,
            "0xHunter: Pledge has not yet started."
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            airdropNum[_recipients[i]] = _amounts[i];
        }
    }

    function getAirdrop() external {
        require(airdropNum[msg.sender] > 0 && block.timestamp <= pledgeTime + 7 days, "0xHunter: You don't satisfy the claiming conditions.");
        _mintList(airdropNum[msg.sender]);
        airdropNum[msg.sender] = 0;
    }

    /**
     * @dev For the last sales, 1 random 0xHunter will be picked and gifted with a Mustang as his ride.
     */
    function _mintList(uint8 _num) private {
        for (uint8 i = 0; i < _num; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(msg.sender, newTokenId);
            _incrementTokenId();
            if (newTokenId == MAX_SUPPLY - 1650) {
                uint256 randomNum = random() % 999;
                bytes32 randomHash = keccak256(
                    abi.encode(
                        ownerOf(newTokenId - randomNum - 1000),
                        ownerOf(newTokenId - randomNum - 2000),
                        ownerOf(newTokenId - randomNum - 3000)
                    )
                );
                uint256 riderId = newTokenId -
                    (uint256(randomHash) % newTokenId);
                emit Rider(riderId, ownerOf(riderId));
            }
        }
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev generates a random number based on block info
     */
    function random() private view returns (uint256) {
        bytes32 randomHash = keccak256(
            abi.encode(
                block.timestamp,
                block.difficulty,
                block.coinbase,
                msg.sender
            )
        );
        return uint256(randomHash);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);
        _currentTokenId++;
    }

    /**
     * @dev change the baseTokenURI only by Admin
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    /**
     * @dev set the presale and pledge time only by Admin
     */
    function setAllTime(uint256 _preSaleTime, uint256 _pledgeTime)
        external
        onlyOwner
    {
        presaleTime = _preSaleTime;
        pledgeTime = _pledgeTime;
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

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function recoverGodhead() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @param _amounts amounts
     */
    function addAddressesToWhitelist(
        address[] memory addrs,
        uint8[] memory _amounts
    ) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = _amounts[i];
        }
    }
}