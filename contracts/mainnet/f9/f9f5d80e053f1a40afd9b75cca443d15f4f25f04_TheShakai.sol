// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Burnable.sol';

 /**
 * @title contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TheShakai is ERC721Burnable {
    using SafeMath for uint256;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;    

    uint256 public mintPrice;
    uint256 public maxPublicToMint;
    uint256 public maxPresaleToMint;
    uint256 public maxNftSupply;
    uint256 public maxPresaleSupply;
    uint256 public currentTID;

    mapping(address => uint256) public presaleNumOfUser;
    mapping(address => uint256) public publicNumOfUser;
    mapping(address => uint256) public totalClaimed;

    address private wallet1;
    address private wallet2;

    bool public presaleAllowed;
    bool public publicSaleAllowed;    
    uint256 public presaleTime;
    uint256 public publicSaleTime;    

    mapping(address => bool) public whitelisted;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _status = _NOT_ENTERED;

        maxNftSupply = 4444;
        maxPresaleSupply = 1000;
        mintPrice = 0.08 ether;
        maxPublicToMint = 10;
        maxPresaleToMint = 3;
        currentTID = 0;
        presaleAllowed = false;
        publicSaleAllowed = false;
        presaleTime = 0;
        publicSaleTime = 0;
        wallet1 = 0x7f74182c4422FE057Df96b2Ba9c978C2F8fc7721;
        wallet2 = 0x828ce81303FB095d294245ECdb5E94a7432C45F0;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function isPresaleOpened() public view returns(bool) {
        uint256 curTimestamp = block.timestamp;
        if (presaleAllowed && presaleTime <= curTimestamp && currentTID < maxPresaleSupply) {
            return true;
        }
        return false;
    }

    function isPublicSaleOpened() public view returns(bool) {
        uint256 curTimestamp = block.timestamp;
        if (publicSaleAllowed && publicSaleTime <= curTimestamp) {
            return true;
        }
        return false;
    }


    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMaxNftSupply(uint256 _maxValue) external onlyOwner {
        maxNftSupply = _maxValue;
    }

    function setMaxPresaleSupply(uint256 _maxValue) external onlyOwner {
        maxPresaleSupply = _maxValue;
    }

    function setMaxPresaleToMint(uint256 _maxValue) external onlyOwner {
        maxPresaleToMint = _maxValue;
    }

    function setMaxPublicToMint(uint256 _maxValue) external onlyOwner {
        maxPublicToMint = _maxValue;
    }

    function reserveNfts(address _to, uint256 _count) external onlyOwner {
        uint256 i;
        uint256 ts = totalSupply();
        require(_to != address(0), "Invalid address to reserve.");
        require(ts == currentTID, "Ticket id and supply not matched.");        
        
        currentTID = currentTID.add(_count);

        for (i = 0; i < _count; i++) {
            _safeMint(_to, ts + i);
        }
    }

    function setPresaleStatus(bool newStatus, uint256 timeDiff) external onlyOwner {
        uint256 curTimestamp = block.timestamp;
        presaleAllowed = newStatus;
        presaleTime = curTimestamp.add(timeDiff);
    }

    function setPublicSaleStatus(bool newStatus, uint256 timeDiff) external onlyOwner {
        uint256 curTimestamp = block.timestamp;
        publicSaleAllowed = newStatus;
        publicSaleTime = curTimestamp.add(timeDiff);
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }

    function removeToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = false;
        }
    }

    function getTicketCount(address user) public view returns (uint256) {
        return presaleNumOfUser[user].add(publicNumOfUser[user]).sub(totalClaimed[user]);
    }

    function buyTickets(uint256 count, bool mode) external payable {
        uint256 amount = 0;

        if (!mode) {
            amount = presaleNumOfUser[_msgSender()];
            require(isPresaleOpened(), "Presale has not started yet");
            require(whitelisted[_msgSender()], "You are not on white list");
            require(count.add(amount) <= maxPresaleToMint, "Exceeds max presale allowed per user");
            require(currentTID.add(count) <= maxPresaleSupply, "Exceeds max presale supply");
            require(count > 0, "Must mint at least one token");
            require(mintPrice.mul(count) <= msg.value, "Ether value sent is not correct");

            presaleNumOfUser[_msgSender()] = count.add(presaleNumOfUser[_msgSender()]);
        } else {
            amount = publicNumOfUser[_msgSender()];
            require(isPublicSaleOpened(), "Public sale has not started yet");
            require(count.add(amount) <= maxPublicToMint, "Exceeds max public sale allowed per user");
            require(currentTID.add(count) <= maxNftSupply, "Exceeds max supply");
            require(count > 0, "Must mint at least one token");
            require(mintPrice.mul(count) <= msg.value, "Ether value sent is not correct");

            publicNumOfUser[_msgSender()] = count.add(publicNumOfUser[_msgSender()]);            
        }
        
        currentTID = currentTID.add(count);
    }

    function claim() external nonReentrant {
        uint256 ticketNum = getTicketCount(_msgSender());

        totalClaimed[_msgSender()] = ticketNum.add(totalClaimed[_msgSender()]);
        
        for(uint256 i = 0; i < ticketNum; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(_msgSender(), mintIndex);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balance2 = balance.mul(20).div(100);
        payable(wallet2).transfer(balance2);   
        payable(wallet1).transfer(balance.sub(balance2));        
    }
}