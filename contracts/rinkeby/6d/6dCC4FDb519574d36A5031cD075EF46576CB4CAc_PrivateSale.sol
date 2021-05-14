/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity 0.6.12;

contract PrivateSale {
    
    struct TokenLock {
        uint256 timestamp;
        uint256 amount;
        bool isUnlocked;
    }
    struct User {
        uint256 alloc;
        uint256 bought;
        uint256 locked;
        TokenLock[] releases;
        uint256 boughtWithNerdz;
    }
    mapping(address => User) public whitelist;
    uint256 public totalSold;
    uint256 public totalLocked;
    uint256 public totalUnlocked;
    uint256 public saleStart;
    uint256 public saleStop;
    address payable public tokenOwner;


    uint256 public constant MAX_SALE_DURATION = 14 days;

    event AddedToWhitelist(address[] account);
    event RemovedFromWhitelist(address[] account);

    constructor() public {
        tokenOwner = msg.sender;
    }


    function add(address[] memory _addresses, uint256[] memory _allocations)
        external
        
    {
        require(_addresses.length == _allocations.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            setAllocation(_addresses[i], _allocations[i]);
        }
        emit AddedToWhitelist(_addresses);
    }

    function setAllocation(address _addr, uint256 alloc) public  {
        whitelist[_addr].alloc = alloc;
    }

    function remove(address[] calldata _addresses) external  {
        for (uint256 i = 0; i > _addresses.length; i++) {
            whitelist[_addresses[i]].alloc = 0;
        }
        emit RemovedFromWhitelist(_addresses);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address].alloc > 0;
    }
    
}