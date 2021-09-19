/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface TokenConverter {
    function checkTokensDistance(address _tokenA, address _tokenB) external view returns (uint8);
    function convertTwo(
        address _tokenA,
        address _tokenB,
        uint _amount
    ) external view returns (uint);
    function DEFAULT_ROUTER() external returns (address);
    function DEFAULT_FACTORY() external returns (address);
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract TokenWrapped {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    uint public start = 0;
    uint public THRESHOLD = 30 minutes;
    uint public MAX_DOLLARS = 1000 * 1e18;
    uint public DELAY = 20 seconds;

    // main
    address constant public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant public USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant public TOKEN_CONVERTER = 0xe2bf8ef5E2b24441d5B2649A3Dc6D81afC1a9517;

    TokenConverter tokenConverter;

    address public owner;
    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    modifier issuerOnly {
        require(isIssuer[msg.sender], "You do not have issuer rights");
        _;
    }
    modifier whitelistOnly {
        require(isWhitelist[msg.sender], "You do not have whitelist rights");
        _;
    }

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public isIssuer;
    mapping(address => bool) public isWhitelist;
    mapping(address => uint) public periods;


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event IssuerRights(address indexed issuer, bool value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function mint(address _to, uint _amount) external issuerOnly returns (bool success) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint _amount) external issuerOnly returns (bool success) {
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function burnFrom(address _from, uint _amount) external issuerOnly returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint _amount) external returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


    function transfer(address _to, uint _amount) external returns (bool success) {
        if (!isCan(msg.sender, _to, _amount)) return false;
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
        
    }

    function transferFrom(address _from, address _to, uint _amount) external returns (bool success) {
        if (!isCan(_from, _to, _amount)) return false;
        require(_amount <= balanceOf[_from]);
        require(_amount <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function isCan(address _from, address _to, uint _amount) internal returns (bool success) {

        if (isWhitelist[_from] || isWhitelist[_to]) {
            if (tokenConverter.checkTokensDistance(address(this), WBNB) == 1) {
                if (start == 0) start = block.timestamp;
            }
            return true;
        }

        if (tokenConverter.checkTokensDistance(address(this), WBNB) == 0) { 
            return true; 
        } else {
            if (start == 0) start = block.timestamp; 
            if ((block.timestamp - start) >= THRESHOLD) return true;

            uint inWBNB = tokenConverter.convertTwo(USDT, WBNB, MAX_DOLLARS);
            uint inToken = tokenConverter.convertTwo(WBNB, address(this), inWBNB);

            if (_amount <= inToken) return true;

            address _pair = getPairAddress(address(this), WBNB, tokenConverter.DEFAULT_FACTORY());
            // address _router = tokenConverter.DEFAULT_ROUTER();
            // buy
            if (msg.sender == _pair && _from == _pair) return false;
            // sell
            // if (msg.sender == _router && _to == _pair) return false;

            // delay between transactions
            if ((block.timestamp - periods[msg.sender]) < DELAY) return false;
            else periods[msg.sender] = block.timestamp;
            
        }
        
        return true;
    }

    function getPairAddress(address t1, address t2, address factory) internal view returns (address) {
        return IFactory(factory).getPair(t1, t2); 
    }


    function transferOwnership(address _newOwner) external restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function setIssuerRights(address _issuer, bool _value) external restricted {
        isIssuer[_issuer] = _value;
        emit IssuerRights(_issuer, _value);
    }

    function setWhitelistRights(address _user, bool _value) external restricted {
        isWhitelist[_user] = _value;
    }

    function setWhitelistUsers(address[] memory addresses, bool value)
    external restricted {
        for (uint i = 0; i < addresses.length; i++) {
            isWhitelist[addresses[i]] = value;
        }
    }

    function setThreshold(uint value_) external restricted {
        THRESHOLD = value_;
    }

    function setMaxDollars(uint value_) external restricted {
        MAX_DOLLARS = value_;
    }

    constructor() {
        name = 'DeSpace Protocol';
        symbol = 'DES';
        decimals = 18;

        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);

        isIssuer[msg.sender] = true;
        emit IssuerRights(msg.sender, false);

        tokenConverter = TokenConverter(TOKEN_CONVERTER);
    }
}