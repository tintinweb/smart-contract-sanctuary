// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*

██████╗ ██████╗ ██████╗  █████╗ ███╗   ██╗██████╗  █████╗ ███████╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝
██████╔╝██████╔╝██████╔╝███████║██╔██╗ ██║██║  ██║███████║███████╗
██╔═══╝ ██╔═══╝ ██╔═══╝ ██╔══██║██║╚██╗██║██║  ██║██╔══██║╚════██║
██║     ██║     ██║     ██║  ██║██║ ╚████║██████╔╝██║  ██║███████║
╚═╝     ╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝

*/

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";

contract PPPandas is Ownable, ERC721Enumerable, PaymentSplitter {

    using SafeMath for uint;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public PANDA_PRICE = 0.02 ether;
    uint public MAX_PANDAS = 8888;
    uint public PRESALE_PANDAS = 500;
    uint private reservedPandas = 88;
    uint public presaleStartTime = 1631631600;
    uint public presaleEndTime = presaleStartTime + 24 hours;
    uint public publicSaleStartTime = 1631631600;
    uint private pandasForSale = MAX_PANDAS - reservedPandas;
    uint public maxPerTx = 20;
    uint public presaleMaxTx = 5;
    bool public hasLegndBeenClaim = false;
    string private _baseURIextended;
    string public PROVENANCE;
    mapping(address => uint) NFTsToClaim;
    mapping(address => bool) isOnWhiteList;
    mapping(address => bool) isTeam;

    address coreTeam = 0x689DBd5A8F6b91c41f427B16d7e5A711829c5BE4;

    address[] private _team = [coreTeam];
    uint256[] private _team_shares = [100];

    constructor()
        ERC721("PPPandasV2", "PPP")
        PaymentSplitter(_team, _team_shares)
    {
        _baseURIextended = "";
        isTeam[msg.sender] = true;
        isTeam[coreTeam] = true;

        NFTsToClaim[coreTeam] = reservedPandas;

        isOnWhiteList[msg.sender] = true;
    }

    // Modifiers

    modifier verifyGift(uint _amount) {
        require(_totalSupply() < pandasForSale, "Error 8,888: Sold Out!");
        require(_totalSupply().add(_amount) <= pandasForSale, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        _;
    }

    modifier verifyClaim(address _addr, uint _amount) {
        require(NFTsToClaim[_addr] > 0, "Sorry! You dont have any shares to claim.");
        require(_amount <= NFTsToClaim[_addr], "Hold up! Purchase would exceed max supply. Try a lower amount.");
        _;
    }

    modifier verifyBuy(uint _amount) {
        require(block.timestamp > presaleStartTime, "Sorry Presale has not started yet!");
        require(_totalSupply() < pandasForSale, "Error 8,888 Sold Out!");
        require(_totalSupply().add(_amount) <= pandasForSale, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        if (block.timestamp >= publicSaleStartTime) {
            require(_amount <= maxPerTx, "Hey you can not buy more than 20 at one time. Try a smaller amount.");
            require(msg.value >= PANDA_PRICE.mul(_amount), "Dang! You dont have enough ETH!");
        }
        if (block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime) {
            require(isOnWhiteList[msg.sender] == true, "Sorry you are not on the whitelist");
            require(_totalSupply().add(_amount) <= PRESALE_PANDAS, "Error: 500 PreSale Pandas Sold");
            require(_amount <= presaleMaxTx, "Hey you can not buy more than 5 at one time. Try a smaller amount.");
            require(msg.value >= PANDA_PRICE.mul(_amount), "Dang! You dont have enough ETH!");
        }
        _;
    }

    modifier onlyTeam() {
        require(isTeam[msg.sender] == true, "Sneaky sneaky! You are not part of the team");
        _;
    }

    // Setters

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setWhiteList(address[] memory _addr) external onlyTeam {
        for(uint i = 0; i < _addr.length; i++){
            isOnWhiteList[_addr[i]] = true;
        }
    }

    function setReservedPandas(uint _newReserve) external onlyOwner {
        reservedPandas = _newReserve;
    }

    function setPresalePandas(uint _newNumber ) external onlyOwner {
        PRESALE_PANDAS = _newNumber;
    }

    function increaseSupply() internal {
        _tokenIds.increment();
    }

    function _totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE = _provenanceHash;
    }

    function setPresaleTime(uint _newTime) external onlyOwner {
        presaleStartTime = _newTime;
        publicSaleStartTime = presaleStartTime + 5 minutes;
    }

    function setPublicSaleDate(uint _newTime) external onlyOwner {
        publicSaleStartTime =_newTime;
    }

    function contractURI() public view returns (string memory) {
        return _baseURIextended;
    }

    function buyPPPandas(uint _amount) external payable verifyBuy(_amount) {
        address _to = msg.sender;
        for (uint i = 0; i < _amount; i++) {
            uint id = _totalSupply() + 1;
            if(id == 8833) {
                id = id + 1;
            }
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    function giftManyPPPandas(address[] memory _addr) external onlyTeam verifyGift(_addr.length) {
        for (uint i = 0; i < _addr.length; i++) {
            address _to = _addr[i];
            uint id = _totalSupply() + 1;
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    function claimPandas(uint _amount) external onlyTeam verifyClaim(msg.sender, _amount) {
        address _addr = msg.sender;
        if(hasLegndBeenClaim == false && msg.sender == coreTeam){
            _safeMint(msg.sender, 8833);
            NFTsToClaim[_addr] = NFTsToClaim[_addr] - 1;
            increaseSupply();
            hasLegndBeenClaim = true;
        }
        else {
            for (uint i = 0; i < _amount; i++) {
                uint id = _totalSupply() + 1;
                _safeMint(msg.sender, id);
                NFTsToClaim[_addr] = NFTsToClaim[_addr] - 1;
                increaseSupply();
            }
        }
    }
    // Withdraw

    function withdrawAll() external onlyTeam {
            release(payable(_team[0]));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

/**

 Generative Art: @Jim Dee
 Smart Contract Consultant: @realkelvinperez

 https://generativenfts.io/

**/