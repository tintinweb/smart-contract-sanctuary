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
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint expectedRate, uint slippageRate);
}

contract TokenConverter {
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}

contract KyberProxy is TokenConverter, Ownable {
    
    uint256 constant internal MAX_UINT = uint256(0) - 1;
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    SwapEtherToToken swapEtherToToken;
    SwapTokenToEther swapTokenToEther;
    SwapTokenToToken swapTokenToToken;
    KyberNetworkProxy kyber;

    event ETHReceived(address indexed sender, uint amount);
    event Swap(address indexed sender, ERC20 srcToken, ERC20 destToken, uint amount);

    constructor (KyberNetworkProxy _kyber) public {
        kyber = _kyber;
        swapEtherToToken = new SwapEtherToToken();
        swapTokenToEther = new SwapTokenToEther();
        swapTokenToToken = new SwapTokenToToken();
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
        Token from,
        Token to, 
        uint256 srcQty, 
        uint256 minConversionRate
    ) external payable returns (uint256 destAmount) {
        
        ERC20 srcToken = ERC20(from);
        ERC20 destToken = ERC20(to);

        if (srcToken == ETH_TOKEN_ADDRESS && destToken != ETH_TOKEN_ADDRESS)
            swapEtherToToken.execSwap.value(srcQty)(kyber, srcToken, msg.sender);
        else if (srcToken != ETH_TOKEN_ADDRESS && destToken == ETH_TOKEN_ADDRESS)
            swapTokenToEther.execSwap(kyber, srcToken, srcQty, destToken);
        else 
            swapTokenToToken.execSwap.value(srcQty)(kyber, srcToken, srcQty, destToken, msg.sender);

        require(destAmount > minConversionRate, "Return amount too low");       

        emit Swap(msg.sender, srcToken, destToken, destAmount);
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

    function setSwapEtherToToken(
        SwapEtherToToken _swapEtherToToken
    ) public onlyOwner returns (bool) {
        swapEtherToToken = _swapEtherToToken;
    }

    function setSwapTokenToEther(
        SwapTokenToEther _swapTokenToEther
    ) public onlyOwner returns (bool) {
        swapTokenToEther = _swapTokenToEther;
    }

    function setSwapTokenToToken(
        SwapTokenToToken _swapTokenToToken
    ) public onlyOwner returns (bool) {
        swapTokenToToken = _swapTokenToToken;
    }

    function() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
	
}


contract SwapEtherToToken {
    
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    /*
    @dev Swap the user&#39;s ETH to ERC20 token
    @param token destination token contract address
    @param destAddress address to send swapped tokens to
    */
    function execSwap(
        KyberNetworkProxy proxy, 
        ERC20 token, 
        address destAddress) 
    public payable returns (uint) {
        uint minConversionRate;

        // Get the minimum conversion rate
        (minConversionRate,) = proxy.getExpectedRate(ETH_TOKEN_ADDRESS, token, msg.value);

        // Swap the ETH to ERC20 token
        uint destAmount = proxy.swapEtherToToken.value(msg.value)(token, minConversionRate);

        // Send the swapped tokens to the destination address
        require(token.transfer(destAddress, destAmount));

        return destAmount;

    }
}

contract SwapTokenToEther {
        
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    //@dev Swap the user&#39;s ERC20 token to ETH
    //@param token source token contract address
    //@param tokenQty amount of source tokens
    //@param destAddress address to send swapped ETH to
    function execSwap(
        KyberNetworkProxy proxy, 
        ERC20 token, 
        uint256 tokenQty, 
        address destAddress
    ) public returns (uint) {
        uint minConversionRate;

        // Check that the player has transferred the token to this contract
        require(token.transferFrom(msg.sender, this, tokenQty));

        // Set the spender&#39;s token allowance to tokenQty
        require(token.approve(proxy, tokenQty));

        // Get the minimum conversion rate
        (minConversionRate,) = proxy.getExpectedRate(token, ETH_TOKEN_ADDRESS, tokenQty);

        // Swap the ERC20 token to ETH
        uint destAmount = proxy.swapTokenToEther(token, tokenQty, minConversionRate);

        // Send the swapped ETH to the destination address
        destAddress.transfer(destAmount);

        return destAmount;

    }
}

contract SwapTokenToToken {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    /*
    @dev Swap the user&#39;s ERC20 token to another ERC20 token
    @param srcToken source token contract address
    @param srcQty amount of source tokens
    @param destToken destination token contract address
    @param destAddress address to send swapped tokens to
    */
    function execSwap(
        KyberNetworkProxy proxy, 
        ERC20 srcToken, 
        uint256 srcQty, 
        ERC20 destToken, 
        address destAddress
    ) public payable returns (uint) {

        // Check that the player has transferred the token to this contract
        require(srcToken.transferFrom(msg.sender, this, srcQty));

        // Set the spender&#39;s token allowance to tokenQty
        require(srcToken.approve(proxy, srcQty));

        (uint minConversionRate,) = proxy.getExpectedRate(srcToken, ETH_TOKEN_ADDRESS, srcQty);

        // Swap the ERC20 token to ERC20
        uint destAmount = proxy.swapTokenToToken(srcToken, srcQty, destToken, minConversionRate);

        // Send the swapped tokens to the destination address
        require(destToken.transfer(destAddress, destAmount));

        return destAmount;
    }
}