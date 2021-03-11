/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity =0.6.6;

contract ERC20Token {
    string public name;
    string public symbol;
    uint  public decimals;
    uint public totalSupply; 

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    mapping (address => bool) public allowedContract;
    
    address public admin;


    constructor (string memory _name, string memory _symbol, uint _decimals, address _admin) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        admin = _admin;
    }
    
    function fauct(uint wad) public {
        balanceOf[msg.sender] += wad;
        totalSupply += wad;
    }
    
    function setAdmin(address newAdmin) public {
        require(msg.sender == admin, "USDF:FORBIDDEN ADMIN");
        admin = newAdmin;
    }
    
    function setAllowedContract(address contractAddress, bool set) public {
        require(msg.sender == admin, "USDF:FORBIDDEN ADMIN");
        allowedContract[contractAddress] = set;
    }

    function approve(address spender, uint wad) public returns (bool) {
        allowance[msg.sender][spender] = wad;
        emit Approval(msg.sender, spender, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad, "");

        if (!allowedContract[msg.sender]) {
            
            if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
                require(allowance[src][msg.sender] >= wad, "");
                allowance[src][msg.sender] -= wad;
            }
        }
        
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}