/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENCED

contract jiggle {
    
    // SafeMath
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    

    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    
    string private _name;
    string private _symbol;

    uint private  _supply;
    uint8 private _decimals;
    
    address private _owner;
    address public PCS_POOL;
    
    bool public partymode;
    uint public deploy_timestamp;
    
    constructor() {
        deploy_timestamp = block.timestamp;
        partymode = false;
        _owner = msg.sender;
        
        _name = "Jiggle Party";
        _symbol = "JIGGLE";
        _supply = 1_000_000;  // 1 Million
        _decimals = 6;
        
        _balances[_owner] = totalSupply();
        emit Transfer(address(this), _owner, totalSupply());
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return mul(_supply, 10 ** _decimals);
    }
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);

    function _transfer(address from, address to, uint amount) private returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient funds.");
        
        _balances[from] = sub(balanceOf(from), amount);
        _balances[to] = add(balanceOf(to),amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        return _transfer(msg.sender, to, amount);
    }
    
    function override_partymode(bool toggle) public owner returns(bool){
        partymode = toggle;
        return true;
    }


    // Selling on AMM DEXs will utilize this function to swap funds.
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient authorized funds.");
        
        
        //Toggle party mode on check
        if (block.timestamp > deploy_timestamp + 2700){ //2700s = 45min
            if(amount == 69*10**_decimals || amount == 8008*10**_decimals || amount == 420*10**_decimals){
                partymode = true;
            }
        }
        
        
        //Jiggle rebase
                uint jiggle_amount = div(balanceOf(PCS_POOL),100);
        uint roll = randMod(100);
        
        if (partymode = false){
                    if (roll > 48){ //~50% chance of inflationary/delfationary rebase
                    _balances[PCS_POOL] = sub(balanceOf(PCS_POOL),jiggle_amount); 
                    _supply -= jiggle_amount; //Deflationary
                    }
                    else{
                    _balances[PCS_POOL] = add(balanceOf(PCS_POOL),jiggle_amount);
                    _supply += jiggle_amount; //Inflationary
                    }
        }
        if (partymode = true){
                    if (roll > 70){ //Bring out the drugs, time to party ya fucken drugger
                    _balances[PCS_POOL] = sub(balanceOf(PCS_POOL),jiggle_amount);
                    _supply -= jiggle_amount;
                    }   
                    else{
                    _balances[PCS_POOL] = add(balanceOf(PCS_POOL),jiggle_amount);
                    _supply += jiggle_amount;
                    }
        }
        
        //Finalize transaction and allowance. 
        _transfer(from, to, amount);
        _allowances[from][msg.sender] = sub(allowance(from, msg.sender),amount);

        return true;
    }


    function approve(address spender, uint amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }
    
    function renounceOwnership() public owner returns(bool) {
        _owner = address(this);
        return true;
    }
    
    function setPoolAddress(address poolAddress) public owner returns(bool){
        PCS_POOL = poolAddress;
        return true;
    }
    
    function randMod(uint _modulus) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp))) % _modulus;
    }
    
}