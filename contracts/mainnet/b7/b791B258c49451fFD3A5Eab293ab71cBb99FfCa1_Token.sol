// File: contracts/Ownable.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Function can only be performed by the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

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

// File: contracts/Token.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;



contract Token is Ownable {
    using SafeMath for uint;

    uint256 private constant _totalSupply = 80808808000000000000000;
    uint256 private constant _top = 100;
    uint256 private _beginTax;

    uint256 public holdersCount;
    address constant GUARD = address(1);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => address) private _nextHolders;

    function name() public view returns (string memory) {
        return "BINGO";
    }

    function symbol() public view returns (string memory) {
        return "BING0";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    constructor () public {
        _nextHolders[GUARD] = GUARD;
        _beginTax = now + 30 minutes;

        addHolder(msg.sender, 80808808000000000000000);

        emit Transfer(address(0), msg.sender, 80808808000000000000000);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Invalid address 3");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address who) public view returns (uint256) {
        return _balances[who];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(_balances[msg.sender] >= value, "Insufficient balance");

        _transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(_balances[from] >= value, "Insufficient balance");
        require(_allowances[from][msg.sender] >= value, "Insufficient balance");
        
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

        _transferFrom(from, to, value);
    }

    function _transferFrom(address from, address to, uint256 value) private returns (bool) {
        if (now > _beginTax) {
            address random = _getRandomHolder();
            uint256 tax = value.mul(15).div(100);
            value = value.mul(85).div(100);

            _updateBalance(random, _balances[random].add(tax));

            emit Transfer(from, random, tax);
        }
        
        if (_balances[to] == 0) {
            addHolder(to, value);
        } else {
            _updateBalance(to, _balances[to].add(value));
        }

        if (_balances[from].sub(value) == 0) {
            removeHolder(from);
        } else {
            _updateBalance(from, _balances[from].sub(value));
        }

        emit Transfer(from, to, value);
        return true;
    }

    //make private
    function addHolder(address who, uint256 balance) private {
        require(_nextHolders[who] == address(0), "Invalid address (add holder)");

        address index = _findIndex(balance);
        _balances[who] = balance;

        _nextHolders[who] = _nextHolders[index];
        _nextHolders[index] = who;

        holdersCount = holdersCount.add(1);
    }

    //make private
    function removeHolder(address who) private {
        require(_nextHolders[who] != address(0), "Invalid address (remove holder)");

        address prevHolder = _findPrevHolder(who);
        _nextHolders[prevHolder] = _nextHolders[who];
        _nextHolders[who] = address(0);
        _balances[who] = 0;
        holdersCount = holdersCount.sub(1);
    }

    function getTopHolders(uint256 k) public returns (address[] memory) {
        require(k <= holdersCount, "Index out of bounds");
        address[] memory holdersLists = new address[](k);
        address currentAddress = _nextHolders[GUARD];
        
        for(uint256 i = 0; i < k; ++i) {
            holdersLists[i] = currentAddress;
            currentAddress = _nextHolders[currentAddress];
        }

        return holdersLists;
    }

    function getTopHolder(uint256 n) public returns (address) {
        require(n <= holdersCount, "Index out of bounds");
        address currentAddress = _nextHolders[GUARD];
        
        for(uint256 i = 0; i < n; ++i) {
            currentAddress = _nextHolders[currentAddress];
        }

        return currentAddress;
    }

    function _updateBalance(address who, uint256 newBalance) internal {
        require(_nextHolders[who] != address(0), "Invalid address (update balance)");
        address prevHolder = _findPrevHolder(who);
        address nextHolder = _nextHolders[who];

        if(_verifyIndex(prevHolder, newBalance, nextHolder)){
            _balances[who] = newBalance;
        } else {
            removeHolder(who);
            addHolder(who, newBalance);
        }
    }

    function _verifyIndex(address prevHolder, uint256 newValue, address nextHolder) internal view returns(bool) {
        return (prevHolder == GUARD || _balances[prevHolder] >= newValue) && 
            (nextHolder == GUARD || newValue > _balances[nextHolder]);
    }

    function _findIndex(uint256 newValue) internal view returns(address) {
        address candidateAddress = GUARD;
        while(true) {
            if(_verifyIndex(candidateAddress, newValue, _nextHolders[candidateAddress]))
                return candidateAddress;
                
            candidateAddress = _nextHolders[candidateAddress];
        }
    }

    function _isPrevHolder(address who, address prev) internal view returns(bool) {
        return _nextHolders[prev] == who;
    }

    function _findPrevHolder(address who) internal view returns(address) {
        address currentAddress = GUARD;
        while(_nextHolders[currentAddress] != GUARD) {
            if(_isPrevHolder(who, currentAddress))
                return currentAddress;
                
            currentAddress = _nextHolders[currentAddress];
        }

        return address(0);
    }

    function _getRandomHolder() private returns (address) {
        uint256 mod = 100;

        if (holdersCount < 100) {
            mod = holdersCount;
        }

        uint256 n = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
        uint256 randomIndex = n % mod;

        return getTopHolder(randomIndex);
    }

    function quickSort(uint[] memory arr, int left, int right) internal {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}