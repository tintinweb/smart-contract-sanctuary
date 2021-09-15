// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./import_zap.sol";


contract Royal is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    uint256 private _currentTokenId = 0;

    uint256 MAX_SUPPLY = 4444;
    string public baseTokenURI;
    
    uint256 public NFT_price = 0.02 ether;

    uint256 public startTime = block.timestamp;
    string _name = "Royal";
    string _symbol = "RYT";

    constructor() ERC721(_name, _symbol) {
        // baseTokenURI = _uri;
        _initializeEIP712(_name);
    }
    function set_start_time(uint256 time) external onlyOwner{
        startTime = time;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        require(_currentTokenId < MAX_SUPPLY, "Max Supply Reached");
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }
    

    function buy() public payable {
        require(block.timestamp >= startTime, "It's not time yet");
        require(msg.value == NFT_price, "Sent Amount Not Enough");
        require(_currentTokenId < MAX_SUPPLY, "Max Supply Reached");
    
            uint256 newTokenId = _getNextTokenId();
            _mint(msg.sender, newTokenId);
            _incrementTokenId();
    }


    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    // function randomHash() internal view returns (uint256) {
    //     bytes32 txHash = keccak256(
    //         abi.encode(block.coinbase, block.timestamp, block.difficulty)
    //     );
    //     return uint256(txHash);
    // }

    /**
     * @dev increments the value of _currentTokenId,When all 9,788 Ghosts are sold out, a randomHash Ghost NFT owner will win a Tesla Model Y. The more NFT owned, the bigger the chance.
     */
    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);

        _currentTokenId++;
    }

    /**
     * @dev change the baseGhostURI if there are future problems with the API service
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, 
         string(abi.encodePacked(Strings.toString(_tokenId),".json"))
        ));
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
   
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}