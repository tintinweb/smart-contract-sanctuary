pragma solidity ^0.4.11;

contract DMINT {
    string public name = &#39;DMINT&#39;;
    string public symbol = &#39;DMINT&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000000;
    uint public miningReward = 1000000000000000000;
    uint private divider;
    uint private randomNumber;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public successesOf;
    mapping (address => uint256) public failsOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DMINT() public {
        balanceOf[msg.sender] = totalSupply;
        divider -= 1;
        divider /= 1000000000;
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
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function () external payable {
        if (msg.value == 0) {
            randomNumber += block.timestamp + uint(msg.sender);
            uint minedAtBlock = uint(block.blockhash(block.number - 1));
            uint minedHashRel = uint(sha256(minedAtBlock + randomNumber + uint(msg.sender))) / divider;
            uint balanceRel = balanceOf[msg.sender] * 1000000000 / totalSupply;
            if (balanceRel >= 100000) {
                uint k = balanceRel / 100000;
                if (k > 255) {
                    k = 255;
                }
                k = 2 ** k;
                balanceRel = 500000000 / k;
                balanceRel = 500000000 - balanceRel;
                if (minedHashRel < balanceRel) {
                    uint reward = miningReward + minedHashRel * 100000000000000;
                    balanceOf[msg.sender] += reward;
                    totalSupply += reward;
                    Transfer(0, this, reward);
                    Transfer(this, msg.sender, reward);
                    successesOf[msg.sender]++;
                } else {
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