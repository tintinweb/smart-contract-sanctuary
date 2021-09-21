/**
 *Submitted for verification at polygonscan.com on 2021-09-20
*/

pragma solidity 0.8.1; 


contract incrementCoin {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 public _totalSupply;                        // Update total supply (100000 for example)
    string public name;                                   // Set the name for display purposes
    uint public decimals;                            // Amount of decimals for display purposes
    string public symbol; 
    address[] public approvedMinters;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    using SafeMath for uint256;
    
    constructor() {
        balances[msg.sender] = 100;               // Give the creator all initial tokens (100000 for example)
        _totalSupply = 100000;                        // Update total supply (100000 for example)
        name = "Increment Coin";                                   // Set the name for display purposes
        decimals = 5;                            // Amount of decimals for display purposes
        symbol = "ICUP"; 
        approvedMinters.push(msg.sender);
        approvedMinters.push(0x882f55CF807b3f941a289c42196183EF75836353);
    }
    
    function transfer(address to, uint256 numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender].sub(numTokens);
      balances[to] = balances[to].add(numTokens);
      emit Transfer(msg.sender, to, numTokens);
      return true;
    }
    
    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
      return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address delegate) public view returns (uint) {
        return allowed[tokenOwner][delegate];
    }
    
    function approve(address delegate, uint numTokens)  public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= balances[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      balances[owner] = balances[owner].sub(numTokens);
      allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
      balances[buyer] = balances[buyer].add(numTokens);
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    modifier onlyMinter {
        bool isAnApprovedMinter = false;
        for (uint i = 0; i < approvedMinters.length; i++) {
            if (approvedMinters[i] == msg.sender) {
                isAnApprovedMinter = true;
                break;
            }
        }
        require(isAnApprovedMinter);
        _;
    }
    
    function mint(address to, uint256 numTokens) public onlyMinter returns (bool) {
        _totalSupply = _totalSupply.add(numTokens);
        if (0 <= balances[to]) {
            balances[to] = balances[to].add(numTokens);
            return true;
        }
        balances[to] = numTokens;
        return true;
    }

    // adds a minter for the coin
    function addMinter(address account) public onlyMinter {
        approvedMinters.push(account);
        emit MinterAdded(account);
    }
    
    // let's a person remove themselves from the minter list
    function renounceMinter() public {
        bool isAnApprovedMinter = false;
        for (uint i = 0; i < approvedMinters.length; i++) {
            if (approvedMinters[i] == msg.sender) {
                isAnApprovedMinter = true;
                delete approvedMinters[i];
                break;
            }
        }
        require(isAnApprovedMinter);
        MinterRemoved(msg.sender);
    }
    
    function transferMinterRole(address newMinter) public {
        for (uint i = 0; i < approvedMinters.length; i++) {
            if (approvedMinters[i] == msg.sender) {
                delete approvedMinters[i];
                emit MinterRemoved(msg.sender);
                approvedMinters.push(newMinter);
                emit MinterAdded(newMinter);
                break;
            }
        }
    }
    
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}