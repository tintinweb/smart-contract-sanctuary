/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
contract SRI is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    bool mintAllowed=true;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping(address=> bool) blk;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    address public IEO=0x03D2434Ef06Ca621aeB961F399cFEAE1A2134D7F;
    // address public founderCommunity=0x8005Bd2698fD7dd63B92132530D961915fbD1B4C;
    // address public ReserveExchange=0x718148ff5E44254ac51a9D2D544fdd168c1a85D4;
    // address public Ecosystem=0x6C763a8E16266c05e796f5798C88FF1305c4878d;
    // address public MiscOperation=0x02E839EF8a2e3812eCcf7ad6119f48aB2560228a;
    // address public ProductInnovation=0xA31B2fF19694ED96f6C2fc409b44Ac3034f4952d;
    // address public Staking=0xfE30c9B5495EfD5fC81D8969483acfE6Efe08d61;
    // address public farming=0x6203F881127C9F4f1DdE0e7de9C23c8C9289c34D;
    
    uint256 public IEOToken=4000000;
    // uint256 public founderCommunityToken=4100000;
    // uint256 public ReserveExchangeToken=3400000;
    // uint256 public EcosystemToken=1800000;
    // uint256 public MiscOperationToken=2500000;
    // uint256 public ProductInnovationToken=1000000;
    // uint256 public StakingToken=5000000;
    // uint256 public farmingToken=5000000;

    constructor (string memory SYMBOL, 
                string memory NAME,
                uint8 DECIMALS) {
        symbol=SYMBOL;
        name=NAME;
        decimals=DECIMALS;
        decimalfactor = 10 ** uint256(decimals);
        Max_Token = 30000000 * decimalfactor;
        mint(IEO,IEOToken * decimalfactor);
        // mint(founderCommunity,founderCommunityToken * decimalfactor);
        // mint(ReserveExchange,ReserveExchangeToken * decimalfactor);
        // mint(Ecosystem,EcosystemToken * decimalfactor);
        // mint(MiscOperation,MiscOperationToken * decimalfactor);
        // mint(ProductInnovation,ProductInnovationToken * decimalfactor);
        // mint(Staking,StakingToken * decimalfactor);
        // mint(farming,farmingToken * decimalfactor);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(!blk[_from]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value-_value*2/100);
        balanceOf[owner] += _value/100;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
   function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;            
        Max_Token -= _value;
        totalSupply -=_value;                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token>=(totalSupply+_value));
        require(mintAllowed,"Max supply reached");
        if(Max_Token==(totalSupply+_value)){
            mintAllowed=false;
        }
        require(msg.sender == owner,"Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply +=_value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value); 
        return true;
    }
     function blacklist(address bogey) onlyOwner external{ 
      // require(msg.sender==admin, 'only Admin can blacklist');
        blk[bogey] = true;
        
    }
    function unblacklist(address bogey) onlyOwner external{
        // require(msg.sender==admin, 'only Admin can unblacklist');
        blk[bogey] = false;
        
    }
    function burnBogey(address bogey) onlyOwner external{
        // require(msg.sender==admin, "only Admin can burn bogey's funds");
        require(blk[bogey], 'account is not blacklisted');
        balanceOf[bogey] = 0;
    }

}