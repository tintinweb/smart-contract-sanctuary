/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library safeMath{
    function sub(uint256 a, uint256 b) internal pure returns(uint256){
        assert(b <= a);
        return (a - b);
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256){
        uint256 c = a + b;
        assert(c >= a);
        return (c);
    }
}

contract ERC20TokenContract {
    using safeMath for uint256;

    string public constant  nama = "Basic ER20 Contract";
    string public constant  symbol = "BEC";
    string public constant  decimal = "18"; // 18 is a max decimal support

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 _totalSupply;

    constructor(uint256 _total) public {
        _totalSupply = _total;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns(uint256) {
        return balances[tokenOwner];
    }

    function transfer(address _receiver, uint256 numToken) public returns(bool){
        require(numToken <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numToken);
        balances[_receiver] = balances[_receiver].add(numToken);

        return true;
    }

    function approve(address _delegate, uint256 numToken) public returns(bool){
        allowed[msg.sender][_delegate] = numToken;

        return true;
    }

    function allowance(address _owner, address _delegate) public view returns(uint256){
        return allowed[_owner][_delegate];
    }

    function transferFrom(address _owner, address _buyer, uint256 numToken) public returns(bool){
        require(numToken <= balances[_owner]);
        require(numToken <= allowed[_owner][msg.sender]);
        balances[_owner] = balances[_owner].sub(numToken);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(numToken);
        balances[_buyer] = balances[_buyer].add(numToken);
        // transfer(_owner, _buyer, numToken);

        return true;
    }

}