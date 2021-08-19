/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity ^0.8.6;

// ----------------------------------------------------------------------------


// ITC CONTRACT Constrctor
contract Code {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totaltax;
    address private _owner = 0x74c5D75F390B8b479CcB086E171eAf5b18AbA6e1;
    uint256 public _totalSupply;
    
    bool private _tradingopen = true;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    
    /**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
    uint256 private _fundingWalletFee = 5;
    uint256 private _liquidityFee = 5;
    uint256 private _reflectionFee = 5;
    uint256 private _minimumToDistribute = 5;
    uint256 private _burnFee = 5;
    // string private a = " _burnFee = 5";
    //     string private b = "_minimumToDistribute = 5";
    //     string private c = "";
    //     string private d = "";
    //     string private e = "";
    mapping(address => bool) private _blacklist;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    /**
     * ITC constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "ITCoin";
        symbol = "ITC";
        decimals = 9;
        _totalSupply = 500000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
// ITC functions
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require( !isblacklist(to) && !isblacklist(msg.sender),"recipient is blacklisted");
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // require(_from == _owner);
        require( !isblacklist(_from) && !isblacklist(_to),"Either you or recipient is blacklisted");
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // function setTradingOpen() external {
    //     require(msg.sender == _owner,"You are not owner");
    //     _tradingOpen = true;
    // }
    
    // function setTradingOpen() external {
    //     require(msg.sender == _owner,"You are not owner");
    //     _tradingOpen = false;
    // }

    
     
    function fees() public view returns (uint256 fundingWalletFee, uint256 burnFee)  {
        
        return (_fundingWalletFee,_burnFee);
    }
    
    
    
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
     
    // function tradingOpen() external view returns (bool) {
    //     return _tradingOpen;
    // }
    
    function blacklist(address _add) public returns(bool){
        require(msg.sender == _owner,"You are not owner");
        _blacklist[_add] = true;
        return true;
    }
    function removeblacklist(address _add) public returns(bool){
        require(msg.sender == _owner,"You are not owner");
        _blacklist[_add] = false;
        return true;
    }
    
    function isblacklist(address _add) view public returns(bool){
        return _blacklist[_add];
    }
    
    
}