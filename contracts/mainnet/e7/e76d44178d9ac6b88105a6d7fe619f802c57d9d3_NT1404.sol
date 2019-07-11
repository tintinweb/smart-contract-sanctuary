/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnerTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner account is required");
        _;
    }

    function transferOwner(address newOwner)
    public
    onlyOwner {
        require(newOwner != owner, "New Owner cannot be the current owner");
        require(newOwner != address(0), "New Owner cannot be zero address");
        address prevOwner = owner;
        owner = newOwner;
        emit OwnerTransferred(prevOwner, newOwner);
    }
}

library AdditiveMath {
    function add(uint256 x, uint256 y)
    internal
    pure
    returns (uint256) {
        uint256 sum = x + y;
        require(sum >= x, "Results in overflow");
        return sum;
    }

    function subtract(uint256 x, uint256 y)
    internal
    pure
    returns (uint256) {
        require(y <= x, "Results in underflow");
        return x - y;
    }
}

library AddressMap {
    struct Data {
        int256 count;
        mapping(address => int256) indices;
        mapping(int256 => address) items;
    }

    address constant ZERO_ADDRESS = address(0);

    function append(Data storage self, address addr)
    internal
    returns (bool) {
        if (addr == ZERO_ADDRESS) {
            return false;
        }

        int256 index = self.indices[addr] - 1;
        if (index >= 0 && index < self.count) {
            return false;
        }

        self.count++;
        self.indices[addr] = self.count;
        self.items[self.count] = addr;
        return true;
    }

    function remove(Data storage self, address addr)
    internal
    returns (bool) {
        int256 oneBasedIndex = self.indices[addr];
        if (oneBasedIndex < 1 || oneBasedIndex > self.count) {
            return false;  // address doesn&#39;t exist, or zero.
        }

        // When the item being removed is not the last item in the collection,
        // replace that item with the last one, otherwise zero it out.
        //
        //  If {2} is the item to be removed
        //     [0, 1, 2, 3, 4]
        //  The result would be:
        //     [0, 1, 4, 3]
        //
        if (oneBasedIndex < self.count) {
            // Replace with last item
            address last = self.items[self.count];  // Get the last item
            self.indices[last] = oneBasedIndex;     // Update last items index to current index
            self.items[oneBasedIndex] = last;       // Update current index to last item
            delete self.items[self.count];          // Delete the last item, since it&#39;s moved
        } else {
            // Delete the address
            delete self.items[oneBasedIndex];
        }

        delete self.indices[addr];
        self.count--;
        return true;
    }

    function clear(Data storage self)
    internal {
        self.count = 0;
    }

    function at(Data storage self, int256 index)
    internal
    view
    returns (address) {
        require(index >= 0 && index < self.count, "Index outside of bounds.");
        return self.items[index + 1];
    }

    function indexOf(Data storage self, address addr)
    internal
    view
    returns (int256) {
        if (addr == ZERO_ADDRESS) {
            return -1;
        }

        int256 index = self.indices[addr] - 1;
        if (index < 0 || index >= self.count) {
            return -1;
        }
        return index;
    }

    function exists(Data storage self, address addr)
    internal
    view
    returns (bool) {
        int256 index = self.indices[addr] - 1;
        return index >= 0 && index < self.count;
    }

}

interface ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ERC1404 is ERC20 {
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string);
}

contract NT1404 is ERC1404, Ownable {

    // ------------------------------- Variables -------------------------------

    using AdditiveMath for uint256;
    using AddressMap for AddressMap.Data;

    address constant internal ZERO_ADDRESS = address(0);
    string public constant name = "NEWTOUCH BCL LAB TEST";
    string public constant symbol = "NTBCLTEST";
    uint8 public constant decimals = 0;

    AddressMap.Data public shareholders;
    bool public issuingFinished = false;

    mapping(address => uint256) internal balances;
    uint256 internal totalSupplyTokens;
    
    uint8 public constant SUCCESS_CODE = 0;
    string public constant SUCCESS_MESSAGE = "SUCCESS";

    // ------------------------------- Modifiers -------------------------------

    modifier canIssue() {
        require(!issuingFinished, "Issuing is already finished");
        _;
    }

    modifier hasFunds(address addr, uint256 tokens) {
        require(tokens <= balances[addr], "Insufficient funds");
        _;
    }
    
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    // -------------------------------- Events ---------------------------------

    event Issue(address indexed to, uint256 tokens);
    event IssueFinished();
    event ShareholderAdded(address shareholder);
    event ShareholderRemoved(address shareholder);

    // -------------------------------------------------------------------------

    function detectTransferRestriction (address from, address to, uint256 value)
        public
        view
        returns (uint8 restrictionCode)
    {
        restrictionCode = SUCCESS_CODE;
    }
        
    function messageForTransferRestriction (uint8 restrictionCode)
        public
        view
        returns (string message)
    {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        }
    }
    
    function transfer (address to, uint256 value)
        public
        hasFunds(msg.sender, value)
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        transferTokens(msg.sender, to, value);
        success = true;
    }

    /**
     * (not used)
     */
    function transferFrom (address from, address to, uint256 value)
        public
        returns (bool success)
    {
        success = false;
    }

    function issueTokens(uint256 quantity)
    external
    onlyOwner
    canIssue
    returns (bool) {
        // Avoid doing any state changes for zero quantities
        if (quantity > 0) {
            totalSupplyTokens = totalSupplyTokens.add(quantity);
            balances[owner] = balances[owner].add(quantity);
            shareholders.append(owner);
        }
        emit Issue(owner, quantity);
        emit Transfer(ZERO_ADDRESS, owner, quantity);
        return true;
    }

    function finishIssuing()
    external
    onlyOwner
    canIssue
    returns (bool) {
        issuingFinished = true;
        emit IssueFinished();
        return issuingFinished;
    }

    /**
     * (not used)
     */
    function approve(address spender, uint256 tokens)
    external
    returns (bool) {
        return false;
    }

    // -------------------------------- Getters --------------------------------

    function totalSupply()
    external
    view
    returns (uint256) {
        return totalSupplyTokens;
    }

    function balanceOf(address addr)
    external
    view
    returns (uint256) {
        return balances[addr];
    }

    /**
     *  (not used)
     */
    function allowance(address addrOwner, address spender)
    external
    view
    returns (uint256) {
        return 0;
    }

    function holderAt(int256 index)
    external
    view
    returns (address){
        return shareholders.at(index);
    }

    function isHolder(address addr)
    external
    view
    returns (bool) {
        return shareholders.exists(addr);
    }


    // -------------------------------- Private --------------------------------

    function transferTokens(address from, address to, uint256 tokens)
    private {
        // Update balances
        balances[from] = balances[from].subtract(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);

        // Adds the shareholder if they don&#39;t already exist.
        if (balances[to] > 0 && shareholders.append(to)) {
            emit ShareholderAdded(to);
        }
        // Remove the shareholder if they no longer hold tokens.
        if (balances[from] == 0 && shareholders.remove(from)) {
            emit ShareholderRemoved(from);
        }
    }

}