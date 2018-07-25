pragma solidity ^0.4.23;

// Ownable contract with CFO
contract Ownable {
    address public owner;
    address public cfoAddress;

    constructor() public{
        owner = msg.sender;
        cfoAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function setCFO(address newCFO) external onlyOwner {
        require(newCFO != address(0));

        cfoAddress = newCFO;
    }
}

// Pausable contract which allows children to implement an emergency stop mechanism.
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    // Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }


    // called by the owner to pause, triggers stopped state
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    // called by the owner to unpause, returns to normal state
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

// interface for presale contract
contract ParentInterface {
    function transfer(address _to, uint256 _tokenId) external;
    function recommendedPrice(uint16 quality) public pure returns(uint256 price);
    function getPet(uint256 _id) external view returns (uint64 birthTime, uint256 genes,uint64 breedTimeout,uint16 quality,address owner);
}

contract AccessControl is Pausable {
    ParentInterface public parent;
    
    function setParentAddress(address _address) public whenPaused onlyOwner
    {
        ParentInterface candidateContract = ParentInterface(_address);

        parent = candidateContract;
    }
}

// setting a special price
contract Discount is AccessControl {
    uint128[101] public discount;
    
    function setPrice(uint8 _tokenId, uint128 _price) external onlyOwner {
        discount[_tokenId] = _price;
    }
}

contract Sales is Discount {

    constructor(address _address) public {
        ParentInterface candidateContract = ParentInterface(_address);
        parent = candidateContract;
        paused = true;
    }
    
	// purchasing a parrot
    function purchaseParrot(uint256 _tokenId) external payable whenNotPaused
    {
        uint64 birthTime; uint256 genes; uint64 breedTimeout; uint16 quality; address parrot_owner;
        (birthTime,  genes, breedTimeout, quality, parrot_owner) = parent.getPet(_tokenId);
        
        require(parrot_owner == address(this));
        
        if(discount[_tokenId] == 0)
            require(parent.recommendedPrice(quality) <= msg.value);
        else
            require(discount[_tokenId] <= msg.value);
        
        parent.transfer(msg.sender, _tokenId);
    }
    
    function gift(uint256 _tokenId, address to) external onlyOwner{
        parent.transfer(to, _tokenId);
    }

    function withdrawBalance(uint256 summ) external onlyCFO {
        cfoAddress.transfer(summ);
    }
}