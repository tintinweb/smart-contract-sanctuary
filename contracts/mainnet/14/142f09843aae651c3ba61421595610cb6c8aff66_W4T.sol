pragma solidity ^0.4.19;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract W4T {
    string public name = &#39;W4T&#39;;
    string public symbol = &#39;W4T&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;
    uint public miningReward = 1000000000000000000;
    uint private randomNumber;
    
    address public owner;
    
    uint public domainPrice = 10000000000000000000; // 10 W4T
    uint public bytePrice   = 100000000000000;      // 0.0001 W4T
    uint public premiumDomainK = 10;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public successesOf;
    mapping (address => uint256) public failsOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (bytes8 => bool) public zones;
    mapping (bytes8 => mapping (bytes32 => address)) public domains;
    mapping (bytes8 => mapping (bytes32 => mapping (bytes32 => string))) public pages;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    event ZoneRegister(bytes8 zone);
    event DomainRegister(bytes8 zone, string domain, address owner);
    event PageRegister(bytes8 zone, string domain, bytes32 path, string content);
    event DomainTransfer(bytes8 zone, string domain, address owner);
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function W4T() public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) external {
        _transfer(msg.sender, _to, _value);
    }
    
    /* Transfer tokens from other address */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    /* Set allowance for other address */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /* Set allowance for other address and notify */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn(uint256 _value) internal returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function registerZone(bytes8 zone) external onlyOwner {
        zones[zone] = true;
        ZoneRegister(zone);
    }
    
    function registerDomain(bytes8 zone, string domain) external {
        uint domainLength = bytes(domain).length;
        require(domainLength >= 2 && domainLength <= 32);
        bytes32 domainBytes = stringToBytes32(domain);
        require(zones[zone]);
        require(domains[zone][domainBytes] == 0x0);
        
        uint amount = domainPrice;
        if (domainLength <= 4) {
            amount *= premiumDomainK ** (5 - domainLength);
        }
        burn(amount);
        domains[zone][domainBytes] = msg.sender;
        DomainRegister(zone, domain, msg.sender);
    }
    
    function registerPage(bytes8 zone, string domain, bytes32 path, string content) external {
        uint domainLength = bytes(domain).length;
        require(domainLength >= 2 && domainLength <= 32);
        bytes32 domainBytes = stringToBytes32(domain);
        require(zones[zone]);
        require(domains[zone][domainBytes] == msg.sender);
        
        burn(bytePrice * bytes(content).length);
        pages[zone][domainBytes][path] = content;
        PageRegister(zone, domain, path, content);
    }
    
    function transferDomain(bytes8 zone, string domain, address newOwner) external {
        uint domainLength = bytes(domain).length;
        require(domainLength >= 2 && domainLength <= 32);
        bytes32 domainBytes = stringToBytes32(domain);
        require(zones[zone]);
        require(domains[zone][domainBytes] == msg.sender);
        
        domains[zone][domainBytes] = newOwner;
        DomainTransfer(zone, domain, newOwner);
    }
    
    function () external payable {
        if (msg.value == 0) {
            randomNumber += block.timestamp + uint(msg.sender);
            uint minedAtBlock = uint(block.blockhash(block.number - 1));
            uint minedHashRel = uint(sha256(minedAtBlock + randomNumber + uint(msg.sender))) % 100000;
            uint balanceRel = balanceOf[msg.sender] * 1000 / totalSupply;
            if (balanceRel >= 1) {
                if (balanceRel > 29) {
                    balanceRel = 29;
                }
                balanceRel = 2 ** balanceRel;
                balanceRel = 50000 / balanceRel;
                balanceRel = 50000 - balanceRel;
                if (minedHashRel < balanceRel) {
                    uint reward = miningReward + minedHashRel * 100000000000000;
                    balanceOf[msg.sender] += reward;
                    totalSupply += reward;
                    Transfer(0, this, reward);
                    Transfer(this, msg.sender, reward);
                    successesOf[msg.sender]++;
                } else {
                    Transfer(this, msg.sender, 0);
                    failsOf[msg.sender]++;
                }
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
}