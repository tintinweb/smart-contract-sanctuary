// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract FooDogs is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    Counters.Counter private _tokenIdCounter;
    
    address public immutable buddhaContract = 0x657F49b422f98B3092F27add6210831BF2e56622;

    mapping (uint256 => string) private _tokenURIs;
    mapping(address => uint256) public totalMinted;
    mapping(address => uint256) public _totalRedeemed;
    mapping(address => uint256) public _ffaRedeemd;
    mapping(address => uint256) public _whiteList;

    string private _baseURIextended;
    
    uint256 public constant maxTokenSupply = 8888;
    uint256 public constant maxFFARedeem = 5;
    
    bool public reservedMint = false;
    bool public freeForAll = false;
    
    constructor() ERC721("FooDogs", "FOO") {
    }
  	
  	function populateWhiteList(address[] memory _addys, uint256[] memory _amount) external onlyOwner {
  	    require(_addys.length == _amount.length, "INCORRECT STRUCTURE PROVIDED");
  	    
  	    for(uint256 i = 0; i < _addys.length; i++) {
  	        _whiteList[_addys[i]] = _whiteList[_addys[i]].add(_amount[i]);
  	    }
  	    return;
  	}
  	
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function setReservedMint(bool _trueOrFalse) external onlyOwner {
        reservedMint = _trueOrFalse;
    }
    
    function setFreeForAll(bool _trueOrFalse) external onlyOwner {
        freeForAll = _trueOrFalse;
    }
  	
  	function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function reservedRedemption() public {
        uint256 owned = getOwned(msg.sender);
        uint256 whiteList = viewWhiteList(msg.sender);
        uint256 eligible = owned.sub(_totalRedeemed[msg.sender]);
        require(owned != 0 && eligible != 0 || whiteList != 0, "ATTEMPTED TO MINT MORE THAN ALLOTED");
        require(_tokenIdCounter.current().add(eligible) <= maxTokenSupply, "ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(reservedMint == true, "RESERVED MINT INACTIVE");
        
        if(eligible != 0) {
            for(uint256 i = 0; i < eligible; i++) {
                _totalRedeemed[msg.sender] = _totalRedeemed[msg.sender].add(1);
                _safeMint(msg.sender, _tokenIdCounter.current().add(1));
                _tokenIdCounter.increment();
            }
        } else if(whiteList != 0) {
            for(uint256 i = 0; i < whiteList; i++) {
                _whiteList[msg.sender] = _whiteList[msg.sender].sub(1);
                _safeMint(msg.sender, _tokenIdCounter.current().add(1));
                _tokenIdCounter.increment();
            }
        }
        return;
    }
    
    function freeForAllRedemption(uint256 _numberOfMints) public {
        require(_tokenIdCounter.current().add(_numberOfMints) <= maxTokenSupply, "ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(_ffaRedeemd[msg.sender].add(_numberOfMints) <= maxFFARedeem, "ATTEMPTED TO MINT MORE THAN ALLOTED");
        require(freeForAll == true, "FREE FOR ALL INACTIVE");

        for(uint256 i = 0; i < _numberOfMints; i++) {
            _ffaRedeemd[msg.sender] = _ffaRedeemd[msg.sender].add(1);
            _safeMint(msg.sender, _tokenIdCounter.current().add(1));
            _tokenIdCounter.increment(); 
        }
        return;
    }
    
    function viewWhiteList(address _address) public view returns(uint256) {
  	    return _whiteList[_address];
  	}
    
    function getOwned(address _owner) public view returns(uint256) {
  	    return IERC721(buddhaContract).balanceOf(_owner);
  	}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
}