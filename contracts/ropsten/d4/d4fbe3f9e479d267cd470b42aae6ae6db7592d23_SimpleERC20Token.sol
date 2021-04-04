/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity 0.8.0;

contract SimpleERC20Token {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    // Modify this section
    string public name = "Lemon Token";
    string public symbol = "LEMON";
    uint8 public decimals = 18;
    uint256 public totalSupply = 2000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function sendBatchCS(address[] calldata _recipients, uint256[] calldata _values) external returns (bool) {
        require(_recipients.length == _values.length);

        uint senderBalance = balanceOf[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            if(msg.sender != _recipients[i]){
                senderBalance = senderBalance - value;
                balanceOf[to] += value;
            }
			emit Transfer(msg.sender, to, value);
        }
        balanceOf[msg.sender] = senderBalance;
        return true;
}
    
    // function sendBatch(address[] calldata _recipients, uint256[] calldata _values) external returns (bool) {
    //     require(_recipients.length == _values.length);
    //     for (uint i = 0; i < _values.length; i++) {
    //         require(transfer(_recipients[i], _values[i]));
    //     }
    //     return true;
    // }
}