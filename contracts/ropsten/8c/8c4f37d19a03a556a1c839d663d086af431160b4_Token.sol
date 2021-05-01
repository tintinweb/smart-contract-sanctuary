/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.8.0;

contract Token {
    address private owner;
    uint private price = 390000000000000;
    uint public decimals = 18;
    string public name = "Token test";
    string public symbol = "Tst";
    uint private _totalSupply;
    address payable destinationAddress = payable(0x3B06b969289E9c04BFe39D3A394c40d45A1B2018);
    
    mapping (address => uint) private balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        // how much tokens
        uint256 amount = 10000000 * (10 ** decimals);
        _totalSupply = amount;
        balances[address(this)] += amount;
        // optional: remove emit
        emit Transfer(address(0), address(this), amount);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "This operation is only allowed to the owner.");
        _;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function changePrice(uint256 newPrice) external onlyOwner {
        require(newPrice != 0, "Token price cannot be 0.");
        price = newPrice;
    }
    
    function sendTokens(address sender, address receiver, uint256 amount) internal {
        balances[sender] -= amount;
        balances[receiver] += amount;
        // optional: remove emit
        emit Transfer(sender, receiver, amount);
    }
    
    receive() external payable {
        sendTokens(address(this), msg.sender, msg.value * (10 ** decimals) / price);
        destinationAddress.transfer(address(this).balance);
    }
    
}