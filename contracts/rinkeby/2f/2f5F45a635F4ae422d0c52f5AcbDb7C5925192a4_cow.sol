// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./import_zap.sol";


contract cow is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    uint256 private _currentTokenId = 1;

    uint256 public MAX_SUPPLY = 9999;
    string public baseTokenURI;
    
   
    uint256 public pre_one_package;
    uint256 public pre_two_package;
    uint256 public pre_three_package;
    uint256 public one_package;
    uint256 public two_package;
    uint256 public three_package;
    uint256 public presale_total;
    uint256 public startTime = block.timestamp;
    string _name = "Crunchy Cows";
    string _symbol = "cow";

    constructor() ERC721(_name, _symbol ) {
        // baseTokenURI = _uri;
        _initializeEIP712(_name);
    
        pre_one_package=0.025 ether;
        pre_two_package=0.0425 ether;
        pre_three_package=0.06 ether;
        presale_total=600;
        
        one_package=0.02625 ether;
        two_package=0.044625 ether;
        three_package=0.063 ether;
    }
    function set_start_time(uint256 time) external onlyOwner{
        startTime = time;
    }
 
    
    function update_presale(uint256 one, uint256 two, uint256 three, uint256 total)external onlyOwner{
        pre_one_package=one;
        pre_two_package=two;
        pre_three_package=three;
        presale_total=total;
        
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
    

    function buy(uint256 numberOfTokens) public payable {
        
        require(_currentTokenId+numberOfTokens <= MAX_SUPPLY, "Max Supply Reached");
         if(msg.value==one_package){_mintcows(1, msg.sender);}
        if(msg.value==two_package){_mintcows(2, msg.sender);}
        if(msg.value==three_package){_mintcows(3, msg.sender);}
            
    }
    function _presale(uint256 numberOfTokens) public payable{
        
        require(_currentTokenId+numberOfTokens <= presale_total,"Required number of Tokens are not available");
        if(msg.value==pre_one_package){_mintcows(1, msg.sender);}
        if(msg.value==pre_two_package){_mintcows(2, msg.sender);}
        if(msg.value==pre_three_package){_mintcows(3, msg.sender);}
        
    }
    
    function _mintcows(uint256 numberOfTokens, address sender) internal {
        for(uint256 i = 0; i < numberOfTokens; i++) {
             uint256 newTokenId = _getNextTokenId();
            _mint(sender, newTokenId);
            _incrementTokenId();
        }
    }



   
    function withdraw(uint256 amount) external onlyOwner {
      payable(owner()).transfer(amount);
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