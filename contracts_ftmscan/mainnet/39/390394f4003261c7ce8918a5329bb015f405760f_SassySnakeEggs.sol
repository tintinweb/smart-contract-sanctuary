// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract SassySnakeEggs is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 public MAX_SUPPLY;
    address public SKIN_ERC20_CONTRACT;
    string public baseUri;

    Counters.Counter private _eggMintCounter;
    mapping(address => bool) private _approvedMinters;
    mapping(address => uint256) public huntRewards;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _snakeskinErc20

    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        SKIN_ERC20_CONTRACT = _snakeskinErc20;
    }    

    function mintEgg(address recipient, uint256 numEggs) public whenNotPaused {
        require(_approvedMinters[msg.sender], "You must be approved to call this function");

        for (uint256 i = 0; i < numEggs; i++) {
        	_eggMintCounter.increment();
            _safeMint(recipient, _eggMintCounter.current());	
        }
    }

    function claimHuntRewards() public whenNotPaused {
        require(huntRewards[msg.sender] > 0, "No eggs to claim for function caller");

        for (uint256 i = 0; i < huntRewards[msg.sender]; i++) {
            _eggMintCounter.increment();
            _safeMint(msg.sender, _eggMintCounter.current());
        }

        huntRewards[msg.sender] = 0;
    }

    function assignRewards(address[] memory winners, uint256[] memory amounts) public {
        require(_approvedMinters[msg.sender], "Sender is not approved to call this function");

        for (uint256 i = 0; i < winners.length; i++) {
            huntRewards[winners[i]] = amounts[i];
        }
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function approveMinter(address entity) public onlyOwner {
        _approvedMinters[entity] = true;
    }

    function supplyMinted() public view returns (uint256) {
        return _eggMintCounter.current();
    }    

    // Override requirements
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}