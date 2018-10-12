pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0), "Can&#39;t transfer to address 0x0");
        owner = _to;
        return true;
    }
}

contract ERC20 {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract TokenConverter {
    function convert(Token _fromToken, Token _toToken) external payable returns (uint256 amount);
}

contract KyberProxy is TokenConverter, Ownable {
    
    uint256 constant internal MAX_UINT = uint256(0) - 1;
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event ETHReceived(address indexed sender, uint amount);
    event Swap(address indexed sender, ERC20 srcToken, ERC20 destToken, uint amount);
    event Test(address indexed from, address indexed to, string msg);
    

    function convert(
        Token from,
        Token to
    ) external payable returns (uint256 destAmount) {

        ERC20 srcToken = ERC20(from);
        ERC20 destToken = ERC20(to);       

        if (srcToken == ETH_TOKEN_ADDRESS && destToken != ETH_TOKEN_ADDRESS) {
            emit Test(srcToken, destToken, "execSwapEtherToToken");
        } else if (srcToken != ETH_TOKEN_ADDRESS && destToken == ETH_TOKEN_ADDRESS) {
            emit Test(srcToken, destToken, "execSwapTokenToEther");

        } else {
            emit Test(srcToken, destToken, "execSwapTokenToToken");
        }
        return 1;

    }

}