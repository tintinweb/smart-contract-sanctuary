/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function emitTransfer(address _from, address _to, uint256 _amount) external returns (bool);
}

interface IRNG {
    function random(address _sender, uint256 _nonce, uint256 _modulo) external view returns (uint256);
}

contract HamsterBurrow {
    address public owner;
    address private mapper;
    address private rng;
    uint256 public startBlock;
    uint256 public endBlock;
    mapping (address => bool) private tokenWhitelist;
    mapping (string => address) public tokenNames;
    mapping (address => mapping(address => uint256)) public balances; // tokenAddress => owner => balance ToDo: make it private
    mapping (address => uint256) public totalSupply; // tokenAddress => totalSupply ToDo: make it private
    mapping (address => uint256) public birthRates; // owner => emissionRate
    mapping (address => uint256) public lastUpdated; // owner => blockNumber
    mapping (address => uint256) private nonces; // owner => rngCount

    uint256 private constant VIRUS_AMOUNT = 1000000; // Initial Virus Infection Amount
    uint256 private constant VIRUS_MAX = 256000000; // Virus cannot reproduce over this amount

    // Time paramters (Mainnet)
    uint256 private constant BLOCK_INTERVAL = 3 seconds;
    uint256 private constant NUM_BLOCK_GAME = 365 days / BLOCK_INTERVAL;
    uint256 private constant NUM_BLOCK_TO_FEED = 24 hours / BLOCK_INTERVAL;
    uint256 private constant NUM_BLOCK_TO_DUPLICATE = 24 hours / BLOCK_INTERVAL;
    uint256 private constant EMISSION_RATE = 100000000; // Queen+King reproduce 100 BABY per block

    // Probability Parameters
    uint256 private constant MUTATE_ENTROPY = 10; // 10% (1/10)
    uint256 private constant QUEEN_ENTROPY = 2; // 50% (1/2)

    // Excnahge Rate Parameters
    uint256 private constant HAM_PER_MERGE = 100000000; // 100 HAM -> 1 QUEEN or KING
    uint256 private constant HAM_PER_SEPARATE = 90000000; // 1 QUEEN or KING -> 90 HAM
    uint256 private constant BABY_PER_HAM = 1000000000; // 1000 BABY -> 1 HAM

    constructor() {
        owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == mapper, 'HamsterBurrow: no owner role');
        _;
    }

    modifier onlyWhitelisted() {
        require(tokenWhitelist[msg.sender], 'HamsterBurrow: token not whitelisted');
        _;
    }
    
    // Views
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
            numPending = min(blockNumber() - lastUpdated[_owner], NUM_BLOCK_TO_FEED) * numMates * birthRates[_owner];
        }
        return numPending;
    }

    function pendingVirusPlus(address _owner) public view returns (uint256) {
        uint256 numPending = 0;
        uint256 base = balances[tokenNames['VIRUS']][_owner];
        if(base > 0) {
            numPending = (blockNumber() - lastUpdated[_owner]) * base / NUM_BLOCK_TO_DUPLICATE;
        }
        return numPending;
    }

    // External Functions
    function mint(address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        _mint(msg.sender, _to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyWhitelisted returns (bool) {
        _burn(msg.sender, _from, _amount);
        return true;
    }

    function transfer(address _from, address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        updateBalance(_from);
        updateBalance(_to);

        if(_amount > 0) {
            require(balances[msg.sender][_from] >= _amount, 'HamsterBurrow: insufficient fund');

            balances[msg.sender][_from] -= _amount;
            balances[msg.sender][_to] += _amount;
        
            IERC20(msg.sender).emitTransfer(_from, _to, _amount);
        }

        callback(_from, _to, _amount);

        updateBirthRate(_from);
        updateBirthRate(_to);

        return true;
    }

    function tokenReceived(address _from, uint _amount) external returns (bool) {
        require(msg.sender == tokenNames['HAMSTER'], 'HamsterBurrow: only HamsterCoin can call');
        
        if(_from != owner) {
            updateBalance(_from);
            merge(_from, _amount);
            updateBirthRate(_from);
        }

        return true;
    }

    // Private Functions
    function _mint(address _token, address _to, uint256 _amount) private returns (bool) {
        balances[_token][_to] += _amount;
        totalSupply[_token] += _amount;
        IERC20(_token).emitTransfer(address(0), _to, _amount);
        return true;
    }

    function _burn(address _token, address _from, uint256 _amount) private returns (bool) {
        balances[_token][_from] = balances[_token][_from] > _amount ? balances[_token][_from] - _amount : 0;
        totalSupply[_token] = totalSupply[_token] > _amount ? totalSupply[_token] - _amount : 0;
        IERC20(_token).emitTransfer(_from, address(0), _amount);
        return true;        
    }

    function updateBalance(address _owner) private returns (bool) { // ToDo: make it private
        // Current Balance
        uint256 currentBabyBalance = balanceOf(tokenNames['BABY'], _owner);
        uint256 currentVirusBalance = balanceOf(tokenNames['VIRUS'], _owner);

        // Adjust totalSupply
        totalSupply[tokenNames['BABY']] += currentBabyBalance - balances[tokenNames['BABY']][_owner];
        totalSupply[tokenNames['VIRUS']] += currentVirusBalance - balances[tokenNames['VIUS']][_owner];

        // Update balances (flush pending balance)
        balances[tokenNames['BABY']][_owner] = currentBabyBalance;
        balances[tokenNames['VIRUS']][_owner] = currentVirusBalance;
        lastUpdated[_owner] = blockNumber();

        mutate(_owner);
        cure(_owner);
        return true;
    }

    function updateBirthRate(address _owner) private returns (bool) { // ToDo: make it private
        uint256 numQK = totalSupply[tokenNames['QUEEN']] + totalSupply[tokenNames['KING']];
        if(numQK > 0) {
            birthRates[_owner] = EMISSION_RATE * 2 / (totalSupply[tokenNames['QUEEN']] + totalSupply[tokenNames['KING']]);
        }else{
            birthRates[_owner] = 0;
        }
        return true;
    }

    // Triggers
    function callback(address _from, address _to, uint256 _amount) private onlyWhitelisted returns (bool) {
        if(_to == address(this)) {
            if (msg.sender == tokenNames['BABY']) transmute(_from, _amount);
            else if (msg.sender == tokenNames['QUEEN']) separate(_from, _amount);
            else if (msg.sender == tokenNames['KING']) separate(_from, _amount);
        } else {
            if (msg.sender == tokenNames['VIRUS']) cancel(_from, _to, _amount);
            else if (msg.sender == tokenNames['VACCINE']) cure(_to);
            else infect(_from, _to);
        }
        return true;   
    }

    // Actions
    function mutate(address _owner) private returns (bool) {
        uint256 random = IRNG(rng).random(_owner, nonces[_owner], MUTATE_ENTROPY);
        if(random == 0) {
            _mint(tokenNames['VIRUS'], _owner, VIRUS_AMOUNT);
        }
        nonces[_owner]++;
        return true;
    }

    function cure(address _owner) private returns (bool) {
        uint256 vrsBalance = balanceOf(tokenNames['VIRUS'], _owner);
        uint256 vacBalance = balanceOf(tokenNames['VACCINE'], _owner);

        if(vrsBalance > 0 && vacBalance > 0) {
            if(vrsBalance >= vacBalance) {
                balances[tokenNames['VIRUS']][_owner] = vrsBalance - vacBalance;
                balances[tokenNames['VACCINE']][_owner] = 0;
                IERC20(tokenNames['VIRUS']).emitTransfer(_owner, address(0), vacBalance);
                IERC20(tokenNames['VACCINE']).emitTransfer(_owner, address(0), vacBalance);
            } else {
                balances[tokenNames['VIRUS']][_owner] = 0;
                balances[tokenNames['VACCINE']][_owner] = vacBalance - vrsBalance;    
                IERC20(tokenNames['VIRUS']).emitTransfer(_owner, address(0), vrsBalance);
                IERC20(tokenNames['VACCINE']).emitTransfer(_owner, address(0), vrsBalance);
            }
        }

        return true;
    }

    function merge(address _owner, uint256 _amount) private returns (bool) {
        uint256 refund = 0;
        if(_amount >= HAM_PER_MERGE) {
            refund = _amount - HAM_PER_MERGE;
            uint256 random = IRNG(rng).random(_owner, nonces[_owner], QUEEN_ENTROPY);
            if(random == 0) {
                _mint(tokenNames['QUEEN'], _owner, 1);
            } else {
                _mint(tokenNames['KING'], _owner, 1);
            }
            nonces[_owner]++;
        } else {
            refund = _amount;
        }

        if(refund > 0) {
            IERC20(tokenNames['HAMSTER']).transfer(_owner, refund);
        }

        return true;
    }

    function separate(address _owner, uint256 _amount) private returns (bool) {
        _burn(msg.sender, address(this), _amount); // Burn Queen or King
        IERC20(tokenNames['HAMSTER']).transfer(_owner, _amount * HAM_PER_SEPARATE);
        return true;
    }

    function transmute(address _owner, uint256 _amount) private returns (bool) {
        _burn(tokenNames['BABY'], _owner, _amount);
        IERC20(tokenNames['HAMSTER']).transfer(_owner, _amount * 1e6 / BABY_PER_HAM);
        return true;
    }

    function cancel(address _from, address _to, uint256 _amount) private returns (bool) {
        _mint(tokenNames['VIRUS'], _from, _amount);
        cure(_to);
        return true;
    }

    function infect(address _from, address _to) private returns (bool) {
        if(balanceOf(tokenNames['VIRUS'], _from) > 0) {
            _mint(tokenNames['VIRUS'], _to, balanceOf(tokenNames['VIRUS'], _from));
            cure(_to);
        }
        return true;
    }

    // Admin
    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        owner = _newOwner;
        return true;
    }

    function setMapper(address _mapper) external onlyOwner returns (bool) {
        mapper = _mapper;
        return true;
    }

    function init(address _rng, uint256 _startBlock) public onlyOwner returns (bool) {
        rng = _rng;
        startBlock = _startBlock == 0 ? block.number : _startBlock;
        endBlock = startBlock + NUM_BLOCK_GAME;
        return true;
    }

    function setToken(address _token, string memory _name) public onlyOwner returns (bool) {
        tokenWhitelist[_token] = true;
        tokenNames[_name] = _token;
        return true;
    }

    function setEndBlock(uint256 _endBlock) external onlyOwner returns (bool) {
        endBlock = _endBlock;
        return true;
    }

    // Utils
    function min(uint256 _x, uint256 _y) private pure returns (uint256) {
        return _x > _y ? _y : _x;
    }

    function blockNumber() private view returns (uint256) { // ToDo: make it private
        return min(block.number, endBlock);
    }
}