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

contract KyberNetworkProxy  {
    function trade(ERC20 src,uint srcAmount,ERC20 dest,address destAddress,uint maxDestAmount,uint minConversionRate,address walletId)
    public payable returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint expectedRate, uint slippageRate);
}

contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}

contract KyberProxy is TokenConverter, Ownable {
    
    uint256 constant internal MAX_UINT = uint256(0) - 1;
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(ETH_ADDRESS);

    KyberNetworkProxy kyber;

    event ETHReceived(address indexed sender, uint amount);
    event Swap(address indexed sender, Token srcToken, Token destToken, uint amount);

    constructor (KyberNetworkProxy _kyber) public {
        kyber = _kyber;
    }

    function getReturn(
        Token from,
        Token to, 
        uint256 srcQty
    ) external view returns (uint256) {
        ERC20 srcToken = ERC20(from);
        ERC20 destToken = ERC20(to);   
        (uint256 amount,) = kyber.getExpectedRate(srcToken, destToken, srcQty);
        return amount;
    }

    function convert(
        Token srcToken,
        Token destToken, 
        uint256 srcQty, 
        uint256 minReturn
    ) external payable returns (uint256 destAmount) {
        
        destAmount = _convert(srcToken, destToken, srcQty);
        require(destAmount > minReturn, "Return amount too low");       

        emit Swap(msg.sender, srcToken, destToken, destAmount);
        return destAmount;
    }

    function _convert(
        Token from,
        Token to,   
        uint256 srcQty
    ) internal returns (uint256 destAmount) {

        // Check that the player has transferred the token to this contract
        require(from.transferFrom(msg.sender, this, srcQty), "Error pulling tokens");
        require(to.approve(kyber, srcQty), "Without allowance to tokenQty");     

        uint minConversionRate = this.getReturn(from, to, srcQty);

        ERC20 srcToken = ERC20(from);
        ERC20 destToken = ERC20(to);

        if (srcToken == ETH_TOKEN_ADDRESS && destToken != ETH_TOKEN_ADDRESS) {
            require(msg.value == srcQty, "msg.value is not equal to srcQty");
            destAmount = kyber.swapEtherToToken.value(msg.value)(srcToken, minConversionRate);
            require(destToken.transfer(msg.sender, destAmount), "Error sending tokens (swapEtherToToken)");
        } else if (srcToken != ETH_TOKEN_ADDRESS && destToken == ETH_TOKEN_ADDRESS) {
            kyber.swapTokenToEther(srcToken, srcQty, minConversionRate);
            msg.sender.transfer(destAmount);
        } else {
            destAmount = kyber.trade(
                srcToken,           // srcToken
                srcQty,             // srcQty
                destToken,          // destToken 
                msg.sender,         // destAddress
                MAX_UINT,           // maxDestAmount
                minConversionRate,  // minConversionRate
                0                   // walletId
            );
            require(destToken.transfer(msg.sender, destAmount), "Error sending tokens (trade)");
        }

        return destAmount;
    } 

    function withdrawTokens(
        Token _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        return _token.transfer(_to, _amount);
    }

    function withdrawEther(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _to.transfer(_amount);
    }

    function setConverter(
        KyberNetworkProxy _converter
    ) public onlyOwner returns (bool) {
       kyber = _converter;
    }

    function() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
	
}