// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
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

contract FlukeLoops is ERC721Enumerable, ContextMixin, Ownable {
    uint public constant MAX_CAP = 2500;
    string _baseTokenURI;

    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    mapping(address=>bool) public whitelist;

    uint256 presaleStarts = 1642359600; //January 16th 7 PM GMT
    uint256 presaleEnds = 1642446000; //January 17th 7 PM GMT

    uint256 public TOKEN_PRICE = 50000000000000000; //0.05 ETH

    address fees2 = 0x4076899bb34B4Af5faaDF6d574be58c935faff97;

    //Event to tell OpenSea that this item is frozen
    event PermanentURI(string _value, uint256 indexed _id);

    mapping(uint256=>string) public frozenUris;

    constructor() ERC721("FlukeLoops", "FlukeLoops")  {
        setBaseURI('https://flukenft.com/api/subset/2/token/');
    }

    function mint(uint _tokenId) public payable {
        require(_tokenId < MAX_CAP, "Max limit");
        require(!_exists(_tokenId), "Already minted");
        require(block.timestamp > presaleStarts, "Presale not started");
        if (block.timestamp < presaleEnds) {
            require(whitelist[msg.sender], "Not whitelisted");
            require(_tokenId % 5 == 0, "Invalid purchase");
        }

        require(msg.value == TOKEN_PRICE, "Invalid value");

        _safeMint(msg.sender, _tokenId);
    }

    function mintBatch(uint[] memory _tokenIds) public payable {
        require(block.timestamp > presaleStarts, "Presale not started");
        require(_tokenIds.length <= 10, "Maximum is 10");

        if (block.timestamp < presaleEnds) {
            require(whitelist[msg.sender], "Not whitelisted");
        }

        require(msg.value == _tokenIds.length * TOKEN_PRICE, "Invalid value");

        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] < MAX_CAP, "Max limit");
            require(!_exists(_tokenIds[i]), "Already minted");
            if (block.timestamp < presaleEnds) {
                require(_tokenIds[i] % 5 == 0, "Invalid purchase");
            }
        
            _safeMint(msg.sender, _tokenIds[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    
    function tokenURI(uint256 _input) public view virtual override returns (string memory) {
        if (bytes(frozenUris[_input]).length > 0) {
            return frozenUris[_input];
        }
        return ERC721.tokenURI(_input);
    }
    
    function freeze(string memory _value, uint256 _id) public onlyOwner {
        require(bytes(frozenUris[_id]).length == 0, "Already freezed");

        frozenUris[_id] = _value;
        emit PermanentURI(_value, _id);
    }

    function _withdrawFees() public {
        uint balance = address(this).balance;
        uint partialBalance = balance / 10;
        require(payable(fees2).send(partialBalance));
        require(payable(owner()).send(balance - partialBalance));
    }

    function _enableWhitelist(address[] memory _wallets, bool _status) public onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            whitelist[_wallets[i]] = _status;
        }
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
}