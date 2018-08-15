pragma solidity ^0.4.24;

// DO YOU LOVE 0xBTC?
// LETS SUMMARIZE 0xBTC
// > PURE MINED CRYPTO
// > PoW CONSENSUS PROVIDED BY ETH
// > NO TEAM, NO ICO, JUST VOLUNTEERS 
// > TRUSTLESS ERC20 
// UPLOAD YOUR REASON WHY YOU LOVE 0xBTC AND GET FREE 0xBTCLOVE TOKENS! 
// (also check the Transfer address in the ILove0xBTC function)

contract ZEROxBTCLove {

    string public name = "0xBTCLove";      //  token name
    string public symbol = "0xBTCLove";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (uint => bool) public ZEROxBTCLovers;
    

    uint256 public totalSupply = 0;

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }
    
    // MINE YOUR OWN 0xBTCLOVE FUNCTIONS!!
    // DIFFICULTY ALWAYS... 0! (but it will rise slightly because you cannot mine strings which other people submitted, or you just found a hash collission!!)
    
    function ILove0xBTC(string reason) public {
        uint hash = uint(keccak256(bytes(reason)));
        if (!ZEROxBTCLovers[hash]){
            // congratulations we found new love for 0xBTC!
            // reward: an 0xBTC love token 
            ZEROxBTCLovers[hash] = true; 
            balanceOf[msg.sender] += (10 ** 18);
            for (uint i = 0; i < 100; i++) {
                emit Transfer(0xB6eD7644C69416d67B522e20bC294A9a9B405B31, msg.sender, 10**18); // <3 
            }
            emit New0xBTCLove(msg.sender, reason);
                
            uint beforeSupply = totalSupply;
            
            totalSupply += (10 ** 18); // Can actually overflow this because im bad at solidity (lel hackers lel)
        
            assert(totalSupply > beforeSupply);
        }
    }

    function transfer(address _to, uint256 _value) public validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event New0xBTCLove(address who, string reason);
}