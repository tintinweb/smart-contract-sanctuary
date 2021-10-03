// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NonFungibleMembership is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string _baseTokenURI = 'https://nonfungible.tools/api/metadata/';
    uint256 private _price = 0.75 ether;

    uint256 RESERVED_FOUNDING_MEMBERS = 10;
    uint256 FOUNDING_MEMBERS_SUPPLY = 100;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _subscriptionCounter;

    struct SubscriptionPlan {
        uint256 price;
        uint256 duration;
    }

    mapping (uint => SubscriptionPlan) subscriptionPlans;

    // Address -> Date in time
    mapping (address => uint256) subscriptionExpiration;

    event Mint(address indexed _address, uint256 tokenId);
    event Subscription(address _address, SubscriptionPlan plan, uint256 timestamp, uint256 expiresAt, uint256 subscriptionCounter);

    constructor() ERC721("Non Fungible Tools Membership", "NFTOOLS") {
        subscriptionPlans[0] = SubscriptionPlan(0.1 ether, 30 days);
        subscriptionPlans[1] = SubscriptionPlan(0.5 ether, 365 days); 

        for (uint i = 0; i < RESERVED_FOUNDING_MEMBERS; i++) {
            _safeMint(msg.sender);
        }
    }

    function updateSubscriptionPlan(uint index, SubscriptionPlan memory plan) public onlyOwner {
        subscriptionPlans[index] = plan;
    }

    function _getSubscriptionPlan(uint index) private view returns (SubscriptionPlan memory) {
        SubscriptionPlan memory plan = subscriptionPlans[index];

        require(plan.duration > 0, "Subscription plan does not exist");

        return plan;
    }

    function getSubscriptionPlan(uint index) external view returns (SubscriptionPlan memory) {
        return _getSubscriptionPlan(index);
    }

    function subscribe(address _to, uint planIndex) whenNotPaused public payable {
        SubscriptionPlan memory plan = _getSubscriptionPlan(planIndex);

        require(plan.price == msg.value, "Wrong amount sent");
        require(plan.duration > 0, "Subscription plan does not exist");

        uint256 startingDate = block.timestamp;

        // Add to existing current subscription if it exists.
        if(_hasActiveSubscription(_to)) {
            startingDate = subscriptionExpiration[_to];
        }   

        uint256 expiresAt = startingDate + plan.duration;

        subscriptionExpiration[_to] = expiresAt;
        _subscriptionCounter.increment();

        emit Subscription(_to, plan, block.timestamp, expiresAt, _subscriptionCounter.current());
    }

    function _hasActiveSubscription(address _address) private view returns (bool) {
        // subscriptionExpiration[_address] will be 0 if that address never had a subscription.  
        return subscriptionExpiration[_address] > block.timestamp;    
    }

    function hasActiveSubscription(address _address) external view returns (bool) {
        return _hasActiveSubscription(_address);
    }

    function getSubscription(address _address) external view returns (uint256) {
        return subscriptionExpiration[_address];
    }

     function mint(address _to) whenNotPaused public payable  {
        require(msg.value == _price, "Wrong amount sent");
        require(_tokenIdCounter.current() < FOUNDING_MEMBERS_SUPPLY, "Can't mint over supply limit");
        require(balanceOf(_to) == 0, "Can only mint one founding membership");

        _tokenIdCounter.increment();
    
        _safeMint(_to, _tokenIdCounter.current());
        emit Mint(_to, _tokenIdCounter.current());
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause()  public onlyOwner whenPaused {
        _unpause();
    }

    function _safeMint(address to) public onlyOwner {
        _tokenIdCounter.increment();

        _safeMint(to, _tokenIdCounter.current());
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function hasFoundingMemberToken(address wallet) public view returns (bool) {
       return balanceOf(wallet) > 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}