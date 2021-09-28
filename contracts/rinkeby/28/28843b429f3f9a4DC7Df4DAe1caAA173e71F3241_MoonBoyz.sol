// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract MoonBoyz is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxMoonBoyzSupply = 11111;
    bool public whiteListSale = false;
    bool public regularSale = false;
    uint256 public salePrice;
    
    mapping(address => uint256) public totalAvailableForUser;
    
    address[] public whiteListOne;
    address[] public whiteListTwo;
    address[] public whiteListThree;
    address[] public whiteListFour;
    address[] public whiteListFive;
    address[] public whiteListSix;
    address[] public whiteListSeven;
    address[] public whiteListEight;
    address[] public whiteListNine;
    address[] public whiteListTen;
    address[] public whiteListEleven;
    
    
    address payable thisContract;
    
    
    address[] private _team = [
        0x700eec4D6Ed56ED0F97a0f43Fc9DF5B426Ba25Fc, 
        0xDFf1889Ec0F09d14dE9379938bDc3Df0c6D0B39C, 
        0x4c2a5a4ea0d3f7E9142535f260A05b975Ee1df02, 
        0xDbe3BfBEc8332b0835bf0f466bA34c64655Ba94D, 
        0x12B285072b1Ffc70F367f08066b0D9A7d3337309 
        ];
    
    uint256[] private _teamShares = [
        23,
        22,
        23,
        22,
        10
        ];
    
    constructor() ERC721("MoonBoyz", "MOONBOYZ") PaymentSplitter(_team, _teamShares) {
    }
    
    fallback() external payable {

  	}
  	
  	function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
    }

    function setThisContract(address payable _thisContract) external onlyOwner {
        thisContract = _thisContract;
    }
    
    function populateWhiteListOne(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListOne.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }
    }
    
    function populateWhiteListTwo(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListTwo.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }   
    }
    
    function populateWhiteListThree(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListThree.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }
    }
    
    function populateWhiteListFour(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListFour.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }   
    }
    
    function populateWhiteListFive(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListFive.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }
    }
    
    function populateWhiteListSix(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListSix.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }   
    }
    
    function populateWhiteListSeven(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListSeven.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }
    }
    
    function populateWhiteListEight(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListEight.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }   
    }
    
    function populateWhiteListNine(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListNine.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }
    }
    
    function populateWhiteListTen(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListTen.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }   
    }
    
    function populateWhiteListEleven(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteListEleven.push(_users[i]);
            totalAvailableForUser[_users[i]] = totalAvailableForUser[_users[i]] + 2;
        }
    }
    
    function whitelistOwners(address _owners) public onlyOwner {
        whiteListOne.push(_owners);
        whiteListTwo.push(_owners);
        whiteListThree.push(_owners);
        whiteListFour.push(_owners);
        whiteListFive.push(_owners);
        whiteListSix.push(_owners);
        whiteListSeven.push(_owners);
        whiteListEight.push(_owners);
        whiteListNine.push(_owners);
        whiteListTen.push(_owners);
        whiteListEleven.push(_owners);
        totalAvailableForUser[_owners] = 299;
    }
    
    function viewWhitelistOneStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListOne.length; i++) {
            if(whiteListOne[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistTwoStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListTwo.length; i++) {
            if(whiteListTwo[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistThreeStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListThree.length; i++) {
            if(whiteListThree[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistFourStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListFour.length; i++) {
            if(whiteListFour[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistFiveStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListFive.length; i++) {
            if(whiteListFive[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistSixStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListSix.length; i++) {
            if(whiteListSix[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistSevenStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListSeven.length; i++) {
            if(whiteListSeven[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistEightStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListEight.length; i++) {
            if(whiteListEight[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistNineStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListNine.length; i++) {
            if(whiteListNine[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistTenStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListTen.length; i++) {
            if(whiteListTen[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function viewWhitelistElevenStatus(address _user) public view returns(bool) {
        for(uint256 i = 0; i < whiteListEleven.length; i++) {
            if(whiteListEleven[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function whiteListGroupOne() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistOneStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupTwo() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistTwoStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupThree() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistThreeStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupFour() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistFourStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupFive() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistFiveStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupSix() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistSixStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupSeven() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistSevenStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupEight() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistEightStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupNine() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistNineStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupTen() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistTenStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function whiteListGroupEleven() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(whiteListSale == true, "Whitelisted Sale Not Active");
        uint256 _tokenID = getAvailableIndex();
        require(viewWhitelistElevenStatus(msg.sender), "Not In Group One");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        require(totalAvailableForUser[msg.sender] >= 1, "Exceeds Alotted Amount");
        totalAvailableForUser[msg.sender] = totalAvailableForUser[msg.sender] - 1;
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function regularSaleMint() public payable {
        require(msg.value >= salePrice, "Insuffcient amount sent");
        require(regularSale == true, "Normal Sale Not Active");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current() < maxMoonBoyzSupply, "At Max Supply");
        uint256 _tokenID = getAvailableIndex();
        require(!super._exists(_tokenID), "Token ID Exists");
        
        _safeMint(msg.sender, _tokenID);
        _tokenIdCounter.increment();
    }
    
    function getAvailableIndex() public view returns(uint256) {
        for(uint256 i = 1; i < maxMoonBoyzSupply; i++) {
            if(!_exists(i)) {
                return i;
            }
        }
        return 0;
    }
    
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function setWhitelistSale(bool _trueOrFalse) external onlyOwner {
        whiteListSale = _trueOrFalse;
    }
    
    function setRegularSale(bool _trueOrFalse) external onlyOwner {
        regularSale = _trueOrFalse;
    }
    
    function setSalePrice(uint256 _priceInWei) external onlyOwner {
        salePrice = _priceInWei;
    }
    
    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    
}