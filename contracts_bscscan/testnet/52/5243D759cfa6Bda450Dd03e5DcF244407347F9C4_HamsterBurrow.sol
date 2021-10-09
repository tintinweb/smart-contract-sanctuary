/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function emitTransfer(address _from, address _to, uint256 _amount) external returns (bool);
}

interface IRNG {
    function generate(address _sender, uint256 _nonce, uint256 _modulo) external view returns (uint256);
}

contract HamsterBurrow {
    address public owner;
    address private rng;
    mapping (address => bool) public tokenWhitelist;
    mapping (string => address) public tokenNames;
    mapping (address => mapping(address => uint256)) public balances; // tokenAddress => owner => balance
    mapping (address => uint256) public totalSupply; // tokenAddress => totalSupply
    mapping (address => uint256) public lastUpdated; // owner => blockNumber
    mapping (address => uint256) public lastMerges; // owner => mergedBlockNumber
    mapping (address => uint256) public nonces; // owner => rngCount

    uint256 public BIRTH_RATE = 1000000; // BHAM per block
    uint256 public VIRUS_RATE = 1000000; // VRS per block
    uint256 public VIRUS_MAX = 256000000;
    uint256 public TIME_TO_FEED = 24 hours / 15 seconds;
    uint256 public TIME_TO_DUPLICATE = 24 hours / 15 seconds;
    uint256 public MUTATE_ENTROPY = 10; // 10% (1/10)
    uint256 public QUEEN_ENTROPY = 2; // 50% (1/2)
    uint256 public CONVERSION = 100000000000;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'insufficient privilege');
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        owner = _newOwner;
        return true;
    }

    modifier onlyWhitelisted() {
        require(tokenWhitelist[msg.sender], 'token not whitelisted');
        _;
    }

    function init(address _rng) external onlyOwner returns (bool) {
        rng = _rng;
        return true;
    }

    function balanceOf(address _token, address _owner) public view returns (uint256) {
        if(_token == tokenNames['BABY']) {
            return balances[_token][_owner] + pendingHamsterPlus(_owner);
        } else if (_token == tokenNames['VIRUS']) {
            return min(balances[_token][_owner] + pendingVirusPlus(_owner), VIRUS_MAX);
        } else {
            return balances[_token][_owner];
        }
    }
    
    function pendingHamsterPlus(address _owner) public view returns (uint256) {
        uint256 numPending = 0;
        if(balanceOf(tokenNames['VIRUS'], _owner) == 0) {
            uint256 numMates = min(balances[tokenNames['QUEEN']][_owner], balances[tokenNames['KING']][_owner]);
            numPending = min(block.number - lastUpdated[_owner], TIME_TO_FEED) * numMates * BIRTH_RATE;
        }
        return numPending;    
    }

    function pendingVirusPlus(address _owner) public view returns (uint256) {
        uint256 numPending = 0;
        uint256 base = balances[tokenNames['VIRUS']][_owner];
        if(base > 0) {
            numPending = (block.number - lastUpdated[_owner]) * base / TIME_TO_DUPLICATE;
        }
        return numPending;
    }

    function mint(address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        _mint(msg.sender, _to, _amount);
        return true;
    }

    function _mint(address _token, address _to, uint256 _amount) private returns (bool) {
        balances[_token][_to] += _amount;
        totalSupply[_token] += _amount;
        IERC20(_token).emitTransfer(address(0), _to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyWhitelisted returns (bool) {
        balances[msg.sender][_from] -= _amount;
        totalSupply[msg.sender] -= _amount;
        IERC20(msg.sender).emitTransfer(_from, address(0), _amount);
        return true;
    }

    function transfer(address _from, address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        updateBalance(_from);
        updateBalance(_to);

        if(_amount > 0) {
            require(balances[msg.sender][_from] >= _amount, 'insufficient fund');

            balances[msg.sender][_from] -= _amount;
            balances[msg.sender][_to] += _amount;
        
            IERC20(msg.sender).emitTransfer(_from, _to, _amount);
        }

        callback(_from, _to, _amount);
        
        return true;
    }

    function updateBalance(address _owner) private returns (bool) {
        balances[tokenNames['BABY']][_owner] = balanceOf(tokenNames['BABY'], _owner);
        balances[tokenNames['VIRUS']][_owner] = balanceOf(tokenNames['VIRUS'], _owner);
        lastUpdated[_owner] = block.number;
        mutate(_owner);
        return true;
    }

    // Triggers
    function callback(address _from, address _to, uint256 _amount) private onlyWhitelisted returns (bool) {
        if(_to == address(this)) {
            if (msg.sender == tokenNames['BABY']) merge(_from, _amount);
            else if (msg.sender == tokenNames['SEED']) reveal(_from);
        } else {
            if (msg.sender == tokenNames['VIRUS']) cancel(_from, _amount);
            else if (msg.sender == tokenNames['VACCINE']) cure(_to);
            else infect(_from, _to);
        }
        return true;   
    }

    // Actions
    function mutate(address _owner) private returns (bool) {
        uint256 random = IRNG(rng).generate(_owner, nonces[_owner], MUTATE_ENTROPY);
        if(random == 0) {
            _mint(tokenNames['VIRUS'], _owner, VIRUS_RATE);
        }
        nonces[_owner]++;
        return true;
    }

    function cure(address _owner) private returns (bool) {
        uint256 vrsBalance = balanceOf(tokenNames['VIRUS'], _owner);
        uint256 vacBalance = balanceOf(tokenNames['VACCINE'], _owner);

        if(vrsBalance >= vacBalance) {
            balances[tokenNames['VIRUS']][_owner] = vrsBalance - vacBalance;
            balances[tokenNames['VACCINE']][_owner] = 0;
            IERC20(tokenNames['VIRUS']).emitTransfer(_owner, address(0), vacBalance);
            IERC20(tokenNames['VACCINE']).emitTransfer(_owner, address(0), vacBalance);
        } else {
            balances[tokenNames['VIRUS']][_owner] = 0;
            balances[tokenNames['VACCINE']][_owner] = 0;    
            IERC20(tokenNames['VIRUS']).emitTransfer(_owner, address(0), vrsBalance);
            IERC20(tokenNames['VACCINE']).emitTransfer(_owner, address(0), vacBalance);
        }
        return true;
    }

    function merge(address _owner, uint256 _amount) private returns (bool) {
        uint256 refund = 0;
        if(_amount >= CONVERSION && lastMerges[_owner] == 0) {
            refund = _amount - CONVERSION;
            lastMerges[_owner] = block.number;
        } else {
            refund = _amount;
        }
        if(refund > 0) {
            balances[msg.sender][_owner] += refund;
            IERC20(msg.sender).emitTransfer(address(this), _owner, refund);
        }
        return true;
    }

    function reveal(address _owner) private returns (bool) {
        if (lastMerges[_owner] > 0 && lastMerges[_owner] < block.number) {
            uint256 random = IRNG(rng).generate(_owner, nonces[_owner], QUEEN_ENTROPY);
            if(random == 0) {
                _mint(tokenNames['QUEEN'], _owner, 1);
            } else {
                _mint(tokenNames['KING'], _owner, 1);
            }
            lastMerges[_owner] = 0;
            nonces[_owner]++;
        }
        return true;         
    }

    function cancel(address _owner, uint256 _amount) private returns (bool) {
        _mint(tokenNames['VIRUS'], _owner, _amount);
        return true;
    }

    function infect(address _from, address _to) private returns (bool) {
        if(balanceOf(tokenNames['VIRUS'], _from) > 0) {
            _mint(tokenNames['VIRUS'], _to, balanceOf(tokenNames['VIRUS'], _from));
        }
        return true;
    }

    // Admin
    function setToken(address _token, string memory _name) external onlyOwner returns (bool) {
        tokenWhitelist[_token] = true;
        tokenNames[_name] = _token;
        return true;
    }

    // Utils
    function min(uint256 _x, uint256 _y) private pure returns (uint256) {
        return _x > _y ? _y : _x;
    }

    // Debug
    function setBalance(address _token, address _owner, uint256 _balance) external onlyOwner returns (bool) {
        balances[_token][_owner] = _balance;
        totalSupply[_token] += _balance;
        return true;
    }

    function setLastTransfer(address _owner, uint256 _block) external onlyOwner returns (bool) {
        lastUpdated[_owner] = _block;
        return true;
    }

    function setLastMerge(address _owner, uint256 _block) external onlyOwner returns (bool) {
        lastMerges[_owner] = _block;
        return true;
    }

    function setNonce(address _owner, uint256 _nonce) external onlyOwner returns (bool) {
        nonces[_owner] = _nonce;
        return true;
    }
}